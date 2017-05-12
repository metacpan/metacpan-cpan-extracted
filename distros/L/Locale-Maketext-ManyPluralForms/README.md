# perl-Locale-Maketext-ManyPluralForms
[![Build Status](https://travis-ci.org/binary-com/perl-Locale-Maketext-ManyPluralForms.svg?branch=master)](https://travis-ci.org/binary-com/perl-Locale-Maketext-ManyPluralForms)
[![codecov](https://codecov.io/gh/binary-com/perl-Locale-Maketext-ManyPluralForms/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Locale-Maketext-ManyPluralForms)


#### INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# NAME

Locale::Maketext::ManyPluralForms

# SYNOPSIS

    use Locale::Maketext::ManyPluralForms {'*' => ['Gettext' => 'i18n/*.po']};
    my $lh = Locale::Maketext::ManyPluralForms->get_handle('en');
    $lh->maketext("Hello");

# DESCRIPTION

The implementation supporting internationalisation with many plural forms
using Plural-Forms header from .po file to add plural method to Locale::Maketext based class.
As described there [http://www.perlmonks.org/index.pl?node\_id=898687](http://www.perlmonks.org/index.pl?node_id=898687).

# METHODS

## Locale::Maketext::ManyPluralForms->import({'\*' => \['Gettext' => 'i18n/\*.po'\]})

This method to specify languages.

## $self->plural($num, @strings)

This method handles plural forms. You can invoke it using Locale::Maketext's
bracket notation, like "\[plural,\_1,string1,string2,...\]". Depending on value of
_$num_ and language function returns one of the strings. If string contain %d
it will be replaced with _$num_ value.

# SEE ALSO

[Locale::Maketext](https://metacpan.org/pod/Locale::Maketext),
[Locale::Maketext::Lexicon](https://metacpan.org/pod/Locale::Maketext::Lexicon)

# COPYRIGHT AND LICENSE

Copyright (C) 2016 binary.com
