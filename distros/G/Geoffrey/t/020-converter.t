use Test::More tests => 10;

use strict;
use FindBin;
use warnings;
use Test::Exception;

use_ok 'DBI';

require_ok('Geoffrey::Role::Converter');
use_ok 'Geoffrey::Role::Converter';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $s_filepath = '.tmp.sqlite';
my $dbh        = DBI->connect("dbi:SQLite:database=$s_filepath");
my $converter  = Geoffrey::Converter::SQLite->new(
    max_version => 3.8,
    dbh         => $dbh
);
is( $converter->check_version('3.7'), 1, 'min version check' );

throws_ok {
    $converter->check_version('3.0');
}
'Geoffrey::Exception::NotSupportedException::Version', 'underneath min version expecting to die';

throws_ok {
    $converter->check_version('3.9');
}
'Geoffrey::Exception::NotSupportedException::Version', 'above min version expecting to die';

throws_ok {
    $converter->type( {} );
}
'Geoffrey::Exception::RequiredValue::ColumnType', 'It is a Pg type and should die in SQLite';

throws_ok {
    $converter->type( { type => 'xml' } );
}
'Geoffrey::Exception::NotSupportedException::ColumnType', 'It is a Pg type and should die in SQLite';

unlink $s_filepath or warn "Could not unlink $s_filepath: $!";
