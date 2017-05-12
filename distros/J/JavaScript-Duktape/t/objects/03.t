#object properities

use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

{#array forEach
    {
        $js->set('arr', [0,1,2,3]);
        my $arr = $js->get_object('arr');

        my $total = 0;
        $arr->forEach(sub {
            my ($value, $index, $ar) = @_;
            is $value, $index;
            $total += $value;
        });

        is $total, 6;
    }

    {
        $js->set('arr', [1,2,3,4]);
        my $arr = $js->get_object('arr');

        my $total = 0;
        $arr->forEach(sub {
            my ($value, $index, $ar) = @_;
            is (($value-1), $index);
            $total += $value;
        });

        is $total, 10;
    }
}

{ #sort
    $js->eval(qq~
        var things2 = ['word', 'Word', '1 Word', '2 Words'];
        things2.sort(); // ['1 Word', '2 Words', 'Word', 'word']

    ~);
    $js->set('things', ['word', 'Word', '1 Word', '2 Words']);
    my $things = $js->get_object('things');
    is_deeply ( $things->sort(_), ['1 Word', '2 Words', 'Word', 'word'] );

    $js->set('numbers', [4, 2, 5, 1, 3]);
    my $numbers = $js->get_object('numbers');

    $numbers->sort(sub {
        my ($a, $b) = @_;
        return $a - $b;
    });
    is_deeply $numbers, [1, 2, 3, 4, 5];
}

{ #sort utf8 using localeCompare function
    use utf8;
    $js->set('items', ['réservé', 'premier', 'cliché', 'communiqué', 'café', 'adieu']);

    my $items = $js->get_object('items');

    $items->sort(sub{
        my $a = $duk->to_perl_object(0);
        my $b = $duk->to_perl_object(1);
        return $a->localeCompare($b);
    });

    is_deeply $items, ['adieu', 'café', 'cliché', 'communiqué', 'premier', 'réservé'];
}


done_testing(13);
