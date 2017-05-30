use strict;
use warnings;

# compare pathnames for equality - / and \ are treated identically
sub is_path
{
    goto \&Test::More::is if $^O ne 'MSWin32';

    my ($got, $want, $test_name) = @_;

    $got =~ s{\\}{/}g;

    $test_name ||= 'path name matches';
    $test_name .= ' (where / and \\ are considered identical)';

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is($got, $want, $test_name);
}

# compare pathname to regex - / and \ are treated identically
sub like_path
{
    goto \&Test::More::like if $^O ne 'MSWin32';

    my ($got, $want_re, $test_name) = @_;

    $got =~ s{\\}{/}g;

    $test_name ||= 'path name matches';
    $test_name .= ' (where / and \\ are considered identical)';

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like($got, $want_re, $test_name);
}

1;
