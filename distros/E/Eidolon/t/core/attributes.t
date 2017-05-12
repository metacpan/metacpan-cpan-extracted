#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/attributes.t - attributes tests
#
# ==============================================================================  

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests => 5;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Attributes");
    use ETests_Attributes;
}

# methods
ok( ETests_Attributes->can("MODIFY_CODE_ATTRIBUTES"), "MODIFY_CODE_ATTRIBUTES method" );
ok( ETests_Attributes->can("FETCH_CODE_ATTRIBUTES"),  "FETCH_CODE_ATTRIBUTES method"  );

is
(
    ETests_Attributes->code_cache->{"Yamaoka"}, 
    \&ETests_Attributes::akira, 
    "code reference lookup" 
);

is_deeply
( 
    ETests_Attributes->attr_cache->{ \&ETests_Attributes::akira }, 
    [ "Yamaoka" ],
    "attributes lookup"
);

