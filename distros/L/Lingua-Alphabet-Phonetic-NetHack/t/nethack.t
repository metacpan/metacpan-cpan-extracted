use Test::More no_plan;
use Data::Dumper;  # for debugging only

BEGIN { use_ok('Lingua::Alphabet::Phonetic') };
BEGIN { use_ok('Lingua::Alphabet::Phonetic::NetHack') };

my $oSpeaker = new Lingua::Alphabet::Phonetic('NetHack');
# diag(Dumper($oSpeaker));
isa_ok($oSpeaker, 'Lingua::Alphabet::Phonetic::NetHack');

# These should not cause any errors:
my @a = $oSpeaker->enunciate(undef);
is_deeply(\@a, []);
@a = $oSpeaker->enunciate('');
is_deeply(\@a, []);
# diag(Dumper(\@a));
@a = $oSpeaker->enunciate(' ');
is_deeply(\@a, ['ghost']);

my @asSpeak = $oSpeaker->enunciate('Just another Perl hacker!');
# diag(Dumper(\@asSpeak));
# is(5, scalar(@asSpeak));
my @asExpected = qw( jabberwock unicorn spider trapper ghost ant nymph orc trapper humanoid eye rodent ghost pudding eye rodent leprechaun ghost humanoid ant cockatrice kobold eye rodent potion );
is_deeply(\@asExpected, \@asSpeak);

__END__

