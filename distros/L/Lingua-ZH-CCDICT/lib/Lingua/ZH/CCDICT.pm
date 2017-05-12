package Lingua::ZH::CCDICT;

use strict;
use warnings;

use 5.006001;

use vars qw ($VERSION);

$VERSION = '0.05';

use File::Spec;
use Params::Validate qw(:all);
use Sub::Name qw( subname );
use Lingua::ZH::CCDICT::Romanization;
use Lingua::ZH::CCDICT::Romanization::Pinyin;

my %storage;
BEGIN { %storage = map { lc $_ => $_ } ( qw( InMemory XML BerkeleyDB ) ) }


sub new
{
    my $class = shift;
    my %p = validate_with( params => \@_,
                           spec   =>
                           { storage =>
                             { callbacks =>
                               { 'is a valid storage type' =>
                                 sub { $storage{ lc $_[0] } } },
                             },
                           },
                           allow_extra => 1,
                         );

    my $storage_class = __PACKAGE__ . '::Storage::' . $storage{ lc delete $p{storage} };

    eval "use $storage_class";
    die $@ if $@;

    return $storage_class->new(%p);
}

my %Ignore = map { $_ => 1 } qw( fUTF8 fCNS11643 fGB fBig5 );

my %CCDICTToInternal =
    ( fTotalStrokes => 'stroke_count',
      fCangjie      => 'cangjie',
      fFourCorner   => 'four_corner',
    );

my %RomanizationToInternal =
    ( fHakka        => 'pinjim',
      fCantonese    => 'jyutping',
      fMandarin     => 'pinyin',
    );

my %RomanizationType = map { $_ => 1 } values %RomanizationToInternal;

sub parse_source_file
{
    my $self = shift;
    my $file = shift;
    my $status_fh = $ENV{CCDICT_VERBOSE} ? \*STDERR : undef;
    my $lines_per = 5000;

    unless ( defined $file )
    {
        my $pack_as_file = File::Spec->catfile( split /::/, __PACKAGE__ );
        $pack_as_file .= '.pm';

        (my $dir = $INC{$pack_as_file}) =~ s/\.pm$//;

        $file = File::Spec->catfile( $dir, 'Data.pm' );
    }

    open my $fh, '<', $file
        or die "Cannot read $file: $!";

    my $last_char;
    my %entry;
    while (<$fh>)
    {
        chomp;

        next unless substr( $_, 0, 1 ) eq 'U';

        my ( $unicode, $type, $data ) = split /\t/, $_, 3;

        s/^\s+|\s+$//g for $unicode, $type, $data;

        next if $Ignore{$type};

        my ( $codepoint, $homograph ) = $unicode =~ /U\+([\dABCDEF]+)\.(\d)/;

        die "Bad line (line #$.):\n$_\n\n" unless $codepoint;

        # not sure how to handle this, to be honest.
        next if $homograph;

        # generate a real Unicode character in Perl
        my $unicode_char = chr( hex($codepoint) );

        $last_char = $unicode_char unless defined $last_char;

        # this relies on the fact that data for each char is grouped
        # together on consecutive lines in the ccdict.txt file.
        if ( $unicode_char ne $last_char )
        {
            $self->_add_entry( $last_char, { %entry, unicode => $last_char } );

            %entry = ();

            $last_char = $unicode_char;
        }

        if ( exists $CCDICTToInternal{$type} )
        {
            my $internal = $CCDICTToInternal{$type};

            $entry{$internal} = $data;
        }
        elsif ( exists $RomanizationToInternal{$type} )
        {
            my $internal = $RomanizationToInternal{$type};

            my $class = $self->_romanization_class($internal);

            my $is_obsolete = 0;
            foreach my $syl ( split /[\s;]+/, $data )
            {
                # Deal with various mysterious bits and mistakes
                next if $syl eq '}';
                next if $syl eq '(also)';
                next if $syl eq '(old)';

                next if $syl =~ /^p?\d+$/;

                next if $syl =~ /^\(coll/;

                $syl =~ s/^{?([^}]+)}$/$1/;
                $syl =~ s/{[^}]+}?$//;

                if ( $syl eq 'obs' )
                {
                    $is_obsolete = 1;
                    next;
                }

                my $romanized = $class->new( syllable => $syl,
                                             obsolete => $is_obsolete,
                                           );

                next unless $romanized;

                push @{ $entry{$internal} }, $romanized;
            }
        }
        elsif ( $type eq 'fR/S' )
        {
            my ( $radical, $index ) = split /\./, $data;

            $entry{radical} = $radical;
            $entry{index} = $index;
        }
        elsif ( $type eq 'fEnglish' )
        {
            $entry{english} =
                [ grep { defined && length } split /\s*\[\d\d?\]\s*/, $data ];
        }
        else
        {
            die "Invalid line: $_\n";
        }

        if (  ! ( $. % $lines_per ) && $status_fh )
        {
            print $status_fh "$. lines processed\n";
        }
    }

    $self->_add_entry( $last_char, { %entry, unicode => $last_char } );
}

