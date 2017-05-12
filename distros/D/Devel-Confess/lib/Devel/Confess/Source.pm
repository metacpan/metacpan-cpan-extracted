package Devel::Confess::Source;
use 5.006;
use strict;
use warnings FATAL => 'all';

sub import {
  $^P |= "$]" >= 5.010 ? 0x400 : do {
    *DB::DB = sub {}
      unless defined &DB::DB;
    0x02;
  };
}

my $want_color = $^O ne 'MSWin32' ? 1 : eval {
  require Win32::Console::ANSI;
  Win32::Console::ANSI->import;
  1;
};

sub source_trace {
  my ($skip, $context, $evalonly) = @_;
  $skip ||= 1;
  $skip += $Carp::CarpLevel;
  $context ||= 3;
  my $i = $skip;
  my @out;
  while (my ($pack, $file, $line) = (caller($i++))[0..2]) {
    next
      if $Carp::Internal{$pack} || $Carp::CarpInternal{$pack};
    next
      if $evalonly && $file !~ /^\(eval \d+\)(?:\[|$)/;
    my $lines = _get_content($file) || next;

    my $start = $line - $context;
    $start = 1 if $start < 1;
    $start = $#$lines if $start > $#$lines;
    my $end = $line + $context;
    $end = $#$lines if $end > $#$lines;

    my $context = "context for $file line $line:\n";
    for my $read_line ($start..$end) {
      my $code = $lines->[$read_line];
      $code =~ s/\n\z//;
      if ($want_color && $read_line == $line) {
        $code = "\e[30;43m$code\e[m";
      }
      $context .= sprintf "%5s : %s\n", $read_line, $code;
    }
    push @out, $context;
  }
  return ''
    if !@out;
  return join(('=' x 75) . "\n",
    '',
    join(('-' x 75) . "\n", @out),
    '',
  );
}

sub _get_content {
  my $file = shift;
  no strict 'refs';
  if (exists $::{'_<'.$file} && @{ '::_<'.$file }) {
    return \@{ '::_<'.$file };
  }
  elsif ($file =~ /^\(eval \d+\)(?:\[.*\])?$/) {
    return ["Can't get source of evals unless debugger available!"];
  }
  elsif (open my $fh, '<', $file) {
    my @lines = ('', <$fh>);
    return \@lines;
  }
  else {
    return ["Source file not available!"];
  }
}

1;
