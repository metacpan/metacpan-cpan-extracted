use Test2::V0;
use Test2::Require::Module 'Cpanel::JSON::XS::Type';

use Cpanel::JSON::XS::Type;

use JSON::UnblessObject qw(
    unbless_object
);

{
    package Foo;
    sub new  {
        my ($class, %args) = @_;
        bless \%args, $class
    }
    sub num  { 123 }
    sub str  { "HELLO" }
    sub lang { ["perl", "raku"] }
    sub bar  { Bar->new }
    sub id   { $_[0]->{id} }
}

{
    package Bar;
    sub new { bless {}, $_[0] }
    sub a { "AAA" }

    sub JSON_KEYS { qw/a/ }
}

{
    package OverloadingCollection;
    sub new {
        my ($class, $list) = @_;
        bless { list => $list }, $class;
    }

    use overload
        '@{}'    => sub { shift->{list} },
        fallback => 1;
}

{
    package IteratableCollection;
    sub new {
        my ($class, $list) = @_;
        bless $list, $class;
    }

    {
        my $counter = 0;
        sub next {
            my $self = shift;
            if ($counter < scalar @$self) {
                return $self->[$counter++];
            }
            else {
                $counter = 0;
                return;
            }
        }
    }
}

subtest 'When object is unbless value, then it returns same value' => sub {
    is unbless_object(123), 123;
    is unbless_object('hello'), 'hello';
    is unbless_object({}), {};
    is unbless_object([]), [];
};

subtest 'When spec is not passed, then it returns same value' => sub {
    my $foo = Foo->new;
    is unbless_object($foo), $foo;
};

subtest 'When spec is scalar, then it returns same value' => sub {
    my $foo = Foo->new;

    is unbless_object($foo, 'hoge'), $foo;
    is unbless_object($foo, 123), $foo;
    is unbless_object($foo, JSON_TYPE_INT), $foo;
    is unbless_object($foo, JSON_TYPE_STRING), $foo;
};

subtest 'When spec is arrayref, then it returns unblessed value' => sub {

    like dies { unbless_object(Foo->new, [ ]) },
         qr/object could not be converted to array ref/;

    subtest 'object is overloading @{}' => sub {
        my $collection = OverloadingCollection->new(['aaa', 'bbb']);

        is unbless_object($collection, [ JSON_TYPE_STRING, JSON_TYPE_STRING ]), [ 'aaa', 'bbb' ];
        is unbless_object($collection, [ JSON_TYPE_STRING ]), [ 'aaa' ];
        is unbless_object($collection, [ ]), [ ];
    };

    subtest 'object is iteratable' => sub {
        my $collection = IteratableCollection->new(['aaa', 'bbb']);

        is unbless_object($collection, [ JSON_TYPE_STRING, JSON_TYPE_STRING ]), [ 'aaa', 'bbb' ];
        is unbless_object($collection, [ JSON_TYPE_STRING ]), [ 'aaa' ];
        is unbless_object($collection, [ ]), [ ];
    };
};

subtest 'When spec is hashref, then it returns unblessed value' => sub {
    my $foo = Foo->new;

    is unbless_object($foo, { num => JSON_TYPE_INT }),    { num => 123 };
    is unbless_object($foo, { str => JSON_TYPE_STRING }), { str => "HELLO" };

    is unbless_object($foo,
        {
            num => JSON_TYPE_INT,
            str => JSON_TYPE_STRING,
        }
    ),  {
            num => 123,
            str => "HELLO"
        };
};

subtest 'When spec is a reference that is neither arrayref nor hashref, throw exception' => sub {
    my $foo = Foo->new;

    like dies { unbless_object($foo, sub { }) }, qr/reference not supported spec/;
    like dies { unbless_object($foo, \1) }, qr/reference not supported spec/;
};

subtest 'When spec is JSON_TYPE_ARRAYOF_CLASS, then it returns unbless value' => sub {
    my $collection = OverloadingCollection->new(['aaa', 'bbb']);

    is unbless_object($collection, json_type_arrayof(JSON_TYPE_STRING)), ['aaa', 'bbb'];
};

subtest 'When spec is JSON_TYPE_HASHOF_CLASS, then it returns unbless value' => sub {

    like dies { unbless_object(Foo->new, json_type_hashof(JSON_TYPE_STRING)) },
         qr/object could not call JSON_KEYS method/;

    is unbless_object(Bar->new, json_type_hashof(JSON_TYPE_STRING)), { a => 'AAA' };
};

subtest 'When spec is JSON_TYPE_ANYOF_CLASS, then it returns unbless value' => sub {
    my $spec = json_type_anyof(
                    JSON_TYPE_STRING,
                    json_type_arrayof(JSON_TYPE_STRING),
                    json_type_hashof(JSON_TYPE_STRING)
               );

    subtest 'object that can be converted to array' => sub {
        is unbless_object(OverloadingCollection->new(['aaa', 'bbb']), $spec), ['aaa', 'bbb'];
        is unbless_object(IteratableCollection->new(['aaa', 'bbb']), $spec), ['aaa', 'bbb'];
    };

    subtest 'object that can be converted to hash' => sub {
        is unbless_object(Bar->new, $spec), { a => 'AAA' };
    };

    subtest 'object that cannot be converted to array and hash' => sub {
        my $foo = Foo->new;
        is unbless_object($foo, $spec), $foo;
    };
};

subtest 'When unknown blessed spec, throw exception' => sub {
    my $spec = bless {}, 'UnknownSpec';

    like dies { unbless_object(Foo->new, $spec) }, qr/object not supported spec/;
};

subtest 'When spec is a complex combination of JSON_TYPE_ARRAYOF and HASH' => sub {
    my $collection = IteratableCollection->new([
        Foo->new(id => 456),
        Foo->new(id => 567),
        Foo->new(id => 678),
    ]);

    my $spec = json_type_arrayof({
        num  => JSON_TYPE_INT,
        str  => JSON_TYPE_STRING,
        lang => json_type_arrayof(JSON_TYPE_STRING),
        bar  => json_type_hashof(JSON_TYPE_STRING),
        id   => JSON_TYPE_INT,
    });

    my $expected = [
        {
            id   => 456,
            num  => 123,
            str  => 'HELLO',
            lang => ['perl', 'raku'],
            bar  => {
                a => 'AAA',
            },
        },
        {
            id   => 567,
            num  => 123,
            str  => 'HELLO',
            lang => ['perl', 'raku'],
            bar  => {
                a => 'AAA',
            },
        },
        {
            id   => 678,
            num  => 123,
            str  => 'HELLO',
            lang => ['perl', 'raku'],
            bar  => {
                a => 'AAA',
            },
        }
    ];

    is unbless_object($collection, $spec), $expected;
};

done_testing;
