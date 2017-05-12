use String::Koremutake;
my $k = String::Koremutake->new;

my $s = $k->integer_to_koremutake(65535);        # botretre
my $i = $k->koremutake_to_integer('koremutake'); # 10610353957
