use strict;
use warnings;
use lib './lib';
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

## in this example we will set an array and

# set a global numbers array to javascript
$js->set('numbers', [1, 2, 3, 4, 5]);

# check if it's really set in JavaScript
$js->eval(q{
    print(numbers[0]); // => 1
    print(numbers[4]); // => 5
});


my $numbers = $js->get_object('numbers');

# now $numbers is an object of javascript Array

# we can shift
$numbers->shift(_); #=> [1,2,3,4]

# we can pop
$numbers->pop(_); # => [2,3,4]

# and we can run any Array.prototype method
# 0 => 2
# 1 => 3
# 2 => 4
$numbers->forEach(sub {
    my ($value, $index, $ar) = @_;
    print $index, " => ", $value, "\n";
});

print "We ar now reversed \n";

my $reversed = $numbers->reverse(_);

# 0 => 4
# 1 => 3
# 2 => 2
$reversed->forEach(sub {
    my ($value, $index, $ar) = @_;
    print $index, " => ", $value, "\n";
});
