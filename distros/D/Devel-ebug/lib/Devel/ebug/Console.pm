package Devel::ebug::Console;

our $VERSION = '0.63'; # VERSION

use strict;
use warnings;
use lib 'lib';
use Carp;
use Class::Accessor::Chained::Fast;
use Devel::ebug;
use Term::ReadLine;
use base qw(Class::Accessor::Chained::Fast);

sub run {
  my $self = shift;
  my $backend = shift;

  $SIG{INT} = sub {
    die "INT";
  };

  my $filename = join " ", @ARGV;

  unless ($filename) {
    $filename = '-e "Interactive ebugging shell"';
  }

  my $ebug = Devel::ebug->new;
  $ebug->program($filename);
  $ebug->backend($backend);
  $ebug->load;

  my $codelines = {};

  print "* Welcome to Devel::ebug $Devel::ebug::VERSION\n";

  my $term = Term::ReadLine->new('ebug');
  my $attribs = $term->Attribs;
  $attribs->{completion_function} = sub {
    my ($text, $line, $start) = @_;
    my $pad = $ebug->pad || {};
    return unless $line =~ s/^x //;
    my @result = grep { /^\Q$line/ } keys %$pad;
    if ($line =~ /^[\$\@]/) {
      s/^[\$\@]// for @result;
    }
    return @result;
  };
  my $last_command = "s";
  my $list_always = 0;
  my $list_lines_count = 9;

  while (1) {
    if ($ebug->finished) {
      print "ebug: Program finished. Enter 'restart' or 'q'\n";
    } else {
      if ($list_always) {
        show_codelines($codelines, $ebug, $list_lines_count) if($list_always);
      } else {
        print $ebug->subroutine
        . "(" . $ebug->filename . "#" . $ebug->line . "):\n"
        . $ebug->codeline, "\n";
      }
    }

    my $command = $term->readline("ebug: ");
    $command = "q" if not defined $command;
    $command = $last_command if ($command eq "");

    if ($command =~ /^\s*[?h](elp)?\s*$/) {
      print 'Commands:

      b Set break point at a line number (eg: b 6, b code.pl 6, b code.pl 6 $x > 7,
      b Calc::fib)
     bf break on file loading (eg: bf Calc.pm)
      d Delete a break point (d 6, d code.pl 6)
      e Eval Perl code and print the result (eg: e $x+$y)
      f Show all the filenames loaded
      l List codelines or set number of codelines to list (eg: l, l 20)
      L List codelines always (toggle)
      n Next (steps over subroutine calls)
      o Output (show STDOUT, STDERR)
      p Show pad
      r Run until next break point or watch point
    ret Return from subroutine  (eg: ret, ret 3.141)
restart Restart the program
      s Step (steps into subroutine calls)
      T Show a stack trace
      u Undo (eg: u, u 4)
      w Set a watchpoint (eg: w $t > 10)
      x Dump a variable using YAML (eg: x $object)
      q Quit
';
    } elsif ($command eq 'l') {
      show_codelines($codelines, $ebug, $list_lines_count);
    } elsif ($command =~ /^ l \s+ (\d+) $/x) {
      $list_lines_count = $1 if $1 > 0;
      show_codelines($codelines, $ebug, $list_lines_count);
    } elsif ($command eq 'L') {
      $list_always = !$list_always;
    } elsif ($command eq 'p') {
      my $pad = $ebug->pad_human;
      foreach my $k (sort keys %$pad) {
        my $v = $pad->{$k};
        print "  $k = $v;\n";
      }
    } elsif ($command eq 's') {
      $ebug->step;
    } elsif ($command eq 'n') {
      $ebug->next;
    } elsif ($command eq 'o') {
      my($stdout, $stderr) = $ebug->output;
      print "STDOUT:\n$stdout\n";
      print "STDERR:\n$stderr\n";
    } elsif ($command eq 'r') {
      $ebug->run;
      # TODO: Consider using this instead:
      # eval { $ebug->run };
    } elsif ($command eq 'restart') {
      $ebug->load;
    } elsif ($command =~ /^ret ?(.*)/) {
      $ebug->return($1);
    } elsif ($command eq 'T') {
      my @trace = $ebug->stack_trace_human;
      foreach my $frame (@trace) {
        print "$frame\n";
      }
    } elsif ($command eq 'f') {
      print "$_\n" foreach $ebug->filenames;
    } elsif (my($line, $condition) = $command =~ /^b (\d+) ?(.*)/) {
      undef $condition unless $condition;
      $ebug->break_point($line, $condition);
    } elsif ($command =~ /^b (.+?) (\d+) ?(.*)/) {
      $ebug->break_point($1, $2, $3);
    } elsif ($command =~ /^b (.+)/) {
      $ebug->break_point_subroutine($1);
    } elsif ($command =~ /^bf (.+)/) {
      $ebug->break_on_load($1);
    } elsif ($command =~ /^d (.+?) (\d+)/) {
      $ebug->break_point_delete($1, $2);
    } elsif ($command =~ /^d (\d+)/) {
      $ebug->break_point_delete($1);
    } elsif ($command =~ /^w (.+)/) {
      my($watch_point) = $command =~ /^w (.+)/;
      $ebug->watch_point($watch_point);
    } elsif ($command =~ /^u ?(.*)/) {
      $ebug->undo($1);
    } elsif ($command eq 'q') {
      exit;
    } elsif ($command =~ /^x (.+)/) {
      my $v = $ebug->eval("use YAML; Dump($1)") || "";
      print "$v\n";
    } elsif ($command =~ /^e (.+)/) {
      my $v = $ebug->eval($1) || "";
      print "$v\n";
    } elsif ($command) {
      my $v = $ebug->eval($command) || "";
      print "$v\n";

    }
    $last_command = $command;
  }
}

sub show_codelines {
  my ($codelines, $ebug, $list_lines_count) = @_;

  my $line_count = int($list_lines_count / 2);

  if (not exists $codelines->{$ebug->filename}) {
    $codelines->{$ebug->filename} = [$ebug->codelines];
  }

  my @span = ($ebug->line-$line_count .. $ebug->line+$line_count);
  @span = grep { $_ > 0 } @span;
  my @codelines = @{$codelines->{$ebug->filename}};
  my @break_points = $ebug->break_points();
  my %break_points;
  $break_points{$_}++ foreach @break_points;
  foreach my $s (@span) {
    my $codeline = $codelines[$s -1 ];
    next unless defined $codeline;
    if ($s == $ebug->line) {
      print "*";
    } elsif ($break_points{$s}) {
      print "b";
    } else {
      print " ";
    }
    print "$s:$codeline\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Console

=head1 VERSION

version 0.63

=head1 SYNOPSIS

  # it's easier to use the 'ebug' script
  use Devel::ebug::Console;
  my $console = Devel::ebug::Console->new();
  $console->run();

=head1 DESCRIPTION

L<Devel::ebug::Console> is an interactive command-line front end to L<Devel::ebug>. It
is a simple Perl debugger, much like perl5db.pl.

=head1 NAME

Devel::ebug::Console - Console front end to Devel::ebug

=head1 SEE ALSO

L<Devel::ebug>, L<ebug>

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
