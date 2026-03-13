#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test nested data structures
subtest 'nested structures' => sub {
    package RefPkg1;
    use Legba qw/nested_slot/;
    
    my $nested = {
        level1 => {
            level2 => {
                level3 => [1, 2, { deep => 'value' }]
            }
        }
    };
    
    nested_slot($nested);
    Test::More::is_deeply(nested_slot(), $nested, 'nested structure preserved');
    Test::More::is(nested_slot()->{level1}{level2}{level3}[2]{deep}, 'value', 'deep access works');
};

# Test modifying stored reference
subtest 'modify stored reference' => sub {
    package RefPkg2;
    use Legba qw/modify_slot/;
    
    my $data = { count => 0 };
    modify_slot($data);
    
    # Modify through retrieved reference
    my $ref = modify_slot();
    $ref->{count}++;
    
    Test::More::is(modify_slot()->{count}, 1, 'modification persists');
    
    # Original also sees change
    Test::More::is($data->{count}, 1, 'original reference sees change');
};

# Test circular references
subtest 'circular references' => sub {
    package RefPkg3;
    use Legba qw/circular_slot/;
    
    my $a = { name => 'a' };
    my $b = { name => 'b', ref => $a };
    $a->{ref} = $b;
    
    circular_slot($a);
    
    my $got = circular_slot();
    Test::More::is($got->{name}, 'a', 'circular ref a.name');
    Test::More::is($got->{ref}{name}, 'b', 'circular ref a.ref.name');
    Test::More::is($got->{ref}{ref}{name}, 'a', 'circular ref cycle works');
};

# Test blessed references
subtest 'blessed references' => sub {
    package MyClass;
    sub new { bless { value => $_[1] }, $_[0] }
    sub value { $_[0]->{value} }
    
    package RefPkg4;
    use Legba qw/blessed_slot/;
    
    my $obj = MyClass->new(42);
    blessed_slot($obj);
    
    my $got = blessed_slot();
    Test::More::isa_ok($got, 'MyClass', 'blessing preserved');
    Test::More::is($got->value, 42, 'method call works');
};

# Test weak references  
subtest 'weak references' => sub {
    package RefPkg5;
    use Legba qw/weak_slot/;
    use Scalar::Util qw(weaken isweak);
    
    my $strong = { data => 'test' };
    my $weak = $strong;
    weaken($weak);
    
    weak_slot($weak);
    
    # The slot holds a copy, so it won't be weak
    Test::More::ok(!isweak(weak_slot()), 'stored copy is not weak');
    Test::More::is(weak_slot()->{data}, 'test', 'weak ref data accessible');
};

# Test reference to slot value
subtest 'reference to slot' => sub {
    package RefPkg6;
    use Legba qw/ref_target_slot/;
    
    ref_target_slot("original");
    
    # Can't take ref to the accessor return value and modify it
    # but we can store a reference in another slot
    package RefPkg7;
    use Legba qw/ref_holder_slot/;
    
    ref_holder_slot(\RefPkg6::ref_target_slot());
    Test::More::is(${ref_holder_slot()}, "original", 'reference to scalar');
};

# Test multiple references to same external data
subtest 'shared external data' => sub {
    package RefPkg8;
    use Legba qw/share_a share_b/;
    
    my $shared = { shared => 1 };
    share_a($shared);
    share_b($shared);
    
    $shared->{shared} = 2;
    
    Test::More::is(share_a()->{shared}, 2, 'share_a sees update');
    Test::More::is(share_b()->{shared}, 2, 'share_b sees update');
};

# Test storing filehandles
subtest 'filehandle' => sub {
    package RefPkg9;
    use Legba qw/fh_slot/;
    
    open my $fh, '<', \(my $data = "test data");
    fh_slot($fh);
    
    my $got_fh = fh_slot();
    my $line = <$got_fh>;
    Test::More::is($line, "test data", 'filehandle readable');
    close $got_fh;
};

# Test regex references
subtest 'regex ref' => sub {
    package RefPkg10;
    use Legba qw/regex_slot/;
    
    my $re = qr/^hello\s+world$/i;
    regex_slot($re);
    
    my $got = regex_slot();
    Test::More::ok("Hello World" =~ $got, 'regex works');
    Test::More::ok("goodbye" !~ $got, 'regex non-match works');
};

done_testing();
