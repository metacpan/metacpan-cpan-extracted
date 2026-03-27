#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Medusa::XS');

# Set up a mock logger to capture messages
{
    package TestLogger;
    our @LOG;
    
    sub new { 
        @LOG = (); 
        bless {}, shift;
    }
    sub debug { push @LOG, $_[1]; }
    sub info { push @LOG, $_[1]; }
    sub error { push @LOG, $_[1]; }
    sub get_log { join("\n", @LOG); }
}

# ----------------------------------------------------------------
# Test 1: Wrap a subroutine and verify auditing produces log output
# ----------------------------------------------------------------
{
    # Reset LOG with mock logger
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    
    sub test_add {
        my ($a, $b) = @_;
        return $a + $b;
    }
    
    Medusa::XS::wrap_sub(\&test_add, 'test_add');
    ok(Medusa::XS::is_audited(\&test_add), 'test_add is audited after wrap_sub');
    
    my $result = test_add(2, 3);
    is($result, 5, 'wrapped function returns correct value');
    
    my $log_content = TestLogger->get_log();
    
    like($log_content, qr/test_add/, 'log contains function name');
    like($log_content, qr/called/i, 'log contains "called"');
}

# ----------------------------------------------------------------
# Test 2: Test function returning multiple values
# ----------------------------------------------------------------
{
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    
    sub test_multi_return {
        return (1, 2, 3);
    }
    
    Medusa::XS::wrap_sub(\&test_multi_return, 'test_multi_return');
    
    my @result = test_multi_return();
    is_deeply(\@result, [1, 2, 3], 'multi-value return preserved');
    
    my $log_content = TestLogger->get_log();
    
    like($log_content, qr/returned/i, 'log contains "returned"');
}

# ----------------------------------------------------------------
# Test 3: Void context call
# ----------------------------------------------------------------
{
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    our $side_effect = 0;
    
    sub test_void {
        $side_effect = 42;
    }
    
    Medusa::XS::wrap_sub(\&test_void, 'test_void');
    
    test_void();
    is($side_effect, 42, 'void context side effect works');
}

# ----------------------------------------------------------------
# Test 4: Complex arguments pass through correctly
# ----------------------------------------------------------------
{
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    
    sub test_complex_args {
        my ($hash, $array) = @_;
        return $hash->{key} . join('', @$array);
    }
    
    Medusa::XS::wrap_sub(\&test_complex_args, 'test_complex_args');
    
    my $result = test_complex_args({key => 'hello'}, [1, 2, 3]);
    is($result, 'hello123', 'complex args passed correctly');
}

# ----------------------------------------------------------------
# Test 5: Exception handling - function that dies
# ----------------------------------------------------------------
{
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    
    sub test_die {
        die "intentional failure";
    }
    
    Medusa::XS::wrap_sub(\&test_die, 'test_die');
    
    eval { test_die() };
    like($@, qr/intentional failure/, 'exception propagates correctly');
}

# ----------------------------------------------------------------
# Test 6: Timing measurement
# ----------------------------------------------------------------
{
    $Medusa::XS::LOG{LOG} = TestLogger->new();
    @TestLogger::LOG = ();
    
    sub test_timing {
        select(undef, undef, undef, 0.01);  # Sleep 10ms
        return "done";
    }
    
    Medusa::XS::wrap_sub(\&test_timing, 'test_timing');
    
    my $result = test_timing();
    is($result, 'done', 'timed function returns correctly');
    
    my $log_content = TestLogger->get_log();
    
    # XS uses elapsed= format (check for a decimal number after "elapsed")
    like($log_content, qr/elapsed.*\d+\.\d+/, 'log shows timing info');
}

done_testing();
