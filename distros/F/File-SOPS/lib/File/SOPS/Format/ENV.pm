package File::SOPS::Format::ENV;
# ABSTRACT: dotenv (.env) format handler for SOPS
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use File::SOPS::Comment;
use File::SOPS::Encrypted;
use File::SOPS::Format::ENV::Ordered;
use File::SOPS::Metadata;
use File::SOPS::Metadata::Flat;
use namespace::clean;

# Same reason as in the other two handlers: every frame between a caller and
# this module is this distribution's own, so a refusal raised here reported a
# line inside File::SOPS rather than the line the caller wrote encrypt() or
# emit() on. See the note in File::SOPS::Format::JSON.
our @CARP_NOT = qw( File::SOPS File::SOPS::Encrypted );

# THE COMMENT SLOT, and it is not a name -- it is the PATH sops authenticates a
# comment under.
#
# Measured against sops 3.13.3: every comment leaf in an env document decrypts
# under the AAD `:` and under nothing else, which is _path_to_aad([ '' ]) --
# an empty key component. (The same holds for a top-level comment in a YAML
# document; a comment inside `map:` is `map:` and inside `list:` is `list:`.
# Go joins the path with ':' and appends one, so the root is ':' where this
# distribution's _path_to_aad answers '' for a genuinely empty path -- a
# difference no YAML or JSON document can reach, because their leaves are
# never at the root.)
#
# So a comment cannot live under an invented key: any other spelling changes
# the AAD and the leaf stops decrypting. It cannot live in a mapping VALUE slot
# either -- File::SOPS::_encrypt_tree refuses that, because sops reads such a
# document at exit 0 and writes Go's comment struct into the key (docs/adr/0041,
# measurement 7). What is left is a sequence under the empty key, and a sequence
# adds no path component, so every element authenticates under `:` exactly as
# sops writes it.
our $COMMENT_KEY = '';

# ONE Flat object for the whole handler, and the only spelling of `sops_` in
# this file. is_metadata_key and flatten have to agree about the prefix, and
# the way they stay agreeing is by being the same string in one place
# (docs/adr/0022).
my $FLAT = File::SOPS::Metadata::Flat->new(prefix => 'sops_');


# THE ONE LINE SCANNER. parse() and parse_in_document_order() both go through
# it, deliberately: the second has to classify every line exactly as the first
# does or the shapes it returns cannot line up with the tree the MAC walk holds
# (docs/adr/0036, condition 1). A second copy of "what is a comment, what is a
# key, where does the metadata start" is how those two drift.
#
# Faithful to the store's own reader, measured: only a truly EMPTY line is
# skipped (a line of blanks is refused), a `#` first byte is a comment whatever
# follows, the key is everything before the FIRST `=`, and a line with no `=`
# is an error. Nothing is trimmed anywhere.
sub _scan {
    my ($class, $content) = @_;

    my @items;
    my $lineno = 0;
    for my $line (split /\n/, $content, -1) {
        $lineno++;
        next unless length $line;

        if (substr($line, 0, 1) eq '#') {
            push @items, {
                kind => 'comment',
                text => substr($line, 1),
                line => $lineno,
            };
            next;
        }

        my $eq = index($line, '=');
        # The line is NOT quoted into the message: an unreadable line in an
        # encrypted document is still the document's content.
        croak "line $lineno is neither a comment nor a KEY=VALUE pair: it has "
            . "no '=' and does not start with '#'. sops refuses the same line "
            . "with 'invalid dotenv input line'"
            if $eq < 0;

        my $key = substr($line, 0, $eq);
        push @items, {
            kind  => ($FLAT->is_metadata_key($key) ? 'metadata' : 'data'),
            key   => $key,
            value => substr($line, $eq + 1),
            line  => $lineno,
        };
    }

    return \@items;
}

# The wire is UTF-8 bytes and this library's boundary is characters, so every
# key, value and comment crossing in gets decoded exactly once -- the crossing
# YAML::XS and Cpanel::JSON::XS(utf8) do for the other two formats, and the one
# the emitters below undo with an unconditional encode (docs/adr/0003).
#
# A refusal rather than a silent pass-through of the bytes: leaving them would
# make the very next emit double-encode them, so the document would fail its
# own MAC with no wrong byte anywhere to point at. utf8::decode leaves the
# string untouched when it fails.
sub _characters {
    my ($bytes, $what) = @_;

    my $chars = $bytes;
    croak "$what is not valid UTF-8, and a dotenv document has no other way to "
        . "say what its bytes mean. Both other parsers here refuse the same "
        . "document; sops, whose strings are byte slices, reads it"
        unless utf8::decode($chars);

    return $chars;
}

