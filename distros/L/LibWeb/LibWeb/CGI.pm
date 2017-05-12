#==============================================================================
# LibWeb::CGI -- Extra cgi supports for libweb applications.

package LibWeb::CGI;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: CGI.pm,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#-#############################
# Use standard library.
use strict;
use vars qw(@ISA $VERSION $AutoloadClass);

#-#############################
# Use custom library.
require LibWeb::Class;
require LibWeb::Core;

$VERSION = '0.02';

#-#############################
# Inheritance.
# Require CGI.pm version > 2.66.
require CGI;
@ISA = qw( LibWeb::Class CGI );
# This variable tells CGI what type of default object to create when
# called in the function-oriented manner.
$CGI::DefaultClass = __PACKAGE__;
# This tells the CGI autoloader where to look for functions that are
# not defined. If you wish to override CGI's autoloader, set this to
# the name of your own package.
$AutoloadClass = 'CGI';
# Avoid denial of service attacks.
$CGI::POST_MAX = 1024 * 100; # Default: Max 100K posts.
$CGI::DISABLE_UPLOADS = 1;   # Default: No uploads.

#-#############################
# Methods.
sub new {
    #
    # Params: [ -post_max=>, -disable_uploads=>, -auto_escape=> ]
    #
    # Pre:
    # - -post_max is the ceiling on the size of POSTings, in bytes.
    #   The default for LibWeb::CGI is 100 Kilobytes.
    # - -disable_uploads, if non-zero, will disable file uploads completely
    #   which is the default for LibWeb::CGI.
    # - -auto_escape determines whether the text and labels that you provide
    #   for form elements are escaped according to HTML rules.  Non-zero value
    #   will enable auto escape, and undef will disable auto escape (default
    #   for LibWeb::CGI).
    #
    my ($class, $Class, $self, $rc, $post_max, $disable_uploads, $auto_escape);
    $class = shift;
    $Class = ref($class) || $class;

    ($rc, $post_max, $disable_uploads, $auto_escape) =
      $Class->rearrange( ['RC', 'POST_MAX', 'DISABLE_UPLOADS', 'AUTO_ESCAPE'], @_ );
    
    # Set up base class: CGI accordingly.
    $CGI::POST_MAX = $post_max if defined($post_max);
    $CGI::DISABLE_UPLOADS = $disable_uploads if defined($disable_uploads);

    # Inherit instance variables from the base class.
    $self = $Class->CGI::new();
    bless($self, $Class);

    # This doesn't work.  Some HTMLs still printed
    # out as escaped.  I don't know why.
    ($auto_escape) ? $self->autoEscape( $auto_escape ) :
                     $self->autoEscape( undef );

    # Any necessary initialization.
    #$self->_init($rc);
    
    # Returns a reference to this object.
    return $self;
}

#sub _init {
#    #
#    # Params: $rc
#    #
#    # Pre:
#    # - $rc is absolute path to the rc file for LibWeb.
#    #
#    # Initialization whenever an object of this class is created.
#    # Put site customizations here to override several CGI.pm's variables.
#    #
#    my ($self, $key, $value);
#    $self = shift;

#    # Instance variables for this class.
#    $self->{__PACKAGE__.'.core'} = new LibWeb::Core(shift);

#    # A work-around to inherit LibWeb.pm instance variables without doing MI.
#    while ( ($key,$value) = each (%LibWeb::Core::RC) ) {
#	$self->{__PACKAGE__.$key} = $value
#	  unless exists $self->{__PACKAGE__.$key};
#    }
#}

sub DESTROY {}

sub header {
    my $self = shift;
    #$self->delete_all();
    #$self->autoEscape(undef);
    if (@_) { return $self->SUPER::header(@_); }
    else { 
	my $crlf = $LibWeb::Core::RC{CRLF} || "\n\n";
	return "Content-Type: text/html$crlf$crlf";
    }
}

sub is_param_not_null {
    my $self = shift;
    return ( defined($_[0]) && ($_[0] ne "") && ($_[0] ne " ") );
}

