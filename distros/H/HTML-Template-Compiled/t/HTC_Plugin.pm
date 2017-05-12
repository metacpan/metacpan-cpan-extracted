use strict;
use warnings;
use Data::Dumper;
{
package # hide from CPAN =)
    HTC_Plugin1;
use HTML::Template::Compiled::Expression qw(:expressions);

HTML::Template::Compiled->register(__PACKAGE__);
sub register {
    my ($class) = @_;
    my %plugs = (
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                HOMER => [sub { exists $_[1]->{BEER} }, qw(BEER)],
            },
        },
        compile => {
            HOMER => {
                open => sub {
                    my ($htc, $token, $args) = @_;
                    my $OUT = $args->{out};
                    my $attr = $token->get_attributes;
                    my $beer = $attr->{BEER};
                    my $varstr = $htc->get_compiler->parse_var($htc,
                        var => $beer,
                        method_call => $htc->method_call,
                        deref => $htc->deref,
                        formatter_path => $htc->formatter_path,
                    );
                    my $expression = _expr_literal(
                        <<"EOM"
$OUT "Homer wants " . $varstr . " beers";
EOM
                    );
                    return $expression->to_string;
                },
            },
        },
    );
    return \%plugs;
}

}

#1;
#__END__

{
package # hide from CPAN =)
    HTC_Plugin2;

use HTML::Template::Compiled::Expression qw(:expressions);
HTML::Template::Compiled->register(__PACKAGE__);
sub register {
    my ($class) = @_;
    my %plugs = (
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                BART => [sub { exists $_[1]->{DONUT} }, qw(DONUT)],
            },
        },
        compile => {
            BART => {
                open => sub {
                    my ($htc, $token, $args) = @_;
                    my $OUT = $args->{out};
                    my $attr = $token->get_attributes;
                    my $beer = $attr->{DONUT};
                    my $varstr = $htc->get_compiler->parse_var($htc,
                        var => $beer,
                        method_call => $htc->method_call,
                        deref => $htc->deref,
                        formatter_path => $htc->formatter_path,
                    );
                    my $expression = _expr_literal(
                        <<"EOM"
$OUT "Bart wants " . $varstr . " donuts";
EOM
                    );
                    return $expression->to_string;
                },
            },
        },
    );
    return \%plugs;
}

}


1;
