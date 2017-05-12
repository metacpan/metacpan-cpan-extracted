#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Inline 'Ruby';
use Data::Dumper;

my @exc = (
    [qr{Illegal division by zero}, 'PerlException'],
    [qr{Missing right (?:curly or square )?bracket}, 'PerlException'],
);

# TEST:$n=2;
my $n = 0;
sub test_exception {
    my $iter = shift;
    eval { iter($iter)->callback($n) };
    die unless $@;
    my $x = $@;

    # Methods:
    # TEST*$n
    like ($x->message, $exc[$n][0], "Message for $n");
    # print Dumper $x->message;

    # TEST*$n
    is ($x->type, $exc[$n][1], "Type for $n");
    # print Dumper $x->type;

    # TEST*$n
    is ("$x", $x->inspect . "\n", "Stringification for $n");

    # Not tested:
    # print Dumper $x->inspect;
    # print "Stringified: $x\n";
    # print Dumper $x->backtrace;

    $n++;

    return;
}

# Division by zero
test_exception( sub {
        my $x = 0;
        my $y = 1;
        my $z;
        # TODO : This eval + rethrow with die is the only way to get it to
        # work. But why?
        eval { $z = $y/$x; };
        die $@;
    });

test_exception( sub {
        eval "sub bar {";
        die $@;
    });

# Inline::Ruby must clear $@ if there is no exception:
iter(sub { 0 })->catch_perlerr;
# TEST
is ($@, '', "No exception");

# If a Perl exception occurs, but is trapped by a Ruby rescue block, we need
# to notice and clean it up. Yay!
iter(sub {
    local $^W;
    my $x = 0;
    my $y = 1;
    return $y/$x;
})->catch_perlerr;
# print "But... $@\n";
# TEST
is ($@, '', "No exception");

__END__
__Ruby__

def callback(t)
    yield t
end

def catch_perlerr
  begin
    return yield "neil"
  rescue PerlException => e
    print "Note: ruby caught an exception. No biggie!\n"
    return nil
  end
end
