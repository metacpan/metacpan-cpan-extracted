package Egg::Model::Auth::API::DBIC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use DBIx::Class::ResultClass::HashRefInflator;

our $VERSION= '0.01';

sub myname { 'dbic' }

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{dbic} ||= {};
	my $moniker= $c->{model_name} || die q{I want setup 'model_name'.};
	$e->is_model($moniker) || die qq{'$moniker' model is not found.};
	$class->mk_classdata('search_attr');
	$class->search_attr( $c->{search_attr} || {} );
	$class->_setup_filed($c);
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::dbic"}=
	   sub { ${$_[0]}->{___dbic} ||= ${$_[0]}->e->model($moniker) };
	$class->next::method($e);
}
sub restore_member {
	my $self  = shift;
	my $id    = shift || croak __PACKAGE__. ' - I want user id.';
	my $result= $self->dbic
	            -> search({ $self->id_col => $id }, $self->search_attr );
	$result->result_class('DBIx::Class::ResultClass::HashRefInflator');
	$self->_restore_result( $result->first );
}

1;

__END__

=head1 NAME

Egg::Model::Auth::API::DBIC - API component to access attestation data base by using DBIC. 

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    dbic => {
      model_name     => 'dbic_model_name',
      search_attr    => '.....',
      id_field       => 'user_id',
      password_field => 'password',
      active_field   => 'active',
      group_field    => 'a_group',
      },
    );
  
  __PACKAGE__->setup_api('DBIC');

=head1 DESCRIPTION

It is API component to access the attestation data base by using Egg::Model::DBIC.

The setting of 'dbic' is added to the configuration to use it and 'DBIC' is set
 by 'setup_api' method.

=head1 CONFIGURATION

Additionally, there is a common configuration to API class.

see L<Egg::Model::Auth::Base::API>.

=head3 model_name

Label name to acquire model of attestation data.

=head3 search_attr

It sets it if there is an option to pass it to the search method of DBIC.

=head1 METHODS

=head2 myname

Own API label name is returned.

=head2 restore_member ([LOGIN_ID])

The data of LOGIN_ID is acquired from the attestation data base, and the HASH 
reference is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,
L<Egg::Release::DBI>,
L<DBIx::Class::ResultClass::HashRefInflator>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

