package Locale::Utils::Autotranslator; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Encode qw(decode find_encoding);
use Locale::PO;
use Locale::TextDomain::OO::Util::ExtractHeader;
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(CodeRef Str);
use Try::Tiny;
use namespace::autoclean;

our $VERSION = '1.002';

# plural_ref e.g. ru
# The key is the plural form 0, 1 or 2.
# The value is the first number 0 .. that is resulting in that plural form.
# 0 => 1, # singular
# 1 => 2, # 2 .. 4 plural
# 2 => 5, # 5 .. plural
has _plural_ref => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

sub _clear_plural_ref {
    my $self = shift;

    %{ $self->_plural_ref } = ();

    return;
}

# to store the original gettext parts by placeholder number
# e.g.
# %*(%1,singular,plural,zero)
# 1 => [ '*', 'singular', 'plural'. 'zero' ],
# %quant(%2,singular,plural)
# 2 => [ 'quant', 'singular', 'plural' ],
has _gettext_ref => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

sub _clear_gettext_ref {
    my $self = shift;

    %{ $self->_gettext_ref } = ();

    return;
}

has _num_ref => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

sub _clear_num_ref {
    my $self = shift;

    %{ $self->_num_ref } = ();

    return;
}

has error => (
    is       => 'rw',
    init_arg => undef,
    writer   => '_error',
    clearer  => '_clear_error',
);

has translation_count => (
    is       => 'rw',
    init_arg => undef,
    writer   => '_translation_count',
);

sub _translation_count_increment {
    my $self = shift;

    $self->_translation_count( $self->translation_count + 1 );

    return;
}

has developer_language => (
    is      => 'ro',
    isa     => Str,
    default => 'en',
);

has language => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has before_translation_code => (
    is  => 'ro',
    isa => CodeRef,
);

has after_translation_code => (
    is  => 'ro',
    isa => CodeRef,
);

has comment => (
    is      => 'rw',
    isa     => Str,
    clearer => '_clear_comment',
);

# Coding schema:
# a .. w, z     => A .. W, Z
# A .. W, Z     => YA .. YW, YZ
# space         => YX
# open, e.g. {  => XX
# :             => XY
# close, e.g. } => XZ
# other         => XAA .. XPP
#                  like hex but
#                  0123456789ABCDEF is
#                  ABCDEFGHIJKLMNOP
# not valid     => XQ .. XW, YY

my $encode_az = sub {
    my $inner = shift;
    local *__ANON__ = '$encode_az->'; ## no critic (InterpolationOfMetachars LocalVars)

    my $encode_inner = sub {
        my ( $lc, $uc, $space, $colon, $other ) = @_;
        local *__ANON__ = '$encode_inner->'; ## no critic (InterpolationOfMetachars LocalVars)

        defined $lc
            and return uc $lc;
        defined $uc
            and return q{Y} . $uc;
        defined $space
            and return 'YX';
        defined $colon
            and return 'XY';

        $other = ord $other;
        $other > 255 ## no critic (MagicNumbers)
            and confess 'encode error Xnn overflow';
        my $digit2 = int $other / 16; ## no critic (MagicNumbers)
        my $digit1 = $other % 16; ## no critic (MagicNumbers)
        for my $digit ( $digit2, $digit1 ) {
            $digit = [ q{A} .. q{P} ]->[$digit];
        }

        return q{X} . $digit2 . $digit1;
    };

    $inner =~ s{
        ( [a-wz] )
        | ( [A-WZ] )
        | ( [ ] )
        | ( [:] )
        | ( . )
    }
    {
        $encode_inner->($1, $2, $3, $4, $5, $6)
    }xmsge;

    return 'XX'. $inner . 'XZ';
};

