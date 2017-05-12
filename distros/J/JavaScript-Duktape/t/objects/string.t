use lib './lib';
use strict;
use warnings;
use Data::Dumper;
use JavaScript::Duktape;
use Test::More;

my $js = JavaScript::Duktape->new;
my $duk = $js->duk;
my $ret = $duk->eval_string( q{
    String;
});

my $string = $duk->to_perl_object(-1);
$duk->pop();

my $str = $string->new("Hi there");
my $str2 = $str->slice(0, 2);
is $str2, 'Hi';

is $str->charAt(10000), '';
is $str->charAt(0), 'H';

is $str->toUpperCase(_), 'HI THERE';
is $str->slice(3, $str->length), 'there';



is $string->new('Blue Whale')->indexOf('Blue'), 0;     #// returns  0
is $string->new('Blue Whale')->indexOf('Blute'), -1;   #// returns -1
is $string->new('Blue Whale')->indexOf('Whale', 0), 5; #// returns  5
is $string->new('Blue Whale')->indexOf('Whale', 5), 5; #// returns  5
is $string->new('Blue Whale')->indexOf('', 9), 9;      #// returns  9
is $string->new('Blue Whale')->indexOf('', 10), 10;    #// returns 10
is $string->new('Blue Whale')->indexOf('', 11), 10;    #// returns 10


{
    my $str = $string->new('To be, or not to be, that is the question.');
    my $count = 0;
    my $pos = $str->indexOf('e');

    while ($pos != -1) {
      $count++;
      $pos = $str->indexOf('e', $pos + 1);
    }
    is $count, 4; #// displays 4
    is $str->concat->(' EOF'), 'To be, or not to be, that is the question. EOF';
}


my $orig = $string->new('   foo  ');
is $orig->trim(_), 'foo'; #// 'foo'

is $duk->get_top(), 0;

done_testing(16);
