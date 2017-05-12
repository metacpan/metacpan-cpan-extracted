use Test::More;
use strict;
use warnings;
use utf8;
use Scalar::Util qw/isweak/;
use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });

my $manifest = $ep->opf->context('manifest');
is(ref $manifest, 'EPUB::Parser::File::OPF::Context::Manifest', 'manifest class name');
is(ref $manifest->opf, 'EPUB::Parser::File::OPF', 'opf class name');

ok( isweak($manifest->{opf}), 'is weak' );

done_testing;

