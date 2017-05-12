package Egg::Model::Session::Manager::TieHash;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TieHash.pm 322 2008-04-17 12:33:58Z lushe $
#
use strict;
use warnings;
use Tie::Hash;
use Carp qw/ croak /;
use base qw/ Egg::Component /;

our $VERSION= '0.03';
our @ISA;

push @ISA, 'Tie::ExtraHash';

sub data       { $_[0]->[0] }
sub attr       { $_[0]->[1] }
sub e          { $_[0]->[1]{e} }
sub session_id { $_[0]->[1]{session_id} }
sub startup    { @_ }

{
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	for my $accessor (qw/ is_new is_update /) {
		*{__PACKAGE__."::$accessor"}= sub {
			my $self= shift;
			return $self->attr->{$accessor} unless @_;
			$self->attr->{$accessor}= shift;
		  };
	}
	for my $accessor
	   (qw/ restore insert update issue_session_id make_session_id /) {
		*{__PACKAGE__."::$accessor"}=
		  sub { die qq{'$accessor' There is no absolute method.} };
	}
	for my $accessor (qw/ get_bind_data set_bind_data /) {
		*{__PACKAGE__."::$accessor"}= sub {};
	}
  };

sub _setup {
	my($class, $e)= @_;
	$class->config->{param_name} ||= 'ss';
	$class->next::method($e);
}
sub TIEHASH {
	my($class, $e, $id)= @_;
	bless [{},
	  { e=> $e, is_new=> 0, is_update=> 0, session_id=> ($id || 0) }],
	  $class;
}
sub STORE {
	my($self, $key, $value)= @_;
	$self->attr->{is_update} ||= 1;
	$self->data->{$key}= $value;
}
sub DELETE {
	my($self, $key)= @_;
	$self->attr->{is_update} ||= 1;
	delete($self->data->{$key});
}
sub init_session {
	my($self)= @_;
	my $id= $self->accept_session_id;
	return $self->_init_param($self->data) if $self->is_new;
	my $data;
	{
		my $tmp= $self->restore($id) || return $self->_remake_session;
		$data= $self->store_decode($tmp) || return $self->_remake_session;
	  };
	return $self->_remake_session
	    if (! $data->{___session_id} or $id ne $data->{___session_id});
	$self->_init_param( $self->[0]= $data );
}
sub change {
	my($self)= @_;
	$self->data->{___session_id}= $self->create_session_id;
	$self;
}
sub clear {
	my($self)= @_;
	$self->[0]= {};
	$self->_remake_session;
	$self;
}
sub accept_session_id {
	my($self)= @_;
	if (my $id= $self->session_id) {
		return ($self->valid_session_id($id) || $self->create_session_id);
	}
	if (my $id= $self->get_bind_data($self->config->{param_name})) {
		if ($self->valid_session_id($id)) {
			$self->attr->{session_id}= $id;
			return $id;
		}
	}
	$self->create_session_id;
}
sub output_session_id {
	my $self= shift;
	my $id  = shift || $self->session_id;
	$self->set_bind_data($self->config->{param_name}, $id);
	$id;
}
sub create_session_id {
	my($self)= @_;
	$self->attr->{is_new}= 1;
	$self->attr->{session_id}= $self->make_session_id;
}
sub _remake_session {
	my($self)= @_;
	$self->create_session_id;
	$self->_init_param( $self->[0]= {} );
}
sub _init_param {
	my($self, $param)= @_;
	$param->{___session_id} ||= $self->session_id;
	unless ($param->{create_time}) {
		$param->{create_time}= time;
		$param->{old_time}= $param->{now_time};
	}
	$param->{now_time}= time;
	$self;
}
sub store_encode     { $_[1] || $_[0]->data }
sub store_decode     { $_[1] || $_[0]->data }
sub valid_session_id { $_[1] || croak q{I want session id.} }

sub close {
	my($self)= @_;
	if ($self->is_update) {
		if ($self->data) {
			my $id= $self->session_id;
			my $method= $self->is_new ? 'insert': 'update';
			$self->e->debug_out("# + session ${method}: $id");
			$self->$method($self->store_encode);
			$self->set_bind_data
			   ($self->config->{param_name}, $id) if $self->is_new;
		}
		$self->[0]= undef;
		$self->is_update(0);
		$self->is_new(0);
	}
	@_;
}
sub _finalize_error {
	$_[0]->is_update(0);
	@_;
}
sub _output { &close }

sub DESTROY { &close }

1;

__END__

=head1 NAME

Egg::Model::Session::Manager::TieHash - Tie HASH base class for session manager. 

=head1 SYNOPSIS

  package MyApp::Model::Session::TieHash;
  use base qw/ Egg::Model::Session::Manager::TieHash /;

=head1 DESCRIPTION

It is a base class for the TieHash class of the component module generated with
L<Egg::Helper::Model::Sesson> to use it.

=head1 METHODS

This module has succeeded to L<Egg::Component>.

=head2 TIEHASH

This constructor is called among constructors of the Manager class.
Therefore, because the application is executed at the same time when model is 
called, it is not necessary to consider it.

  # It is called at the same time at this time.
  my $session= $e->model('session_label');
  
  # The object of this class is obtained by 'Context' method of the Manager class.
  my $tiehash= $session->context;

=head2 data

The raw data of the session is returned.

