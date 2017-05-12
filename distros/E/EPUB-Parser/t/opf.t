use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new->load_file({ file_path  => 't/var/denden_converter.epub' });
my $opf = $ep->opf;

is( ref $opf->parser, 'EPUB::Parser::File::Parser::OPF', 'opf_parser' );

subtest 'EPUB::Parser::File::OPF::path' => sub {
    is($opf->path, 'OEBPS/content.opf', 'opf_path');
};

subtest 'EPUB::Parser::File::OPF::dir' => sub {
    is($opf->dir, 'OEBPS', 'opf_dir');
};

subtest 'EPUB::Parser::File::OPF::data' => sub {
    ok(length $opf->data, 'opf_data');
};

subtest 'EPUB::Parser::File::OPF::nav_path' => sub {
    is($opf->nav_path, 'OEBPS/nav.xhtml', 'nav_path');
};

subtest 'EPUB::Parser::File::OPF::cover_image_path' => sub {
    is($ep->opf->cover_image_path, 'cover.png', 'rel cover img path');
    is($ep->opf->cover_image_path({ abs => 1 }), 'OEBPS/cover.png', 'abs cover img path');

};

subtest 'EPUB::Parser::File::OPF::guess_version' => sub {
    is($opf->guess_version, '3.0', 'guess_version');
};

done_testing;
