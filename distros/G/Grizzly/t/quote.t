use Test::More tests => 5;
use App::Cmd::Tester;

use v5.36;
use Grizzly;

my $result = test_app( Grizzly => [qw(quote ibm)] );
isnt( $result->output, '', 'gives an output for quote info' );

my $result = test_app( Grizzly => [qw(quote msft)] );
isnt( $result->output, '', 'gives an output for quote info' );

my $result = test_app( Grizzly => [qw(quote)] );
like( $result->stdout, qr//, 'printed what we expected' );
is( $result->stderr, '', 'nothing sent to sderr' );
isnt( $result->error, undef, 'threw no exceptions' );
