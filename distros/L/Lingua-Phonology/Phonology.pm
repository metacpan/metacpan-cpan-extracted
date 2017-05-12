#!/usr/bin/perl -w

package Lingua::Phonology;

$VERSION = 0.35_2;

use strict;
use warnings;
use warnings::register;

use Carp qw/carp croak/;
use Lingua::Phonology::Common;
use Lingua::Phonology::Features;
use Lingua::Phonology::Segment;
use Lingua::Phonology::Symbols;
use Lingua::Phonology::Rules;
use Lingua::Phonology::Syllable;


=head1 NAME

Lingua::Phonology - a module providing a unified way to deal with
linguistic representations of phonology.

=head1 SYNOPSIS

    use Lingua::Phonology;
    $phono = new Lingua::Phonology;

    # Get sub-objects
    $features = $phono->features;
    $symbols = $phono->symbols;
    $rules = $phono->rules;
    $syllabification = $phono->syllable;
    $segment = $phono->segment;

    # Load phonology defaults
    $phono->loadfile;

    # Load a phonology definition from a file
    $phono->loadfile('language.xml');

    # Save phonology definition to a file
    $phono->savefile('language.xml');

=head1 ABSTRACT

Lingua::Phonology is a unified module for handling phonological descriptions
and units. It includes sub-modules for hierarchical (feature-geometric) sets of
features, phonetic or orthographic symbols, individual segments, linguistic
rules, syllabification algorithms, etc. It is written as an object-oriented
module, wherein one will generally have a single object for the list of
features, one for the phonetic symbols, one for the set of rules, etc., and
multiple segment objects to be programatically manipulated.

=cut

# Remainder of POD is after the __END__ token

sub err ($) { warnings::warnif(shift); return; };

# Constructor - creates new (empty) objects
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = bless {}, $class;

	$self->{FEATURES} = Lingua::Phonology::Features->new();
	$self->{SYMBOLS} = Lingua::Phonology::Symbols->new($self->{FEATURES});
	$self->{RULES} = Lingua::Phonology::Rules->new();
	$self->{SYLLABLE} = Lingua::Phonology::Syllable->new();

	return $self;
}

# Next section deals w/ making accessor methods
# Accessor methods to create and/or iterate over (order may be significant!)
my @accessors = qw/features symbols syllable rules/;

# Object types to create/expect--all accessors must be defined here
my %classes = (
    features => 'Lingua::Phonology::Features',
    symbols => 'Lingua::Phonology::Symbols',
    rules => 'Lingua::Phonology::Rules',
    syllable => 'Lingua::Phonology::Syllable'
);

# Continuations (if needed)
my %continue = (
    features => sub { $_[0]->{SYMBOLS}->features($_[1]) if defined $_[1] }
);

# Create methods for each of the accessors
while (my ($name, $class) = each %classes) {
    my $key = uc $name;
    no strict 'refs';
    *$name = sub {
        return $_[0]->{$key} unless @_ > 1;
        my ($self, $val) = @_;
        croak "Argument to $name() not a $class" unless _is($val, $class);
        $self->{$key} = $val;
        $continue{$name}->(@_) if exists $continue{$name};
        return $self->{$key};
    };
}
        
# Get blank segments
sub segment {
	my $self = shift;
	my $seg = Lingua::Phonology::Segment->new($self->{FEATURES});
	$seg->symbolset($self->{SYMBOLS});
	return $seg;
}

# Load a complete phonology definition from a file
sub loadfile {
    my ($self, $file) = @_;
    my $err = 0;

    # If called with one argument, load defaults. Submodules implement
    # "default" in different ways--that's their problem. They must do the right
    # thing when loadfile() is called on them with no arguments.
    if (not defined $file) {
        for (@accessors) {
            $self->$_->loadfile or $err = 1;
        }
    }

    # When given an actual filename
    else {
        my $parse;
        eval { $parse = _parse_from_file $file };
        return err($@) unless $parse;

        for (@accessors) {
            $self->$_->_load_from_struct($parse->{$_}) or $err = 1;
        }
    }

    # $return should 
    return $err ? () : 1;
}

