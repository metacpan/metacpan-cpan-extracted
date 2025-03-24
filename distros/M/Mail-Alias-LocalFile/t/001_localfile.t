#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;

# use FindBin qw($Bin);
# use lib "$Bin/../../../../lib";  # Adjust path as needed to find LocalFile

# Tests for LocalFile.pm
use_ok('Mail::Alias::LocalFile');

# Test basic initialization
subtest 'Basic Initialization' => sub {
    # Test constructor requires aliases
    throws_ok { Mail::Alias::LocalFile->new() } qr/Missing required arguments: aliases/, 
        'Constructor requires aliases argument';
    
    # Test valid initialization
    my $aliases = { 'test' => 'test@example.com' };
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    isa_ok($resolver, 'Mail::Alias::LocalFile', 'Object created successfully');
    is_deeply($resolver->aliases, $aliases, 'Aliases stored correctly');
};

# Test email validation
subtest 'Email Validation' => sub {
    my $aliases = { 'test' => 'test@example.com' };
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test processing valid email
    $resolver->process_potential_email('valid@example.com');
    is_deeply($resolver->expanded_addresses, ['valid@example.com'], 
        'Valid email address added to expanded addresses');
    is_deeply($resolver->warning, [], 'No warnings for valid email');
    
    # Test processing invalid email
    $resolver->expanded_addresses([]);  # Reset
    $resolver->warning([]);             # Reset
    $resolver->process_potential_email('invalid@email@example.com');
    is($resolver->warning->[0], 
   'ERROR: invalid@email@example.com is not a correctly formatted email address, skipping', 
   'Warning generated for invalid email');

    # Test case normalization
    $resolver->expanded_addresses([]);  # Reset
    $resolver->warning([]);             # Reset
    $resolver->process_potential_email('UPPER@EXAMPLE.COM');
    is($resolver->expanded_addresses->[0], 'upper@example.com', 
        'Email address normalized to lowercase');
};

# Test alias expansion
subtest 'Alias Expansion' => sub {
    my $aliases = {
        'simple' => 'simple@example.com',
        'multiple' => 'one@example.com,two@example.com',
        'array' => ['three@example.com', 'four@example.com'],
        'nested' => 'simple, nested2',
        'nested2' => 'nested3',
        'nested3' => 'final@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test simple alias
    my $result = $resolver->resolve_recipients(['simple']);
    is($result->{recipients}, 'simple@example.com', 'Simple alias expanded correctly');
    
    # Test multiple emails in one alias
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['multiple']);
    cmp_bag($resolver->expanded_addresses, ['one@example.com', 'two@example.com'], 
        'Multiple emails in alias expanded correctly');
    
    # Test array alias
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['array']);
    cmp_bag($resolver->expanded_addresses, ['three@example.com', 'four@example.com'], 
        'Array alias expanded correctly');
    
    # Test nested aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['nested']);
    like($result->{recipients}, qr/simple\@example\.com/, 'First level nested alias included');
    like($result->{recipients}, qr/final\@example\.com/, 'Deeply nested alias included');
};

# Test MTA aliases
subtest 'MTA Aliases' => sub {
    my $aliases = {
        'postmaster' => 'mta_postmaster',
        'normal' => 'normal@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test mta_ prefix alias
    my $result = $resolver->resolve_recipients(['postmaster']);
    is_deeply($resolver->mta_aliases, ['postmaster'], 'MTA alias processed correctly');
    like($result->{recipients}, qr/postmaster/, 'MTA alias included in recipients');
    
    # Test direct mta_ prefix
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['mta_direct']);
  # is_deeply($resolver->mta_aliases, ['direct'], 'Direct MTA alias processed correctly');
  # is_deeply($resolver->mta_aliases, ['Does not exist'], 'Direct MTA alias skipped correctly');
    ok($result->{recipients} eq '', 'A key beginning with mta_ is not included in recipients');
    ok(@{$result->{warning}} > 0, 'A key beginning with mta_ generates a warning');
    
    # Test mixed normal and MTA aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['normal', 'postmaster']);
    is_deeply($resolver->mta_aliases, ['postmaster'], 'MTA alias processed in mixed input');
    like($result->{recipients}, qr/normal\@example\.com/, 'Normal email included in mixed input');
    like($result->{recipients}, qr/postmaster/, 'MTA alias included in mixed input');
};

# Test duplicate removal
subtest 'Duplicate Removal' => sub {
    my $aliases = {
        'team' => 'a@example.com,b@example.com,a@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test duplicate removal
    my $result = $resolver->resolve_recipients(['team']);
    is_deeply($resolver->expanded_addresses, ['a@example.com', 'b@example.com', 'a@example.com'], 
        'Expanded addresses include duplicates');
    is_deeply($resolver->uniq_email_addresses, ['a@example.com', 'b@example.com'], 
        'Unique addresses list removes duplicates');
    
    # Test case insensitivity in duplicate removal
    $aliases = {
        'team' => 'a@example.com,B@example.com,A@EXAMPLE.COM'
    };
    
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['team']);
    # Since emails are normalized to lowercase before comparison
    cmp_bag($resolver->uniq_email_addresses, ['a@example.com', 'b@example.com'], 
        'Duplicate removal is case insensitive');
};

