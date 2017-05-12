# HTTP Cookies (RFC 2965)
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Cookie;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Cookie::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens = ();
    my ($name, $value, $avpair);
    my $OK = 1; # optimism

    $self->mesg(1, *parse{PACKAGE} . "::parse: data '$data'");

    # split cookie into name and value
    while (defined($data) && length($data) > 0) {
	# Using split should get the first ;, and quoted ; are OK in the
	# value (? are they?).	Note that $data gets shorter each
	# interation through the loop.
	($avpair, $data) = split(/;\s*/, $data, 2);
	if (! defined($avpair) || $avpair eq "") {
	    # Only one cookie, not a collection
	    $avpair = $data;
	    $data = "";
	    last unless $avpair;
	}
	defined($data) or $data = ""; # to avoid warnings from line below
	$self->mesg(2, *parse{PACKAGE} . "::parse: avpair '$avpair' data '$data'");

	# Using split should get the first =, and quoted = are OK in the
	# value
        ($name, $value) = split(/\s*=\s*/, $avpair, 2);
	unless (defined($name)) {
	    carp "Undefined cookie name! data '$data' avpair '$avpair'";
	    $OK = 0;
	}
	$self->mesg(2, *parse{PACKAGE} . "::parse: name '$name' value '$value'");

        if (${$self->{"params"}}{"handle_PHPSESSID"} && $name =~ /^PHPSESSID$/) {
            my $phpsess = handle_PHPSESSID($value);
	    $OK = 0 unless $phpsess eq "PHP Session ID";
            push @tokens, $phpsess;
        } else {
            push @tokens, "Cookie: $name";
            push @tokens, "Cookie value: $value"       # values are optional
                if defined($value) && ${$self->{"params"}}{"cookie_values"};
        }
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"Cookie"}) &&
        ${$self->{"params"}}{"Syntax only"}{"Cookie"}) {
        $self->{"tokens"} = [ $OK ? "Cookie syntax OK"
                                  : "Cookie syntax NOT OK" ];
    } else {
        $self->{"tokens"} = \@tokens;
    }
}

sub handle_PHPSESSID {
    my $str = shift;
    defined($str) or confess "handle_PHPSESSID called without an argument\n";

    return $str =~ /^[a-f0-9]{32}$/
	? "PHP Session ID"
	: "Invalid PHP Session ID";
}

# accessor functions not provided by the superclass

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
