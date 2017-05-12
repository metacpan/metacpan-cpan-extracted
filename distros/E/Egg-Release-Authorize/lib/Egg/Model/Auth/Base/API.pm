package Egg::Model::Auth::Base::API;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: API.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Base Egg::Component /;

our $VERSION= '0.01';

__PACKAGE__->mk_accessors('auth');

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{$class->myname};
	my $id_reg = $c->{user_id_regexp}  || qr{[A-Za-z0-9\_\-]{4,16}};
	my $psw_reg= $c->{password_regexp} || qr{[\x00-\x7F]{4,16}};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::valid_id"}= sub { ($_[1] and $_[1]=~m{^$id_reg$}) };
	*{"${class}::valid_password"}= sub { ($_[1] and $_[1]=~m{^$psw_reg$}) };
	$class->next::method($e);
}
sub new {
	my($class, $auth)= @_;
	bless \$auth, $class;
}
sub password_check {
	my $self = shift;
	my $c_psw= shift || croak 'I want crypt password.';
	my $t_psw= shift || croak 'I want target password.';
	$c_psw=~s{^\s+} []; $c_psw=~s{\s+$} [];
	$t_psw=~s{^\s+} []; $t_psw=~s{\s+$} [];
	$c_psw eq $t_psw ? 1: 0;
}
sub _setup_filed {
	my($class, $config)= @_;
	$class->id_col ($config->{id_field}       || 'id' );
	$class->psw_col($config->{password_field} || 'password' );
	$class->act_col($config->{active_field}) if $config->{active_field};
	$class->grp_col($config->{group_field})  if $config->{group_field};
	$class;
}
sub _restore_result {
	my $self= shift;
	my $data= shift || return 0;
	$data->{___api_name}= $self->myname;
	$data->{___user}    = $data->{$self->id_col}  || "";
	$data->{___password}= $data->{$self->psw_col} || "";
	$data->{___active}  = $self->act_col ? ($data->{$self->act_col} || 0): 1;
	$data->{___group}   = $self->grp_col ? ($data->{$self->grp_col} || ""): "";
	for (@{$data}{qw/ ___user ___password ___group /}) { s/^\s+//; s/\s+$// }
	wantarray ? %$data: $data;
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Base::API - Base class for API module of Egg::Model::Auth.

=head1 DESCRIPTION

It is a base class to succeed to from API class dynamically generated with the
 AUTH controller.

see 
L<Egg::Model::Auth::API::DBI>,
L<Egg::Model::Auth::API::DBIC>,
L<Egg::Model::Auth::API::File>,

=head1 CONFIGURATION

各APIクラス用コンフィグレーションで共通の項目です。



=head1 METHODS

=head2 new

Constructor.

  my $auth= $e->model('auth_label_name');
  my $api = $auth->api('File');

=head2 valid_id ([INPUT_ID])

The format of INPUT_ID is checked.

The format can be defined by setting the regular expression to 'user_id_regexp'
 of the configuration for each API.

Default is '[A-Za-z0-9\_\-]{4,16}'.

=head2 valid_pasword ([INPUT_PASSWORD])

The format of INPUT_PASSWORD is checked.

The format can be defined by setting the regular expression to 'password_regexp'
 of the configuration for each API.

Default is '[\x00-\x7F]{4,16}'.

=head2 password_check ([REGIST_PASSWORD], [INPUT_PASSWORD])

If REGIST_PASSWORD is corresponding to INPUT_PASSWORD, effective is returned.

  if ($api->password_check($reg_psw, $in_psw)) {
     .........
  } else {
     .........
  }

It is not possible to correspond by this method when encrypted for the registered
password. Please set up the component of the Crypt system to API class.

  package MyApp::Model::Auth::MyAuth;
  ...........
  ....
  
  __PACKAGE__->setup_api( File=> qw/ Crypt::SHA1 / );

see 
L<Egg::Model::Auth::Crypt::SHA1>,
L<Egg::Model::Auth::Crypt::MD5>,
L<Egg::Model::Auth::Crypt::Func>,
L<Egg::Model::Auth::Crypt::CBC>,

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base>,
L<Egg::Base>,
L<Egg::Component>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

