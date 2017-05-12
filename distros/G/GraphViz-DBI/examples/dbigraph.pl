#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use DBI;
use GraphViz::DBI;

our $VERSION='0.01';

my %opts = (
    help     => 0,
    man      => 0,
    verbose  => 0,
    dbd      => '',
    dbname   => '',
    dsn      => '',
    user     => '',
    pass     => '',
    as       => '',
);

GetOptions(\%opts, qw(
    help
    man
    verbose
    dbd=s
    dbname=s
    dsn=s
    user=s
    pass=s
    as=s
)) || pod2usage(2);

pod2usage(1) if $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};
$opts{dsn} = "dbi:$opts{dbd}:dbname=$opts{dbname}"
    if $opts{dbd} && $opts{dbname};
pod2usage(1) unless $opts{dsn};
$opts{as} ||= 'png';

my $dbh = DBI->connect(@opts{qw/dsn user pass/});
my $as = "as_$opts{as}";
print GraphViz::DBI->new($dbh)->graph_tables->$as;
$dbh->disconnect;

__END__

=head1 NAME

dbigraph.pl - graph database tables and their relations

=head1 SYNOPSIS

dbigraph.pl --dbd=Pg --dbname=mydb --user=marcel | xv -

dbigraph.pl --dsn='dbi:Pg:dbname=mydb' --user=marcel --as=png >mydb.png

=head1 DESCRIPTION

This program constructs a GraphViz graph for a database showing tables
and connecting them if they are related.

=head1 OPTIONS

This section describes the supported command line options. Minimum
matching is supported.

=over 4

=item B<--dbd>

Database drive to use, e.g. 'Pg'. Only if given together with the
C<--dbname> option will this be used for the DSN.

=item B<--dbname>

Database name to use. Only if given together with the C<--dbd> option
will this be used for the DSN.

=item B<--dsn>

DSN to use, e.g. 'dbi:Pg:mydb'. Only used if C<--dbd> and C<--dbname>
aren't given.

=item B<--user>

Username to use for connecting to the database.

=item B<--pass>

Password to use for connecting to the database.

=item B<--as>

Output format, e.g. 'gif', 'png', etc. Defaults to 'png' if not given.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<--verbose>

Print information messages as we go along.

=back

=head1 BUGS

Some. Possibly. I haven't fully tested it.

=head1 AUTHOR

Marcel GrE<uuml>nauer E<lt>marcel@codewerk.comE<gt>

=head1 COPYRIGHT

Copyright 2001 Marcel GrE<uuml>nauer. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

GraphViz(3pm), GraphViz::DBI(3pm).

=cut
