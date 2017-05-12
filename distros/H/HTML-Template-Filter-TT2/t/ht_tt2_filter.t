use strict;
use Test::More;
use HTML::Template;


my @cases = (
    {
        label    => "variable",
        template => "The title is: [% title %]",
        params   => { title => "Lorem ipsum" },
        output   => "The title is: Lorem ipsum",
    },
    {
        label    => "variable wih default, not using it",
        template => "[% name :John Doe %]",
        params   => { name => "Gloria Leonard" },
        output   => "Gloria Leonard",
    },
    {
        label    => "variable with default, using it",
        template => "[% name :John Doe %]",
        params   => {  },
        output   => "John Doe",
    },
    {
        label    => "variable with filter",
        template => "[% duck | html %]",
        params   => { duck => "_\\o< coin!" },
        output   => "_\\o&lt; coin!",
    },
    {
        label    => "variable with filter and default",
        template => "[% name :John Doe | html %]",
        params   => { name => "Dillion Day" },
        output   => "Dillion Day",
    },
    {
        label    => "if statement (true)",
        template => "[% if cond1 %]cond1=true[% else %]conf1=false[% end_if %]",
        params   => { cond1 => 1 },
        output   => "cond1=true",
    },
    {
        label    => "if statement (false)",
        template => "[% if cond2 %]conf2=true[% else %]conf2=false[% end_if %]",
        params   => { cond2 => 0 },
        output   => "conf2=false",
    },
    {
        label    => "loop",
        template => "interfaces: [% loop interface %]\n"
                  . "  name=[% name %]  addr=[% address %][% end_loop %]\n",
        params   => {
            interface => [
                { name => "lo",    address => "127.0.0.1" },
                { name => "eth0",  address => "192.168.1.1" },
            ]
        },
        output   => "interfaces: \n"
                  . "  name=lo  addr=127.0.0.1\n"
                  . "  name=eth0  addr=192.168.1.1\n",
    },
);


plan tests => 3 + 4 * @cases;

use_ok("HTML::Template::Filter::TT2");
can_ok("HTML::Template::Filter::TT2", qw(ht_tt2_filter));
can_ok(__PACKAGE__, qw(ht_tt2_filter));


for my $case (@cases) {
    my @args = (
        scalarref => \$case->{template},
        filter => \&ht_tt2_filter,
    );

    my $tmpl = eval { HTML::Template->new(@args) };
    is( $@, "", "[[ $case->{label} ]]" );
    isa_ok( $tmpl, "HTML::Template" );

    eval { $tmpl->param(%{$case->{params}}) };
    is( $@, "", "passing params" );

    is( $tmpl->output, $case->{output}, "checking rendered output" );
}

