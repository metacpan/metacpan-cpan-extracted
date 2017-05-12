use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Test::Fatal;
use Gnuplot::Builder::JoinDict;

sub check_log_once {
    my ($log_ref, $exp_dict, $exp_keys, $exp_vals) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is scalar(@$log_ref), 1, "called once";
    identical $log_ref->[0]{dict}, $exp_dict, "argument ok";
    is_deeply $log_ref->[0]{keys}, $exp_keys, "keys ok";
    is_deeply $log_ref->[0]{values}, $exp_vals, "values ok";
}

sub create_validator {
    my ($log_ref) = @_;
    return sub {
        my ($got_dict) = @_;
        push @$log_ref, +{
            dict => $got_dict,
            keys => [$got_dict->get_all_keys],
            values => [$got_dict->get_all_values]
        };
    };
}

{
    my @call_log = ();
    my $validator = create_validator(\@call_log);

    note("--- new()");
    @call_log = ();
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 1, y => 2],
        validator => $validator
    );
    check_log_once(\@call_log, $dict, [qw(x y)], [1 ,2]);

    my $new_dict;
    note("--- set()");
    @call_log = ();
    $new_dict = $dict->set(y => 3, z => 4);
    check_log_once(\@call_log, $new_dict, [qw(x y z)], [1, 3, 4]);

    note("--- set_all()");
    @call_log = ();
    $new_dict = $dict->set_all(100);
    check_log_once(\@call_log, $new_dict, [qw(x y)], [100, 100]);

    note("--- delete()");
    @call_log = ();
    $new_dict = $dict->delete("x");
    check_log_once(\@call_log, $new_dict, [qw(y)], [2]);

    note("--- clone() [NOT EXECUTED]");
    @call_log = ();
    $dict->clone();
    is scalar(@call_log), 0, "validator should not be executed when clone()";
}

{
    note("-- validator inheritance");
    my @call_log = ();
    my $dict = Gnuplot::Builder::JoinDict->new(
        content => [], validator => create_validator(\@call_log)
    );
    check_log_once(\@call_log, $dict, [], []);

    my $new_dict = $dict->set(x => 10, y => 20);

    @call_log = ();
    my $newnew_dict = $new_dict->set(x => 100, z => 300);
    check_log_once(\@call_log, $newnew_dict, [qw(x y z)], [100, 20, 300]);
}

{
    note("-- validator dies");
    like(
        exception{ Gnuplot::Builder::JoinDict->new(validator => sub { die "BOOM!" }) },
        qr/BOOM!/,
        "an exception thrown from validator is detected from outside"
    );
}

done_testing;

