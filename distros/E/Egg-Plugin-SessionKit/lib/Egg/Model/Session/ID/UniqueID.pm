package Egg::Model::Session::ID::UniqueID;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UniqueID.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub make_session_id {
	$ENV{UNIQUE_ID} || die q{ $ENV{UNIQUE_ID} variable cannot be acquired. };
}
sub valid_session_id {
	my $self= shift;
	my $id= shift || croak q{I want session id.};
	$id=~m{^[A-Za-z0-9\@\-]{19}$} ? $id : (undef);
}

1;

__END__

=head1 NAME

Egg::Model::Session::ID::UniqueID - 'mod_uniqueid' is used for session ID.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   .....
   ID::UniqueID
   );

=head1 DESCRIPTION

Enhancing module 'mod_uniqueid' of Apache is used for session ID.

The WEB server should set up to use it and Apache and mod_uniqueid have set it up.

see L<http://www.apache.org/>.

=head1 METHODS

=head2 make_session_id

The value of environment variable 'UNIQUE_ID' is returned.

=head2 valid_session_id (SESSION_ID)

The result of the format check of session ID is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<http://www.apache.org/>,
L<http://httpd.apache.org/docs/2.0/ja/mod/mod_unique_id.html>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