sub _encode_named_placeholder {
    my ( $self, $placeholder ) = @_;

    ## no critic (EscapedMetacharacters)
    $placeholder =~ s{
        ( \\ \{ )
        | \{ ( [^\{\}]* ) \}
    }
    {
        $1
        || $encode_az->($2)
    }xmsge;
    ## use critic (EscapedMetacharacters)

    return $placeholder;
}

my $decode_inner = sub {
    my $inner = shift;
    local *__ANON__ = '$decode_inner->'; ## no critic (InterpolationOfMetachars LocalVars)

    my @chars = $inner =~ m{ (.) }xmsg;
    my $decoded = q{};
    CHAR:
    while ( @chars ) {
        my $char = shift @chars;
        if ( $char =~ m{ \A [A-WZ] \z }xms ) {
            $decoded .= lc $char;
            next CHAR;
        }
        if ( $char eq q{Y} ) {
            @chars
                or return "DECODE_ERROR_Y($inner)";
            my $char2 = shift @chars;
            $decoded .= $char2 eq q{X}
                ? q{ }
                : uc $char2;
            next CHAR;
        }
        if ( $char eq q{X} ) {
            @chars
                or return "DECODE_ERROR_Xn($inner)";
            my $char2 = shift @chars;
            if ( $char2 eq q{Y} ) {
                $decoded .= q{:};
                next CHAR;
            }
            @chars
                or return "DECODE_ERROR_Xnn($inner)";
            my $char3 = shift @chars;
            my $decode_string = 'ABCDEFGHIJKLMNOP';
            my $index2 = index $decode_string, $char2;
            $index2 == -1 ## no critic (MagicNumbers)
                and return "DECODE_ERROR_X?($inner)";
            my $index1 = index $decode_string, $char3;
            $index1 == -1 ## no critic (MagicNumbers)
                and return "DECODE_ERROR_Xn?($inner)";
            $decoded .= chr $index2 * 16 + $index1; ## no critic (MagicNumbers)
            next CHAR;
        }
        return "DECODE_ERROR($inner)";
    }

    return $decoded;
};

sub _decode_named_placeholder {
    my ( $self, $placeholder ) = @_;

    $placeholder =~ s{
        XX
        ( [[:upper:]]+ )
        XZ
    }
    {
        q[{] . $decode_inner->($1) . q[}]
    }xmsge;

    return $placeholder;
}

sub _prepare_plural {
    my ( $self, $nplurals, $plural_code ) = @_;

    exists $self->_plural_ref->{0}
        and return;

    ## no critic (MagicNumbers)
    NUMBER:
    for ( 0 .. 1000 ) {
        my $plural = $plural_code->($_);
        if ( $plural > ( $nplurals - 1 ) ) {
            confess sprintf
                'Using plural formula with value %s. Got index %s. nplurals is %s. Then the maximal expected index is %s',
                $_,
                $plural,
                $nplurals,
                $nplurals - 1;
        }
        if ( ! exists $self->_plural_ref->{$plural} ) {
            $self->_plural_ref->{$plural} = $_;
        }
        $nplurals == ( keys %{ $self->_plural_ref } )
            and last NUMBER;
    }
    ## use critic (MagicNumbers)

    return;
}

sub translate { ## no critic (ExcessComplexity)
    my ( $self, $name_read, $name_write ) = @_;

    defined $name_read
        or confess 'Undef is not a name of a po/pot file';
    defined $name_write
        or confess 'Undef is not a name of a po file';
    my $pos_ref = Locale::PO->load_file_asarray($name_read)
        or confess "$name_read is not a valid po/pot file";

    my $header = Locale::TextDomain::OO::Util::ExtractHeader
        ->instance
        ->extract_header_msgstr(
            Locale::PO->dequote(
                $pos_ref->[0]->msgstr
                    || confess "No header found in file $name_read",
            ),
        );
    my $charset     = $header->{charset};
    my $encode_obj  = find_encoding($charset);
    my $nplurals    = $header->{nplurals};
    my $plural_code = $header->{plural_code};
    $self->_clear_error;
    $self->_clear_plural_ref;
    my $entry_ref = { encode_obj => $encode_obj };

    $self->_translation_count(0);
    try {
        MESSAGE:
        for my $po ( @{$pos_ref}[ 1 .. $#{$pos_ref} ] ) { # without 0 = header
            $self->_clear_comment;
            $entry_ref->{msgid}
                = $po->msgid
                && $encode_obj->decode( $po->dequote( $po->msgid ) );
            $entry_ref->{msgid_plural}
                = defined $po->msgid_plural
                && $encode_obj->decode( $po->dequote( $po->msgid_plural ) );
            $entry_ref->{msgstr}
                = defined $po->msgstr
                && $po->dequote( $po->msgstr );
            length $entry_ref->{msgstr}
                and next MESSAGE;
            $entry_ref->{msgstr_n} = {};
            my $msgstr_n = $po->msgstr_n || {};
            my $is_all_translated = 1;
            for my $index ( 0 .. ( $nplurals - 1 ) ) {
                $entry_ref->{msgstr_n}->{$index}
                    = defined $msgstr_n->{$index}
                    && $po->dequote( $msgstr_n->{$index} );
                my $is_translated
                    = defined $entry_ref->{msgstr_n}->{$index}
                    && length $entry_ref->{msgstr_n}->{$index};
                $is_all_translated &&= $is_translated;
            }
            $is_all_translated
                and next MESSAGE;
            if ( length $entry_ref->{msgid_plural} ) {
                if ( $nplurals ) {
                    $self->_prepare_plural($nplurals, $plural_code);
                }
                $self->_translate_named_plural($entry_ref, $po);
            }
            ## no critic (EscapedMetacharacters)
            elsif ( $entry_ref->{msgid} =~ m{ \{ [^\{\}]+ \} }xms ) {
                $self->_translate_named($entry_ref, $po);
            }
            ## use critic (EscapedMetacharacters)
            elsif ( $entry_ref->{msgid} =~ m{ [%] (?: \d | [*] | quant ) }xms ) {
                $self->_translate_gettext($entry_ref, $po);
            }
            else {
                $self->_translate_simple($entry_ref, $po);
            }
            $self->_update_comment($po);
        }
        if ( $self->translation_count ) {
            Locale::PO->save_file_fromarray($name_write, $pos_ref);
        }
    }
    catch {
        if ( $self->translation_count ) {
            Locale::PO->save_file_fromarray($name_write, $pos_ref);
        }
        m{ \A \QAPI error\E | \A (?: Before | After ) \Q translation break\E \b }xms
            or confess $_;
    };

    return $self;
}

sub _encode_named {
    my ( $self, $msgid, $num ) = @_;

    $num = defined $num ? $num : 1;
    $self->_clear_num_ref;
    my $encode_placeholder = sub {
        my ( $placeholder, $is_num ) = @_;
        local *__ANON__ = '$encode_placeholder->'; ## no critic (InterpolationOfMetachars LocalVars)
        if ( $is_num ) {
            $self->_num_ref->{$num} = $placeholder;
            return $num++;
        }
        return $self->_encode_named_placeholder($placeholder);
    };
    ## no critic (EscapedMetacharacters)
    $msgid =~ s{
        ( \\ \{ )
        | (
            \{
            [^\{\}:]+
            ( [:] ( num )? [^\{\}]* )?
            \}
        )
    }
    {
        $1
        || $encode_placeholder->($2, $3)
    }xmsge;
    ## use critic (EscapedMetacharacters)

    return $msgid;
}

sub _decode_named {
    my ( $self, $msgstr ) = @_;

    $msgstr =~ s{ ( \d+ ) }{
        exists $self->_num_ref->{$1} ? $self->_num_ref->{$1} : $1
    }xmsge;
    $msgstr = $self->_decode_named_placeholder($msgstr);

    return $msgstr;
}

sub _translate_named {
    my ( $self, $entry_ref, $po ) = @_;

    my $msgid = $self->_encode_named( $entry_ref->{msgid} );
    my $msgstr = $self->_translate_with_api($msgid);
    $msgstr = $self->_decode_named($msgstr);
    $po->msgstr( $entry_ref->{encode_obj}->encode($msgstr) );

    return;
}

sub _translate_named_plural {
    my ( $self, $entry_ref, $po ) = @_;

    my $msgid        = $entry_ref->{msgid};
    my $msgid_plural = $entry_ref->{msgid_plural};
    MSGSTR_N:
    for my $index ( sort keys %{ $self->_plural_ref } ) {
        defined $entry_ref->{msgstr_n}->{$index}
            and length $entry_ref->{msgstr_n}->{$index}
            and next MSGSTR_N;
        my $any_msgid = $self->_encode_named(
            $index
                ? ( $msgid_plural, $self->_plural_ref->{$index} )
                : $msgid,
        );
        my $any_msgstr = $self->_translate_with_api($any_msgid);
        $any_msgstr = $self->_decode_named($any_msgstr);
        $po->msgstr_n->{$index}
           = $po->quote( $entry_ref->{encode_obj}->encode($any_msgstr) );
    }

    return;
}

sub _encode_gettext_inner { ## no critic (ManyArgs)
    my ( $self, $quant, $number, $inner, $singular, $plural, $zero ) = @_;

    $self->_gettext_ref->{$inner} ||= [
        map {
            ( defined && length )
            ? $self->_translate_with_api($_)
            : undef;
        } $singular, $plural, $zero
    ];

    return $encode_az->("$quant,$number,$inner");
}

sub _encode_gettext {
    my ( $self, $msgid ) = @_;

    ## no critic (ComplexRegexes)
    $msgid =~ s{
        ( %% )                    # escaped
        |
        [%] ( [*] | quant ) [(]   # quant
        [%] ( \d+ ) [,]           # number
        (                         # inner
            ( [^,)]* )            # singular
            [,] ( [^,)]* )        # plural
            (?: [,] ( [^,)]* ) )? # zero
        )
        [)]
        |
        [%] ( \d+ )               # simple
    }
    {
        $1
        ? $1
        : $2
        ? $self->_encode_gettext_inner($2, $3, $4, $5, $6, $7)
        : $encode_az->($8)
    }xmsge;
    ## use critic (ComplexRegexes)

    return $msgid;
}

