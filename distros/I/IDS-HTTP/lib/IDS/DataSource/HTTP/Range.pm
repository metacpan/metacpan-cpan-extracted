# HTTP Range; RFC 2616 sections 14.16, 
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Range;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);
use IDS::DataSource::HTTP::Int;

$IDS::DataSource::HTTP::Range::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my ($units, $range, @tokens);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    ### according to Section 3.11, \w is not a big enough class
    if ($data =~ m!^((bytes)|(\w+))=(.*)$!) {
        push @tokens, "Range units: $1";
	my $ranges = $4;
        for $range (split /,\s*/, $ranges) {
	    $range =~ /(\d+)-(\d+)?/;
	    if (defined($1)) { # start is optional
		push @tokens, "Range start";
		my $start = new IDS::DataSource::HTTP::Int($self->{"params"}, $1);
		push @tokens, $start->tokens;
	    } else {
		push @tokens, "No range start";
	    }
	    if (defined($2)) { # end is optional
		push @tokens, "Range end";
		my $end = new IDS::DataSource::HTTP::Int($self->{"params"}, $2);
		push @tokens, $end->tokens;
	    } else {
		push @tokens, "No range end";
	    }
	    if (! defined($1) && ! defined($2)) { # error
		my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " invalid range (with units) in '$data'\n";
		$self->warn($pmsg, \@tokens, "!Invalid range");
	    }
	}
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " invalid range in '$data'\n";
	$self->warn($pmsg, \@tokens, "!Invalid range");
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
