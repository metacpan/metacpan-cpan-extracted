package Font::FreeType::NamedInfo;
use warnings;
use strict;

1;

__END__

=head1 NAME

Font::FreeType::NamedInfo - information from 'names table' in font file

=head1 SYNOPSIS

    use Font::FreeType;

    my $freetype = Font::FreeType->new;
    my $face = $freetype->face('Vera.ttf');
    my $infos = $face->namedinfos;
    if($infos && @$infos) {
      say $_->string for(@$infos);
    }


=head1 DESCRIPTION

The TrueType and OpenType specifications allow the inclusion of a special
I<names table> in font files. This table contains textual (and internationalized)
information regarding the font, like family name, copyright, version, etc.

Possible values for I<platform_id>, I<encoding_id>, I<language_id>, and
I<name_id> are given in the file I<ttnameid.h> from FreeType distribution. For
details please refer to the TrueType or OpenType specification.

=head1 METHODS

=over 4

=item platform_id

=item encoding_id

=item language_id

=item name_id

=item string

The I<name> string. Note that its format differs depending on the (platform,
 encoding) pair. It can be a Pascal String, a UTF-16 one, etc.

Generally speaking, the string is not zero-terminated. Please refer to the
TrueType specification for details.

=back


=cut
