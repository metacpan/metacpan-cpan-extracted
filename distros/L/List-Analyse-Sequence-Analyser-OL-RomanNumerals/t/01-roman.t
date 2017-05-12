#!perl -T

use List::Analyse::Sequence;
use Test::More 'no_plan';

{
    my @ul = qw( foo bar baz whiz );

    my $seq = List::Analyse::Sequence->new;
    $seq->use_these_analysers(qw( List::Analyse::Sequence::Analyser::OL::RomanNumerals ));
    $seq->analyse( @ul );
    my ($result, $discard) = $seq->result;

    ok( !exists $result->[0], "No result" );
    ok( exists $discard->[0], "Discard" );
    isa_ok( $discard->[0], "List::Analyse::Sequence::Analyser::OL::RomanNumerals" );
}

{
    my @ol = ( "i. foo", "ii. bar", "iii. baz", "iv. whiz" );

    my $seq = List::Analyse::Sequence->new;
    $seq->use_these_analysers(qw( List::Analyse::Sequence::Analyser::OL::RomanNumerals ));
    $seq->analyse( @ol );
    my ($result, $discard) = $seq->result;

    ok( !exists $discard->[0], "Result" );
    ok( exists $result->[0], "no discard" );
    isa_ok( $result->[0], "List::Analyse::Sequence::Analyser::OL::RomanNumerals" );
}

{
    my @ol = ( "Zoot: i. foo", "Zoot: ii. bar", "Zoot: iii. baz", "Zoot: iv. whiz" );

    my $seq = List::Analyse::Sequence->new;
    $seq->use_these_analysers(qw( List::Analyse::Sequence::Analyser::OL::RomanNumerals ));
    $seq->analyse( @ol );
    my ($result, $discard) = $seq->result;

    ok( !exists $discard->[0], "Result" );
    ok( exists $result->[0], "no discard" );
    isa_ok( $result->[0], "List::Analyse::Sequence::Analyser::OL::RomanNumerals" );
    is( $result->[0]->prefix, "Zoot: ", "Correct prefix" );
}
