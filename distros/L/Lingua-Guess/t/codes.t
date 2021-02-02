use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use Lingua::Guess;

my $carol = <<EOF;
Good King Wences'las looked out,
on the Feast of Stephen,
When the snow lay round about,
deep and crisp and even;
Brightly shone the moon that night,
tho' the frost was cruel,
When a poor man came in sight,
gath'ring winter fuel.
EOF

my $lg = Lingua::Guess->new ();
my $guesses = $lg->guess ($carol);
for my $guess (@$guesses) {
    if ($guess->{name} eq 'english') {
	ok ($guess->{code2} eq 'en', "Got 2-letter language code for English");
	ok ($guess->{code3} eq 'eng', "Got 3-letter language code for English");
    }
}

done_testing ();
