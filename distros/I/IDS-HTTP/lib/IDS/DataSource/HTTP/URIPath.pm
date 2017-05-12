# HTTP URI path; implements RFC 2396, 2616 (primary), standards
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::URIPath;
use base qw(IDS::DataSource::HTTP::Part);

use strict;
use warnings;
use Carp qw(carp confess);
use IDS::Utils qw(split_value);

$IDS::DataSource::HTTP::URIPath::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $path = $self->{"data"}; # convenience
    my (@tokens, @pathtokens, $qpath, $query);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: path '$path'");

    if ($path =~ /^([^?]+)\?(.+)$/) { # query
	$qpath = $1;
	$query = $2;
	$self->mesg(3, *parse{PACKAGE} .  "::parse: query path '$path' query '$query'");

	@pathtokens = split_value("URL Query path part",
				  '([\/])', $qpath);
	push @tokens, @pathtokens;
	$self->mesg(3, *parse{PACKAGE} .  "::parse: path tokens:\n    ",
	            "\n    ", \@pathtokens);
	push @tokens, "URL Query separator: ?";
	for my $qpart (split /(\&)/, $query) {
	    $self->mesg(3, *parse{PACKAGE} .  "::parse: query part '$qpart'");
	    if (${$self->{"params"}}{"handle_PHPSESSID"} && $qpart =~ /^PHPSESSID=/) {
		push @tokens, handle_PHPSESSID($qpart);
	    } elsif ($qpart eq '&') {
	        push @tokens, 'URL Query separator: &'
	    } else {
		$qpart =~ /^([^=]+)=(.*)/;
		if (defined($1)) {
		    push @tokens, "URL Query question: $1";
		    $qpart = $2;
		}
		my @subparts = split /\+/, $qpart;
		#map { $_ = $self->expand_pct($_) } @subparts;
		push @tokens, ($#subparts >= 1
		    ? split_value("URL Query value subpart", '\+', $qpart)
		    : "URL Query value part: $qpart");
	    }
	}
    } else { # no query
	$self->mesg(3, *parse{PACKAGE} .  "::parse: not a query");
	if ($path =~ m!^(.*/)?([^/]*)?$!) {
	    if (${$self->{"params"}}{"file_types_only"}) {
		# pull off last element and handle it specially if we can
		$path = defined($1) ? "$1" : "/";
		my $file = $2;

		# deal with a the leading / which causes the split_value
		# to return an empty first element.
		$path =~ s!^/!! and push @tokens, "URL directory part: /";
		my @parts = split_value("URL directory part", '([\/])', $path);
		#map { $_ = $self->expand_pct($_) } @parts;
		push @tokens, @parts;
		defined($file) and push @tokens, $self->id_file($file);
	    } else {
		# deal with a the leading / which causes the split_value
		# to return an empty first element.
		$path =~ s!^/!! and push @tokens, "URL path part: /";
		push @tokens, split_value("URL path part", '([\/])', $path);
	    }
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " invalid path '$path'\n";
	    $self->warn($pmsg, \@tokens, "!Invalid path '$path'");
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

sub id_file {
    my $self = shift;
    my $fname = shift;
    defined($fname) or
        confess *id_file{PACKAGE} . "::id_file missing fname";
    my $type = '';
    my $len = ${$self->{"params"}}{"file_name_lengths"} ?
	      length($fname) . " " : "";

    # common file types
    $fname =~ /^$/ and $type = "directory";
    $fname =~ /\.(gif|tif{1,2}|jpe?g)$/i and $type = "image";
    $fname =~ /\.(s?html?)$/i and $type = "html";
    $fname =~ /\.(pl)$/i  and $type = "Perl";
    $fname =~ /\.(php)$/i and $type = "PHP";
    $fname =~ /\.(pdf)$/i and $type = "PDF";
    $fname =~ /\.(txt)$/i and $type = "text";
    $fname =~ /\.(css)$/i and $type = "html style sheet";
    $fname =~ /\.(vcs)$/i and $type = "vCalendar";
    return ($type ? "$type " : "unknown$len" ) . "file";
}

sub handle_PHPSESSID {
    my $str = shift or confess "handle_PHPSESSID called without an argument\n";

    return $str =~ /PHPSESSID=[a-f0-9]{32}/
	? "PHP Session ID"
	: "Invalid PHP Session ID";
}

# accessor functions
sub path {
    my $self = shift;
    return $self->{"data"};
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