sub parameter {
    #
    # Sample usage: $this->parameter(cgi_parameter).
    #
    # Pre:
    # 1. cgi_parameter is the parameter passed by either `GET' or `POST'.
    #
    # Post:
    # 1. If cgi_parameter is a mandatory form value (the ones without `.' as prefix
    #    in the parameter's name) and it is null, print an error message and abort
    #    the program.
    # 2. Return the value of the parameter.
    #
    my ( $self, $key, $value, $param_is_not_null );
    $self = shift;
    $key = shift;
    $value = $self->CGI::param($key);

    # Check for denial of service attacks.
    # CGI::cgi_error() is available since CGI 2.47.
    # Where is CGI::cgi_error()??  It's supported pre CGI3, but seems to be
    # disappeared in new release of CGI.pm 3.01 alpha (24/04/2000).
    # Need to apply patch here if CGI version is < 2.47 or >= 3.01 alpha.
    eval {
	$self->fatal( -msg => 'Invalid post.  Post too large.',
		      -alertMsg => "413 POST too large for CGI param: $key",
		      -helpMsg => $self->{HHTML}->post_too_large() )
	  if ( !$value && $self->cgi_error() );
    };
                                             

    # Check to see if mandatory cgi form values are non-null.
    $param_is_not_null = $self->is_param_not_null($value);
    unless ($key =~ m:^[.].*$:) {
	unless ( $param_is_not_null ) {
	    $key =~ s:[_]+: :g;
	    $self->fatal(-msg => ucfirst($key)." not entered.",
			 -alertMsg => "$key not entered.",
			 -helpMsg => $LibWeb::Core::RC{HHTML}->hit_back_and_edit()
			);
	}
    }

    # Return undef for non-mandatory cgi parameter's value if
    # it's not entered by user.
    return undef unless($param_is_not_null);

    # Sanitize all html tags.
    #$value = $self->sanitize(-html => $value) if defined($value);
    return $value;
}

sub redirect {
    #
    # Params: -url=> [, -cookie=> ].
    # e.g. 'http://www.your_site.org/help.html'  or '/help.html'.
    #
    # Post:
    # 1. Redirect the client Web browser to the specified page.
    #
    my ($self, $url, $cookie);
    $self = shift;
    ($url, $cookie) = $self->rearrange( ['URL', 'COOKIE'], @_ );

    # Append 'http://' to the url to make sure redirect work.
    unless ($url =~ m"^http://") {
	# remove front slash of url.
	#$url =~ s:^[/]::;
	chop $self->{URL_ROOT};
	$url = $self->{URL_ROOT} . $url;
    }

    print $self->SUPER::redirect( -url => $url, -cookie => $cookie );
#    $self->send_cookie($cookie) if defined($cookie);
#    print "Status: 302 Moved\nLocation: $url\n\n" if defined($url);
#    #print "Content-Type: text/html\n\n";
    exit(0);
}

sub send_cookie {
    shift;
    LibWeb::Core->new()->send_cookie(@_);
}

sub fatal {
    shift;
    LibWeb::Core->new()->fatal(@_);
}

sub sanitize {
    shift;
    LibWeb::Core->new()->sanitize(@_);
}

1;
__DATA__

1;
__END__

=head1 NAME

LibWeb::CGI - Extra cgi supports for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

LibWeb::Core

=back

=head1 ISA

=over 2

=item *

CGI

=item *

LibWeb::Class

=back

=head1 SYNOPSIS

  use LibWeb::CGI;
  my $q = new LibWeb::CGI();

  my $parameter = $q->parameter('cgi_param_to_fetch');

  my $param = $q->param('cgi_param_to_fetch');

  print $q->header();

  $q->redirect( -url => '/cgi-bin/logout.cgi', -cookie => 'auth=0' );

  $q->send_cookie( [$cookie1, $cookie2] );

  $q->sanitize( -text => $user_input, -allow => ['_', '-'] );

  $q->fatal(
             -msg => 'Password not entered.',
             -alertMsg => '$user did not enter password!',
             -helpMsg => \('Please hit back and edit.')
           );

=head1 ABSTRACT

This class ISA the vanilla CGI.pm to provide some additional features.
It is still considered to be experimental but used internally by
LibWeb::Session and LibWeb::Admin.

The current version of LibWeb::CGI is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. MAX_LOGIN_ATTEMPT_ALLOWED) are those
variables set through LibWeb's rc file.  Please read L<LibWeb::Core>
for more information.  `Sanitize' means escaping any illegal character
possibly entered by user in a HTML form.  This will make Perl's taint
mode happy and more importantly make your site more secure.
Definition for illegal characters is given in L<LibWeb::Core>.  All
`error/help messages' mentioned can be found at L<LibWeb::HTML::Error>
and they can be customized by ISA (making a sub-class of)
LibWeb::HTML::Default.  Please see L<LibWeb::HTML::Default> for
details.  Method's parameters in square brackets means optional.

=head1 DESCRIPTION

=head2 METHODS

B<new()>

args: [ -post_max=>, -disable_uploads=>, -auto_escape=> ]

=over 2

=item *

C<-post_max> is the ceiling on the size of POSTings, in bytes.  The
default for LibWeb::CGI is 100 Kilobytes.

