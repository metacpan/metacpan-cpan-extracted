# $Id: /mirror/gungho/lib/Gungho/Plugin/Statistics/Storage/SQLite.pm 4238 2007-10-29T15:08:17.605700Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Plugin::Statistics::Storage::SQLite;
use strict;
use warnings;
use base qw(Gungho::Base);
use DBI;
use File::Temp;
use Path::Class::Dir;
use Sys::Hostname ();

__PACKAGE__->mk_accessors($_) for qw(file _dbh);

sub setup
{
    my $self = shift;
    my $dir = Path::Class::Dir->new( ($self->config && $self->config->{storage}) || File::Spec->tmpdir);
    my $file = $dir->file(sprintf("gungho-stats-%s-%s-%06d", Sys::Hostname::hostname(), $$, rand(100000)));

    $self->file( $file );
}


sub dbh
{
    my $self = shift;

    my $dbh = $self->_dbh;
    if (! $dbh || ! $dbh->ping) {
        my $file = $self->file;

        $dbh = DBI->connect(
            "dbi:SQLite:dbname=$file",
            undef,
            undef,
            { RaiseError => 1, AutoCommit => 1 }
        );

        $dbh->do(<<EOSQL);
CREATE TABLE counters (
    name  TEXT PRIMARY KEY,
    value INTEGER NOT NULL DEFAULT 0
);
EOSQL
        foreach my $name qw(active_requests finished_requests) {
            $dbh->do("INSERT INTO counters (name, value) VALUES (?, ?)", undef, $name, 0);
        }

        $self->_dbh( $dbh );
    }
    return $dbh;
}

sub incr
{
    my ($self, $action) = @_;

    my $dbh  = $self->dbh();
    my $sth  = $dbh->prepare_cached("UPDATE counters SET value = value + 1 WHERE name = ?");
    $sth->execute($action);
    $sth->finish();
}

#sub _dump
#{
#    my ($self, $action) = @_;
#
#    my $dbh  = $self->dbh();
#    my $sth = $dbh->prepare("SELECT value FROM counters");
#    $sth->execute();
#    use Data::Dump;
#    while (my $h = $sth->fetchrow_hashref) {
#        print STDERR Data::Dump::dump($h);
#    }
#}

sub decr
{
    my ($self, $action) = @_;

    my $dbh  = $self->dbh();
    my $sth  = $dbh->prepare_cached("UPDATE counters SET value = value - 1 WHERE name = ?");
    $sth->execute($action);
    $sth->finish();
}

sub get
{
    my ($self, $action) = @_;

    my $dbh  = $self->dbh();
    my $sth = $dbh->prepare_cached("SELECT value FROM counters WHERE name = ?");
    $sth->execute($action);
    my ($value) = $sth->fetchrow_array;
    $sth->finish;
    return $value;
}

sub DESTROY
{
    my $self = shift;
    $self->file->remove if $self->file;
}

1;

__END__

=head1 NAME 

Gungho::Plugin::Statistics::Storage::SQLite

=head1 METHODS

=head2 setup

=head2 dbh

=head2 incr

=head2 decr

=head2 get

=head2 DESTROY

=cut
