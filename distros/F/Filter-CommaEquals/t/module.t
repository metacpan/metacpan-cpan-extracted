use Test2::V0;
use Filter::CommaEquals;

my @array = ( 42, 1138, 96 );

ok(
    eval { @array ,= 433; },
    '@array ,= 433; # Should push 433 to @array',
);

ok(
    join(', ', @array) eq '42, 1138, 96, 433',
    'Verify array contents',
);

ok(
    eval { @array ,= '@array ,= 433'; },
    q|@array ,= '@array ,= 433'; # Should push '@array ,= 433' to @array|,
);

ok(
    join(', ', @array) eq '42, 1138, 96, 433, @array ,= 433',
    'Verify array contents',
);

ok(
    eval { q{# @array ,= '@array ,= 433'} },
    'We should ignore comments',
);

ok(
    join(', ', @array) eq '42, 1138, 96, 433, @array ,= 433',
    'Verify array contents',
);

done_testing;
