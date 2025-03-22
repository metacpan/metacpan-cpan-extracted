#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util qw( refaddr );
use Data::Dump qw( pp );

my $a = Something->new;

warn $a;
warn pp $a;
warn refaddr( $a );


package Something;

use strict;
use warnings;

use Carp qw( cluck );


use overload (
        '""' => sub { cluck "stringify"; return "address of ". ref($_[0]); }
    );

sub new 
{
    my $package = shift;
    return bless {}, $package;
}