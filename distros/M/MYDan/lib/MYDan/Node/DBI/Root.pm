package MYDan::Node::DBI::Root;

=head1 NAME

MYDan::Node::DBI::Root - DB interface to MYDan::Node root data

=head1 SYNOPSIS

 use MYDan::Node::DBI::Root;

 my $db = MYDan::Node::DBI::Root->new( '/database/file' );

=cut
use strict;
use warnings;

=head1 METHODS

See MYDan::Util::SQLiteDB.

=cut
use base qw( MYDan::Util::SQLiteDB );

=head1 DATABASE

A SQLITE db has tables of I<two> columns:

 key : node name
 value : info associated with node

=cut
sub define
{
    key => 'TEXT NOT NULL PRIMARY KEY',
    value => 'BLOB',
};

1;
