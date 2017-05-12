use t::boilerplate;

use Test::More;
use English      qw( -no_match_vars );
use Scalar::Util qw( blessed );

use_ok 'File::DataClass::Exception';

my $class = 'File::DataClass::Exception'; $EVAL_ERROR = undef;

eval { $class->throw_on_error }; my $e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok ! $e, 'No throw without error';

eval { $class->throw( 'PracticeKill' ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

is blessed $e, $class, 'Good class';
is $e->class, 'File::DataClass::Exception', 'Default exception class';
like $e, qr{ PracticeKill \s* \z   }mx, 'Throws error message';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
