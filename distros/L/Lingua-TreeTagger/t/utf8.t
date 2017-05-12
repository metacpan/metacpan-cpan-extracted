#!/usr/bin/perl

use utf8;

use Test::More;
use Test::More::UTF8;

use Encode qw( encode_utf8 );
use Lingua::TreeTagger;
use Path::Class;
use File::Temp qw();

# Skip using the tests unless we have french-utf8 installed
my $utf8_test_lang = 'french';
my $testparamfile = file( $Lingua::TreeTagger::_treetagger_lib_path, 
    $utf8_test_lang . '-utf8.par' );

my $default_tokenizer = $Lingua::TreeTagger::_tokenizer_prog_path;
$default_tokenizer =~ s/tokenize\.pl$/utf8-tokenize.perl/;
my $testtokenizer = file( $default_tokenizer );

if( -e $testparamfile && -e $testtokenizer ) {
    plan tests => 14;
}
else {
    plan skip_all => 'Need french-utf8 parameter files and utf8 tokenizer '
                   . 'installed to test utf8'
                   ;
}


my $tagger = Lingua::TreeTagger->new(
    'language' => $utf8_test_lang,
    'use_utf8' => 1,
    'options'  => [ qw( -token -lemma -no-unknown ) ],
);

# Check that the parameter and abbreviation files got set correctly
is( $tagger->_parameter_file->basename, $utf8_test_lang . '-utf8.par', 
    "Found correct UTF-8 parameter file" );
is( $tagger->_abbreviation_file->basename, $utf8_test_lang . '-abbreviations-utf8',
    "Found correct UTF-8 abbreviation file" );
like( $Lingua::TreeTagger::_tokenizer_prog_path, qr/utf8-tokenize\.perl/,
    "Correctly reset the default tokenizer" );
    
my $teststr = "Où sont passées toutes nos nuits de rêve? Aide-moi à les retrouver.";
my $tagged_text = $tagger->tag_text( \$teststr );
is( $tagged_text->length, 15, "Tagged text is correct length" );
# Test the relevant tokens for Unicode correctness
is( $tagged_text->sequence->[0]->original, 'Où', "Got correct token for index 0" );
is( $tagged_text->sequence->[2]->original, 'passées', "Got correct token for index 2" );
is( $tagged_text->sequence->[2]->lemma, 'passer', "Got correct lemma for index 2" );
is( $tagged_text->sequence->[7]->original, 'rêve', "Got correct token for index 7" );
is( $tagged_text->sequence->[11]->original, 'à', "Got correct token for index 7" );

# Test the text output for Unicode correctness. Check for ê character somewhere
like( encode_utf8( $tagged_text->as_text ), qr/\x{c3}\x{aa}/, 
    "Tagged text returns Unicode string" );

my $test_file_handle = File::Temp->new();
binmode( $test_file_handle, ':utf8' );
print $test_file_handle "Je n'aurai besoin que de deux nuits d'hôtel.\n";
close $test_file_handle;

my $tagged_filetext = $tagger->tag_file( $test_file_handle->filename() );

is( ref( $tagged_filetext ), 'Lingua::TreeTagger::TaggedText',
    'method tag_file outputs a Lingua::TreeTagger::TaggedText object...' );
is( $tagged_filetext->length, 11, '... which has the right number of tokens' );
is( $tagged_filetext->sequence->[9]->original, 'hôtel', "Got correct token for index 9" );

# Check for the ô character somewhere
like( encode_utf8( $tagged_filetext->as_text ), qr/\x{c3}\x{b4}/, 
    "Tagged text returns Unicode string" );