# Test circular reference detection
subtest 'Circular Reference Detection' => sub {
    my $aliases = {
        'circle1' => 'circle2',
        'circle2' => 'circle3',
        'circle3' => 'circle1',
        'self' => 'self',
        'normal' => 'normal@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test basic circular detection
    my $circular = $resolver->detect_circular_references($aliases);
    ok(scalar(grep { /circle1 -> circle2 -> circle3 -> circle1/ } @$circular), 
        'Detected multi-level circular reference');
    ok(scalar(grep { /self -> self/ } @$circular), 
        'Detected self-reference');
    
    # Test circular reference handling during resolution
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['circle1']);
    ok(@{$result->{warning}} > 0, 'Circular reference generates warnings');
    ok(@{$result->{circular_references}} > 0, 'Circular reference output identified');
    
    # Test mixed circular and normal aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['circle1', 'normal']);
    like($result->{recipients}, qr/normal\@example\.com/, 
        'Normal email extracted despite circular reference');
};

# Test whitespace and formatting handling
subtest 'Whitespace and Formatting' => sub {
    my $aliases = {
        'spaces' => '  spaced@example.com  ,  another@example.com',
        'mixed_format' => 'one@example.com two@example.com,three@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test spaces in alias values
    my $result = $resolver->resolve_recipients(['spaces']);
    cmp_bag($resolver->expanded_addresses, ['spaced@example.com', 'another@example.com'], 
        'Spaces trimmed from email addresses');
    
    # Test mixed space/comma separation
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['mixed_format']);
    cmp_bag($resolver->expanded_addresses, 
        ['one@example.com', 'two@example.com', 'three@example.com'], 
        'Mixed space/comma separation handled correctly');
};

# Test real-world example from provided aliases.yml
subtest 'Real-world Example' => sub {
    my $aliases = {
        'Jill' => 'Jill@example.com,VP',
        'VP' => 'Jill',
        'bill' => 'Bill.Williams@somecompany.com',
        'mary' => 'Mary@example.com',
        'tech_team' => [
            'john@company.com,     Joe@example.com,,,mary,',
            'dev_leads'
        ],
        'dev_leads' => [
            'sarah@company.com',
            'mike@company.com    Mary@example.com',
            'bill, Jill, mike.smith@example.com',
            'tech_team'
        ],
        'group2' => 'Billy@example.com,  mike.smith@example.com,mary@example.com',
        'postmaster' => 'mta_postmaster'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test circular detection in complex structure
    my @circular = $resolver->detect_circular_references($aliases);
    ok(scalar @circular > 0, 'Circular references detected in complex structure');
    
    # Test expansion of complex group
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['group2']);
    cmp_bag(
        $resolver->expanded_addresses, 
        ['billy@example.com', 'mike.smith@example.com', 'mary@example.com'],
        'Complex group expanded correctly'
    );
    
    # Test MTA alias in complex structure
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['postmaster']);
    is_deeply($resolver->mta_aliases, ['postmaster'], 'MTA alias handled correctly in complex structure');
};

# Test handling of missing aliases
subtest 'Missing Alias' => sub {
    my $aliases = {
        'valid' => 'valid@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['validxx']);

    # Test non-existent alias
    $resolver->process_potential_alias('nonexistent');
    like($resolver->warning->[0], qr/ERROR: The alias validxx was not found/, 
        'Warning for non-existent alias');
  # ok($result->{processed_aliases} eq \%{}, 'A missing alias is not processed');
    ok($result->{recipients} eq '', 'A missing alias is not included as a recipient');
    like($resolver->original_input->[0], qr/validxx/, 'The missing alias is recorded in original_input'); 

};

# Test multiple alias processing
subtest 'Multiple Alias Processing' => sub {
    my $aliases = {
        'alias1' => 'one@example.com',
        'alias2' => 'two@example.com',
        'mixed' => 'three@example.com, alias1'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test multiple aliases in one call
    my $result = $resolver->resolve_recipients(['alias1', 'alias2']);
    cmp_bag($resolver->expanded_addresses, ['one@example.com', 'two@example.com'], 
        'Multiple aliases expanded correctly');
    
    # Test mixed direct emails and aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['direct@example.com', 'alias1']);
    cmp_bag($resolver->expanded_addresses, ['direct@example.com', 'one@example.com'], 
        'Mixed direct emails and aliases handled correctly');
    
    # Test alias with embedded alias
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['mixed']);
    cmp_bag($resolver->expanded_addresses, ['three@example.com', 'one@example.com'], 
        'Alias with embedded alias expanded correctly');
};

# Test result structure
subtest 'Result Structure' => sub {
    my $aliases = {
        'simple' => 'simple@example.com',
        'mta' => 'mta_relay'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['simple', 'mta']);
    
    # Test result structure
    ok(exists $result->{expanded_addresses}, 'Result contains expanded_addresses');
    ok(exists $result->{uniq_email_addresses}, 'Result contains uniq_email_addresses');
    ok(exists $result->{recipients}, 'Result contains recipients');
    ok(exists $result->{original_input}, 'Result contains original_input');
    ok(exists $result->{warning}, 'Result contains warning');
    ok(exists $result->{aliases}, 'Result contains aliases reference');
    ok(exists $result->{processed_aliases}, 'Result contains processed_aliases');
    ok(exists $result->{mta_aliases}, 'Result contains mta_aliases');
    
    # Test result values
    is_deeply($result->{expanded_addresses}, ['simple@example.com'], 'expanded_addresses correct');
    is_deeply($result->{uniq_email_addresses}, ['simple@example.com'], 'uniq_email_addresses correct');
    is_deeply($result->{original_input}, ['simple', 'mta'], 'original_input correct');
    is_deeply($result->{mta_aliases}, ['relay'], 'mta_aliases correct');
    like($result->{recipients}, qr/simple\@example\.com/, 'recipients contains email');
    like($result->{recipients}, qr/relay/, 'recipients contains MTA alias');
};

done_testing();
