use strict;
use warnings;
use Test::More;
use Getopt::EX::Config;

# Test underscore to dash conversion (enabled by default)
{
    # Test with dash options (should work when conversion is enabled)
    {
        my $config = Getopt::EX::Config->new(
            long_lc => 1,
            territory_lc => 0,
        );
        my @argv = qw(--long-lc --no-territory-lc -- other args);
        ok eval {
            $config->deal_with(\@argv, "long_lc!", "territory_lc!");
            1;
        }, 'dash options work when REPLACE_UNDERSCORE is enabled';
        
        ok($config->{long_lc}, 'long_lc set via --long-lc');
        ok(!$config->{territory_lc}, 'territory_lc unset via --no-territory-lc');
    }
    
    # Test that original underscore format still works
    {
        my $config = Getopt::EX::Config->new(
            long_lc => 0,
            territory_lc => 1,
        );
        my @argv = qw(--long_lc --no-territory_lc -- other args);
        
        ok eval {
            $config->deal_with(\@argv, "long_lc!", "territory_lc!");
            1;
        }, 'original underscore format still works';
        
        ok($config->{long_lc}, 'long_lc set via --long_lc');
        ok(!$config->{territory_lc}, 'territory_lc unset via --no-territory_lc');
    }
}

# Test with conversion disabled
{
    local $Getopt::EX::Config::REPLACE_UNDERSCORE = 0;
    
    # Test that dash options don't work when conversion is disabled
    {
        my $config = Getopt::EX::Config->new(
            long_lc => 1,
            territory_lc => 0,
        );
        my @argv = qw(--long-lc --no-territory-lc -- other args);
        ok !eval {
            $config->deal_with(\@argv, "long_lc!", "territory_lc!");
            1;
        }, 'dash options fail when REPLACE_UNDERSCORE is disabled';
    }
    
    # Test that underscore options still work
    {
        my $config = Getopt::EX::Config->new(
            long_lc => 0,
            territory_lc => 1,
        );
        my @argv = qw(--long_lc --no-territory_lc -- other args);
        ok eval {
            $config->deal_with(\@argv, "long_lc!", "territory_lc!");
            1;
        }, 'underscore options work when conversion is disabled';
        
        ok($config->{long_lc}, 'long_lc set via --long_lc');
        ok(!$config->{territory_lc}, 'territory_lc unset via --no-territory_lc');
    }
}

done_testing();