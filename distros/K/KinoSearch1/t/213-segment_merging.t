use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 10;
use File::Path qw( rmtree );
use File::Spec::Functions qw( catfile );
use File::stat qw( stat );

BEGIN {
    use_ok('KinoSearch1::InvIndexer');
    use_ok('KinoSearch1::Searcher');
    use_ok('KinoSearch1::Analysis::Tokenizer');
    use_ok('KinoSearch1::Index::IndexReader');
}
use KinoSearch1::Test::TestUtils qw( create_index init_test_index_loc );

my $invindex_loc = init_test_index_loc();
my ( $invindexer, $searcher, $hits, $another_invindex,
    $yet_another_invindex );
my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $fake_norm_file = catfile( $invindex_loc, '_4.f0' );

sub init_invindexer {
    my %args = @_;
    undef $invindexer;
    $invindexer = KinoSearch1::InvIndexer->new(
        invindex => $invindex_loc,
        analyzer => $tokenizer,
        %args,
    );
    if ( $args{create} ) {
        open( my $fh, '>', $fake_norm_file )
            or die "can't open $fake_norm_file: $!";
        print $fh "blah";
    }
    $invindexer->spec_field( name => 'letters' );
}

my $create = 1;
my @correct;
for my $num_letters ( reverse 1 .. 10 ) {
    init_invindexer( create => $create );
    $create = 0;
    for my $letter ( 'a' .. 'b' ) {
        my $doc     = $invindexer->new_doc;
        my $content = ( "$letter " x $num_letters ) . 'z';

        $doc->set_value( letters => $content );
        $invindexer->add_doc($doc);
        push @correct, $content if $letter eq 'b';
    }
    $invindexer->finish;
}

ok( !-f $fake_norm_file, "overwrote fake leftover norm file" );

$searcher = KinoSearch1::Searcher->new(
    invindex => $invindex_loc,
    analyzer => $tokenizer,
);
$hits = $searcher->search( query => 'b' );
is( $hits->total_hits, 10, "correct total_hits from merged invindex" );
my @got;
push @got, $hits->fetch_hit_hashref->{letters} for 1 .. $hits->total_hits;
is_deeply( \@got, \@correct, "correct top scoring hit from merged invindex" );

init_invindexer();
$another_invindex = create_index( "atlantic ocean", "fresh fish" );
$yet_another_invindex = create_index("bonus");
$invindexer->add_invindexes( $another_invindex, $yet_another_invindex );
$invindexer->finish;
$searcher = KinoSearch1::Searcher->new(
    invindex => $invindex_loc,
    analyzer => $tokenizer,
);
$hits = $searcher->search( query => 'fish' );
is( $hits->total_hits, 1, "correct total_hits after add_invindexes" );
is( $hits->fetch_hit_hashref->{content},
    'fresh fish', "other invindexes successfully absorbed" );
undef $searcher;
undef $hits;

# Open an IndexReader, to prevent the deletion of files on Win32 and verify
# the deletequeue mechanism.
my $reader
    = KinoSearch1::Index::IndexReader->new( invindex => $invindex_loc, );
init_invindexer();
$invindexer->finish( optimize => 1 );
$reader->close;
init_invindexer();
$invindexer->finish( optimize => 1 );
opendir( my $invindex_dh, $invindex_loc )
    or die "Couldn't opendir '$invindex_loc': $!";
my @cfs_files = grep {m/\.cfs$/} readdir $invindex_dh;
closedir $invindex_dh, $invindex_loc
    or die "Couldn't closedir '$invindex_loc': $!";
is( scalar @cfs_files, 1, "merged segment files successfully deleted" );

# Clean up.
rmtree($invindex_loc);
