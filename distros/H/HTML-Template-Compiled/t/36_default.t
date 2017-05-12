# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 2;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use HTC_Utils qw($cache $tdir &cdir);

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<TMPL_VAR escape="js" name="empty" default="foo">
EOM
        debug => 0,
        loop_context_vars => 1,
        path => $tdir,
    );
    $htc->param(
        list => [qw(a b c d e f g h)]
    );
    my $out = $htc->output;
    $out =~ s/\s+/ /g;
    #print $out, $/;
    cmp_ok($out, 'eq','foo ', "loop context vars in include");
}

