package Enum::Declare::Common::MIME;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Type :Str :Type :Export {
	TextPlain             = "text/plain",
	TextHtml              = "text/html",
	TextCss               = "text/css",
	TextCsv               = "text/csv",
	TextXml               = "text/xml",
	TextJavascript        = "text/javascript",
	TextMarkdown          = "text/markdown",
	ApplicationJson       = "application/json",
	ApplicationXml        = "application/xml",
	ApplicationPdf        = "application/pdf",
	ApplicationZip        = "application/zip",
	ApplicationGzip       = "application/gzip",
	ApplicationTar        = "application/x-tar",
	ApplicationFormUrlencoded = "application/x-www-form-urlencoded",
	ApplicationOctetStream = "application/octet-stream",
	ApplicationJavascript = "application/javascript",
	ApplicationLdJson     = "application/ld+json",
	ApplicationMsgpack    = "application/msgpack",
	ApplicationYaml       = "application/yaml",
	ApplicationWasm       = "application/wasm",
	ApplicationSql        = "application/sql",
	MultipartFormData     = "multipart/form-data",
	MultipartByteranges   = "multipart/byteranges",
	ImagePng              = "image/png",
	ImageJpeg             = "image/jpeg",
	ImageGif              = "image/gif",
	ImageSvg              = "image/svg+xml",
	ImageWebp             = "image/webp",
	ImageAvif             = "image/avif",
	ImageBmp              = "image/bmp",
	ImageTiff             = "image/tiff",
	ImageIco              = "image/x-icon",
	AudioMpeg             = "audio/mpeg",
	AudioOgg              = "audio/ogg",
	AudioWav              = "audio/wav",
	AudioWebm             = "audio/webm",
	AudioFlac             = "audio/flac",
	AudioAac              = "audio/aac",
	VideoMp4              = "video/mp4",
	VideoWebm             = "video/webm",
	VideoOgg              = "video/ogg",
	VideoMpeg             = "video/mpeg",
	VideoQuicktime        = "video/quicktime",
	FontWoff              = "font/woff",
	FontWoff2             = "font/woff2",
	FontTtf               = "font/ttf",
	FontOtf               = "font/otf"
};

1;

=head1 NAME

Enum::Declare::Common::MIME - Common MIME type constants

=head1 SYNOPSIS

    use Enum::Declare::Common::MIME;

    say ApplicationJson;  # "application/json"
    say ImagePng;         # "image/png"
    say TextHtml;         # "text/html"

    my $meta = Type();
    ok($meta->valid('application/json'));

=head1 ENUMS

=head2 Type :Str :Export

48 common MIME types covering text, application, image, audio, video,
multipart, and font categories.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
