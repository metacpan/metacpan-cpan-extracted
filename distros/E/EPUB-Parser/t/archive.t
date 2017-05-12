use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });

subtest 'EPUB::Parser::Util::Archive::get_member_data' => sub {
    my $data = $ep->{zip}->get_member_data({ file_path => 'OEBPS/style.css' });
    ok($data);
};


my $it;
subtest 'EPUB::Parser::Util::Archive::get_member_data' => sub {
    $it = $ep->{zip}->get_members({ files_path => [qw{OEBPS/style.css OEBPS/cover.png}] });
    is(ref $it, 'EPUB::Parser::Util::Archive::Iterator', 'class name');
};

subtest 'EPUB::Parser::Util::Archive::size' => sub {
    is($it->size, 2, 'size');
};

subtest 'EPUB::Parser::Util::Archive::item' => sub {
    subtest 'first item' => sub {
        $it->first;
        is($it->path, 'OEBPS/style.css', 'first item path');
        ok(!($it->is_last), 'is not last');
    };
    subtest 'second item' => sub {
        $it->next;
        is($it->path, 'OEBPS/cover.png', 'next item path');
        ok($it->is_last, 'is last');
    };
    subtest 'next when last' => sub {
        $it->next;
        is($it->path, 'OEBPS/cover.png', 'last item path');
        ok($it->is_last, 'is last');
    };
    subtest 'reset iterator' => sub {
        $it->reset;
        is($it->{current_index}, -1);
    };
    subtest 'all' => sub {
        my @data = $it->all;
        is(scalar @data, 2);
    };
};

done_testing;

