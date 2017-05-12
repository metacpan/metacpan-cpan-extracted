use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use File::DataClass::IO qw( dummy );

eval { my $dummy = io( [ 't', 'dummy' ] ) };

like $EVAL_ERROR, qr{ \QUndefined subroutine\E }mx, 'Does not import io';

{  package TC1;

   use Moo;
   use File::DataClass::Types qw( Directory );

   has 'path' => is => 'ro', isa => Directory, coerce => Directory->coercion;
}

{  package TC2;

   use Moo;

   extends 'TC1';
}

my $tc; eval { $tc = TC2->new( path => 't' ) };

ok defined $tc, 'Failed to construct coercion test case';

defined $tc
   and is $tc->path, 't', 'Moose + Inheritance + Type::Tiny + Coercion';

use_ok 'File::DataClass::Constants';

eval { File::DataClass::Constants->Exception_Class( 'TC1' ) };

like $EVAL_ERROR, qr{ \A \QClass 'TC1' is not loaded\E }mx,
   'Bad exception class';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
