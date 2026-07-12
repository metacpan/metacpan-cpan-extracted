use strict;
use warnings;
use Test::More tests => 34;
use Eshu;

# XML family
is(Eshu->detect_lang('data.xml'),       'xml',  '.xml -> xml');
is(Eshu->detect_lang('stylesheet.xsl'), 'xml',  '.xsl -> xml');
is(Eshu->detect_lang('transform.xslt'), 'xml',  '.xslt -> xml');
is(Eshu->detect_lang('image.svg'),      'xml',  '.svg -> xml');
is(Eshu->detect_lang('page.xhtml'),     'xml',  '.xhtml -> xml');

# HTML family
is(Eshu->detect_lang('index.html'),  'html', '.html -> html');
is(Eshu->detect_lang('index.htm'),   'html', '.htm -> html');
is(Eshu->detect_lang('view.tmpl'),   'html', '.tmpl -> html');
is(Eshu->detect_lang('view.tt'),     'html', '.tt -> html');
is(Eshu->detect_lang('view.ep'),     'html', '.ep -> html');

# CSS family
is(Eshu->detect_lang('style.css'),   'css', '.css -> css');
is(Eshu->detect_lang('style.scss'),  'css', '.scss -> css');
is(Eshu->detect_lang('style.less'),  'css', '.less -> css');

# JavaScript / TypeScript family
is(Eshu->detect_lang('app.js'),    'js', '.js -> js');
is(Eshu->detect_lang('comp.jsx'),  'js', '.jsx -> js');
is(Eshu->detect_lang('mod.mjs'),   'js', '.mjs -> js');
is(Eshu->detect_lang('mod.cjs'),   'js', '.cjs -> js');
is(Eshu->detect_lang('app.ts'),    'js', '.ts -> js');
is(Eshu->detect_lang('comp.tsx'),  'js', '.tsx -> js');
is(Eshu->detect_lang('mod.mts'),   'js', '.mts -> js');

# POD
is(Eshu->detect_lang('Manual.pod'), 'pod', '.pod -> pod');

# Uppercase extensions
is(Eshu->detect_lang('foo.C'),  'c',  '.C (uppercase) -> c');
is(Eshu->detect_lang('foo.H'),  'c',  '.H (uppercase) -> c');

# Already-covered extensions still work
is(Eshu->detect_lang('foo.c'),  'c',    '.c -> c');
is(Eshu->detect_lang('Foo.xs'), 'xs',   '.xs -> xs');
is(Eshu->detect_lang('foo.pl'), 'perl', '.pl -> perl');
is(Eshu->detect_lang('Foo.pm'), 'perl', '.pm -> perl');
is(Eshu->detect_lang('foo.t'),  'perl', '.t -> perl');

# No extension
is(Eshu->detect_lang('Makefile'), undef, 'no extension -> undef');

# Unknown extension
is(Eshu->detect_lang('foo.txt'),   undef, '.txt -> undef');
is(Eshu->detect_lang('foo.md'),    undef, '.md -> undef');
is(Eshu->detect_lang('foo.yaml'),  undef, '.yaml -> undef');
is(Eshu->detect_lang('foo.json'),  undef, '.json -> undef');

# Path with directory components — only extension matters
is(Eshu->detect_lang('lib/Foo/Bar.pm'), 'perl', 'path/to/File.pm -> perl');
