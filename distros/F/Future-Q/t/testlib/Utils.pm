package testlib::Utils;
use strict;
use warnings;
use Exporter qw(import);
use Future::Q;
use Test::Builder;
use Test::More;
use Scalar::Util qw(refaddr);
use Carp;

our @EXPORT_OK = qw(newf init_warn_handler test_log_num filter_callbacks is_immediate isnt_identical);

sub newf {
    return Future::Q->new;
}

sub init_warn_handler {
    delete $ENV{PERL_FUTURE_DEBUG};
    $SIG{__WARN__} = sub {
        confess @_;  ## no warning should be printed
    };
}

sub test_log_num {
    my ($testee_code, $exp_log_num, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @logs = ();
    local $Future::Q::OnError = sub { push @logs, shift };
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $testee_code->();
    }
    is(int(@logs), $exp_log_num, $msg) or diag(explain @logs);
}

sub filter_callbacks {
    my ($case_arg, $on_done, $on_fail) = @_;
    my %switch = (
        on_done => sub { ($on_done) },
        on_fail => sub { (undef, $on_fail) },
        both    => sub { ($on_done, $on_fail) },
        none    => sub { () },
    );
    return $switch{$case_arg}->();
}

sub is_immediate {
    my ($case_string) = @_;
    my %switch = (
        normal => sub { 1 },
        die => sub { 1 },
        immediate_done => sub { 1 },
        immediate_fail => sub { 1 },
        immediate_cancel => sub { 1 },
        pending_done => sub { 0 },
        pending_fail => sub { 0 },
        pending_cancel => sub { 0 },
    );
    return $switch{$case_string}->();
}

sub isnt_identical {
    my ($got, $not_exp, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isnt(refaddr($got), refaddr($not_exp), $msg);
}

1;
