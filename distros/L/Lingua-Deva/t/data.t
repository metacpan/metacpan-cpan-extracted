use v5.12.1;
use strict;
use warnings;
use utf8;

use Test::More tests => 10;

BEGIN { use_ok('Lingua::Deva') };

my $d = Lingua::Deva->new();

# Random Sanskrit words with a few invalid characters
my @lines = split /\n/, <<'EOF';
sabhā saṃnikṛṣṭau kumārāḥ tu Ca rājñas kṛṣṇena Paśyema te ubhau |
sarve Rūpeṇa dīrghavairī etaz avṛttir adhaḥ śūro 'kḷptaḥ jñātibhedam |
tṛṇāni bhūmir dṛṣṭvā na brāhmaṇaṃ manyante satāṃ tasyāvṛttibhayaṃ mā
raudreṇa tathā duṣputraiḥ brūyā uvāca Ṛṣīṇām dharmam gṛhṇīte |
Iva bālyāt sarvataḥ Dāne apradhṛṣyaṃ qaf siṃhagrīvo tadā yāhi
EOF

my @dlines = split /\n/, <<'EOF';
सभा संनिकृष्टौ कुमाराः तु च राज्ञस् कृष्णेन पश्येम ते उभौ |
सर्वे रूपेण दीर्घवैरी एतz अवृत्तिर् अधः शूरो ऽकॢप्तः ज्ञातिभेदम् |
तृणानि भूमिर् दृष्ट्वा न ब्राह्मणं मन्यन्ते सतां तस्यावृत्तिभयं मा
रौद्रेण तथा दुष्पुत्रैः ब्रूया उवाच ऋषीणाम् धर्मम् गृह्णीते |
इव बाल्यात् सर्वतः दाने अप्रधृष्यं qअf सिंहग्रीवो तदा याहि
EOF

# Use a larger dataset
my (@large, @dlarge);
push @large, @lines for (1..1000);
push @dlarge, @dlines for (1..1000);

# Returns elapsed time
sub secs {
    my ($start, $end) = @_;
    return sprintf("(%.2f seconds)", $end-$start);
}

my $start = times();
for (@large) { my $tokens = $d->l_to_tokens($_) }
my $end = times();
ok( 1, 'tokenize ' . @large . ' lines ' . secs($start, $end) );

$start = times();
for (@large) { my $aksaras = $d->l_to_aksaras($_) }
$end = times();
ok( 1, 'aksarize ' . @large . ' lines ' . secs($start, $end) );

$start = times();
for (@dlarge) { my $aksaras = $d->d_to_aksaras($_) }
$end = times();
ok( 1, 'aksarize ' . @dlarge . ' lines in Devanagari ' . secs($start, $end) );

my @aksaras;
$start = times();
for (@large) { push @aksaras, @{ $d->l_to_aksaras($_) } }
$end = times();
ok( 1, 'create array of ' . @aksaras . ' aksaras ' . secs($start, $end) );

$start = times();
my @real_aksaras = grep { ref($_) eq 'Lingua::Deva::Aksara' } @aksaras;
$end = times();
my $percent = int (@real_aksaras / @aksaras * 100);
ok( 1, 'grep ' . @real_aksaras . ' (' . $percent .
       '%) actual aksaras in array ' . secs($start, $end) );

$start = times();
for (@real_aksaras) { my $valid = $_->is_valid() };
$end = times();
ok( 1, 'check validity of ' . @real_aksaras . ' aksaras ' .
       secs($start, $end) );

$start = times();
my @onsets = map { defined $_->onset()
                   ? scalar @{ $_->onset() }
                   : 0
                 } @real_aksaras;
$end = times();
my %onsets;
$onsets{$_}++ for (@onsets);
$end = times();
ok( 1, 'calculate onset length frequencies ' . secs($start, $end) );

my %rhymes;
$start = times();
for my $r (grep { defined $_->get_rhyme() } @real_aksaras) {
    $rhymes{ join '', @{$r->get_rhyme()} }++;
}
$end = times();
ok( 1, 'calculate rhyme frequencies ' . secs($start, $end) );

{
    # Catch and count carp warnings emitted in strict mode
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    $d = Lingua::Deva->new( strict => 1, allow => ['|'] );
    $start = times();
    for (@large) { my $aksaras = $d->l_to_aksaras($_) }
    $end = times();
    is( $warnings, 3000, 'aksarize ' . @large .
        ' lines in strict mode, warnings caught ' . secs($start, $end) );
}
