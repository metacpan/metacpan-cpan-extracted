# HTTP::Body

**HTTP Body Parser for Perl**

HTTP::Body parses chunks of HTTP POST data and supports the following content types:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `multipart/related` (XForms)
- `application/xml` (XForms)
- `application/json`
- `application/octet-stream`

Chunked transfer encoding is fully supported.

HTTP::Body is used by [Catalyst](https://metacpan.org/pod/Catalyst), [Dancer](https://metacpan.org/pod/Dancer), [Web::Simple](https://metacpan.org/pod/Web::Simple), and other Perl web frameworks.

## Installation

### From CPAN

```bash
cpanm HTTP::Body
```

Or with the classic CPAN client:

```bash
cpan HTTP::Body
```

### From Source

```bash
git clone https://github.com/libwww-perl/HTTP-Body.git
cd HTTP-Body
cpanm Dist::Zilla
dzil install
```

### System Package Managers

Debian / Ubuntu:

```bash
apt-get install libhttp-body-perl
```

Fedora:

```bash
dnf install perl-HTTP-Body
```

### Dependencies

- [HTTP::Headers](https://metacpan.org/pod/HTTP::Headers)
- [HTTP::Message](https://metacpan.org/pod/HTTP::Message)
- [File::Temp](https://metacpan.org/pod/File::Temp) (>= 0.14)
- [IO::File](https://metacpan.org/pod/IO::File) (>= 1.14)
- [Digest::MD5](https://metacpan.org/pod/Digest::MD5)

## Synopsis

```perl
use HTTP::Body;

my $body = HTTP::Body->new($content_type, $content_length);

while (my $chunk = read_some_data()) {
    $body->add($chunk);
}

my $params  = $body->param;        # hashref of parsed parameters
my $uploads = $body->upload;       # hashref of file uploads
my $raw     = $body->body;         # IO::Handle for raw body
my $order   = $body->param_order;  # arrayref of param keys in order
```

### Parsing a Multipart Upload

```perl
use HTTP::Body;

my $body = HTTP::Body->new('multipart/form-data; boundary=xYzZY', $content_length);
$body->tmpdir('/var/tmp');
$body->cleanup(1);  # auto-delete temp files when done

while (read($input, my $buffer, 8192)) {
    $body->add($buffer);
}

for my $name (keys %{ $body->upload }) {
    my $upload = $body->upload->{$name};
    my $tempfile = $upload->{tempname};
    my $filename = $upload->{filename};
    # process the uploaded file...
}
```

### Chunked Transfer Encoding

```perl
# Omit content_length to enable chunked mode
my $body = HTTP::Body->new($content_type);

while (my $chunk = get_next_chunk()) {
    $body->add($chunk);
}

# Access trailing headers (if any)
my $trailing = $body->trailing_headers;
```

## API

| Method | Description |
|---|---|
| `new($content_type, [$content_length])` | Create a new parser. Omit length for chunked mode. |
| `add($data)` | Feed data to the parser. |
| `body` | Raw body as IO::Handle. |
| `param` | Hashref of parsed form parameters. |
| `param_order` | Arrayref of parameter keys in submission order. |
| `upload` | Hashref of file uploads. |
| `part_data` | Hashref with full multipart metadata per field. |
| `content_type` | The content type of the request. |
| `content_length` | The content length, or -1 for chunked. |
| `chunked` | Returns 1 if the request uses chunked encoding. |
| `trailing_headers` | HTTP::Headers object of trailing headers (chunked). |
| `tmpdir([$path])` | Get/set the temp directory for uploads. |
| `cleanup([$bool])` | Enable auto-deletion of temp files at DESTROY. |
| `state` | Current parser state. |
| `length` | Bytes read so far. |

## Limits

To bound resource use on hostile input, `add()` enforces limits and croaks when one is exceeded. Raise a limit for larger forms, or set it to `0` to disable it:

| Variable | Default | Limits |
|---|---|---|
| `$HTTP::Body::MultiPart::max_parts` | 1000 | parts in a multipart body |
| `$HTTP::Body::UrlEncoded::max_params` | 1000 | fields in a urlencoded body |
| `$HTTP::Body::MultiPart::max_header_size` | 32768 | bytes in a part's header block |
| `$HTTP::Body::MultiPart::max_header_lines` | 100 | lines in a part's header block |

## Configuring Upload Temporary Files

By default, temporary files for uploads use the `.upload` extension instead of the uploaded file's own extension. This can be customized:

```perl
# Keep the uploaded file's own extension (behavior before 1.23)
$HTTP::Body::MultiPart::file_temp_suffix = undef;

# Custom File::Temp template
$HTTP::Body::MultiPart::file_temp_template = 'uploadXXXXXX';

# Custom File::Temp parameters
%HTTP::Body::MultiPart::file_temp_parameters = (
    UNLINK => 0,
    DIR    => '/my/upload/dir',
);
```

## Support

- **Issues:** [GitHub Issues](https://github.com/libwww-perl/HTTP-Body/issues)
- **Source:** [GitHub](https://github.com/libwww-perl/HTTP-Body)
- **CPAN:** [metacpan.org/release/HTTP-Body](https://metacpan.org/release/HTTP-Body)
- **IRC:** `#catalyst` on `irc.perl.org` (users), `#catalyst-dev` (contributors)

## Authors

- Christian Hansen `<christian.hansen@mac.com>`
- Sebastian Riedel `<kraihx@googlemail.com>`
- Andy Grundman `<andy@hybridized.org>`

## Maintainer

- Torsten Raudssus `<torsten@raudssus.de>`

## Contributors

- Simon Elliott
- Kent Fredric
- Christian Walde

## License

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.
