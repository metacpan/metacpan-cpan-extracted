#!/usr/bin/perl

use warnings;

use FindBin qw( $Bin );
use Module::Build;

my $verbose = grep(/^--showsql$/, @ARGV);
                                                                                                           
my $mb = Module::Build->new(
  'module_name' => 'Locale::Object',
  'license'     => 'unrestricted',
  'requires'    => {
    'perl'               => '5.6.0',
    'DateTime::TimeZone' => 0.4,
    'DateTime'           => 0.3,
    'DBI'                => 0,
    'DBD::SQLite'        => 0,
    'Scalar::Util'       => 1.10,
  },
  'build_requires' => {
    'DBI'           => 0,
    'Module::Build' => '0.21',
    'Test::More'    => 0,
    'Test::Pod'     => 0,
  },
  'configure_requires' => {
    'DBD::SQLite'   => 0,
    'Module::Build' => '0.40',
  },
  recommends => {
    'Finance::Currency::Convert::Yahoo' => '0.2',
    'Finance::Currency::Convert::XE' => '0.25',
  },
  meta_merge => {
    resources => {
      repository  => 'https://github.com/castaway/Locale-Object',
    }
    
  }
);

eval {
  require DBI;
  require DBD::SQLite;
  1;
};

if ($@) {
  print "DBD::SQLite is required to run Build.PL. Please check your system configuration.\n";
  exit 1;
}

my $db = "$Bin/lib/Locale/Object/locale.db";

unlink($db);

my $dbh;

{
  no warnings 'once'; # shut up about $DBI::errstr
  
  $dbh = DBI->connect("dbi:SQLite:$db")
  or die "Couldn't connect to $db: $DBI::errstr";
}

open (my $SQL, '<', "$Bin/locale.sql")
  or die "Couldn't open SQL file ($Bin/locale.sql) to create database: $!";

{
  local $/ = ";\n";
  
  while (<$SQL>) {
    next unless $_;
    print $_ if $verbose;
    $dbh->do($_) or die $dbh->errstr;
  }
}

close $SQL;

$mb->create_build_script;
