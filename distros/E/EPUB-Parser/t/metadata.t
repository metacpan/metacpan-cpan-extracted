use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });
my $opf = $ep->opf;

subtest 'EPUB::Parser::File::OPF::Context::Metadata::title' => sub {
    is($opf->metadata->title, 'テスト', 'metadata_title');
};

subtest 'EPUB::Parser::File::OPF::Context::Metadata::creator' => sub {
    is($opf->metadata->creator, 'おーさー', 'metadata_creator');
};

subtest 'EPUB::Parser::File::OPF::Context::Metadata::language' => sub {
    is($opf->metadata->language, 'ja', 'metadata_language');
};

subtest 'EPUB::Parser::File::OPF::Context::Metadata::identifier' => sub {
    is($opf->metadata->identifier, 'urn:uuid:9d53b96a-0027-47f5-9e32-9901db1f1233', 'metadata_identifier');
};


done_testing;
