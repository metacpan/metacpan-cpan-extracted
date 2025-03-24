#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
# use FindBin qw($Bin);
# use lib "$Bin/../../../../lib";
use_ok('Mail::Alias::LocalFile');

# Test 1: Invalid use of 'mta_' prefix as a key in aliases file
subtest 'Invalid mta_ prefix as key' => sub {
    my $aliases = {
        'valid_alias' => 'test@example.com',
        'mta_postmaster' => 'postmaster@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Test when explicitly trying to use the mta_ prefixed key
    my $result = $resolver->resolve_recipients(['mta_postmaster']);
    
    # 1) Test that it's skipped and not included in recipients
    is($result->{recipients}, '', 'mta_ prefixed alias keys are not included in recipients');
    
    # 2) Test that it generates a warning
    ok(scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$result->{warning}}, 
       'Warning is generated for mta_ prefixed alias key');
    
    # 3) Test that it doesn't end up in mta_aliases
    is_deeply($result->{mta_aliases}, [], 'mta_ prefixed alias key is not added to mta_aliases');
    
    # 4) Test that addresses associated with the invalid key are never evaluated
    is_deeply($result->{expanded_addresses}, [], 'Addresses for mta_ prefixed key are not expanded');
};

# Test 2: Valid use of 'mta_' prefix as a value
subtest 'Valid mta_ prefix as value' => sub {
    my $aliases = {
        'hostmaster' => 'mta_hostmaster, test@example.com',
        'simple' => 'test2@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['hostmaster']);
    
    # 1) Test no warning for valid mta_ usage in values
    ok(!scalar grep { /ERROR.+hostmaster/ } @{$result->{warning}}, 
       'No warning for valid use of mta_ prefix in alias value');
    
    # 2) Test recipients includes both the MTA alias (without prefix) and regular email
    like($result->{recipients}, qr/hostmaster/, 'MTA alias included in recipients (without mta_ prefix)');
    like($result->{recipients}, qr/test\@example\.com/, 'Regular email included in recipients');
    
    # 3) Test mta_aliases contains the correct entry (without prefix)
    is_deeply($result->{mta_aliases}, ['hostmaster'], 
              'mta_aliases contains correct value with mta_ prefix removed');
    
    # 4) Test uniq_email_addresses has the email but not the MTA alias
    is_deeply($result->{uniq_email_addresses}, ['test@example.com'],
       'Regular email is in uniq_email_addresses, but MTA alias is not');
};

# Test 3: Passing an mta_ prefixed alias directly - should be skipped with warning
subtest 'Direct mta_ prefix - should be skipped' => sub {
    my $aliases = {
        'normal' => 'test@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['mta_direct']);
    
    # Direct mta_ prefixed alias should be skipped with warning
    is_deeply($result->{mta_aliases}, [], 
              'Direct mta_ prefixed alias is skipped and not added to mta_aliases');
    
    # Recipients should be empty
    is($result->{recipients}, '', 'Recipients is empty when only direct mta_ prefixed alias is provided');
    
    # Should generate a warning
    ok(scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$result->{warning}}, 
       'Warning generated for direct mta_ prefixed alias');
};

# Test 4: Mixed valid and invalid usage
subtest 'Mixed valid and invalid mta_ usages' => sub {
    my $aliases = {
        'valid' => 'mta_valid_service, email@example.com',
        'mta_invalid' => 'invalid@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['valid', 'mta_invalid']);
    
    # Valid usage should work correctly
    is_deeply($result->{mta_aliases}, ['valid_service'], 
              'Valid mta_ usage correctly processed');
    
    # Invalid key should be skipped and generate warning
    ok(scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$result->{warning}}, 
       'Warning for invalid mta_ prefix in key');
    
    # Recipients should only contain valid entries
    like($result->{recipients}, qr/valid_service/, 'Valid MTA service in recipients');
    like($result->{recipients}, qr/email\@example\.com/, 'Valid email in recipients');
    unlike($result->{recipients}, qr/invalid\@example\.com/, 'Invalid email not in recipients');
};

# Test 5: Mixed direct mta_ prefix with valid alias
subtest 'Mixed direct mta_ prefix with valid alias' => sub {
    my $aliases = {
        'valid' => 'test@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['valid', 'mta_direct']);
    
    # Direct mta_ prefix should be skipped with warning
    is_deeply($result->{mta_aliases}, [], 
              'Direct mta_ prefixed alias is skipped even when mixed with valid alias');
    
    # Recipients should contain only the valid email
    is($result->{recipients}, 'test@example.com', 'Recipients contains only the valid email');
    
    # Should generate a warning
    ok(scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$result->{warning}}, 
       'Warning generated for direct mta_ prefixed alias in mixed input');
};

# Test 6: Nested aliases with mta_ prefix in values
subtest 'Nested aliases with mta_ prefix in values' => sub {
    my $aliases = {
        'level1' => 'mta_service1, level2',
        'level2' => 'mta_service2, email@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['level1']);
    
    # Both mta_ services should be processed
    cmp_bag($result->{mta_aliases}, ['service1', 'service2'], 
            'Both nested mta_ services correctly processed');
    
    # Recipients should contain all valid entries
    like($result->{recipients}, qr/service1/, 'First MTA service in recipients');
    like($result->{recipients}, qr/service2/, 'Second MTA service in recipients');
    like($result->{recipients}, qr/email\@example\.com/, 'Email in recipients');
};

# Test 7: Alias containing mta_ prefixed value that is also a key (improperly) in aliases
subtest 'Alias value matching improper mta_ key' => sub {
    my $aliases = {
        'valid' => 'mta_service, email@example.com',
        'mta_service' => 'service@example.com'  # Improper key
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['valid']);
    
    # The mta_service in valid's value should be processed normally as a service
    # It should NOT expand the improper mta_service key
    is_deeply($result->{mta_aliases}, ['service'], 
              'mta_ value correctly processed without expanding improper key');
    
    # Recipients should contain service and email
    like($result->{recipients}, qr/service/, 'MTA service in recipients');
    like($result->{recipients}, qr/email\@example\.com/, 'Email in recipients');
    unlike($result->{recipients}, qr/service\@example\.com/, 'Value of improper key not in recipients');
};

# Test 8: Test detect_circular_references function with mta_ prefixed keys
subtest 'detect_circular_references with mta_ keys' => sub {
    my $aliases = {
        'normal' => 'value',
        'mta_bad' => 'bad_value'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my @circular = $resolver->detect_circular_references($aliases);
    
    # Test warning is generated for mta_ key
    ok(scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$resolver->warning}, 
       'detect_circular_references generates warning for mta_ key');
};

# Test 9: Multiple mta_ prefixed values in one alias
subtest 'Multiple mta_ values in one alias' => sub {
    my $aliases = {
        'multi' => 'mta_service1, mta_service2, email@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['multi']);
    
    # Both services should be processed
    cmp_bag($result->{mta_aliases}, ['service1', 'service2'], 
            'Multiple mta_ services correctly processed');
    
    # Recipients should contain all valid entries
    like($result->{recipients}, qr/service1/, 'First MTA service in recipients');
    like($result->{recipients}, qr/service2/, 'Second MTA service in recipients');
    like($result->{recipients}, qr/email\@example\.com/, 'Email in recipients');
};

# Test 10: Multiple direct mta_ prefixed aliases
subtest 'Multiple direct mta_ prefixed aliases' => sub {
    my $aliases = {
        'normal' => 'test@example.com'
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result = $resolver->resolve_recipients(['mta_direct1', 'mta_direct2']);
    
    # All direct mta_ prefixed aliases should be skipped
    is_deeply($result->{mta_aliases}, [], 
              'Multiple direct mta_ prefixed aliases all skipped');
    
    # Recipients should be empty
    is($result->{recipients}, '', 'Recipients is empty when only direct mta_ prefixed aliases are provided');
    
    # Should generate warnings
    my $warning_count = scalar grep { /ERROR: Alias keys with 'mta_' prefix are not allowed/ } @{$result->{warning}};
    is($warning_count, 2, 'Warnings generated for all direct mta_ prefixed aliases');


};

done_testing();