# Save a total phonology. We do this by concatenating the strings returned by
# the to_str() methods in the various submodules.
sub savefile {
    my ($self, $file) = @_;

    my $str = '';
    for (@accessors) {
        $str .= "\n" . $self->$_->_to_str;
    }
    $str = "<?xml version=\"1.0\" standalone=\"yes\" ?>\n<phonology>$str</phonology>\n";

    eval { $file = _to_handle($file, '>') };
    return err($@) if $@;

    print $file $str;
    return $str;
}

1;

__END__

=head1 DESCRIPTION

Lingua::Phonology is a module for modeling phonological descriptions of
languages. It is designed with a classical generative phonology in mind,
handing feature geometry, phonetic symbols, ordered rule sets, and
syllabification algorithms. Both synchronic underlying-to-surface language
change and diachronic language change can be modeled with this module. The
module is designed to be very powerful and entirely programmatic, allowing you
to define and manipulate a phonology entirely in perl, and it includes many
features that you will probably never use. Some of the functionality of
Lingua::FeatureMatrix and Lingua::SoundChange is duplicated here, but with
much, much greater power.

Lingua::Phonology is split into several sub-modules, each of which does one
specific thing. Here are the sub-modules, with a brief description of each:

=over 4

=item * L<Lingua::Phonology::Features>

Lingua::Phonology::Features allows you to define and manipulate the feature set
that your language uses. This module allows for arbitrarily complex
heirarchical feature geometry systems and implements one such system as its
default, but you can also implement flat "classical" feature systems.

=item * L<Lingua::Phonology::Segment>

Lingua::Phonology::Segment, as its name implies, is the class that handles
individual segments. Segments are associated with a feature set (a
Lingua::Phonology::Features object), and are manipulated by various other
modules.

=item * L<Lingua::Phonology::Symbols>

Lingua::Phonology::Symbols is a class that acts as a "phonetic interpreter" for
Lingua::Phonology::Segment objects. It takes a Segment and attempts to match it
with a textual phonetic symbol. This module contains methods for defining and
manipulating the set of phonetic symbols used.

=item * L<Lingua::Phonology::Rules>

Lingua::Phonology::Rules allows you to define processes that act upon words .
You use this class to define the conditions and effects of each rule, and then
apply that rule or many rules at once to a word.

=item * L<Lingua::Phonology::Syllable>

Lingua::Phonology::Syllable is a subclass of Lingua::Phonology::Rules designed
to handle syllabificaion. By setting just a few parameters, you can use this
module to break a word up into syllables.

=item * L<Lingua::Phonology::Functions>

This module, unlike all of the others, is not object oriented. It provides a
set of functions that can be used to make it easier to write rules for
Lingua::Phonology::Rules.

=back

When you create a Lingua::Phonology object with C<new Lingua::Phonology>, it comes
bundled with a single object for each of these classes:
Lingua::Phonology::Features, Lingua::Phonology::Symbols,
Lingua::Phonology::Rules, Lingua::Phonology::Syllable. There are simple methods
for accessing each of these objects. There is also a method that can be used to
generate new Lingua::Phonology::Segment objects (since you will doubtlessly
want more than one segment). The only module not automatically bundled with
Lingua::Phonology is Lingua::Phonology::Functions, which you need to C<use>
yourself if you want to access its functions.

The complete description of the function and use of each of these modules is on
their respective man pages. It is recommended that you read these pages in the
order given above to best understand them.

=head1 WARNINGS

Always C<use> them. Lingua::Phonology contains many useful warnings, but it
generally will not display them unless C<use warnings> is on. All of the
modules within Lingua::Phonology provide named warnings spaces, so you can
turn the warnings specific to Lingua::Phonology or any submodule on or off.

	use warnings 'Lingua::Phonology';       # use all warnings w/in Lingua::Phonology
	no warnings 'Lingua::Phonology::Rules'; # ignore warnings coming from Lingua::Phonology::Rules
	# etc.

