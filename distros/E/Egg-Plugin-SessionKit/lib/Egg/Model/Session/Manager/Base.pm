package Egg::Model::Session::Manager::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;
use Class::C3;
use base qw/ Egg::Base /;

our $VERSION= '0.02';

our $AUTOLOAD;

sub startup {
	my $class= shift;
	my $base = "${class}::TieHash";
	$base->initialize;
	for (@_) {
		next if /^\#/;
		my $pkg= /^\+(.+)/ ? $1: "Egg::Model::Session::$_";
		$base->isa_register(1, $pkg);
	}
	$base->isa_terminator('Egg::Model::Session::Manager::TieHash');
	$base;
}
sub new {
	my($class, $e, $c, $d)= splice @_, 0, 4;
	my $handlers= $e->{session_handlers} ||= {};
	tie my %tiehash, "${class}::TieHash", $e, (shift || 0);
	tied(%tiehash)->init_session;
	$handlers->{$class}= bless \%tiehash, $class;
}
sub context {
	tied(%{$_[0]});
}
sub close_session {
	my($self)= @_;
	my $context= $self->context || return $self;
	my $handlers= $context->e->{session_handlers} || return $self;
	my $class= ref $self;
	return $self unless $handlers->{$class};
	delete $handlers->{$class};
	$context->e->model_manager->reset_context($self->label_name);
	$self->context->close;
	$self;
}
sub AUTOLOAD {
	my $self= shift;
	my($method)= $AUTOLOAD=~m{([^\:]+)$};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub {
		my $proto= shift;
		tied(%{$proto})->$method(@_);
	  };
	$self->$method(@_);
}
sub DESTROY { &close_session }

1;

__END__

=head1 NAME

Egg::Model::Session::Manager::Base - Base class for session manager. 

=head1 SYNOPSIS

  package MyApp::Model::Session::Manager;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    .........
    );
  
  __PACKAGE__->startup(
    .........
    );

=head1 DESCRIPTION

L<Egg::Helper::Model::Sesson> It is a base class for the Manager class of the
component module that generates to use it.

=head1 METHODS

This module has succeeded to L<Egg::Base>.

=head2 startup ([LOAD_MODULES])

LOAD_MODULES is set up and @ISA of receipt TieHash class is set up.

  __PACKAGE__->startup qw/
    Base::FileCache
    ........
    /;

'Egg::Model::Session' part of the module name given to LOAD_MODULES is omitted 
and specified. To treat the module name by the full name, '+' is put on the head.

  __PACKAGE__->startup qw/
    +Egg::Plugin::SessionKit::Bind::URI
    ........
    /;

=head2 new

コンストラクタ。 

'MyApp::Model::Session::TieHash' class is done in tie, and the object that does
the HASH in the wrapping is returned.

  my $session= $e->model('session_name');

The content of the received object becomes session data.
It can access the session by treating the value of the object of this HASH base.

  my $data= $session->{data_key};
  
  $session->{in_data}= 'hoge';

=head2 context

The object of the TieHash class is returned.

However, even if the method of the TieHash class is used with the object of this
class, the same result is obtained because this class
is relaying L<Egg::Model::Session::Manager::TieHash> by AUTOLOAD.

  my $id= $session->context->session_id;
  
     or
  
  my $id= $session->session_id;

=head2 close_session

All opened sessions are shut.

In a word, if the two or more sessions have been opened at the same time when 
two or more component modules have been treated, the all are shut.

  $session->close_session;
  
  # The close method is used to shut individually.
  $session->close

However, because this method is executed with '_finish' hook, it is not necessary
 to usually consider it on the application side.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Helper::Model::Session>,
L<Egg::Base>,
L<Class::C3>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