# The bytes a key goes onto the wire as. The value's half of this is
# Encrypted::value_to_bytes, which encodes the same way and for the same
# reason; a key has no type ladder to go through, so it is the encode alone.
sub _key_bytes {
    my ($key) = @_;
    my $bytes = $key;
    utf8::encode($bytes);   # unconditional: no-op for ASCII, correct for the rest
    return $bytes;
}

sub parse {
    my ($class, $content) = @_;
    croak "content required" unless defined $content;

    my (%data, %flat, @comments);

    for my $item (@{ $class->_scan($content) }) {
        my $kind = $item->{kind};

        if ($kind eq 'comment') {
            push @comments, _comment_leaf($item);
            next;
        }

        if ($kind eq 'metadata') {
            croak "the flat metadata key '$item->{key}' is set twice "
                . "(line $item->{line})"
                if exists $flat{ $item->{key} };
            $flat{ $item->{key} } = $item->{value};
            next;
        }

        my $key = _characters($item->{key}, "the key on line $item->{line}");

        croak "line $item->{line} has an EMPTY key, which is where this "
            . "handler keeps the document's comments -- they authenticate "
            . "under that path and cannot be moved to another one. sops reads "
            . "such a document, this one cannot represent it. Give the entry a "
            . "name"
            if $key eq $COMMENT_KEY;

        croak "the key '$key' is set twice (line $item->{line}). sops keeps "
            . "both entries -- its tree is an ordered list, not a map -- and a "
            . "Perl hash cannot, so this document is refused rather than "
            . "silently losing one of them"
            if exists $data{$key};

        # Unescape first, decode second: that is the order the store reads in
        # (bytes, replace, string), and backslash-n is ASCII either way.
        $data{$key} = _characters(
            $FLAT->unescape_value($item->{value}),
            "the value of '$key' on line $item->{line}",
        );
    }

    $data{$COMMENT_KEY} = \@comments if @comments;

    my $metadata = %flat
        ? File::SOPS::Metadata->from_hash($FLAT->unflatten({
              map { $_ => _characters($flat{$_}, "the metadata key '$_'") }
                  keys %flat
          }))
        : undef;

    return (\%data, $metadata);
}

