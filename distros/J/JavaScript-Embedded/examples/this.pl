use strict;
use warnings;
use lib './lib';
use JavaScript::Embedded;
use Data::Dumper;

my $js = JavaScript::Embedded->new();
my $duk = $js->duk;

$js->eval(q{
    function Person (fname, lname) {
        this.firstName = fname;
        this.lastName  = lname;
        this.getName   = getName;
    }
});

$js->set('getName', sub {
    return this->firstName . ' ' . this->lastName;
});


my $person = $js->get_object('Person');

my $me = $person->new('Joe', 'Me');

print $me->getName(_), "\n";
