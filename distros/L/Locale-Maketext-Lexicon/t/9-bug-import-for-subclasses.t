#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;

package Hello::I18N;
use base qw/Locale::Maketext/;

package Hello::I18N::zh_tw;
use base qw/Hello::I18N/;
use Locale::Maketext::Lexicon ( Gettext => 't/messages.mo', );

package Hello::I18N::bzh_bzh;
use base qw/Hello::I18N/;
use Locale::Maketext::Lexicon ( Gettext => \*::DATA, _use_fuzzy => 1);

package main;

ok(my $lh = Hello::I18N->get_handle('zh-tw'), 'got handle');

is(
    $lh->maketext('This is a test'),
    '這是測試',
    'translated'
);

ok($lh = Hello::I18N->get_handle('bzh_BZH'), 'Gettext - get_handle on DATA again');
is(
    eval { $lh->maketext("See you another time!") },
    "D'ur wech all !",
    'Gettext - fuzzy recognized: _use_fuzzy has been set'
);

__DATA__
msgid ""
msgstr ""
"Project-Id-Version: Test App 0.01\n"
"POT-Creation-Date: 2006-06-13 11:36+0800\n"
"PO-Revision-Date: 2006-06-13 02:00+0800\n"
"Last-Translator: <yannk@cpan.org>\n"
"Language-Team: German <yannk@cpan.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=ISO-8859-1\n"
"Content-Transfer-Encoding: 8bit\n"

#: Hello.pm:16
#, big, furry, fuzzy
msgid "See you another time!"
msgstr "D'ur wech all !"
