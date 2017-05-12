package LJ::GetCookieSession;

use warnings;
use strict;
use vars qw($VERSION);

use WWW::Mechanize;
require Digest::MD5;


our $VERSION = '0.01';

=pod

=head1 NAME 

 LJ::GetCookieSession - A perl module to log into livejournal services

=head1 VERSION

Version 0.01
 
=head1 SYNOPSIS

C<LJ::GetSessionCookie> is an C<perl> module which is used to generate value of cookie parameter
named 'ljsession', which can be used in future requests to lj services.

Request mode sessiongenerate (see L<http://www.livejournal.com/doc/server/ljp.csp.flat.sessiongenerate.html>) is used.  

  use LJ::GetSessionCookie;
  
  my $ljsession = LJ::GetCookieSession->generate({user=> ..., pass=>...});

L<http://www.livejournal.com/developer/protocol.bml>
 
=head1 EXAMPLE

The following simple shows how to use the module to get all comments from LiveJournal.

	use WWW::Mechanize;
	use LJ::GetCookieSession;
	
	my $mech = WWW::Mechanize->new(
		agent      => 'support@creograf.ru',
		cookie_jar => { "ljsession" => "" }
	);
	
	 my $ljsession = LJ::GetCookieSession->generate({user=> ..., pass=>...});

	die "failed to log into lj: ljsession failed\n" unless ( defined $ljsession );

	$mech->add_header ('X-LJ-Auth' => "cookie");
	$mech->add_header ('Cookie' => "ljsession=$ljsession");

	$mech->get("http://livejournal.com/export_comments.bml?get=comment_body");

    return undef unless ($mech->res->is_success);

	my $xml_comments = $mech->content();

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Anastasiya Deeva, Studio Creograf L<http://creograf.ru>, L<support@creograf.ru>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AVAILABLE METHODS

=head2 LJ::GetSessionCookie::generate()

C<LJ::GetSessionCookie::generate()> is a routine which generates value of cookie 'ljsession' for LiveJournal.

=over 4

=item user

The username who owns the journal;
this option is B<required>.

=item pass

The password of the C<user>;
this option is B<required>.

=item server

URL of remote site to login.  

=back

=cut

sub generate {
	my $self = shift;
	my $pars = { 
		"server"=>"http://livejournal.com",
		%{$_[0]}
	};
	$pars->{"server"}="http://".$pars->{'server'} unless($pars->{'server'} =~ /^http/);
	
	die "user and password are required for login" unless($pars->{'user'} and $pars->{'pass'});
 
	my $mech = WWW::Mechanize->new( agent => 'support@creograf.ru', );

	my $r =
	  $mech->post( $pars->{"server"} . "/interface/flat", { "mode" => "getchallenge" } );
	my $response = $self->_flatresponse( $mech->content() );
	
	die "challenge not recieved" unless $response->{'challenge'};

	$r = $mech->post(
		$pars->{"server"} . "/interface/flat",
		{
			"mode"           => "sessiongenerate",
			"user"           => $pars->{"user"},
			"auth_method"    => "challenge",
			"auth_challenge" => $response->{'challenge'},
			"auth_response" =>
			  $self->_calcchallenge( $response->{'challenge'}, $pars->{"pass"} )
		}
	);

	$response = $self->_flatresponse( $mech->content() );

	die "auth failed".$mech->content() unless $response->{'ljsession'};

    return undef unless defined $response->{'ljsession'}; 
	return $response->{'ljsession'};
}

# Define reference from new to generate
#*new="";
#*new=\&generate;

# generates challenge response 
sub _calcchallenge {
	my $self = shift;
	my ( $challenge, $password ) = @_;
	
	my $md5_1=Digest::MD5->new;
    $md5_1->add($password);
    $password=$md5_1->hexdigest;
	
	my $md5 = Digest::MD5->new;
	$md5->add($challenge);
	$md5->add($password);
	return $md5->hexdigest;
}

# parses response of http://www.livejournal.com/interface/flat 
sub _flatresponse {
	my $self     = shift;
	my $response = shift;
	my $r        = {};
	my @ar       = split( /\n/, $response );

	my $index = 0;
	foreach my $name (@ar) {
		$name =~ s/\n//g;
		if ( length($name) > 0 ) {
			my $value = $ar[ $index + 1 ];
			$value =~ s/\n//g;
			$r->{$name} = $value;
			$ar[ $index + 1 ] = "";
		}
		$index++;
	}
	return $r;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-lj-getsessioncookie at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LJ-GetSessionCookie>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LJ::GetSessionCookie


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LJ-GetSessionCookie>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LJ-GetSessionCookie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LJ-GetSessionCookie>

=item * Search CPAN

L<http://search.cpan.org/dist/LJ-GetSessionCookie/>

=back

=cut
1;

