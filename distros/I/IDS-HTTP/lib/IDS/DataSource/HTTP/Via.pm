# HTTP Via; Section 14.45 RFC 2616.
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Via;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Via::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    my $tokenpat = qr/[-a-zA-Z0-9!#\$%^&*_+|.~]+/; # missing '"` (3 chars)
    my $viapat = qr!(($tokenpat)/)?($tokenpat)\s+([0-9A-Za-z.:]+)([^,]*)?(,\s*)?!;
    while ($data =~ m!$viapat!g) {
        my ($name, $version, $received, $comment) = ($2, $3, $4, $5);
	if (defined($name) && $name) {
	    push @tokens, "Via protocol: $name";
	} else {
	    push @tokens, "Via protocol implied: HTTP";
	}
	push @tokens, "Via protocol version: $version";

	# abusing the protocol slghtly, since an authority can also
	# include user info.
	my $ua = new IDS::DataSource::HTTP::URIAuthority($self->{"params"}, $received);
	push @tokens, $ua->tokens;
	if (defined($comment) && $comment) {
	    push @tokens, "Via comment: $comment";
	}
    } 
    if ($data !~ m!$viapat!g) {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
                 ${$self->{"params"}}{"source"} .
                 " invalid via '$data'\n";
        $self->warn($pmsg, \@tokens, "!Invalid via value");
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
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
