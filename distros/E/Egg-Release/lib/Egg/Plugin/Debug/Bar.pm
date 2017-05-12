package Egg::Plugin::Debug::Bar;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Bar.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

my $debug_bar;
sub _setup {
	my($e)= @_;
	unless ($e->debug) {
		$debug_bar= sub {};
		return $e->next::method;
	}
	my $name_uc= $e->uc_namespace;
	my $c= $e->config->{plugin_debug_bar} ||= {};
	my $reboot_button;
	if ( my $n= $ENV{"${name_uc}_FCGI_REBOOT"}
	         || $ENV{"${name_uc}_PPCGI_REBOOT"} ) {
		my $name= $n ne 1 ? $n: 'reboot';
		$reboot_button= sub {
			<<END_BUTTON;
<input onclick="location.href='$_[0]?${name}=1'" type="button" value="Reboot" class="debug_button" />
END_BUTTON
		  };
	}
	$reboot_button ||= sub {};
	$debug_bar= sub {
		my($egg)= @_;
		my $ctype;
		return 0 if ($ctype= $e->response->content_type and $ctype!~m{^text/html});
		my $body= $egg->response->body || return 0;
		$$body=~m{<html.*?>.+</html.*?>}is || return 0;
		my $c= $egg->config->{plugin_debug_bar};
		my $path= $egg->req->path;
		my $bar= <<END_BAR;
<style type="text/css">
@{[ $c->{style} || $egg->_debugbar_style ]}
</style>
<div id="debug_bar">
<div style="float:right">
<input onclick="history.back()" type="button" value="Previous Page" class="debug_button" />
<input onclick="location.reload()" type="button" value="Reload" class="debug_button" />
<input onclick="location.href='${path}'" type="button" value="Rerequest" class="debug_button" />
@{[ $reboot_button->($path) ]}
</div>
Egg::Plugin::Debug::Bar $VERSION
</div>
END_BAR
		$$body=~s{^(.*?<body.*?>)} [$1$bar]is;
	  };
	$e->next::method;
}
sub _output {
	my($e)= @_;
	$debug_bar->($e);
	$e->next::method;
}
sub _debugbar_style {
	<<END_STYLE;
#debug_bar {
	height:18px;
	background:#CCC;
	border-bottom:#555 solid 1px;
	margin:0px 0px 10px 0px;
	font:bold 12px Times,sans-serif;
	text-align:left;
	padding:2px 2px 2px 10px;
	}
#debug_bar .debug_button {
	width:100px;
	height:18px;
	background:#AAA;
	border:#777 solid 1px;
	cursor:pointer;
	}
END_STYLE
}

1;

__END__

=head1 NAME

Egg::Plugin::Debug::Bar - Plugin to bury bar for debugging under contents for Egg. 

=head1 SYNOPSIS

  use Egg qw/ Debug::Bar /;

  # dispatch.fcgi
  
  #!/usr/local/bin/perl
  BEGIN {
    $ENV{EXAMPLE_REQUEST_CLASS} ||= 'Egg::Request::FastCGI';
  #  $ENV{EGGRELEASE_FCGI_LIFE_COUNT} = 0;
  #  $ENV{EGGRELEASE_FCGI_LIFE_TIME}  = 0;
    $ENV{EGGRELEASE_FCGI_RELOAD}     = 1;
    };
  use lib "/path/to/MyApp/lib";
  use MyApp;
  MyApp->handler;

=head1 DESCRIPTION

This plugin buries the bar for debugging under the upper part of contents at debug
mode.

When it is operated by FastCGI, this is convenient. The useful function that can
be used in other platforms is not provided.

$ENV{EGGRELEASE_FCGI_RELOAD} of the trigger script for FastCGI is set and used.
Then, the button named Reboot appears in the bar.
When the FastCGI process falls and it will be requested that this button be
pushed when the application is developed next time, come do the reload of the
project.

It comes do not to have to reactivate the WEB server when developing by this.

Especially, it is L<Module::Refresh> in FastCGI. However, I think it is convenient
when this plugin is used by Ki or do not exist.

Besides, it might be good to set $ENV{EGGRELEASE_FCGI_LIFE_COUNT} and
$ENV{EGGRELEASE_FCGI_LIFE_TIME}, etc.
Please see at the document of L<Egg::Request::FastCGI> in detail.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request::FastCGI>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

