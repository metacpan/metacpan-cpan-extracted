use Test::More;
use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;
eval "use Number::Format;";
plan skip_all => 'Number::Format required for these tests' if $@;
plan tests => 3;

sub render {
    my( $template, %vars ) = @_;
    my $result;

    eval {     
        my $t = new HTML::Template::Pluggable(
            scalarref => \$template,
            case_sensitive => 1,
        );
        $t->param( %vars );
    
        $result = $t->output;
    };
    diag $@ if $@;
    return $result;
}

my $out;

$out = render( 
    "Amount: <tmpl_var order.total_amount>",
    order     => { total_amount => 12.2 }
);
is( $out, 'Amount: 12.2', 'Substitute value from hashref' );

my $formatter = new Number::Format;
ok( $formatter && $formatter->isa('Number::Format'), 'Instantiate Number::Format' );

$out = render(
    q{Amount: <tmpl_var name="Formatter.format_price(order.total_amount, 2, 'USD ')">},
    Formatter => $formatter,
    order     => { total_amount => 12.2 }
);
is( $out, 'Amount: USD 12.20' );

__END__
1..0 # SKIP Number::Format required for these tests
