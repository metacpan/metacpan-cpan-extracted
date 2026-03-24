# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::Word2Num;
# ABSTRACT: A wrapper for Lingua:XXX::word2num modules Lingua::Word2Num is a module for converting texts in their spoken language representation into numbers.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ var block

my  Readonly::Scalar $COPY    = 'Copyright (c) PetaMem, s.r.o. 2004-present';
our $VERSION = '0.2603230';

# templates for functional and object interface

my $template_func = 'use __PACKAGE_WITH_VERSION__ ();'."\n".
                    '$result = __PACKAGE__::__FUNCTION__($word);'."\n";

my $template_obj  = 'use __PACKAGE_WITH_VERSION__ ();'."\n".
                    'my $tmp_obj = new __PACKAGE__;'."\n".
                    '$result = $tmp_obj->__FUNCTION__("$word");'."\n";

our %known = (
    afr => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    ces => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    deu => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    eng => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    eus => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    fra => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    ind => {
        package  => 'Words2Nums',
        version  => '',
        function => 'words2nums',
        code     => $template_func,
    },
    ita => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    jpn => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    nld => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    nor => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    pol => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    por => {
        package  => 'Words2Nums',
        version  => '',
        function => 'word2num',
        code     => $template_func,
    },
    rus => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    spa => {
        package  => 'Word2Num',
        version  => '',
        function =>'w2n',
        code     => $template_func,
    },
    swe => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
    zho => {
        package  => 'Word2Num',
        version  => '',
        function => 'w2n',
        code     => $template_func,
    },
);

# }}}

# {{{ new                       constructor

sub new {
    return bless {}, shift;
}

# }}}
# {{{ cardinal                  convert text to number

sub cardinal :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $result = '';

    my $lang   = shift // return $result;
    my $word   = shift // return $result;

    my @langs = ($lang eq '*')
              ? sort keys %known
              : (lc $lang)
              ;

    return $result if (!defined $known{$langs[0]});

    for my $lang (@langs) {
        eval $self->preprocess_code($lang);                 ## no critic 'eval'
        carp $@ if $@;

        return $result if (defined $result && $result ne '');
    }

    return '';
}

# }}}
# {{{ known_langs               list of currently supported languages

sub known_langs :Export {
    return [sort keys %known];
}

# }}}
# {{{ preprocess_code           prepare code for evaluation

sub preprocess_code {
    my $self = shift;
    my $lang = shift // return;

return if !defined $known{$lang};

    my $result                = $known{$lang}{code};
    my $pkg_name              = 'Lingua::' . uc($lang) . '::' . $known{$lang}{package};
    my $pkg_name_with_version = $known{$lang}{version} ne ''
                              ? "$pkg_name $known{$lang}{version}" : $pkg_name;
    my $function              = $known{$lang}{function};

    $result =~ s/__PACKAGE_WITH_VERSION__/$pkg_name_with_version/g;
    $result =~ s/__PACKAGE__/$pkg_name/g;
    $result =~ s/__FUNCTION__/$function/g;
    $result =~ s/__CHARSET__/$known{$lang}{charset}/g;

    return $result;
}

# }}}

1;
__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::Word2Num 

=head1 VERSION

version 0.2603230

A wrapper for Lingua:XXX::word2num modules

Lingua::Word2Num is a module for converting texts in their spoken
language representation into numbers. This is wrapper for various
Lingua::XXX::Word2Num modules. Input text must be in utf8 encoding.

For further information about various limitations see documentation
for currently used package.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::Word2Num;

 my $words = Lingua::Word2Num->new;

 # try to use czech module (Lingua::CES::Word2Num) for conversion to number
 my $number = $words->cardinal( 'ces', 'sto dvacet' );

 # or procedural usage if you dislike OO
 my $number = Lingua::Word2Num::cardinal( 'ces', 'sto dvacet');

 print $text || "sorry, can't convert this czech language text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<cardinal> (positional)

  1   str    language code
  2   str    text to convert
  =>  num    converted number
  =>  undef  if the input string is not known

Conversion from a text in the specified language into a number.


=item B<known_langs> (void)

  =>  lref  list of known languages

List of all currently supported languages.


=item B<new> (void)

  =>  obj  returns new object

Constructor.


=item B<preprocess_code> (void)

  =>  str  returns a template

Private.


=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item cardinal

=item known_langs

=item langs

=back

=cut

# }}}
# {{{ REQUIRED MODULES

=pod

=head1 Required modules

This module is only wrapper and requires other CPAN modules for requested
conversions eg. Lingua::AFR::Numbers for Afrikaans.

Currently supported languages/modules are:

=over 2

=item afr - L<Lingua::AFR::Word2Num>

=item ces - L<Lingua::CES::Word2Num>

=item deu - L<Lingua::DEU::Word2Num>

=item eng - L<Lingua::ENG::Word2Num>

=item eus - L<Lingua::EUS::Word2Num>

=item fra - L<Lingua::FRA::Word2Num>

=item ind - L<Lingua::IND::Words2Nums>

=item ita - L<Lingua::ITA::Word2Num>

=item jpn - L<Lingua::JPN::Word2Num>

=item nld - L<Lingua::NLD::Word2Num>

=item nor - L<Lingua::NOR::Word2Num>

=item pol - L<Lingua::POL::Word2Num>

=item por - L<Lingua::POR::Words2Nums>

=item rus - L<Lingua::RUS::Word2Num>

=item spa - L<Lingua::SPA::Word2Num>

=item swe - L<Lingua::SWE::Word2Num>

=item zho - L<Lingua::ZHO::Word2Num>

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek E<lt>development@petamem.comE<gt>
   Vitor Serra Mori E<lt>development@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=cut

# }}}
