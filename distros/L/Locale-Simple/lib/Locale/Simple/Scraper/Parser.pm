use strict;
use warnings;

package Locale::Simple::Scraper::Parser;
our $VERSION = '0.200';
# ABSTRACT: parser to finds translation tokens in a code file

use base qw( Parser::MGC );

use Moo;
use Try::Tiny;
use curry;
use charnames ();

has func_qr => ( is => 'ro', lazy => 1, default => sub { shift->default_func_qr } );
has found  => ( is => 'ro', default => sub { [] } );
has type => ( is => 'ro', required => 1 );

with "Locale::Simple::Scraper::ParserShortcuts";

# The helper names are exported from a Go package, so they start with an
# upper case letter there. A package prefix before the dot needs no pattern of
# its own: the word boundary already matches after the dot.
sub default_func_qr {
    my ( $self ) = @_;
    return qr/\b(?:L(?:|n|p|np|d|dp|dn|dnp)\b|N(?:|n|p|np|d|dp|dn|dnp)_)/ if $self->type eq "go";

    # Rust has macros: a bang follows the name, and the deferred markers are
    # lower case there. The path before a macro needs no pattern either.
    return qr/\b(?:l(?:|n|p|np|d|dp|dn|dnp)!|n(?:|n|p|np|d|dp|dn|dnp)_!)/ if $self->type eq "rs";
    return qr/\b(?:l(?:|n|p|np|d|dp|dn|dnp)\b|N(?:|n|p|np|d|dp|dn|dnp)_)/;
}

# Maps a name as written in the source to the one the argument tables use.
sub canonical_func {
    my ( $self, $func ) = @_;
    $func =~ s/^L/l/ if $self->type eq "go";
    if ( $self->type eq "rs" ) {
        $func =~ s/!$//;
        $func = ucfirst $func if $func =~ /_$/;
    }
    return $func;
}

sub parse {
    my ( $self ) = @_;
    $self->sequence_of( $self->c_any_of( $self->curry::noise, $self->curry::call ) );
    return $self->found;
}

sub noise {
    my ( $self ) = @_;
    my $noise = $self->substring_before( $self->func_qr );
    $self->fail( "no noise found" ) if !length $noise;
    $self->debug( "discarded %d characters of noise", length $noise );
    return $noise;
}

# A call whose arguments do not parse is reported and skipped; reading goes
# on where they failed, at the top level and inside another call's argument
# alike. Nothing is read twice, so nothing is recorded twice.
sub call {
    my ( $self ) = @_;

    my $func = $self->canonical_func( $self->expect( $self->func_qr ) );
    my $line = ( $self->where )[0];
    $self->debug( "found func $func at line %d", $line );

    try {
        my $arguments = $self->arguments( $func );
        push @{ $self->found }, { func => $func, args => $arguments, line => $line };
    }
    catch {
        die $_ if !eval { $_->isa( "Parser::MGC::Failure" ) };
        $self->warn_failure( $_ );
    };

    return;
}

sub arguments {
    my ( $self, $func ) = @_;

    my @arguments = ( $self->op( "(" ), $self->required_args( $func ), $self->extra_arguments, $self->op( ")" ) );
    $self->debug( "found %d arguments", scalar @arguments );

    return \@arguments;
}

sub op {
    my ( $self, $op ) = @_;
    return if $self->with_ws( maybe_expect => qr/\s*\Q$op\E/ );
    $self->fail( "Expected \"$op\"" );
}

sub extra_arguments {
    my ( $self ) = @_;
    return if !$self->maybe_expect( "," );

    my $extra_args = $self->list_of( ",", sub { $self->argument( "argument" ) } );
    return @{$extra_args};
}

# An argument the catalogue does not need, the count or one after it: any
# code up to the comma or closing bracket that ends it. Returns its source
# text, or nothing when it is a translation call alone, as that call is
# recorded on its own.
sub argument {
    my ( $self, $name ) = @_;
    $self->skip_ws;
    my $start = $self->pos;
    my $parts = $self->sequence_of( $self->c_any_of( $self->code_parts ) );
    $self->fail( "Expected $name" ) if $self->pos == $start;
    return if !@{$parts};
    return substr $self->{str}, $start, $self->pos - $start;
}

