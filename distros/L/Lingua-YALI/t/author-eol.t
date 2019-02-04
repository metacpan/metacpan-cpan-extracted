
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/yali-builder',
    'bin/yali-identifier',
    'bin/yali-language-identifier',
    'lib/Lingua/YALI.pm',
    'lib/Lingua/YALI/Builder.pm',
    'lib/Lingua/YALI/Examples.pod',
    'lib/Lingua/YALI/Identifier.pm',
    'lib/Lingua/YALI/LanguageIdentifier.pm',
    't/00-compile.t',
    't/00-everything_loads.t',
    't/Builder/00-general.t',
    't/Builder/01-new.t',
    't/Builder/02-train_file.t',
    't/Builder/03-train_handler.t',
    't/Builder/04-train_string.t',
    't/Builder/05-store_with_train_file.t',
    't/Builder/06-store_with_train_handle.t',
    't/Builder/07-store_with_train_string.t',
    't/Builder/08-store_with_wrong_parameters.t',
    't/Examples/01-LanguageIdentifier-Synopsis.t',
    't/Identifier/00-general.t',
    't/Identifier/01-add_class.t',
    't/Identifier/02-remove_class.t',
    't/Identifier/03-get_classes.t',
    't/Identifier/04-identify_file.t',
    't/Identifier/05-identify_handle.t',
    't/Identifier/06-identify_string.t',
    't/Identifier/07-manipulation_with_classes.t',
    't/Identifier/08-manipulation_and_identification.t',
    't/Identifier/aaa01.txt',
    't/Identifier/bbb01.txt',
    't/Identifier/classes.list',
    't/Identifier/files.txt',
    't/Identifier/mix01.txt',
    't/LanguageIdentifier/00-general.t',
    't/LanguageIdentifier/00-get_available_languages.t',
    't/LanguageIdentifier/01-add_language.t',
    't/LanguageIdentifier/02-remove_language.t',
    't/LanguageIdentifier/03-get_languages.t',
    't/LanguageIdentifier/04-identify_file.t',
    't/LanguageIdentifier/05-identify_handle.t',
    't/LanguageIdentifier/06-identify_string.t',
    't/LanguageIdentifier/ces01.txt',
    't/LanguageIdentifier/eng01.txt',
    't/LanguageIdentifier/files.txt',
    't/author-critic.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-unused-vars.t',
    't/yali-builder/00-general.t',
    't/yali-builder/01-help.t',
    't/yali-builder/02-count.t',
    't/yali-builder/03-ngram.t',
    't/yali-builder/04-train.t',
    't/yali-identifier/00-general.t',
    't/yali-identifier/01-help.t',
    't/yali-identifier/02-format.t',
    't/yali-identifier/03-classes.t',
    't/yali-identifier/04-input-each_line.t',
    't/yali-identifier/04-input.t',
    't/yali-identifier/05-filelist-each_line.t',
    't/yali-identifier/05-filelist.t',
    't/yali-language-identifier/00-general.t',
    't/yali-language-identifier/01-help.t',
    't/yali-language-identifier/02-format.t',
    't/yali-language-identifier/03-supported.t',
    't/yali-language-identifier/04-languages.t',
    't/yali-language-identifier/05-input-each_line.t',
    't/yali-language-identifier/05-input.t',
    't/yali-language-identifier/06-filelist-each_line.t',
    't/yali-language-identifier/06-filelist.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
