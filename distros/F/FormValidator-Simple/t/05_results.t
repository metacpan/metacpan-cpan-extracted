use strict;
use Test::More tests => 34;

BEGIN{ use_ok("FormValidator::Simple::Results") }

my $results = FormValidator::Simple::Results->new;

$results->register('r1');
$results->register('r2');
$results->register('r3');

my $valids = $results->valid;
is( scalar(keys %$valids), 3    );
ok( exists $valids->{r1});
ok( exists $valids->{r2});
ok( !$results->has_missing );
ok( !$results->has_invalid );

$results->record('r1')->is_blank(1);

my $valids2 = $results->valid;
is( scalar(keys %$valids2), 2     );
ok( exists $valids2->{r2});
ok( exists $valids2->{r3});
ok( $results->has_error     );
ok( !$results->success      );
ok( $results->has_blank     );
ok( !$results->has_invalid  );
ok( $results->missing('r1') );

my @missings = $results->missing;
is( scalar(@missings),  1   );
is( $missings[0],      'r1' );

$results->record('r2')->set( 'ASCII' => 1     );
$results->record('r2')->set( 'INT'   => undef );

ok( $results->has_error   );
ok( $results->has_invalid );
ok( !$results->success    );

my @invalids = $results->invalid;
is( scalar(@invalids), 1     );
is( $invalids[0],      'r2'  );
ok( !$results->invalid('r1') );
ok( $results->invalid('r2')  );
ok( !$results->invalid('r3') );
ok( !$results->invalid('r2', 'ASCII') );
ok(  $results->invalid('r2', 'INT'  ) );

$results->record('r3')->data('data');
my $valids3 = $results->valid;
is( scalar(keys %$valids3), 1     );
ok( exists $valids3->{r3});
is( $results->valid('r3'), 'data' );


$results->clear;
is(scalar keys %{$results->valid}, 0);
is(scalar @{$results->missing}, 0);
ok(!$results->has_error);
ok(!$results->has_invalid);
ok($results->success);

