package Groonga::API::Test;

use strict;
use warnings;
use base 'Exporter';
use Test::More;
use Path::Extended;
use JSON::XS;
use Groonga::API;
use Groonga::API::Constants qw/:all/;
use version;
no bytes;

our @EXPORT = (
  qw/
    tmpdir tmpfile
    grn_test ctx_test db_test
    table_test table_column_test
    indexed_table_test
    load_into_table
    version_ge
  /, 
  @Test::More::EXPORT, 
  @JSON::XS::EXPORT,
  @Groonga::API::Constants::EXPORT_OK,
);

our %TMPDIR;
our $ROOT;

sub version_ge {
  my $version = shift;
  version->parse('v'.Groonga::API::get_version()) >= version->parse('v'.$version) ? 1 : 0;
}

sub tmpdir { 
  $TMPDIR{$$} ||= do {
    $ROOT ||= do {
      my $root = file(__FILE__)->parent;
      until ($root->file('Makefile.PL')->exists) {
        my $parent = $root->parent;
        if ($root eq $parent) {
          BAIL_OUT "failed to find root";
        }
        $root = $parent;
      }
      $root;
    };
    my $dir = $ROOT->subdir("tmp/$$");
    $dir->remove if $dir->exists;
    $dir;
  };
}

sub tmpfile { tmpdir()->file(shift)->stringify }

sub grn_test {
  my ($test, %opts) = @_;

  my $tmpdir = tmpdir()->mkdir;

  Groonga::API::init() and BAIL_OUT;

  eval { $test->() };
  diag $@ if $@;

  Groonga::API::fin();

  $tmpdir->remove;
}

sub ctx_test {
  my ($test, %opts) = @_;

  grn_test(sub {
    if (Groonga::API::get_major_version() > 1) {
      Groonga::API::default_logger_set_max_level(GRN_LOG_DUMP);
    }
    if (Groonga::API::get_major_version() > 2) {
      my $logdir = $ROOT ? $ROOT->subdir("tmp/log")->mkdir : ".";
      Groonga::API::default_logger_set_path("$logdir/groonga.log");
    }

    my $ctx = Groonga::API::ctx_open(GRN_CTX_USE_QL);
    if ($ctx and ref $ctx eq "Groonga::API::ctx") {
      eval { $test->($ctx) };
      diag $@ if $@;

      if (Groonga::API::get_major_version() > 1) {
        Groonga::API::ctx_close($ctx);
      } else {
        Groonga::API::ctx_fin($ctx);
      }
    }
    else {
      fail "failed to prepare a context";
    }
  }, %opts);
}

sub db_test {
  my ($test, %opts) = @_;

  my $dbfile = tmpfile('test.db');

  ctx_test(sub {
    my $ctx = shift;

    my $db = Groonga::API::db_create($ctx, $dbfile, undef);
    if ($db and ref $db eq "Groonga::API::obj") {
      eval { $test->($ctx, $db) };
      diag $@ if $@;

      Groonga::API::obj_unlink($ctx, $db);
    }
    else {
      fail "failed to prepare a database";
    }
  }, %opts);
}

sub table_test {
  my ($test, %opts) = @_;

  my $table_key = $opts{table_key} || GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_HASH_KEY;

  db_test(sub {
    my ($ctx, $db) = @_;

    my $name = "table";
    my $keytype = (($table_key & GRN_OBJ_TABLE_TYPE_MASK) == GRN_OBJ_TABLE_NO_KEY) ? undef : Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
    my $valtype = Groonga::API::ctx_at($ctx, GRN_DB_UINT32);
    my $table = Groonga::API::table_create($ctx, $name, bytes::length($name), undef, $table_key, $keytype, $valtype);
    if ($table and ref $table eq "Groonga::API::obj") {
      eval { $test->($ctx, $db, $table) };
      diag $@ if $@;

      Groonga::API::obj_unlink($ctx, $table);
    }
    else {
      fail "failed to prepare a table";
    }
  }, %opts);
}

sub table_column_test {
  my ($test, %opts) = @_;

  table_test(sub {
    my ($ctx, $db, $table) = @_;

    my $name = "text";
    my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
    my $column = Groonga::API::column_create($ctx, $table, $name, bytes::length($name), undef, GRN_OBJ_PERSISTENT, $type);
    if ($column and ref $table eq "Groonga::API::obj") {
      eval { $test->($ctx, $db, $table, $column) };
      diag $@ if $@;

      Groonga::API::obj_unlink($ctx, $column);
    }
    else {
      fail "failed to prepare a column";
    }
  }, %opts);
}

sub indexed_table_test {
  my ($test, %opts) = @_;

  my $table_key = $opts{index_table_key} || GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_PAT_KEY|GRN_OBJ_KEY_NORMALIZE;

  table_column_test(sub {
    my ($ctx, $db, $table, $column) = @_;

    my $table_name = "index_table";
    my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
    my $index_table = Groonga::API::table_create($ctx, $table_name, bytes::length($table_name), undef, $table_key, $type, undef);
    ok defined $index_table, "created index table";

    my $tokenizer = Groonga::API::ctx_at($ctx, GRN_DB_BIGRAM);
    my $rc = Groonga::API::obj_set_info($ctx, $index_table, GRN_INFO_DEFAULT_TOKENIZER, $tokenizer);
    is $rc => GRN_SUCCESS, "set tokenizer";

    my $index_name = "index";
    my $index_column = Groonga::API::column_create($ctx, $index_table, $index_name, bytes::length($index_name), undef, GRN_OBJ_COLUMN_INDEX|GRN_OBJ_WITH_POSITION, $table);

    my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_UINT32);
    my $source_id = pack 'L', Groonga::API::obj_id($ctx, $column);
    Groonga::API::bulk_write($ctx, $bulk, $source_id, bytes::length($source_id));
    $rc = Groonga::API::obj_set_info($ctx, $index_column, GRN_INFO_SOURCE, $bulk);
    is $rc => GRN_SUCCESS, "set source";

    if ($index_table and ref $index_table eq "Groonga::API::obj") {
      eval { $test->($ctx, $db, $table, $column, $index_table, $index_column) };
      diag $@ if $@;

      Groonga::API::obj_unlink($ctx, $index_column);
      Groonga::API::obj_unlink($ctx, $index_table);
    }
    else {
      fail "failed to prepare an index table";
    }
  }, %opts);
}

sub load_into_table {
  my ($ctx, $data, %opts) = @_;

  my $table_name = $opts{table_name} || "table";

  my $json = encode_json($data);
  my $rc = Groonga::API::load($ctx, GRN_CONTENT_JSON,
    $table_name, bytes::length($table_name),
    undef, 0,
    $json, bytes::length($json),
    undef, 0,
    undef, 0,
  );
}

1;

__END__

=head1 NAME

Groonga::API::Test

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
