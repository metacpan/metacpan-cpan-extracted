use strict;
use warnings;

use Test::More;

{
    package MyE;

    use strict;
    use warnings;

    use base 'Exception::Class::Base';
}

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
eval { MyE->throw() };
isa_ok( $@, 'MyE', 'can throw MyE without loading Exception::Class' );

my $caught = MyE->caught();
ok( $caught, 'caught MyE exception' );

done_testing();
