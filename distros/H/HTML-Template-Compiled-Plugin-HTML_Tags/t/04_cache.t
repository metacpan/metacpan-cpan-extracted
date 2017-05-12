# $Id: 04_cache.t,v 1.1 2007/10/27 11:33:30 tinita Exp $
use warnings;
use strict;
use blib;
use lib 't';
use Test::More tests => 2;
use HTML::Template::Compiled;
my $cache = "t/cache";
mkdir $cache;
#$HTML::Template::Compiled::Storable = 0;
for ("plugin without filecache", "plugin with filecache") {
    HTML::Template::Compiled->preload($cache);
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%html_option opt %>
EOM
        plugin => [qw(::HTML_Tags)],
        debug    => 0,
        file_cache => 1,
        file_cache_dir => $cache,
        cache => 0,
    );
    my $o = [ 'opt_2', # selected
            ['opt_1', 'option 1'],
            ['opt_2', 'option 2'],
    ];
    $htc->param(
        opt => $o,
    );
    my $exp = HTML::Template::Compiled::Plugin::HTML_Tags::_options(@$o);
    my $out = $htc->output;
    s/\s+/ /g, s/\s+\z//, s/^\s+// for ($exp, $out);
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$exp], ['exp']);
    #print "out: $out\n";
    cmp_ok($out, 'eq', $exp, $_);
    #cmp_ok($out, '=~', qr{Homer wants 3 beers.*Bart wants 7 donuts}s, "two plugins");
}


HTML::Template::Compiled->clear_filecache($cache);
