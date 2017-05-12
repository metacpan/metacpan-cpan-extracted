# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 4;
BEGIN { use_ok('HTML::Template::Compiled') };

{
    my $htc = HTML::Template::Compiled->new(
        path => 't/templates',
        filehandle => \*DATA,
        global_vars => 1,
        search_path_on_include => 1,
        debug => 0,
        case_sensitive => 0,
    );

    $htc->param(
        global => 42,
        outer => [
            {
                loopvar => 'one',
            },
            {
                loopvar => 'two',
                global => 23,
            },
            {
                loopvar => 'three',
            },
        ],
    );
    my $out = $htc->output;
    #print $out, $/;
    cmp_ok($out, '=~', qr{
        loopvar:\ one.*global:\ 42.*\ included:.*
        loopvar:\ two.*global:\ 23.*\ included:.*
        loopvar:\ three.*global:\ 42.*\ included:.*
        }xs, 'global_vars');
    cmp_ok($out, "!~", "neverset", "global_vars and unset variable");
}

{
    my $htc = HTML::Template::Compiled->new(
        global_vars => 2,
        scalarref => \<<EOM,
<tmpl_with a>
 <tmpl_with b>
  <tmpl_var a>
  <tmpl_var inner>
  <tmpl_var ..c.inner>
 </tmpl_with>
</tmpl_with>
EOM
        debug => 0,
    );
    $htc->param(
        a => {
            b => { inner => 23 },
            c => { inner => 42 },
        },
    );
    my $out = $htc->output;
    #print "($out)\n";
    like($out, qr/^\s+23\s+42\s+$/, "global_vars => 2");
}

__DATA__
global: <tmpl_var global>
<tmpl_loop outer>
 <tmpl_with undefined1></tmpl_with><tmpl_loop undefined2></tmpl_loop><tmpl_if undefined3></tmpl_if><tmpl_unless undefined4></tmpl_unless>
 loopvar: <tmpl_var loopvar>
 global: <tmpl_var global>
 included: <tmpl_include include_w_global.htc >
</tmpl_loop>

<tmpl_if neverset>neverset</tmpl_if>