sub _decode_gettext_inner {
    my ( $self, $inner ) = @_;

    $inner = $decode_inner->($inner);
    if ( $inner =~ m{ \A ( \d+ ) \z }xms ) {
        return q{%} . $1;
    }
    if ( $inner =~ m{ \A ( [*] | quant ) [,] ( \d+ ) [,] ( .* ) \z }xms ) {
        my ( $quant, $number, $plural ) = ( $1, $2, $self->_gettext_ref->{$3} );
        return join q{},
            q{%},
            $quant,
            q{(},
            ( join q{,}, "%$number", grep { defined } @{$plural}[ 0 .. 2 ] ),
            q{)};
    }

    return "DECODE_ERROR($inner)";
}

sub _decode_gettext {
    my ( $self, $msgstr ) = @_;

    $msgstr =~ s{
        XX
        ( [[:upper:]]+? )
        XZ
    }
    {
        $self->_decode_gettext_inner($1)
    }xmsge;

    return $msgstr;
}

sub _translate_gettext {
    my ( $self, $entry_ref, $po ) = @_;

    $self->_clear_gettext_ref;
    my $msgid = $self->_encode_gettext( $entry_ref->{msgid} );
    my $msgstr = $self->_translate_with_api($msgid);
    $msgstr = $self->_decode_gettext($msgstr);
    $po->msgstr( $entry_ref->{encode_obj}->encode($msgstr) );

    return;
}

