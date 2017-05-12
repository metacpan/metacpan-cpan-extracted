package Log::Any::DBI::Query;

our $DATE = '2016-02-22'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use DBI;
use Log::Any::For::Class qw(add_logging_to_class);

my $log_query  = $ENV{LOG_SQL_QUERY}  // 1;
my $log_result = $ENV{LOG_SQL_RESULT} // 0;

sub _precall_logger {
    my $args = shift;
    my $margs = $args->{args};

    my ($meth) = $args->{name} =~ /.+::(.+)/;
    return if $meth =~ /\Afetch.+\z/;
    if ($meth eq 'execute') {
        $log->tracef("SQL query (%s): {{%s}}", $meth, [@{$margs}[1..$#{$margs}]]);
    } else {
        $log->tracef("SQL query (%s): {{%s}}", $meth, $margs->[1]);
    }
}

sub _postcall_logger {
    my $args = shift;

    #$log->tracef("D1: %s", $args->{name});

    my ($meth) = $args->{name} =~ /.+::(.+)/;
    return if $meth =~ /\A(prepare|execute)\z/;
    $log->tracef("SQL result (%s): %s", $meth, $args->{result});
}

sub import {
    my $class = shift;
    my @meths = @_;

    # I put it in $doit in case we need to add more classes from inside $logger,
    # e.g. DBD::*, etc.
    my $doit;
    $doit = sub {
        my @classes = @_;

        add_logging_to_class(
            classes => \@classes,
            precall_logger => \&_precall_logger,
            postcall_logger => \&_postcall_logger,
            filter_methods => sub {
                my $meth = shift;
                return 1 if $log_query && $meth =~
                    /\A(
                         DBI::db::(prepare|do|select.+) |
                         DBI::st::(execute)
                     )\z/x;
                return 1 if $log_result && $meth =~
                    /\A(
                         DBI::db::(do|select.+) |
                         DBI::st::(fetch.+)
                     )\z/x;
                0;
            },
        );
    };

    # DBI is used here to trigger loading of DBI::db
    $doit->("DBI", "DBI::db", "DBI::st");
}

1;
# ABSTRACT: Log DBI queries (and results)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::DBI::Query - Log DBI queries (and results)

=head1 VERSION

This document describes version 0.07 of Log::Any::DBI::Query (from Perl distribution Log-Any-DBI-Query), released on 2016-02-22.

=head1 SYNOPSIS

 use DBI;
 use Log::Any::DBI::Query;

 # now SQL queries will be logged
 my $dbh = DBI->connect("dbi:...", $user, $pass);
 $dbh->do("INSERT INTO table VALUES (...)");

From command-line:

 % TRACE=1 perl -MLog::Any::Adapter::Screen -MLog::Any::DBI::Query your-dbi-app.pl

To also log SQL results:

 % TRACE=1 LOG_SQL_RESULT=1 \
     perl -MLog::Any::Adapter::Screen -MLog::Any::DBI::Query your-dbi-app.pl

Sample log output:

 SQL query: {{INSERT INTO table VALUES (...)}

=head1 DESCRIPTION

This is a simple module you can do to log SQL queries for your L<DBI>-based
applications.

For queries, it logs calls to C<prepare()>, C<do()>, C<select*>.

For results, it logs calls to C<do()>, C<select*>, C<fetch*>.

Compared to L<Log::Any::For::DBI>, it produces a bit less noise if you are only
concerned with logging queries.

=head1 ENVIRONMENT

=head2 LOG_SQL_QUERY (bool, default 1)

=head2 LOG_SQL_RESULT (bool, default 1)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-DBI-Query>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-DBI-Query>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-DBI-Query>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Any::DBI::QueryResult>

L<Log::Any::For::DBI> which logs more methods, including C<connect()>, etc..

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
