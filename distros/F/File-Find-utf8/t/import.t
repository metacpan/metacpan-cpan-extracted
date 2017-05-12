#!perl
use strict;
use warnings;
use Test::Exception tests => 5;

# Test the various import combinations.
# Each test is performed in its own package to prevent one use
# statement influencing the other.

# Arguments to File::Find::find(depth), defines an empty test, not finding anything
my @findargs = ( { preprocess => sub { () }, wanted => sub { } }, '.' );

# Correct handling of the :none tag
{
    package test_none;
    use File::Find::utf8 qw(:none);
    Test::Exception::throws_ok
        {
            find(@findargs);
        }
        qr/Undefined subroutine &test_none::find called/,
        ':none correctly imported';
}

# Correct handling of !find
{
    package test_notfind;
    use File::Find::utf8 qw(!find);
    Test::Exception::throws_ok
          {
              find(@findargs);
          }
          qr/Undefined subroutine &test_notfind::find called/,
          'find correctly not imported with !find';
    Test::Exception::lives_ok
          {
              finddepth(@findargs);
          }
          'finddepth correctly imported with !find';
}

# Correct handling of /find/
{
    package test_re;
    use File::Find::utf8 qw(/find/);
    Test::Exception::lives_ok
    {
        find(@findargs);
        finddepth(@findargs);
    }
    'find and finddepth correctly imported with /find/';
}

# Correct handling of invalid symbol
{
    package test_invalid;
    require File::Find::utf8;
    Test::Exception::throws_ok
          {
              File::Find::utf8->import(qw(invalid_symbol));
          }
          qr/"invalid_symbol" is not exported by the File::Find module/,
          'invalid symbol correctly noted';
}
