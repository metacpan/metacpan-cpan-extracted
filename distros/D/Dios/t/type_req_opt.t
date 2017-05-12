use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package TypeCheck::RequiredOptional;

    use strict;
    use warnings;

    use Dios;

    method new ($class:) { bless {}, $class; }

    method required_named      ( Int :$foo! ) {}
    method optional_named      ( Int :$foo  ) {}
    method required_positional ( Int  $foo  ) {}
    method optional_positional ( Int  $foo? ) {}

}

our $tester = TypeCheck::RequiredOptional->new;


throws_ok { $tester->optional_named() }
          qr/Value \(undef\) for named parameter :\$foo is not of type Int/,
          'proper error when failing to pass optional named arg';
throws_ok { $tester->optional_positional() }
          qr/Value \(undef\) for positional parameter \$foo is not of type Int/,
          'proper error when failing to pass optional positional arg';

throws_ok { $tester->required_named() }
          qr/No argument \('foo' => <int>\) found for required named parameter :\$foo/,
          'proper error when failing to pass required named arg';
throws_ok { $tester->required_positional() }
          qr/No argument found for positional parameter \$foo/,
          'proper error when failing to pass required positional arg';


done_testing;
