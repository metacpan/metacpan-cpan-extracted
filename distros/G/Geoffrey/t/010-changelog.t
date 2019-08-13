use Test::More tests => 17;

use strict;
use FindBin;
use warnings;
use Test::Exception;

use_ok 'DBI';

require_ok('Geoffrey');
use_ok 'Geoffrey';

my $o_geoffrey =
  new_ok( 'Geoffrey', [ converter_name => 'SQLite', dbh => DBI->connect("dbi:SQLite:database=.tmp.sqlite"), ] );

ok( $o_geoffrey->isa('Geoffrey'),                'Geoffrey is really Geoffrey' );
ok( $o_geoffrey->reader->isa('Geoffrey::Read'),  'Check if reader is Geoffrey::Read' );
ok( $o_geoffrey->writer->isa('Geoffrey::Write'), 'Check if writer is Geoffrey::Write' );

my $o_writer = $o_geoffrey->writer;
is( $o_writer->author,                     'Mario Zieschang',     'author sub test' );
is( $o_writer->io_name,                    'None',                'io_name sub test' );
is( $o_writer->converter->changelog_table, 'geoffrey_changelogs', 'changelog_table sub test' );
ok( $o_writer->converter->isa('Geoffrey::Converter::SQLite'),  'converter sub test' );
ok( $o_writer->dbh->isa('DBI::db'),                            'dbh sub test' );
ok( $o_writer->changelog_io->isa('Geoffrey::Changelog::None'), 'changelog_io sub test' );
ok( $o_writer->changeset->isa('Geoffrey::Changeset'),          'changeset sub test' );

is(
    $o_geoffrey->write( q~.~, 'main', 1 ), q~{
  'changelogs' => [
                    '1-indexes',
                    '2-views'
                  ]
}
~, 'changeset sub test'
);

throws_ok {
    Geoffrey->new( converter_name => 'SQLite', dbh => "" );
}
'Geoffrey::Exception::Database::NoDbh', 'Test esception if dbh is wrong datatype';

throws_ok {
    Geoffrey->new( converter_name => 'SQLite', );
}
'Geoffrey::Exception::Database::NoDbh', 'Test esception if dbh is missing';
