use strict;
use Test::More tests => 6;
use Test::Requires 'Plack::Response';

BEGIN {
    use_ok 'HTTP::Response::Maker::Plack';
    use_ok 'HTTP::Response::Maker::Plack', class => 't::Plack::Response', prefix => 't_';
}

my $found = FOUND [ Location => '/' ];
isa_ok $found, 'Plack::Response';
is     $found->header('Location'), '/';
is     $found->code, 302;

my $t_404 = t_NOT_FOUND;
isa_ok $t_404, 't::Plack::Response';

{
    package t::Plack::Response;
    use base 'Plack::Response';
}
