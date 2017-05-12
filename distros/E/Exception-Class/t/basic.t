use strict;
use warnings;

use File::Spec;

use Test::More 0.88;

use Exception::Class;

# There's actually a few tests here of the import routine.  I don't
# really know how to quantify them though.  If we fail to compile and
# there's an error from the Exception::Class::Base class then
# something here failed.
BEGIN {
    package FooException;

    use Exception::Class;
    use base qw(Exception::Class::Base);
}

use Exception::Class (
    'YAE' => { isa => 'SubTestException', alias => 'yae' },

    'SubTestException' => {
        isa         => 'TestException',
        description => q|blah'\\blah|
    },

    'TestException',

    'FooBarException' => { isa => 'FooException' },

    'FieldsException' => { isa => 'YAE', fields => [qw( foo bar )] },
    'MoreFieldsException' => { isa => 'FieldsException', fields => ['yip'] },

    'Exc::AsString',

    'Bool' => { fields => ['something'] },

    'ObjectRefs',
    'ObjectRefs2',
    'ObjectRefs3',
);

$Exception::Class::BASE_EXC_CLASS = 'FooException';
Exception::Class->import('BlahBlah');

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)

# Accessors
{
    eval { Exception::Class::Base->throw( error => 'err' ); };

    my $e = $@;

    isa_ok( $e, 'Exception::Class::Base', '$@' );

    is(
        $e->error, 'err',
        q{Exception's error message should be 'err'}
    );

    is(
        $e->message, 'err',
        q{Exception's message should be 'err'}
    );

    is(
        $e->description, 'Generic exception',
        q{Description should be 'Generic exception'}
    );

    is(
        $e->package, 'main',
        q{Package should be 'main'}
    );

    my $expect = File::Spec->catfile( 't', 'basic.t' );
    is(
        $e->file, $expect,
        "File should be '$expect'"
    );

    is(
        $e->line, 52,
        'Line should be 52'
    );

    is(
        $e->pid, $$,
        "PID should be $$"
    );

    is(
        $e->context_hash->{pid}, $$,
        'PID is also in context_hash',
    );

    is(
        $e->uid, $<,
        "UID should be $<"
    );

    is(
        $e->euid, $>,
        "EUID should be $>"
    );

    is(
        $e->gid, $(,
        "GID should be $("
    );

    is(
        $e->egid, $),
        "EGID should be $)"
    );

    ok(
        defined $e->trace,
        'Exception object should have a stacktrace'
    );
}

# Test subclass creation
{
    eval { TestException->throw( error => 'err' ); };
    my $e = $@;

    isa_ok( $e, 'TestException' );

    is(
        $e->description, 'Generic exception',
        q{Description should be 'Generic exception'}
    );

    eval { SubTestException->throw( error => 'err' ); };

    $e = $@;

    isa_ok( $e, 'SubTestException' );

    isa_ok( $e, 'TestException' );

    isa_ok( $e, 'Exception::Class::Base' );

    is(
        $e->description, q|blah'\\blah|,
        q|Description should be "blah'\\blah"|
    );

    eval { YAE->throw( error => 'err' ); };

    $e = $@;

    isa_ok( $e, 'SubTestException' );

    eval { BlahBlah->throw( error => 'yadda yadda' ); };

    $e = $@;

    isa_ok( $e, 'FooException' );

    isa_ok( $e, 'Exception::Class::Base' );
}

# Trace related tests
{
    ok(
        !Exception::Class::Base->Trace,
        q{Exception::Class::Base class 'Trace' method should return false}
    );

    eval {
        Exception::Class::Base->throw(
            error      => 'has stacktrace',
            show_trace => 1,
        );
    };

    my $e = $@;

    like(
        $e->as_string, qr/Trace begun/,
        'Setting show_trace to true should override value of Trace'
    );

    Exception::Class::Base->Trace(1);

    ok(
        Exception::Class::Base->Trace,
        q{Exception::Class::Base class 'Trace' method should return true}
    );

    eval { argh(); };

    $e = $@;

    ok(
        $e->trace->as_string,
        'Exception should have a stack trace'
    );

    eval {
        Exception::Class::Base->throw(
            error      => 'has stacktrace',
            show_trace => 0,
        );
    };

    $e = $@;

    unlike(
        $e->as_string, qr/Trace begun/,
        'Setting show_trace to false should override value of Trace'
    );

    my @f;
    while ( my $f = $e->trace->next_frame ) { push @f, $f; }

    ok(
        ( !grep { $_->package eq 'Exception::Class::Base' } @f ),
        'Trace should contain frames from Exception::Class::Base package'
    );
}

# overloading
{
    Exception::Class::Base->Trace(0);
    eval { Exception::Class::Base->throw( error => 'overloaded' ); };

    my $e = $@;

    is(
        "$e", 'overloaded',
        'Overloading in string context'
    );

    Exception::Class::Base->Trace(1);
    eval { Exception::Class::Base->throw( error => 'overloaded again' ); };

SKIP:
    {
        skip( 'Perl 5.6.0 is broken.  See README.', 1 ) if $] == 5.006;

        my $re = qr/overloaded again.+eval \{...\}/s;

        my $x = "$@";
        like(
            $x, $re,
            'Overloaded stringification should include a stack trace'
        );
    }
}

# Test using message as hash key to constructor
{
    eval { Exception::Class::Base->throw( message => 'err' ); };

    my $e = $@;

    is(
        $e->error, 'err',
        q{Exception's error message should be 'err'}
    );

    is(
        $e->message, 'err',
        q{Exception's message should be 'err'}
    );
}

## no critic (Modules::ProhibitMultiplePackages)
{
    {
        package X::Y;

        use Exception::Class (__PACKAGE__);

        sub xy_die () { __PACKAGE__->throw( error => 'dead' ); }

        eval {xy_die};
    }

    my $e = $@;

    is(
        $e->error, 'dead',
        q{Error message should be 'dead'}
    );
}

# subclass overriding as_string

sub Exc::AsString::as_string { return uc $_[0]->error }

{
    eval { Exc::AsString->throw( error => 'upper case' ) };

    my $e = $@;

    is(
        "$e", 'UPPER CASE',
        'Overriding as_string in subclass'
    );
}

# fields

{
    eval { FieldsException->throw( error => 'error', foo => 5 ) };

    my $e = $@;

    can_ok( $e, 'foo' );

    is(
        $e->foo, 5,
        q{Exception's foo method should return 5}
    );

    is_deeply(
        $@->field_hash,
        { foo => 5, bar => undef },
        q{Exception's fields_hash should contain foo=>5,bar=>undef}
    );
}

# more fields.
{
    eval {
        MoreFieldsException->throw( error => 'error', yip => 10, foo => 15 );
    };

    my $e = $@;

    can_ok( $e, 'foo' );

    is(
        $e->foo, 15,
        q{Exception's foo method should return 15}
    );

    can_ok( $e, 'yip' );

    is(
        $e->yip, 10,
        q{Exception's foo method should return 10}
    );
}

sub FieldsException::full_message {
    return join q{ }, $_[0]->message, 'foo = ' . $_[0]->foo;
}

# fields + full_message

{
    eval { FieldsException->throw( error => 'error', foo => 5 ) };

    my $e = $@;

    like(
        "$e", qr/error foo = 5/,
        'FieldsException should stringify to include the value of foo'
    );
}

# single arg constructor
{
    eval { YAE->throw('foo') };

    my $e = $@;

    ok(
        $e,
        'Single arg constructor should work'
    );

    is(
        $e->error, 'foo',
        'Single arg constructor should just set error/message'
    );
}

# unsafe ref capture
{
    ObjectRefs2->UnsafeRefCapture(1);

    eval { Foo->new->bork2 };
    my $exc = $@;

    my @args = ( $exc->trace->frames )[1]->args;

    ok(
        ref $args[0],
        'References should be saved in the stack trace'
    );
}

# no refs - deprecated
{
    ObjectRefs3->NoRefs(0);

    eval { Foo->new->bork2 };
    my $exc = $@;

    my @args = ( $exc->trace->frames )[1]->args;

    ok(
        ref $args[0],
        'References should be saved in the stack trace'
    );
}

# aliases
{

    package FooBar;

    use Exception::Class (
        'SubAndFields' => {
            fields => 'thing',
            alias  => 'throw_saf',
        }
    );

    eval { throw_saf 'an error' };
    my $e = $@;

    ::ok( $e, 'Throw exception via convenience sub (one param)' );
    ::is( $e->error, 'an error', 'check error message' );

    eval { throw_saf error => 'another error', thing => 10 };
    $e = $@;

    ::ok( $e, 'Throw exception via convenience sub (named params)' );
    ::is( $e->error, 'another error', 'check error message' );
    ::is( $e->thing, 10, 'check "thing" field' );

    ::is( $e->package, __PACKAGE__, 'package matches current package' );
}

{

    package BarBaz;

    use overload '""' => sub {'overloaded'};
}

{
    sub throw { TestException->throw( error => 'dead' ) }

    TestException->Trace(1);

    eval { throw( bless {}, 'BarBaz' ) };
    my $e = $@;

    unlike(
        $e->as_string, qr/\boverloaded\b/,
        'overloading is ignored by default'
    );

    TestException->RespectOverload(1);

    eval { throw( bless {}, 'BarBaz' ) };
    $e = $@;

    like( $e->as_string, qr/\boverloaded\b/, 'overloading is now respected' );
}

{
    my %classes = map { $_ => 1 } Exception::Class::Classes();

    ok(
        $classes{TestException},
        'TestException should be in the return from Classes()'
    );
}

{
    sub throw2 { TestException->throw( error => 'dead' ); }

    eval { throw2('abcdefghijklmnop') };
    my $e = $@;

    like(
        $e->as_string, qr/'abcdefghijklmnop'/,
        'arguments are not truncated by default'
    );

    TestException->MaxArgLength(10);

    eval { throw2('abcdefghijklmnop') };
    $e = $@;

    like(
        $e->as_string, qr/'abcdefghij\.\.\.'/,
        'arguments are now truncated'
    );
}

done_testing();

sub argh {
    Exception::Class::Base->throw( error => 'ARGH' );
}

package Foo;

sub new {
    return bless {}, shift;
}

sub bork {
    my $self = shift;

    ObjectRefs->throw('kaboom');
}

sub bork2 {
    my $self = shift;

    ObjectRefs2->throw('kaboom');
}
