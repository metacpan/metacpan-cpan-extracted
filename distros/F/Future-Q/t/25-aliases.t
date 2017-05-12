use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Future::Q;

{
    package testlib::Spy;

    sub new {
        my ($class) = @_;
        my $self = bless {
            mock => Test::MockModule->new('Future::Q'),
            history => {},
        }, $class;
        foreach my $method (qw(try then done fail)) {
            $self->{history}{$method} = [];
            $self->{mock}->mock($method, sub {
                push(@{$self->{history}{$method}}, [@_]);
                goto $self->{mock}->original($method);
            });
        }
        return $self;
    }

    sub clear {
        my ($self) = @_;
        foreach my $method (keys %{$self->{history}}) {
            @{$self->{history}{$method}} = ();
        }
    }

    sub history_of {
        my ($self, $method) = @_;
        return @{$self->{history}{$method}};
    }
}


note("---- tests for alias methods");
my $spy = testlib::Spy->new;

{
    $spy->clear;
    my $f = Future::Q->new;
    my $func = sub { };
    $f->fcall($func, "a", "b", "c");
    my @his = $spy->history_of("try");
    is_deeply(\@his, [[$f, $func, qw(a b c)]], "fcall is alias for try");
}

{
    $spy->clear;
    my $f = Future::Q->new;
    my $func = sub { };
    $f->catch($func);
    my @his = $spy->history_of("then");
    is_deeply(\@his, [[$f, undef, $func]], "catch is alias for then");
}

{
    $spy->clear;
    my $f = Future::Q->new;
    $f->fulfill(1,2,3);
    my @his = $spy->history_of("done");
    is_deeply(\@his, [[$f, 1,2,3]], "fulfill is alias for done");
}

{
    $spy->clear;
    my $f = Future::Q->new;
    $f->reject(1,2,3);
    my @his = $spy->history_of("fail");
    is_deeply(\@his, [[$f, 1,2,3]], "reject is alias for fail");
    $f->catch(sub { }); ## failure handled
}


done_testing();
