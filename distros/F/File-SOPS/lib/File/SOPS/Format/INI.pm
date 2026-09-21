package File::SOPS::Format::INI;
# ABSTRACT: INI format handler for SOPS
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use File::SOPS::Comment;
use File::SOPS::Encrypted;
# The tied hash docs/adr/0036 requires. USED WHERE IT STANDS rather than
# copied: two copies of an order-preserving hash is exactly how ENV and INI
# drift apart, which both tickets warned about for weeks. k158 gave it a
# file of its own, so this loads the class itself where it used to load the
# whole dotenv handler to reach it.
use File::SOPS::Format::ENV::Ordered;
use File::SOPS::Metadata;
use File::SOPS::Metadata::Flat;
use namespace::clean;

# Same reason as in the other three handlers: every frame between a caller and
# this module is this distribution's own, so a refusal raised here reported a
# line inside File::SOPS rather than the line the caller wrote encrypt() or
# emit() on. See the note in File::SOPS::Format::JSON.
our @CARP_NOT = qw( File::SOPS File::SOPS::Encrypted );

# THE COMMENT SLOT, and -- as in Format::ENV -- it is not a name but the PATH
# sops authenticates a comment under. What it is NOT is the same path.
#
# Measured against sops 3.13.3, one comment in every position an ini document
# has: every comment leaf decrypts under the AAD of its SECTION and under
# nothing else -- `db:` inside `[db]`, `api:` for one written above `[api]`,
# `DEFAULT:` for one above a key that sits outside any section. Never `db::`.
#
# That is Go's own rule and not an ini quirk: sops walks a branch with the
# branch's path and a comment is an ITEM of the branch whose key is a Comment
# struct, so it contributes NO path component, where an ordinary key does. In
# a dotenv document the branch is the document root, whose path is empty, and
# `_path_to_aad([''])` spells that root as `:` -- which is why Format::ENV can
# keep its comments under a real, empty KEY and still produce the AAD sops
# wrote. Here the branch is a section and its path is NOT empty, so the same
# spelling would produce `db::`. Measured, that is the AAD of a genuine empty
# key nested in a mapping, and the leaf does not decrypt.
#
# So this key is reserved AND the walk in File::SOPS knows it: a `''` key
# holding a sequence of comments contributes no path component when the path
# is already non-empty. Nothing else in an ini document can collide with it,
# because sops refuses an empty key name outright (exit 2, `empty key name`).
# Spelled here as well as in File::SOPS ($COMMENT_BUCKET_KEY, which carries the
# walk rule) because this module is loaded FROM there and cannot read it at
# compile time. t/61 pins that the two are the same string.
our $COMMENT_KEY = '';

# The section the metadata lives in, and the one section name a data document
# may not use. sops refuses one at exit 203, with the message it gives a YAML
# document with a top-level `sops` key.
our $METADATA_SECTION = 'sops';

# Where a value outside any section goes. go-ini's own name for the implicit
# first section; sops shows it as `"DEFAULT": {}` in --output-type json and
# authenticates such a value under `DEFAULT:<key>:`, measured.
our $DEFAULT_SECTION = 'DEFAULT';

# ONE Flat object for the whole handler. The prefix is EMPTY here, where
# Format::ENV's is `sops_`: the flat scheme is the same one (docs/adr/0022),
# and an ini document separates the metadata by putting it in a section of its
# own instead of by prefixing every key.
my $FLAT = File::SOPS::Metadata::Flat->new(prefix => '');

my $ORDERED = 'File::SOPS::Format::ENV::Ordered';

# go-ini reads BOTH of these as the key/value delimiter, and takes the first
# one it finds -- measured: `host: localhost` is the key `host`, and `k := v`
# is the key `k` with the value `= v`.
my $DELIMITERS = '=:';


###############################################################################
# THE ONE LINE SCANNER
#
# parse() and parse_in_document_order() both go through it, deliberately: the
# second has to classify every line exactly as the first does or the shapes it
# returns cannot line up with the tree the MAC walk holds (docs/adr/0036,
# condition 1). A second copy of "what is a section, what is a comment, where
# does a value end" is how those two drift.
#
# It is go-ini's grammar, measured rather than read out of the source: the two
# delimiters, the continuation backslash, the inline comment, the three quote
# forms, and the fact that a comment block attaches to whatever comes NEXT.
###############################################################################

