use Test::More;
use strict;
use warnings;
use File::Slurp qw/read_file/;
use EPUB::Parser;

subtest 'EPUB::Parser::load_file' => sub {
    my $ep = EPUB::Parser->new;
    eval { $ep->load_file({ file_path  => 't/var/denden_converter.epub' }) };
    is($@,'', 'load_file');
};

subtest 'EPUB::Parser::load_binary' => sub {
    my $ep = EPUB::Parser->new;
    my $bin_data = read_file( 't/var/denden_converter.epub', binmode => ':raw' );

    local $@;
    eval { $ep->load_binary({ data  => $bin_data }) };
    is($@,'', 'read_binary');
};

subtest 'EPUB::Parser::data_from_path' => sub {
    my $ep = EPUB::Parser->new;
    $ep->load_file({ file_path  => 't/var/denden_converter.epub' });
    ok( length $ep->data_from_path('OEBPS/nav.xhtml'), 'data_from_path' );
};

done_testing;
