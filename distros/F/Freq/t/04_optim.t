

use Test::More tests => 2;
use Freq;

my $testdoc0 = '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20';

my $testdoc1 = ' _3_ _2_ _9_ _3_ _6_ _2_ december _3_ _1_ _1_ _9_ _9_ _0_ monday home edition metro part b page _4_ column _4_ letters desk _2_ _3_ _9_ words vietnam ready for business in response to articles on vietnam seeking to rejoin the international economy front page dec _2_ _3_ _2_ _4_ your article getting back to business in vietnam was an excellent coverage for business purposes it did not however address the reason for the trade embargo with the welfare of the vietnamese people in mind due to loss of life suffered by the boat people who did not make it in addition to the cost of hard cash that the united states and other benevolent nations are contributing to care for those who made it no profit from any business could be justified as long as vietnam is still dotted with concentration camps and the people still risk their lives trying to escape at a time when communism is collapsing or already collapsed in many countries the vietnamese people would be betrayed by any attempt to shore up the shaky communist regime in hanoi there is enough proof as unveiled recently that socialism marxist style does not benefit the people but just a small group of party members practicing totalitarian dictatorship the american ideal of freedom and pursuit of happiness should not be further strained by greed and the chase for a fast buck there is plenty of business in the united states for the taker a few more years of patient pressure will result in a vietnam with freedom and democracy where people will take a boat out for fishing and not for escaping';

my $testdoc2 = 'december _3_ _1_ _1_ _9_ _9_ _0_ monday home edition metro part b page _4_ column _3_ letters desk _3_ _3_ words tagger arrest the only way we are ever going to end the nasty filthy graffiti problem is to come down hard on the idiots doing it i would be happy to contribute to a reward fund irv bush marina del rey letter to the editor';


my $index = Freq->open_write( 'idxA' );
$index->index_document( 'test_doc_0', $testdoc0 );
$index->index_document( 'test_doc_1', $testdoc1 );
$index->index_document( 'test_doc_2', $testdoc2 );
my $the_full = $index->{isrs}->{'the'};
$index->close_index();

$index = Freq->open_write( 'idxB' );
$index->index_document( 'test_doc_0', $testdoc0 );
$index->index_document( 'test_doc_1', $testdoc1 );
my $the_01 = $index->{isrs}->{'the'};
$index->close_index();

$index = Freq->open_write( 'idxB' );
$index->index_document( 'test_doc_2', $testdoc2 );
my $the_2 = $index->{isrs}->{'the'};
$index->close_index();

is_deeply($the_full, 
          Freq::_append_isr($the_01, 3, $the_2), 
		  'append succeeded');



# index the Odyssey

system("rm -rf idx* od01 od0-1");

my @od0_files = glob("./t/data/book0*");
my @od1_files = glob("./t/data/book1*");
my $od0_1_index = Freq->open_write('od0-1');
for my $filename (@od0_files){
    open FILE, "<$filename" or die $!;
    my $text = join '', <FILE>;
    close FILE;
    $od0_1_index->index_document($filename, join(' ', Freq::tokenize_std($text)));
}
$od0_1_index->close_index();

$od0_1_index = Freq->open_write('od0-1');
for my $filename (@od1_files){
    open FILE, "<$filename" or die $!;
    my $text = join '', <FILE>;
    close FILE;
    $od0_1_index->index_document($filename, join(' ', Freq::tokenize_std($text)));
}
$od0_1_index->close_index();

my $od01_index = Freq->open_write('od01');
for my $filename (@od0_files, @od1_files){
    open FILE, "<$filename" or die $!;
    my $text = join '', <FILE>;
    close FILE;
    $od01_index->index_document($filename, 
                                join(' ', 
                                     Freq::tokenize_std($text)));
}
$od01_index->close_index();

# compact od0-1
Freq::optimize_index('od0-1');


$index = Freq->open_read( 'od01' );
my $gods01 = Freq::_read_isr($index->{cdb}, 'gods');
$index->close_index();

$index = Freq->open_read( 'od0-1' );
my $gods0_1 = Freq::_read_isr($index->{cdb}, 'gods');
$index->close_index();

is_deeply($gods01, $gods0_1, 'odyssey isr compaction correct');


exit 0;

