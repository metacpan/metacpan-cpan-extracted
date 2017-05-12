# HTTP Cache-Control; Section 14.9 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::CacheControl;
use base qw(IDS::DataSource::HTTP::Part);

use strict;
use warnings;
use Carp qw(carp confess);

$IDS::DataSource::HTTP::CacheControl::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens = ();
    my $OK = 1; # optimism

    # Simple directives that are a single token.  Hash for speed
    my %directives = ("no-cache" => 1,
                      "no-store" => 1,
		      "no-transform" => 1,
		      "only-if-cached" => 1,
		      "public" => 1,
		      "no-store" => 1,
		      "no-transform" => 1,
		      "must-revalidate" => 1,
		      "proxy-revalidate" => 1,
		     );
    # The pattern for a token
    my $tokenpat = qr/[-a-zA-Z0-9!#\$%^&*_+|.~]+/; # missing '"` (3 chars)

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    for my $directive (split /,?\s+/, $data) { ### non-standard: accept , as part of sep
	my $lcdirective = lc($directive);
	$self->mesg(3, *parse{PACKAGE} . "::parse: lcdirective '$lcdirective'");

	if (exists($directives{$lcdirective})) {
	    push @tokens, "Cache Control directive: $directive";
	} elsif ($lcdirective =~ /^(max-age|min-fresh|s-maxage)=(\d+)$/) {
	    push @tokens, "Cache Control directive: $1";
	    my $i = new IDS::DataSource::HTTP::Int($self->{"params"}, $2);
	    push @tokens, $i->tokens;
	} elsif ($lcdirective =~ /^max-stale(=(\d+))?$/) {
	    push @tokens, "Cache Control directive: max-stale";
	    push @tokens, IDS::DataSource::HTTP::Int->new($self->{"params"}, $2)->tokens
	        if defined($2);
	} elsif ($lcdirective =~ /^(private|no-cache)(="($tokenpat)")?/) {
	    push @tokens, "Cache Control directive: $1";
	    push @tokens, "Cache Control $1 field: $3" 
	        if defined($3);
	} elsif ($lcdirective =~ /^($tokenpat)=(("$tokenpat")|$tokenpat)?$/) {
	    push @tokens, "Cache Control extension directive: $1";
	    push @tokens, "Cache Control extension value: $2" 
	        if defined($2);
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " invalid cache response directive in '$directive'\n";
	    $self->warn($pmsg, \@tokens, "!Invalid cache response directive");
	    $OK = 0;
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"Cache-Control"}) &&
        ${$self->{"params"}}{"Syntax only"}{"Cache-Control"}) {
        $self->{"tokens"} = [ $OK ? "Cache-Control syntax OK"
                                  : "Cache-Control syntax NOT OK" ];
    } else {
        $self->{"tokens"} = \@tokens;
    }
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
