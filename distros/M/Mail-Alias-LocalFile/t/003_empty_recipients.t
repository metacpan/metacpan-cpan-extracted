#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
# use FindBin qw($Bin);
# use lib "$Bin/../../../../lib";  # Adjust path as needed to find LocalFile

# Test for empty recipients in various edge cases
use_ok('Mail::Alias::LocalFile');

# 1) Test non-existent alias
subtest 'Non-existent alias' => sub {
    my $aliases = {
        'existing' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['nonexistent']);
    
    is($result->{recipients}, '', 'Recipients is empty when using non-existent alias');
    ok(scalar @{$result->{warning}} > 0, 'Warning is generated for non-existent alias');
    like($result->{warning}->[0], qr/ERROR: The alias nonexistent was not found/, 
         'Warning message indicates alias not found');
};

# 2) Test alias key with mta_ prefix
subtest 'Alias key with mta_ prefix' => sub {
    my $aliases = {
        'normal' => 'test@example.com',
        'mta_postmaster' => 'postmaster@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test using the mta_ prefixed key directly
    my $result = $resolver->resolve_recipients(['mta_postmaster']);
    
    # Recipients should be empty because the key is skipped and not expanded
    is($result->{recipients}, '', 'Recipients is empty when using mta_ prefixed alias key');
    ok(scalar @{$result->{warning}} > 0, 'Warning is generated for mta_ prefixed alias key');
    like($result->{warning}->[0], qr/ERROR: Alias keys with 'mta_' prefix are not allowed/, 
         'Warning message indicates mta_ prefix not allowed in keys');
};

# 3) Test alias key with no values
subtest 'Alias key with no values' => sub {
    my $aliases = {
        'empty_alias' => '',
        'normal' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['empty_alias']);
    
    is($result->{recipients}, '', 'Recipients is empty when alias has no values');
    is_deeply($result->{expanded_addresses}, [], 'No addresses expanded from empty alias');
};

# 4) Test alias value held in a hash (invalid structure)
subtest 'Alias value as hash' => sub {
    # Create a hash reference that will be used as an alias value
    my $hash_value = { 'key' => 'value' };
    
    my $aliases = {
        'hash_alias' => $hash_value,
        'normal' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['hash_alias']);
    
    # Since the code doesn't explicitly handle hash values, it will likely ignore them
    is($result->{recipients}, '', 'Recipients is empty when alias value is a hash');
    is_deeply($result->{expanded_addresses}, [], 'No addresses expanded from hash alias');
};

# 5) Test alias with only malformed email addresses
subtest 'Alias with only malformed email addresses' => sub {
    my $aliases = {
        'bad_emails' => 'invalid@email@example.com, not-an-email, missing-at-sign.com',
        'normal' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['bad_emails']);
    
    is($result->{recipients}, '', 'Recipients is empty when alias contains only malformed emails');
    is_deeply($result->{expanded_addresses}, [], 'No addresses expanded from malformed emails');
    ok(scalar @{$result->{warning}} > 0, 'Warnings generated for malformed emails');
};

# Additional test: Combination of all edge cases
subtest 'Combined edge cases' => sub {
    my $hash_value = { 'key' => 'value' };
    
    my $aliases = {
        'nonexistent' => undef,  # Will be treated as non-existent
        'mta_postmaster' => 'postmaster@example.com',
        'empty_alias' => '',
        'hash_alias' => $hash_value,
        'bad_emails' => 'invalid@email@example.com, not-an-email',
        'normal' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients([
        'nonexistent', 
        'mta_postmaster', 
        'empty_alias', 
        'hash_alias', 
        'bad_emails'
    ]);
    
    is($result->{recipients}, '', 'Recipients is empty when combining all edge cases');
    ok(scalar @{$result->{warning}} > 0, 'Warnings generated for problematic inputs');
};

# Test the normal case for comparison
subtest 'Normal case' => sub {
    my $aliases = {
        'normal' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['normal']);
    
    isnt($result->{recipients}, '', 'Recipients is not empty in normal case');
    is($result->{recipients}, 'test@example.com', 'Recipients contains expected email in normal case');
};

# Test case with mixed valid and invalid inputs
subtest 'Mixed valid and invalid inputs' => sub {
    my $aliases = {
        'valid' => 'valid@example.com',
        'empty' => '',
        'bad_email' => 'not-an-email',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['valid', 'empty', 'bad_email', 'nonexistent']);
    
    isnt($result->{recipients}, '', 'Recipients is not empty with mixed inputs');
    is($result->{recipients}, 'valid@example.com', 'Recipients contains only the valid email');
    ok(scalar @{$result->{warning}} > 0, 'Warnings generated for invalid inputs');
};

done_testing();