sub _translate_simple {
    my ( $self, $entry_ref, $po ) = @_;

    $po->msgstr(
        $entry_ref->{encode_obj}->encode(
            $self->_translate_with_api( $entry_ref->{msgid} ),
        ),
    );

    return;
}

sub _update_comment {
    my ( $self, $po ) = @_;

    defined $self->comment
        or return;
    length $self->comment
        or return;
    if ( ! defined $po->comment ) {
        $po->comment( $self->comment );
        return;
    }
    my @lines
        = grep {
            $_ ne $self->comment;
        }
        $po->comment =~ m{ [\n]* ( [^\n]+ ) }xmsg;
    $po->comment( join "\n", $self->comment, @lines );

    return;
}

sub _translate_with_api {
    my ( $self, $msgid ) = @_;

    $self->error
        and die "API error\n";
    if ( $self->before_translation_code ) {
        $self->before_translation_code->($self, $msgid)
            or die "Before translation break\n";
    }
    my $msgstr = try {
        $self->translate_text($msgid);
    }
    catch {
        $self->_error( ( defined && length ) ? $_ : 'unknown error' );
        q{};
    };
    $self->error
        and die "API error\n";
    $msgstr =~ s{ [\x{0}\x{4}] }{}xmsg; # because of mo file conflicts
    $self->_translation_count_increment;
    if ( $self->after_translation_code ) {
        $self->after_translation_code->($self, $msgid, $msgstr)
            or die "After translation break\n";
    }

    return $msgstr;
}

