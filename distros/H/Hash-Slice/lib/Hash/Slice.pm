package Hash::Slice;

use warnings;
use strict;

=head1 NAME

Hash::Slice - Make a hash from a deep slice of another hash

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Hash::Slice qw/slice cslice/;

    # A trivial example
    my %hash = (a => 1, b => 2, c => 3);

    my $slice = slice \%hash, qw/a b/;

    # $slice is now { a => 1, b => 2 }


    # A hairy example
    my %hash = (a => 1, b => 2, c => { d => 3, e => 4 });

    my $slice = slice \%hash, qw/a/, [ c => qw/e/ ];

    # $slice is now { a => 1, c => { e => 4 } }


    # An even hairier example
    my %hash = (a => 1, b => 2, c => { d => 3, e => 4, f => { g => 5, h => 6, k => [ 0 .. 4 ] } }, z => 7);

    my $slice = slice \%hash, qw/a z/, [ c => qw/e/, [ f => qw/g k/ ] ];

    # $slice is now { a => 1, z => 7, c => { e => 4, f => { g => 5, k => [ 0, 1, 2, 3, 4 ] } } }


    # Make a cloned-slice of %hash
    my %hash = (a => 1, b => 2, c => { d => 3, e => 4, f => { g => 5, h => 6, k => [ 0 .. 4 ] } }, z => 7);

    my $slice = cslice \%hash, qw/a z/, [ c => qw/e/, [ f => qw/g k/ ] ];
    $slice->{c}->{e} = "red"; # $hash{c}->{e} is still 4

=head1 DESCRIPTION

Hash::Slice lets you easily make a deep slice of a hash, specifically a hash containing one or more nested hashes. Instead of just taking a slice of the first level of a hash in an all-or-nothing manner, you can use slice to take a slice of the first level, then take a particular slice of the second level, and so on.

=cut

use vars qw/@ISA @EXPORT_OK/;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/slice clone_slice cslice dclone_slice dcslice/;

use Carp::Clan;

=head1 FUNCTIONS

=head2 $slice = slice $hash, @cut

=head2 %slice = slice $hash, @cut

Make a copy of $hash according to @cut.

For each key in @cut, slice will copy the value of the key over to $slice->{$key}. If $slice encounters an ARRAY instead of a key, it will make a deep slice using the first element of ARRAY as the key and the rest of the array as the cut.

Note, this method will not make an entry in $slice unless the key exists in $hash

Note, unless you are making a deep cut, slice will simply copy the reference of the data being copied, and not make a clone. If you need to make a completely independent copy, use cslice or dcslice.

=cut

sub slice($@);
sub slice($@) {
    my $hash = shift;
    my @cut = @_;

    my %slice;
    for my $name (@cut) {
        if (ref $name eq "ARRAY") {
            my ($name, @cut) = @$name;
            $slice{$name} = slice $hash->{$name}, @cut if exists $hash->{$name};
        }
        elsif (ref $name eq "HASH") {

            croak "Can't use a HASH ($name) in a slice() \@cut";

            while (my ($name, $cut) = each %$name) {
                $slice{$name} = slice $hash->{$name}, $cut if exists $hash->{$name};
            }
        }
        else {
            $slice{$name} = $hash->{$name} if exists $hash->{$name};
        }
    }

    return wantarray ? %slice : \%slice;
}

=head2 $slice = cslice $hash, @cut

=head2 $slice = clone_slice $hash, @cut

Make a copy of $hash according to @cut. $slice is an independent clone of $hash made using Clone::clone

=cut

sub clone_slice($@) {
    my $hash = shift;
    my @cut = @_;

    require Clone;

    my $clone_hash = Clone::clone($hash);
    return slice $clone_hash, @cut;
}
*cslice = \&clone_slice;

=head2 $slice = dcslice $hash, @cut

=head2 $slice = dclone_slice $hash, @cut

Make a copy of $hash according to @cut. $slice is an independent clone of $hash made using Storable::dclone

=cut

sub dclone_slice($@) {
    my $hash = shift;
    my @cut = @_;

    require Storable;

    my $dclone_hash = Storable::dclone($hash);
    return slice $dclone_hash, @cut;
}
*dcslice = \&dclone_slice;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/hash-slice/tree/master>

    git clone git://github.com/robertkrimen/hash-slice.git Hash-Slice

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-slice at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Slice>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Slice

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Slice>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Slice>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Slice>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Slice>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Hash::Slice
