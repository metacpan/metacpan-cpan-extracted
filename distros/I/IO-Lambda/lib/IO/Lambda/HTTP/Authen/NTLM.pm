# $Id: NTLM.pm,v 1.9 2008/12/17 10:51:39 dk Exp $

package IO::Lambda::HTTP::Authen::NTLM;

use strict;
use Authen::NTLM 1.05;

use IO::Lambda qw(:all);

sub authenticate
{
	my ( $class, $self, $req, $response) = @_;

	lambda {
		# issue req phase 1
		my $method = ($class =~ /:(\w+)$/)[0];
		
		my $ntlm = Authen::NTLM-> new(
			user     => $self-> {username},
			password => $self-> {password},
			domain   => $self-> {domain},
			version  => $self-> {ntlm_version},
		);

		my $r = $req-> clone;
		$r-> content('');
		$r-> header('Content-Length' => 0);
		$r-> header('Authorization'  => "$method " . $ntlm-> challenge);
				
		context $self-> handle_connection( $r);
	tail {
		my $answer = shift;
		return $answer unless ref($answer);

                return $answer if $answer-> code != 401;
		my $challenge = $answer-> header('WWW-Authenticate') || '';
		return $answer unless $challenge =~ s/^$method //;

		# issue req phase 2
		my $r = $req-> clone;
        	$r-> header('Authorization' => "$method ". $ntlm-> challenge($challenge));

		context $self-> handle_connection( $r);
		&tail();
	}}
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::HTTP::Authen::NTLM - library for enabling NTLM authentication in IO::Lambda::HTTP

=head1 SYNOPSIS

	use IO::Lambda qw(:all);
	use IO::Lambda::HTTP;
	
	my $req = HTTP::Request-> new( GET => "http://company.com/protected.html" );
	
	my $r = IO::Lambda::HTTP-> new(
		$req,
		username   => 'moo',
		password   => 'foo',
		keep_alive => 1,
	)-> wait;
	
	print ref($r) ? $r-> as_string : $r;

=head1 DESCRIPTION

IO::Lambda::HTTP::Authen::NTLM allows to authenticate against servers that are
using the NTLM authentication scheme popularized by Microsoft. This type of
authentication is common on intranets of Microsoft-centric organizations.

The module takes advantage of the Authen::NTLM module by Mark Bush. Since there
is also another Authen::NTLM module available from CPAN by Yee Man Chan with an
entirely different interface, it is necessary to ensure that you have the
correct NTLM module.

In addition, there have been problems with incompatibilities between different
versions of Mime::Base64, which Bush's Authen::NTLM makes use of. Therefore, it
is necessary to ensure that your Mime::Base64 module supports exporting of the
encode_base64 and decode_base64 functions.

=head1 SEE ALSO

L<IO::Lambda>, L<Authen::NTLM>. 

Description copy-pasted from L<LWP::Authen::Ntlm> by Gisle Aas.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
