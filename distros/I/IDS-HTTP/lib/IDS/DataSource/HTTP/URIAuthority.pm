# HTTP URI authority; implements RFC 2396 (primary), 2616 (primary),
# 2732 (IPv6 updates) standards.
# no 2732 yet
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::URIAuthority;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::URIAuthority::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"user"}, $self->{"host"},
          $self->{"port"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $authority = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: authority '$authority'");

    if ($authority =~ m!;:@?/!) {
	# specifically noted illegal character
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " authority '$authority' contains an illegal char";
	$self->warn($pmsg, \@tokens, "!Illegal character in authority");
    }

    # <userinfo>@<host>:<port>
    ### user expr below needs to handle escaped chars
    my $userpat = qr/[-_.!~*';:&=+\$,()A-Za-z0-9]*/;
    if ($authority =~ m!^(($userpat)@)?([^:]+)(:(\d+))?!) {
	my $user = $2; # may be empty
	my $host = $3;
	my $port = $5; # may be empty

	# handling and detailed checking of each part now
	$self->{"user"} = $user;
	defined($user) and push @tokens, "Userinfo: '$user'";

	$self->{"host"} = new IDS::DataSource::HTTP::Host($self->{"params"}, $host);
	push @tokens, $self->{"host"}->tokens;

	if (defined($port)) {
	    $self->{"port"} = $port;
	    push @tokens, "Port: $port";
	    unless($port =~ /^\d*$/) {
		my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " port '$port' contains non-digit";
		$self->warn($pmsg, \@tokens, "!non-digit in port '$port'");
	    }
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

# accessor functions not provided by the superclass
sub hostname {
    my $self = shift;
    return $self->{"host"};
}

sub port {
    my $self = shift;
    return $self->{"port"} || 80;
}

sub userinfo {
    my $self = shift;
    return $self->{"user"};
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut

1;
