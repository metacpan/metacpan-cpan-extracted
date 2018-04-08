package Memorator::Backend::Mojo::SQLite;
use strict;
use warnings;
{ our $VERSION = '0.006'; }

use Memorator::Util ();
use constant TABLE_NAME => 'eid2jid';

use Mojo::Base -base;

has mojodb => sub { die "missing mandatory parameter 'mojodb'" };
has name   => sub { die "missing mandatory parameter 'name'" };

sub add_mapping {
   my ($self, $eid, $jid) = @_;
   $self->_db->insert($self->table_name => {eid => $eid, jid => $jid});
}

sub _db { return shift->mojodb->db }

sub deactivate_mapping {
   my ($self, $id) = @_;
   $self->_db->query($self->deactivate_mapping_query($id));
}

sub deactivate_mapping_query {
   my ($self, $id) = @_;
   my $table = $self->table_name;
   return ("UPDATE $table SET active = 0 WHERE id = ?", $id);
}

sub ensure_table {
   my $self = shift;
   $self->mojodb->migrations->name($self->name)
     ->from_string($self->migration)->migrate;
   return $self;
} ## end sub ensure_table

sub mapping_between {
   my ($self, $eid, $jid) = @_;
   my $res = $self->_db->query($self->mapping_between_query($eid, $jid));
   my $e2j = $res->hash;
   $res->finish;
   return $e2j;
} ## end sub mapping_between

sub mapping_between_query {
   my ($self, $eid, $jid) = @_;
   my $table = $self->table_name;
   my $query =
       "SELECT * FROM $table "
     . " WHERE  jid = ? AND eid = ? AND active > 0 "
     . " AND id IN (SELECT MAX(id) FROM $table WHERE eid = ?)";
   return ($query, $jid, $eid, $eid);
} ## end sub mapping_between_query

sub remove_mapping {
   my ($self, $id) = @_;
   $self->_db->delete($self->table_name, {id => $id});
}

sub stale_mappings {
   my $self = shift;
   my $res = $self->_db->query($self->stale_mappings_query) or return;
   return $res->hashes->each;
}

sub stale_mappings_query {
   my $self  = shift;
   my $table = $self->table_name;
   return
       "SELECT * FROM $table "
     . "  WHERE (id, eid) NOT IN "
     . "  (SELECT MAX(id), eid FROM $table GROUP BY eid)";
} ## end sub stale_mappings_query

sub table_name { Memorator::Util::local_name(shift->name, TABLE_NAME) }

1;
