#Courtesy of chromatic
#http://search.cpan.org/~chromatic/Test-Kwalitee/lib/Test/Kwalitee.pm

# in a separate test file
use Test::More;

eval
{
    require Test::Kwalitee;
        Test::Kwalitee->import();
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

