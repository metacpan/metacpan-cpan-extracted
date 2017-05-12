package Lingua::Conjunction;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( conjunction );
$VERSION = '2.00';

# Language-specific definitions (these may not be correct, and certainly
# they are not complete... E-mail corrections and additions to the author
# and an updated version will be released.)

# Format of %language is as follows:
# Two-letter ISO language codes... see Locale::Language.pm from CPAN for
#   more details.
# sep = item  separator (usually a comma)
# alt = alternate ("phrase") separator
# pen = 1 = use penultimate separator/0 = don't use penultimate
#   (ie, "Jack, Jill and Spot" vs. "Jack, Jill, and Spot")
# con = conjunction ("and")
# dis = disjunction ("or"), well, grammatically still a "conjunction"...

my %language =
(
 'af' => { sep => ',', alt => ";", pen => 1, con => 'en',  dis => 'of'    },
 'da' => { sep => ',', alt => ";", pen => 1, con => 'og',  dis => 'eller' },
 'de' => { sep => ',', alt => ";", pen => 1, con => 'und', dis => 'oder'  },
 'en' => { sep => ',', alt => ";", pen => 1, con => 'and', dis => 'or'    },
 'es' => { sep => ',', alt => ";", pen => 1, con => 'y',   dis => 'o'     },
 'fi' => { sep => ',', alt => ";", pen => 1, con => 'ja',  dis => 'tai'   },
 'fr' => { sep => ',', alt => ";", pen => 0, con => 'et',  dis => 'ou'    },
 'it' => { sep => ',', alt => ";", pen => 1, con => 'e',   dis => 'o'     },
 'la' => { sep => ',', alt => ";", pen => 1, con => 'et',  dis => 'vel'   },
 'nl' => { sep => ',', alt => ';', pen => 1, con => 'en',  dis => 'of'    },
 'no' => { sep => ',', alt => ";", pen => 0, con => 'og',  dis => 'eller' },
 'pt' => { sep => ',', alt => ";", pen => 1, con => 'e',   dis => 'ou'    },
 'sw' => { sep => ',', alt => ";", pen => 1, con => 'na',  dis => 'au'    },
);

# Conjunction types. Someday we'll add either..or, neither..nor
my %types =
(
    'and'     => 'con',
    'or'      => 'dis'
);

my %punct     = %{$language{en}};
my $list_type = $types{'and'};

use Carp;

# Lingua::Conjunction->separator( SCALAR ) - sets the separator
sub separator
{
    $punct{sep} = $_[1];
}

# Lingua::Conjunction->separator_phrase( SCALAR ) - sets the alternate
#   (phrase) separator
sub separator_phrase
{
    $punct{alt} = $_[1];
}

# Lingua::Conjunction->penultimate( BOOL ) - enables/disables punultimate
#  separator
sub penultimate
{
    $punct{pen} = $_[1];
}

# Lingua::Conjunction->connector( SCALAR ) - sets a specific connector
sub connector
{
    $punct{$list_type} = $_[1];
}

# Lingua::Conjunction->connector_type ( "and" | "or" ) - use "and" or "or"
#  (with appropriate translation for language)
sub connector_type
{
    croak "Undefined connector type \`$_[1]\'", unless ($types{$_[1]});
    $list_type = $types{$_[1]};
}

# Lingua::Conjunction->lang( LANG_CODE ) - sets the language to use
sub lang
{
    my $language = $_[1] || 'en';
    croak "Undefined language \`$language\'",
        unless (defined($language{$language}));
    %punct = %{$language{$language}};
}

sub conjunction
{
    return $_[0] if @_ < 2;
    return join " $punct{$list_type} ", @_ if @_ == 2;

    if ($punct{pen})
    {
	return join "$punct{sep} ", @_[0..$#_-1], "$punct{$list_type} $_[-1]",
	    unless grep /$punct{sep}/, @_;
	return join "$punct{alt} ", @_[0..$#_-1], "$punct{$list_type} $_[-1]";
    }
    else
    {
	return join "$punct{sep} ", @_[0..$#_-2], "$_[-2] $punct{$list_type} $_[-1]",
	    unless grep /$punct{sep}/, @_;
	return join "$punct{alt} ", @_[0..$#_-2], "$_[-2] $punct{$list_type} $_[-1]";
    }

}

1;


__END__


=head1 NAME

Lingua::Conjunction - Convert Perl lists into linguistic conjunctions

=head1 SYNOPSIS

    use Lingua::Conjunction;

    # emits "Jack"
    $name_list = conjunction('Jack');

    # emits "Jack and Jill"
    $name_list = conjunction('Jack', 'Jill');
  
    # emits "Jack, Jill, and Spot"
    $name_list = conjunction('Jack', 'Jill', 'Spot');

    # emits "Jack, a boy; Jill, a girl; and Spot, a dog"
    $name_list = conjunction('Jack, a boy', 'Jill, a girl', 'Spot, a dog');

    # emits "Jacques, un garcon; Jeanne, une fille; et Spot, un chien"
    Lingua::Conjunction->lang('fr');
    $name_list = conjunction(
        'Jacques, un garcon',
        'Jeanne, une fille',
        'Spot, un chien'
    );

=head1 DESCRIPTION

Lingua::Conjunction exports a single subroutine, C<conjunction>, that
converts a list into a properly punctuated text string.

You can cause C<conjunction> to use the connectives of other languages, by
calling the appropriate subroutine:

    Lingua::Conjunction->lang('en');   # use 'and' (default)
    Lingua::Conjunction->lang('es');   # use 'y'

Supported languages in this version are English, Spanish, French, Italian,
German, Portuguese, Norwegian, Danish, Dutch, Afrikaans, Swahili, and Latin.
(Klingon is intentionally not supported.)

You can also set connectives individually:

    Lingua::Conjunction->separator("...");
    Lingua::Conjunction->separator_phrase("--");
    Lingua::Conjunction->connector_type("or");

    # emits "Jack... Jill... or Spot"
    $name_list = conjunction('Jack', 'Jill', 'Spot');

The C<separator_phrase> is used whenever the separator already appears in
an item of the list. For example:

    # emits "Doe, a deer; Ray; and Me"
    $name_list = conjunction('Doe, a deer', 'Ray', 'Me');

You may use the C<penultimate> routine to diable the separator after the
next to last item. Generally this is bad English practice but the option
is there if you want it:

    # emits "Jack, Jill and Spot"
    Lingua::Conjunction->penultimate(0);
    $name_list = conjunction('Jack', 'Jill', 'Spot');

I have been told that the penultimate comma is not standard for some
languages, such as Norwegian. Hence the defaults set in the C<%languages>.

=head1 REVISION HISTORY

Originally this modules was uploaded to CPAN as C<Text::List>. After some
criticism, it was renamed.

As per suggestions, other features were added.  Probably too many features
for what amounts to a simple hack.

More languages could be added, but some languages have more complex
rules (inflections and multiple forms of 'and' depending on the
context, etc.)

=head1 SEE ALSO

C<Locale::Language>

The I<Perl Cookbook> in Section 4.2 has a simular subroutine called
C<commify_series>. The different is that 1. this routine handles
multiple languages and 2. being a module, you do not have to add
the subroutine to a script every time you need it. 

=head1 AUTHORS

Robert Rothenberg <rrwo@cpan.org>

Damian Conway <damian@csse.monash.edu.au>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



