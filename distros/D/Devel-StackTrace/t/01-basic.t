use strict;
use warnings;

use Test::More 0.88;

use Devel::StackTrace;

sub get_file_name { File::Spec->canonpath( ( caller(0) )[1] ) }
my $test_file_name = get_file_name();

# Test all accessors
{
    my $trace = foo();

    my @f = ();
    while ( my $f = $trace->prev_frame ) { push @f, $f; }

    my $cnt = scalar @f;
    is(
        $cnt, 4,
        'Trace should have 4 frames'
    );

    @f = ();
    while ( my $f = $trace->next_frame ) { push @f, $f; }

    $cnt = scalar @f;
    is(
        $cnt, 4,
        'Trace should have 4 frames'
    );

    is(
        $f[0]->package, 'main',
        'First frame package should be main'
    );

    is(
        $f[0]->filename, $test_file_name,
        "First frame filename should be $test_file_name"
    );

    is( $f[0]->line, 1009, 'First frame line should be 1009' );

    is(
        $f[0]->subroutine, 'Devel::StackTrace::new',
        'First frame subroutine should be Devel::StackTrace::new'
    );

    is( $f[0]->hasargs, 1, 'First frame hasargs should be true' );

    ok(
        !$f[0]->wantarray,
        'First frame wantarray should be false'
    );

    my $trace_text = <<"EOF";
Trace begun at $test_file_name line 1009
main::baz(1, 2) called at $test_file_name line 1005
main::bar(1) called at $test_file_name line 1001
main::foo at $test_file_name line 13
EOF

    is( $trace->as_string, $trace_text, 'trace text' );
}

# Test constructor params
{
    my $trace = SubTest::foo( ignore_class => 'Test' );

    my @f = ();
    while ( my $f = $trace->prev_frame ) { push @f, $f; }

    my $cnt = scalar @f;

    is( $cnt, 1, 'Trace should have 1 frame' );

    is(
        $f[0]->package, 'main',
        'The package for this frame should be main'
    );

    $trace = Test::foo( ignore_class => 'Test' );

    @f = ();
    while ( my $f = $trace->prev_frame ) { push @f, $f; }

    $cnt = scalar @f;

    is( $cnt, 1, 'Trace should have 1 frame' );
    is(
        $f[0]->package, 'main',
        'The package for this frame should be main'
    );
}

# 15 - stringification overloading
{
    my $trace = baz();

    my $trace_text = <<"EOF";
Trace begun at $test_file_name line 1009
main::baz at $test_file_name line 99
EOF

    my $t = "$trace";
    is( $t, $trace_text, 'trace text' );
}

