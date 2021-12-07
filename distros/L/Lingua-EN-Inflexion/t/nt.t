use warnings;


use Test::More;

use Lingua::EN::Inflexion;

my %seen_plur;
my %seen_pret;

for my $inflexion (readline *DATA) {
    next if $inflexion =~ m{\A \s* \# }xms;
    my ($sing, $plur, $pret) = $inflexion =~ m{\A \s* (\S+) \s* (\S+) \s* (\S+)}xms;

    if (!$seen_plur{$plur}) {
        is verb($sing)->plural,   $plur,  "$sing --> $plur";
        is verb($plur)->singular, $sing,  "$sing <-- $plur";
    }

    if ($pret ne '_') {
        is verb($sing)->past, $pret,  "$sing (s) --> $pret";
        if (!$seen_plur{$plur}) {
            is verb($plur)->past, $pret,  "$plur (p) --> $pret";
        }
    }

    $seen_plur{$plur}++;
    $seen_pret{$pret}++;
}


done_testing();

__DATA__
    isn't              aren't            wasn't
#    aren't             aren't            weren't
    can't              can't             couldn't
    daren't            daren't           _
    doesn't            don't             didn't
    don't              don't             didn't
    hasn't             haven't           hadn't
    haven't            haven't           hadn't
    mayn't             mayn't            mightn't
    mustn't            mustn't           _
    needn't            needn't           _
    oughtn't           oughtn't          _
    sha'n't            sha'n't           shouldn't
    shan't             shan't            shouldn't
    won't              won't             wouldn't
