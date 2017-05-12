#!/usr/bin/perl

use Test::More tests => 16;

use Lingua::TreeTagger::ConfigData;

use File::Temp qw();

BEGIN {
    use_ok( 'Lingua::TreeTagger' ) || print "Bail out!
";
}

ok(
    -x $Lingua::TreeTagger::_treetagger_prog_path,
    'path to tree-tagger executable correctly configured'
);

ok(
    -e $Lingua::TreeTagger::_tokenizer_prog_path,
    'path to TreeTagger\'s default tokenizer correctly configured'
);

eval {
    my $bad_language_tagger = Lingua::TreeTagger->new(
        'language' => 'en',
    );
};

like(
    $@,
    qr/no parameter file/,
    'constructor correctly croaks when language has no parameter file'
);

my $test_language = Lingua::TreeTagger::ConfigData->config( 'test_language' );

my $tagger = Lingua::TreeTagger->new(
    'language' => $test_language,
    'options'  => [ qw( -token -lemma -no-unknown ) ],
);

cmp_ok(
    ref( $tagger ), 'eq', 'Lingua::TreeTagger',
    'is a Lingua::TreeTagger'
);

can_ok( $tagger, qw(
    new
    language
    options
    tokenizer
    _parameter_file
    _abbreviation_file
) );

ok(
    -e $tagger->_parameter_file(),
    'path to TreeTagger\'s parameter files correctly configured'
);

# Not sure if every language has an abbreviation file...
#ok(
#    -e $tagger->_abbreviation_file(),
#    'path to TreeTagger\'s abbreviation files correctly configured'
#);

eval {
    $tagger->tag_file();
};

like(
    $@,
    qr/requires a path argument/,
    'method tag_file correctly croaks when no path is passed in argument'
);

eval {
    $tagger->tag_file( 'no_such_file.txt' );
};

like(
    $@,
    qr/File .+ not found/,
    'method tag_file correctly croaks when argument is not a valid file'
);

my $test_file_handle = File::Temp->new();
print $test_file_handle 'Yet another sample text.';
close $test_file_handle;

my $tagged_text = $tagger->tag_file( $test_file_handle->filename() );

cmp_ok(
       ref( $tagged_text ), 'eq', 'Lingua::TreeTagger::TaggedText',
       'method tag_file outputs a Lingua::TreeTagger::TaggedText object...'
      );

ok(
   $tagged_text->length() == 5,
   '... which has the right number of tokens'
  );



sub my_tokenizer {
    my ( $original_text_ref ) = @_;
    my @tokens = split /\s+/, $$original_text_ref;
    my $tokenized_text = join "\n", @tokens;
    return \$tokenized_text;
}



eval {
    $tagger->tag_text();
};

like(
    $@,
    qr/requires a string reference as argument/,
    'method tag_text correctly croaks when no string is passed in argument'
);

my $tagged_text = $tagger->tag_text( \q{Yet another sample text.} );

cmp_ok(
    ref( $tagged_text ), 'eq', 'Lingua::TreeTagger::TaggedText',
    'method tag_text outputs a Lingua::TreeTagger::TaggedText object...'
);

ok(
    $tagged_text->length() == 5,
    '... which has the right number of tokens'
);


my $tagger_with_custom_tokenizer = eval {
    Lingua::TreeTagger->new(
                            'language'  => 'english-utf8',
                            'tokenizer' => \&my_tokenizer,
                           )
  };

SKIP: {
    skip "No english parameter file", 2 if $@ =~ /no parameter file for language english/;

    my $custom_tagged_text = $tagger_with_custom_tokenizer->tag_file(
        $test_file_handle->filename()
    );

    ok(
        $custom_tagged_text->length() == 4,
        'method tag_file works fine with custom tokenizer'
    );

    my $custom_tagged_text
      = $tagger_with_custom_tokenizer->tag_text( \q{Yet another sample text.} );

    ok(
       $custom_tagged_text->length() == 4,
       'method tag_text works fine with custom tokenizer'
      );
}

