package HTML::Show;

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Browser::Open;

our $VERSION = '0.001';    # VERSION

=encoding utf-8

=head1 NAME

HTML::Show - Show html in a browser locally

=head1 SYNOPSIS

    use HTML::Show;
   	
	HTML::Show::show('<html><head><title>Showing html</title></head><body><h1>Show html</h1></body></html>');
     
=head1 DESCRIPTION

Show html in the local browser without url, only with the content.

This module does not export anything and the interface is "sub" oriented, but the API is subject to changes.

=head1 FUNCTIONS

=cut

=head2 show

Show the html content. Accept anything that can be stringified.

=cut

sub show {
    my $html_file = Path::Tiny::tempfile( UNLINK => 0, SUFFIX => '.html' );
    $html_file->spew_utf8( "" . shift() );
    Browser::Open::open_browser( $html_file->canonpath() );
}

1;

__END__

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-HTML-Show/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

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

