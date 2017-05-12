use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
require './t/helper.pl';
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

my @refs;

$js->set( print => sub {
    my $str = shift;
    print $str || "undefined", "\n";
});


$duk->eval_string(qq~
    var tt = {};
    tt.all = test;
    function test (fn){
        this.name = 'Mamod';
        this.lastname = "Foo";
        this.fn   = fn;
    }

    test.prototype.setLast = function(fn){
        this.lastname = fn;
        this.fullname = this.name + fn('Mehyar');
    }

    var obj = new test();
    print(obj.name);
    obj.setLast(function(last){
        print(this.name);
        return last;
    });
    print(obj.lastname('Mehyar2'));
    print(obj.fullname);
    test;
~);

my $obj = $duk->to_perl_object(-1);
$duk->pop();

sub test {
    my $this = this;
    my $last = shift;

    ##first call expect global object
    ##so it must return undef
    print Dumper $this->name;
    return $last;
}

{ #normal
    my $tr = $_;
    my $t = $obj->new();
    print Dumper $t->name;
    # $t->setLast->($duk->cache(\&test));
    $t->setLast(  \&test );

    print Dumper $t->lastname('Mehyar2');
    print Dumper $t->fullname;
}

test_stdout();

__DATA__
Mamod
undefined
Mamod
Mehyar2
MamodMehyar
$VAR1 = 'Mamod';
$VAR1 = undef;
$VAR1 = 'Mamod';
$VAR1 = 'Mehyar2';
$VAR1 = 'MamodMehyar';
