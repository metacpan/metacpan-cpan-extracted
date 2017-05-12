# HTTP method line
# from RFC 2616, 2518
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::MethodLine;
use base qw(IDS::DataSource::HTTP::Part);

use strict;
use warnings;
use Carp qw(carp);
use IDS::DataSource::HTTP::URI;

$IDS::DataSource::HTTP::MethodLine::VERSION     = "1.0";

sub parse {
    my $self  = shift;
    my $line = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} . "::parse: data '$line'");

    my @pieces = split /\s+/, $line;

    $self->{"method"} = $pieces[0];
    push @tokens, "Method: $pieces[0]";
    # verify method is listed in RFC 2616 or RFC 2518
    unless ($pieces[0] =~ /OPTIONS|GET|HEAD|POST|PUT|DELETE|TRACE|CONNECT|PROPFIND|PROPPATCH|MKCOL|COPY|MOVE|LOCK|UNLOCK/) {
	my $pmsg = ${$self->{"params"}}{"source"} .
	        " contains an invalid method: '$pieces[0]'\n";
	$self->warn($pmsg, \@tokens, "!Invalid method: '$pieces[0]'");
    }

    if (defined($pieces[1])) {
	$self->{"path"} = new IDS::DataSource::HTTP::URIPath($self->{"params"}, $pieces[1]);
	push @tokens, $self->{"path"}->tokens();
    } else {
	$self->{"path"} = "NO Path!";
	my $pmsg = "No Path (line: '$line') in " . ${$self->{"params"}}{"source"};
	$self->warn($pmsg, \@tokens, $self->{"path"});
    }

    if (defined($pieces[2]) && $pieces[2]) {
	$self->{"http-version"} = $pieces[2];
	if ($pieces[2] =~ /\d+\.\d+/) {
	    push @tokens, "HTTP Version: $pieces[2]";
	} else {
	    my $pmsg = "Invalid HTTP Version: $pieces[2] in " . ${$self->{"params"}}{"source"};
	    $self->warn($pmsg, \@tokens, "!Invalid HTTP Version: $pieces[2]");
	}
    } else {
        push @tokens, "Implied HTTP version: <= 1.0";
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

sub empty {
    my $self = shift;
    undef $self->{"data"};
    undef $self->{"tokens"};
}

# accessor functions not provided by the superclass
sub path {
    my $self = shift;
    return $self->{"path"} eq "NO Path!" ? "" : $self->{"path"}->path;
}

sub method {
    my $self = shift;
    return $self->{"method"};
}

sub http_version {
    my $self = shift;
    return $self->{"http-version"};
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
