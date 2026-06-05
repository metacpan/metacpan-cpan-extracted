package FakeHash {
    use strict;
    use warnings;
    use Tie::Hash;
    use parent -norequire, 'Tie::ExtraHash';
}

use strict;
use warnings;
use Test::More;
use HTTP::XSHeaders;
use HTTP::Headers;

tie my %newhash, 'FakeHash';
my $headers = bless \%newhash => 'HTTP::Headers';

is( ref $headers, 'HTTP::Headers', 'Correct reference' );
ok( tied( %{$headers} ), 'Correct tie' );

$headers->push_header( 'X-Foo' => 'Bar' );
is( $headers->header('X-Foo'), 'Bar', 'Header was set correctly' );

done_testing();
