package Egg::Plugin::Cache::UA;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UA.pm 306 2008-03-07 10:55:58Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Plugin::LWP /;

our $VERSION = '1.01';

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_cache_ua} ||= {};
	$conf->{content_type}       ||= 'text/html';
	$conf->{content_type_error} ||= 'text/html';
	$conf->{cache_name}    || die q{ I want setup 'cache_name'. };
	$conf->{cache_expires} ||= undef;
	my $allows= $conf->{allow_hosts} || die q{ I want setup 'allow_hosts' };
	my $regex = join '|',
	   map{quotemeta}(ref($allows) eq 'ARRAY' ? @$allows: $allows);

	no warnings 'redefine';
	*Egg::Plugin::Cache::UA::handler::referer_check= sub {
		my($self)= @_;
		my $referer= $self->e->request->referer || return 1;
		$referer=~m{^https?\://(?:$regex)} ? 1: 0;
	  };

	$e->next::method;
}
sub cache_ua {
	$_[0]->{cache_ua} ||= Egg::Plugin::Cache::UA::handler->new
	                       ($_[0], $_[0]->config->{plugin_cache_ua});
}

package Egg::Plugin::Cache::UA::handler;
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Base /;

*remove= \&delete;

sub new {
	my $self= shift->SUPER::new(@_);
	$self->{cache}= {};
	$self;
}
sub get {
	my($self, $url, $option)= __get_args(@_);
	$self->referer_check || return 0;
	my $result= $self->cache($option->{cache_name})->get($url) || do {
		my %attr;
		my $method= uc $option->{request_method} || 'GET';
		if (my $res= $self->e->ua->request( $method => $url )) {
			if ($res->is_success) {
				$attr{is_success}= 1;
				if (my $status= $res->status_line) {
					$attr{status}= $status if $status!~/^200/;
				}
				my @content_type= $res->header('content_type') || "";
				$attr{content_type}= $content_type[0]
				                  || $option->{content_type};
				$attr{content}= $res->content || "";
			} else {
				$attr{status}= $res->status_line || '403 Forbidden';
				$attr{error} = " Error in $url : ". $res->status_line;
			}
		} else {
			$attr{status}= "408 Request Time-out";
			$attr{error} = " $url doesn't return the response. ";
		}
		$attr{content_type} ||= $option->{content_type_error};
		$attr{content}      ||= "";
		$self->cache->set($url, \%attr, $option->{cache_expires});
		$attr{no_hit}= 1;
		\%attr;
	  };
}
sub output {
	my($self, $url, $option)= __get_args(@_);
	my $cache= $self->get($url, $option) || {
	  no_hit       => 1,
	  status       => '500 Internal Server Error',
	  content_type => $option->{content_type_error},
	  error        => ' referer is illegal.',
	  };
	my $response= $self->e->response;
	$response->headers->header('X-CACHE-UA'=> 'hit')
	         unless $cache->{no_hit};
	$response->is_expires($option->{expires})
	         if $option->{expires};
	$response->last_modified($option->{last_modified})
	         if $option->{last_modified};
	$response->status($cache->{status}) if $cache->{status};
	$response->content_type($cache->{content_type});
	$cache->{content}= $cache->{error} if $cache->{error};
	$response->body(\$cache->{content});
}
sub delete {
	my $self= shift;
	my($name, $url)= @_
	   ? (@_ > 1 ? @_: (undef, shift)): croak q{ I want url. };
	$self->cache($name)->remove($url);
}
sub cache {
	my $self= shift;
	my $name= shift || $self->param('cache_name');
	$self->{cache}{$name} ||= $self->e->model($name);
}
sub __get_args {
	my $self  = shift;
	my $url   = shift || croak q{ I want URL. };
	my %option= (
	  %{$self->params},
	  %{ $_[1] ? {@_}: ($_[0] || {}) },
	  );
	($self, $url, \%option);
}

1;

__END__

=head1 NAME

Egg::Plugin::Cache::UA - The result of the WEB request is cached. 

=head1 SYNOPSIS

  package MyApp;
  use Egg qw/Cache::UA/;
  .......
  .....

  package MyApp::Dispatch;
  .........
  
  MyApp->dispatch_map(
    ...........
    cache=> {
      google => sub {
        my($e)= @_;
        $e->cache_ua->output('http://xxx.googlesyndication.com/pagead/show_ads.js');
        },
      brainer=> sub {
        my($e)= @_;
        $e->cache_ua->output('http://xxx.brainer.jp/ad.js');
        },
      },
    );

=head1 DESCRIPTION

This module caches and recycles the request result of L<Egg::Plugin::LWP>.

