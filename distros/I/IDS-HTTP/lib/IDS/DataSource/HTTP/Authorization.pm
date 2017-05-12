# HTTP Authorization from RFC 2616 section 14.8, RFC 2617 (primary)
# Base 64 is from RFC 3548 (and earlier RFCs as well)
#
# subclass of HTTP; see that for interface requirements
#

package IDS::DataSource::HTTP::Authorization;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Authorization::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $credentials = $self->{"data"}; # convenience
    my @tokens = ();

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$credentials'");
    my $base64pat = qr![0-9A-Za-z+/=]+!;
    
    ### Need to fill this out with more auth styles
    if ($credentials =~ /^Basic\s+($base64pat+)$/) {
        push @tokens, "Basic auth credentials"; 
	### should have a param to indicate whether or not to include
	### the hash
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
                 ${$self->{"params"}}{"source"} .
                 " unknown auth credentials '$credentials'\n";
        $self->warn($pmsg, \@tokens, "!unknown auth credentials");
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
