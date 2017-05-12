
use lib 'lib';
use strict;
use Test::More;
use Kwiki::Purple::Sequence;

plan tests => 49;

chdir('t');

make_directory();

my $sequence = Kwiki::Purple::Sequence->new;
is($sequence->plugin_directory, './plugin/purple_sequence',
    'correct plugin_directory');


# does the sequence sequence
{
    for my $goal qw(1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P
                    Q R S T U V W X Y Z 10 11 12 13 14 15 16 17 18 19 1A) {
        my $nid = $sequence->get_next_and_update('foo');
        is($nid, $goal, "got $nid when expecting $goal");
    }
}

destroy_directory();
make_directory();

# does the index index
{
    my $url = 'http://www.example.com/foo';
    my $nid = $sequence->get_next_and_update($url);
    is($sequence->query_index($nid), $url, "$nid retrieves $url");

    for (1 .. 10) {
        $nid = $sequence->get_next_and_update($url . $_);
    }
    is($sequence->query_index($nid), $url . 10, "$nid retrieves ${url}10");
}

# does the index do permissions handling?
#{
#}

destroy_directory();

sub make_directory {
    mkdir('plugin');
    mkdir('plugin/purple_sequence');
}

sub destroy_directory {
    io('plugin')->rmtree;
}
