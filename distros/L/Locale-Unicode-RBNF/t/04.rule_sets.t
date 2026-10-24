#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/04.rule_sets.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use File::Spec;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' )       || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF' );
    use_ok( 'Locale::Unicode::RBNF::CLDR' ) || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF::CLDR' );
};

# NOTE: rule_sets_from_description
subtest 'rule_sets_from_description' => sub
{
    my $desc = <<'EOT';
%%lenient-parse:
    &[last primary ignorable ] << ' ' << ',';
%main:
    -x: minus >>;
    0: zero;
    1100/100: << hundred[ >>];
    1000>: =#,##0=;
%%private@noparse:
    0:' leading space;
    1: ;
EOT
    my $r = Locale::Unicode::RBNF->rule_sets_from_description( $desc );
    ok( $r, 'description divided' ) || diag( Locale::Unicode::RBNF->error );
    is( $r->{lenient_parse}, "&[last primary ignorable ] << ' ' << ','", 'lenient-parse rules extracted' );
    is( scalar( @{$r->{rule_sets}} ), 2, 'two rule sets' );
    my( $main, $priv ) = @{$r->{rule_sets}};
    is( $main->{name}, '%main', 'name' );
    is( $main->{type}, 'main', 'type' );
    is( $main->{private}, 0, 'public' );
    is_deeply( $main->{rules},
    [
        { descriptor => '-x', text => 'minus >>' },
        { descriptor => '0', text => 'zero' },
        { descriptor => '1100/100', text => '<< hundred[ >>]' },
        { descriptor => '1000>', text => '=#,##0=' },
    ], 'rules of the public rule set' );
    is( $priv->{name}, '%%private', 'the @noparse suffix is removed from the name' );
    is( $priv->{private}, 1, 'private' );
    is( $priv->{parseable}, 0, 'not parseable' );
    is_deeply( $priv->{rules}, [ { descriptor => '0', text => "' leading space" }, { descriptor => '1', text => '' } ], 'the apostrophe and an empty text are kept' );
    {
        # The expected error is also reported as a warning, which is not shown.
        local $SIG{__WARN__} = sub{};
        ok( !defined( Locale::Unicode::RBNF->rule_sets_from_description( '' ) ), 'empty description' );
    }
};

# NOTE: rbnf_groupings, current format
subtest 'rbnf_groupings, current format' => sub
{
    my $st;
    my $cldr = Locale::Unicode::RBNF::CLDR->new( File::Spec->catdir( 't', 'cldr' ), \$st );
    ok( !$st, 'CLDR object' ) || diag( $st );
    my $groupings = $cldr->rbnf_groupings( 'ja' );
    is_deeply( [ map( $_->{grouping}, @$groupings ) ], [ 'SpelloutRules', 'OrdinalRules' ], 'groupings in document order' );
    my( $fin ) = grep( $_->{type} eq 'spellout-cardinal-financial', @{$groupings->[0]->{rule_sets}} );
    ok( $fin, 'rule set found' );
    my( $three ) = grep( $_->{descriptor} eq '3', @{$fin->{rules}} );
    is( $three->{text}, "\x{53C2}", 'rule text' );
    # The divided rules, put back together, must give the same rules once compiled.
    my $doc = $cldr->_rbnf_doc( 'fr' );
    foreach my $g ( @{$cldr->rbnf_groupings( $doc )} )
    {
        my $rebuilt = join( "\n", map{ my $s = $_; ( $s->{name} . ( $s->{parseable} ? '' : '@noparse' ) . ':' ), map( "$_->{descriptor}: $_->{text};", @{$s->{rules}} ) } @{$g->{rule_sets}} );
        my( $orig ) = $cldr->rbnf_rules( 'fr', $g->{grouping} );
        my $a = Locale::Unicode::RBNF->new( locale => 'fr', cldr => File::Spec->catdir( 't', 'cldr' ), rules => $orig );
        my $b = Locale::Unicode::RBNF->new( locale => 'fr', cldr => File::Spec->catdir( 't', 'cldr' ), rules => $rebuilt );
        ok( $a && $b, "fr $g->{grouping} compiles both ways" );
        is( $b->rules, $a->rules, "fr $g->{grouping} rebuilt identically" );
    }
};

# NOTE: rbnf_groupings, legacy format
subtest 'rbnf_groupings, legacy format' => sub
{
    my $st;
    my $cldr = Locale::Unicode::RBNF::CLDR->new( File::Spec->catdir( 't', 'legacy' ), \$st );
    my $groupings = $cldr->rbnf_groupings( 'xx' );
    is( scalar( @$groupings ), 1, 'one grouping' );
    my @sets = @{$groupings->[0]->{rule_sets}};
    is_deeply( [ map( $_->{name}, @sets ) ], [ '%spellout-numbering', '%%teen' ], 'access attribute' );
    my( $radix ) = grep( $_->{descriptor} eq '1100/100', @{$sets[0]->{rules}} );
    ok( $radix, 'radix attribute folded into the descriptor' );
    is( $radix->{text}, '<%%teen< hundred[ >>]', 'arrows converted' );
};

done_testing();

__END__
