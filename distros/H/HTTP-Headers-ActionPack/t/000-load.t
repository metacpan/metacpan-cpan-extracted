#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal 0.0003;

BEGIN {
    use_ok('HTTP::Headers::ActionPack');
    use_ok('HTTP::Headers::ActionPack::AuthenticationInfo');
    use_ok('HTTP::Headers::ActionPack::Authorization::Basic');
    use_ok('HTTP::Headers::ActionPack::Authorization::Digest');
    use_ok('HTTP::Headers::ActionPack::DateHeader');
    use_ok('HTTP::Headers::ActionPack::LinkHeader');
    use_ok('HTTP::Headers::ActionPack::LinkList');
    use_ok('HTTP::Headers::ActionPack::MediaType');
    use_ok('HTTP::Headers::ActionPack::MediaTypeList');
    use_ok('HTTP::Headers::ActionPack::PriorityList');
    use_ok('HTTP::Headers::ActionPack::Util');
    use_ok('HTTP::Headers::ActionPack::WWWAuthenticate');
}

done_testing;
