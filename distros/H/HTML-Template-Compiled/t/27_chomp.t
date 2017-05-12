use warnings;
use strict;
use lib 't';
use Test::More tests => 3;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<tmpl_var foo POST_CHOMP=3 >
<tmpl_var  foo >
<!--tmpl_var foo PRE_CHOMP=3 -->
<%var foo PRE_CHOMP=3 POST_CHOMP=3 %>
EOM
        tagstyle => [qw(+classic +asp +comment )],
        debug => 0,
    );
    $htc->param(foo => 23);
    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, 'eq', '23232323', "chomp");
}

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%loop foo %>
* <%= _ %>
<%/loop PRE_CHOMP=3 POST_CHOMP=3 %>
EOM
        tagstyle => [qw(+asp)],
        debug => 0,
    );
    my $exp = <<'EOM';

* 2
* 3
* 4
EOM
    $htc->param(foo => [2..4]);
    chomp($exp);
    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, 'eq', $exp, "chomp loop");
}


