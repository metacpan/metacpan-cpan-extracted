use warnings;
use strict;
use lib 't';
use Test::More tests => 9;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache35";
$cache_dir = create_cache($cache_dir);

sub HTML::Template::Compiled::Test::bar {
    return $_[0]->[0]
}
sub HTML::Template::Compiled::Test::baz {
    return $_[0]->[1]
}

local $HTML::Template::Compiled::DEBUG = 0;
{
    local $HTML::Template::Compiled::DEBUG = 1;
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%= /foo.bar %>
<%= /foo.boo %>
<%= /foo.baz %>
EOM
        debug => 0,
    );
    my $obj = bless [23, 24], 'HTML::Template::Compiled::Test';
    $htc->param(foo => $obj);
    my $out;
    eval {
        $out = $htc->output;
    };
    ok($@, "Exception");
    if ($@) {
        #warn __PACKAGE__.':'.__LINE__.": $@\n";
        my $msg = $htc->debug_code;
        my $msg_html = $htc->debug_code(1);;
        #print $msg, $/;
        #print $msg_html, $/;
        cmp_ok($msg, '=~', qr/ ERROR line (\d+)/, 'Error message');
    }
    else {
        ok(0, 'Exception');
    }
}

{
    my %exp = (
        mc => {
            0 => {
                count => {
                    1 => '### HTML::Template::Compiled Cache Debug ### FILE CACHE MISS: simple.tmpl',
                    2 => '### HTML::Template::Compiled Cache Debug ### FILE CACHE HIT: simple.tmpl',
                },
            },
            1 => {
                count => {
                    1 => '### HTML::Template::Compiled Cache Debug ### MEM CACHE MISS: simple.tmpl',
                    2 => '### HTML::Template::Compiled Cache Debug ### MEM CACHE HIT: simple.tmpl',
                },
            },
            2 => {
                count => {
                    1 => '### HTML::Template::Compiled Cache Debug ### MEM CACHE MISS: simple.tmpl'
. '### HTML::Template::Compiled Cache Debug ### FILE CACHE MISS: simple.tmpl',
                    2 => '### HTML::Template::Compiled Cache Debug ### MEM CACHE HIT: simple.tmpl',
                },
            },
        },
    );
    for my $mc (0, 1, 2) {
        my $memcache = 0;
        my $file_cache = 1;
        my $file_cache_dir = $cache_dir;
        if ($mc == 1) {
            $memcache = 1;
            $file_cache = 0;
            $file_cache_dir = '';
        }
        elsif ($mc == 2) {
            $memcache = 1;
        }
        my %args = (
            filename => "simple.tmpl",
            path => $tdir,
            cache       => $memcache,
            file_cache  => $file_cache,
            file_cache_dir  => $file_cache_dir,
            cache_debug => [qw/ mem_hit mem_miss file_hit file_miss /],
        );
        for my $count (1..2) {
            my $warn = '';
            {
                local $SIG{__WARN__} = sub {
                    $warn .= shift;
                };
                my $htc = HTML::Template::Compiled->new(
                    %args,
                );
                if ($count == 2) {
                    $htc->clear_cache();
                    HTML::Template::Compiled->clear_filecache($cache_dir);
                }
            }
            $warn =~ s/[\r\n]//g;
            my $exp = $exp{mc}->{$mc}->{count}->{$count};
            my $cache_string = $mc == 0 ? "file cache" : $mc == 1 ? "mem cache" : "file and mem cache";
            cmp_ok($warn, 'eq', $exp, "cache=$cache_string count=$count");
        }
    }
}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
