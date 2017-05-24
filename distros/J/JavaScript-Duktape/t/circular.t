use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;
use Data::Dumper;

my $js   = JavaScript::Duktape->new();
my $duk  = $js->duk;
my $self = $duk;

$duk->eval_string(q{
    function Foo() {
        var self = this;
        this.abc = "Hello";
        this.circular = this;
        this.test = {
            hi : this,
            bye : self
        };
    }

    var foo = new Foo();
    foo;
});

my $t = $duk->to_perl(-1);
is $t->{test}->{hi}->{abc}, 'Hello';
is $t->{circular}->{abc}, 'Hello';
done_testing(2);
