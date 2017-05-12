#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    use Test::More tests => 12; #'no_plan';
    use_ok 'Lingua::TokenParse';
};

my $p = Lingua::TokenParse->new(
#    verbose => 1,
);
isa_ok $p, 'Lingua::TokenParse', 'With no arguments';

is scalar( @{ $p->parts } ), 0, 'no parts';
is scalar( @{ $p->combinations } ), 0, 'no combinations';
is scalar( keys %{ $p->knowns } ), 0, 'no knowns';
is scalar( keys %{ $p->definitions } ), 0, 'no definitions';

my %lexicon;
@lexicon{qw(part i tion on)} = qw(a b c d);

$p = Lingua::TokenParse->new(
#    verbose => 1,
    word => 'partition',
    lexicon => \%lexicon,
    score => 0,
);
isa_ok $p, 'Lingua::TokenParse', 'With arguments';

# Parse again but with a constraint.
my $rule = qr/\.on$/;
$p->constraints( [ $rule ] );
$p->parse;
ok not (grep { /$rule/ } @{ $p->combinations }),
    'constrained combinations';
ok not (grep { /$rule/ } keys %{ $p->knowns }),
    'constrained knowns';

my $lexicon = 'eg/lexicon.db';
$p->lexicon_cache( lexicon_file => $lexicon );
ok -e $lexicon, 'lexicon stored';
$p->lexicon( {} );
is scalar( keys %{ $p->lexicon } ), 0, 'lexicon cleared';
$p->lexicon_cache( $lexicon );
ok scalar( keys %{ $p->lexicon } ) > 0, 'lexicon retrieved';
