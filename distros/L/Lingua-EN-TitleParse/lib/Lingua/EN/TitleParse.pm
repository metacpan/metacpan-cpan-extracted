package Lingua::EN::TitleParse;

use 5.006000;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;
    $self->{titles} = $params{titles} ? $self->_load( $params{titles} ) : $self->_default_titles;
    $self->{clean}  = $params{clean} ? 1 : 0;
    return $self;
}

# parse uses a hash-table of "normalised" titles to very efficiently identify
# titles, regardless of the number of titles required to look up.
# Normalised text for our purposes consists of lower-case \w characters,
# all other characters and spaces being \W.
# Using this technique we find titles regardless of case or other
# punctuation used. e.g. MR, Mr., mr, and Mr can all be found.
#
# Once we have identified the normalised title we then capture the real
# title, with the punctuation and case as in the original string, by
# counting forward the correct number of normalised characters and
# capturing non-normalised characters along the way.

sub parse {

    my ($self, $name) = @_;

    return () unless defined $name;

    my ($title, $remaining_name) = ('', $name);
    my $titles = ref $self ? $self->{titles} : $self->_default_titles;

    # Try to find a normalised title using a hash lookup.
    # Split the name by spaces/non-word characters, then match in
    # reverse order against a list of normalised titles.
    # Take the largest matching title.
    my $normalised_title;
    my @name_chunks = split(/\W+/, lc $name);
    while (pop @name_chunks) {
        my $possible_title = join(" ", @name_chunks);
        if (exists $titles->{$possible_title}) {
            $normalised_title = $possible_title;
            last;
        }
    }

    if ($normalised_title) {
        # Find the normalised title in the real string
        # by counting the number of normalised characters
        # (ignore any spaces in the count)
        my $unspaced_title  = $normalised_title;
        $unspaced_title =~ s/\s//g;
        my $character_count = length $unspaced_title;
        my @characters      = split (//, $name);
        my @title_chars;
        while ($character_count > 0 && scalar @characters > 0) {
            my $character = shift @characters;
            push (@title_chars, $character);
            # only count down when we have a normalised character
            $character_count-- if $character =~ /^\w$/;
        }
        # Now add any trailing un-normalised characters to the title too
        # e.g. for "Mr." we want the "." in "Mr." too,
        while ($characters[0] =~ /^\W$/) {
            push (@title_chars, shift @characters);
        }

        $title           = join("", @title_chars);
        $remaining_name  = join("", @characters);

        # clean up any spaces at the point of separation
        $title          =~ s/\s+$//;
        $remaining_name =~ s/^\s+//;
    }

    # Return a cleaned title if that option was set
    $title = $titles->{$normalised_title} if $normalised_title && ref $self && $self->{clean};

    return ($title, $remaining_name);    
}

# This method must match how parse()
# handles its input string.

sub normalise {
    my ($self, $title) = @_;

    # remove leading/trailing whitespace
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;
    # remove punctuation & consolidate spaces
    $title =~ s/\W+/ /;
    # lower-case
    $title = lc($title);

    return $title;
}

sub titles {
    my $self = shift;
    my $titles = ref $self ? $self->{titles} : $self->_default_titles;
    return sort values %$titles;
}

sub _load {
    my ($self, $titles) = @_;
    my $normalised_titles = {};
    foreach my $title (@$titles) {
        my $normalised_title = $self->normalise($title);
        # Store the title in our hashref pointing at the original title
        $normalised_titles->{$normalised_title} = $title;
    }
    return $normalised_titles;
}

sub _default_titles {
    return {
        # Basic titles
        'mr' => 'Mr',
        'ms' => 'Ms',
        'mrs' => 'Mrs',
        'miss' => 'Miss',
        'mx' => 'Mx',
        'dr' => 'Dr',
        # Combined titles
        'mr and mrs' => 'Mr and Mrs',
        'mr mrs' => 'Mr & Mrs',
        # Extended titles
        'sir' => 'Sir',
        'dame' => 'Dame',
        'messrs' => 'Messrs',
        'madame' => 'Madame',
        'madam' => 'Madam',
        'mme' => 'Mme',
        'mister' => 'Mister',
        'master' => 'Master',
        'mast' => 'Mast',
        'msgr' => 'Msgr',
        'mgr' => 'Mgr',
        'count' => 'Count',
        'countess' => 'Countess',
        'duke' => 'Duke',
        'duchess' => 'Duchess',
        'lord' => 'Lord',
        'lady' => 'Lady',
        'marquis' => 'Marquis',
        'marquess' => 'Marquess',
        # Medical
        'doctor' => 'Doctor',
        'sister' => 'Sister',
        'matron' => 'Matron',
        'nurse' => 'Nurse',
        # Legal
        'judge' => 'Judge',
        'justice' => 'Justice',
        'attorney' => 'Attorney',
        'solicitor' => 'Solicitor',
        'barrister' => 'Barrister',
        'qc' => 'QC',
        'kc' => 'KC',
        # Police
        'det' => 'Det',
        'detective' => 'Detective',
        'insp' => 'Insp',
        'inspector' => 'Inspector',
        # Military
        'brig' => 'Brig',
        'brigadier' => 'Brigadier',
        'captain' => 'Captain',
        'capt' => 'Capt',
        'colonel' => 'Colonel',
        'col' => 'Col',
        'commander in chief' => 'Commander in Chief',
        'commander' => 'Commander',
        'commodore' => 'Commodore',
        'cdr' => 'Cdr',
        'field marshall' => 'Field Marshall',
        'fl off' => 'Fl Off',
        'flight officer' => 'Flight Officer',
        'flt lt' => 'Flt Lt',
        'flight lieutenant' => 'Flight Lieutenant',
        'general of the army' => 'General of the Army',
        'general' => 'General',
        'gen' => 'Gen',
        'pte' => 'Pte',
        'private' => 'Private',
        'sgt' => 'Sgt',
        'sargent' => 'Sargent',
        'air commander' => 'Air Commander',
        'air commodore' => 'Air Commodore',
        'air marshall' => 'Air Marshall',
        'lieutenant colonel' => 'Lieutenant Colonel',
        'lt col' => 'Lt Col',
        'lt gen' => 'Lt Gen',
        'lt cdr' => 'Lt Cdr',
        'lieutenant' => 'Lieutenant',
        'lt' => 'Lt',
        'leut' => 'Leut',
        'lieut' => 'Lieut',
        'major general' => 'Major General',
        'maj gen' => 'Maj Gen',
        'major' => 'Major',
        'maj' => 'Maj',
        'pilot officer' => 'Pilot Officer',
        # Religious
        'rabbi' => 'Rabbi',
        'bishop' => 'Bishop',
        'brother' => 'Brother',
        'chaplain' => 'Chaplain',
        'father' => 'Father',
        'pastor' => 'Pastor',
        'mother superior' => 'Mother Superior',
        'mother' => 'Mother',
        'most reverend' => 'Most Reverend',
        'most reverand' => 'Most Reverand',
        'very reverend' => 'Very Reverend',
        'very reverand' => 'Very Reverand',
        'reverend' => 'Reverend',
        'reverand' => 'Reverand',
        'mt revd' => 'Mt Revd',
        'v revd' => 'V Revd',
        'revd' => 'Revd',
        # Academic
        'professor' => 'Professor',
        'prof' => 'Prof',
        'associate professor' => 'Associate Professor',
        'assoc prof' => 'Assoc Prof',
        # Other
        'alderman' => 'Alderman',
        'ald' => 'Ald',
        # These might be followed by another title
        # in which case we will fail to pick that up.
        'his excellency' => 'His Excellency',
        'his honour' => 'His Honour',
        'his honor' => 'His Honor',
        'her excellency' => 'Her Excellency',
        'her honour' => 'Her Honour',
        'her honor' => 'Her Honor',
        'the right honourable' => 'The Right Honourable',
        'the right honorable' => 'The Right Honorable',
        'the honourable' => 'The Honourable',
        'the honorable' => 'The Honorable',
        'right honourable' => 'Right Honourable',
        'right honorable' => 'Right Honorable',
        'rt hon' => 'Rt Hon',
        'rt hon' => 'Rt Hon',
        'the hon' => 'The Hon',
        'the hon' => 'The Hon',
    };
}

1;
__END__

=head1 NAME

Lingua::EN::TitleParse - Parse titles in people's names

=head1 SYNOPSIS

  use Lingua::EN::TitleParse;

  # Functional interface
  my ($title, $name) = Lingua::EN::TitleParse->parse("Mr Joe Bloggs");

  # $title = "Mr", $name = "Joe Bloggs"

  # OO interface
  $title_obj      = Lingua::EN::TitleParse->new();
  ($title, $name) = $title_obj->parse("Mr Joe Bloggs");

  # $title = "Mr", $name = "Joe Bloggs"

  # Use your own titles with the OO interface
  #
  @titles = ('Master', 'International Master', 'Grandmaster');
  $title_obj  = Lingua::EN::TitleParse->new( titles => \@titles );
  ($title, $name) = $title_obj->parse("Grandmaster Joe Bloggs");

  # $title = "Grandmaster", $name = "Joe Bloggs"

  # Retrieve the list of titles
  @titles = $title_obj->titles;

  # Optionally get cleaned titles on output
  $title_obj      = Lingua::EN::TitleParse->new( clean => 1 );
  ($title, $name) = $title_obj->parse("mR. Joe Bloggs");

  # $title = "Mr", $name  = "Joe Bloggs"
 
  # Without 'clean' turned on
  $title_obj      = Lingua::EN::TitleParse->new();
  ($title, $name) = $title_obj->parse("mR. Joe Bloggs");

  # $title = "mR.", $name  = "Joe Bloggs"


=head1 DESCRIPTION

This module parses strings containing people's names to identify
titles, like "Mr", "Mrs", etc, so the names and titles can be separated.

e.g. "Mr Joe Bloggs" will be parsed to "Mr", and "Joe Bloggs".

The module handles "fuzziness" such as changes of case and punctuation
characters: "Mr", "MR", "Mr.", and "mr" will all be recognised correctly.

It differs from another CPAN module, Lingua::EN::NameParse, in two key
respects:

Firstly, Lingua::EN::TitleParse performs well irrespective of the
number of titles being matched against.  While Lingua::EN::NameParse
loops through a series of regular expressions, and suffers when the set
of titles being matched is long, Lingua::EN::TitleParse uses hash-lookups
after "normalising" each name string, providing consistently good
performance.

Secondly it's only focused on parsing titles in names, whereas
Lingua::EN::NameParse attempts much more.  However the extra
intelligence of Lingua::EN::NameParse can come at the cost of
predictablity. Lingua::EN::TitleParse is more conservative, and
by default makes no changes to the case or content (with the exception
of compressing extra white-space) of what was input, effectively
only splitting the input string in two. (But that said, there is an
option to output cleaned titles).

We're using the same titles Lingua::EN::NameParse uses (their "extended set")
with minor additions, but your own set of titles can be imported instead.

=head2 METHODS

=over

=item parse

This method identifies a title in a name and splits the name
out into the title and the rest of the name.

  # e.g. via the functional interface
  my ($title, $name) = Lingua::EN::TitleParse->parse("Mr Joe Bloggs");

  # e.g. via the Object-Oriented interface
  $title_obj      = Lingua::EN::TitleParse->new();
  ($title, $name) = $title_obj->parse("Mr Joe Bloggs");

=item titles

This method returns an array of the titles in use.  This will either
be the default titles, or custom titles input during construction.

  # e.g. via the functional interface
  @titles = Lingua::EN::TitleParse->titles;

  # e.g. via the Object-Oriented interface
  $title_obj = Lingua::EN::TitleParse->new( titles => \@custom_titles );
  @titles = $title_obj->titles;

=back

=head2 EXPORT

None.


=head1 SEE ALSO

Lingua::EN::NameParse


=head1 AUTHOR

Philip Abrahamson, E<lt>PhilipAbrahamson@venda.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Venda Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
