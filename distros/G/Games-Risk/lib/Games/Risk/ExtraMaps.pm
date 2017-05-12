#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::ExtraMaps;
# ABSTRACT: base class for exta maps
$Games::Risk::ExtraMaps::VERSION = '4.000';
use File::ShareDir::PathClass;
use Moose;
use Path::Class;

extends 'Games::Risk::Map';

 
# -- public method

sub sharebase {
    my $self  = shift;
    my $extra   = $self->extra_category;
    my $distini = file("dist.ini");

    if ( -e $distini ) { 
        my ($line) = $distini->slurp;
        return dir( "share" ) if $line =~ /$extra/;
    }

    return File::ShareDir::PathClass->dist_dir("Games-Risk-ExtraMaps-$extra");
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::ExtraMaps - base class for exta maps

=head1 VERSION

version 4.000

=head1 DESCRIPTION

Due to the weight of extra maps (with images), those are deported in
some other CPAN distributions. But this means that their shared data is
now located in a place which is not L<Games::Risk>'s one.

This class is therefore a base class for extra maps to allow smooth
finding of the share directory, with an overloading of C<sharedir>
method.

=for Pod::Coverage extra_category

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