=head1 METHODS

=head2 new

    my $phono = new Lingua::Phonology;

Takes no arguments, and returns a new Lingua::Phonology object. This new object
will contain one Lingua::Phonology::Features object, one
Lingua::Phonology::Symbols object, one Lingua::Phonology::Rules object, and one
Lingua::Phonology::Syllable object.  These objects will be initialized to refer
to one another where appropriate, so it is rarely necessary to use C<new> on
any of the sub-modules.

=head2 features

    my $features = $phono->features;

Returns the Lingua::Phonology::Features object associated with the current
phonology. You may also pass a Features object as an argument, which sets the
current Features object.

=head2 symbols

    my $symbols = $phono->symbols;

Returns the current Lingua::Phonology::Symbols object. As with C<features()>, you can pass a
Symbols object as an argument to set the current Symbols object, if
desired.

=head2 rules

    my $rules = $phono->rules;

Returns the current Lingua::Phonology::Rules object, or sets the current object
if a Rules object is provided as an argument.

=head2 syllable

    my $syllabification = $phono->syllable;

Returns a Lingua::Phonology::Syllable object, or sets the current object if
a Syllable object is provided as an argument.

=head2 segment

    my $seg = $phono->segment;

Returns a new Lingua::Phonology::Segment object associated with the current
feature set and symbol set. This method takes no arguments, and cannot be used
to initialize a segment. Therefore, it's probably easier to use the segment()
method of Lingua::Phonology::Symbols (which you can access with C<<
$phono->symbols->segment($foo) >>.

=head2 loadfile

    # Load defaults
    $phono->loadfile;
    
    # Load phonology definition from a file
    $phono->loadfile('phono.xml');

This method can be used to either load the defaults for all modules that come
with defaults (currently Lingua::Phonology::Features and
Lingua::Phonology::Symbols), or to load a phonology definition from a file.

Lingua::Phonology reads phonology definitions written in XML. The specification
for the XML format that Lingua::Phonology reads is described in
L<Lingua::Phonology::FileFormatPOD>.

This method returns true on success, and undef on failure.

=head2 savefile

    # Save to a file
    $phono->savefile('phono.xml');

This method writes the current phonology state to the file given as the
argument. The argument to this function may be the name of a file or a
filehandle reference. If the name of a file is given, the file is truncated
before the new file is written. The only way to append to an existing file is
to pass a reference to a file opened in append mode.

This method returns undef if there is an error, else the string that was
written to the file.

The file written is an XML document described in
L<Lingua::Phonology::FileFormatPOD>.

=head1 APOLOGIA

This module was written to fill my need for a truly versatile, sufficiently
powerful way of handling phonologies. The existing Perl tools
(Lingua::SoundChange and Lingua::FeatureMatrix) worked well enough for what
they did, but they all lacked some functionality that I considered
important. Thus, I decided to make my own tool. I have to a certain extent
reinvented the wheel, but I prefer to think of it as replacing the wheel
with a jet engine, since Lingua::Phonology is much more powerful than the
existing modules.

Nonetheless, I am interested in integrating with existing tools, especially
ones that are widely used and would be useful to others. Feel free to send
me suggestions, or to make your own module interfacing Lingua::Phonology
with whatever else.

=head1 BUGS

Probably. Please send bug reports and code improvements to the author.

=head1 SEE ALSO

L<Lingua::Phonology::Features>

L<Lingua::Phonology::Symbols>

L<Lingua::Phonology::Segment>

L<Lingua::Phonology::Rules>

L<Lingua::Phonology::Syllable>

L<Lingua::Phonology::Functions>

L<Lingua::Phonology::FileFormatPOD>

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>.

This module is no longer actively maintained, though it does get occasional
bugfixes. It has been superceded by a command-line tool called C<phonix>, which
can be found at F<http://phonix.googlecode.com>.

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut
