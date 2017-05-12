use Test::More;
#use Test::More tests => 22;
use Lingua::TypoGenerator 'typos';

my @files = glob "t/*.txt"; 

plan tests => scalar @files;
for my $file (@files) {
    open F, "<$file" or die "couldn't open $file: $!\n";
    my @expected = <F>;
    chomp for @expected;
    $accents = shift @expected;
    my ($word) = $file =~ /(\w+)\.txt/;
    my @got = typos($word, accents => $accents);
    is_deeply(\@got, \@expected, "$word");
}
