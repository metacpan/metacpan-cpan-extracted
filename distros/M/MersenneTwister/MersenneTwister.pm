# Filename: Rand/MersenneTwister.pm
# Author:   George Schlossnagle <george@omniti.com>
#           Theo Schlossnagle <jesus@omniti.com> 
# Created:  03 October 2002
# Version:  1.0.1
#
# Copyright (c) OmniTI Computer Consulting, Inc. All rights reserved.
#   This program is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#

package Rand::MersenneTwister;

require 5.004;
require Exporter;
require DynaLoader;
require AutoLoader;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

$VERSION = "1.0.1" ;

@ISA = qw(Exporter DynaLoader);


%EXPORT_TAGS = (
		FUNCS => [ qw(mt_init
                              mt_free
                              mt_seed
			      mt_rand) ],
	       );

@EXPORT = qw( ERROR );

@EXPORT_OK = qw(
		mt_init
		mt_free
		mt_seed
		mt_rand);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined Rand::MersenneTwister macro $constname";
        }
    }
    eval "sub $AUTOLOAD { \"$val\" }";
    goto &$AUTOLOAD;
}

bootstrap Rand::MersenneTwister $VERSION ;

sub new {
  my $self = shift;
  my $class = ref($self) || $self;

  my $td = mt_init();
  my $obj = bless { GEN => $td }, $class;
  if(@_) {
    $obj->seed(@_);
  }
  return $obj;
}

sub seed {
  my($self, $seed) = @_;
  $seed ||= time*$$*100000;
  mt_seed($self->{GEN}, $seed);
}

sub rand {
  my $self = shift;
  return mt_rand($self->{GEN}, @_);
}

sub DESTROY {
  my($self) = shift;
  mt_free($self->{GEN});
}

1;

__END__

=head1 NAME

Mcrypt - Perl extension for a Mersenne Twister PRGN implementation with context.

=head1 SYNOPSIS

  use Rand::MersenneTwister;

  # Object-oriented methods

  # New object context optionally seeded.
  $r = Rand::MersenneTwister->new( [$seed] );
  
  # Seed or reseed this PRNG context.
  $r->seed($number); 

  # fetch the next random number in the sequance.
  # between 0 and 1
  my $random_number = $r->rand;
  # between 0 and $v
  my $random_number = $r->rand($v);

  # If the $r goes out of context, it is freed.


=head1 DESCRIPTION

This module wraps a fast, C implementation of a Mersenne Twister-based PRNG.
=head1 Exported constants

The predefined groups of exports in the use statements are as follows:

use Rand::MersenneTwister;

Exports the following functions: mt_init, mt_free, mt_seed,
mt_rand.

=head1 EXAMPLES

    use Rand::MersenneTwister;

    my $r = Rand::MersenneTwister->new();
    $r->seed();
    my $randmon_number = $r->rand(100);

=head1 AUTHOR

George Schlossnagle <george@omniti.com>
Theo Schlossnagle <jesus@omniti.com>

=head1 SEE ALSO

http://www.math.keio.ac.jp/~matumoto/mt.html

For the less worldly:

http://www.math.keio.ac.jp/~matumoto/emt.html

=cut
