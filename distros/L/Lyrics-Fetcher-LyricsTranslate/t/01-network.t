#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet ('lyricstranslate.com' => 80);
use Test::More tests => 5;

use Lyrics::Fetcher;
use Lyrics::Fetcher::LyricsTranslate;

like (
	Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat'),
	qr/soldiers/i,
	'lyrics to Lyube - Kombat contain the word "soldiers"');

like (
	Lyrics::Fetcher->fetch('Lyube', 'Kombat', 'LyricsTranslate'),
	qr/soldiers/i,
	'usage via Lyrics::Fetcher');

like (
	Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat', 'English'),
	qr/soldiers/i,
	'language selection: English');

like (
	Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat', 'English'),
	qr/soldiers/i,
	'language selection: 328');

like (
	Lyrics::Fetcher::LyricsTranslate->fetch('Lyube', 'Kombat', 'Transliteration'),
	qr/soldaty/i,
	'language selection: Transliteration');
