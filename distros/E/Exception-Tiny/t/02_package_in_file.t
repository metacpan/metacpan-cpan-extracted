use strict;
use warnings;
use Test::More;

{
    package MyException;
    use strict;
    use warnings;
    use parent 'Exception::Tiny';
    1;
}

eval {
    MyException->throw('oops');
};

my $E = $@;
like "$E", qr/oops at .+02_package_in_file\.t line 14./;

done_testing;
