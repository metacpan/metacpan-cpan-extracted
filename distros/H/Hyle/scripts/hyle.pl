#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use DBI;
use DBIx::Class;
use DBIx::Class::Schema::Loader;
use Class::Load;
use Getopt::Long;
use Plack::Runner;
use Hyle;

sub run {
    my ($dsn,$username,$password);
    GetOptions("dsn=s" => \$dsn, "user=s" => \$username, "pass=s" => \$password)
        or die "can't get the options";


    unless ($dsn) {
    print <<"EOF";
    Usage: hyle.pl --dsn "dbi:SQLite:dbname=dbfile"
EOF

        exit 1;
    }

    $0 = "hyle.pl --dsn $dsn" if $password;

    $password ||= '';
    $username ||= '';

    my $tempdir = tempdir(CLEANUP => 1);
    DBIx::Class::Schema::Loader::make_schema_at(
        'Schema',
        { dump_directory => $tempdir },
        [ $dsn,  $username,$password, {} ],
    );


    push @INC, $tempdir;

    eval {
        require Schema;
        Schema->import();
        1;
    } or do {
        my $err = $@ || "unknown";
        die $err;
    };

# get the scema
    my $schema = Schema->connect($dsn, $username, $password);

    for my $source ($schema->sources() ) {
        # hack, add something as a primary column if no primary column(s) are defined
        my $source_class = $schema->source($source);
        next if $source_class->primary_columns();

        print STDERR <<"EOF";
        WARNING: Table $source has no primary key defined, defaulting to using all columns.
EOF
        $source_class->set_primary_key($source_class->columns());
    }

    my $app    = Hyle->new( schema => $schema )->to_app;
    my $runner = Plack::Runner->new();
    $runner->parse_options(@ARGV);

    $runner->run($app);
}

run() unless caller();

__END__

head1 NAME 

hyle.pl

=head1 DESCRIPTION

Simple REST API database backend implemented with Plack and DBIx::Class.

For more details, see L<Hyle>.

=head1 SYNOPSIS

    # hyle.pl --dsn "dbi:SQLite:dbname=/home/user/some_database.sqlite3"
    # HTTP::Server::PSGI: Accepting connections at http://0:5000/
    # ...

=head1 OPTIONS

=head2 dsn

=head2 user

=head2 pass

This script uses Plack::Runner internally and therefore also accepts all parameters that plackup accepts.





