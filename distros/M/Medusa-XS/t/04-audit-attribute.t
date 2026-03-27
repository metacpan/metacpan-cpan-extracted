#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Phase 4: Test :Audit attribute handling

# Create a simple mock logger to capture output
{
    package MockLogger;
    our @MESSAGES;
    
    sub new {
        my $class = shift;
        @MESSAGES = ();
        return bless {}, $class;
    }
    
    sub debug { push @MESSAGES, $_[1] }
    sub info  { push @MESSAGES, $_[1] }
    sub error { push @MESSAGES, $_[1] }
    sub clear { @MESSAGES = () }
}

use_ok('Medusa::XS');

# Set up mock logger globally
$Medusa::XS::LOG{LOG} = MockLogger->new();

# ----------------------------------------------------------------
# Test 1: Basic :Audit attribute on subroutine
# ----------------------------------------------------------------
{
    package TestPkg1;
    use Medusa::XS;
    
    sub audited_add :Audit {
        my ($a, $b) = @_;
        return $a + $b;
    }
    
    package main;
    
    MockLogger->clear();
    
    ok(Medusa::XS::is_audited(\&TestPkg1::audited_add), 
       ':Audit attribute marks sub as audited');
    
    my $result = TestPkg1::audited_add(10, 20);
    is($result, 30, ':Audited sub returns correct value');
    
    my $has_call = grep { /audited_add.*called/ } @MockLogger::MESSAGES;
    my $has_return = grep { /audited_add.*returned/ } @MockLogger::MESSAGES;
    
    ok($has_call, 'log contains call message');
    ok($has_return, 'log contains return message');
}

# ----------------------------------------------------------------
# Test 2: Multiple :Audit subs in same package
# ----------------------------------------------------------------
{
    package TestPkg2;
    use Medusa::XS;
    
    sub method_a :Audit { return "a"; }
    sub method_b :Audit { return "b"; }
    sub method_c { return "c"; }  # Not audited
    
    package main;
    
    ok(Medusa::XS::is_audited(\&TestPkg2::method_a), 'method_a is audited');
    ok(Medusa::XS::is_audited(\&TestPkg2::method_b), 'method_b is audited');
    ok(!Medusa::XS::is_audited(\&TestPkg2::method_c), 'method_c is NOT audited');
}

# ----------------------------------------------------------------
# Test 3: :Audit on sub that throws exception
# ----------------------------------------------------------------
{
    package TestPkg3;
    use Medusa::XS;
    
    sub throws :Audit {
        die "expected error";
    }
    
    package main;
    
    eval { TestPkg3::throws() };
    like($@, qr/expected error/, 'exception propagates through :Audit');
}

# ----------------------------------------------------------------
# Test 4: :Audit preserves calling context at return
# Note: The wrapped sub always runs in list context internally.
# The context is handled at the return boundary.
# ----------------------------------------------------------------
{
    package TestPkg4;
    use Medusa::XS;
    
    sub returns_multi :Audit {
        return (1, 2, 3);
    }
    
    package main;
    
    my $scalar = TestPkg4::returns_multi();
    is($scalar, 1, ':Audit returns first element in scalar context');
    
    my @list = TestPkg4::returns_multi();
    is_deeply(\@list, [1, 2, 3], ':Audit preserves list context');
}

# ----------------------------------------------------------------
# Test 5: FETCH_CODE_ATTRIBUTES returns Audit for audited subs
# ----------------------------------------------------------------
{
    package TestPkg5;
    use Medusa::XS;
    use attributes;
    
    sub with_audit :Audit { return 1; }
    sub without_audit { return 2; }
    
    package main;
    
    my @attrs_with = attributes::get(\&TestPkg5::with_audit);
    ok(grep({ $_ eq 'Audit' } @attrs_with), 
       'FETCH_CODE_ATTRIBUTES returns Audit for audited sub');
    
    my @attrs_without = attributes::get(\&TestPkg5::without_audit);
    ok(!grep({ $_ eq 'Audit' } @attrs_without), 
       'FETCH_CODE_ATTRIBUTES returns empty for non-audited sub');
}

# ----------------------------------------------------------------
# Test 6: :Audit with arguments (future-proofing)
# ----------------------------------------------------------------
{
    package TestPkg6;
    use Medusa::XS;
    
    # :Audit(level=debug) - options parsed but currently ignored
    sub with_options :Audit(level=debug) {
        return "options";
    }
    
    package main;
    
    ok(Medusa::XS::is_audited(\&TestPkg6::with_options), 
       ':Audit(options) marks sub as audited');
    
    my $result = TestPkg6::with_options();
    is($result, "options", ':Audit(options) sub works correctly');
}

# ----------------------------------------------------------------
# Test 7: GUIDs appear in log  
# ----------------------------------------------------------------
{
    package TestPkg7;
    use Medusa::XS;
    
    sub for_guid :Audit { return 1; }
    
    package main;
    
    MockLogger->clear();
    
    TestPkg7::for_guid();
    TestPkg7::for_guid();
    
    # GUIDs should appear in the log output (UUID v4 format)
    my @guids = grep { /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i } 
                @MockLogger::MESSAGES;
    ok(@guids >= 2, 'GUIDs appear in log messages');
}

done_testing();
