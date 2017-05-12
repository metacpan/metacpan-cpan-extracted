package Language::Zcode::Translator;

use strict;
use warnings;

# XXX For some reason, Constants & Memory aren't getting imported
# (But importing %Constants into PlotzParse works!)
use Language::Zcode::Util qw(%Constants @Memory);
use Language::Zcode::Translator::Generic;

=head1 Language::Zcode::Translator

This class is just a factory. It figure out which subclass of 
Language::Zcode::Translator::Generic we want to use. It then
loads that class, and creates a translator object of that class.

A translator object has methods to translate Z-code into a given language.
See L<Language::Zcode::Translator::Generic>.

=cut

my %known_languages = map {$_=>1} qw(Perl PIR XML);

sub new {
    my ($class, $language, @arg) = @_;
    # XXX I'll bet there's some fancy way of telling if a class exists.
    # E.g., test $class->can("new")
    die"Unknown language $language\n" unless exists $known_languages{$language};
    my $new_class = "Language::Zcode::Translator::$language";
    # Include the necessary translator code or die()
    eval "use $new_class"; die "$@\n" if $@;
    return new $new_class @arg;
}

1;