# 16-18 - frame_count, frame, reset_pointer, frames methods
{
    my $trace = foo();

    is(
        $trace->frame_count, 4,
        'Trace should have 4 frames'
    );

    my $f = $trace->frame(2);

    is(
        $f->subroutine, 'main::bar',
        q{Frame 2's subroutine should be 'main::bar'}
    );

    $trace->next_frame;
    $trace->next_frame;
    $trace->reset_pointer;

    $f = $trace->next_frame;
    is(
        $f->subroutine, 'Devel::StackTrace::new',
        'next_frame should return first frame after call to reset_pointer'
    );

    my @f = $trace->frames;
    is(
        scalar @f, 4,
        'frames method should return four frames'
    );

    is(
        $f[0]->subroutine, 'Devel::StackTrace::new',
        q{first frame's subroutine should be Devel::StackTrace::new}
    );

    is(
        $f[3]->subroutine, 'main::foo',
        q{last frame's subroutine should be main::foo}
    );
}

# Not storing references
{
    my $obj = RefTest->new;

    my $trace = $obj->{trace};

    my $call_to_trace = ( $trace->frames )[1];

    my @args = $call_to_trace->args;

    is(
        scalar @args, 1,
        'Only one argument should have been passed in the call to trace()'
    );

    like(
        $args[0], qr/RefTest=HASH/,
        q{Actual object should be replaced by string 'RefTest=HASH'}
    );
}

# Storing references
{
    my $obj = RefTest2->new;

    my $trace = $obj->{trace};

    my $call_to_trace = ( $trace->frames )[1];

    my @args = $call_to_trace->args;

    is(
        scalar @args, 1,
        'Only one argument should have been passed in the call to trace()'
    );

    isa_ok( $args[0], 'RefTest2' );
}

# Storing references (deprecated interface 1)
{
    my $obj = RefTestDep1->new;

    my $trace = $obj->{trace};

    my $call_to_trace = ( $trace->frames )[1];

    my @args = $call_to_trace->args;

    is(
        scalar @args, 1,
        'Only one argument should have been passed in the call to trace()'
    );

    isa_ok( $args[0], 'RefTestDep1' );
}

# No ref to Exception::Class::Base object without refs
if ( $Exception::Class::VERSION && $Exception::Class::VERSION >= 1.09 )
{
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval {
        Exception::Class::Base->throw(
            error      => 'error',
            show_trace => 1,
        );
    };
    my $exc = $@;
    eval { quux($exc) };

    ok( !$@, 'create stacktrace with no refs and exception object on stack' );
}

{
    sub FooBar::some_sub { return Devel::StackTrace->new }

    my $trace = eval { FooBar::some_sub('args') };

    my $f = ( $trace->frames )[2];

    is( $f->subroutine, '(eval)', 'subroutine is (eval)' );

    my @args = $f->args;

    is( scalar @args, 0, 'no args given to eval block' );
}

{
    {
        package    #hide
            FooBarBaz;

        sub func2 {
            return Devel::StackTrace->new( ignore_package => qr/^FooBar/ );
        }
        sub func1 { FooBarBaz::func2() }
    }

    my $trace = FooBarBaz::func1('args');

    my @f = $trace->frames;

    is( scalar @f, 1, 'check regex as ignore_package arg' );
}

## no critic (Modules::ProhibitMultiplePackages)
{
    package    #hide
        StringOverloaded;

    use overload q{""} => sub {'overloaded'};
}

{
    my $o = bless {}, 'StringOverloaded';

    my $trace = baz($o);

    unlike(
        $trace->as_string, qr/\boverloaded\b/,
        'overloading is ignored by default'
    );
}

{
    my $o = bless {}, 'StringOverloaded';

    my $trace = respect_overloading($o);

    like(
        $trace->as_string, qr/\boverloaded\b/,
        'overloading is ignored by default'
    );
}

{
    package    #hide
        BlowOnCan;

    sub can { die 'foo' }
}

{
    my $o = bless {}, 'BlowOnCan';

    my $trace = baz($o);

    like(
        $trace->as_string, qr/BlowOnCan/,
        'death in overload::Overloaded is ignored'
    );
}

{
    my $trace = max_arg_length('abcdefghijklmnop');

    my $trace_text = <<"EOF";
Trace begun at $test_file_name line 1021
main::max_arg_length('abcdefghij...') called at $test_file_name line 307
EOF

    is( $trace->as_string, $trace_text, 'trace text' );

    my $trace_text_1 = <<"EOF";
Trace begun at $test_file_name line 1021
main::max_arg_length('abc...') called at $test_file_name line 307
EOF

    is(
        $trace->as_string( { max_arg_length => 3 } ),
        $trace_text_1,
        'trace text, max_arg_length = 3',
    );
}

SKIP:
{
    skip 'Test only runs on Linux', 1
        unless $^O eq 'linux';

    my $frame = Devel::StackTrace::Frame->new(
        [ 'Foo', 'foo/bar///baz.pm', 10, 'bar', 1, 1, q{}, 0 ],
        []
    );

    is( $frame->filename, 'foo/bar/baz.pm', 'filename is canonicalized' );
}

{
    my $obj = RefTest4->new();

    my $trace = $obj->{trace};

    ok(
        ( !grep { ref $_ } map { @{ $_->{args} } } @{ $trace->{raw} } ),
        'raw data does not contain any references when unsafe_ref_capture not set'
    );

    is(
        $trace->{raw}[1]{args}[1], 'not a ref',
        'non-refs are preserved properly in raw data as well'
    );
}

{
    my $trace = overload_no_stringify( CodeOverload->new() );

    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval { $trace->as_string() };

    is(
        $@, q{},
        'no error when respect_overload is true and object overloads but does not stringify'
    );
}

{
    my $trace = Filter::foo();

    my @frames = $trace->frames();
    is( scalar @frames, 2, 'frame_filtered trace has just 2 frames' );
    is(
        $frames[0]->subroutine(), 'Devel::StackTrace::new',
        'first subroutine'
    );
    is(
        $frames[1]->subroutine(), 'Filter::bar',
        'second subroutine (skipped Filter::foo)'
    );
}

{
    my $trace = FilterAllFrames::a_foo();

    my @frames = $trace->frames();
    is(
        scalar @frames, 2,
        'after filtering whole list of frames, got just 2 frames'
    );
    is(
        $frames[0]->subroutine(), 'FilterAllFrames::a_bar',
        'first subroutine'
    );
    is(
        $frames[1]->subroutine(), 'FilterAllFrames::a_foo',
        'second subroutine'
    );
}

done_testing();

# This means I can move these lines down without constantly fiddling
# with the checks for line numbers in the tests.

#line 1000
sub foo {
    bar( @_, 1 );
}

sub bar {
    baz( @_, 2 );
}

sub baz {
    Devel::StackTrace->new( @_ ? @_[ 0, 1 ] : () );
}

sub quux {
    Devel::StackTrace->new();
}

sub respect_overloading {
    Devel::StackTrace->new( respect_overload => 1 );
}

sub max_arg_length {
    Devel::StackTrace->new( max_arg_length => 10 );
}

sub overload_no_stringify {
    return Devel::StackTrace->new( respect_overload => 1 );
}

{
    package    #hide
        Test;

    sub foo {
        trace(@_);
    }

    sub trace {
        Devel::StackTrace->new(@_);
    }
}

{
    package    #hide
        SubTest;

    use base qw(Test);

    sub foo {
        trace(@_);
    }

    sub trace {
        Devel::StackTrace->new(@_);
    }
}

{
    package    #hide
        RefTest;

    sub new {
        my $self = bless {}, shift;

        $self->{trace} = trace($self);

        return $self;
    }

    sub trace {
        Devel::StackTrace->new();
    }
}

{
    package    #hide
        RefTest2;

    sub new {
        my $self = bless {}, shift;

        $self->{trace} = trace($self);

        return $self;
    }

    sub trace {
        Devel::StackTrace->new( unsafe_ref_capture => 1 );
    }
}

{
    package    #hide
        RefTestDep1;

    sub new {
        my $self = bless {}, shift;

        $self->{trace} = trace($self);

        return $self;
    }

    sub trace {
        Devel::StackTrace->new( no_refs => 0 );
    }
}

{
    package    #hide
        RefTest4;

    sub new {
        my $self = bless {}, shift;

        $self->{trace} = trace( $self, 'not a ref' );

        return $self;
    }

    sub trace {
        Devel::StackTrace->new();
    }
}

{
    package    #hide
        CodeOverload;

    use overload '&{}' => sub {'foo'};

    sub new {
        my $class = shift;
        return bless {}, $class;
    }
}

{
    package    #hide
        Filter;

    sub foo {
        bar();
    }

    sub bar {
        return Devel::StackTrace->new(
            frame_filter => sub { $_[0]{caller}[3] ne 'Filter::foo' } );
    }
}

{
    package    #hide
        FilterAllFrames;

    sub a_foo { b_foo() }
    sub b_foo { a_bar() }
    sub a_bar { b_bar() }

    sub b_bar {
        my $stacktrace = Devel::StackTrace->new();
        $stacktrace->frames( only_a_frames( $stacktrace->frames() ) );
        return $stacktrace;
    }

    sub only_a_frames {
        my @frames = @_;
        return grep { $_->subroutine() =~ /^FilterAllFrames::a/ } @frames;
    }
}
