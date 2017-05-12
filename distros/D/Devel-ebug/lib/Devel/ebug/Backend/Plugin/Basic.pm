package Devel::ebug::Backend::Plugin::Basic;
$Devel::ebug::Backend::Plugin::Basic::VERSION = '0.59';
use strict;
use warnings;

sub register_commands {
  return (basic => { sub => \&basic });
}

sub basic {
  my ($req, $context) = @_;
  return {
    codeline   => $context->{codeline},
    filename   => $context->{filename},
    finished   => $context->{finished},
    line       => $context->{line},
    package    => $context->{package},
    subroutine => subroutine($req, $context),
  };
}

sub subroutine {
  my ($req, $context) = @_;
  foreach my $sub (keys %DB::sub) {
    my ($filename, $start, $end) = $DB::sub{$sub} =~ m/^(.+):(\d+)-(\d+)$/;
    next if $filename ne $context->{filename};
    next unless $context->{line} >= $start && $context->{line} <= $end;
    return $sub;
  }
  return 'main';
}

1;
