use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template::Compiled;
use lib 't';

{
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Pad = "FOO";
    my %args = (
        scalarref => \<<"EOM",
foo: <%= foo %>

<%loop list join=", " %><%= _ %><%/loop list %>
EOM
        cache => 0,
        pre_chomp => 0,
        post_chomp => 1,
        # debug => 1,
    );
    my $htc = HTML::Template::Compiled->new(
        %args,
    );
    $htc->param(
        foo => 23,
        list => [2 .. 5],
    );
    my $out = $htc->output;
    #warn __PACKAGE__.':'.__LINE__.": $out\n";
    cmp_ok($out, '=~', "foo: 23", "[Data::Dumper] literal template strings");
    cmp_ok($out, '=~', "2, 3, 4, 5", "[Data::Dumper] 'join' strings in loops");
}


