# vim:expandtab tabstop=4 shiftwidth=4

package Hash::DeepAccess;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use Exporter 'import';
use Want;

our @EXPORT = qw( deep );

=head1 NAME

Hash::DeepAccess - The great new Hash::DeepAccess!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Allows retrieving and changing values in a nested hash structure.

    use Hash::DeepAccess;

    my $hash = {
        a => {
            b => {
                c => {
                    d => 5
                },
            },
        },
    };

    my $five = deep($hash, qw( a b c d ));

    deep($hash, qw( a b c d )) = 10;

=head1 EXPORT

=head2 deep(HASH, PATH, ...)

Retrieve the value determined by the path elements in the given hash. It's an
lvalue function, so values can be assigned to it to insert elements deep into
hashes. The function tries to be smart about this and does not create empty
hashes for non-existent paths unless a value is actually assigned. However, if
a value is assigned and elements in the path reference non-hash values, those
are overwritten with hashes to create the requested structure.

=cut

sub deep : lvalue {
    my ($hash, @path) = @_;

    my $lvalue = want(qw( LVALUE ASSIGN ));

    my $last = pop @path;

    while(@path) {
        my $node = shift @path;

        croak("Expected a hash") if ref($hash) ne 'HASH';

        if(!defined($hash->{$node}) || ref($hash->{$node}) ne 'HASH') {
            if($lvalue) {
                $hash->{$node} = {};
            }
            else {
                return undef;
            }
        }

        $hash = $hash->{$node};
    }

    return $hash->{$last};
}

=head1 AUTHOR

Jonas Kramer, C<< <jkramer at mark17.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-deepaccess at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-DeepAccess>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::DeepAccess


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-DeepAccess>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-DeepAccess>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-DeepAccess>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-DeepAccess/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jonas Kramer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Hash::DeepAccess
