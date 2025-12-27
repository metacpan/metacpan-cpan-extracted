use strict;
use warnings;

use Test::More tests => 20;
use File::MimeInfo::Simple;

# Test modern MIME types added in 2025
# We test _find_mimetype_by_table directly since on Unix the file command
# analyzes content, not extensions

my $lookup = \&File::MimeInfo::Simple::_find_mimetype_by_table;

# Modern image formats
is($lookup->('photo.webp'), 'image/webp', 'WebP image');
is($lookup->('photo.avif'), 'image/avif', 'AVIF image');
is($lookup->('photo.heic'), 'image/heic', 'HEIC image');
is($lookup->('photo.heif'), 'image/heif', 'HEIF image');
is($lookup->('photo.jxl'), 'image/jxl', 'JPEG XL image');

# Web fonts
is($lookup->('font.woff'), 'font/woff', 'WOFF font');
is($lookup->('font.woff2'), 'font/woff2', 'WOFF2 font');
is($lookup->('font.otf'), 'font/otf', 'OTF font');

# Modern web/dev formats
is($lookup->('data.json'), 'application/json', 'JSON file');
is($lookup->('doc.md'), 'text/markdown', 'Markdown file');
is($lookup->('config.toml'), 'application/toml', 'TOML file');
is($lookup->('video.webm'), 'video/webm', 'WebM video');

# TypeScript/JavaScript variants
is($lookup->('app.ts'), 'text/typescript', 'TypeScript file');
is($lookup->('app.tsx'), 'text/tsx', 'TSX file');
is($lookup->('component.jsx'), 'text/jsx', 'JSX file');
is($lookup->('module.mjs'), 'text/javascript', 'ES module');

# Modern Office formats (OOXML)
is($lookup->('doc.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'DOCX file');
is($lookup->('sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'XLSX file');
is($lookup->('slides.pptx'), 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'PPTX file');

# WebAssembly
is($lookup->('module.wasm'), 'application/wasm', 'WebAssembly file');

