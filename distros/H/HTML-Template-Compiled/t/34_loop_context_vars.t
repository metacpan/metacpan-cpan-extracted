
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 17;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use HTC_Utils qw($cache $tdir &cdir);
use strict;
use warnings;
my $short_tmpl = 'file_debug.html';
my $long_tmpl = cdir('subdir', 'file_debug.html');
my $short_path = cdir($tdir, $short_tmpl);
my $long_path = cdir($tdir, $long_tmpl);

{
    my $htc = HTML::Template::Compiled->new(
        path => $tdir,
        filename => $short_tmpl,
        cache => 0,
        loop_context_vars => 1,
        search_path_on_include => 1,
        debug => 0,
    );

    my $out = $htc->output;
    #print $out, $/;
    $out =~ s/\s+/ /g;
    cmp_ok($out, "=~", qr#^test \Q$short_path $short_tmpl\E end#,
        "filename debug 1");
}
{
    my $htc = HTML::Template::Compiled->new(
        path => $tdir,
        filename => $long_tmpl,
        loop_context_vars => 1,
        search_path_on_include => 1,
        cache => 0,
        debug => 0,
    );

    my $out = $htc->output;
    #print $out, $/;
    $out =~ s/\s+/ /g;
    cmp_ok($out, "=~", qr#^test \Q$long_path $long_tmpl\E end#,
        "filename debug 2");
}
for my $debug (qw/ start end /, 'start,end') {
    for my $short (0, 1) {
        my $debug_string = $debug;
        $debug_string .= ',short' if $short;
        my $htc = HTML::Template::Compiled->new(
            path => $tdir,
            filename => $long_tmpl,
            loop_context_vars => 1,
            search_path_on_include => 1,
            debug => 0,
            cache => 0,
            debug_file => $debug_string,
        );

        my $out = $htc->output;
        #print $out, $/;
        $out =~ s/\s+/ /g;
        cmp_ok($out, "=~", qr#test \Q$long_path\E \Q$long_tmpl\E end#,
            "filename debug '$debug_string'");
        my $testpath = $short ? $long_tmpl : $long_path;
        if ($debug =~ m/start/) {
            cmp_ok($out, "=~", qr#<!-- start \Q$testpath\E -->#,
                "filename debug '$debug_string' start");
        }
        if ($debug =~ m/end/) {
            cmp_ok($out, "=~", qr#<!-- end \Q$testpath\E -->#,
                "filename debug '$debug_string' end");
        }
    }
}

