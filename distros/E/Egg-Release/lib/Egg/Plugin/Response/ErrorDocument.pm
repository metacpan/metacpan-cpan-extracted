package Egg::Plugin::Response::ErrorDocument;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ErrorDocument.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

sub _setup {
	my($e)= @_;
	my $c= $e->config->{plugin_response_errordocument} ||= {};
	$c->{view_name} ||= do {
		my $view= $e->config->{VIEW} || die q{ I want setup 'VIEW' };
		ref($view->[0]) eq 'ARRAY' ? $view->[0][0]: $view->[0];
	  };
	$e->is_view($c->{view_name})
	   || die qq{ I want setup VIEW of '$c->{view_name}'. };
	$c->{template} || die q{ I want setup 'template'. };
	my $ignore= $c->{ignore_status} ||= [qw/ 200 301 302 303 304 307 /];
	   $ignore= [$ignore] unless ref($ignore) eq 'ARRAY';
	if (my $in= $c->{include_ignore_status}) {
		splice @$ignore, 0, 0, (ref($in) eq 'ARRAY' ? @$in: $in);
	}
	$c->{ignore_hash}= { map{ $_=> 1 }@$ignore };
	$e->next::method;
}
sub _output {
	my($e)= @_;
	my $status= $e->response->status || return $e->next::method;
	return $e->next::method if $e->request->is_head;
	my $c= $e->config->{plugin_response_errordocument};
	return $e->next::method if $c->{ignore_hash}{$status};
	my $res= $e->response;
	$res->no_cache(1)                 if $c->{no_cache};
	$res->status($c->{always_status}) if $c->{always_status};
	$e->page_title( "$status -". $res->status_string );
	$res->content_type
	  ( $c->{content_type} || $e->config->{content_type} || 'text/html' );
	$e->stash->{response_status}= $status;
	$e->stash->{"status_$status"}= 1;
	$e->view($c->{view_name})->output($c->{template});
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::Response::ErrorDocument? - Plugin that outputs error document.

=head1 SYNOPSIS

  package MyApp;
  use Egg qw/ Response::ErrorDocument /;
  
  __PACKAGE__->egg_startup(
    ...........
    ...
    plugin_response_errordocument=> {
      view_name     => 'mason',
      template      => 'error/document.tt',
      ignore_status => [qw/ 200 301 302 303 304 307 /],
      no_cache      => 1,
      
      },
    );

=head1 DESCRIPTION

It is a plugin to output the error screens such as '404 Not Found' and '500 Inta
rnal Server Error'.

The template for this plugin is needed for use.

The template of the following content is assumed.

  <html>
  <head>
  <title><% $e->page_title %></title>
  </head>
  <body>
  <h1><% $e->page_title %></h1>
  <div>
  %
  % if ($s->{status_401}) {
  %
  This server could not verify that you are authorized to access the document requested. 
  Either you supplied the wrong credentials (e.g., bad password), 
  or your browser doesn't understand how to supply the credentials required.
  %
  % } elsif ($s->{status_403}) {
  %
  You don't have permission to access on this server.
  %
  % } elsif ($s->{status_404}) {
  %
  The requested URL <% $e->request->path %> was not found on this server.
  %
  % } else {
  %
  The server encountered an internal error and was unable to complete your request.
  Please contact the server administrator, 
  %
  % }
  %
  </div>
  </body>
  </html>

Such a template is preserved by a suitable name, and it sets it to 'template' of
the configuration.

=head1 CONFIGURATION

The configuration of this plugin is done by 'plugin_response_errordocument'.

=head2 view_name => [VIEW_NAME]

Name of view that error document outputs.

  view_name => 'Mason',

=head2 template => [TEMPLATE]

Template used to output error document. 

  template => 'document/error.tt',

Thing that is template treatable by view specified by 'view_name'

=head2 ignore_status => [STATUS_ARRAY]

List of status code in which processing of this plugin is passed.

Default is 200,301,302,303,304,307.

  ignore_status => [qw/ 200 301 302 303 304 307 403 /],

=head2 include_ignore_status => [STATUS_ARRAY]

STATUS_ARRAY is added to 'ignore_status'.

  include_ignore_status => 403,

=head2 always_status ([STATUS_CODE])

When the error document is output, the response status is compulsorily made
STATUS_CODE.

Especially, because it tries to output an original error document by the result
code in mod_perl, it is necessary to always return the success code by this
setting.

  always_status => 200,

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View>,
L<Egg::View::Mason>,
L<Egg::View::HT>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

