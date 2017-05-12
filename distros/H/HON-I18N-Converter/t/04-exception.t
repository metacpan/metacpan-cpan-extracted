use strict;
use warnings;

use File::Temp qw/tempfile tempdir/;
use HON::I18N::Converter;

use Test::Exception;
use Test::More tests => 2;

dies_ok { HON::I18N::Converter->new( excel => 't/resources/foobar.xls') } 'file read';

my $dir = File::Temp->newdir();
my $converter = HON::I18N::Converter->new( 
  excel => 't/resources/1-language/input/file.xls'
);

dies_ok { $converter->build_properties_file('TOTO', $dir) } 'unknown format';