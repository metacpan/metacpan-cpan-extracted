use Test::More tests => 7;

use strict;
use FindBin;
use warnings;
use File::Spec;
use Data::Dumper;
use Test::Exception;

use Test::Mock::Geoffrey::DBI;
use Test::Mock::Geoffrey::Converter::SQLite;

require_ok('Geoffrey::Write');
use_ok 'Geoffrey::Write';

my $converter = Test::Mock::Geoffrey::Converter::SQLite->new;

my $object = new_ok(
    'Geoffrey::Write',
    [
        'changelog_count', 1, 'author', 'Mario Zieschang',
        'converter', $converter, 'dbh', Test::Mock::Geoffrey::DBI->new
    ]
);

is(
    Data::Dumper->new( $object->triggers )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [
            {
                author  => "Mario Zieschang",
                entries => [ { name => "Trigger 1" } ],
                id      => "1-1-maz"
            },
            {
                author  => "Mario Zieschang",
                entries => [ { name => "Trigger 2" } ],
                id      => "1-2-maz"
            }
        ]
      )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'no file at all'
);

is( $object->inc_changelog_count, 1, 'test inc changelog count' );

is(
    Data::Dumper->new( $object->functions )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)
      ->Dump,
    Data::Dumper->new(
        [
            {
                author  => "Mario Zieschang",
                entries => [ { name => "Function 1" } ],
                id      => "2-1-maz"
            },
            {
                author  => "Mario Zieschang",
                entries => [ { name => "Function 2" } ],
                id      => "2-2-maz"
            }
        ]
      )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'no file at all'
);

is( $object->inc_changelog_count, 2, 'test inc changelog count' );