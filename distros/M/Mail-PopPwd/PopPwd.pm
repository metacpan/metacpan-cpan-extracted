#
# PopPwd.pm
# Last Modification: Fri Oct 10 18:31:17 WEST 2003
#
# Copyright (c) 2002 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Mail::PopPwd;
use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter AutoLoader);
$VERSION = 0.03;
@ISA = qw(Exporter);
require 5;
use IO::Socket;
use Crypt::Cracklib;

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {
		HOST      => "localhost",
		PORT      => 106,
		TIMEOUT   => 0,
		USER      => "",
		NAME      => "",
		STOREDPWD => "",
		OLDPWD    => "",
		NEWPWD    => "",
		CONFPWD   => "",
		NMIN      => 6,
		NMAX      => 12,
		NDIFCHARS => 4,
		NSEQWORD  => 4,
		CRACKLIB  => "",
		@_,
	};
	bless ($self, $class);
	return($self);
}

sub count_chars {
	my $string = shift;

	my %seen;
	my @chars = split(//, $string);
	@seen{@chars} = ();
	return(scalar(keys(%seen)));
}

sub checkpwd {
	my $self = shift;

	$self->{USER} or return(551);
	$self->{OLDPWD} or return(551);
	$self->{NEWPWD} or return(553);
	$self->{CONFPWD} or return(554);
	return(555) if(length($self->{NEWPWD}) < $self->{NMIN});
	return(556) if(length($self->{NEWPWD}) > $self->{NMAX});
	return(557) if($self->{NEWPWD} ne $self->{CONFPWD});
	return(558) if($self->{STOREDPWD} && ($self->{OLDPWD} ne $self->{STOREDPWD}));
	return(559) if(&count_chars($self->{NEWPWD}) < $self->{NDIFCHARS});

	my $pwdrev = reverse($self->{NEWPWD});
	return(560) if(&check_dif($self->{NEWPWD},$self->{OLDPWD},$self->{NSEQWORD}) || &check_dif($pwdrev,$self->{OLDPWD},$self->{NSEQWORD}));
	return(561) if(&check_dif($self->{NEWPWD},$self->{USER},$self->{NSEQWORD}) || &check_dif($pwdrev,$self->{USER},$self->{NSEQWORD}));
	return(562) if($self->{NAME} &&
			(&check_dif($self->{NEWPWD}, $self->{NAME},$self->{NSEQWORD}) ||
				&check_dif($pwdrev, $self->{NAME}, $self->{NSEQWORD})));

	if($self->{CRACKLIB}) {
		my $reason = fascist_check($self->{NEWPWD}, $self->{CRACKLIB});
		chomp($reason);
		($reason eq "ok") or return(563);
	}
	return();
}

sub change {
	my $self = shift;

	my $socket = IO::Socket::INET->new(
			PeerAddr => $self->{HOST},
			PeerPort => $self->{PORT},
			Proto    => "tcp",
			Type     => SOCK_STREAM,
			Timeout  => $self->{TIMEOUT}		
	) or return(join("", "Couldn't connect to ", $self->{HOST}, ":", $self->{PORT}, " $@\n"));

	my $EOL = "\015\012";
	my $error = "";
	TEST: {
		print $socket join(" ", "user", $self->{USER}), $EOL;
		last TEST if($error = &get_answer($socket));
		print $socket join(" ", "pass", $self->{OLDPWD}), $EOL;
		last TEST if($error = &get_answer($socket));
		print $socket join(" ", "newpass", $self->{NEWPWD}), $EOL;
		last TEST if($error = &get_answer($socket));
		print $socket "quit$EOL";
		last TEST if($error = &get_answer($socket));
	}
	close($socket);
	return($error);
}

sub get_answer {
	my $answer = shift;
	my $line = <$answer>;
	my $v = substr($line,0,3);
	return(($v eq "200") ? "" : $line);
}

sub check_dif($$$) {
	my($str1, $str2, $n) = @_;

	($str1, $str2) = ($str2, $str1) if(length($str2) < length($str1));
	my @parts = $str1 =~ /(?=(.{$n}))/g;
	for(@parts) { return($_) if($str2 =~ /\Q$_\E/ig); }
	return();
}

1;

__END__

# POD Documentation (perldoc PopPwd or pod2html this_file)

=head1 NAME

Mail::PopPwd - Perl 5 module to talk to a poppasswd daemon

=head1 SYNOPSIS

  use Mail::PopPwd;

  my $poppwd = Mail::PopPwd->new(
                        HOST   => "localhost",
                        USER   => "hdias",
                        OLDPWD => "********",
                        NEWPWD => "********");
  my $error = $poppwd->change();

  # set hash values

  $poppwd->{HOST} = "localhost";
  $poppwd->{USER} = "hdias";
  $poppwd->{OLDPWD} = "********";
  $poppwd->{NEWPWD} = "********";

=head1 DESCRIPTION

This module implements an Object-Oriented interface to a poppassd daemon.
It can be used to write perl-based clients to change users password (you
can use this for change passwords via www clients).

=head1 CONSTRUCTORS

   Mail::POP3Client->new(
                HOST    => "local",
                PORT    => 106,
                USER    => "",
                OLDPWD  => "",
                NEWPWD  => "",
                TIMEOUT => 0,
   );

=over 4

=item *
B<HOST> is the poppassd daemon server name or IP address (default='localhost')

=item *
B<PORT> is the poppassd daemon server port (default=106)

=item *
B<TIMEOUT> set a timeout value for socket operations (default=0)

=item *
B<USER> is the userID of the account on the poppassd daemon server

=item *
B<NAME> is the name of the userID (for matching against the new password)

=item *
B<STOREDPWD> is the cleartext stored password for the userID (if you use a
database to store passwords)

=item *
B<OLDPWD> is the cleartext old password for the userID

=item *
B<NEWPWD> is the cleartext new password for the userID

=item *
B<CONFPWD> is the cleartext confirmation password for the userID

=item *
B<NMIN> is the minimum number of characters of password (default=6)

=item *
B<NMAX> is the maximum number of characters of password (default=12)

=item *
B<NDIFCHARS> is the number of differents characters in password
(default=4)

=item *
B<NSEQWORD> is the number of similar characters in NEWPWD and OLDPWD, USER
or NAME

=item *
B<CRACKLIB> is the location of your pw_dict file for use with cracklib
module

=head1 METHODS

These commands are intended to make writing a poppassd client easier.

=over 4

=item I<new>()

Construct a new connection with this. You should give it at least 4
arguments; HOST, USER, OLDPWD and NEWPWD. All others arguments are
optional. All passwords are send in clear text.

=item I<checkpwd>()

Check password against given paramenters; STOREDPWD, NMIN, NMAX,
NDIFCHARS, NSEQWORD and CRACKLIB if you set the path to the dictionary
(check the password for their appearance in dictfile).
Return a error code if the passwords are invalid.

=item I<change>()

Connect to poppasswd daemon and change the old password to the new
password. Return a error if the connection fail.

=back

=head1 ERROR CODES

=over 4

=item B<551>

USER empty

=item B<552>

OLDPWD empty

=item B<553>

NEWPWD empty

=item B<554>

CONFPWD empty

=item B<555>

length of NEWPWD lesser then NMIN

=item B<556>

length of NEWPWD greater then NMAX

=item B<557>

STOREDPWD and OLDPWD do not match

=item B<558>

CONFPWD and NEWPWD do not match

=item B<559>

The NEWPWD must have NDIFCHARS or more different characters.

=item B<560>

The NEWPWD and OLDPWD is similar

=item B<561>

The NEWPWD and USER is similar

=item B<562>

The NEWPWD and NAME is similar

=item B<563>

BAD PASSWORD: it is based on a dictionary word or to easy

=back

=head1 AUTHOR

Henrique Dias <hdias@aesbuc.pt>

=head1 CREDITS

Based on poppassd by Pawel Krawczyk <kravietz@ceti.com.pl>,
http://www.ceti.com.pl/~kravietz/prog.html

and 

change-pass.cgi by mp@atlantic.net

Thanks to Anita Afonso for the revision.

=head1 SEE ALSO

perl(1).

=cut