# The pieces such code is made of. Translation calls in it are recorded.
# String literals and bracket pairs are read as a whole, so a comma or a
# bracket inside them does not end the argument.
sub code_parts {
    my ( $self ) = @_;
    return (
        $self->curry::call,
        $self->skipped_literals,
        $self->curry::bracketed,
        $self->c_expect( qr/\w+|[^\w\s,()\[\]{}]/ ),
    );
}

# A bracket pair with what it holds, commas included. A pair left open (in
# broken code, or opened inside a literal form the scraper does not know)
# ends where its contents do. It never fails once opened, so what is read
# inside it is never read again.
sub bracketed {
    my ( $self ) = @_;
    my $open = $self->expect( qr/[(\[{]/ );
    ( my $close = $open ) =~ tr/([{/)]}/;
    $self->sequence_of( $self->c_any_of( $self->code_parts, $self->c_expect( "," ) ) );
    $self->maybe_expect( $close );
    return $open;
}

# The language's string literals as they appear in skipped code. The quoted
# forms are read leniently, any escape and empty included, as their text is
# not kept; the others are read as for a msgid.
sub skipped_literals {
    my ( $self ) = @_;
    my @literals = map {
        ref $_ && $_->[0] =~ /^["']\z/
          ? $self->c_expect( $self->quoted_qr( $_->[0] ) )
          : $self->literal_scope( $_ )
    } $self->literal_forms;
    return @literals, map { $self->c_expect( $_ ) } $self->code_only_literals;
}

sub quoted_qr {
    my ( $self, $quote ) = @_;
    my $q = quotemeta $quote;
    return qr/$q(?:[^\\$q]|\\.)*$q/s;
}

# Literals that never hold a msgid but must not be read as code: JavaScript
# template literals, Python strings with any prefix (f-strings, bytes), Go
# runes and Rust chars (one character or one escape; a Rust lifetime has no
# closing quote and stays code).
sub code_only_literals {
    my $char = qr/'(?:\\.[^'\\\n]*|[^'\\\n])'/;
    my $python = qr/(?<!\w)[rRbBfFuUtT]{0,2}(?:"""(?:[^\\]|\\.)*?"""|'''(?:[^\\]|\\.)*?'''|"(?:[^\\"\n]|\\.)*"|'(?:[^\\'\n]|\\.)*')/s;
    my %literals = ( js => [qr/`(?:[^`\\]|\\.)*`/s], py => [$python], go => [$char], rs => [$char] );
    return @{ $literals{ shift->type } || [] };
}

sub required_args {
    my ( $self, $func ) = @_;
    my %arg_lists = (
        l     => [qw( tr_token )],
        ln    => [qw( tr_token    comma  plural_token  comma  plural_count )],
        lp    => [qw( context_id  comma  tr_token )],
        lnp   => [qw( context_id  comma  tr_token      comma  plural_token  comma  plural_count )],
        ld    => [qw( domain_id   comma  tr_token )],
        ldn   => [qw( domain_id   comma  tr_token      comma  plural_token  comma  plural_count )],
        ldp   => [qw( domain_id   comma  context_id    comma  tr_token )],
        ldnp  => [qw( domain_id   comma  context_id    comma  tr_token      comma  plural_token  comma  plural_count )],

        # Deferred-translation markers — runtime no-ops, scraper treats
        # them identically to their l* twins.
        N_    => [qw( tr_token )],
        Nn_   => [qw( tr_token    comma  plural_token )],
        Np_   => [qw( context_id  comma  tr_token )],
        Nnp_  => [qw( context_id  comma  tr_token      comma  plural_token )],
        Nd_   => [qw( domain_id   comma  tr_token )],
        Ndn_  => [qw( domain_id   comma  tr_token      comma  plural_token )],
        Ndp_  => [qw( domain_id   comma  context_id    comma  tr_token )],
        Ndnp_ => [qw( domain_id   comma  context_id    comma  tr_token      comma  plural_token )],
    );
    return $self->collect_from( $arg_lists{$func} );
}

sub tr_token     { shift->named_token( "translation token" ) }
sub plural_token { shift->named_token( "plural translation token" ) }
sub plural_count { shift->argument( "count of plural entity" ) }
sub context_id   { shift->named_token( "context id" ) }
sub domain_id    { shift->named_token( "domain id" ) }
sub comma        { shift->op( "," ) }

sub constant_string {
    my ( $self ) = @_;

    my @components = $self->literal_scopes;

    my $string;
    if ( defined $self->concat_op ) {
        $string = $self->list_of( $self->concat_op, $self->c_any_of( @components ) );
    }
    else {
        # No concatenation operator: a string argument is a single literal.
        my $single = $self->maybe( sub { $self->any_of( @components ) } );
        $string = defined $single ? [$single] : [];
    }

    return join "", map { defined $_ ? $_ : "" } @{$string} if @{$string};

    $self->fail;
}

# undef means the language has no concatenation operator.
sub concat_op {
    my %ops = ( js => "+", pl => ".", tx => qr/(_|~)/, py => "+", php => ".", go => "+", rs => undef );
    return $ops{ shift->type };
}

# String literal forms per language type. An entry is either
# [ open, content method, close, arguments ] or the name of a method that
# parses a whole literal by itself (for forms whose terminator depends on the
# opening). Quoted forms name the escape table their contents are read with.
sub literal_forms {
    my %forms = (
        js => [ quoted( q["], "js" ), quoted( q['], "js" ), [ q[`], "js_template_contents", q[`] ] ],
        pl => [ quoted( q["], "perl" ),   quoted( q['], "single" ) ],
        py => ["python_strings"],
        tx => [ quoted( q["], "xslate" ), quoted( q['], "single" ) ],
        # No single quotes: in Go they delimit a rune, not a string.
        go  => [ quoted( q["], "go" ), [ q[`], "go_backtick_string_contents", q[`] ] ],
        # No single quotes either (chars and lifetimes), and no concatenation.
        rs  => [ quoted( q["], "rust" ), "rust_raw_string" ],
        php => [ quoted( q["], "php" ), quoted( q['], "single" ), "php_heredoc_or_nowdoc" ],
    );
    return @{ $forms{ shift->type } };
}

sub quoted {
    my ( $quote, $escapes ) = @_;
    return [ $quote, "quoted_string_contents", $quote, $quote, $escapes ];
}

sub literal_scopes {
    my ( $self ) = @_;
    return map { $self->literal_scope( $_ ) } $self->literal_forms;
}

# Whitespace before a literal is skipped; inside it, it is text.
sub literal_scope {
    my ( $self, $form ) = @_;
    if ( !ref $form ) {
        my $read = $self->c_with_ws( $form );
        return sub { $self->skip_ws; $self->$read };
    }
    my ( $open, $contents, $close, @args ) = @{$form};
    return $self->curry::scope_of( $open, $self->c_with_ws( $contents, @args ), $close );
}

# The text up to the closing quote, with its escapes read as the language
# reads them.
sub quoted_string_contents {
    my ( $self, $quote, $escapes ) = @_;
    my $q    = quotemeta $quote;
    my $text = $self->maybe_expect( qr/(?:[^\\$q]++|\\.)+/s );
    $text = $self->unescape( $text, $escapes ) if defined $text;
    $self->fail( "no string contents found" ) if !defined $text or !length $text;
    return $text;
}

# Python: adjacent literals join, also over lines and comments. Each is plain,
# raw (r) or unicode (u), in single or triple quotes; raw ones keep their
# backslashes. Other prefixes (f, b, t and their raw forms) give no constant
# str: not read.
sub python_strings {
    my ( $self ) = @_;
    my @parts = ( $self->python_string );
    while (
        defined(
            my $part = $self->maybe(
                sub {
                    $self->expect( qr/(?:\s|#[^\n]*|\\\r?\n)*/ );
                    $self->python_string;
                }
            )
        )
      )
    {
        push @parts, $part;
    }
    my $text = join "", @parts;
    $self->fail( "no string contents found" ) if !length $text;
    return $text;
}

sub python_string {
    my ( $self ) = @_;
    my ( undef, $prefix, $quote ) = $self->expect( qr/([rRuU]?)("""|'''|"|')/ );
    my $q = quotemeta substr( $quote, 0, 1 );
    my $body =
      length $quote == 3
      ? qr/(?:[^\\$q]++|\\.|$q(?!$q$q))*/s
      : qr/(?:[^\\$q\n]++|\\.)*/s;
    my $text = $self->expect( $body );
    $self->expect( qr/\Q$quote\E/ );
    return lc $prefix eq "r" ? $text : $self->unescape( $text, "python" );
}

# A JavaScript template literal is a msgid while it holds no ${ substitution.
# Its line breaks are LF.
sub js_template_contents {
    my ( $self ) = @_;
    my $text = $self->maybe_expect( qr/(?:[^\\`\$]++|\\.|\$(?!\{))+/s );
    $self->fail( "no string contents found" ) if !defined $text;
    $text =~ s/\r\n?/\n/g;
    $text = $self->unescape( $text, "js_template" );
    $self->fail( "no string contents found" ) if !length $text;
    return $text;
}

# Escapes inside string literals, per table: the patterns tried after a
# backslash, each with the text it stands for, and what becomes of an escape
# no pattern takes: the character alone (drop), backslash and character
# (keep), or no msgid at all (fail: the language rejects it). A table may
# name the variables the literal interpolates: such a literal is no constant
# and gives no msgid either; escaped sigils stay text. The scraper
# reads and writes bytes, so a character named by its code point is stored
# as its UTF-8 bytes; Go and PHP byte escapes are stored as the byte.
my %c_escape = ( a => "\a", b => "\b", e => "\e", f => "\f", n => "\n", r => "\r", t => "\t", v => "\x0b" );

sub c_escape { exists $c_escape{ $_[0] } ? $c_escape{ $_[0] } : $_[0] }

sub digits {
    ( my $digits = shift ) =~ tr/_//d;
    return length $digits ? $digits : 0;
}

sub code_point {
    my ( $number ) = @_;
    die "code point out of range\n" if $number > 0x10FFFF;
    my $char = do { no warnings; chr $number };
    utf8::encode( $char );
    return $char;
}

# Go and Rust take no surrogate halves.
sub scalar_value {
    my ( $number ) = @_;
    die "surrogate half\n" if $number >= 0xD800 and $number <= 0xDFFF;
    return code_point( $number );
}

sub named_char {
    my ( $name ) = @_;
    my $char = charnames::string_vianame( $name );
    die "unknown character name\n" if !defined $char;
    utf8::encode( $char );
    return $char;
}

sub reject { die "escape the language rejects\n" }

my @js_tail = (
    [ qr/([bfnrtv])/        => \&c_escape ],
    [ qr/x([0-9A-Fa-f]{2})/ => sub { code_point( hex $_[0] ) } ],
    [ qr/u([Dd][89ABab][0-9A-Fa-f]{2})\\u([Dd][C-Fc-f][0-9A-Fa-f]{2})/ => sub {
            code_point( 0x10000 + ( hex( $_[0] ) - 0xD800 ) * 0x400 + hex( $_[1] ) - 0xDC00 );
        }
    ],
    [ qr/u([0-9A-Fa-f]{4})/   => sub { code_point( hex $_[0] ) } ],
    [ qr/u\{([0-9A-Fa-f]+)\}/ => sub { code_point( hex $_[0] ) } ],
    [ qr/[xu]/                => \&reject ],
);

my %escapes = (
    perl => {
        rules => [
            [ qr/([abefnrt])/                => \&c_escape ],
            [ qr/x\{\s*([0-9A-Fa-f_]*)\s*\}/ => sub { code_point( hex digits( $_[0] ) ) } ],
            [ qr/x([0-9A-Fa-f]{0,2})/        => sub { code_point( hex digits( $_[0] ) ) } ],
            [ qr/N\{U\+([0-9A-Fa-f_]+)\}/    => sub { code_point( hex digits( $_[0] ) ) } ],
            [ qr/N\{([^}]+)\}/               => sub { named_char( $_[0] ) } ],
            [ qr/o\{\s*([0-7_]+)\s*\}/       => sub { code_point( oct digits( $_[0] ) ) } ],
            [ qr/([0-7]{1,3})/               => sub { code_point( oct $_[0] ) } ],
            [ qr/c(.)/s                      => sub { chr( ord( uc $_[0] ) ^ 64 ) } ],
            # Case changes and \Q act on the text that follows: not read.
            [ qr/[lLuUQEF]/ => \&reject ],
        ],
        other => "drop",
        # Every $ names a variable (a lone one does not compile); an @ does
        # before a name, ::, ', $, +, -, a digit or {. Under use utf8 the
        # name may start with any letter.
        interpolates => qr/\$|\@[0-9:'{\$+\-_\p{XIDS}]/,
    },
    js => {
        rules => [
            [ qr/(?:\r\n|\n|\r|\xE2\x80[\xA8\xA9])/ => sub { "" } ],
            [ qr/0(?![0-9])/                        => sub { "\0" } ],
            [ qr/([0-3][0-7]{0,2}|[4-7][0-7]?)/     => sub { code_point( oct $_[0] ) } ],
            @js_tail,
        ],
        other => "drop",
    },
    # Templates take no octal escapes, nor \8 and \9.
    js_template => {
        rules => [
            [ qr/(?:\n|\xE2\x80[\xA8\xA9])/ => sub { "" } ],
            [ qr/0(?![0-9])/              => sub { "\0" } ],
            [ qr/[0-9]/                   => \&reject ],
            @js_tail,
        ],
        other => "drop",
    },
    python => {
        rules => [
            [ qr/(?:\r\n|\n|\r)/    => sub { "" } ],
            [ qr/([\\'"abfnrtv])/   => \&c_escape ],
            [ qr/([0-7]{1,3})/      => sub { code_point( oct $_[0] ) } ],
            [ qr/x([0-9A-Fa-f]{2})/ => sub { code_point( hex $_[0] ) } ],
            [ qr/u([0-9A-Fa-f]{4})/ => sub { code_point( hex $_[0] ) } ],
            [ qr/U([0-9A-Fa-f]{8})/ => sub { code_point( hex $_[0] ) } ],
            [ qr/N\{([^}]+)\}/      => sub { named_char( uc $_[0] ) } ],
            [ qr/[xuUN]/            => \&reject ],
        ],
        other => "keep",
    },
    go => {
        rules => [
            [ qr/([\\"abfnrtv])/     => \&c_escape ],
            [ qr/([0-3][0-7]{2})/    => sub { chr oct $_[0] } ],
            [ qr/x([0-9A-Fa-f]{2})/  => sub { chr hex $_[0] } ],
            [ qr/u([0-9A-Fa-f]{4})/  => sub { scalar_value( hex $_[0] ) } ],
            [ qr/U([0-9A-Fa-f]{8})/  => sub { scalar_value( hex $_[0] ) } ],
        ],
        other => "fail",
    },
    rust => {
        rules => [
            [ qr/\r?\n[ \t\r\n]*/                       => sub { "" } ],
            [ qr/0/                                     => sub { "\0" } ],
            [ qr/([\\"'nrt])/                           => \&c_escape ],
            [ qr/x([0-7][0-9A-Fa-f])/                   => sub { code_point( hex $_[0] ) } ],
            [ qr/u\{((?:[0-9A-Fa-f]_*){1,6})\}/         => sub { scalar_value( hex digits( $_[0] ) ) } ],
        ],
        other => "fail",
    },
    xslate => {
        rules => [ [ qr/([nrt])/ => \&c_escape ] ],
        other => "drop",
    },
    # Perl, Xslate and PHP single quotes.
    single => {
        rules => [ [ qr/([\\'])/ => sub { $_[0] } ] ],
        other => "keep",
    },
    php => {
        rules => [
            [ qr/([nrtvef\\\$"])/        => \&c_escape ],
            [ qr/([0-7]{1,3})/           => sub { chr( oct( $_[0] ) & 0xFF ) } ],
            [ qr/x([0-9A-Fa-f]{1,2})/    => sub { chr hex $_[0] } ],
            [ qr/u\{([0-9A-Fa-f]+)\}/    => sub { code_point( hex $_[0] ) } ],
            [ qr/u\{/                    => \&reject ],
        ],
        other        => "keep",
        interpolates => qr/\$[A-Za-z_{[:^ascii:]]|\{\$/,
    },
);

# A heredoc reads the escapes of double quotes, except the quote itself.
$escapes{php_heredoc} = {
    %{ $escapes{php} },
    rules => [ [ qr/([nrtvef\\\$])/ => \&c_escape ], @{ $escapes{php}{rules} }[ 1 .. $#{ $escapes{php}{rules} } ] ],
};

sub unescape {
    my ( $self, $text, $table ) = @_;
    my ( $rules, $other, $interpolates ) = @{ $escapes{$table} }{qw( rules other interpolates )};
    my $result = "";
    my $plain  = sub {
        my ( $bytes ) = @_;
        utf8::decode( my $chars = $bytes );    # UTF-8 text is matched as characters
        $self->fail( "interpolated variable" ) if $interpolates and $chars =~ $interpolates;
        return $bytes;
    };
  ESCAPE: while ( $text =~ /\G([^\\]*)\\/gc ) {
        $result .= $plain->( $1 );
        for my $rule ( @{$rules} ) {
            my ( $pattern, $meaning ) = @{$rule};
            next if $text !~ /\G$pattern/gc;
            my $char = eval { $meaning->( $1, $2 ) };
            $self->fail( "escape not read: $@" ) if !defined $char;
            $result .= $char;
            next ESCAPE;
        }
        $text =~ /\G(.)/sgc;
        $self->fail( "escape not read: \\$1" ) if $other eq "fail";
        $result .= $other eq "keep" ? "\\$1" : $1;
    }
    return $result . $plain->( substr( $text, pos( $text ) || 0 ) );
}

# Heredoc and nowdoc: the closing identifier is the one that was opened, so
# the whole literal is parsed here. A heredoc reads its escapes, a nowdoc
# keeps the text.
sub php_heredoc_or_nowdoc {
    my ( $self ) = @_;
    my @open = $self->expect( qr/<<<[ \t]*(?:'(\w+)'|"(\w+)"|(\w+))[ \t]*\r?\n/ );
    shift @open;    # the whole match comes first, then the captures
    my $nowdoc = defined $open[0];
    my ( $id ) = grep { defined } @open;
    my $close = qr/\r?\n[ \t]*\Q$id\E\b/;
    my $text = $self->raw_string_contents( $close );
    $self->expect( $close );
    $text = $self->unescape( $text, "php_heredoc" ) if !$nowdoc;
    $self->fail( "no string contents found" ) if !length $text;
    return $text;
}

# A raw string ends at a quote followed by as many hashes as it was opened
# with, so it is parsed as a whole.
sub rust_raw_string {
    my ( $self ) = @_;
    my ( undef, $hashes ) = $self->expect( qr/r(#*)"/ );
    my $close = qr/"\Q$hashes\E/;
    my $text = $self->raw_string_contents( $close );
    $self->expect( $close );
    return $text;
}

sub go_backtick_string_contents { shift->raw_string_contents( q[`] ) }

# Contents up to the given terminator pattern, as they are (PHP heredoc and
# nowdoc, Go backticks, Rust raw strings).
sub raw_string_contents {
    my ( $self, $stop ) = @_;
    my $text = $self->substring_before( $stop );
    $self->fail( "no string contents found" ) if !length $text;
    return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple::Scraper::Parser - parser to finds translation tokens in a code file

=head1 VERSION

version 0.200

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/locale-simple/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software, licensed under:

  The MIT (X11) License

=cut
