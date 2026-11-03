package Locale::Simple::PO2JSON;
# ABSTRACT: Convert a gettext PO file to the JSON data Locale::Simple reads in the browser
our $VERSION = '0.200';

use strict;
use warnings;

use Encode ();
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw( po2data data2json );

my %ESCAPE = (
    n => "\n", t => "\t", r => "\r", a => "\a",
    b => "\b", f => "\f", v => "\x0b", '\\' => '\\', '"' => '"',
);

sub _unquote {
    my ( $path, $n, $str ) = @_;
    $str =~ s{\\(?:([ntrabfv\\"])|([0-7]{1,3})|x([0-9a-fA-F]{1,2})|(.))}{
        defined $1 ? $ESCAPE{$1}
      : defined $2 ? chr( oct $2 )
      : defined $3 ? chr( hex $3 )
      : die "$path line $n: unknown escape sequence \\$4\n"
    }gse;
    return $str;
}

# One or more quoted strings on a line, as msgfmt reads them: "a" "b" is "ab".
my $STR  = qr/"(?:[^"\\]|\\.)*"/;
my $STRS = qr/$STR(?:\s*$STR)*/;

sub _unquote_all {
    my ( $path, $n, $strings ) = @_;
    my $val = '';
    $val .= _unquote( $path, $n, $1 ) while $strings =~ /"((?:[^"\\]|\\.)*)"/g;
    return $val;
}

sub _read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read PO file $path: $!\n";
    local $/;
    my $raw = <$fh>;
    close $fh;
    $raw = '' unless defined $raw;
    $raw =~ s/\A\xEF\xBB\xBF//;
    my $text = eval { Encode::decode( 'UTF-8', $raw, Encode::FB_CROAK() ) };
    die "Cannot read PO file $path: not valid UTF-8\n" unless defined $text;
    return $text;
}

sub _parse_header {
    my ($msgstr) = @_;
    my %h;
    for my $line ( split /\n/, $msgstr ) {
        next unless $line =~ /\A([^:]+):(.*)\z/;
        my ( $k, $v ) = ( $1, $2 );
        s/\A\s+|\s+\z//g for $k, $v;
        $h{$k} = $v;
    }
    $h{lang} = $h{Language} if defined $h{Language} && length $h{Language};
    return \%h;
}

sub po2data {
    my ( $path, %opt ) = @_;
    my $text = _read_file($path);

    my ( %entries, $header, $has_plural );
    my ( $cur, $field, $flags, $cur_flags ) = ( undef, undef, {} );

    my $finish = sub {
        return unless $cur;
        my $e = $cur;
        undef $cur;
        undef $field;
        my @str = map { defined $_ ? $_ : '' } @{ $e->{msgstr} };
        if ( !defined $e->{msgctxt} && $e->{msgid} eq '' ) {
            $header = _parse_header( $str[0] // '' );
            return;
        }
        return if $cur_flags->{fuzzy};
        return unless @str && length $str[0];
        $has_plural = 1 if defined $e->{msgid_plural};
        my $key = defined $e->{msgctxt} ? "$e->{msgctxt}\x04$e->{msgid}" : $e->{msgid};
        $entries{$key} = [ $e->{msgid_plural}, @str ];
    };

    my $n = 0;
    for my $line ( split /\r?\n/, $text ) {
        $n++;
        if ( $line =~ /\A\s*\z/ ) {
            $finish->();
            $flags = {};
        }
        elsif ( $line =~ /\A\s*#~/ ) {
            # obsolete entry, including #~| previous msgids
            $finish->();
            $flags = {};
        }
        elsif ( $line =~ /\A\s*#(.?)(.*)\z/ ) {
            my ( $kind, $rest ) = ( $1, $2 );
            $finish->() if $cur && $field =~ /\Amsgstr/;
            if ( $kind eq ',' ) {
                $flags->{$_} = 1 for grep { length } split /[\s,]+/, $rest;
            }
        }
        elsif ( $line =~ /\A\s*(msgctxt|msgid_plural|msgid|msgstr(?:\[(\d+)\])?)\s*($STRS)\s*\z/ ) {
            my ( $kw, $idx, $val ) = ( $1, $2, _unquote_all( $path, $n, $3 ) );
            if ( $kw eq 'msgctxt' || $kw eq 'msgid' ) {
                $finish->() if $cur && $field =~ /\Amsgstr/;
                if ( !$cur ) {
                    $cur       = { msgstr => [] };
                    $cur_flags = $flags;
                    $flags     = {};
                }
                die "$path line $n: $kw not allowed here\n"
                  if defined $cur->{$kw}
                  || ( $kw eq 'msgctxt' && defined $cur->{msgid} );
                $cur->{$kw} = $val;
                $field = $kw;
            }
            elsif ( $kw eq 'msgid_plural' ) {
                die "$path line $n: msgid_plural without msgid\n"
                  unless $cur && defined $cur->{msgid};
                $cur->{msgid_plural} = $val;
                $field = $kw;
            }
            else {
                die "$path line $n: $kw without msgid\n"
                  unless $cur && defined $cur->{msgid};
                $idx = 0 unless defined $idx;
                $cur->{msgstr}[$idx] = $val;
                $field = "msgstr[$idx]";
            }
        }
        elsif ( $line =~ /\A\s*($STRS)\s*\z/ ) {
            die "$path line $n: string without keyword\n" unless $cur && defined $field;
            my $val = _unquote_all( $path, $n, $1 );
            if ( $field =~ /\Amsgstr\[(\d+)\]\z/ ) { $cur->{msgstr}[$1] .= $val }
            else                                   { $cur->{$field} .= $val }
        }
        else {
            die "$path line $n: syntax error\n";
        }
    }
    $finish->();

    $header ||= {};
    warn "$path: no Plural-Forms header, keeping the plural forms as found\n"
      if $has_plural && !defined $header->{'Plural-Forms'};

    my $data = { '' => $header, %entries };
    $data = { $opt{domain} => $data } if defined $opt{domain};
    return $data;
}

sub data2json {
    my ( $data, %opt ) = @_;
    my $json = JSON::PP->new->canonical->utf8;
    $json->pretty if $opt{pretty};
    my $out = $json->encode($data);
    $out =~ s/\n\z//;
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple::PO2JSON - Convert a gettext PO file to the JSON data Locale::Simple reads in the browser

=head1 VERSION

version 0.200

=head1 SYNOPSIS

    use Locale::Simple::PO2JSON qw( po2data data2json );

    my $data = po2data('de.po');
    my $json = data2json( po2data( 'de.po', domain => 'myapp' ), pretty => 1 );

=head1 DESCRIPTION

Reads a gettext PO file and produces the data structure the JavaScript side of
L<Locale::Simple> loads: a header hash under the empty key and one entry per
translated message. Which entries are kept follows C<msgfmt>: entries with an
empty first translation, fuzzy entries (the header excepted) and obsolete
entries are left out.

=head2 po2data

    my $data = po2data( $path, domain => $name );

Returns a hash reference. The empty key holds the header (values trimmed, plus
C<lang> from C<Language>); every other key is the C<msgid>, or
C<"$msgctxt\x04$msgid"> with a context, and holds an array reference
C<[ $msgid_plural_or_undef, @msgstr ]>. With C<domain> the whole structure is
nested under that name. A file without C<Plural-Forms> header that contains
plural entries produces one warning; the entries keep the forms they have.
Dies with C<Cannot read PO file PATH: REASON> or C<PATH line N: REASON>.

=head2 data2json

    my $json = data2json( $data, pretty => 1 );

Encodes UTF-8 JSON with sorted keys and without trailing newline.

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
