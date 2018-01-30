use strict;
use warnings;

# hide Cpanel::JSON::XS
use lib map {
    my $m = $_;
    sub { return unless $_[1] eq $m; die "Can't locate $m in \@INC (hidden).\n" };
} qw{Cpanel/JSON/XS.pm};

use Test::More 0.88;
use JSON::MaybeXS qw/:legacy/;

my $in = '[1, 2, 3, 4]';

my $arr = from_json($in);
my $j = to_json($arr);
is($j, '[1,2,3,4]');
is(ref($arr), 'ARRAY');

my $json = 'JSON::MaybeXS';
diag "using invocant: $json";
like(
    do { eval { $json->from_json($in) }; $@ },
    qr/from_json should not be called as a method/,
    'blessed invocant detected in from_json',
);

like(
    do { eval { $json->to_json($arr, { blah => 1 } ) }; $@ },
    qr/to_json should not be called as a method/,
    'blessed invocant detected in to_json',
);

done_testing;

__END__

  to_json
       $json_text = to_json($perl_scalar)

    Converts the given Perl data structure to a json string.

    This function call is functionally identical to:

       $json_text = JSON()->new->encode($perl_scalar)

  from_json
       $perl_scalar = from_json($json_text)

    The opposite of "to_json": expects a json string and tries to parse it,
    returning the resulting reference.

    This function call is functionally identical to:

        $perl_scalar = JSON()->decode($json_text)
