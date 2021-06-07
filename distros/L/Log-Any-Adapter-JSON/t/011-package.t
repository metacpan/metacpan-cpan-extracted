use Test::Most 'die';

use Test::More::UTF8;
use Encode;
use Cpanel::JSON::XS;

my $tempfile;

BEGIN {
    use Path::Tiny;
    $tempfile = Path::Tiny->tempfile;
}

{
    package MyClass;
    use Log::Any '$log';
    use Log::Any::Adapter 'JSON', $tempfile->opena;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub foo {
        $log->debug('hello, world');
    }

    1;
}

# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return decode_json $line;
}

subtest 'Category from package' => sub {
    my $obj = MyClass->new;
    $obj->foo;

    is( last_line()->{message}, 'hello, world', 'message OK' );
    is( last_line()->{category}, 'MyClass',     'category OK' );
};

done_testing;

