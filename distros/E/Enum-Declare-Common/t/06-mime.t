use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::MIME;

subtest 'text types' => sub {
	is(TextPlain,       'text/plain',       'TextPlain');
	is(TextHtml,        'text/html',        'TextHtml');
	is(TextCss,         'text/css',         'TextCss');
	is(TextCsv,         'text/csv',         'TextCsv');
	is(TextJavascript,  'text/javascript',  'TextJavascript');
	is(TextMarkdown,    'text/markdown',    'TextMarkdown');
};

subtest 'application types' => sub {
	is(ApplicationJson,  'application/json',  'ApplicationJson');
	is(ApplicationXml,   'application/xml',   'ApplicationXml');
	is(ApplicationPdf,   'application/pdf',   'ApplicationPdf');
	is(ApplicationZip,   'application/zip',   'ApplicationZip');
	is(ApplicationGzip,  'application/gzip',  'ApplicationGzip');
	is(ApplicationYaml,  'application/yaml',  'ApplicationYaml');
	is(ApplicationWasm,  'application/wasm',  'ApplicationWasm');
	is(ApplicationOctetStream, 'application/octet-stream', 'ApplicationOctetStream');
	is(ApplicationFormUrlencoded, 'application/x-www-form-urlencoded', 'ApplicationFormUrlencoded');
};

subtest 'image types' => sub {
	is(ImagePng,  'image/png',      'ImagePng');
	is(ImageJpeg, 'image/jpeg',     'ImageJpeg');
	is(ImageGif,  'image/gif',      'ImageGif');
	is(ImageSvg,  'image/svg+xml',  'ImageSvg');
	is(ImageWebp, 'image/webp',     'ImageWebp');
	is(ImageAvif, 'image/avif',     'ImageAvif');
};

subtest 'audio and video types' => sub {
	is(AudioMpeg, 'audio/mpeg', 'AudioMpeg');
	is(AudioOgg,  'audio/ogg',  'AudioOgg');
	is(VideoMp4,  'video/mp4',  'VideoMp4');
	is(VideoWebm, 'video/webm', 'VideoWebm');
};

subtest 'font types' => sub {
	is(FontWoff,  'font/woff',  'FontWoff');
	is(FontWoff2, 'font/woff2', 'FontWoff2');
	is(FontTtf,   'font/ttf',   'FontTtf');
	is(FontOtf,   'font/otf',   'FontOtf');
};

subtest 'meta accessor' => sub {
	my $meta = Type();
	ok($meta->valid('application/json'), 'application/json is valid');
	ok(!$meta->valid('application/foo'), 'application/foo is not valid');
	is($meta->name('text/html'), 'TextHtml', 'name of text/html');
	ok($meta->count > 40, 'more than 40 MIME types');
};

done_testing;
