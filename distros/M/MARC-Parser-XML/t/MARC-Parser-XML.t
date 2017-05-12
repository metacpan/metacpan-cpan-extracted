use strict;
use warnings;

use Test::More tests => 23;

use_ok('MARC::Parser::XML');

my @leaders = (
    '00755cam  22002414a 4500',
    '00647pam  2200241 a 4500',
    '00605cam  22002054a 4500',
    '00579cam  22002054a 4500',
    '00801nam  22002778a 4500',
    '00665nam  22002298a 4500',
    '00579nam  22002178a 4500',
    '00661nam  22002538a 4500',
    '00603cam  22002054a 4500',
    '00696nam  22002538a 4500',
);

my $parser = MARC::Parser::XML->new('t/files/marc.xml');
isa_ok( $parser, 'MARC::Parser::XML' );
can_ok( $parser, ('next') );
my $count = 0;
while ( my $record = $parser->next() ) {
    $count++;
    is( $record->[0]->[-1], $leaders[ $count - 1 ], "next record" );
}

$parser = MARC::Parser::XML->new('t/files/marc-ns-prefix.xml');
$count  = 0;
while ( my $record = $parser->next() ) {
    $count++;
    is(
        $record->[0]->[-1],
        $leaders[ $count - 1 ],
        "next record with namespace prefix"
    );
}