sub _add_entry
{
    my $self    = shift;
    my $unicode = shift;
    my $entry   = shift;

    return unless defined $entry->{radical};

    $self->_real_add_entry( $unicode, $entry );
}

sub _romanization_class
{
    return
        ( $_[1] eq 'pinyin' ?
          'Lingua::ZH::CCDICT::Romanization::Pinyin' :
          'Lingua::ZH::CCDICT::Romanization'
        );
}

sub _is_romanization_type
{
    return $RomanizationType{ $_[1] };
}

sub _InternalTypes
{
    return values %CCDICTToInternal, values %RomanizationToInternal, 'index', 'radical';
}

# Some of these may be overridden in subclasses, but they provide an
# easy default
foreach my $type ( __PACKAGE__->_InternalTypes() )
{
    my $sub =
        __PACKAGE__->_is_romanization_type($type)
        ? sub { my $s = shift;
                $s->_match( $type => map { lc } @_ ) }
        : sub { my $s = shift;
                $s->_match( $type => @_ ) };

    my $sub_name = "match_$type";
    no strict 'refs';

    *{$sub_name} = subname $sub_name => $sub;
}


1;

__END__


=head1 NAME

Lingua::ZH::CCDICT - An interface to the CCDICT Chinese dictionary

=head1 SYNOPSIS

  use Lingua::ZH::CCDICT;

  my $dict = Lingua::ZH::CCDICT->new( storage => 'InMemory' );

=head1 DESCRIPTION

This module provides a Perl interface to the CCDICT dictionary created
by Thomas Chin. This dictionary is indexed by Unicode character number
(traditional character), and contains information about these
characters.

CCDICT is released under a Creative Commons Attribution License
(version 2.5).

The dictionary contains the following information, though not all
information is avaialable for every character.

=over 4

=item * Radical number

The number of the radical. Always available.

=item * Index

The total number of strokes minus the number of strokes in the
radical. Always available.

=item * Total stroke count

The total number of strokes in the character.

=item * Cangjie

The Cangjie Chinese input system code.

=item * Four Corner

The Four Corner Chinese input system code.

=back

In addition, the dictionary contains English definitions (often
multiple definitions), and romanizations for the character in
different languages and systems. The romanizations available include
Pinjim for Hakka, Jyutping for Cantonese and (Hanyu) Pinyin for
Mandarin.

=head1 DICTIONARY BUGS

The CCDICT dictionary is distributed by Thomas Chin in a simple but
non-standard, textual ASCII-only format. I've tried to work around
errors or ambiguities in the dictionary data, although there are
probably still oddities lurking. Please send bug reports to me so I
can figure out whether the error is in my code or the dictionary
itself.

=head1 STORAGE

This module is capable of parsing the CCDICT format file, and can also
store the data in other formats (just Berkeley DB fo rnow).

Each storage system is implemented via a module in the
C<Lingua::ZH::CCDICT::Storage::*> class hierarchy. All of these
modules are subclasses of C<Lingua::ZH::CCDICT> class, and implement
its methods for searching the dictionary.

