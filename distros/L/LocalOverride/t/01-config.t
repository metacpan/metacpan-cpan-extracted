#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

my %fallthrough;

BEGIN {
    push @INC, sub { $fallthrough{$_[1]}++; open my $fh, '<', \'1'; $fh; };
}

use LocalOverride;

# Don't do local loads if core_only is set
{
    %fallthrough = ();
    local $LocalOverride::core_only = 1;

    require co::Foo;
    is_deeply(\%fallthrough, { 'co/Foo.pm' => 1 }, 'load from core only');
}

# Don't do local loads for modules outside of the base namespace
{
    %fallthrough = ();
    local $LocalOverride::base_namespace = 'base';

    require xbn::Foo;
    is_deeply(\%fallthrough, {
        'xbn/Foo.pm'              => 1,
    }, 'load from core only if outside of base namespace');

    require base::Foo;
    is_deeply(\%fallthrough, {
        'base/Foo.pm'             => 1,
        'base/Local/Foo.pm'       => 1,
        'xbn/Foo.pm'              => 1,
    }, 'load from core and Local if within base namespace');
}

# Look for overrides in a namespace other than Local
{
    %fallthrough = ();
    local $LocalOverride::local_prefix = 'Custom';

    require cst::Foo;
    is_deeply(\%fallthrough, {
        'cst/Foo.pm'             => 1,
        'Custom/cst/Foo.pm'      => 1,
    }, 'load from custom local namespace with empty base namespace');

    %fallthrough = ();
    local $LocalOverride::base_namespace = 'base';

    require base::cst::Foo;
    is_deeply(\%fallthrough, {
        'base/cst/Foo.pm'        => 1,
        'base/Custom/cst/Foo.pm' => 1,
    }, 'load from custom local namespace with base namespace set');

}

done_testing;