Because 'is_update' is not renewed even if this value is operated directly, 
data is not preserved with 'close' method.

The thing used directly doesn't come recommended usually. Or, after the value is
 substituted, 'is_update' should be made effective.

  # This is equivalent to $session->{hoge}.
  my $hoge= $tiehash->data->{hoge};
  
  # 'is_update' is made effective if it saves data by the 'close' method.
  $tiehash->data->{banban}= 'hooo';
  $tiehash->is_update(1);
  
  # Only this makes 'is_update' effective usually.
  $session->{banban}= 'hooo';

=head2 attr

The HASH reference of the data etc. shared in this class is returned.

=head2 e

The object of the project is returned.

=head2 session_id

ID of the session that has been treated now is returned.

=head2 startup

It is a method of the terminal to keep interchangeability with the module of an
old version.

=head2 is_new

Ture is returned if a present session is new.

=head2 is_update

When the value is substituted for the session data, it becomes effective.

However, please note not becoming effective because the substitution of the data
of manipulating data directly by the data method and a deep hierarchy cannot be
detected.

  # As for this, 'is_update' becomes effective at the same time. There is no 
  # necessity especially considered usually.
  $session->{hoge}= 'boo';
  
  # In this case, 'is_update' : like invalidity.
  $session->{mydata}{banban}= 'booo';
  
  # However, if the value of single hierarchical key can be updated even once,
  # 'is_update' becomes effective.
  $session->{hoge}= 'boo';
  $session->{mydata}{banban}= 'booo';
  
  # When data is operated directly, it is necessary to update 'is_update' for 
  # oneself.
  $tiehash->data->{hoo}= 'boo';
  $tiehash->is_update(1);

=head2 init_session

The session is initialized.

If session ID is obtained from the client, reading existing data is tried.
New session ID is issued and a new session is begun when failing in this reading.

=head2 change

Session ID is newly issued and it exchanges it for existing ID.

Data is succeeded as it is.

  $session->{hoge}= 'boo';
  my $session_id= $session->session_id;
  
  $session->change;
  
  # Then, $session_id and $session->session_id become not equal.
  # The content of $session->{hoge} : like 'boo'.

=head2 clear

All the session data is cleared, new session ID is issued, and it makes it to a
new session.

  $session->{hoge}= 'boo';
  my $session_id= $session->session_id;
  
  $session->clear;
  
  # Then, $session_id and $session->session_id disappear equally,
  # and $session->{hoge} is not obtained.

=head2 accept_session_id

Session ID is received from the client or a new session is issued and it returns it.

This method is used to use it internally.

=head2 output_session_id

It is processed to send the client session ID.

This method is called from 'close' method.

=head2 create_session_id

New session ID is issued and 'is_new' method is made effective.

=head2 store_encode

This method originally wards off the received data as it is though it is a method
for the encode of the data passed to 'insert' and 'update' method.

This method is override by Store system module such
as L<Egg::Model::Session::Store::Base64>.

=head2 store_decode

This method originally wards off the received data as it is though it is a method
for deciphered doing the data received from 'restore' method.

This method is override by Store system module such
as L<Egg::Model::Session::Store::Base64>.

=head2 valid_session_id

This method originally wards off received ID as it is though it is a method for
the judgment whether the format of session ID received from the client is correct.

This method is override by ID system module such
as L<Egg::Model::Session::ID::SHA1>.

=head2 close

The session is close.

If 'is_update' method is effective, it saves data.

If 'is_new' is effective at this time, 'insert' method and if it is invalid,
'update' method is used for preservation.

And, after it preserves it, 'is_new' and 'is_update' are invalidated.

This method need not usually be called by the application because it is called
with '_finish' hook at the end of processing.

=head1 ABSOLUTE METHODS

=over 4

=item * restore, insert, update, get_bind_data, set_bind_data, issue_session_id, make_session_id, 

=back

When the component module with the above-mentioned method is not loaded, the
exception is generated.

  __PACKAGE__->startup qw/
    Base::FileCache
    ID::SHA1
    Bind::Cookie
    /;

=head1 COMPONENT MODULES

It is a component module of package enclosing list. L<Egg::Plugin::SessionKit>

=head2 Base system

It processes it concerning the preservation of the session data.

L<Egg::Model::Session::Base::DBI>,
L<Egg::Model::Session::Base::DBIC>,
L<Egg::Model::Session::Base::FileCache>,

=head2 ID system

It processes it concerning session ID issue etc.

L<Egg::Model::Session::ID::IPaddr>,
L<Egg::Model::Session::ID::SHA1>,
L<Egg::Model::Session::ID::MD5>,
L<Egg::Model::Session::ID::UniqueID>,
L<Egg::Model::Session::ID::UUID>,

=head2 Store system

The encode of the session data and processing concerning the decipherment are 
done.

L<Egg::Model::Session::Store::Base64>,
L<Egg::Model::Session::Store::UUencode>,

=head2 Plugin system

The function is enhanced.

L<Egg::Model::Session::Plugin::AbsoluteIP>,
L<Egg::Model::Session::Plugin::AgreeAgent>,
L<Egg::Model::Session::Plugin::CclassIP>,
L<Egg::Model::Session::Plugin::Ticket>,

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,
L<Egg::Model::Session::Manager::Base>,
L<Egg::Helper::Model::Session>,
L<Egg::Component>,
L<Tie::ExtraHash>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

