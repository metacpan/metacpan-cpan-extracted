package Egg::Plugin::Response::Redirect;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Redirect.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

{
	no warnings 'redefine';
	*Egg::Response::handler::redirect_body= sub { shift->e->redirect_body(@_) };
  };

sub _setup {
	my($e)= @_;
	my $conf = $e->config->{plugin_response_redirect} ||= {};
	my $style= $conf->{style} ||= {};

	$conf->{default_url}  ||= '/';
	$conf->{default_wait} ||= 0;
	$conf->{default_msg}  ||= 'Processing was completed.';

	$style->{body}
	  ||= q{ background:#FFEDBB; text-align:center; };
	$style->{h1}
	  ||= q{ font:bold 20px sans-serif; margin:0px; margin-left:0px; };
	$style->{div}
	  ||= q{ background:#FFF7ED; padding:10px; margin:50px;}
	    . q{ font:normal 12px sans-serif; border:#D15C24 solid 3px;}
	    . q{ text-align:left; };

	$e->next::method;
}
sub redirect_body {
	my $e= shift;
	$e->finished('200 OK');
	$e->response->body($e->__redirect_body(@_));
}
sub __redirect_body {
	my $e= shift;
	my($res, $c)= ($e->response, $e->config);
	my $cr    = $c->{plugin_response_redirect};
	my $style = $cr->{style};

	my $url   = shift || $cr->{default_url};
	my $msg   = shift || $cr->{default_msg};
	my $attr  = $_[0] ? (ref($_[0]) ? $_[0]: {@_}): {};
	my $wait  = defined($attr->{wait}) ? $attr->{wait}: $cr->{default_wait};
	my $onload= $attr->{onload} ? qq{ onload="$attr->{onload}"}: "";
	my $more  = $attr->{more} || "";
	my $alert = ! $attr->{alert} ? "": <<END_SCRIPT;
<script type="text/javascript"><!-- //
window.onload= alert('${msg}');
// --></script>
END_SCRIPT

	my $body_style= $attr->{body_style} || $style->{body};
	my $div_style = $attr->{div_style}  || $style->{div};
	my $h1_style  = $attr->{h1_style}   || $style->{h1};

	my $clang = $res->content_language($c->{content_language} || 'en');
	my $ctype = $res->content_type($c->{content_type} || 'text/html');

	<<END_OF_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="${clang}">
<head>
<meta http-equiv="content-language" content="${clang}" />
<meta http-equiv="Content-Type" content="${ctype}" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="refresh" content="${wait};url=${url}" />
${alert}
<style type="text/css">
body { ${body_style} }
div  { ${div_style} }
h1   { ${h1_style} }
</style>
</head>
<body${onload}>
<div>
<h1>${msg}</h1>
<a href="${url}">- Please click here when forwarding fails...</a>
</div>
${more}
</body>
</html>
END_OF_HTML
}

1;

__END__

=head1 NAME

Egg::Plugin::Response::Redirect - Output of redirect screen etc. 

=head1 SYNOPSIS

  use Egg qw/ Response::Redirect /;
  
  __PACKAGE__->egg_startup(
    plugin_redirect => {
      default_url  => '/',
      default_wait => 0,
      default_msg  => 'Processing was completed.',
      style => {
        body => ' ..... ',
        h1   => ' ..... ',
        div  => ' ..... ',
        },
      },
    );
  
  # redirect screen is output and processing is ended.
  $e->redirect_body('/hoge_page', 'complete ok.', alert => 1 );
  
  # The HTML source of redirect screen is acquired.
  my $html= $e->redirect_body_source('/hoge_page', 'complete ok.', alert => 1 );

=head1 DESCRIPTION

It is a plugin that outputs the redirect screen.

=head1 CONFIGURATION

The configuration is done by 'plugin_redirect'.

  plugin_redirect => {
   ........
   ...
   },

=head2 default_url => [DEFAULT_URL]

When URL at the redirect destination is unspecification, it uses it.

Default is '/'.

=head2 default_wait => [WAIT_TIME]

When waiting time until redirecting is generated is unspecification, it uses it.

Default is '0',

=head2 default_msg => [REDIRECT_MESSAGE]

When redirect  message is unspecification, it uses it.

Default is 'Processing was completed.'.

=head2 style => [HASH]

The screen style is set with HASH.

=head3 body => [BODY_STYLE]

The entire basic setting of screen.

 Default:
   background  : #FFEDBB;
   text-align  : center;

=head3 h1 => [H1_STYLE]

Style of E<lt>h1E<gt>.

 Default:
   font        : bold 20px sans-serif;
   margin      : 0px;
   margin-left : 0px;'.

=head3 div => [DIV_STYLE]

Style of E<lt>divE<gt>.

 Default:
   background  : #FFF7ED;
   padding     : 10px;
   margin      : 50px;
   font        : normal 12px sans-serif;
   border      : #D15C24 solid 3px;
   text-align  : left;

=head1 METHODS

=head2 redirect_body_source ( [URL], [MESSAGE], [OPTION_HASH] )

The HTML source of redirect screen is returned.

When URL is unspecification, 'default_url' of the configuration is used.

When MESSAGE is unspecification, 'defautl_msg' of the configuration is used.

The following options are accepted with OPTION_HASH.

=head3 wait => [WAIT_TIME]

Waiting time until redirecting is generated.

'default_wait' of the configuration is used at the unspecification.

  $e->redirect_body_source(0, 0, wait => 1 );

=head3 alert => [BOOL]

When the screen is displayed, the alert of the JAVA script is generated.

MESSAGE is displayed in this alert.

  $e->redirect_body_source(0, 0, alert => 1 );

=head3 onload_func => [ONLOAD_FUNCTION]

Onload is added to E<lt>bodyE<gt> when given.

  $e->redirect_body_source(0, 0, onload_func => 'onload_script()' );

=head3 body_style => [STYLE]

style->{body} of the configuration is used when omitting it.

=head3 h1_style => [STYLE]

style->{h1} of the configuration is used when omitting it.

=head3 div_style => [STYLE]

style->{div} of the configuration is used when omitting it.

=head2 redirect_body ( [URL], [MESSAGE], [OPTION_HASH] )

$e-E<gt>response-E<gt>redirect is setup.

And, the return value of 'redirect_body_source' method is set in $e-E<gt>response-E<gt>body.

The argument extends to 'redirect_body_source' method as it is.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Response>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

