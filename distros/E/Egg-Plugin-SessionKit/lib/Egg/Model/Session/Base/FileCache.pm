package Egg::Model::Session::Base::FileCache;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FileCache.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Cache::FileCache;
use Carp qw/ croak /;

our $VERSION= '3.00';

sub cache { $_[0]->attr->{cache} }

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{filecache} ||= {};
	$c->{cache_root} ||= $e->config->{dir}{cache};
	$c->{namespace}  ||= do {
		my $pkg= ref($class) || $class;
		$pkg=~m{([^\:]+)\:+[^\:]+$};
		"session_". lc($1);
	  };
	$c->{cache_depth} ||= 3;
	$c->{default_expires_in} ||= 60* 60;
	$class->next::method($e);
}
sub TIEHASH {
	my $self= shift->next::method(@_);
	$self->attr->{cache}=
	      Cache::FileCache->new($self->config->{filecache});
	$self;
}
sub restore {
	my $self= shift;
	my $id  = shift || $self->session_id || croak q{I want session id.};
	$self->cache->get($id) || 0;
}
sub insert {
	my $self= shift;
	my $data= shift || croak q{I want session data.};
	my $id  = shift || $self->session_id || croak q{I want session id.};
	$self->cache->set($id, $data);
}
*update= \&insert;

sub delete {
	my $self= shift;
	my $id= shift || croak q{I want session id.};
	$self->cache->remove($id);
	$self;
}

1;

__END__

=head1 NAME

Egg::Model::Session::Base::FileCache - Session management by Cache::FileCache.

=head1 SYNOPSIS

  package MyApp::Model::Sesion;
  
  __PACKAGE__->config(
   filecache => {
     cache_root         => MyApp->path_to('cache'),
     namespace          => 'sessions',
     cache_depth        => 3,
     default_expires_in => (60* 60),
     },
   );
  
  __PACKAGE__->startup(
   Base::FileCache
   ID::SHA1
   Bind::Cookie
   );

=head1 DESCRIPTION

The session data is preserved by using L<Cache::FileCache>.

And, 'Base::DBI' is added to startup of the component module generated with
L<Egg::Helper::Model::Session>. Default is this module.

There is no Store system component needing because Cache::FileCache can treat 
HASH well.

  __PACKAGE__->startup(
   Base::FileCache
   ID::SHA1
   Bind::Cookie
   );

=head1 CONFIGURATION

'filecache' key is set to config of the session component module.

  __PACKAGE__->config(
   filecache => {
    .......
    },
   );

All set items are passed to L<Cache::FileCache>.

see L<Cache::FileCache>.

=head1 METHODS

Because most of these methods is the one that L<Egg::Model::Session> internally
uses it, it is not necessary to usually consider it on the application side.

=head2 cache

The L<Cache::FileCache> object is returned.

=head2 restore ([SESSION_ID])

The session data obtained by received SESSION_ID is returned.

When SESSION_ID is not obtained, it acquires it in 'Session_id' method.

=head2 insert ([SESSION_DATA], [SESSION_ID])

New session data is preserved.

SESSION_DATA is indispensable.

When SESSION_ID is not obtained, it acquires it in 'Session_id' method.

=head2 update ([SESSION_DATA], [SESSION_ID])

The same processing as 'insert' is done.

=head2 delete ([SESSION_ID])

The session data is deleted.

SESSION_ID is indispensable.

  $session->delete('abcdefghijkemn12345');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,
L<Egg::Model::Session::Manager::Base>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Model>,
L<Cache::FileCache>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

