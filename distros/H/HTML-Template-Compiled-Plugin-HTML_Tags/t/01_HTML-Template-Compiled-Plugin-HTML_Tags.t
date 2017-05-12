# $Id: 01_HTML-Template-Compiled-Plugin-HTML_Tags.t,v 1.6 2007/07/25 18:54:16 tinita Exp $
use warnings;
use strict;
use blib;
use lib 't';
use lib '../HTML-Template-Compiled/blib/lib';
use Test::More tests => 8;
use_ok('HTML::Template::Compiled');
use_ok('HTML::Template::Compiled::Plugin::HTML_Tags');

my ($exp_2, $exp_3);
{
    local $/;
    my $exp = <DATA>;
    ($exp_2, $exp_3) = split /^-+$/m, $exp;
}

{
    my $htc = HTML::Template::Compiled->new(
        plugin => ['HTML::Template::Compiled::Plugin::HTML_Tags'],
        scalarref => \<<'EOM',
<%HTML_OPTION foo%>
EOM
        debug => 0,
    );
    $htc->param(
        foo => [
            3,
            [1, 'Jan'],
            [2, 'Feb'],
            [3, 'Mar'],
        ],
    );
    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~', qr{<option.*1.*Jan.*<option.*2.*Feb.*<option.*selected.*Mar}s, "options");
    $htc->param(
        foo => [
            [2,3],
            [1, 'Jan'],
            [2, 'Feb'],
            [3, 'Mar'],
        ],
    );
    $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~', qr{<option.*1.*Jan.*<option.*2.*.selected.*Feb.*<option.*selected.*Mar}s, "multiple options");

    $htc->param(
        foo => [
            ['Feb','Mar'],
            'Jan',
            'Feb',
            'Mar',
        ],
    );
    $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~', qr{<option.*Jan.*Jan.*<option.*Feb.*.selected.*Feb.*<option.*selected.*Mar}s, "multiple options");

}
{
    my $htc = HTML::Template::Compiled->new(
        plugin => ['HTML::Template::Compiled::Plugin::HTML_Tags'],
        scalarref => \<<'EOM',
<%HTML_TABLE foo HEADER=1%>
EOM
        debug => 0,
    );
    $htc->param(
        foo => [
            [1, 'Jan'],
            [2, 'Feb'],
            [3, 'Mar'],
        ],
    );
    my $out = $htc->output;
    #print "out: $out\n";
    $exp_2 =~ s/\s+//g;
    $out =~ s/\s+//g;
    cmp_ok($out, 'eq', $exp_2, "table");
}
{
    my $htc = HTML::Template::Compiled->new(
        plugin => ['HTML::Template::Compiled::Plugin::HTML_Tags'],
        scalarref => \<<'EOM',
<%HTML_SELECT foo SELECT_ATTR="class='myselect'"%>
EOM
        debug => 0,
    );
    $htc->param(
        foo => {
            name    => 'foo',
            value   => 2,
            options => [
                [1, 'Jan'],
                [2, 'Feb'],
                [3, 'Mar'],
            ],
        },
    );
    my $out = $htc->output;
    #print "out: $out\n";
    $exp_3 =~ s/\s+//g;
    $out =~ s/\s+//g;
    cmp_ok($out, 'eq', $exp_3, "select");
}
{
    my $htc = HTML::Template::Compiled->new(
        plugin => ['HTML::Template::Compiled::Plugin::HTML_Tags'],
        scalarref => \<<'EOM',
<%HTML_OPTION_LOOP foo %>
<%= value %>:<%= label %>(<%= selected %>)
<%/HTML_OPTION_LOOP %>
<%HTML_BOX_LOOP foo %>
<%= value %>:<%= label %>(<%= selected %>)
<%/HTML_BOX_LOOP %>
EOM
        debug => 0,
    );
    $htc->param(
        foo => [
            2,
            [1, 'Jan'],
            [2, 'Feb'],
            [3, 'Mar'],
        ],
    );
    my $out = $htc->output;
    #print "out: $out\n";
    $out =~ s/\s+//g;
    cmp_ok(
        $out, 'eq',
          qq#1:Jan()2:Feb(selected="selected")3:Mar()#
        . qq#1:Jan()2:Feb(checked="checked")3:Mar()#,
        "select");
}


__DATA__
<table >
<tr ><th >1</th><th >Jan</th></tr>
<tr >
<td >2</th>
<td >Feb</th>
</tr>

<tr >
<td >3</th>
<td >Mar</th>
</tr>

</table>
----------------------------
<select name="foo" class='myselect'>
<option value="1" >Jan</option>
<option value="2" selected="selected">Feb</option>
<option value="3" >Mar</option>
</select>