Especially, I think that it is effective in the contents match system advertisement
etc. of the type that returns the JAVA script.
It becomes difficult to receive the influence of the response speed of advertisement 
ASP server by the action of cashe.

It is necessary to setup L<Egg::Model::Cache> to use it, and to set the label name
to acquire the model to 'cache_name' of the configuration.

This module has succeeded to L<Egg::Plugin::LWP>.

=head1 CONFIGURATION

The configuration is set by 'plugin_cache_ua'.

  package MyApp;
  
  __PACKAGE__->startup(
    plugin_cache_ua => {
      cache_name         => 'cache_model_name',
      allow_hosts        => [qw/ mydomain.name /],
      content_type       => 'text/html',
      content_type_error => 'text/html',
      cache_expires      => 60* 60,
      expires            => '+1d',
      last_modified      => '+1d',
      },
    );

=head3 allow_hosts

The host name that permits the use of cashe is set with ARRAY.

It is necessary to set this.

  allow_hosts => [qw/ www.domain.com domain.com domain.net /],

When the regular expression is set, the access is not accepted because each value
is put on quotemeta.

When it is not possible to acquire it, processing is continued disregarding this
setting though it checks with HTTP_REFERER of the environment variable because 
the thing that cannot be acquired under the influences of the proxy and 
the security software, etc. can break out, too.

=head3 content_type

Default of sent contents type.

This setting is substitution when the contents type is not obtained because of the 
WEB request.

'text/html' is used if it unsets it.

  content_type=> 'text/javascript',

=head3 content_type_error

Contents type used when data is not obtained by some errors' occurring by WEB request.

Default is 'text/html'.

=head3 cache_name

Model name of cashe used.

The model name to acquire the cashe object set up with L<Egg::Model::Cache> is set.

There is no default. Please set it.

=head3 cache_expires

It is a value passed to the third argument of 'set' method of cashe.

This is a setting that assumes the use of L<Cache::Memcached>.

  cache_expires=> 60* 60,  # It is effective for one hour.

It is not necessary to set it usually.

Validity term is done depending on the cashe model used.

=head3 expires or last_modified

The response header to press the cashe of the browser side is set.

It specifies it by the form used by CGI module. 

  expires       => '+1d',
  last_modified => '+1d',

=head3 request_method

It is request a method when WEB is requested.

Default is 'GET'.

I think that you should specify this when you are putting necessary in 'get' 
method as undefined usually.

  $e->cache_ua->get( 'http://.....' => { request_method=> 'POST' } );

=head1 NAME

=head2 cache_ua

The Egg::Plugin::Cache::UA::handler object is returned.

 my $cache_ua= $e->cache_ua;

=head1 HADLER METHODS

=head2 get ( [URL], [OPTION] )

The request is sent to URL.

The content is returned if becoming a hit to cashe.

OPTION overwrites the default.

The HASH reference returns to the return value without fail.

  my $res= $e->cache_ua->get('http://domainname/');
  
  if ($res->{is_success}) {
    $e->stash->{request_content}= \$res->{content};
  } else {
    $e->finished($res->{status} || 500);
  }

The content of content is set in $e-E<gt>response-E<gt>body. When content is not
 obtained by the error's occurring by the request, the content of error is set.

Because $e-E<gt>response-E<gt>body is defined, the processing of view comes to 
be passed by the operation of Egg.

The content of the returned HASH reference is as follows.

=head3 is_success

Succeeding in the request is true.

=head3 status

There is a status line obtained because of the response.

=head3 content_type

There is a contents type obtained because of the response.

Instead, the default of the setting enters when the contents type is not obtained.

=head3 content

There is a content of contents obtained because of the response. 

=head3 error

One the respondent error message enters when is_success is false.

=head3 no_hit

When not becoming a hit to cashe, it becomes true.

=head2 output ( [URL], [OPTION] )

Content is set directly to L<Egg::Response> based on information obtained by the
get method.

The response header set here is as follows.

=head3 X-CACHE-UA

When no_hit is only false, it is set.
In a word, the thing that becomes a hit to cashe is shown.

=head3 expires or last_modified

It is set based on the setting.

=head3 status

The obtained status line is set.

=head3 content_type

The obtained contents type is set.

=head2 delete ( [URL] )

The data of URL is deleted from cashe.

  $e->delete('http://domainname/');

=over 4

=item * Alias = remove.

=back

=head2 cache ([LABEL_NAME])

The cashe object set to 'cache_name' is returned usually.

When LABEL_NAME is specified, an arbitrary model object is returned.

 my $cache= $e->cache_ua->cache('cache_label');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Response>,
L<Egg::Plugin::LWP>,
L<Egg::Model::Cache>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

