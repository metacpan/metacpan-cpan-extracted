package Egg::Model::Auth::Session::FileCache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FileCache.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Cache::FileCache;
use UNIVERSAL::require;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	my $config= $class->config;
	my $c= $config->{filecache} ||= {};
	$c->{cache_root} ||= $e->config->{dir}{cache};
	$c->{namespace}  ||= do {
		my $pkg= ref($class) || $class;
		$pkg=~m{([^\:]+)\:+[^\:]+$};
		"auth_". lc($1);
	  };
	$c->{cache_depth} ||= 3;
	$c->{default_expires_in} ||= $config->{cache_interval};
	my $len= $c->{session_id_length} ||= 32;
	unless ($class->can('make_session_id')) {
		my $function= Digest::SHA1->require ? 'Digest::SHA1::sha1_hex': do {
			$@=~m{} and die $@;
			Digest::MD5->require or die $@;
			'Digest::MD5::md5_hex';
		  };
		no strict 'refs';  ## no critic.
		no warnings 'redefine';
		*{"${class}::make_session_id"}= sub {
			substr( &$function(time. $$. rand(1000). {}), 0, $len );
		  };
	}
	$class->mk_accessors('session_id');
	$class->next::method($e);
}
sub filecache {
	$_[0]->{filecache} ||= Cache::FileCache->new($_[0]->config->{filecache});
}
sub get_session {
	my($self)= @_;
	my $id   = $self->{session_id} ||= $self->get_bind_id || return 0;
	my $data = $self->filecache->get($id) || return 0;
	my $tmp  = $data->{___session_id} || return 0;
	$id eq $tmp ? $data : 0;
}
sub set_session {
	my $self= shift;
	my $data= shift || croak 'I want session data.';
	my $id= $self->{session_id} ||= $self->make_session_id;
	$data->{___session_id}= $id;
	$self->filecache->set( $id => $data );
	$self->set_bind_id($id);
	$data;
}
sub remove_session {
	my $self= shift;
	my $id= $self->session_id || return 0;
	$self->filecache->remove($id);
	$self->next::method($id);
}

1;

=head1 NAME

Egg::Model::Auth::Session::FileCache - Session management for AUTH component.

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    filecache => {
      cache_root  => MyApp->path_to('cache'),
      namespace   => 'AuthSession',
      cache_depth => 3,
      .............
      ......
      },
    );
  
  __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

=head1 DESCRIPTION

An easy session function is offered to the AUTH component by L<Cache::FileCache>.

To use it, L<Cache::FileCache> is set by 'filecache' of the configuration.
And, 'FileCache' is set by 'setup_session' method.

If neither it nor Bind system component are set up, L<Egg::Model::Auth::Bind::Cookie>
 is specified with the client following 'FileCache' because the mistress cannot injure.

  __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

This module doesn't come to annul the session data positively.
Please set by the configuration concerning auto_purge or receive the L<Cache::FileCache>
object from 'filecache' method and control data.

=head1 METHODS

=head2 filecache

L<Cache::FileCache> The object is returned.

=head2 make_session_id

Session ID is generated and it returns it.

Session ID is generated with L<Digest::SHA1> or L<Digest::MD5>.

The character string length of session ID can be set by 'session_id_length' of
 the configuration.

The AUTH controller must Obarraid it this method when you want to generate 
original session ID.

=head2 get_session ([SESSION_ID])

The session data corresponding to SESSION_ID is returned.

=head2 set_session ([SESSION_DATA_HASH], [SESSION_ID])

The session data is preserved. And, session ID is passed to 'set_bind_id'.

When SESSION_ID is omitted, new session ID is received from 'make_session_id' method.

=head2 remove_session ([SESSION_ID])

The session data corresponding to SESSION_ID is annulled.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Bind::Cookie>,
L<Cache::FileCache>,
L<UNIVERSAL::require>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

