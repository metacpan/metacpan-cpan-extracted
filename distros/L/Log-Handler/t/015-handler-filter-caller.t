use strict;
use warnings;
use Test::More tests => 3;
use Log::Handler;

my $CHECK  = 0;
my $STRING = '';

ok(1, 'use');

my $log = Log::Handler->new();

ok(2, 'new');

$log->add(
    forward => {
        forward_to     => \&check,
        maxlevel       => 6,
        filter_caller  => 'Foo::Bar',
        message_layout => '%p',
        newline        => 0,
    }
);

sub check {
    my $m = shift;
    if ($m->{message} eq 'Foo::Bar') {
        $CHECK++;
    }
}

Foo::Bar::baz();
Foo::Baz::baz();

ok($CHECK == 1, "checking filter_caller ($CHECK)");

package Foo::Bar;

sub baz {
    $log->info();
}

package Foo::Baz;

sub baz {
    $log->info();
}

1;
