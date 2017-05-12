use Kelp::Base -strict;
use Test::More;
use Kelp;

my $app = Kelp->new;
my $tmpl = '[% IF !bar %]foo[% ELSE %]bar[% END %]';

can_ok $app, $_ for qw/template/;
like $app->template( \$tmpl, { bar => 1 } ), qr/bar/;
unlike $app->template( \$tmpl, { bar => 1 } ), qr/foo/;
like $app->template( \$tmpl, { bar => 0 } ), qr/foo/;
unlike $app->template( \$tmpl, { bar => 0 } ), qr/bar/;

done_testing;
