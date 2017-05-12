use strict;
use warnings;

use Test::More tests => 4;    # last test to print

use FindBin;
use Path::Iterator::Rule;
use Path::Tiny qw( path );
use YAML::XS;
use Log::Log4perl qw( :easy );

#Log::Log4perl->easy_init($WARN);

my $filesdir = "$FindBin::Bin/test_files/";

use ELF::Extract::Sections;

my $exclude = Path::Iterator::Rule->new->name( "*.pl", "*.yaml" );
my $iter = Path::Iterator::Rule->new->file->not($exclude)->iter($filesdir);

while ( my $file = $iter->() ) {
    my $f       = path($file);
    my $yaml    = path( $file . '.yaml' );
    my $data    = YAML::XS::LoadFile( $yaml->stringify );
    my $scanner = ELF::Extract::Sections->new( file => $f );
    my $d       = {};
    for ( values %{ $scanner->sections } ) {
        $d->{ $_->name } = {
            size   => $_->size,
            offset => $_->offset,
        };
    }
    is_deeply( $d, $data, sprintf 'Analysis of %s matches data stored in %s', $f->basename, $yaml->basename );
}

