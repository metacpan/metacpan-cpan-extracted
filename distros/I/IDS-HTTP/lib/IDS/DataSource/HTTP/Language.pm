# HTTP Accept-Language line; section 14.4 of RFC 2616 applies here
# qvalues are from section 3.9
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Language;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Language::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $accept = $self->{"data"}; # convenience
    my ($lang, $param, @tokens);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$accept'");

    # Example line:
    # Accept-Language: da, en-gb;q=0.8, en;q=0.7
    my $langpat = qr'[a-zA-Z]{1,8}(-[a-zA-Z]{1,8})?';
    my $qvalpat = qr'(0(\.\d{0,3})?)|(1(\.0{0,3})?)';
    # First, split at commas
    for my $langpref (split /, */, $accept) {
        $langpref =~ /^([^;]+)(;.*)?/;
	$lang = $1;
	$param = $2;
	push @tokens, $lang =~ /^($langpat)|(x-$langpat)|\*$/
	    ? "Accept language: $lang"
	    : "Invalid accept language: $lang";

        # See if a parameter is present (e.g., qvalue)
	if (defined($param)) {
	    my $pobj = new IDS::DataSource::HTTP::AcceptParams($self->{"params"}, $param);
	    push @tokens, $pobj->tokens();
	}
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
