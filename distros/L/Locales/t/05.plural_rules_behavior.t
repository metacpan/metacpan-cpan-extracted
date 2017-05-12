use Test::More;

use Locales;

my @tests;

diag "Setting up for individual rule tests.";
my $loc = Locales->new('en');
for my $tag ( sort $loc->get_language_codes() ) {
    my $tag_loc = Locales->new($tag) || next;
    for my $rule ( $tag_loc->get_plural_form_categories() ) {
        next if !exists $tag_loc->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules'}{$rule};    # i.e. 'other'
        my $string    = $tag_loc->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules'}{$rule};
        my $perl_code = Locales::plural_rule_string_to_code( $string, $rule );
        my $js_code   = Locales::plural_rule_string_to_javascript_code( $string, $rule );
        push @tests, [ $tag, $rule, $perl_code, $js_code, $string ];
    }
}

eval 'use JE ()';
plan $@ ? ( 'skip_all' => 'JE.pm required for testing JS/Perl plural behavior tests' ) : ( 'tests' => ( scalar(@tests) * 262 ) );
my $js = JE->new();
my $err;
my @nums = ( 0, 1.6, 2.2, 3.14159, 42.78, 0 .. 256 );
diag "Starting individual rule tests.";

for my $n (@nums) {

    for my $t (@tests) {
        my $perl = eval "$t->[2]";
        is(
            $js->eval("var f = $t->[3]; return f($n)") || 'undefined',
            $perl->($n) || 'undefined',
            "perl and js plural rules behave the same. Tag: $t->[0] Category: $t->[1] Number: $n"
        ) || _error( $t->[4], $t->[3], $t->[2], $t->[0], $t->[1], $n );

        ## See details in comment above Locales::get_plural_form(), basically, "negatives keep same category as positive"
        ## is(
        ##     $js->eval("var f = $t->[3]; return f(-$n)") || 'undefined',
        ##     $perl->("-$n") || 'undefined',
        ##     "perl and js plural rules behave the same. Tag: $t->[0] Category: $t->[1] Number: -$n"
        ## ) || _error( $t->[4], $t->[3], $t->[2], $t->[0], $t->[1], "-$n" );
    }
}

use Data::Dumper;
diag( Dumper($err) ) if $err;

sub _error {
    my ( $raw, $js, $perl, $tag, $cat, $num ) = @_;
    push( @{ $err->{$raw}{$tag} }, $num ) if $ENV{'RELEASE_TESTING'};
    diag("\tRaw: $raw\n\tJS: $js\n\tPerl: $perl\n");
}
