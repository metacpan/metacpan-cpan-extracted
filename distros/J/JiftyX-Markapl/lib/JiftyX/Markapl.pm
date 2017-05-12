package JiftyX::Markapl;

use strict;
use warnings;
our $VERSION = '0.03';

1;
__END__

=head1 NAME

JiftyX::Markapl - A Jifty extension to let you use Markapl for templating

=head1 DESCRIPTION

JiftyX::Markapl is an implementation of using Markapl in Jifty.

So far it requires several configuration steps to do this.

Edit C<etc/config.yml>. Add "Markapl" in to the list of framework
plugins, and add C<JiftyX::Markapl::Handler> in to the view handlers,
remove the Template-Declare and Mason Handlers from the list.

    framework:
      Plugins:
        - Markapl: {}

      TemplateClass: MyApp::View
      View:
        Handlers:
          - Jifty::View::Static::Handler
          - JiftyX::Markapl::Handler

Verify that you still have 'TemplateClass' with value C<MyApp::View>

Then, edit your C<MyApp/View.pm>:

    package MyApp::View;
    use Markapl;
    use JiftyX::Markapl::Helpers;

    template '/' => sub {
        h1("#heading") { "Hello, MyApp" };
    };

Then you should be able to visit "/' and see the hello.

For a fully working example, see example/Oreo directory.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

L<Markapl>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
