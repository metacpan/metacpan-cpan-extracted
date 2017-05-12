#-----------------------------------------------------------------
# MRS::Constants
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: Used constants in the MRS::Client's modules
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use strict;
use warnings;
package MRS::Constants;

our $VERSION = '1.0.1'; # VERSION

#-----------------------------------------------------------------
#
#  MRS::EntryFormat ... enumeration of entry formats
#
#-----------------------------------------------------------------
package MRS::EntryFormat;

our $VERSION = '1.0.1'; # VERSION

use constant {
    PLAIN    => 'plain',
    TITLE    => 'title',
    HTML     => 'html',
    FASTA    => 'fasta',
    SEQUENCE => 'sequence',
    HEADER   => 'header',    # only limited usage
};

#-----------------------------------------------------------------
# Return 1 only if $format is one of the recognized constants.
# $client is here only because it knows what MRS version we are
# working with.
# -----------------------------------------------------------------
sub check {
    my ($class, $format, $client) = @_;
    return 0 unless $format;

    my $regex = PLAIN . '|' . TITLE . '|' . FASTA . '|' . HEADER;
    $regex .= '|' . HTML .  '|' . SEQUENCE unless $client && $client->is_v6;

    my $regex_c = qr/^($regex)$/;
    $format =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::XFormat ... enumeration of extended format options
#
#-----------------------------------------------------------------
package MRS::XFormat;

our $VERSION = '1.0.1'; # VERSION

use constant {
    CSS_CLASS   => 'css_class',
    URL_PREFIX  => 'url_prefix',
    REMOVE_DEAD => 'remove_dead_links',
    ONLY_LINKS  => 'only_links',
};

#-----------------------------------------------------------------
# Return 1 only if $format is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $format) = @_;
    return 0 unless $format;
    my $regex =
        CSS_CLASS . '|' . URL_PREFIX . '|' . REMOVE_DEAD . '|' . ONLY_LINKS;
    my $regex_c = qr/^($regex)$/;
    $format =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::Algorithm ... enumeration of scoring algorithms
#
#-----------------------------------------------------------------
package MRS::Algorithm;

our $VERSION = '1.0.1'; # VERSION

use constant {
    VECTOR   => 'Vector',
    DICE     => 'Dice',
    JACCARD  => 'Jaccard',
};

#-----------------------------------------------------------------
# Return 1 only if $algorithm is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $algorithm) = @_;
    return 0 unless $algorithm;
    my $regex = VECTOR . '|' . DICE . '|' . JACCARD;
    my $regex_c = qr/^($regex)$/;
    $algorithm =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::Operator ... enumeration of operators
#
#-----------------------------------------------------------------
package MRS::Operator;

our $VERSION = '1.0.1'; # VERSION

use constant {
    CONTAINS       => ':',
    LT             => 'LT',
    LE             => 'LE',
    EQ             => 'EQ',
    GT             => 'GT',
    GE             => 'GE',
    UNION          => 'UNION',
    INTERSECTION   => 'INTERSECTION',
    NOT            => 'NOT',
    OR             => 'OR',
    AND            => 'AND',
    ADJACENT       => 'ADJACENT',
    CONTAINSSTRING => 'CONTAINSSTRING',
};

#-----------------------------------------------------------------
# Return 1 only if $query contains at least one of the recognized
# operators (which qualifies it for an expression)
# -----------------------------------------------------------------
sub contains {
    my ($class, $query) = @_;
    return 0 unless $query;
    my $regex =
        UNION . '|' . INTERSECTION .
        '|' . LT . '|' . LE. '|' . EQ . '|' . GT . '|' . GE .
        '|' . NOT . '|' . '|' . OR . '|' . AND .
        '|' . ADJACENT . '|' . CONTAINSSTRING;
    my $regex_c1 = qr/\W+($regex)\W+/;
    my $regex_c2 = qr/:/;
    $query =~ $regex_c1 or $query =~ $regex_c2;
}

#-----------------------------------------------------------------
#
#  MRS::JobStatus ... enumeration of blast job states
#
#-----------------------------------------------------------------
package MRS::JobStatus;

our $VERSION = '1.0.1'; # VERSION

use constant {
    UNKNOWN  => 'unknown',
    QUEUED   => 'queued',
    RUNNING  => 'running',
    ERROR    => 'error',
    FINISHED => 'finished',
};

#-----------------------------------------------------------------
# Return 1 only if $status is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $status) = @_;
    return 0 unless $status;
    my $regex = UNKNOWN . '|' . QUEUED . '|' . RUNNING . '|' . ERROR . '|' . FINISHED;
    my $regex_c = qr/^($regex)$/;
    $status =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::BlastOutputFormat
#
#-----------------------------------------------------------------
package MRS::BlastOutputFormat;

our $VERSION = '1.0.1'; # VERSION

use constant {
    XML   => 'xml',
    HITS  => 'hits',
    FULL  => 'full',
    STATS => 'stats',
};

#-----------------------------------------------------------------
# Return 1 only if $format is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $format) = @_;
    return 0 unless $format;
    my $regex = XML . '|' . HITS . '|' . FULL . '|' . STATS;
    my $regex_c = qr/^($regex)$/;
    $format =~ $regex_c;
}

1;


=pod

=head1 NAME

MRS::Client - Used constants in the MRS::Client's modules

=head1 VERSION

version 1.0.1

=head1 NAME

MRS::Constants - part of a SOAP-based client accessing MRS databases

=head1 REDIRECT

For the full documentation of the project see please:

   perldoc MRS::Client

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
