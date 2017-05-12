# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 2;
BEGIN { use_ok('HTML::Template::Compiled') };

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%with foo.bar %>
    bar:<%= _[0] %>
<%/with foo.bar %>
<%with foo.baz %>
    baz:<%= _[0] %>
<%/with foo.baz %>
EOM
        debug => 0,
    );

    $htc->param(
        foo => {
            bar => [qw/ this and that /],
        },
    );
    my $out = $htc->output;
    $out =~ s/\s+//g;
    #print $out, $/;
    cmp_ok($out, "eq", "bar:this", "global_vars and unset variable");
}