In addition some storage classes may offer additional methods.

=head2 Storage Subclasses

The following storage subclasses are available:

=over 4

=item * Lingua::ZH::CCDICT::Storage::InMemory

This class stores the entire parsed dictionary in memory.

=item * Lingua::ZH::CCDICT::Storage::BerkeleyDB

This class can convert the CCDICT source file to a set of BerkeleyDB
files.

=back

=head1 USAGE

This module allows you to look up information in the dictionary based
on a number of keys. These include the Unicode character (as a
character, not its number), stroke count, radical number, and any of
the various romanization systems.

=head1 METHODS

This class provides the following methods.

=head2 Lingua::ZH::CCDICT->new(...)

This method always takes at least one parameter, "storage". This
indicates what storage subclass to use. The current options are
"InMemory" and "BerkeleyDB".

Any other parameters given will be passed to the appropriate
subclass's C<new()> method.

=head2 $dict->parse_source_file($filename)

If you don't specify a file, then it will use the data file
distributed with this module. This is probably what you want, unless
you have a local copy of the dictionary that you want to work
with. Note that the dictionary format has changes a fair bit between
versions, so this probably won't work with much older or newer
versions of the CCDICT data.

This method is what does the real work of creating a dictionary. Note
that if you are not using the InMemory storage subclass, you only need
to parse the source file once, and then you can reuse the stored data.

=head1 MATCH METHODS

When doing a lookup based on the romanization of a character, the tone
is indicated with a number at the end of the syllable, as opposed to
using the Unicode character combining the latin letter with the
diacritic.

In addition, lookups based on a Pinyin romanization should use the
u-with-umlaut character (character 252 in Unicode) rather than two "u"
characters.

The return value for any lookup will be an object in a
C<Lingua::ZH::CCDICT::ResultSet> subclass.

Result sets always return matches in ascending Unicode character
order.

=head2 $ccdict->match_unicode(@chars)

This method matches on one or more Unicode characters. Unicode
characters should be given as Perl characters (i.e. C<chr(0x7D20)>),
not as a number.

This dictionary index uses I<traditional> Chinese characters.
Simplified character lookups will not work (but you could use
C<Encode::HanConvert> to convert simple to traditional first).

=head2 $ccdict->match_radical(@numbers)

Given a set of numbers, this method returns those characters
containing the specified radical(s).

=head2 $ccdict->match_index(@numbers)

Given a set of numbers, this method returns those characters
containing the specified index(es).

=head2 $ccdict->match_stroke_count(@numbers)

Given a set of numbers, this method returns those characters
containing the specified number(s) of strokes.

=head2 $ccdict->match_cangjie(@codes)

Given a set of Cangjie codes, this method returns the character(s) for
those code(s).

=head2 $ccdict->match_four_corner(@codes)

Given a set of Four Corner codes, this method returns the character(s)
for those code(s).

=head2 $ccdict->match_pinjim(@romanizations)

=head2 $ccdict->match_jyutping(@romanizations)

=head2 $ccdict->match_pinyin(@romanizations)

=head2 $ccdict->all_characters()

Returns a result set containing all of the characters in the
dictionary.

=head2 $ccdict->entry_count()

Returns the number of entries in the dictionary

=head1 ENVIRONMENT VARIABLES

There are several environment variables you can set to change this
module's behavior.

=over 4

=item * CCDICT_DEBUG_SOURCE

Causes a warning when bad data is enountered in the ccdict dictionary
source. This is primarily useful if you want to find bugs in the
dictionary itself.

=item * CCDICT_VERBOSE

Tells the module to give you progress reports when parsing the source
file. These are sent to STDERR.

=back

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

CCDICT is copyright (c) 1995-2006 Thomas Chin.

=head1 SEE ALSO

Lingua::ZH::CEDICT - for converting between Chinese and English.

Encode::HanConvert - for converting between simplified and traditional
characters in various character sets.

http://www.chinalanguage.com/dictionaries/CCDICT/ - the home of the CCDICT
dictionary.

=cut

