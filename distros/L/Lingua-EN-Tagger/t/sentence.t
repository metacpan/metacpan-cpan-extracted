# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 10;
use Lingua::EN::Tagger;

ok('Lingua::EN::Tagger', 'module compiled'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$p = new Lingua::EN::Tagger;

@phrases = (    "Andrew W. Mellon Foundation", 
                "Spring Clearance at J.C. Penny",
                "Prof. Paul Nelson",
                "Apr. 12, 1953",
                "On Dec. 24, 1994",
                "The mtn. road"
        );

$i=0;
foreach( @phrases ){
        $s = join ' ', $p->_split_sentences( &prepare( $_ ) );
        is( $s, $_, "sentence ender $i");
        $i++;
}


$text = "A line of Chinese-made cars began rolling onto a ship here Friday, bound for Europe. The cars, made at a gleaming new Honda factory on the outskirts of this sprawling city near Hong Kong, signal the latest move by China to follow Japan and South Korea in building itself into a global competitor in one of the cornerstones of the industrial economy. China's debut as an auto exporter, small as it may be for now, foretells a broader challenge to a half-century of American economic and political ascendance. The nation's manufacturing companies are building wealth at a remarkable rate, using some of that money to buy assets abroad. And China has been scouring the world to acquire energy resources, with the bid to buy an American oil company only the latest overture. St. (Cecilia) was a musical saint. She had her head cut off. 3.14 is the value of pi.";

ok( $sentences = $p->get_sentences( $text ) );
is( scalar @$sentences, 8 );
my $reunited = join( ' ', @$sentences );
is( $reunited, $text );



sub prepare {
        ( $sentence ) = @_;
        @s = split /\s+/, $sentence;
        return \@s;
}
