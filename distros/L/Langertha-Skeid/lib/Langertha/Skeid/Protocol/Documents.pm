package Langertha::Skeid::Protocol::Documents;
our $VERSION = '0.004';
# ABSTRACT: The document conversion routes of docling-serve -- relayed, the pages read off the answer
use strict;
use warnings;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid::Protocol::Audio;


# The client's path and the path below the node URL it is relayed to. The node URL is a base:
# `_endpoint_url_for_node` puts the /v1 in, so these are the paths docling serves below it.
my %UPSTREAM_PATH = (
  '/v1/convert/file'   => '/convert/file',
  '/v1/convert/source' => '/convert/source',
);

# The node kinds, beside the default (chat). Per kind: nothing yet -- a table, because the next
# kind is a row here, not a branch in the router.
my %KIND = (
  documents => 1,
);

# The routing key of the documents route. It stands where the model name stands for every other
# route: key policies grant it (`models: [qwen, documents]`), an alias of that name tiers the
# nodes. It is not the name of a model and no node carries it.
my $ROUTING_KEY = 'documents';

# Largest answer body Skeid decodes to read the page count off it. A converted document is
# markdown, JSON, HTML, text and doctags side by side; beyond this the count is not worth the
# CPU of decoding it on the request path, and the event simply has no `pages`.
my $MAX_PARSE_BYTES = 8 * 1024 * 1024;

# Request fields by which the node fetches from, or writes to, an address the client names --
# a server-side request made from inside the cluster network. Refused unless the operator allows
# remote sources (`documents.allow_remote_sources`). The names are read as a form parser reads
# them: any case, any white space around, an index or brackets behind (`callbacks[0]`).
my %REMOTE_FIELD = map { $_ => 1 } qw(callbacks http_sources);

