package Locale::Maketext::Lexicon::Getcontext;

use strict;

use Locale::Maketext::Lexicon::Gettext;

our $VERSION = "0.05";
my ( $InputEncoding, $OutputEncoding, $DoEncoding );

sub input_encoding  {$InputEncoding}
sub output_encoding {$OutputEncoding}

# functions
*parse_mo           = \&Locale::Maketext::Lexicon::Gettext::parse_mo;
*_unescape          = \&Locale::Maketext::Lexicon::Gettext::_unescape;
*_gettext_to_maketext
    = \&Locale::Maketext::Lexicon::Gettext::_gettext_to_maketext;



#
# parse()
# -----
# copy-pasted from Locale::Maketext::Lexicon::Gettext, with s/msgid/msgctxt/g
#
sub parse {
    my $self = shift;
    my ( %var, $key, @ret );
    my @metadata;
    my @comments;
    my @fuzzy;

    $InputEncoding = $OutputEncoding = $DoEncoding = undef;

    use Carp;
    Carp::cluck "Undefined source called\n" unless defined $_[0];

    # Check for magic string of MO files
    return parse_mo( join( '', @_ ) )
        if ( $_[0] =~ /^\x95\x04\x12\xde/ or $_[0] =~ /^\xde\x12\x04\x95/ );

    local $^W;    # no 'uninitialized' warnings, please.

    require Locale::Maketext::Lexicon;
    my $KeepFuzzy = Locale::Maketext::Lexicon::option('keep_fuzzy');
    my $UseFuzzy  = $KeepFuzzy
        || Locale::Maketext::Lexicon::option('use_fuzzy');
    my $AllowEmpty = Locale::Maketext::Lexicon::option('allow_empty');
    my $process    = sub {
        if ( length( $var{msgstr} ) and ( $UseFuzzy or !$var{fuzzy} ) ) {
            push @ret, ( map transform($_), @var{ 'msgctxt', 'msgstr' } );
        }
        elsif ($AllowEmpty) {
            push @ret, ( transform( $var{msgctxt} ), '' );
        }
        if ( $var{msgctxt} eq '' ) {
            push @metadata, parse_metadata( $var{msgstr} );
        }
        else {
            push @comments, $var{msgctxt}, $var{msgcomment};
        }
        if ( $KeepFuzzy && $var{fuzzy} ) {
            push @fuzzy, $var{msgctxt}, 1;
        }
        %var = ();
    };

    # Parse PO files
    foreach (@_) {
        s/[\015\012]*\z//;    # fix CRLF issues

        /^(msgctxt|msgid|msgstr) +"(.*)" *$/
            ? do {            # leading strings
            $var{$1} = $2;
            $key = $1;
            }
            :

            /^"(.*)" *$/
            ? do {            # continued strings
            $var{$key} .= $1;
            }
            :

            /^# (.*)$/
            ? do {            # user comments
            $var{msgcomment} .= $1 . "\n";
            }
            :

            /^#, +(.*) *$/
            ? do {            # control variables
            $var{$_} = 1 for split( /,\s+/, $1 );
            }
            :

            /^ *$/ && %var
            ? do {            # interpolate string escapes
            $process->($_);
            }
            : ();

    }

    # do not silently skip last entry
    $process->() if keys %var != 0;

    push @ret, map { transform($_) } @var{ 'msgctxt', 'msgstr' }
        if length $var{msgstr};
    push @metadata, parse_metadata( $var{msgstr} )
        if $var{msgctxt} eq '';

    return wantarray
        ? ( { @metadata, @ret }, {@comments}, {@fuzzy} )
        : ( { @metadata, @ret } );

}


#
# parse_metadata()
# --------------
# copy-pasted from Locale::Maketext::Lexicon::Gettext, with no change,
# because it accesses the $InputEncoding and $OutputEncoding vars
#
sub parse_metadata {
    return map {
              (/^([^\x00-\x1f\x80-\xff :=]+):\s*(.*)$/)
            ? ( $1 eq 'Content-Type' )
                ? do {
                    my $enc = $2;
                    if ( $enc =~ /\bcharset=\s*([-\w]+)/i ) {
                        $InputEncoding = $1 || '';
                        $OutputEncoding
                            = Locale::Maketext::Lexicon::encoding()
                            || '';
                        $InputEncoding = 'utf8'
                            if $InputEncoding =~ /^utf-?8$/i;
                        $OutputEncoding = 'utf8'
                            if $OutputEncoding =~ /^utf-?8$/i;
                        if (Locale::Maketext::Lexicon::option('decode')
                            and ( !$OutputEncoding
                                or $InputEncoding ne $OutputEncoding )
                            )
                        {
                            require Encode::compat if $] < 5.007001;
                            require Encode;
                            $DoEncoding = 1;
                        }
                    }
                    ( "__Content-Type", $enc );
                }
                : ( "__$1", $2 )
            : ();
    } split( /\r*\n+\r*/, transform(pop) );
}


