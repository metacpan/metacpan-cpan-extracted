# -*- coding: utf-8; mode: cperl -*-
use strict;
# Adjust the number here!
use Test::More tests => 38;
use File::Basename;

use Tie::MAB2::Dualdb;
use Tie::MAB2::Dualdb::Recno;
use Tie::MAB2::Dualdb::Id;
# Add more test here!

use BerkeleyDB qw( DB_CREATE DB_INIT_MPOOL DB_INIT_CDB DB_NEXT DB_RDONLY );

my $dualdb = "t/kafka.dualdb";


{

  # Create the database with one record

  my @tie;
  my $flags = DB_CREATE;
  tie(@tie,
      "Tie::MAB2::Dualdb",
      filename => $dualdb,
      flags => $flags,
     ) or die;

  open my $fh, "t/kafka.mab" or die;
  local $/ = "\n";
  my $rec = <$fh>;
  close $fh;
  $tie[0] = $rec;
  eval { $tie[1] = $rec; }; # must fail
  ok($@, "no duplicates");
  untie @tie;
}

{

  # verify that the two tables exist

  my $e = BerkeleyDB::Unknown->new(
                                   Filename => $dualdb,
                                   Flags => DB_RDONLY
                                  ) or die $BerkeleyDB::Error;
  my $c = $e->db_cursor;
  my ($k, $v) = ("", "") ;
  my %found;
  while ($c->c_get($k, $v, DB_NEXT) == 0) {
    $found{$k}++;
  }
  ok(keys %found == 2, "two tables in database");
  ok($found{id}, "table 'id'");
  ok($found{recno}, "table 'recno'");
}

{

  # verify that there is one record in the array and that it is blessed

  my @tie;
  tie(@tie,
      "Tie::MAB2::Dualdb::Recno",
      filename => $dualdb,
      flags => DB_RDONLY,
     ) or die;
  ok(@tie==1, "one record");
  my $rec = $tie[0];
  ok($rec->isa("MAB2::Record::titel"), "record blessed");

}

{

  # verify that there is one record in the hash and that the value is 0

  my %tie;
  tie(%tie,
      "Tie::MAB2::Dualdb::Id",
      filename => $dualdb,
      flags => DB_RDONLY,
     ) or die;
  ok(keys %tie==1, "exactly one record in hash");
  my($key,$val) = each %tie;
  ok($val == 0, "points to record no 0");

}

{

  # delete that one record

  my @tie;
  my $flags = DB_CREATE;
  tie(@tie,
      "Tie::MAB2::Dualdb",
      filename => $dualdb,
      flags => $flags,
     ) or die;
  eval {@tie = ();}; # impossible
  ok($@, "clear not allowed");
  untie @tie;

}

unlink $dualdb;

{

  # Create the database with 26 records

  # Als das funktionierte, rief einer laut: geil!

  my(@tie,%tie);
  my $flags = DB_CREATE;
  my $tied_array = tie(@tie,
                       "Tie::MAB2::Dualdb",
                       filename => $dualdb,
                       flags => $flags,
                      ) or die;
  my $env = $tied_array->env;
  tie(%tie,
      "Tie::MAB2::Dualdb::Id",
      filename => File::Basename::basename($dualdb),
      flags => $flags,
      env => $env,
     ) or die;

  open my $fh, "t/kafka.mab" or die;
  local $/ = "\n";
  while (my $rec = <$fh>) {
    chomp $rec;
    push @tie, $rec;
    ok($. == scalar keys %tie, "correct keys in hash at record $.");
  }
  close $fh;
  my $tie = @tie;
  ok($tie == 26, "exactly $tie==26 records");

  $tie[12] = "";

  ok(scalar keys %tie == 25, "25 keys in hash after one delete");

  my $rec = $tie[6]->as_string;
  $tie[6] = "";
  $tie[12] = $rec;

  ok(scalar keys %tie == 25, "still 25 keys in hash after a small shuffle");

  undef $tied_array;
  untie @tie;
  untie %tie;
}

unlink $dualdb;
