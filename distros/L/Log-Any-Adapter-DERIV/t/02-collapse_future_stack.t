use strict;
use warnings;
use Test::More;
use Log::Any qw($log);
use Log::Any::Adapter qw();
use Log::Any::Adapter::DERIV;
use Path::Tiny;
use Future;
use JSON::MaybeUTF8 qw(:v1);
use Clone qw(clone);

subtest '_collapse_future_stack' => sub {
    my $sample_stack = [
        {
            'line' => 451,
            'file' => '/home/git/regentmarkets/cpan/local/lib/perl5/Future.pm',
            'package' => 'Future',
            'method'  => '(eval)'
        },
        {
            'package' => 'Future',
            'file' => '/home/git/regentmarkets/cpan/local/lib/perl5/Future.pm',
            'method' => '_mark_ready',
            'line'   => 625
        },
        {
            'method'  => 'done',
            'package' => 'main',
            'file'    => 't/02-stack.t',
            'line'    => 13
        }
    ];
    my $arg_stack      = [@$sample_stack[0,1,2,0,1,2]];
    #diag("arg stack "); diag  explain($arg_stack);
    # remove the outest stack frame
    my $expected_stack = [@$sample_stack[0,2,0,2]];
    is_deeply(
        Log::Any::Adapter::DERIV->_collapse_future_stack(
            { stack => $arg_stack }
        ),
        { stack => $expected_stack },
        "stack is collapsed"
    );
    $arg_stack = clone($sample_stack);
    pop $arg_stack->@*;
    $expected_stack = clone($arg_stack);
    pop $expected_stack->@*;
    is_deeply(
        Log::Any::Adapter::DERIV->_collapse_future_stack(
            { stack => $arg_stack }
        ),
        { stack => $expected_stack },
        "stack is collapsed when the last one is a Future"
    );
};

subtest 'test collapse from message' => sub {
    my $get_message = sub {
        my $f             = shift;
        my $json_log_file = Path::Tiny->tempfile;
        Log::Any::Adapter->import(
            'DERIV',
            log_level     => 'debug',
            json_log_file => $json_log_file
        );
        $f->done;
        my $message = $json_log_file->slurp;
        chomp $message;
        $message = decode_json_text($message);
        return $message;
    };

    my $f1 = Future->new;
    my $f2 = $f1->then_done->then_done->then_done->then_done->then(
        sub { $log->debug("this is a debug message") } );
    my $message        = $get_message->($f1);
    my $expected_stack = [
        map { ; { package => $_ } } (
            "Future",        "main",
            "main",          "Test::Builder",
            "Test::Builder", "Test::More",
            "main"
        )
    ];
    my $stack =
      [ map { ; { package => $_->{package} } } @{ $message->{stack} } ];
    is_deeply( $stack, $expected_stack, "the stack value is correct" );

    $f1 = Future->new;
    $f2 = Future->new;
    my $f3 = $f1->then_done->then_done->then( sub { $f2->done } );
    my $f4 = $f2->then_done->then_done->then(
        sub { $log->debug("this is a debug message"); Future->done } );
    $message        = $get_message->($f1);
    $expected_stack = [
        map { ; { package => $_ } } (
            "Future",        "main",
            "Future",        "main",
            "main",          "Test::Builder",
            "Test::Builder", "Test::More",
            "main"
        )
    ];
    $stack = [ map { ; { package => $_->{package} } } @{ $message->{stack} } ];
    is_deeply( $stack, $expected_stack, "more example" );
};
done_testing();