#
# transform()
# ---------
# copy-pasted from Locale::Maketext::Lexicon::Gettext, with no change,
# because it accesses the $InputEncoding and $OutputEncoding vars
#
sub transform {
    my $str = shift;

    if ( $DoEncoding and $InputEncoding ) {
        $str
            = ( $InputEncoding eq 'utf8' )
            ? Encode::decode_utf8($str)
            : Encode::decode( $InputEncoding, $str );
    }

    $str =~ s/\\([0x]..|c?.)/qq{"\\$1"}/eeg;

    if ( $DoEncoding and $OutputEncoding ) {
        $str
            = ( $OutputEncoding eq 'utf8' )
            ? Encode::encode_utf8($str)
            : Encode::encode( $OutputEncoding, $str );
    }

    return Locale::Maketext::Lexicon::option('disable_maketext_conversion')
            ? $str : _gettext_to_maketext($str);
}


__PACKAGE__

__END__

=encoding UTF-8

=head1 NAME

Locale::Maketext::Lexicon::Getcontext - PO file parser for Maketext

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Called via B<Locale::Maketext::Lexicon>:

    package Hello::I18N;
    use base 'Locale::Maketext';
    use Locale::Maketext::Lexicon {
        de => [Getcontext => 'hello/de.po'],
    };

Directly calling C<parse()>:

    use Locale::Maketext::Lexicon::Getcontext;
    my %Lexicon = %{ Locale::Maketext::Lexicon::Getcontext->parse(<DATA>) };
    __DATA__
    #: Hello.pm:10
    msgid "Hello, World!"
    msgstr "Hallo, Welt!"

    #: Hello.pm:11
    msgid "You have %quant(%1,piece) of mail."
    msgstr "Sie haben %quant(%1,Poststueck,Poststuecken)."

=head1 WARNING

This module is a very experimental fork/variant of
L<Locale::Maketext::Lexicon::Gettext> where messages are fetched by
their C<msgctxt> instead of their C<msgid>. It is currently mostly
developed to help the I18N of L<OpenFoodFacts|http://openfoodfacts.org/>
and L<OpenBeautyFacts|http://openbeautyfacts.org/>. You probably don't
want to use this, unless you really now what you are doing.

=head1 DESCRIPTION

This module implements a perl-based C<Gettext> parser for
B<Locale::Maketext>. It transforms all C<%1>, C<%2>, <%*>... sequences
to C<[_1]>, C<[_2]>, C<[_*]>, and so on.  It currently accepts only
plain PO files.

This module also looks for C<%I<function>(I<args...>)>
in the lexicon strings, and transform it to C<[I<function>,I<args...>]>.
Any C<%1>, C<%2>... sequences inside the I<args> will have their percent
signs (C<%>) replaced by underscores (C<_>).

The name of I<function> above should begin with a letter or underscore,
followed by any number of alphanumeric characters and/or underscores.
As an exception, the function name may also consist of a single asterisk
(C<*>) or pound sign (C<#>), which are C<Locale::Maketext>'s shorthands
for C<quant> and C<numf>, respectively.

As an additional feature, this module also parses MIME-header style
metadata specified in the null msgstr (C<"">), and add them to the
C<%Lexicon> with a C<__> prefix.  For example, the example above will
set C<__Content-Type> to C<text/plain; charset=iso8859-1>, without
the newline or the colon.

Any normal entry that duplicates a metadata entry takes precedence.
Hence, a C<msgid "__Content-Type"> line occurs anywhere should override
the above value.

=head1 OPTIONS

=head2 use_fuzzy

When parsing PO files, fuzzy entries (entries marked with C<#, fuzzy>)
are silently ignored.  If you wish to use fuzzy entries, specify a true
value to the C<_use_fuzzy> option:

    use Locale::Maketext::Lexicon {
        de => [Getcontext => 'hello/de.po'],
            _use_fuzzy => 1,
    };

=head2 allow_empty

When parsing PO files, empty entries (entries with C<msgstr "">) are
silently ignored.  If you wish to allow empty entries, specify a true
value to the C<_allow_empty> option:

    use Locale::Maketext::Lexicon {
        de => [Getcontext => 'hello/de.po'],
            _allow_empty => 1,
    };

=head2 disable_maketext_conversion

After parsing PO files, the strings are converted from the Gettext syntax
to the Maketext syntax.  If you wish to disable this, specify a true value
to the C<_disable_maketext_conversion> option:

    use Locale::Maketext::Lexicon {
        de => [Getcontext => 'hello/de.po'],
            _disable_maketext_conversion => 1,
    };


=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>,
L<Locale::Maketext::Lexicon::Gettext>

=head1 AUTHORS

=over

=item Sébastien Aperghis-Tramoni <saper@cpan.org>

=item Clinton Gormley <drtech@cpan.org>

=item Audrey Tang <cpan@audreyt.org>

=back

=head1 COPYRIGHT

Copyright 2002-2014 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

