use strict;
use warnings;
use Test::More tests => 15;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use HTC_Utils qw/ $tdir &create_cache &remove_cache /;
my $cache_dir = "cache39";
$cache_dir = create_cache($cache_dir);

my $warning = '';
local $SIG{__WARN__} = sub { $warning = $_[0] };
for my $li (0..1) {
    my %args = (
        filename => "line_info1.html",
        file_cache_dir => $cache_dir,
        file_cache => 1,
        cache => 0,
        path => $tdir,
        line_info => $li,
#        debug => 1,
    );
    my $htc = HTML::Template::Compiled->new(
        %args,
        warnings => 0,
    );
    $htc->param(
        foo => undef,
    );
    my $out = $htc->output;
    $out =~ s/\s+/ /g;
    cmp_ok($out, "eq", "test test2 test3 foo: undef line 4 test4 ", "warnings 0 output ok");
    cmp_ok($warning, "eq", '', "warnings 0 shouldn't produce any warnings");

    HTML::Template::Compiled->clear_filecache($cache_dir);
    $warning = '';

    $htc = HTML::Template::Compiled->new(
        %args,
        warnings => 1,
    );
    $htc->param(
        foo => undef,
    );
    $out = $htc->output;
    $out =~ s/\s+/ /g;
    cmp_ok($out, "eq", "test test2 test3 foo: undef line 4 test4 " , "warnings 1 output ok");
    cmp_ok($warning, "=~", 'Use of uninitialized value', "warnings 1 should produce warnings");
    if ($li) {
        cmp_ok($warning, '=~', "at t.templates.line_info1.html line 4", "line information");
    }
    HTML::Template::Compiled->clear_filecache($cache_dir);
    $warning = '';

    $htc = HTML::Template::Compiled->new(
        %args,
        warnings => 'fatal',
    );
    $htc->param(
        foo => undef,
    );
    $out = '';
    eval {
        $out = $htc->output;
    };
    my $error = $@;
    cmp_ok($out, "eq", "", "warnings fatal empty output ok");
    cmp_ok($error, "=~", 'Use of uninitialized value', "warnings fatal should die");
    if ($li) {
        cmp_ok($error, '=~', "at t.templates.line_info1.html line 4", "line information");
    }
    HTML::Template::Compiled->clear_filecache($cache_dir);
    $warning = '';
}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
