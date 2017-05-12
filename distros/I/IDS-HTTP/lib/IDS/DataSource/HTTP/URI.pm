# HTTP URI; implements RFC 2396 (primary), 2616 (primary), 2732 (IPv6
# updates) standards
# no 2732 yet
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::URI;
use base qw(IDS::DataSource::HTTP::Part);

use strict;
use warnings;
use Carp qw(carp confess);
use IDS::DataSource::HTTP::URIAuthority;
use IDS::DataSource::HTTP::URIPath;

$IDS::DataSource::HTTP::URI::VERSION     = "1.0";

# pull apart a URI from left to right in order to identify errors better
# than if we simply used a big regular expression.
sub parse {
    my $self  = shift;
    my $url = $self->{"data"}; # convenience
    my ($scheme, $rest);
    my @tokens = ();
    my $OK = 1; # optimism

    $self->mesg(1, *parse{PACKAGE} .  "::parse: URI '$url'");

    # scheme (RFC 2396 section 3.1)
    if ($url =~ m!^([a-zA-Z][-+.a-zA-Z0-9]*):(.*)$!) {
	$scheme = $1;
	$rest = $2;
	$self->mesg(2, *parse{PACKAGE} .  "::parse: scheme '$scheme'");
    } elsif ($url =~ m!^/.*$!) {
	undef $scheme;
        $rest = $url;
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " '$url' is invalid\n";
        $self->warn($pmsg, \@tokens, "!Invalid URI");
	$OK = 0;

	if (exists(${$self->{"params"}}{"Syntax only"}{"URI"}) &&
	    ${$self->{"params"}}{"Syntax only"}{"URI"}) {
	    $self->{"tokens"} = [ "URI syntax NOT OK" ];
	} else {
	    $self->{"tokens"} = \@tokens;
	}

	return; # give up.
    }
    $self->mesg(2, *parse{PACKAGE} .  "::parse: rest '$rest'");

    if (defined($scheme) ) {
	#$scheme = lc($scheme); # per section 3.1?
	$self->{"scheme"} = $scheme;
        push @tokens, "Scheme: $scheme";
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " '$url' is missing the scheme (protocol)\n";
	$self->warn($pmsg, \@tokens, "!Missing scheme");
        $rest = $url; # to try to continue
	$OK = 0;
    }

    # type of path (RFC 2396 section 3)

    # No path
    if (! $rest) {
	# URIs are not required to have paths
	push @tokens, "No URI path";
	$OK = 0;
	
	if (exists(${$self->{"params"}}{"Syntax only"}{"URI"}) &&
	    ${$self->{"params"}}{"Syntax only"}{"URI"}) {
	    $self->{"tokens"} = [ "URI syntax NOT OK" ];
	} else {
	    $self->{"tokens"} = \@tokens;
	}
	return;
    }

    # Unknown path
    unless ($rest =~ m!^/(.)!) {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " cannot determine the path type in '$url'\n";
	$self->warn($pmsg, \@tokens, "!Unknown path type");
        $OK = 0;

	if (exists(${$self->{"params"}}{"Syntax only"}{"URI"}) &&
	    ${$self->{"params"}}{"Syntax only"}{"URI"}) {
	    $self->{"tokens"} = [ "URI syntax NOT OK" ];
	} else {
	    $self->{"tokens"} = \@tokens;
	}

	return; # out of options for parsing
    }

    # Expected path
    if ($1 eq '/') { # net_path
        if ($rest =~ m!^//([^/]+)[/?]?(.*)!) {
	    my $authority = $1;
	    $rest = $2; # might be empty;
	    $self->{"authority"} = new IDS::DataSource::HTTP::URIAuthority($self->{"params"}, $authority);
	    push @tokens, $self->{"authority"}->tokens();
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " cannot extract the authority in '$rest'\n";
	    $self->warn($pmsg, \@tokens, "!Unknown authority type");
	    $OK = 0;
	    # no return; we will try to get a path
	}
    }

    $self->{"path"} = new IDS::DataSource::HTTP::URIPath($self->{"params"}, $rest);
    push @tokens, $self->{"path"}->tokens();

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"URI"}) &&
        ${$self->{"params"}}{"Syntax only"}{"URI"}) {
        $self->{"tokens"} = [ $OK ? "URI syntax OK"
                                  : "URI syntax NOT OK" ];
    } else {
        $self->{"tokens"} = \@tokens;
    }
}

sub empty {
    my $self = shift;
    undef $self->{"data"}, $self->{"tokens"}, $self->{"authority"},
          $self->{"path"}, $self->{"scheme"};
}

# accessor functions not provided by the superclass
sub authority {
    my $self = shift;
    return $self->{"authority"};
}

sub path {
    my $self = shift;
    return $self->{"path"};
}

sub scheme {
    my $self = shift;
    return $self->{"scheme"};
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
