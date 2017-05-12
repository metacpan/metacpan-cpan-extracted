
use Test::More tests => 11;
use Freq;

my $index = Freq->open_read( 'testindex' );

my $result = $index->fancy_search('way [we blabla]');
is_deeply( $result, 
           { 'test_doc_2' => [ "27-28" ] },
           'valid + invalid words within alternation');

$result = $index->fancy_search('way [hoohoo blabla]');
is_deeply( $result, 
           {},
           'invalid alternation');

$result = $index->fancy_search('the [only idiots] way');
is_deeply( $result, 
           { test_doc_2 => [ "25-27" ] },
           'valid nonmatching word plus matching word within alternation');

$result = $index->fancy_search('the [idiots way] blabla');
is_deeply( $result, 
           {},
           'invalid word in top sequence');

$result = $index->fancy_search('the #w6 ever');
is_deeply( $result, 
           { test_doc_2 => [ "25-30" ] },
           'true #w search');

$result = $index->fancy_search('the #w2 ever');
is_deeply( $result, 
           {},
           'false #w search');

$result = $index->fancy_search('the #t5 ever');
is_deeply( $result, 
           { test_doc_2 => [ "25-30" ] },
           'true #t search');

$result = $index->fancy_search('the #t4 ever');
is_deeply( $result, 
           {},
           'false #t search (too short)');

$result = $index->fancy_search('the #t6 ever');
is_deeply( $result, 
           {},
           'false #t search (too long)');

$index->close_index();



# some extras 

$index = Freq->open_read("od01");
$result = $index->fancy_search('he gave his daughters');
is_deeply( $result, 
           { './t/data/book10' => [ "160-163" ] },
           'straight sequence');

$result = $index->fancy_search('he [<handed his> <gave his>] daughters');
is_deeply( $result, 
           { './t/data/book10' => [ "160-163" ] },
           'alternation of sequences');


$index->close_index();

exit 0;

