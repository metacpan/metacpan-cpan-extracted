# Objective:
# ----------
#
# Test Event::Lib::base::args() and ::args_del()

use Test;
BEGIN { plan tests => 7 + 4 + 7 + 8 }
use Event::Lib;

{ # read-only access
    sub handler1 {
	my ($ev, $evtype, @args) = @_;
	ok($ev->args, 10_000);
	ok($ev->args, @args);
	ok(($ev->args)[0], $args[0]);
	ok(($ev->args)[9_999], $args[-1]);
    }

    my $e = timer_new(\&handler1, 1 .. 10_000);
    ok($e->args, 10_000);
    ok(($e->args)[0], 1);
    ok(($e->args)[9_999], 10_000);
    $e->add(0.5);
    
    event_mainloop;
}


{ # write access: deleting args
    sub handler2 {
	my ($ev, $evtype, @args) = @_;
	ok($ev->args, 0);
	ok(@args, 0);
    }

    my $e = timer_new(\&handler2, 1 .. 10_000);
    ok($e->args, 10_000);
    $e->args_del;
    ok($e->args, 0);
    $e->add(0.5);

    event_mainloop;
}

{ # write access: replace args
    sub handler3 {
	my ($ev, $evtype, @args) = @_;
	ok($ev->args, 26);
	ok($ev->args, @args);
	ok( join("", $ev->args), join("", 'A'..'Z') );
	ok( join("", $ev->args), join("", @args) );
    }

    my $e = timer_new(\&handler3, 1 .. 10_000);
    ok($e->args, 10_000);
    $e->args('A' .. 'Z');
    ok($e->args, 26);
    ok( join("", $e->args), join("", 'A'..'Z') );
    $e->add(0.5);

    event_mainloop;
}

{ # write access: delete args (Lib.xs wont yet free the array of SV*'s),
  # then set them again
    sub handler4 {
	goto &handler3;	# 4 tests
    }
    
    my $e = timer_new(\&handler3, 1 .. 10_000);
    ok($e->args, 10_000);
    $e->args_del;
    ok($e->args, 0);
    $e->args('A' .. 'Z');
    ok($e->args, 26);
    ok( join("", $e->args), join("", 'A'..'Z') );
    $e->add(0.5);

    event_mainloop;
}
