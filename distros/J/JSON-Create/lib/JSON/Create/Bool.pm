package JSON::Create::Bool;

use warnings;
use strict;

our @ISA = qw!Exporter!;
our @EXPORT = qw!true false!;
our $VERSION = '0.34';

my $t = 1;
my $f = 0;
my $true  = bless \$t, __PACKAGE__;
my $false = bless \$f, __PACKAGE__;

sub true
{
    return $true;
}

sub false
{
    return $false;
}

1;

=encoding UTF-8

=head1 NAME

JSON::Create::Bool - booleans for JSON::Create

=head1 SYNOPSIS

    use JSON::Create::Bool;

    my %thing = (yes => true, no => false);
    print json_create (\%thing);

=head1 DESCRIPTION

This module provides substitute booleans for JSON::Create. These
booleans are intended only to be used for generating C<true> and
C<false> literals in JSON output. They don't work very well for other
purposes. If you want booleans which can be used for general purposes,
please try other modules like L<boolean>.

=head1 EXPORTS

C<true> and C<false> are exported by default.

=cut

