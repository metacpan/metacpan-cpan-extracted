use strict;
use Test::More tests => 6;
use Test::Requires 'HTTP::Exception';

use_ok 'HTTP::Response::Maker::Exception';

{
    eval { NOT_FOUND() };

    my $not_found = HTTP::Exception->caught;
    isa_ok $not_found,       'HTTP::Exception::Base';
    is     $not_found->code, 404;
}

{
    eval { FOUND([ location => 'http://www.example.com/' ]) };
    my $found = HTTP::Exception->caught;
    isa_ok $found, 'HTTP::Exception::Base';
    is     $found->code, 302;
    is     $found->location, 'http://www.example.com/';
}
