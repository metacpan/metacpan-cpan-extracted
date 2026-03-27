#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Test Phase 2: Custom op infrastructure

BEGIN {
    use_ok('Medusa::XS') || BAIL_OUT("Cannot load Medusa::XS");
}

# ------------------------------------------------------------------ #
# Test _make_test_audit_op() - creates and frees an AUDITOP           #
# ------------------------------------------------------------------ #

{
    my $result = Medusa::XS::_make_test_audit_op("test_method", "Test::Package");
    ok(defined $result, '_make_test_audit_op: result defined');
    like($result, qr/^AUDIT_CACHE\@Test::Package::test_method$/, '_make_test_audit_op: returns AUDIT_CACHE confirmation');
    
    my $result2 = Medusa::XS::_make_test_audit_op("another_method", "Another::Pkg");
    ok(defined $result2, '_make_test_audit_op: second AUDIT_CACHE created');
}

# ------------------------------------------------------------------ #
# Test wrap_sub() - wraps a CV with auditing                          #
# ------------------------------------------------------------------ #

{
    sub test_sub_for_wrapping { return 42; }
    
    my $coderef = \&test_sub_for_wrapping;
    ok(ref($coderef) eq 'CODE', 'wrap_sub: got a coderef');
    ok(!Medusa::XS::is_audited($coderef), 'wrap_sub: CV is not audited initially');
    
    my $wrapped = Medusa::XS::wrap_sub($coderef);
    ok(defined $wrapped, 'wrap_sub: returns something');
    ok(Medusa::XS::is_audited($coderef), 'wrap_sub: CV is marked as audited');
}

# ------------------------------------------------------------------ #
# Test is_audited() with various inputs                               #
# ------------------------------------------------------------------ #

{
    ok(!Medusa::XS::is_audited("string"), 'is_audited: string returns false');
    ok(!Medusa::XS::is_audited(123), 'is_audited: number returns false');
    ok(!Medusa::XS::is_audited([1,2,3]), 'is_audited: arrayref returns false');
    
    sub fresh_unwrapped_sub { return 1; }
    ok(!Medusa::XS::is_audited(\&fresh_unwrapped_sub), 'is_audited: fresh sub is not audited');
}

# ------------------------------------------------------------------ #
# Test that wrapping is idempotent                                    #
# ------------------------------------------------------------------ #

{
    sub idempotent_test_sub { return 'hello'; }
    
    my $coderef = \&idempotent_test_sub;
    
    Medusa::XS::wrap_sub($coderef);
    ok(Medusa::XS::is_audited($coderef), 'idempotent: CV is audited after first wrap');
    
    my $result = Medusa::XS::wrap_sub($coderef);
    ok(defined $result, 'idempotent: second wrap_sub succeeds');
    ok(Medusa::XS::is_audited($coderef), 'idempotent: CV is still audited');
}

# ------------------------------------------------------------------ #
# Test wrap_sub() with custom method name                             #
# ------------------------------------------------------------------ #

{
    sub sub_with_custom_name { return 'test'; }
    
    my $coderef = \&sub_with_custom_name;
    my $wrapped = Medusa::XS::wrap_sub($coderef, "custom_audit_name");
    ok(defined $wrapped, 'custom name: wrap_sub succeeds');
    ok(Medusa::XS::is_audited($coderef), 'custom name: CV is marked as audited');
}

# ------------------------------------------------------------------ #
# Test wrap_sub() with anonymous sub                                  #
# ------------------------------------------------------------------ #

{
    my $anon = sub { return "anonymous"; };
    
    my $wrapped = Medusa::XS::wrap_sub($anon);
    ok(defined $wrapped, 'anon sub: wrap_sub succeeds');
    ok(Medusa::XS::is_audited($anon), 'anon sub: marked as audited');
}

# ------------------------------------------------------------------ #
# Test wrap_sub() error handling                                      #
# ------------------------------------------------------------------ #

{
    eval { Medusa::XS::wrap_sub("not a coderef"); };
    like($@, qr/argument must be a code reference/i, 'error: croaks on non-coderef');
    
    eval { Medusa::XS::wrap_sub([1,2,3]); };
    like($@, qr/argument must be a code reference/i, 'error: croaks on arrayref');
}

done_testing();
