use Test::More no_plan;
use Data::Dumper;  # for debugging only

# BEGIN { use_ok('Lingua::Alphabet::Phonetic') };
BEGIN { use_ok('Lingua::Alphabet::Phonetic::StarWars') };

my $oSpeaker = new Lingua::Alphabet::Phonetic('StarWars');
# diag(Dumper($oSpeaker));
isa_ok($oSpeaker, 'Lingua::Alphabet::Phonetic::StarWars');

# These should not cause any errors:
my @a = $oSpeaker->enunciate(undef);
is_deeply(\@a, []);
@a = $oSpeaker->enunciate('');
is_deeply(\@a, []);
# diag(Dumper(\@a));
@a = $oSpeaker->enunciate('m');
is_deeply(\@a, ['Mothma']);

my @asSpeak = $oSpeaker->enunciate('Just another Perl hacker!');
# diag(Dumper(\@asSpeak));
# is(5, scalar(@asSpeak));
my @asExpected = qw( Jedi Ugnaught Skywalker Tyranus Ackbar Needa Organa Tyranus Hutt Evazan Ree-Yees Palpatine Evazan Ree-Yees Leia Hutt Ackbar Chewbacca Kenobi Evazan Ree-Yees );
is_deeply(\@asExpected, \@asSpeak);

__END__

