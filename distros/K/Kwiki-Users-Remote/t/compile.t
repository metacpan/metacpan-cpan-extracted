use lib 't', 'lib';
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok 'Kwiki::Users::Remote';
    use_ok 'Kwiki::UserName::Remote';
}
