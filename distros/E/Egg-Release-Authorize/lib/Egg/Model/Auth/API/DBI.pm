package Egg::Model::Auth::API::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub myname { 'dbi' }

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{dbi} ||= {};
	$class->_setup_filed($c);
	$class->mk_classdata($_) for qw/ dbi_label statement /;
	my $label= $class->dbi_label( $c->{label} || 'dbi::main' );
	$e->is_model($label) || die $class. qq{ - '$label' model is not found.};
	if (my $sql= $c->{select_statement}) {
		$class->statement( $sql );
	} else {
		my $dbname= $c->{dbname} || 'members';
		my $id_col= $class->id_col;
		$class->statement(qq{SELECT * FROM $dbname WHERE $id_col = ? });
	}
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::__prepare"}=
	   ( $c->{prepare_cache} or $c->{prepare_cached} )
	   ? sub { $_[1]->prepare_cached($_[2]) }
	   : sub { $_[1]->prepare($_[2]) };
	$class->next::method($e);
}
sub restore_member {
	my $self= shift;
	my $id  = shift || croak __PACKAGE__. ' - I want user id.';
	my $sth = $$self->{restore_sth} ||= $self->__prepare
	          ( $$self->e->model($self->dbi_label)->dbh, $self->statement );
	my %bind;
	$sth->execute($id);
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	$sth->fetch || return 0;
	$self->_restore_result(\%bind);
}
sub _finish {
	my($self)= @_;
	$$self->{restore_sth}->finish if $$self->{restore_sth};
	$self->next::method;
}
sub _finalize_error { &_finish }

1;

__END__

=head1 NAME

Egg::Model::Auth::API::DBI - API component to access attestation data base by using DBI. 

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    dbi => {
      dbname         => 'members',
      label          => 'dbi_label',
      prepare_cached => 1,
      user_id_regexp => qr{[a-z][a-z0-9]{3.16}},
      password_regexp=> .......
      id_field       => 'user_id',
      password_field => 'password',
      active_field   => 'active',
      group_field    => 'a_group',
      },
    );
  
  __PACKAGE__->setup_api('DBI');

=head1 DESCRIPTION

It is API component to access the attestation data base by using L<Egg::Model::DBI>.

The setting of 'dbi' is added to the configuration to use it and 'DBI' is set by
 'setup_api' method.

=head1 CONFIGURATION

Additionally, there is a common configuration to API class.

see L<Egg::Model::Auth::Base::API>.

=head3 label

Label name to acquire data base handler of L<Egg::Model::DBI>.

=head3 select_statement

SELECT statement to acquire attestation data.

The statement with one Prasfolda for login ID is set.

  statement => "SELECT * FROM members a LECT JOIN profile ON a.id = b.id WHERE a.id = ? ",

When this is set, 'dbname' is disregarded.
It sets it when SQL complex though the attestation data is acquired is 
necessary.

Login ID and the password are at least necessary though it is also good to specify
the acquired column.
Additionally, please add columns of an effective flag and the group, etc. 
arbitrarily.

The acquired data becomes possible the reference to everything by 'data' method.

=head3 dbname

Table name of attestation data base.

If 'statement' is set, this setting is not used.

Default is 'members'.

The following SELECT statements are used by this.

  SELECT * FROM [dbname] WHERE [id_field] = ?

=head3 prepare_cached

'prepare_cached' comes to be used by the data base handler when keeping effective.

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

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

