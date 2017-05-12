use warnings;
use strict;
use lib qw(t);
use Test::More tests => 4;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);
use Fcntl qw(:seek);

{
    local $/;
    my $data = <DATA>;
    for my $styles (
        [qw(-classic +php -comment -asp +tt)],
        [qw(+classic -php +comment -asp -tt)],
        [qw(+classic -php +comment +asp -tt)],
    ) {
        my $htc = HTML::Template::Compiled->new(
            scalarref => \$data,
            tagstyle => $styles,
            debug => 0,
            cache => 0,
        );
        my $match = '';
        for my $style (@$styles) {
            if ($style =~ m/^\+(.*)/) {
                $match .= "$1: BAR\n";
            }
            elsif ($style =~ m/^\-(.*)/) {
                $match .= "$1: .*foo.*\n";
            }
        }
        $htc->param(foo => "BAR");
        my $out = $htc->output;
        cmp_ok($out,"=~", qr{$match}, "tagstyle (@$styles)");
        #print "out: $out\n";
    }
}


__DATA__
classic: <tmpl_var foo>
php: <?= foo ?>
comment: <!-- tmpl_var foo -->
asp: <%= foo %>
tt: [%var foo %]
