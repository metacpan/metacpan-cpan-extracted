package Alien::CLIPS;

use strict;
use warnings;

our @ISA;

BEGIN {
  my $ok = eval {
    require Alien::Base;
    @ISA = qw(Alien::Base);
    1;
  };
  @ISA = () if !$ok;
}

sub dynamic_libs {
  return grep { defined && length } (
    $ENV{INLINE_CLIPS_LIB},
    $ENV{ALIEN_CLIPS_LIB},
  );
}

sub bin_dir {
  return grep { defined && length } (
    $ENV{INLINE_CLIPS_BIN},
    $ENV{ALIEN_CLIPS_BIN},
  );
}

1;

__END__

=head1 NAME

Alien::CLIPS - Find or build CLIPS using Alien::Build

=head1 DESCRIPTION

This Alien distribution prefers a system CLIPS installation and otherwise
builds CLIPS from the FuzzyCLIPS source repository:

L<https://github.com/jtrujil43/FuzzyCLIPS>
