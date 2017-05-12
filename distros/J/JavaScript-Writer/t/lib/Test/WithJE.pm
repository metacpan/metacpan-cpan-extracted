package Test::WithJE;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use JE;
use JavaScript::Writer;
use self;

sub setup : Test(setup) {
    js->new;

    $self->{js} = js;
    $self->{je} = new JE;
    $self->{stash} = {};

    $self->{je}->new_function(
        alert => sub {
            pass("alert(@_);");
        }
    );
}

sub test_function_call : Test(2) {

    js->alert(42);
    js->dummy(qw(Lorem Ipsum));

    my $str = js->as_string;

    $self->{je}->new_function(
        dummy => sub {
            is_deeply(\@_, [qw(Lorem Ipsum)], "dummy function is called.");
        }
    );

    $self->{je}->eval($str);
}

1;
