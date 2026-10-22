#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Tags ();
use EO::TagsX ();
use EO::Twin qw(imp imp_w twin_is fresh);

no strict 'refs';
$EO::Twin::BASE = 'EO::Tags';

{
    my $p = fresh();
    is( imp('EO::Tags', $p, '/^is_/'), undef, 'a pattern' );
    ok( defined &{"${p}::is_x"} && defined &{"${p}::is_y"}, '... imports every match' );
    ok( !defined &{"${p}::a1"}, '... and nothing else' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, '/a/'), undef, 'a pattern is not anchored' );
    ok( defined &{"${p}::a1"} && defined ${"${p}::sa"} && \@{"${p}::arr"} == \@EO::Tags::arr,
        '... and matches sigils too' );
}

{
    my $p = fresh();
    my ($err, $warn) = imp_w('EO::Tags', $p, '/s/');
    like( $err, qr/^Can't continue after import errors/, 'a pattern reaching @EXPORT_FAIL goes through export_fail' );
    like( $warn->[0], qr/^"risky" is not implemented/, '... which rejects risky' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, '!/^_/'), undef, 'a negated pattern first' );
    ok( defined &{"${p}::a1"} && !defined &{"${p}::_priv"}, '... is :DEFAULT less the matches' );
}

{
    my $p = fresh();
    my $err = imp('EO::Tags', $p, '/(/');
    like( $err, qr/^Unmatched \( in regex/, 'a bad pattern croaks with the regex message' );
}

{
    package EO::Latin;
    use Ex::Op;
    our @EXPORT_OK = ("\$\xe9", '$plain');
    no strict 'refs';
    ${"EO::Latin::\xe9"} = 'e';
    our $plain = 'p';
}
SKIP: {
    skip 'unicode_strings needs perl 5.12', 2 if $] < 5.012;
    my $ok = eval q{
        package EO::PatHints;
        use feature 'unicode_strings';
        BEGIN { EO::Latin->import('/^\$\w+$/') }
        1;
    };
    ok( $ok, 'a pattern under the caller\'s unicode_strings' ) or diag $@;
    ok( !exists $EO::PatHints::{"\xe9"} && exists $EO::PatHints::{plain},
        '... keeps Exporter\'s rules: \w does not match a Latin-1 letter' );
}

for my $mod (qw(EO::Tags EO::TagsX)) {
    our $ran = 0;
    my $ok = eval qq{
        package EO::ReEval;
        use re 'eval';
        BEGIN { $mod->import(q{/(?{ \$main::ran = 1 })/}) }
        1;
    };
    ok( !$ok && !$main::ran, "$mod: the caller's use re 'eval' does not reach a pattern" );
    like( $@, qr/^Eval-group not allowed at runtime/, "$mod: ... it dies as a run-time pattern" );
}

twin_is( 'a pattern',              '/^is_/' );
twin_is( 'an unanchored pattern',  '/s/' );
twin_is( 'a negated pattern',      '!/^_/' );
twin_is( 'a pattern less a name',  '/^is_/', '!is_y' );
twin_is( 'a pattern on sigils',    '/^[\$\@%]/' );
twin_is( 'a pattern matching none', '/^zzz/' );
twin_is( 'a bad pattern',          '/(/' );
twin_is( 'a lone slash',           '/' );
twin_is( 'a tag and a pattern',    ':both', '/^b/' );

done_testing;
