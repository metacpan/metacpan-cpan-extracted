#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin qw($Bin);
use lib "$Bin/../../../../lib";  # Adjust path as needed to find Mail::Alias::LocalFile

#use FindBin;  # path to this script
#use lib "$FindBin::Bin/../../../"; # path to lib directory
#use Mail::Alias::LocalFile;



# Test for empty processed_aliases HashRef
use_ok('Mail::Alias::LocalFile');

subtest 'Empty processed_aliases HashRef' => sub {
    # Create a simple aliases hash
    my $aliases = {
        'test1' => 'test1@example.com',
        'test2' => 'test2@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Initial state check
    is_deeply($resolver->processed_aliases, {}, 'processed_aliases starts empty');
    
    # Case 1: No aliases are processed when only emails are provided
    my $result = $resolver->resolve_recipients(['direct1@example.com', 'direct2@example.com']);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty when only direct emails are given');
    
    # Case 2: Empty result when no recipients are provided
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients([]);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty when no recipients are provided');
    
    # Case 3: Empty result for non-existent aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['nonexistent1', 'nonexistent2']);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty when only non-existent aliases are given');
    
    # Case 4: Direct MTA aliases don't populate processed_aliases
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $result = $resolver->resolve_recipients(['mta_alias1', 'mta_alias2']);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty when only MTA aliases are given');
    
    # Case 5: Empty after manually calling extract_addresses_from_list
    $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    $resolver->extract_addresses_from_list('direct@example.com');
    is_deeply($resolver->processed_aliases, {}, 
        'processed_aliases remains empty after extract_addresses_from_list with direct email');
};

# Tracking processed aliases test
subtest 'Tracking processed aliases' => sub {
    # Create aliases hash with nested aliases
    my $aliases = {
        'simple' => 'test@example.com',
    };
    
    my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
    
    # Initial state check
    is_deeply($resolver->processed_aliases, {}, 'processed_aliases starts empty');
    
    # Process an alias
    my $result = $resolver->resolve_recipients(['simple']);
    
    # Verify processed_aliases is now populated
    isnt(scalar(keys %{$result->{processed_aliases}}), 0, 
        'processed_aliases populated after processing a real alias');
    
    # Check that the specific alias was processed
    ok(exists $result->{processed_aliases}{'simple'}, 
        'The alias was properly tracked in processed_aliases');
};

# Test for edge cases
subtest 'Edge Cases' => sub {
    # Create a resolver with an empty aliases hash
    my $resolver = Mail::Alias::LocalFile->new(aliases => {});
    
    # Check initial state
    is_deeply($resolver->processed_aliases, {}, 'processed_aliases starts empty with empty aliases');
    
    # Process with empty input
    my $result = $resolver->resolve_recipients([]);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty with empty input and empty aliases');
    
    # Process with only direct emails
    $result = $resolver->resolve_recipients(['test@example.com']);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty with direct email and empty aliases');
    
    # Process with only nil/undefined values
    $result = $resolver->resolve_recipients([undef, '', 0]);
    is_deeply($result->{processed_aliases}, {}, 
        'processed_aliases remains empty with nil/undefined values');
};

done_testing();
