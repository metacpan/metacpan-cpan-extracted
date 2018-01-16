#
# $Id: Sqlite.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# client::sqlite Brik
#
package Metabrik::Client::Sqlite;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         db => [ qw(sqlite_file) ],
         autocommit => [ qw(0|1) ],
         dbh => [ qw(INTERNAL) ],
      },
      attributes_default => {
         autocommit => 1,
      },
      commands => {
         open => [ qw(sqlite_file|OPTIONAL) ],
         execute => [ qw(sql_query) ],
         create => [ qw(table_name fields_array key|OPTIONAL) ],
         insert => [ qw(table_name data_hash) ],
         select => [ qw(table_name fields_array|OPTIONAL key|OPTIONAL) ],
         commit => [ ],
         show_tables => [ ],
         describe_table => [ ],
         list_types => [ ],
         close => [ ],
      },
      require_modules => {
         'DBI' => [ ],
         'DBD::SQLite' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('open', $db) or return;

   my $dbh = DBI->connect('dbi:SQLite:dbname='.$db,'','', {
      AutoCommit => $self->autocommit,
      RaiseError => 1,
      PrintError => 0,
      PrintWarn => 0,
      #HandleError => sub {
         #my ($errstr, $dbh, $arg) = @_;
         #die("DBI: $errstr\n");
      #},
   });
   if (! $dbh) {
      return $self->log->error("open: DBI: $DBI::errstr");
   }

   $self->dbh($dbh);

   return 1;
}

sub execute {
   my $self = shift;
   my ($sql) = @_;

   my $dbh = $self->dbh;
   $self->brik_help_run_undef_arg('open', $dbh) or return;
   $self->brik_help_run_undef_arg('execute', $sql) or return;

   $self->log->debug("execute: sql[$sql]");

   my $sth = $dbh->prepare($sql);

   return $sth->execute;
}

sub commit {
   my $self = shift;

   my $dbh = $self->dbh;
   $self->brik_help_run_undef_arg('open', $dbh) or return;

   if ($self->autocommit) {
      $self->log->verbose("commit: skipping cause autocommit is on");
      return 1;
   }

   eval {
      $dbh->commit;
   };
   if ($@) {
      chomp($@);
      return $self->log->warning("commit: $@");
   }

   return 1;
}

sub create {
   my $self = shift;
   my ($table, $fields, $key) = @_;

   $self->brik_help_run_undef_arg('create', $table) or return;
   $self->brik_help_run_undef_arg('create', $fields) or return;
   $self->brik_help_run_invalid_arg('create', $fields, 'ARRAY') or return;

   # create table TABLE (stuffid INTEGER PRIMARY KEY, field1 VARCHAR(512), field2, date DATE);
   # insert into TABLE (field1) values ("value1");

   my $sql = 'CREATE TABLE '.$table.' (';
   for my $field (@$fields) {
      # Fields are table fields, we normalize them (space char not allowed)
      $field =~ s/ /_/g;
      $sql .= $field;
      if (defined($key) && $field eq $key) {
         $sql .= ' PRIMARY KEY NOT NULL';
      }
      $sql .= ',';
   }
   $sql =~ s/,$//;
   $sql .= ');';

   $self->log->verbose("create: $sql");

   return $self->execute($sql);
}

sub insert {
   my $self = shift;
   my ($table, $data) = @_;

   $self->brik_help_run_undef_arg('insert', $table) or return;
   $self->brik_help_run_undef_arg('insert', $data) or return;

   my @data = ();
   if (ref($data) eq 'ARRAY') {
      for my $this (@$data) {
         if (ref($this) ne 'HASH') {
            $self->log->verbose('insert: not a hash, skipping');
            next;
         }
         push @data, $this;
      }
   }
   else {
      if (ref($data) ne 'HASH') {
         return $self->log->error("insert: Argument 'data' must be HASHREF");
      }
      push @data, $data;
   }

   for my $this (@data) {
      my $sql = 'INSERT INTO '.$table.' (';
      # Fields are table fields, we normalize them (space char not allowed)
      my @fields = map { s/ /_/g; $_ } keys %$this;
      my @values = map { $_ } values %$this;
      $sql .= join(',', @fields);
      $sql .= ') VALUES (';
      for (@values) {
         $sql .= "\"$_\",";
      }
      $sql =~ s/,$//;
      $sql .= ')';

      $self->log->verbose("insert: $sql");

      $self->execute($sql);
   }

   return 1;
}

sub select {
   my $self = shift;
   my ($table, $fields, $key) = @_;

   my $dbh = $self->dbh;
   $fields ||= [ '*' ];
   $self->brik_help_run_undef_arg('open', $dbh) or return;
   $self->brik_help_run_undef_arg('select', $table) or return;
   $self->brik_help_run_invalid_arg('select', $fields, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('select', $fields) or return;

   my $sql = 'SELECT ';
   for (@$fields) {
      # Fields are table fields, we normalize them (space char not allowed)
      s/ /_/g;
      $sql .= "$_,";
   }
   $sql =~ s/,$//;
   $sql .= ' FROM '.$table;

   my $sth = $dbh->prepare($sql);
   my $rv = $sth->execute;

   if (! defined($key)) {
      return $sth->fetchall_arrayref;
   }

   return $sth->fetchall_hashref($key);
}

sub show_tables {
   my $self = shift;

   my $dbh = $self->dbh;
   $self->brik_help_run_undef_arg('open', $dbh) or return;

   # $dbh->table_info(undef, $schema, $table, $type, \%attr);
   # $type := 'TABLE', 'VIEW', 'LOCAL TEMPORARY' and 'SYSTEM TABLE'
   my $sth = $dbh->table_info(undef, 'main', '%', 'TABLE');

   my $h = $sth->fetchall_arrayref;
   my @r = ();
   for my $this (@$h) {
      push @r, $this->[-1];  # Last entry is the CREATE TABLE one.
   }

   return \@r;
}

sub list_types {
   my $self = shift;

   return [
      'INTEGER',
      'DATE',
      'VARCHAR(int)',
   ];
}

# https://metacpan.org/pod/DBI#table_info
sub describe_table {
#my $sth = $dbh->column_info(undef,'table_name',undef,undef);
#$sth->fetchall_arrayref;
}

sub close {
   my $self = shift;

   my $dbh = $self->dbh;
   if (defined($dbh)) {
      $dbh->commit;
      $dbh->disconnect;
      $self->dbh(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Sqlite - client::sqlite Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
