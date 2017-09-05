use Test::More tests => 8;

require_ok('MEME::Alphabet');

# Test 2: DNA
my $obj = new MEME::Alphabet;

my $alph = $obj->dna();

ok($alph->is_dna());

# Test 3/4: DNA value in context

# 3: list

SKIP: {
    eval { require Array::Compare };

    skip "Array::Compare- not installed", 2 if $@;

    use Array::Compare;

    my $comp = Array::Compare->new;

    my @expected_result = ('A', 'C', 'G', 'T');

    my @result = ($alph->get_core());

    ok($comp->compare(\@result, \@expected_result));
}

# 4: scalar

my $expected_result = qr/ACGT|ACTG|AGCT|AGTC|ATCG|ATGC|CATG|CAGT|CGTA|CGAT|CTGA|CTAG|GACT|GATC|GCAT|GCTA|GTAC|GTCA|TAGC|TACG|TCGA|TCAG|TGCA|TGAC/;

like($alph->get_core(), $expected_result);

# Test 5: modDNA

$alph = $obj->moddna();

ok($alph->is_moddna());

# Test 6: like DNA

ok($alph->{like} eq 'DNA');

# Test 7: modDNA reverse complement

is($alph->rc_seq('Cmhfc'), '4321G');

# Test 8: Weblogo 3 colour parameter (check C, m, and 1)

like($alph->get_Weblogo_colour_args(), qr/--color #A50026 C Cytosine.*--color #D73027 m.*--color #4575B4 1/);

