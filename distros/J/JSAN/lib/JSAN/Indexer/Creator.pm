package JSAN::Indexer::Creator;
use strict;
use warnings;

use base 'Class::DBI';
use Class::DBI::DATA::Schema translate => [ 'MySQL', 'SQLite' ];
use LWP::Simple;
use YAML;

our $VERSION      = '0.05';
our $MASTER_INDEX = 'http://openjsan.org/index.yaml';

sub create_index_db {
    my ($class, $index, $dsn, $index_db, $location) = @_;
    if ($JSAN::Indexer::LOADER) {
        $_->db_Main->disconnect for $JSAN::Indexer::LOADER->classes;
    }
    unlink $index_db;
    $class->connection($dsn);
    $location ||= $MASTER_INDEX;

    my $yaml = get($location);
    die "Could not load YAML Index from $location" unless $yaml;
    
    my $yaml_index = Load($yaml);
    die "Couldn't parse YAML stream" unless $yaml_index;

    $class->run_data_sql;
    do {
        local $^W;
        $index = $index->new();
    };
    $class->_insert_data($index->loader, $yaml_index);
}

sub _insert_data {
    my ($self, $loader, $yaml) = @_;

    foreach my $login ( keys %{$yaml->{authors}} ) {
        my $author = $yaml->{authors}->{$login};
        $loader->find_class('author')->create({
            login => $login,
            doc   => $author->{doc},
            email => $author->{email},
            url   => $author->{url},
            name  => $author->{name},
        });
    }
    
    foreach my $name ( keys %{$yaml->{distributions}} ) {
        my $distribution = $yaml->{distributions}->{$name};
        my $dist = $loader->find_class('distribution')->create({
            name   => $name,
            doc    => $distribution->{doc},
        });
        my $releases = $distribution->{releases};
        
        foreach my $rel ( @{$releases} ) {
            $loader->find_class('release')->create({
                distribution => $dist->name,
                author       => $rel->{author},
                checksum     => $rel->{checksum},
                created      => $rel->{created},
                doc          => $rel->{doc},
                meta         => Dump($rel->{meta}),
                latest       => $rel->{latest},
                source       => $rel->{source},
                version      => $rel->{version},
                srcdir       => $rel->{srcdir},
            });
        }
    }
    
    foreach my $name ( keys %{$yaml->{libraries}} ) {
        my $library = $yaml->{libraries}->{$name};
        $loader->find_class('library')->create({
            name         => $name,
            version      => $library->{version},
            doc          => $library->{doc},
            distribution => $library->{distribution_name},
            release      => $loader->find_class('release')->search(
                distribution => $library->{distribution_name},
                version      => $library->{distribution_version},
            )->first->id,
        });
    }
}

=head1 NAME

JSAN::Indexer::Creator -- Convert the YAML Index to SQLite

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

1;

__DATA__

DROP TABLE IF EXISTS author;
CREATE TABLE author (
    login    varchar(100) not null primary key,
    name     varchar(100) not null,
    doc      varchar(100) not null,
    email    varchar(100) not null,
    url      varchar(100)
);

DROP TABLE IF EXISTS distribution;
CREATE TABLE distribution (
    name     varchar(100) not null primary key,
    doc      varchar(100) not null
);

DROP TABLE IF EXISTS release;
CREATE TABLE release (
    id           int not null auto_increment primary key,
    distribution varchar(100) not null references distribution,
    author       varchar(100) not null references author,
    checksum     varchar(100) not null,
    created      varchar(100) not null,
    doc          varchar(100) not null,
    meta         text,
    latest       int not null,
    source       varchar(100) not null,
    srcdir       varchar(100) not null,
    version      varchar(100)
);

DROP TABLE IF EXISTS library;
CREATE TABLE library (
    name         varchar(100) not null primary key,
    distribution varchar(100) not null references distribution,
    release      int not null references release,
    version      varchar(100),
    doc          varchar(100) not null
);
