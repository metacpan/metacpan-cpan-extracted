use warnings;
use strict;
use lib 't';
use Test::More tests => 2;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);

{
    my $text = <<'EOM';
[%perl __OUT__ "template: __HTC__";
my $test = __ROOT__->{foo};
__OUT__ $test;
%]
[%loop loop%]
[%perl __OUT__ __INDEX__ . ": " . __CURRENT__->{a}; %]
[%/loop loop%]
[%include include_perl.htc %]
EOM
    HTML::Template::Compiled->ExpireTime(0);
    my $htc = HTML::Template::Compiled->new(
        scalarref => \$text,
        use_perl => 1,
        path => $tdir,
        debug    => 0,
        tagstyle => [qw(-classic -comment +asp +tt)],
        cache => 0,
        search_path_on_include => 1,
    );
    $htc->param(
        foo => 23,
        loop => [{ a => 'A' },{ a => 'B' }],
    );
    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~',
        qr{template: HTML::Template::Compiled.*23.*0: A.*1: B}s, "perl-tag");
}