sub translate_text {
    my ( $self, $msgid ) = @_;

    return q{};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::Utils::Autotranslator - Base class to translate automaticly

$Id: Autotranslator.pm 641 2017-02-24 13:14:23Z steffenw $

$HeadURL: $

=head1 VERSION

1.002

=head1 SYNOPSIS

    package MyAutotranslator;

    use Moo;

    extends qw(
        Locale::Utils::Autotranslator
    );

    sub translate_text {
        my ( $self, $text ) = @_;

        my $translation = MyTranslatorApi
            ->new(
                from => $self->developer_language,
                to   => $self->language,
            )
            ->translate($text);

        return $translation;
    }

How to use see L<Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet|Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet>.

    my $obj = MyAutotranslator->new(
        language                => 'de',
        # all following parameters are optional
        developer_language      => 'en', # en is the default
        before_translation_code => sub {
            my ( $self, $msgid ) = @_;
            ...
            return 1; # true: translate, false: skip translation
        },
        after_translation_code  => sub {
            my ( $self, $msgid, $msgstr ) = @_;
            ...
            return 1; # true: translate, false: skip translation
        },
    );
    $identical_obj = $obj->translate(
        'mydir/de.pot',
        'mydir/de.po',
    );
    my $translation_count = $obj->translation_count;

Return code of E.g. you have a limit of 100 free translations or 10000 words for 1 day
you can skip further translations by return any false.

Use that methods for debugging output.

=head1 DESCRIPTION

Base class to translate automaticly.

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method developer_language

Get back the language of all msgid's. The default is 'en';

=head2 method language

Get back the language you want to translate.

=head2 before_translation_code, after_translation_code

Get back the code references:

$code_ref = $obj->before_translation_code;
$code_ref = $obj->after_translation_code;

=head2 method translate

    $obj->translate('dir/de.pot', 'dir/de.po');

That means:
Read the de.pot file (also possible *.po).
Translate the missing stuff.
Write back to de.po file.

=head2 method translate_text

In base class there is only a dummy method that returns C<q{}>.

The subclass has to implement that method.
Check the code of
L<Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet|Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet>
to see how to implement.

=head2 method comment

Set a typical comment to mark the translation as translated by ... in API class.
Get back that comment.

E.g.

    $self->comment('translated by: api.mymemory.translated.net');

=head2 method translation_count

Get back the count of translations.
This is not the count of translated messages,
this is the count of successful translate_text calls.

my $translation_count = $obj->translation_count;

=head2 method error

Get back the error message if method translate_text dies.

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Encode|Encode>

L<Locale::PO|Locale::PO>

L<Locale::TextDomain::OO::Util::ExtractHeader|Locale::TextDomain::OO::Util::ExtractHeader>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<MooX::Types::MooseLike::Numeric|MooX::Types::MooseLike::Numeric>

L<Try::Tiny|Try::Tiny>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Gettext>

L<Locale::TextDomain::OO|Locale::TextDomain::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
