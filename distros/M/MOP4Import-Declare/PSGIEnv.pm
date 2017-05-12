package MOP4Import::PSGIEnv;
use strict;
my @PSGI_FIELDS;
BEGIN {
  @PSGI_FIELDS
    = qw/
	  HTTPS
	  GATEWAY_INTERFACE
	  REQUEST_METHOD
	  SCRIPT_NAME
	  SCRIPT_FILENAME
	  DOCUMENT_ROOT

	  PATH_INFO
	  PATH_TRANSLATED
	  REDIRECT_STATUS
	  REQUEST_URI
	  DOCUMENT_URI

	  QUERY_STRING
	  CONTENT_TYPE
	  CONTENT_LENGTH

	  SERVER_NAME
	  SERVER_PORT
	  SERVER_PROTOCOL
	  HTTP_USER_AGENT
	  HTTP_REFERER
	  HTTP_COOKIE
	  HTTP_FORWARDED
	  HTTP_HOST
	  HTTP_PROXY_CONNECTION
	  HTTP_ACCEPT

	  HTTP_ACCEPT_CHARSET
	  HTTP_ACCEPT_LANGUAGE
	  HTTP_ACCEPT_ENCODING

	  REMOTE_ADDR
	  REMOTE_HOST
	  REMOTE_USER
	  HTTP_X_REAL_IP
	  HTTP_X_CLIENT_IP
	  HTTP_X_FORWARDED_FOR

	  psgi.version
	  psgi.url_scheme
	  psgi.input
	  psgi.errors
	  psgi.multithread
	  psgi.multiprocess
	  psgi.run_once
	  psgi.nonblocking
	  psgi.streaming
	  psgix.session
	  psgix.session.options
	  psgix.logger
       /;
}

use MOP4Import::Declare -as_base, qw/Opts/
  , [fields => @PSGI_FIELDS]
  , [alias => Env => __PACKAGE__] # XXX: Not [as => 'Env'].
  ;

sub import {
  (my $myPack, my (@more_fields)) = @_;

  my Opts $opts = Opts->new([caller]);

  my $name = 'Env';

  $opts->{basepkg} = $myPack->$name();

  my $innerClass = join("::", $opts->{destpkg}, $name);

  $myPack->declare_alias($opts, $opts->{destpkg}, $name, $innerClass);

  $myPack->dispatch_declare($opts->with_objpkg($innerClass)
			    , $opts->{destpkg}
			    , [base => $opts->{basepkg}]
			    , [fields => @more_fields]
			  );
}

1;

__END__

=head1 NAME

MOP4Import::PSGIEnv - define Env class for PSGI, with extensions.

=head1 SYNOPSIS

  use MOP4Import::PSGIEnv qw/mypsgi.extension/;
  
  return sub {
    (my Env $env) = @_;
    return [200, [], ["PATH_INFO is ", $env->{PATH_INFO}
                    , extension => $env->{'mypsgi.extension'}
                  ]];
  }

=head1 DESCRIPTION

MOP4Import::PSGIEnv is yet another protocol implementation
of L<MOP4Import|MOP4Import::Intro> family.

This module simply defines C<Env> class.
Standard L<PSGI $env|PSGI/The Environment> is already defined.

