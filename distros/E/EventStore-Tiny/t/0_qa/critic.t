use strict;
use warnings;

use FindBin;
use Test::More;

# Skip unless the user explicitely asked for it.
plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.'
    unless $ENV{TEST_AUTHOR};

# Try to load
eval { require Test::Perl::Critic; };
plan skip_all => 'Test::Perl::Critic required to criticize code.'
    if $@;

# Read configuration
Test::Perl::Critic->import(-profile => "$FindBin::Bin/../../perlcritic.rc");

# Criticize
all_critic_ok();

__END__