# ENCRYPTED or PLAINTEXT, decided by the type LABEL and not by the position.
#
# sops types a comment by position -- every `#` line is a Comment item, whatever
# it holds -- and this handler cannot, because the same method has to read a
# plaintext .env and an encrypted one. Asking for `type:comment` specifically
# (rather than "does this look encrypted at all") makes the two answers agree
# everywhere it matters: a plaintext comment whose text spells
# ENC[...,type:str] becomes an ordinary comment here as it does in sops, and is
# excluded from the digest on both sides. What is left ambiguous is a plaintext
# comment whose text is a well-formed ENC[...,type:comment] value, which is
# somebody pasting an encrypted comment leaf into a plaintext file.
sub _comment_leaf {
    my ($item) = @_;

    my $text = $item->{text};

    return $text
        if (File::SOPS::Encrypted->encrypted_type($text) // '') eq 'comment';

    # NOT unescaped: measured, a comment is verbatim in both directions, where
    # a data value is not.
    return File::SOPS::Comment->new(
        text => _characters($text, "the comment on line $item->{line}"));
}


sub parse_in_document_order {
    my ($class, $content) = @_;
    return unless defined $content;

    # Declining is safe, guessing is not: a document this handler cannot scan
    # must not turn a MAC check into an error the caller reads as corruption.
    # parse() will raise the real message a moment later if the document is
    # being read at all.
    my $items = eval { $class->_scan($content) } or return;

    my %doc;
    tie %doc, 'File::SOPS::Format::ENV::Ordered';

    for my $item (@$items) {
        if ($item->{kind} eq 'comment') {
            # The bucket takes the position of the FIRST comment, which is
            # where parse() would put it in a hash that had positions. Only the
            # shape is read, so what matters is that the sequence is here and
            # is as long as the tree's.
            $doc{$COMMENT_KEY} = [] unless ref $doc{$COMMENT_KEY} eq 'ARRAY';
            push @{ $doc{$COMMENT_KEY} }, undef;
            next;
        }

        next if $item->{kind} eq 'metadata';   # the handler drops it, condition 3

        my $key = $item->{key};
        utf8::decode($key);

        # Both of these are documents parse() refuses. Decline rather than
        # answer for them.
        return if $key eq $COMMENT_KEY;
        return if exists $doc{$key};

        $doc{$key} = undef;
    }

    return \%doc;
}


sub serialize {
    my ($class, %args) = @_;
    my $data     = $args{data}     // croak "data required";
    my $metadata = $args{metadata} // croak "metadata required";

    # emit() refuses a top-level sops_ key, so the metadata written below
    # cannot be shadowed by one -- which is the same job Format::JSON's
    # `sops` refusal does, moved to where this format's collision is.
    my $out = $class->emit($data);

    # flatten() has already prefixed the keys and escaped the values, in the
    # order sops writes them: maps sorted, lists ascending. The section goes
    # LAST, where sops puts it; line order is not load-bearing (measured: a
    # file with its sops_ lines reversed still decrypts), and the metadata is
    # excluded from the MAC structurally.
    $out .= _key_bytes($_->[0]) . '=' . _value_bytes($_->[1]) . "\n"
        for $FLAT->flatten($metadata->to_hash);

    return $out;
}

# The metadata's values cross the same boundary the data's do -- characters in
# the model, UTF-8 on the wire. escape_value has already run and only touches
# newlines, so the order of the two is free.
sub _value_bytes {
    my ($value) = @_;
    my $bytes = $value;
    utf8::encode($bytes);
    return $bytes;
}


# The one place this distribution turns a Perl tree into a dotenv document.
# serialize() is this plus the metadata section, and File::SOPS::_serialize_
# plaintext -- what decrypt_file writes and what edit hands the editor -- is
# this on its own.
#
# So this is ON THE WIRE PATH and is not a plaintext formatting knob. In
# particular the sorted key order below is not a diff-readability choice: the
# MAC's encrypt side hashes leaves in `sort keys` order, and that is the
# document's own order only because this loop sorts. Measured on a file sops
# wrote, whose order is the document's: sorting its data lines makes `sops -d`
# fail at exit 51.
sub emit {
    my ($class, $data) = @_;
    croak "data required" unless defined $data;
    croak "a dotenv document is a flat mapping of keys to values, so emit "
        . "needs a HashRef, not " . (ref($data) ? ref($data) . " reference"
                                                : "a scalar")
        unless ref $data eq 'HASH';

    my $out = '';

    for my $key (sort keys %$data) {
        # The empty key sorts first, so the comment block heads the document.
        if ($key eq $COMMENT_KEY) {
            $out .= $class->_comment_lines($data->{$key});
            next;
        }

        croak "$key: a top-level key starting with '" . $FLAT->prefix . "' is "
            . "where the SOPS metadata section goes in a dotenv document, so "
            . "this entry would be read back as metadata instead of as a "
            . "value. sops refuses such a document too (exit 203). Rename the "
            . "entry"
            if $FLAT->is_metadata_key($key);

        $out .= _key_bytes($key) . '=' . _leaf_line($data->{$key}, $key) . "\n";
    }

    return $out;
}

sub _comment_lines {
    my ($class, $bucket) = @_;

    croak "'': the empty key is reserved for this document's comments and "
        . "holds a sequence of them; a "
        . (ref($bucket) ? lc(ref $bucket) . " reference" : "scalar")
        . " here has no line to be written as. See the Comments section of "
        . "File::SOPS::Format::ENV"
        unless ref $bucket eq 'ARRAY';

    my $out = '';
    $out .= '#' . _comment_text($_) . "\n" for @$bucket;
    return $out;
}

sub _comment_text {
    my ($comment) = @_;

    # An encrypted comment is already the line's text.
    return $comment
        if !ref $comment
        && (File::SOPS::Encrypted->encrypted_type($comment) // '') eq 'comment';

    croak "'': the empty key holds this document's comments, and "
        . (ref($comment)  ? "a " . lc(ref $comment) . " reference"
         : defined $comment ? "a plain scalar"
         :                    "an undef")
        . " is not one. Put File::SOPS::Comment objects there, or leave the "
        . "key out"
        unless File::SOPS::Encrypted->is_comment($comment);

    my $text = File::SOPS::Encrypted->value_to_bytes($comment);

    # sops neither escapes nor unescapes a comment (measured: `a\nb` survives
    # as `a\nb`, where the same bytes in a data value come back as a newline),
    # so a comment holding a real newline has no spelling in this format at
    # all -- written out it would become a second line that is not even a valid
    # dotenv line. docs/adr/0008's rule, applied to the one leaf whose text
    # goes to the file unescaped.
    croak "'': a comment holding a newline cannot be written into a dotenv "
        . "document -- a comment is one line, and sops does not escape a "
        . "comment the way it escapes a value (measured). Split it into one "
        . "comment per line"
        if index($text, "\n") >= 0;

    return $text;
}

sub _leaf_line {
    my ($value, $key) = @_;

    # An ENCRYPTED leaf is an ENC[...] string by the time the emitter sees it.
    # Its alphabet is base64 plus []:,= -- no backslash, no newline -- so the
    # store's escape is the identity on it (measured), and the guard below has
    # nothing to catch. docs/adr/0030: the guard is for unencrypted leaves and
    # for the write direction, and refusing an encrypted one would reject
    # documents that work.
    return $value
        if !ref $value && File::SOPS::Encrypted->is_encrypted($value);

    croak "$key: cannot write a " . lc(ref $value) . " into a dotenv document; "
        . "the format is one level deep and has no spelling for a nested "
        . "value. sops refuses the same tree with 'cannot use complex value "
        . "in dotenv file'"
        if ref $value && !blessed($value);

    croak "$key: a comment cannot be a mapping value. In a dotenv document a "
        . "comment is a line of its own, which this handler keeps under the "
        . "empty key -- see the Comments section of File::SOPS::Format::ENV"
        if File::SOPS::Encrypted->is_comment($value);

    # docs/adr/0035: in an untyped store an unencrypted leaf is written as
    # exactly the bytes the digest covers. ASKED of the single source of truth
    # rather than re-derived, so the emitter and the digest cannot drift apart.
    my $bytes   = File::SOPS::Encrypted->value_to_bytes($value);
    my $escaped = $FLAT->escape_value($bytes);

    # docs/adr/0030, verbatim. It asks the escape instead of testing for a
    # character, because a second spelling of the rule is how a guard and the
    # thing it guards drift.
    croak "$key: cannot write this value into a dotenv document; the format's "
        . "newline escape does not round-trip it. The value holds the two "
        . "characters backslash and 'n', which the store's reader turns into a "
        . "newline, so the document would say one thing and its own MAC "
        . "another. sops writes such a file at exit 0 and then refuses to read "
        . "it (MAC mismatch, exit 51)"
        unless $FLAT->unescape_value($escaped) eq $bytes;

    return $escaped;
}


sub detect_content {
    my ($class, $content) = @_;
    return 0 unless defined $content;

    # BOTH halves of what an encrypted dotenv document is, because either alone
    # is too weak: a YAML block scalar can hold a line that spells
    # `sops_version=3.13.3`, and every plaintext .env has no metadata to find.
    my $metadata = 0;
    for my $line (split /\n/, $content, -1) {
        next unless length $line;
        next if substr($line, 0, 1) eq '#';

        my $eq = index($line, '=');
        return 0 if $eq < 0;

        $metadata = 1 if $FLAT->is_metadata_key(substr($line, 0, $eq));
    }

    return $metadata;
}


sub format_name { 'env' }


sub file_extensions { qw(env) }


sub detect {
    my ($class, $filename) = @_;
    return 1 if $filename =~ /\.env$/i;
    return 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Format::ENV - dotenv (.env) format handler for SOPS

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Format::ENV;

    # Parse a dotenv document with its flat SOPS metadata
    my ($data, $metadata) = File::SOPS::Format::ENV->parse($env_content);

    # Serialize data with SOPS metadata
    my $env = File::SOPS::Format::ENV->serialize(
        data     => $encrypted_data,
        metadata => $metadata_obj,
    );

    # Check if a filename is a dotenv file
    if (File::SOPS::Format::ENV->detect('secrets.env')) {
        # It is
    }

=head1 DESCRIPTION

The dotenv (C<.env>) format handler for L<File::SOPS>, which sops calls
C<dotenv>. The document is a flat list of lines:

    #ENC[AES256_GCM,data:...,type:comment]
    FOO=ENC[AES256_GCM,data:...,type:str]
    EMPTY=
    plain_unencrypted=visible
    sops_age__list_0__map_enc=-----BEGIN AGE ENCRYPTED FILE-----\nYWdl...\n
    sops_lastmodified=2026-08-21T08:47:47Z
    sops_mac=ENC[AES256_GCM,data:...,type:str]
    sops_unencrypted_suffix=_unencrypted
    sops_version=3.13.3

B<The whole format is measured, not read out of the Go source.> Everything
below was taken from sops 3.13.3 on one document at a time.

=head2 The line

C<KEY=VALUE>, no spaces around the C<=>, the key being everything up to the
B<first> C<=>. A key may hold spaces, a C<#>, an C<=>-free prefix of anything
at all, and may be empty; a value may hold C<=>, C<#>, quotes and leading or
trailing whitespace, all of which are part of it -- B<quotes are not stripped>,
so C<QUOTED="hello world"> is a value five characters longer than
C<hello world>.

A line whose first byte is C<#> is a B<comment>, whatever follows. An B<empty>
line is skipped; a line of blanks is not -- sops refuses it with
C<invalid dotenv input line>, and so does L</parse>. So is a line that is
neither.

=head2 What sops does to a document it writes

Blank lines are B<dropped>. Comments keep their place among the data lines.
Values are encrypted one per line, with C<type:str> for everything an env
B<source> holds (the store has no syntax for a type, so every value it parses
is a string -- ADR 0002 reproduces that for free) and with whatever type the
value had when the tree came from somewhere else: a YAML source written out
with C<--output-type dotenv> carries C<type:int>, C<type:float>, C<type:bool>
and C<type:time>, and sops reads every one of them back. An empty value is not
encrypted and stays C<KEY=>. The flat C<sops_*> metadata goes last.

=head2 Where this handler differs from sops, and why

=over 4

=item * B<Keys are written sorted.> sops writes them in document order. The
MAC's encrypt side hashes in C<sort keys> order, so a document this library
writes has to B<be> in that order or it fails its own digest -- the same
property L<File::SOPS::Format::YAML> and L<File::SOPS::Format::JSON> get from
their emitters, and the reason C<t/05-format-key-order.t> exists. Measured:
sorting the data lines of a file sops wrote makes C<sops -d> fail at exit 51,
because the digest covers the values in the order the file lists them.

=item * B<Comments are written first,> as a block, because the empty key sorts
first. Their position among the data lines is B<not> preserved -- it cannot be:
the tree is a Perl hash, its order is gone before any emitter sees it, and the
data keys are being reordered anyway. Measured: moving every comment line of a
file sops wrote to the top leaves C<sops -d> at exit 0, because no comment is
in the digest.

=item * B<A value the newline escape cannot carry is refused> rather than
written. See L</The escape, and the one value that is refused>.

=item * B<A boolean, a null and an integral float are written as the bytes the
digest covers>, where sops writes a display form and then cannot read its own
file. See L</An unencrypted leaf is written as its digest bytes>.

=back

=head2 The escape, and the one value that is refused

The env store writes a real newline in a data value as the two characters
backslash and C<n>, and unescapes the same on the way in. Nothing else is
touched -- not a tab, not a carriage return, and B<not a backslash>, so the
transform is not injective: a value that already holds backslash-C<n> is
written identically to one holding a newline, and comes back as the newline.

The digest covers the value B<before> the escape (measured: two documents with
byte-identical data lines and different C<sops_mac> plaintexts), so sops writes
such a file at exit 0 and then refuses to read it, C<MAC mismatch>, exit 51.

This handler B<refuses that value when it writes>, and refuses nothing on the
way in -- reading unescapes unconditionally, exactly as sops does. The rule
asks the escape rather than testing for a character, so that it cannot drift
away from the escape it guards:

    my $bytes   = File::SOPS::Encrypted->value_to_bytes($leaf);
    my $escaped = $flat->escape_value($bytes);
    croak ... unless $flat->unescape_value($escaped) eq $bytes;

Only leaves that reach the document B<verbatim> can trigger it: an encrypted
leaf is an C<ENC[...]> string whose alphabet holds neither a backslash nor a
newline, so the escape is the identity on it. See
L<docs/adr/0030|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0030-an-env-value-the-escape-cannot-carry-is-refused-not-written.md>.

A B<comment's> text is not escaped and not unescaped -- measured, a comment
holding C<a\nb> comes back as C<a\nb> where a data value holding the same bytes
comes back as a newline. A comment text with a real newline in it therefore has
no spelling in this format and is refused as well.

=head2 An unencrypted leaf is written as its digest bytes

A leaf the encryption rules exclude reaches the document as plain text, and the
env store has no type label for it, so the reader hands the digest the literal
text of the line. The condition for such a document to verify is exactly

    the text written == File::SOPS::Encrypted->value_to_bytes($leaf)

and that is what this emitter writes -- it asks the single source of truth
rather than re-deriving anything. sops breaks the condition in three places,
writing a display form where its own digest covers the wire form: a boolean
(C<true> written, C<True> digested), a null (C<< <nil> >> written, the empty
string digested) and a float whose Go display form is not its canonical
positional decimal (C<1.0>, C<1E+20>, C<-0.0>). Each is a file sops wrote at
exit 0 and refused to read in the same run.

So this handler writes C<True>, C<False>, the empty string, C<1>,
C<100000000000000000000> and C<-0> where sops writes C<true>, C<false>,
C<< <nil> >>, C<1.0>, C<1E+20> and C<-0.0>. B<The digest does not move>: those
are the bytes sops's own C<sops_mac> already covers, every one of them is a
line sops itself writes for the corresponding string, and each replaces a line
that makes the whole file unreadable. Nothing is refused for its type. See
L<docs/adr/0035|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0035-an-untyped-stores-unencrypted-leaf-is-written-as-the-bytes-the-digest-covers.md>.

One consequence is worth stating plainly: B<an unencrypted value's type is
erased by the round trip.> C<42> comes back as the string C<"42">, a boolean as
C<"True">, an C<undef> as C<''>. sops does the same to every unencrypted value
it reads. A caller who needs the type preserved puts the value in an
B<encrypted> slot, where the C<type:> label carries it.

=head2 Comments

For YAML and JSON a comment leaf is the exception. B<For an env document it is
the ordinary case>, and this handler reads and writes it rather than refusing
it: a C<.env> with comments goes through C<decrypt_file> and C<edit> without
losing them.

A comment lives in the tree under the empty key, as a sequence:

    {
        ''  => [ File::SOPS::Comment->new(text => ' a comment'), ... ],
        FOO => 'bar',
    }

That is not a convention this handler is free to choose -- see the note on
C<$COMMENT_KEY> in the source. The empty key is B<reserved> for it: L</parse>
refuses a document with an empty data key rather than losing one of the two,
and L</emit> refuses anything in that slot that is not a comment.

Comments are B<not in the MAC>, in any format and in both MAC modes; the
exclusion is C<File::SOPS::_digested_leaves>'s and this handler neither has to
do anything about it nor may. See
L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>.

=head2 What this handler cannot carry

=over 4

=item * B<Nesting.> The format is one level deep. sops refuses a nested value
itself -- C<cannot use complex value in dotenv file; offending key db>, exit 4
-- and so does L</emit>.

=item * B<A duplicate key.> sops keeps both (its tree is an ordered list of
items, not a map) and reads them both back. A Perl hash cannot hold two, so
L</parse> refuses rather than silently keeping the last one.

=item * B<A top-level key starting with C<sops_>.> That is where the metadata
goes; sops refuses such a document too, at exit 203, with the same message it
uses for a top-level C<sops> entry in YAML.

=item * B<Bytes that are not valid UTF-8.> This distribution's boundary is
character strings and its emitters encode unconditionally (ADR 0003), so a data
key or value that will not decode is refused at the line rather than written
back double-encoded. Both sibling parsers refuse the same document
(C<invalid trailing UTF-8 octet> from YAML::XS, C<malformed UTF-8 character>
from Cpanel::JSON::XS); sops, whose strings are byte slices, reads it.

=back

=head2 parse

    my ($data, $metadata) = File::SOPS::Format::ENV->parse($env_string);

Class method. Parses a dotenv document and returns the data tree and, if the
document carries a C<sops_*> section, a L<File::SOPS::Metadata> object built
from it; otherwise C<undef> for the metadata, which is what a plaintext
C<.env> gives.

The tree is B<flat>: one mapping of scalars, plus the comment sequence under
the empty key described in L</Comments>. Values are unescaped
(L<File::SOPS::Metadata::Flat/unescape_value>) and decoded from UTF-8;
comments are decoded and B<not> unescaped.

Dies on a line that is neither a comment nor C<KEY=VALUE>, on a duplicate key,
on an empty key, on a repeated flat metadata key, on a metadata section
L<File::SOPS::Metadata::Flat/unflatten> cannot rebuild, and on a key or value
that is not valid UTF-8. Each message names the line.

=head2 parse_in_document_order

    my $ordered = File::SOPS::Format::ENV->parse_in_document_order($content);

Reparses C<$content> for its B<key order only> and returns the document as a
HashRef whose keys iterate in the order the file writes them, with the
C<sops_*> metadata removed. Returns nothing when the text cannot be read that
way.

This is the half of MAC verification that only a format handler can supply: an
env document sops wrote is in B<document> order, and without this the digest
would be taken in sorted key order and every such file would fail to verify.
The values are C<undef> -- only the shape is read, never a value -- and the
comment sequence is present with the right length so that the shape matches
L</parse>'s. The order comes from a tied hash, which is the whole of what
"order preserving" means for a format whose parser has none. See
L<docs/adr/0036|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0036-the-order-preserving-reparse-is-asked-of-the-format-handler.md>.

=head2 serialize

    my $env = File::SOPS::Format::ENV->serialize(
        data     => \%data,
        metadata => $metadata_obj,
    );

Class method. L</emit> plus the flat C<sops_*> metadata section, appended at
the end as sops writes it.

The C<data> parameter must be a HashRef and C<metadata> a
L<File::SOPS::Metadata> object. Dies through L</emit> if the data carries a
top-level key starting with C<sops_>, which is where the section goes.

=head2 emit

    my $env = File::SOPS::Format::ENV->emit(\%data);

Class method. Turns a tree into a dotenv document B<without> a metadata
section: the comment block first, then C<KEY=VALUE> lines in sorted key order,
each terminated by a newline.

This is the emitter L</serialize> uses and the one C<File::SOPS::decrypt_file>
and C<File::SOPS::edit> write plaintext with, so B<it is on the wire path>. In
particular the sorted key order is not a formatting preference -- see the note
in L</Where this handler differs from sops, and why>.

An encrypted leaf is written verbatim. Everything else is written as
C<< File::SOPS::Encrypted->value_to_bytes >> (see
L</An unencrypted leaf is written as its digest bytes>), escaped for the
format, and refused where that escape does not round-trip (see
L</The escape, and the one value that is refused>).

Dies on a nested value, on an unblessed reference, on a comment in a value
slot, on a top-level key starting with C<sops_>, and on anything in the empty
key that is not a comment. A B<blessed> leaf is written as its stringification,
which is what the digest covers for it -- where L<File::SOPS::Format::YAML> and
L<File::SOPS::Format::JSON> refuse one, because their emitters would write it
as something else (C<docs/adr/0008>). Here document and digest cannot disagree:
they are the same call.

=head2 detect_content

    if (File::SOPS::Format::ENV->detect_content($encrypted)) { ... }

Class method. True when C<$content> is an B<encrypted> dotenv document: every
non-empty line is a comment or a C<KEY=VALUE> pair, B<and> at least one of the
keys belongs to the flat metadata section.

Both halves are needed. A YAML block scalar can hold a line that spells
C<sops_version=3.13.3>, and a plaintext C<.env> carries no metadata at all --
which is why this answers for encrypted content only, and why C<File::SOPS>
asks it only where the content is known to be encrypted. Plaintext is
recognised by its file name.

=head2 format_name

Returns C<'env'>.

=head2 file_extensions

Returns a list of file extensions: C<('env')>.

=head2 detect

    if (File::SOPS::Format::ENV->detect($filename)) {
        # File is a dotenv file based on extension
    }

Class method to detect if a filename is a dotenv file based on extension.

Returns true if the filename ends with C<.env> (case-insensitive), which
covers a bare C<.env> as well as C<secrets.env> -- the same two shapes Go's
C<filepath.Ext> gives sops.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<File::SOPS::Metadata::Flat> - the flat C<sops_*> metadata encoding
this format carries, and the escape it shares with the data values

=item * L<File::SOPS::Comment> - the comment leaf

=item * L<File::SOPS::Format::ENV::Ordered> - the tied hash that carries the
document order this handler's C<parse_in_document_order> returns

=item * docs/adr/0030 - the value that is refused rather than written

=item * docs/adr/0035 - what an unencrypted leaf is written as

=item * docs/adr/0036 - the order-preserving parse, and the contract above

=item * docs/adr/0041 - the comment leaf, and why it is not in the digest

=item * docs/adr/0045 - this handler: the whole document measured, the comment
key, the sorted emitter and the nine refusals

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
