#!perl -T

use strict;
use warnings;

use Test::More tests => 30;
use Test::NoWarnings;
use Test::Differences;
use JSON qw(decode_json);

BEGIN {
    require_ok('Locale::TextDomain::OO::Lexicon::Hash');
    require_ok('Locale::TextDomain::OO::Lexicon::StoreJSON');
}

Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        '::' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "::\x00p\x04c" },
        ],
        ':cat1:' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => ":cat1:\x00p\x04c" },
        ],
        '::dom1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "::dom1\x00p\x04c" },
        ],
        ':cat1:dom1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => ":cat1:dom1\x00p\x04c" },
        ],
        'en::' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "en::\x00p\x04c" },
        ],
        'en:cat1:' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "en:cat1:\x00p\x04c" },
        ],
        'en::dom1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "en::dom1\x00p\x04c" },
        ],
        'en:cat1:dom1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "en:cat1:dom1\x00p\x04c" },
        ],
        'de:cat1:dom1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "de:cat1:dom1\x00p\x04c" },
        ],
        'de:::project1' => [
            { msgid  => "", msgstr => "Content-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=1; plural=0" },
            { msgid  => "de:::project1\x00p\x04c" },
        ],
    });

eq_or_diff
    [
        sort keys %{
            decode_json(
                Locale::TextDomain::OO::Lexicon::StoreJSON->new->copy->to_json,
            )
        },
    ],
    [ qw(
        ::
        ::dom1
        :cat1:
        :cat1:dom1
        de:::project1
        de:cat1:dom1
        en::
        en::dom1
        en:cat1:
        en:cat1:dom1
        i-default::
    ) ],
    'all languages, all categories and all domains';

COPY_REMOVE_CLEAR: {
    eq_or_diff
        do {
            my $obj = Locale::TextDomain::OO::Lexicon::StoreJSON->new;
            $obj->filter_project('project1');
            $obj->copy;
            $obj->clear_filter;
            $obj->filter_domain( qr{ \A dom }xms );
            $obj->copy;
            $obj->clear_filter;
            $obj->filter_category( sub { return $_ eq 'cat1' } );
            $obj->copy;
            $obj->clear_filter;
            $obj->filter_domain('dom1');
            $obj->filter_category('cat1');
            $obj->remove;
            [ sort keys %{ $obj->data } ];
        },
        [ qw(
            ::dom1
            :cat1:
            de:::project1
            en::dom1
            en:cat1:
        ) ],
        'copy remove';
}

sub _wrap_filter {
    return [
        sort keys %{
            decode_json(
                Locale::TextDomain::OO::Lexicon::StoreJSON
                    ->new(@_)
                    ->copy
                    ->to_json,
            )
        },
    ];
}

note 'filter 1 thing';
{
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
        ),
        [ qw(
            en::
            en::dom1
            en:cat1:
            en:cat1:dom1
        ) ],
        'all languages en';
    eq_or_diff
        _wrap_filter(
            filter_category => 'cat1',
        ),
        [ qw(
            :cat1:
            :cat1:dom1
            de:cat1:dom1
            en:cat1:
            en:cat1:dom1
        ) ],
        'all categories cat1';
    eq_or_diff
        _wrap_filter(
            filter_domain => 'dom1',
        ),
        [ qw(
            ::dom1
            :cat1:dom1
            de:cat1:dom1
            en::dom1
            en:cat1:dom1
        ) ],
        'all domains dom1';
}

note 'filter_language_category';
{
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => q{},
        ),
        [ qw(
            ::
            ::dom1
        ) ],
        'empty language and category';
     eq_or_diff
        _wrap_filter(
            filter_category => q{},
            filter_language => 'i-default',
        ),
        [ qw(
            i-default::
        ) ],
        'language i-default, empty category';
     eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => 'cat1',
        ),
        [ qw(
            :cat1:
            :cat1:dom1
        ) ],
        'empty language, category cat1';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_category => 'cat1',
        ),
        [ qw(
            en:cat1:
            en:cat1:dom1
        ) ],
        'language en, category cat1';
}

note 'filter_language_domain';
{
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_domain   => q{},
        ),
        [ qw(
            ::
            :cat1:
        ) ],
        'empty language and domain';
     eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_domain   => q{},
        ),
        [ qw(
            en::
            en:cat1:
        ) ],
        'language en, empty domain';
     eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_domain   => 'dom1',
        ),
        [ qw(
            ::dom1
            :cat1:dom1
        ) ],
        'empty language, domain dom1';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_domain   => 'dom1',
        ),
        [ qw(
            en::dom1
            en:cat1:dom1
        ) ],
        'language en, domain dom1';
}

note 'filter_category_domain';
{
    eq_or_diff
        _wrap_filter(
            filter_category => q{},
            filter_domain   => q{},
        ),
        [ qw(
            ::
            de:::project1
            en::
            i-default::
        ) ],
        'empty category and domain';
    eq_or_diff
        _wrap_filter(
            filter_category => 'cat1',
            filter_domain   => q{},
        ),
        [ qw(
            :cat1:
            en:cat1:
        ) ],
        'category cat1, empty domain';
    eq_or_diff
        _wrap_filter(
            filter_category => q{},
            filter_domain   => 'dom1',
        ),
        [ qw(
            ::dom1
            en::dom1
        ) ],
        'empty category, domain dom1';
    eq_or_diff
        _wrap_filter(
            filter_category => 'cat1',
            filter_domain   => 'dom1',
        ),
        [ qw(
            :cat1:dom1
            de:cat1:dom1
            en:cat1:dom1
        ) ],
        'category cat1, domain dom1';
}

note 'filter_language_category_domain';
{
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => q{},
            filter_domain   => q{},
        ),
        [ qw(
            ::
        ) ],
        'empty language, category and domain';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_category => q{},
            filter_domain   => q{},
        ),
        [ qw(
            en::
        ) ],
        'language en, empty category and domain';
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => 'cat1',
            filter_domain   => q{},
        ),
        [ qw(
            :cat1:
        ) ],
        'empty language, category cat1, empty domain';
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => q{},
            filter_domain   => 'dom1',
        ),
        [ qw(
            ::dom1
        ) ],
        'empty language and category, domain dom1';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_category => 'cat1',
            filter_domain   => q{},
        ),
        [ qw(
            en:cat1:
        ) ],
        'language en, category cat1, empty domain';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_category => q{},
            filter_domain   => 'dom1',
        ),
        [ qw(
            en::dom1
        ) ],
        'language en, empty category, domain dom1';
    eq_or_diff
        _wrap_filter(
            filter_language => q{},
            filter_category => 'cat1',
            filter_domain   => 'dom1',
        ),
        [ qw(
            :cat1:dom1
        ) ],
        'empty language, category cat1, domain dom1';
    eq_or_diff
        _wrap_filter(
            filter_language => 'en',
            filter_category => 'cat1',
            filter_domain   => 'dom1',
        ),
        [ qw(
            en:cat1:dom1
        ) ],
        'language en, category cat1, domain dom1';
}

like
    +Locale::TextDomain::OO::Lexicon::StoreJSON
        ->new
        ->copy
        ->to_javascript,
    qr{\A \Qvar localeTextDomainOOLexicon = {\E .*? \Q};\E \n \z}xms,
    'to_javascript';
like
    +Locale::TextDomain::OO::Lexicon::StoreJSON
        ->new
        ->copy
        ->to_html,
    qr{
        \A
        \Q<script type="text/javascript"><!--\E \n
        \Qvar localeTextDomainOOLexicon = {\E .*? \Q};\E \n
        \Q--></script>\E \n
        \z
    }xms,
    'to_html';