# A header name is a token (RFC 7230 3.2.6).
my $TOKEN = qr/\A[!#\$%&'*+.^_`|~0-9A-Za-z-]+\z/;


sub routes { return sort keys %UPSTREAM_PATH }


sub upstream_path {
  my ($class, $route) = @_;
  return $UPSTREAM_PATH{$route // ''};
}


sub api_format { 'docling' }


sub routing_key { $ROUTING_KEY }


sub kinds { return sort keys %KIND }


sub normalize_kind {
  my ($class, $value) = @_;
  return '' unless defined $value;
  croak 'kind must be a string' if ref $value;
  my $kind = lc "$value";
  $kind =~ s/\A\s+//;
  $kind =~ s/\s+\z//;
  return '' if !length($kind) || $kind eq 'chat';
  return $kind if $KIND{$kind};
  croak "unknown kind '$value' (expected one of: chat, " . join(', ', $class->kinds) . ')';
}


sub normalize_key_header {
  my ($class, $value) = @_;
  return '' unless defined $value;
  croak 'api_key_header must be a string' if ref $value;
  my $name = "$value";
  return '' unless length $name;
  croak "api_key_header '$name' is not a valid HTTP header name" unless $name =~ $TOKEN;
  return '' if lc($name) eq 'authorization';
  return $name;
}


sub max_parse_bytes { $MAX_PARSE_BYTES }


sub form_remote_fields {
  my ($class, $content) = @_;
  my %found;
  my $parts = $content->parts;
  for my $part (@$parts) {
    return ([], 'Nested multipart parts are not supported') if $part->is_multipart;
    my $disposition = $part->headers->content_disposition // next;
    my ($names, undef, $extended) = Langertha::Skeid::Protocol::Audio->disposition_names($disposition);
    return ([], 'A form field name in the extended notation (name*) is not supported') if $extended;
    for my $name (@$names) {
      my $field = $class->_remote_field($name) // next;
      $found{$field} = 1;
    }
  }
  return ([ sort keys %found ], undef);
}

# The canonical field name a request field spells, or undef for a field that is not one of the
# remote ones: case-folded, white space trimmed, `[]`, `[0]` and `.0` dropped.
sub _remote_field {
  my ($class, $name) = @_;
  return unless defined $name;
  (my $field = lc $name) =~ s/\A\s+//;
  $field =~ s/\s+\z//;
  $field =~ s/(?:\[[^\]]*\]|\.[0-9a-z_]+)+\z//;
  return $REMOTE_FIELD{$field} || $field eq 'sources' || $field eq 'target' ? $field : undef;
}


sub json_remote_fields {
  my ($class, $body, $bytes) = @_;
  my %found;
  return [] unless ref($body) eq 'HASH';

  for my $field (qw(http_sources callbacks)) {
    next unless exists $body->{$field};
    my $value = $body->{$field};
    $found{$field} = 1 if defined($value) && !(ref($value) eq 'ARRAY' && !@$value)
      && !(ref($value) eq 'HASH' && !%$value);
    # Named twice: refused even when the one that wins is empty.
    if (defined $bytes) {
      my $count = () = $bytes =~ /"\Q$field\E"/g;
      $found{$field} = 1 if $count > 1;
    }
  }

  if (defined(my $sources = $body->{sources})) {
    my @entries = ref($sources) eq 'ARRAY' ? @$sources : ($sources);
    for my $entry (@entries) {
      my $inline = ref($entry) eq 'HASH'
        && (defined($entry->{kind}) ? lc($entry->{kind}) eq 'file' : defined($entry->{base64_string}))
        && !defined($entry->{url});
      $found{sources} = 1, last unless $inline;
    }
  }

  if (defined(my $target = $body->{target})) {
    my $kind = ref($target) eq 'HASH' ? lc($target->{kind} // '') : '';
    $found{target} = 1 unless $kind eq 'inbody' || $kind eq 'zip';
  }
  return [ sort keys %found ];
}


sub document_count {
  my ($class, $request) = @_;
  if (ref($request) eq 'HASH') {
    my $n = 0;
    for my $field (qw(file_sources http_sources sources)) {
      my $list = $request->{$field};
      $n += ref($list) eq 'ARRAY' ? scalar(@$list) : 0;
    }
    return $n;
  }
  my $n = 0;
  for my $part (@{ $request->parts }) {
    next if $part->is_multipart;
    my $disposition = $part->headers->content_disposition // next;
    my (undef, $is_file) = Langertha::Skeid::Protocol::Audio->disposition_names($disposition);
    $n++ if $is_file;
  }
  return $n;
}


sub pages {
  my ($class, $payload, $res) = @_;
  return unless ref($payload) eq 'HASH';
  return unless $res && $res->is_success;
  return unless ($res->headers->content_type // '') =~ m{json}i;
  my $document = $payload->{document};
  return unless ref($document) eq 'HASH';

  my $content = $document->{json_content};
  if (defined($content) && !ref($content) && length($content)) {
    return if length($content) > $MAX_PARSE_BYTES;
    $content = eval { decode_json($content) };
  }
  return unless ref($content) eq 'HASH';

  my $pages = $content->{pages};
  my $count = ref($pages) eq 'HASH'  ? scalar(keys %$pages)
            : ref($pages) eq 'ARRAY' ? scalar(@$pages)
            :                          return;
  return $count > 0 ? $count : undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Documents - The document conversion routes of docling-serve -- relayed, the pages read off the answer

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Serves C<POST /v1/convert/file> and C<POST /v1/convert/source>, the synchronous calls of
docling-serve, under docling's own paths so that a docling client only changes its base URL. They
are B<relayed routes> (ADR 0021, ADR 0028): the node's endpoint of the same name gets the request
in the shape the client sent it, and its answer -- JSON, or a zip when several documents or
outputs come back -- goes back untouched. This module translates nothing. It holds what Skeid has
to know about that wire all the same, and it is the only place that knows it: the routes, the
request fields that make a node fetch from a URL, where an answer says how many pages it was, and
the two node options (C<kind>, C<api_key_header>) the route family brings.

A docling request has no C<model>. The route is planned over the nodes of kind C<documents>, under
the routing key L</routing_key>, which a key's policy grants like a model name (ADR 0008, 0028).

Everything here is a class method.

=head2 routes

  my @paths = Langertha::Skeid::Protocol::Documents->routes;

The client paths of the documents routes, sorted: C</v1/convert/file> and C</v1/convert/source>.

=head2 upstream_path

The path below a node's URL a client path is relayed to (C</convert/file>), or C<undef> for a path
that is not a documents route.

=head2 api_format

The C<api_format> of a documents event: C<docling>.

=head2 routing_key

The name the route is planned, authorised and reported under: C<documents>. See L</DESCRIPTION>.

=head2 kinds

  my @kinds = Langertha::Skeid::Protocol::Documents->kinds;   # ('documents')

The values a node's C<kind> can take besides the default C<chat>, sorted.

=head2 normalize_kind

  my $kind = Langertha::Skeid::Protocol::Documents->normalize_kind($node{kind});

A node's C<kind> as it is kept: lowercased and trimmed; the empty string for none or C<chat>,
which is a chat node (the default, and what every node was before the option). Croaks on any other
value than L</kinds>, so a misspelled kind fails the config load instead of leaving a documents
node to receive chat requests, or the reverse.

=head2 normalize_key_header

  my $header = Langertha::Skeid::Protocol::Documents->normalize_key_header($node{api_key_header});

The header a node wants its key in, as it is kept: the empty string for none -- the key goes in
C<Authorization: Bearer>, as for every node -- also for C<Authorization> itself, the one header
that is spelled with C<Bearer>. Any other name is the header the raw key is sent in
(C<X-Api-Key> for docling-serve). Croaks unless the name is a token of RFC 7230, so no value can
carry a line break into the upstream request.

=head2 max_parse_bytes

The largest answer, in bytes, Skeid decodes to read C<pages> off it (8 MiB). The proxy passes it
to the relay, which leaves a larger answer undecoded.

=head2 form_remote_fields

  my ($names, $problem) = Langertha::Skeid::Protocol::Documents->form_remote_fields($req->content);

The remote-source fields of a multipart form (C<callbacks>, C<http_sources>, and C<sources>,
C<target>, which carry addresses too), by the name the client spelled them -- each once. The part
names are read as Audio's C<form_fields> reads them, liberally, and a part that carries a file
name counts as well: a node's parser may take it for the field. C<$problem> is a reason to refuse
the whole form (a nested multipart, a name in the C<name*> notation), else C<undef>.

=head2 json_remote_fields

  my $names = Langertha::Skeid::Protocol::Documents->json_remote_fields($decoded, $bytes);

The remote-source fields of a decoded C</v1/convert/source> body: C<http_sources> and
C<callbacks> when present and not empty, C<sources> when an entry is anything but a file source
(C<kind: file>, or an inline C<base64_string>), C<target> when it is not a C<kind> C<inbody> or
C<zip> -- an object naming an address to put the result to. Also, by the raw C<$bytes>, a field
the body names more than once: two parsers may pick different ones, and the one Skeid reads must
not hide the one the node reads. Returns the names, each once, sorted.

=head2 document_count

  my $n = Langertha::Skeid::Protocol::Documents->document_count($decoded);   # a source body
  my $n = Langertha::Skeid::Protocol::Documents->document_count($content);   # a parsed form

How many input documents a request carries: the file parts of a form, or the entries of a source
body's C<file_sources>, C<http_sources> and C<sources>.

=head2 pages

  my $pages = Langertha::Skeid::Protocol::Documents->pages($payload, $res);

The page count of a converted document, off the decoded answer, or C<undef> when the answer does
not say. It is read from C<document.json_content.pages> -- the C<DoclingDocument> keeps one entry
per page, keyed by page number -- and only from a successful JSON answer: not from a zip, which
is not decoded at all, and not from an answer past L</max_parse_bytes>, which the relay did not
decode. C<json_content> may be the object or, in some versions, a string holding it. A document
format without pages (C<pages> empty or absent) says nothing: no C<pages> rather than a zero
nobody measured.

The cost is one decode of the answer, which the relay does for every JSON answer anyway, bounded
by L</max_parse_bytes>; nothing is decoded a second time except a C<json_content> that is a string.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy>, L<Langertha::Skeid::Protocol::Audio>, ADR 0021, ADR 0028

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
