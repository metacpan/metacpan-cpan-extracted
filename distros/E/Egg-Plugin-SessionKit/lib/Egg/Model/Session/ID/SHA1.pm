package Egg::Model::Session::ID::SHA1;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SHA1.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Digest::SHA1 qw/ sha1_hex /;
use Time::HiRes qw/ gettimeofday /;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	$class->config->{id_length} ||= 32;
	$class->next::method($e);
}
sub valid_session_id {
	my $self= shift;
	my $id= shift || croak q{I want session id.};
	my $len= $self->config->{id_length};
	$id=~m{^[a-f0-9]{$len}$} ? $id : (undef);
}
sub make_session_id {
	substr(
	  sha1_hex( gettimeofday. {}. rand(1000). $$ ),
	  0, $_[0]->config->{id_length},
	  );
}

1;

__END__

=head1 NAME

Egg::Model::Session::ID::SHA1 - SHA1 is used for session ID. 

=head1 SYNOPSIS

  package MyApp::Model::Sesion;
  
  __PACKAGE__->startup(
   .....
   ID::SHA1
   );

=head1 DESCRIPTION

It is a component module to use the HEX value obtained with L<Digest::SHA1> for
session ID.

'id_length' is accepted to the configuration.

  __PACKAGE__->config(
    id_length => 32,
    );

It becomes 32 at the unspecification.

=head1 METHODS

=head2 make_session_id

The value obtained by 'sha1_hex' function of L<Digest::SHA1> is returned.

=head2 valid_session_id (SESSION_ID)

The format of SESSION_ID is checked and the result is returned.

=head2 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Digest::SHA1>,
L<Time::HiRes>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

