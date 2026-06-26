use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

# Wrong number of elements in top-level array
eval { $h->html( [ head => [], body => [], extra => 1 ] ) };
like $@, qr/Invalid number of elements/,
  'croaks when top-level array has more than 4 elements';

eval { $h->html( [ head => [] ] ) };
like $@, qr/Invalid number of elements/,
  'croaks when top-level array has fewer than 4 elements';

# Wrong first tag (not 'head')
eval { $h->html( [ foo => [], body => [] ] ) };
like $@, qr/Invalid head tag/, 'croaks when first tag is not "head"';

# Wrong third tag (not 'body')
eval { $h->html( [ head => [], bar => [] ] ) };
like $@, qr/Invalid body tag/, 'croaks when third tag is not "body"';

# Head content is not an ARRAY ref
eval { $h->html( [ head => "not an array", body => [] ] ) };
like $@, qr/Invalid head type/,
  'croaks when head content is a plain string, not an ARRAY ref';

# Body content is not an ARRAY ref
eval { $h->html( [ head => [], body => "not an array" ] ) };
like $@, qr/Invalid body type/,
  'croaks when body content is a plain string, not an ARRAY ref';

# Void tag receiving child array
eval {
    $h->html(
        [
            head => [ title => ["Err"] ],
            body => [ br    => ["child text"] ]
        ]
    );
};
like $@, qr/Cannot pass children to tag of type br/,
  'croaks when void tag br is given a child array';

eval {
    $h->html(
        [
            head => [ title => ["Err"] ],
            body => [ img   => ["child text"] ]
        ]
    );
};
like $@, qr/Cannot pass children to tag of type img/,
  'croaks when void tag img is given a child array';

# html() attrs argument is not a HASH ref
eval {
    $h->html( [qw(not a hash)], [ head => [ title => ["Err"] ], body => [] ] );
};
like $@, qr/expected HASH/,
  'croaks when html() attrs argument is a non-HASH reference';

done_testing;
