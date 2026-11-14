package LibTmux::Codec;
use v5.44;
use LibTmux::X;

sub format ($class, @tokens) {
    for (@tokens) {
        LibTmux::X::InvalidArgument->throw(message => 'invalid format token')
            unless /\A[\@A-Za-z_][A-Za-z_0-9]*\z/;
    }
    my $modifiers =
        's|\\\\|\\\\\\\\|;s|' . "\t" . '|\\\\t|;s|' . "\n" . '|\\\\n|:';
    return join "\t", map { '#{' . $modifiers . $_ . '}' } @tokens;
}

sub decode ($class, $bytes, $count) {
    LibTmux::X::Codec->throw(message => 'expected byte stream')
        if utf8::is_utf8($bytes);
    return [] if $bytes eq '';
    LibTmux::X::Codec->throw(message => 'missing final record newline')
        unless $bytes =~ /\n\z/;
    my @rows;
    my @frames = split /\n/, $bytes, -1;
    pop @frames;
    for my $row (@frames) {
        my @fields = length($row) ? split(/\t/, $row, -1) : ('');
        LibTmux::X::Codec->throw(message => 'incorrect field count')
            unless @fields == $count;
        $_ = _unescape($_) for @fields;
        push @rows, \@fields;
    }
    return \@rows;
}

sub _unescape ($field, $extra = '') {
    my %escapes = (
        '\\' => '\\',
        n    => "\n",
        t    => "\t",
        a    => "\a",
        b    => "\b",
        f    => "\f",
        v    => "\x0b",
        r    => "\r",
        '$'  => '$'
    );
    @escapes{split //, $extra} = split //, $extra;
    my $out = '';
    while (length $field) {
        if ($field =~ s/\A([^\\]+)//s) { $out .= $1; next }

        # Older tmux print paths add vis escapes after format expansion.
        if ($field =~ s/\A\\([0-3][0-7]{2})//) {
            $out .= chr(oct($1));
            next;
        }
        LibTmux::X::Codec->throw(
            message => 'unknown or incomplete field escape')
            unless $field =~ s/\A\\(.)//s && exists $escapes{$1};
        $out .= $escapes{$1};
    }
    return $out;
}

sub _quoted_value ($text, $option) {

    # A command value starts with a verb and unquoted argument separator.
    # String options are one args_escape token, quoted when they contain spaces.
    return $text if $option && $text =~ /\A[A-Za-z][A-Za-z0-9_-]* /;
    if ($option && length($text)) {
        LibTmux::X::Codec->throw(message => 'malformed quoted option value')
            unless $text =~
/\A(?:"((?:\\.|[^"\\])*)"|'((?:\\.|[^'\\])*)'|((?:\\.|[^\x09-\x0d \\"'])+))\z/s;
        $text = $1 // $2 // $3;
    }
    elsif (!$option) {
        LibTmux::X::Codec->throw(
            message => 'malformed quoted environment value')
            unless $text =~ /\A(?:\\.|[^"\\])*\z/s;
    }

    # Both native encoders escape these dollars. tmux 3.4 adds one more
    # slash while printing; an even run identifies that additional layer.
    $text =~ s!(\\+)\$([A-Za-z_{])!
        ('\\' x (length($1) % 2 ? length($1) : length($1) - 1)) . '$' . $2!ge;
    return _unescape($text, $option ? q{"'~#;{}%} : q{"`});
}

sub _option_value ($class, $bytes, $name) {
    return '' if $bytes eq '';
    LibTmux::X::Codec->throw(message => 'missing option record newline')
        unless $bytes =~ s/\n\z//;
    if ($name =~ /\A\@/) {

        # The unquoted name can itself contain spaces, newlines or vis escapes.
        # Its value is the final complete args_escape token, not a second word.
        LibTmux::X::Codec->throw(message => 'unexpected user option record')
            unless $bytes =~
/\A\@.* ("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|(?:\\.|[^\x09-\x0d \\"'])+)\z/s;
        return _quoted_value($1, true);
    }
    my @values;
    pos($bytes) = 0;
    while (pos($bytes) < length($bytes)) {
        LibTmux::X::Codec->throw(message => 'malformed option record')
            unless $bytes =~
            /\G([a-z][a-z0-9-]*)(?:\[[^\]]+\])?\*?(?: ([^\n]*))?(?:\n|\z)/gc;
        my ($resolved, $value) = ($1, $2);
        next unless defined $value;

        # These OPTIONS_TABLE_KEY values use key_string_lookup_key, not
        # args_escape. Use the resolved name even for abbreviated requests.
        push @values, $resolved =~ /\A(?:backspace|prefix|prefix2)\z/
            ? $value
            : _quoted_value($value, true);
    }
    return join "\n", @values;
}

sub _environment_value ($class, $bytes, $name) {
    return undef if $bytes eq '' || $bytes eq "unset $name;\n";
    LibTmux::X::Codec->throw(message => 'malformed environment record')
        unless $bytes =~ /\A\Q$name\E="(.*)"; export \Q$name\E;\n\z/s;
    return _quoted_value($1, false);
}

=head1 NAME

LibTmux::Codec - Reversible single-lookup tmux format records

=head1 DESCRIPTION

Backslash, tab, and newline are escaped by tmux substitution modifiers.
Decoding composes those escapes with older tmux print escapes in one pass,
returning octets. Use this decoder only with L</format> output from a UTF-8
command client; raw command output has a separate contract. An empty stream
has no rows; one newline is one empty single-field record. Malformed streams
throw L<LibTmux::X::Codec|LibTmux::X/Codec>.

Private readers for L<LibTmux::Server/get_option> and
L<LibTmux::Server/get_environment> decode tmux's native quoted values without
evaluating shell text. They do not change L<LibTmux::Server/cmd> output.

=head1 METHODS

=head2 format

C<LibTmux::Codec-E<gt>format(@tokens)> returns one tmux format string in token
order without I/O. Tokens must be registered-style names, including user option
names beginning with C<@>; invalid names throw
L<LibTmux::X::InvalidArgument|LibTmux::X/InvalidArgument>. No input is mutated.

=head2 decode

C<LibTmux::Codec-E<gt>decode($bytes, $field_count)> returns an arrayref of row
arrayrefs in stream order, including empty fields and duplicate rows. It
performs no I/O and does not mutate the input. An empty byte stream returns
C<[]>; malformed framing throws L<LibTmux::X::Codec|LibTmux::X/Codec>.

=cut