=item *

C<-disable_uploads>, if non-zero, will disable file uploads completely
which is the default for LibWeb::CGI.

=item *

C<-auto_escape> determines whether the text and labels that you
provide for form elements are escaped according to HTML rules.
Non-zero value will enable auto escape, and undef will disable auto
escape (default for LibWeb::CGI).

=back

B<header()>

If you provide parameter to that method, it will delegate to the
vanilla CGI's header(); otherwise, it will print out "Content-Type:
text/html$CRLF$CRLF" immediately (faster?).  $CRLF will depend on the
machine you are running LibWeb and LibWeb will determine it
automatically.

B<parameter()>

  my $param = $q->parameter('cgi_parameter_to_fetch');

=over 2

=item *

`cgi_parameter_to_fetch' is the parameter passed by either `GET' or
`POST' via a HTML form.

=item *

If `cgi_parameter_to_fetch' is a mandatory form value (one without `.' 
as prefix in the parameter's name) and it is null, it will print out
an error message, abort the program and send the site administrator an
alert e-mail.  It is intended so save the effort to check whether the
user has entered something for mandatory HTML form values.  To use
this nice feature, you name mandatory form value without `.' as
prefix, for example,

  <input type="text" name="email">

For non-mandatory form values, you name them by attaching `.' as a
prefix to skip the test, for example,

  <input type="text" name=".salary_range">

If you find this not really helpful, you should use the vanilla
param() which is totally unaltered in LibWeb::CGI.  For example,

  my $param = $q->param('param_to_fetch');

and LibWeb::CGI will delegate the call to the vanilla CGI's param().
Another reason to use parameter() (or not to use it) is that it
automatically checks for any possible denial of service attack by
calling CGI::cgi_error().  If the POST is too large, it will print out
an error message and send an e-mail alerting the site administrator.
CGI::cgi_error() is available since CGI 2.47 but seems to be
disappeared in new release of CGI.pm 3.01 alpha (24/04/2000).


=back

B<redirect()>

Params:

  -url=> [, -cookie=> ]

This will redirect the client web browser to the specified url and
send it the cookie specified.  An example of a cookie to pass to that
method will be,

  $cookie1 = 'auth1=0; path=/; expires=Thu, 01-Jan-1970 00:00:01 GMT';
  $cookie2 = 'auth2=0; path=/; expires=Thu, 01-Jan-1970 00:00:01 GMT';

  $q->redirect(
               -url => '/logged_out.htm',
               -cookie => [ $cookie1, $cookie2 ]
              );

For C<-cookie>, you can pass either a scalar or an ARRAY reference.
This method will eventually delegate to the vanilla CGI's redirect().
Why bother doing this is because the vanilla CGI's redirect() does not
guarantee to work if you pass relative url; whereas
LibWeb::CGI::redirect() guarantees that partial url will still work.

B<send_cookie()>

This delegates to LibWeb::Core::send_cookie().  See L<LibWeb::Core>.

B<fatal()>

This delegates to LibWeb::Core::fatal().  See L<LibWeb::Core>.

B<sanitize()>

This delegates to LibWeb::Core::sanitize().  See L<LibWeb::Core>.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=over 2

=item Lincoln Stein (lstein@cshl.org)

=back

=head1 BUGS

=head2 Bug number 1

When you delegate subroutine calls within a cgi script,
$q->param(_variable_) or $q->parameter(_variable_) may not give you
the value of C<_variable_> even you have passed a value for that
variable in a HTML form.  I do not know why.  My two workarounds,

=over 2

=item *

Instantiate another CGI or LibWeb::CGI object within the subroutine
where you want to fetch the parameter and use that object to call
C<param()> or C<parameter()>, or

=item *

Initiate all CGI variables and/or fetch all CGI parameters at the
beginning of your script.

=back

=head2 Bug number 2

B<new()>

args: [ -post_max=>, -disable_uploads=>, -auto_escape=> ]

The C<-auto_escape> doesn't seems to work as expected.  Hopefully it
will be resolved after I get a better understanding of how auto escape
works in the vanilla CGI.

=head2 Bug number 3

There is no selfloaded method in LibWeb::CGI since whenever I try to
put ``use SelfLoader;'' in this module, it just doesn't work well with
the vanilla CGI.  This has to be figured out.

Miscellaneous OO issues with the vanilla CGI have yet to be resolved.

=head1 SEE ALSO

L<CGI>, L<LibWeb::Class>, L<LibWeb::Core>, L<LibWeb::HTML::Default>,
L<LibWeb::HTML::Error>.

=cut
