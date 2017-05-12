use strict;
use warnings;
use lib './lib';
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->eval(q{
    function test () {
        return 'Hi';
    }

    print(test); // function(){ ... }
    print(test()) // Hi
});

## same thing when we do it in perl
my $test = $js->get_object('test');

print $test, "\n"; #
print $test->(), "\n";

$js->eval(q{
    function Person (name){
        this.name = name;
    }

    Person.prototype.getName = function(){
        return this.name;
    };

    var me = new Person('Joe');
    print(me.getName); // function(){ ... }
    print(me.getName()); // Joe
});

# Now let's do it in perl
my $Person = $js->get_object('Person');
my $me = $Person->new('Joe');

print $me->getName, "\n"; #JavaScript::Duktape::Function=CODE(...)
print $me->getName(), "\n"; #still JavaScript::Duktape::Function=CODE(...)

# call the function
print $me->getName(_), "\n";

# or
print $me->getName->(), "\n";
