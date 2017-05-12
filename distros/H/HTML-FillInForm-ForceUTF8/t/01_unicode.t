use strict;
use Test::More;

use HTML::FillInForm::ForceUTF8;

my $fif = HTML::FillInForm::ForceUTF8->new;

ok($fif);

my $fdat;
$fdat->{foo} = "\x{306a}\x{304c}\x{306e}"; #Unicode flagged
$fdat->{bar} = "\xe3\x81\xaa\xe3\x81\x8c\xe3\x81\xae"; # UTF8 bytes

{
    my $output = $fif->fill(
        scalarref => \'<input type="text" name="foo" />',
        fdat      => $fdat
    );
    like $output, qr/$fdat->{foo}/;
}

{
    my $output = $fif->fill(
        scalarref => \'<input type="text" name="bar" />',
        fdat      => $fdat
    );
    like $output, qr/$fdat->{foo}/;
}

done_testing();

