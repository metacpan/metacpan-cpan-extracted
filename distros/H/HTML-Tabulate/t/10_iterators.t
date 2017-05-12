# iterator testing - DBIx::Recordset and Class::DBI iterators
# 

use strict;
use Test::More;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/lib";

plan skip_all => '$ENV{HTML_TABULATE_TEST_DSN} not set - skipping db iterator tests'
  unless $ENV{HTML_TABULATE_TEST_DSN};
plan skip_all => 'DBI not installed'
  unless eval { require DBI };

# Load result strings
my %result = ();
my $test = "$Bin/t10";
die "missing data dir $test" unless -d $test;
opendir my $datadir, $test or die "can't open directory $test";
for (readdir $datadir) {
  next if m/^\./;
  open my $fh, "<$test/$_" or die "can't read $test/$_";
  { 
    local $/ = undef;
    $result{$_} = <$fh>;
  }
  close $fh;
}
close $datadir;

my $t = HTML::Tabulate->new({
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  table => { border => 0, class => 'table' },
  thtr => { class => 'thtr' },
  tr => { class => 'tr' },
  labels => 1,
  null => '-',
  trim => 1,
});

my $dbh;
SKIP: {
  my $db_tests = 2;

  # Setup test data
  ok($dbh = DBI->connect(
      $ENV{HTML_TABULATE_TEST_DSN},
      $ENV{HTML_TABULATE_TEST_USER},
      $ENV{HTML_TABULATE_TEST_PASS},
      { RaiseError => 1 }), 
    "connected to db '$ENV{HTML_TABULATE_TEST_DSN}' ok");
  ok($dbh->do("drop table if exists emp_tabulate"), 'drop table emp_tabulate ok');
  ok($dbh->do(qq(
    create table emp_tabulate (
      emp_id integer unsigned auto_increment primary key,
      emp_name varchar(255),
      emp_title varchar(255),
      emp_birth_dt date
    )
  )), 'create table emp_tabulate ok');
  ok(eval {
    $dbh->do(qq(
      insert into emp_tabulate values(123, 'Fred Flintstone', 'CEO', '1971-04-30')
    ));
    $dbh->do(qq(
      insert into emp_tabulate values(456, 'Barney Rubble', 'Lackey', '1975-08-04')
    ));
    $dbh->do(qq(
      insert into emp_tabulate values(789, 'Dino  ', 'Pet', null)
    ));
  }, 'emp_tabulate inserts ok');

  # DBIx::Recordset
  SKIP: {
    eval { require DBIx::Recordset };
    skip "DBIx::Recordset not installed", $db_tests if $@;

    my $set = eval { DBIx::Recordset->SetupObject({
      '!DataSource' => $dbh,
      '!Table' => 'emp_tabulate',
      '!PrimKey' => 'emp_id',
    }) };
    skip "DBIx::Recordset employee retrieve failed", $db_tests if $@;
    $set->Select;

    # Render1
    my $table = $t->render($set);
#   print $table, "\n";
    is($table, $result{render1}, "DBIx::Recordset render1 okay");

    # Render2 (across)
    $table = $t->render($set, { style => 'across' });
#   print $table, "\n";
    is($table, $result{render2}, "DBIx::Recordset render2 okay");
  }

  SKIP: {
    # Class::DBI setup
    eval { require Class::DBI } or skip "Class::DBI not installed", $db_tests;
    # Define a temp Class::DBI Employee class
    eval qq(
      package Employee;
      use base 'Class::DBI';
      __PACKAGE__->table('emp_tabulate');
      __PACKAGE__->columns(Essential => qw(emp_id emp_name emp_title emp_birth_dt));
    );
    { 
      no warnings;
      *Employee::db_Main = sub { $dbh };
    }
  
    package main;
    my $iter = eval { Employee->retrieve_all };
    skip "Class::DBI employee retrieve failed: $@", $db_tests if $@;
 
    # Render1
    my $table = $t->render($iter);
#   print $table, "\n";
    is($table, $result{render1}, "Class::DBI render1 okay");

    # Render2 (across)
    $table = $t->render($iter, { style => 'across' });
#   print $table, "\n";
    is($table, $result{render2}, "Class::DBI render2 okay");
  }

  SKIP: {
    # DBIx::Class setup
    eval { require DBIx::Class } or skip "DBIx::Class not installed", $db_tests;
    require HTML::Tabulate::Schema;
  
    my $schema = eval { HTML::Tabulate::Schema->connect(sub { $dbh }) }
      or skip("DBIx::Class schema connect failed: $@", $db_tests);
    my $iter = $schema->resultset('EmpTabulate')->search({}, {
        # Join to self and add a joined column for get_column testing
        join => 'self_join',
        '+columns' => {
          joined_emp_title  => 'self_join.emp_title',
        },
      }) or skip("DBIx::Class employee iterator setup failed: $@", $db_tests);
 
    # Render1
    my $table = $t->render($iter);
    is($table, $result{render1}, "DBIx::Class render1 okay");

    # Render2 (across)
    $table = $t->render($iter, { style => 'across' });
    is($table, $result{render2}, "DBIx::Class render2 okay");

    # Render4 (render method column name())
    $table = $t->render($iter, {
      fields => [ qw(emp_id name joined_emp_title) ],
      labels => { 'joined_emp_title' => 'Emp Title' },
    });
    is($table, $result{render4}, "DBIx::Class render4 okay");
  }

  eval { $dbh->do("drop table if exists emp_tabulate") };
}

$dbh->disconnect if ref $dbh;

# Code iterators
$t = HTML::Tabulate->new({ labels => 1, trim => 1, null => '-' });
my @data = ( 
  [ '123', 'Fred Flintstone', 'CEO' ], 
  [ '456', 'Barney Rubble', 'Lackey' ],
  [ '789', 'Wilma Flintstone   ', 'CFO' ], 
  [ '777', 'Betty Rubble', '' ], 
);
my $iterator = sub {
  return shift @data;
};
my $table = $t->render($iterator, { fields => [ qw(emp_id emp_name emp_title) ] });
is($table, $result{render3}, "code iterator ok (arrayrefs)");

$t = HTML::Tabulate->new({ labels => 1, trim => 1, null => '-' });
@data = ( 
  { emp_id => '123', emp_name => 'Fred Flintstone',     emp_title => 'CEO' }, 
  { emp_id => '456', emp_name => 'Barney Rubble',       emp_title => 'Lackey' },
  { emp_id => '789', emp_name => 'Wilma Flintstone   ', emp_title => 'CFO' }, 
  { emp_id => '777', emp_name => 'Betty Rubble' }, 
);
$iterator = sub {
  return shift @data;
};
$table = $t->render($iterator);
is($table, $result{render3}, "code iterator ok (hashrefs, derived fields)");

done_testing;

