# HTTP ETag; Section 14.19 and 3.11 of RFC 2616.  A draft I saw of
# another RFC (un-identified) has the trailing /W, so it is supported
# here as well.
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::ETag;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::ETag::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    # Some lines with entity tags may contain multiple, separated by ,
    my $etagpat = qr'(W/)?"([^"]+)"(/W)?(,\s*)?';
    while ($data =~ m!$etagpat!g) {
        my $etag = $2;
	my $token = (defined($1) || defined($3) ? "Weak " : "") . "Entity Tag";
	unless (${$self->{"params"}}{"handle_EntityTag"}) {
	    $token .= ": $etag";
	}
	push @tokens, $token;
    }
    if ($data !~ m!$etagpat!g) {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
                 ${$self->{"params"}}{"source"} .
                 " invalid etag in '$data'\n";
        $self->warn($pmsg, \@tokens, "!Invalid etag value");
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
