#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Encode qw(encode_utf8);
use Locale::TextDomain::OO::Extract::Perl;
use Locale::TextDomain::OO::Extract::Process;
use Path::Iterator::Rule;
use Path::Tiny qw(path);

our $VERSION = 0;

my @languages = qw( de de-at );
my $category  = 'LC_MESSAGES';
my $domain    = 'example1';

my $process = Locale::TextDomain::OO::Extract::Process->new(
    category => $category, # here unchanged
    domain   => $domain,   # here unchanged
                           # project not used
);

# Skip if po file not exists. You get a default header, change later by hand.
# If skipped, check plural-forms for non English, see:
# http://translate.sourceforge.net/wiki/l10n/pluralforms
SLURP_EXISTING_FILES: {
    # category and project unchanged
    for my $language (@languages) {
        $process->language($language); # in this example changed so not in constructor
        $process->slurp(po => "./LocaleData/$language/$category/$domain.po");
    }
}

# Skip if po file not exists. You get a default header, change later by hand.
PREPARE_FOR_EXTRACTION: {
    $process->remove_all_reference;
    $process->remove_all_automatic;
}

EXTRTACT: {
    # pick files
    my @files = Path::Iterator::Rule
        ->new
        ->file( qw( *.pl *.pm ) )
        ->all( qw( ./files_to_extract_for_process ) );
    # set defaults
    my $extract = Locale::TextDomain::OO::Extract::Perl->new;
    # extract
    for my $file ( map { path($_) } @files ) {
        $extract->clear;
        $extract->category($category);
        $extract->domain($domain);
        $extract->filename( $file->relative( q{./} )->stringify );
        $extract->content_ref( \( $file->slurp_utf8 ) );
        $extract->extract;
    }
    # merge
    # category and project unchanged
    for my $language (@languages) {
        $process->language($language);
        $process->merge_extract({
            lexicon_ref       => $extract->lexicon_ref,
            category          => $category,
            domain            => $domain,
            # extended writing means:
            skip_new_messages => {
                # project not used here compleately ...
                on           => $language eq 'de-at',
                # ... but ...
                # (Empty elements ignored in array.)
                no_skip_for  => [ qr{ \QThis is a new {thing}.\E }xmsi, undef, q{} ],
                # ... except ...
                # (No match but all possible writings shown for the same thing.)
                but_skip_for => 'foo bar',
                                # [ 'foo bar' ] 
                                # qr{ \Qfoo bar\E }xmsi 
                                # [ qr{ \Qfoo bar\E }xmsi ]
            },
        });
    }
}

SPEW_TO_EXISTING_FILES: {
    # Use new files here, to see what's going on.
    # category and project unchanged
    for my $language (@languages) {
        $process->language($language);
        $process->spew(po => "../1st_${language}_${domain}_no_or_new_ref.po");
    }
}

TRANSLATE: {
    # Normally translate here
    # * translation (change PO file msgstr's)
    # * read files agian
    # so recreate lexicon_ref
    ;
}

CLEAN_NO_LONGER_IN_SOURCE_ENTRIES: {
    # Cleans all entries that have got no new reference after extract files.
    $process->remove_all_non_referenced;
}

SPEW_TO_EXISTING_FILES: {
    # Use new files here to see what's going on.
    # category and project unchanged
    for my $language (@languages) {
        $process->language($language);
        $process->spew(po => "../2nd_${language}_${domain}_clean.po");
    }
}

my @content
    = map { ## no critic (Complex Mappings)
        my $text = path("../2nd_${_}_${domain}_clean.po")->slurp_utf8;
        $text =~ s{\r\n}{\n}xmsg; # correct line endings
        encode_utf8($text);
    }
    @languages;

() = print {*STDOUT}
    "de/LC_MESSAGES/example1.po (clean)\n\n",
    $content[0],
    "de-at/LC_MESSAGES/example1.po (clean)\n\n",
    $content[1];

# $Id: 22_process_extended_skip_utf-8.pl 709 2017-11-03 10:40:26Z steffenw $

__END__

Output:

de/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Januar"

#. thing => 'text'
#: files_to_extract_for_process/gettext_loc.pl:15
msgid "This is a new {thing}."
msgstr ""

de-at/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Jänner"

