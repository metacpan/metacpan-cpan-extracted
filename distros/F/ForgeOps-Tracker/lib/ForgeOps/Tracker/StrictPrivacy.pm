package ForgeOps::Tracker::StrictPrivacy;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use Scalar::Util qw(blessed);

# What the configuration's strict_privacy changes in everything this client sends, for apps that
# can't let personal or health data leave their own servers. With it on, only structured facts go
# out (the error's class, its stack frames, release, environment, server, which request it
# happened in, timings and counts); free text, which is where a name, an email or a diagnosis
# hides, never leaves this process: no error message, no breadcrumbs, no endpoint, no SQL
# statement, no source context, no user email or username, and only the context/tag keys listed in
# privacy_allowed_fields.
#
# The same rules as the server's own StrictPrivacy (app/services/strict_privacy.rb), which applies
# them again on arrival when the project's Strict privacy setting is on;
# sdks/strict_privacy_vectors.json pins the results both have to agree on, byte for byte.
our @EXPORT_OK = qw(normalize_message message_fingerprint event span span_name transaction_name strict_path);

use constant FINGERPRINT_LENGTH => 32;

# ASCII "word" characters; boundaries are defined against these, the same in every SDK. Spelled
# out as classes rather than \w, so Perl's own idea of a word (Unicode letters, digits in other
# scripts) never changes the result on a string Perl holds as characters.
my $WORD          = 'A-Za-z0-9_';
my $HEX_OBJECT_ID = qr/0x[0-9a-fA-F]{4,}/;
my $UUID          = qr/(?<![$WORD])[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(?![$WORD])/;
my $NUMBER        = qr/(?<![$WORD])[0-9]+(?![$WORD])/;

# Span data that's structure, not content: the masked statement and which database it ran on.
my @SPAN_DATA_KEYS = ('db.statement', 'db.system');
my $HTTP_METHOD    = qr/\A(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(\S+)/i;
my $SCHEME         = qr{\A[a-z][a-z0-9+.-]*://}i;
my $ROUTE_PARAMETER = qr/\A(?::.+|\{.+\}|<.+>|\[.+\]|\*.*)\z/;

# Error event fields that are never sent, and the per-frame source context.
my @EVENT_FIELDS_DROPPED  = qw(message breadcrumbs endpoint sql_statement);
my @SOURCE_CONTEXT_FIELDS = qw(context_line pre_context post_context);

# normalize_message($message): the message with hex object ids, UUIDs and standalone numbers
# replaced, in that order.
sub normalize_message {
    my ($message) = @_;
    my $text = defined $message ? "$message" : '';
    $text =~ s/$HEX_OBJECT_ID/0x/g;
    $text =~ s/$UUID/<uuid>/g;
    $text =~ s/$NUMBER/<n>/g;
    return $text;
}

# message_fingerprint($message): lets ForgeOps group errors without ever seeing their message: the
# first 32 hex characters of the SHA-256 of the normalized message's UTF-8 bytes, so two messages
# that differ only in ids hash the same, and nothing about the text can be read back from it. The
# message is encoded the same way encode_json encodes it on its way to the server.
sub message_fingerprint {
    my ($message) = @_;
    my $bytes = normalize_message($message);
    utf8::encode($bytes);
    return substr(sha256_hex($bytes), 0, FINGERPRINT_LENGTH);
}

# event(\%payload, \@allowed_fields): an error event payload (EventBuilder::build's shape) reduced
# to what strict privacy sends. message is sent as "" alongside message_fingerprint, exactly what
# the server stores for a strict project.
sub event {
    my ($payload, $allowed_fields) = @_;
    my %reduced = %$payload;
    delete @reduced{@EVENT_FIELDS_DROPPED};
    $reduced{message}             = '';
    $reduced{message_fingerprint} = message_fingerprint($payload->{message});
    $reduced{transaction_name}    = transaction_name($payload->{transaction_name});
    $reduced{context}             = _allowed($payload->{context}, $allowed_fields);
    $reduced{tags}                = _allowed($payload->{tags}, $allowed_fields);
    $reduced{user}                = _user($payload->{user});
    $reduced{backtrace} = [
        map {
            my %frame = %$_;
            delete @frame{@SOURCE_CONTEXT_FIELDS};
            \%frame;
        } @{ $payload->{backtrace} || [] }
    ];
    delete $reduced{$_} for grep { !defined $reduced{$_} } keys %reduced;
    return \%reduced;
}

# span(\%span): a trace's span: an outbound call's name keeps its method and host, never its path
# or query, and its data keeps only the masked statement and database system. data is left out
# entirely when nothing is left of it, the same as the server does.
sub span {
    my ($span) = @_;
    my %reduced = %$span;
    $reduced{name} = span_name($span->{name});
    my $data = ref $span->{data} eq 'HASH' ? $span->{data} : {};
    my %kept = map { exists $data->{$_} ? ($_ => $data->{$_}) : () } @SPAN_DATA_KEYS;
    if (%kept) {
        $reduced{data} = \%kept;
    }
    else {
        delete $reduced{data};
    }
    delete $reduced{$_} for grep { !defined $reduced{$_} } keys %reduced;
    return \%reduced;
}

# span_name($name): "GET https://api.example.com/patients/42?x=1" or
# "GET api.example.com/patients/42" becomes "GET api.example.com". A bare path ("/patients/42"),
# or a method and a path ("GET /patients/42", what the PSGI integration names every request), has
# its ids taken out, like a page path. A name that's none of these ("OrdersController#create",
# "patients#show") is kept.
sub span_name {
    my ($name) = @_;
    return $name unless defined $name;
    return strict_path($name) if index($name, '/') == 0;
    return $name unless $name =~ $HTTP_METHOD;

    my ($method, $target) = (uc $1, $2);
    return "$method " . strict_path($target) if index($target, '/') == 0;
    my $host = _host($target);
    return "$method " . (defined $host ? $host : strict_path($target));
}

# transaction_name($name): which request something happened in: a route or a handler name is kept,
# but a raw path (PSGI's "GET /patients/42") keeps only its first segment, by the span name rule.
sub transaction_name {
    my ($name) = @_;
    return defined $name && length $name ? span_name($name) : $name;
}

# strict_path($path): A request or page path under strict privacy, with no query or fragment. A
# route template ("/patients/:id/notes", "/patients/{id}", "users/<int:id>/", "/files/*path",
# "/posts/[slug]") is kept as it is: its words are a developer's, and its parameters are already
# placeholders. A raw path keeps only its first segment, and the rest becomes ":path":
# "/patients/jane-doe/12" is "/patients/:path". Anything after the first segment of a raw path could
# name a person, and no rule can tell a name from a word ("/patients/janedoe"). A first segment that
# holds a digit or is over 40 characters is ":id" itself.
sub strict_path {
    my ($path) = @_;
    $path = defined $path ? "$path" : '';
    $path =~ s/[?#].*\z//s;
    return $path if _is_route_template($path);

    my $leading = index($path, '/') == 0 ? '/' : '';
    my @segments = grep { length } split m{/}, $path;
    return '/' unless @segments;

    my $first = $segments[0] =~ /[0-9]/ || length($segments[0]) > 40 ? ':id' : $segments[0];
    return $leading . $first . (@segments > 1 ? '/:path' : '');
}

# Whether any segment is a route parameter: ":id", "{id}", "<int:id>", "[slug]" or "*path".
sub _is_route_template {
    my ($path) = @_;
    return scalar grep { $_ =~ $ROUTE_PARAMETER } split m{/}, $path;
}

# An outbound call's host, read by hand rather than with a URL parser (an address a parser rejects
# must never be sent whole): what comes before the first "/", "?" or "#", without a scheme,
# credentials (up to the last "@", since a password can hold one) or port. Only a host when the
# address had a scheme or a port, or the name has a dot or is "localhost"; undef otherwise (a
# relative path).
sub _host {
    my ($target) = @_;
    (my $authority = $target) =~ s/$SCHEME//;
    my $scheme = $authority ne $target;
    $authority =~ s{[/?#].*\z}{}s;
    $authority =~ s/\A.*\@//s;
    my $port = $authority =~ s/:[0-9]+\z//;
    return undef unless length $authority;
    return $authority if $scheme || $port || index($authority, '.') >= 0 || lc($authority) eq 'localhost';
    return undef;
}

# Only top-level keys named in allowed_fields, and only plain values under them (a string, a
# number, or a JSON boolean); undef (left out of the payload) when nothing is left.
sub _allowed {
    my ($fields, $allowed_fields) = @_;
    my %allowed = map { ($_ => 1) } allowed_field_list($allowed_fields);
    return undef unless %allowed && ref $fields eq 'HASH';

    my %kept;
    for my $key (keys %$fields) {
        my $value = $fields->{$key};
        next unless $allowed{$key} && defined $value;
        next if ref $value && !(blessed($value) && $value->isa('JSON::PP::Boolean'));
        $kept{$key} = $value;
    }
    return %kept ? \%kept : undef;
}

# allowed_field_list($fields): privacy_allowed_fields as a list of names, whether it was set as an
# arrayref or as one comma-separated string (FORGE_OPS_PRIVACY_ALLOWED_FIELDS's own form).
sub allowed_field_list {
    my ($fields) = @_;
    my @fields = ref $fields eq 'ARRAY' ? @$fields : split /,/, (defined $fields ? $fields : '');
    return grep { length } map { (my $field = "$_") =~ s/\A\s+|\s+\z//g; $field } @fields;
}

# The user's id, as a string, and nothing else; undef when there's no id.
sub _user {
    my ($user) = @_;
    return undef unless ref $user eq 'HASH';
    my $id = $user->{id};
    return undef unless defined $id && !ref $id && "$id" =~ /\S/;
    return { id => "$id" };
}

1;
