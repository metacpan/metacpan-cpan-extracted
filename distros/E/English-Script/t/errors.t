use Test2::V0;
use English::Script;

my $es;
ok( lives { $es = English::Script->new }, 'new' ) or note $@;

like(
    dies { $es->parse('This isn\'t a valid sentence.') },
    qr/^Failed to parse input/,
    'bad sentence throws exception',
);

is( scalar( @{ $es->data->{errors} } ), 15, 'total errors returned is correct' );

is(
    $es->data->{errors}[-1]{message},
    'Invalid content: Was expecting comment, or sentence',
    'core error message is correct',
);

done_testing;