sub _scan {
    my ($class, $content) = @_;

    my @lines = split /\n/, $content, -1;
    # split with -1 keeps the empty field a trailing newline produces; it is
    # not a line of the document and would only be skipped anyway.
    pop @lines if @lines && $lines[-1] eq '';

    my @items;
    my @comment;                      # raw comment lines, waiting for a node
    my $section = $DEFAULT_SECTION;   # what a key belongs to before any header
    my $i = 0;

    while ($i <= $#lines) {
        my $lineno = $i + 1;
        my $line = $lines[$i];
        $line =~ s/\r\z//;
        $line =~ s/\A\s+//;
        $line =~ s/\s+\z//;

        if (!length $line) { $i++; next }

        if ($line =~ /\A[;#]/) {
            push @comment, $line;
            $i++;
            next;
        }

        if (substr($line, 0, 1) eq '[') {
            # The LAST ']' closes it, which is go-ini's rule and not a typo.
            my $close = rindex($line, ']');
            croak "line $lineno: a section header that is never closed. sops "
                . "refuses the same line with 'unclosed section'"
                if $close < 0;

            $section = substr($line, 1, $close - 1);
            croak "line $lineno: a section header with an EMPTY name. sops "
                . "refuses the same line with 'empty section name'"
                unless length $section;

            push @items, { kind => 'section', name => $section, line => $lineno };
            push @items, {
                kind    => 'comment',
                section => $section,
                lines   => [ splice @comment ],
                line    => $lineno,
            } if @comment;

            $i++;
            next;
        }

        my ($key, $rest) = _read_key($line, $lineno);
        # $i is advanced by the reader for a continued or multi-line value.
        my ($value, $inline) = _read_value(\@lines, \$i, $rest);

        # An inline comment goes into the SAME key's comment block, after any
        # lines above it: go-ini reads the value before it assigns the block,
        # so `port = 5432 ; note` puts `note` on `port` and not on the next
        # key. Measured -- the leaf comes back ABOVE the value it was written
        # beside, which is why the round trip is not position-preserving.
        push @comment, $inline if defined $inline && length $inline;

        push @items, {
            kind    => 'comment',
            section => $section,
            lines   => [ splice @comment ],
            line    => $lineno,
        } if @comment;

        push @items, {
            kind    => 'pair',
            section => $section,
            key     => $key,
            value   => $value,
            line    => $lineno,
        };

        $i++;
    }

    # A comment block at the end of the file is DROPPED. There is no node left
    # for it to attach to, and sops drops it too (measured).

    return \@items;
}

# go-ini's readKey. The key may be quoted -- with backticks when it holds a
# quote or a delimiter, with `"""` when it holds a backtick -- which is what
# the writer below produces for the same keys.
sub _read_key {
    my ($line, $lineno) = @_;

    my $quote;
    if (substr($line, 0, 1) eq '"') {
        $quote = (length($line) > 6 && substr($line, 0, 3) eq '"""') ? '"""' : '"';
    }
    elsif (substr($line, 0, 1) eq '`') {
        $quote = '`';
    }

    if (defined $quote) {
        my $start = length $quote;
        my $pos   = index($line, $quote, $start);
        croak "line $lineno: a quoted key that is never closed. sops refuses "
            . "the same line with 'missing closing key quote'"
            if $pos < 0;

        my $after = $pos + $start;
        my $d = _index_any(substr($line, $after), $DELIMITERS);
        croak "line $lineno: no '=' or ':' after the quoted key. sops refuses "
            . "the same line with 'key-value delimiter not found'"
            if $d < 0;

        my $key = substr($line, $start, $pos - $start);
        $key =~ s/\A\s+//; $key =~ s/\s+\z//;
        return ($key, substr($line, $after + $d + 1));
    }

    my $end = _index_any($line, $DELIMITERS);
    # The line is NOT quoted into the message: an unreadable line in an
    # encrypted document is still the document's content.
    croak "line $lineno is neither a comment, a section header nor a "
        . "'key = value' pair: it holds no '=' and no ':'. sops refuses the "
        . "same line with 'key-value delimiter not found'"
        if $end < 0;
    croak "line $lineno has an EMPTY key name. sops refuses the same line "
        . "with 'empty key name'"
        if $end == 0;

    my $key = substr($line, 0, $end);
    $key =~ s/\A\s+//; $key =~ s/\s+\z//;
    return ($key, substr($line, $end + 1));
}

# go-ini's readValue, and the reason it is here in full rather than as
# `everything after the =`: an UNENCRYPTED leaf reaches the file as its own
# text, so a reader that undoes less than sops's does hands the digest a
# different plaintext and the document fails its own MAC.
#
# Returns the value and the inline comment it swallowed, if any.
sub _read_value {
    my ($lines, $idx, $rest) = @_;

    my $line = $rest;
    $line =~ s/\A\s+//;
    return ('', undef) unless length $line;

    my $quote;
    if (length($line) > 3 && substr($line, 0, 3) eq '"""') { $quote = '"""' }
    elsif (substr($line, 0, 1) eq '`')                     { $quote = '`'   }

    if (defined $quote) {
        my $start = length $quote;
        my $pos   = index($line, $quote, $start);
        return (substr($line, $start, $pos - $start), undef) if $pos >= 0;

        # A quote left open runs on to the line that closes it. This is how a
        # value holding a newline is written and the only way it is readable.
        my @acc = (substr($line, $start));
        while (1) {
            $$idx++;
            return (join("\n", @acc), undef) if $$idx > $#$lines;
            my $next = $lines->[$$idx];
            $next =~ s/\r\z//;
            my $p = index($next, $quote);
            if ($p >= 0) { push @acc, substr($next, 0, $p); last }
            push @acc, $next;
        }
        return (join("\n", @acc), undef);
    }

    $line =~ s/\s+\z//;

    # A trailing backslash continues the value onto the next line, and the
    # continued value is returned WITHOUT the inline-comment strip and without
    # the unquoting below -- go-ini returns from there. Measured: `a = one\`
    # followed by `b = two` is the single value `oneb = two`.
    if (length($line) && substr($line, -1) eq "\\") {
        my $value = substr($line, 0, -1);
        while (1) {
            $$idx++;
            last if $$idx > $#$lines;
            my $next = $lines->[$$idx];
            $next =~ s/\r\z//;
            $next =~ s/\A\s+//; $next =~ s/\s+\z//;
            last unless length $next;
            $value .= $next;
            last unless substr($value, -1) eq "\\";
            $value = substr($value, 0, -1);
        }
        return ($value, undef);
    }

    my $inline;
    my $at = _index_any($line, '#;');
    if ($at >= 0) {
        $inline = substr($line, $at);
        $line   = substr($line, 0, $at);
        $line =~ s/\A\s+//; $line =~ s/\s+\z//;
    }

    $line = substr($line, 1, length($line) - 2)
        if _has_surrounded_quote($line, "'") || _has_surrounded_quote($line, '"');

    return ($line, $inline);
}

# Go's strings.IndexAny over a set of single bytes.
sub _index_any {
    my ($string, $set) = @_;
    my $best = -1;
    for my $char (split //, $set) {
        my $at = index($string, $char);
        $best = $at if $at >= 0 && ($best < 0 || $at < $best);
    }
    return $best;
}

# Go's hasSurroundedQuote, and the third clause is the whole of why `"a"b"`
# survives where `"quoted"` does not: the quote may not appear INSIDE.
sub _has_surrounded_quote {
    my ($string, $quote) = @_;
    return 0 unless length($string) >= 2;
    return 0 unless substr($string, 0, 1) eq $quote;
    return 0 unless substr($string, -1)   eq $quote;
    return 0 unless index($string, $quote, 1) > -1;
    return 0 unless index(substr($string, 1, length($string) - 2), $quote) == -1;
    return 1;
}

# sops's stripCommentChar over go-ini's accumulated block. Only the FIRST
# line's marker goes -- measured, the leaf's plaintext keeps every later line's
# `;` or `#` exactly as the file had it, which is why a `#` comment can come
# back out of a `;` block unchanged.
sub _comment_text_from_lines {
    my ($lines) = @_;

    my $text = join "\n", @$lines;
    $text =~ s/\A\s+//; $text =~ s/\s+\z//;

    if    (substr($text, 0, 1) eq ';') { $text =~ s/\A[; ]+// }
    elsif (substr($text, 0, 1) eq '#') { $text =~ s/\A[# ]+// }

    return $text;
}

# The wire is UTF-8 bytes and this library's boundary is characters, so every
# section name, key, value and comment crossing in gets decoded exactly once --
# the crossing YAML::XS and Cpanel::JSON::XS(utf8) do for the other two
# formats, and the one the emitters below undo with an unconditional encode
# (docs/adr/0003).
sub _characters {
    my ($bytes, $what) = @_;

    my $chars = $bytes;
    croak "$what is not valid UTF-8, and an ini document has no other way to "
        . "say what its bytes mean. Both nested parsers here refuse the same "
        . "document; sops, whose strings are byte slices, reads it"
        unless utf8::decode($chars);

    return $chars;
}

# The bytes a key or a section name goes onto the wire as. The value's half of
# this is Encrypted::value_to_bytes, which encodes the same way and for the
# same reason; a key has no type ladder to go through, so it is the encode
# alone.
sub _key_bytes {
    my ($key) = @_;
    my $bytes = $key;
    utf8::encode($bytes);   # unconditional: no-op for ASCII, correct for the rest
    return $bytes;
}

sub _value_bytes {
    my ($value) = @_;
    my $bytes = $value;
    utf8::encode($bytes);
    return $bytes;
}

sub parse {
    my ($class, $content) = @_;
    croak "content required" unless defined $content;

    my (%data, %flat, %header_seen);

    for my $item (@{ $class->_scan($content) }) {
        my $kind = $item->{kind};

        if ($kind eq 'section') {
            my $name = _characters($item->{name},
                "the section name on line $item->{line}");
            next if $name eq $METADATA_SECTION;

            croak "the section '[$name]' is opened twice (line $item->{line}). "
                . "sops keeps both as separate branches -- its tree is an "
                . "ordered list, not a map -- and a Perl hash cannot, so this "
                . "document is refused rather than silently merging them"
                if $header_seen{$name}++;

            $data{$name} ||= {};
            next;
        }

        next if $item->{section} eq $METADATA_SECTION && $kind eq 'comment';

        if ($kind eq 'comment') {
            my $text = _comment_text_from_lines($item->{lines});
            # sops writes no leaf for a comment with no text: a bare `#` is
            # dropped entirely, measured, and File::SOPS::Comment refuses an
            # empty text for the same reason.
            next unless length $text;

            my $section = _characters($item->{section},
                "the section name for the comment on line $item->{line}");
            push @{ $data{$section}{$COMMENT_KEY} },
                _comment_leaf($text, $item->{line});
            next;
        }

        if ($item->{section} eq $METADATA_SECTION) {
            croak "the flat metadata key '$item->{key}' is set twice "
                . "(line $item->{line})"
                if exists $flat{ $item->{key} };
            $flat{ $item->{key} } = $item->{value};
            next;
        }

        my $section = _characters($item->{section},
            "the section name on line $item->{line}");
        my $key = _characters($item->{key}, "the key on line $item->{line}");

        croak "the key '$key' in section '[$section]' is set twice "
            . "(line $item->{line}). sops keeps the LAST one and drops the "
            . "other without a word; this document is refused rather than "
            . "losing a line somebody wrote"
            if exists $data{$section}{$key};

        $data{$section}{$key} = _characters($item->{value},
            "the value of '$key' on line $item->{line}");
    }

    my $metadata = %flat
        ? File::SOPS::Metadata->from_hash($FLAT->unflatten({
              map { $_ => _characters($FLAT->unescape_value($flat{$_}),
                                      "the metadata key '$_'") }
                  keys %flat
          }))
        : undef;

    return (\%data, $metadata);
}

# ENCRYPTED or PLAINTEXT, decided by the type LABEL and not by the position --
# Format::ENV's rule, for the same reason: the same method has to read a
# plaintext .ini and an encrypted one.
sub _comment_leaf {
    my ($text, $lineno) = @_;

    return $text
        if (File::SOPS::Encrypted->encrypted_type($text) // '') eq 'comment';

    return File::SOPS::Comment->new(
        text => _characters($text, "the comment on line $lineno"));
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
    tie %doc, $ORDERED;
    my %header_seen;

    for my $item (@$items) {
        my $section = $item->{kind} eq 'section' ? $item->{name}
                                                 : $item->{section};
        utf8::decode($section);
        next if $section eq $METADATA_SECTION;   # the handler drops it, condition 3

        if ($item->{kind} eq 'section') {
            return if $header_seen{$section}++;   # a document parse() refuses
        }

        unless (exists $doc{$section}) {
            my %branch;
            tie %branch, $ORDERED;
            $doc{$section} = \%branch;
        }
        next if $item->{kind} eq 'section';

        my $branch = $doc{$section};

        if ($item->{kind} eq 'comment') {
            my $text = _comment_text_from_lines($item->{lines});
            next unless length $text;
            # The bucket takes the position of the FIRST comment, which is
            # where parse() would put it in a hash that had positions. Only the
            # shape is read, so what matters is that the sequence is here and
            # is as long as the tree's.
            $branch->{$COMMENT_KEY} = []
                unless ref $branch->{$COMMENT_KEY} eq 'ARRAY';
            push @{ $branch->{$COMMENT_KEY} }, undef;
            next;
        }

        my $key = $item->{key};
        utf8::decode($key);

        return if exists $branch->{$key};   # a document parse() refuses

        $branch->{$key} = undef;
    }

    return \%doc;
}


sub serialize {
    my ($class, %args) = @_;
    my $data     = $args{data}     // croak "data required";
    my $metadata = $args{metadata} // croak "metadata required";

    # emit() refuses a section named `sops`, so the section written below
    # cannot be shadowed by one -- the same job Format::JSON's `sops` refusal
    # does, moved to where this format's collision is.
    my $out = $class->emit($data);

    # flatten() has already escaped the values, in the order sops writes them:
    # maps sorted, lists ascending. The section goes LAST, where sops puts it;
    # line order is not load-bearing (measured: a file with its metadata lines
    # reversed still decrypts), and the metadata is excluded from the MAC
    # structurally.
    $out .= "\n" if length $out;
    $out .= '[' . $METADATA_SECTION . "]\n";

    my @pairs = map { [ _key_bytes($_->[0]), _value_bytes($_->[1]) ] }
                    $FLAT->flatten($metadata->to_hash);
    $out .= _aligned_lines(\@pairs);

    return $out;
}


# The one place this distribution turns a Perl tree into an ini document.
# serialize() is this plus the metadata section, and File::SOPS::_serialize_
# plaintext -- what decrypt_file writes and what edit hands the editor -- is
# this on its own.
#
# So this is ON THE WIRE PATH and is not a plaintext formatting knob. In
# particular the sorted order below is not a diff-readability choice: the MAC's
# encrypt side hashes leaves in `sort keys` order at every level, and that is
# the document's own order only because this loop sorts. Measured on a file
# sops wrote, whose order is the document's: sorting the data lines of one
# section makes `sops -d` fail at exit 51.
sub emit {
    my ($class, $data) = @_;
    croak "data required" unless defined $data;
    croak "an ini document is a mapping of sections to their keys, so emit "
        . "needs a HashRef, not " . (ref($data) ? ref($data) . " reference"
                                                : "a scalar")
        unless ref $data eq 'HASH';

    my $out   = '';
    my $first = 1;

    for my $name (sort keys %$data) {
        croak "[$name]: '$METADATA_SECTION' is the section the SOPS metadata "
            . "goes in, so this section would be read back as metadata instead "
            . "of as data. sops refuses such a document too (exit 203). Rename "
            . "the section"
            if $name eq $METADATA_SECTION;

        croak "a section name cannot be empty; sops refuses such a header with "
            . "'empty section name'"
            unless length $name;

        my $section = $data->{$name};

        # A top-level SCALAR is what sops itself refuses -- `Section values
        # should always be TreeBranches`, exit 4 -- and an ArrayRef has no
        # spelling here either.
        croak "[$name]: an ini document is exactly two levels deep, so every "
            . "top-level entry is a section and has to be a HashRef, not "
            . (ref($section) ? lc(ref $section) . " reference"
                             : defined $section ? "a scalar" : "an undef")
            . ". sops refuses a top-level scalar with 'Section values should "
            . "always be TreeBranches'"
            unless ref $section eq 'HASH';

        $out .= "\n" unless $first;
        $first = 0;

        my @comments = exists $section->{$COMMENT_KEY}
            ? $class->_comment_blocks($section->{$COMMENT_KEY}, $name)
            : ();

        my @pairs;
        for my $key (sort grep { $_ ne $COMMENT_KEY } keys %$section) {
            push @pairs, [
                _key_bytes($key),
                _leaf_text($section->{$key}, $name, $key),
            ];
        }

        # ONE comment leaf per NODE, and the nodes are the header plus the
        # keys. Not a layout preference: consecutive comment LINES are one
        # leaf on the way back in, so two `; ENC[...]` lines written next to
        # each other come back as a single comment holding both tokens as
        # text. sops never writes that because it keeps each comment where the
        # document had it; this emitter has no positions, so it spreads them.
        #
        # The capacity is exactly what a document can hold: a comment block
        # needs a following node to attach to, so a section with K keys can
        # carry at most K+1 of them, and this writes K+1.
        croak "[$name]: " . scalar(@comments) . " comment blocks in a section "
            . "with " . scalar(@pairs) . " keys. A comment attaches to the "
            . "node that FOLLOWS it and the nodes here are the section header "
            . "and its keys, so at most " . (@pairs + 1) . " can be written -- "
            . "any more would end up on consecutive lines, which this format "
            . "reads back as ONE comment. Join them into one comment, or add "
            . "the keys they belong to"
            if @comments > @pairs + 1;

        $out .= shift @comments if @comments;
        $out .= '[' . _key_bytes($name) . "]\n";
        $out .= _aligned_lines(\@pairs, \@comments);
    }

    return $out;
}

# go-ini's writer pads every key in a section to the longest one IN THAT
# SECTION, counted in BYTES and after the key's own quoting. Measured cosmetic
# for the digest -- a sops-written file with the padding stripped still reads
# at exit 0 -- and reproduced because it is what makes a diff against a
# sops-written file readable, and our [sops] section byte-identical to its.
sub _aligned_lines {
    my ($pairs, $comments) = @_;

    my $align = 0;
    my @quoted;
    for my $pair (@$pairs) {
        my $key = _quote_key($pair->[0]);
        $align = length $key if length $key > $align;
        push @quoted, [ $key, $pair->[1] ];
    }

    my $out = '';
    for my $pair (@quoted) {
        $out .= shift @$comments if $comments && @$comments;
        $out .= $pair->[0] . (' ' x ($align - length $pair->[0])) . ' = '
              . $pair->[1] . "\n";
    }

    return $out;
}

sub _comment_blocks {
    my ($class, $bucket, $section) = @_;

    croak "[$section]: the empty key is reserved for this section's comments "
        . "and holds a sequence of them; a "
        . (ref($bucket) ? lc(ref $bucket) . " reference" : "scalar")
        . " here has no line to be written as. See the comment section of "
        . "File::SOPS::Format::INI"
        unless ref $bucket eq 'ARRAY';

    return map { _comment_block(_comment_text($_, $section)) } @$bucket;
}

sub _comment_text {
    my ($comment, $section) = @_;

    # An encrypted comment is already the line's text.
    return $comment
        if !ref $comment
        && (File::SOPS::Encrypted->encrypted_type($comment) // '') eq 'comment';

    croak "[$section]: the empty key holds this section's comments, and "
        . (ref($comment)    ? "a " . lc(ref $comment) . " reference"
         : defined $comment ? "a plain scalar"
         :                    "an undef")
        . " is not one. Put File::SOPS::Comment objects there, or leave the "
        . "key out"
        unless File::SOPS::Encrypted->is_comment($comment);

    return File::SOPS::Encrypted->value_to_bytes($comment);
}

# go-ini's comment writer, line by line: a line that already carries a marker
# keeps it and is re-spaced, one that does not gets `; `. A multi-line comment
# leaf is therefore several lines again -- which is how it was read, since
# consecutive comment lines are ONE leaf.
sub _comment_block {
    my ($text) = @_;

    my $out = '';
    for my $line (split /\n/, $text, -1) {
        if ($line =~ /\A([;#])(.*)\z/s) {
            my ($marker, $rest) = ($1, $2);
            $rest =~ s/\A\s+//; $rest =~ s/\s+\z//;
            $out .= $marker . ' ' . $rest . "\n";
        }
        else {
            $out .= '; ' . $line . "\n";
        }
    }

    return $out;
}

sub _leaf_text {
    my ($value, $section, $key) = @_;

    # An ENCRYPTED leaf is an ENC[...] string by the time the emitter sees it.
    # Its alphabet is base64 plus []:,= -- no `#`, no `;`, no backtick, no
    # newline and no edge whitespace -- so the writer leaves it bare and the
    # reader returns it unchanged. The guard below has nothing to catch on it,
    # and refusing one would reject documents that work.
    return $value
        if !ref $value && File::SOPS::Encrypted->is_encrypted($value);

    croak "[$section] $key: cannot write a " . lc(ref $value) . " into an ini "
        . "document; the format is two levels deep and has no spelling for a "
        . "nested value. sops does not refuse this one -- it writes a dump of "
        . "the Go value, which is not a document any more"
        if ref $value && !blessed($value);

    croak "[$section] $key: a comment cannot be a mapping value. In an ini "
        . "document a comment is a line of its own, which this handler keeps "
        . "under the section's empty key -- see the comment section of "
        . "File::SOPS::Format::INI"
        if File::SOPS::Encrypted->is_comment($value);

    # docs/adr/0035: in an untyped store an unencrypted leaf is written as
    # exactly the bytes the digest covers. ASKED of the single source of truth
    # rather than re-derived, so the emitter and the digest cannot drift apart.
    my $bytes  = File::SOPS::Encrypted->value_to_bytes($value);
    my $quoted = _quote_value($bytes);

    # docs/adr/0030's rule, in this format's spelling: ask the ROUND TRIP, not
    # a character. go-ini's reader strips a matching pair of surrounding quotes
    # its writer never wrote, and follows a trailing backslash onto the next
    # line, so `"quoted"`, `'quoted'`, `""` and `"""x"""` are all values sops
    # writes at exit 0 and then refuses to read (MAC mismatch, exit 51).
    my $read = _reads_back($quoted);
    croak "[$section] $key: cannot write this value into an ini document; the "
        . "format's quoting does not round-trip it -- written out it reads "
        . "back as something else, so the document would say one thing and its "
        . "own MAC another. sops writes such a file at exit 0 and then refuses "
        . "to read it (MAC mismatch, exit 51)"
        unless defined $read && $read eq $bytes;

    return $quoted;
}

# The round trip itself: the quoted value is put on a line the way emit() puts
# it there, and the line is read back through THIS handler's own scanner. Not a
# test for a character -- a second spelling of the rule is how a guard and the
# thing it guards drift apart (docs/adr/0030).
#
# Returns undef where the line does not read back as one whole value: the
# reader swallowed part of it as an inline comment, or the value ran on past
# the lines it was written on.
sub _reads_back {
    my ($quoted) = @_;

    my @lines = split /\n/, 'k = ' . $quoted, -1;
    $lines[0] =~ s/\A\s+//;
    $lines[0] =~ s/\s+\z//;

    my ($key, $rest) = eval { _read_key($lines[0], 0) };
    return undef unless defined $rest;

    my $index = 0;
    my ($read, $inline) = _read_value(\@lines, \$index, $rest);

    return undef if defined $inline && length $inline;
    return undef unless $index == $#lines;
    return $read;
}

# go-ini's writer, measured: a newline or a backtick takes the `"""` form, a
# `#` or a `;` takes backticks, edge whitespace takes double quotes, and
# everything else goes bare.
sub _quote_value {
    my ($value) = @_;

    return '"""' . $value . '"""' if $value =~ /[\n`]/;
    return '`'   . $value . '`'   if $value =~ /[#;]/;
    return '"'   . $value . '"'   if $value =~ /\A\s/ || $value =~ /\s\z/;
    return $value;
}

# The key's half of the same thing, and the order matters: a key holding a
# backtick takes `"""`, one holding a quote or a delimiter takes backticks.
sub _quote_key {
    my ($key) = @_;

    return '"""' . $key . '"""' if index($key, '`') >= 0;
    return '`'   . $key . '`'   if $key =~ /["\Q$DELIMITERS\E]/;
    return $key;
}


sub detect_content {
    my ($class, $content) = @_;
    return 0 unless defined $content;

    # BOTH halves of what an encrypted ini document is, because either alone is
    # too weak: any line of `key: value` scans as an ini pair, so "it parses"
    # says nothing, and a plaintext .ini has no metadata to find.
    my $items = eval { $class->_scan($content) } or return 0;
    for my $item (@$items) {
        return 1 if $item->{kind} eq 'section'
                 && $item->{name} eq $METADATA_SECTION;
    }

    return 0;
}


sub format_name { 'ini' }


sub file_extensions { qw(ini) }


sub detect {
    my ($class, $filename) = @_;
    return 1 if $filename =~ /\.ini$/i;
    return 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Format::INI - INI format handler for SOPS

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Format::INI;

    # Parse an INI document (encrypted or plaintext)
    my ($data, $metadata) = File::SOPS::Format::INI->parse($ini_string);

    # Serialize a tree plus its metadata back to an INI document
    my $ini = File::SOPS::Format::INI->serialize(
        data     => $data,
        metadata => $metadata,
    );

    # The tree is exactly two levels deep: section -> key
    $data->{db}{host};

    # A section's comments live under the empty key, as a list
    $data->{db}{''};    # [ File::SOPS::Comment, ... ]

=head1 DESCRIPTION

INI format handler for SOPS documents. Reproduces what the reference
implementation does with an ini file, which is what Go's C<gopkg.in/ini.v1>
does: this handler's grammar is that library's, measured against sops 3.13.3
rather than read out of its source.

The tree is B<exactly two levels deep> -- section, then key -- because that is
all the format can express. A value outside any section belongs to the section
named C<DEFAULT>, which is where sops puts it too.

=head2 The line

=over 4

=item * B<< C<[name]> >> opens a section. The name runs to the B<last> C<]> on
the line. An empty name is refused, as sops refuses it.

=item * A line whose first non-blank character is C<;> or C<#> is a comment.
B<Consecutive comment lines are one leaf>, whose text is the block with the
first line's marker stripped and every later line kept verbatim.

=item * Anything else is C<key = value>. B<Both C<=> and C<:> are delimiters>
and the first one found wins. The key may be quoted with backticks or
C<""">; everything before the delimiter is otherwise trimmed and taken as it
stands.

=item * The value is read the way go-ini reads it, which is not "the rest of
the line": a leading C<"""> or backtick quotes it, possibly across several
lines; otherwise a trailing backslash continues it onto the next line, an
unquoted C<#> or C<;> starts an inline comment, and a matching pair of
surrounding quotes is stripped.

=item * A blank line is skipped and does B<not> end a comment block.

=item * A comment at the end of the file is B<dropped>, because it has no
following node to attach to. sops drops it too.

=back

=head2 Where a comment lives, and why it is not where Format::ENV puts one

Measured against sops 3.13.3, with a comment in every position an ini document
has: a comment leaf authenticates under the AAD of its B<section> -- C<db:>,
never C<db::>. sops attaches a comment to the node that follows it, and both a
comment above a key and a comment above the section header itself end up in
that section's branch with the section's own path.

So a section's comments live under the B<empty key> of that section, as a list:

    {
        db => {
            ''   => [ File::SOPS::Comment->new(text => 'a note') ],
            host => 'localhost',
        },
    }

The empty key is reserved for it. Nothing collides: sops refuses an empty key
name outright (exit 2), so an ini document cannot carry one as data.

L<File::SOPS::Format::ENV> keeps its comments under the empty key of the
B<document>, which produces the AAD C<:> -- the same thing for a flat format
and a different thing here. See
L<docs/adr/0047|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0047-an-ini-comment-lives-in-its-section-because-that-is-the-path-it-authenticates-under.md>.

=head2 Where this handler differs from sops, and why

=over 4

=item * B<Sections and keys are written sorted.> sops writes them in document
order. The MAC's encrypt side hashes leaves in C<sort keys> order at every
level, so a document this library writes has to B<be> in that order or it
fails its own digest. Reading takes its order from the document, which is what
L</parse_in_document_order> is for.

=item * B<A section's comments are written before its header,> as a block,
because the tree is a Perl hash and comment position is gone before any
emitter sees it. Measured: comment position is in no digest -- every comment
line in a sops-written file moved to the top still reads at exit 0 -- and a
comment above a section header is read back into that same section.

=item * B<C<DEFAULT> is written with an explicit C<[DEFAULT]> header.> sops
writes the implicit section headerless and first. Writing it in its sorted
position is what keeps the sorted order above true for every section name;
go-ini creates its implicit empty C<DEFAULT> beside the explicit one and sops
reads the result at exit 0, measured.

=item * B<A value the format cannot carry unchanged is refused> rather than
written -- see below.

=item * B<A boolean, a null and an integral float are written as the bytes the
digest covers,> not as sops writes them. docs/adr/0035, unchanged here.

=back

=head2 The quoting, and the values that are refused

go-ini's writer quotes a value in three cases and its reader undoes rather more
than that, so the two do not always agree. Measured, sops 3.13.3, on
B<unencrypted> values -- the only ones whose text reaches the file as itself:

    value                sops wrote            sops -d
    a#b                  `a#b`                 a#b        round trips
    a;b                  `a;b`                 a;b        round trips
    line1<LF>line2       """line1<LF>line2"""  the two lines
    a`b                  """a`b"""             a`b        round trips
    "  leading"          "  leading"           kept
    ""                   ""                    LOSSY: read back as the empty string
    'quoted'             'quoted'              LOSSY: read back as quoted
    "quoted"             "quoted"              LOSSY: read back as quoted
    """x"""              """x"""               LOSSY: read back as x

The last four are files sops writes at exit 0 and then refuses to read
(C<MAC mismatch>, exit 51), because its reader strips a matching pair of
surrounding quotes that its writer never put there.

This handler B<refuses> such a value instead, and it asks the question the way
docs/adr/0030 asks it in the dotenv handler: the value is quoted with this
format's writer, read back with this format's reader, and refused when the two
disagree. A test for a character would be a second spelling of the rule and
would drift from it.

The B<encrypted> slot never reaches this: an C<ENC[...]> string is base64 plus
C<[]:,=>, which the writer leaves bare and the reader returns unchanged.

=head2 An unencrypted leaf is written as its digest bytes

docs/adr/0035, and it is the dotenv handler's rule line for line -- the two
were measured together. The ini store has no type syntax, so an unencrypted
leaf's digest input is the literal text of its line, and this handler writes
exactly C<< File::SOPS::Encrypted->value_to_bytes >> for it. That is where a
boolean becomes C<True>, an C<undef> the empty string, and C<1.0> the token
C<1>: three values sops writes in a display form and then cannot read back
(k124, k125, k137).

=head2 What this handler cannot carry

=over 4

=item * B<Nesting.> The format is two levels deep. sops does not refuse a
deeper tree -- measured, it writes C<< inner = [{host ENC[...]}] >>, a Go
struct dump that is not a document any more. This handler refuses it.

=item * B<A top-level scalar.> sops refuses one itself: C<Section values should
always be TreeBranches>, exit 4.

=item * B<A duplicate section name.> sops keeps both as separate branches -- a
document it writes can contain two C<[db]> blocks -- and a Perl hash cannot.

=item * B<A duplicate key in one section.> sops keeps the last silently; this
handler refuses rather than dropping a line the caller wrote. No sops-written
document can contain one, because go-ini already collapsed it on the way in.

=item * B<A section named C<sops>.> That is where the metadata goes. sops
refuses it too, exit 203.

=item * B<Bytes that are not valid UTF-8.> This distribution's boundary is
characters and its emitters encode unconditionally (docs/adr/0003), so bytes
that carry no meaning as text are refused rather than double-encoded later.

=back

=head2 parse

    my ($data, $metadata) = File::SOPS::Format::INI->parse($ini_string);

Class method. Parses an INI document -- encrypted or plaintext -- and returns
the data as a HashRef of sections and a L<File::SOPS::Metadata> object built
from the C<[sops]> section, or C<undef> where the document has none.

The tree is two levels deep. A value written outside any section is in the
section C<DEFAULT>. A section's comments are a list under its empty key.

Dies on a line that is not a comment, a section header or a C<key = value>
pair; on a section opened twice; on a key set twice inside one section; on an
empty section or key name; and on bytes that are not valid UTF-8.

=head2 parse_in_document_order

    my $ordered = File::SOPS::Format::INI->parse_in_document_order($content);

Reparses C<$content> for its B<key order only> and returns the document as a
HashRef whose sections, and whose keys within each section, iterate in the
order the file writes them, with the C<[sops]> section removed. Returns nothing
when the text cannot be read that way.

This is the half of MAC verification that only a format handler can supply: an
ini document sops wrote is in B<document> order, and without this the digest
would be taken in sorted key order and every such file whose keys were not
already sorted would fail to verify. The values are C<undef> -- only the shape
is read, never a value -- and each section's comment sequence is present with
the right length so that the shape matches L</parse>'s. The order comes from a
tied hash, which is the whole of what "order preserving" means for a format
whose parser has none. See
L<docs/adr/0036|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0036-the-order-preserving-reparse-is-asked-of-the-format-handler.md>.

=head2 serialize

    my $ini = File::SOPS::Format::INI->serialize(
        data     => \%data,
        metadata => $metadata_obj,
    );

Class method. L</emit> plus the flat metadata in a C<[sops]> section, appended
at the end as sops writes it.

The C<data> parameter must be a HashRef of sections and C<metadata> a
L<File::SOPS::Metadata> object. Dies through L</emit> if the data carries a
section named C<sops>, which is where the metadata goes.

=head2 emit

    my $ini = File::SOPS::Format::INI->emit(\%data);

Class method. Turns a tree into an INI document B<without> a metadata section:
each section's comments, then its C<[name]> header, then its C<key = value>
lines padded to the section's longest key -- sections in sorted order, keys
sorted within each.

This is the emitter L</serialize> uses and the one C<File::SOPS::decrypt_file>
and C<File::SOPS::edit> write plaintext with, so B<it is on the wire path>. In
particular the sorted order is not a formatting preference -- see
L</Where this handler differs from sops, and why>.

An encrypted leaf is written verbatim. Everything else is written as
C<< File::SOPS::Encrypted->value_to_bytes >>, quoted for the format, and
refused where that quoting does not round-trip (see
L</The quoting, and the values that are refused>).

Dies on a section that is not a HashRef, on a nested value, on an unblessed
reference, on a comment in a value slot, on a section named C<sops>, and on
anything in a section's empty key that is not a comment. A B<blessed> leaf is
written as its stringification, which is what the digest covers for it -- where
L<File::SOPS::Format::YAML> and L<File::SOPS::Format::JSON> refuse one, because
their emitters would write it as something else (C<docs/adr/0008>). Here
document and digest cannot disagree: they are the same call.

=head2 detect_content

    if (File::SOPS::Format::INI->detect_content($encrypted)) { ... }

Class method. True when C<$content> is an B<encrypted> INI document: every line
is a comment, a section header or a C<key = value> pair, B<and> one of the
sections is C<[sops]>.

Both halves are needed, and this answers for encrypted content only -- a
plaintext C<.ini> carries no metadata at all, and a line of C<key: value> scans
as an ini pair whatever document it came from. Plaintext is recognised by its
file name.

=head2 format_name

Returns C<'ini'>.

=head2 file_extensions

Returns a list of file extensions: C<('ini')>.

=head2 detect

    if (File::SOPS::Format::INI->detect($filename)) {
        # File is an INI file based on extension
    }

Class method to detect if a filename is an INI file based on extension.

Returns true if the filename ends with C<.ini> (case-insensitive).

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<File::SOPS::Format::ENV> - the dotenv handler, which shares this
one's flat metadata, type rule and order-preserving reparse

=item * L<File::SOPS::Format::ENV::Ordered> - the tied hash both of them carry
that reparse's key order in, one per section here

=item * L<File::SOPS::Metadata::Flat> - the flat metadata encoding, here with
an empty prefix

=item * L<File::SOPS::Comment> - the comment leaf

=item * docs/adr/0022 - the flat metadata encoding, and why INI escapes its
metadata and not its data

=item * docs/adr/0035 - what an unencrypted leaf is written as

=item * docs/adr/0036 - the order-preserving parse, and the contract above

=item * docs/adr/0041 - the comment leaf, and why it is not in the digest

=item * docs/adr/0047 - this handler: the whole document measured, the comment
AAD, and the four questions the ticket left open

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
