# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2002-present
#
package Lingua::Num2Word;
# ABSTRACT: A wrapper for Lingua::XXX::num2word modules.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use utf8;

use Carp;
use Encode;

# }}}
# {{{ BEGIN

our $VERSION = 0.0682;

BEGIN {
    use Exporter ();
    use vars qw($VERSION $REVISION @ISA @EXPORT_OK %known);
    ($REVISION) = '$Rev: 682 $' =~ /([\d.]+)/; #'
    @ISA        = qw(Exporter);
    @EXPORT_OK  = qw(cardinal get_interval known_langs langs preprocess_code);
}

# }}}

# {{{ templates for functional and object interface

my $template_func = q{ use __PACKAGE_WITH_VERSION__ ();
                       $result = __PACKAGE__::__FUNCTION__($number);
                     };

my $template_obj  = q{ use __PACKAGE_WITH_VERSION__ ();
                       my $tmp_obj = new __PACKAGE__;
                       $result = $tmp_obj->__FUNCTION__($number);
                     };

# }}}
# {{{ %known                    language codes from iso639 mapped to respective interface

%known = (
    afr => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 0,
        limit_hi => 99_999_999_999,
        function => 'parse',
        code     => $template_obj,
    },
    ces => {
        package  => 'Num2Word',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999,
        function => 'num2ces_cardinal',
        code     => $template_func,
    },
    deu => {
        package  => 'Num2Word',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999,
        function => 'num2deu_cardinal',
        code     => $template_func,
    },
    eng => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 1,
        limit_hi => 999_999_999_999_999, # 1e63
        function => '',
        code     => q{ use __PACKAGE_WITH_VERSION__ qw(American);
                       my $tmp_obj = new __PACKAGE__;
                       $tmp_obj->parse($number);
                       $result = $tmp_obj->get_string;
                     },
    },
    eus => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999,
        function => 'cardinal2alpha',
        code     => $template_func,
    },
    fra => {
        package  => 'Nums2Words',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999_999, # < 1e52
        function => 'num2word',
        code     => $template_func,
    },
    ind => {
        package  => 'Nums2Words',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999_999,
        function => 'nums2words',
        code     => $template_func,
    },
    ita => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999,
        function => 'number_to_it',
        code     => $template_func,
    },
    jpn => {
        package  => 'Number',
        version  => '',
        limit_lo => 1,
        limit_hi => 999_999_999_999_999,
        function => 'to_string',
        code     => q{ use __PACKAGE_WITH_VERSION__ ();
                       my @words = __PACKAGE__::__FUNCTION__($number);
                       $result = join ' ', @words;
                     },
        },
    nld => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 0,
        limit_hi => 99_999_999_999,
        function => 'parse',
        code     => $template_obj,
    },
    nor => {
        package  => 'Num2Word',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999,
        function => 'num2no_cardinal',
        code     => $template_obj,
    },
    pol => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 0,
        limit_hi => 9_999_999_999_999,
        function => 'parse',
        code     => $template_obj,
    },
    por => {
        package  => 'Nums2Words',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999_999,
        function => 'num2word',
        code     => $template_func,
    },
    rus => {
        package  => 'Number',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999_999,
        function => 'rur_in_words',
        code     => q{ use __PACKAGE_WITH_VERSION__ ();
                       $result = __PACKAGE__::__FUNCTION__($number);
                       if ($result) {
                           if ($number) {
                               $result =~ s/\s+\S+\s+\S+\s+\S+$//;
                           }
                           else {
                               $result =~ s/\s+\S+$//;
                           }
                           $result =~ s/^\s+//;
                       }
                     },
    },
    spa => {
        package  => 'Numeros',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999_999_999,
        function => 'cardinal',
        code     => $template_obj,
    },
    swe => {
        package  => 'Num2Word',
        version  => '',
        limit_lo => 0,
        limit_hi => 999_999_999,
        function => 'num2sv_cardinal',
        code     => $template_func,
    },
    zho => {
        package  => 'Numbers',
        version  => '',
        limit_lo => 1,
        limit_hi => 999_999_999_999_999,
        function => '',
        code     => q{ use __PACKAGE_WITH_VERSION__ qw(traditional);
                       my $tmp_obj = new __PACKAGE__;
                       $tmp_obj->parse($number);
                       $result = $tmp_obj->get_string;
                     },
    },
);

# }}}
# {{{ new                       constructor

sub new {
    return bless {}, shift;
}

# }}}
# {{{ known_langs               list of currently supported languages

sub known_langs {
    return wantarray ? sort keys %known : [ sort keys %known ];
}

# }}}
# {{{ get_interval              get minimal and maximal supported number

# Return:
#  undef for unsupported language
#  list or list reference (depending to calling context) with
#  minimal and maximal supported number
#
sub get_interval {
    my $self = ref($_[0]) ? shift : Lingua::Num2Word->new();
    my $lang = shift || return;
    my @limits;

    return if (!defined $known{$lang});

    @limits = ($known{$lang}{limit_lo}, $known{$lang}{limit_hi});

    return @limits if (wantarray);
    return \@limits;
}

# }}}
# {{{ cardinal                  convert number to text

sub cardinal {
    my $self   = ref($_[0]) ? shift : Lingua::Num2Word->new();
    my $result = '';
    my $lang   = defined $_[0] ? shift : return $result;
    my $number = defined $_[0] ? shift : return $result;

    $lang = lc $lang;

    return $result if (!defined $known{$lang});

    if (defined $known{$lang}{lang}) {
        eval $self->preprocess_code($known{$lang}{lang}); ## no critic
        carp $@ if ($@);
    }
    else {
        eval $self->preprocess_code($lang); ## no critic
        carp $@ if ($@);
    }

    return $result;
}

# }}}
# {{{ preprocess_code           prepare code for evaluation

sub preprocess_code {
    my $self                  = shift;
    my $lang                  = shift // return;

    return if !exists $known{$lang};

    my $result                = $known{$lang}{code};
    my $pkg_name              = 'Lingua::' . uc($lang) . '::' . $known{$lang}{package};
    my $pkg_name_with_version = $known{$lang}{version} ne ''
                              ? "$pkg_name $known{$lang}{version}"
                              : $pkg_name
                              ;

    my $function              = $known{$lang}{function};

    $result =~ s/__PACKAGE_WITH_VERSION__/$pkg_name_with_version/g;
    $result =~ s/__PACKAGE__/$pkg_name/g;
    $result =~ s/__FUNCTION__/$function/g;

    return $result;
}
# }}}

1;

__END__

# {{{ POD HEAD

=head1 NAME

Lingua::Num2Word

=head1 VERSION

version 0.0682

wrapper for number to text conversion modules of
various languages in the Lingua:: hierarchy.

=head2 $Rev: 682 $

A wrapper for mosules in the Lingua::XXX hierarchy.
XXX is a code from the ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::Num2Word;

 my $numbers = Lingua::Num2Word->new;

 # try to use czech module (Lingua::CES::Num2Word) for conversion to text
 my $text = $numbers->cardinal( 'ces', 123 );

 # or procedural usage if you dislike OO
 my $text = Lingua::Num2Word::cardinal( 'ces', 123 );

 print $text || "sorry, can't convert this number into czech language.";

 # check if number is in supported interval before conversion
 my $number = 999_999_999_999;
 my $limit  = $numbers->get_interval('ces');
 if ($limit) {
   if ($number > $$limit[1] || $number < $$limit[0]) {
     print "Number is outside of supported range - <$$limit[0], $$limit[1]>.";
   }
   else {
     print Lingua::Num2Word::cardinal( 'ces', $number );
   }
 }
 else {
   print "Unsupported language.";
 }

=head1 DESCRIPTION

A wrapper for Lingua::XXX::num2word modules.

Lingua::Num2Word is a wrapper for modules for converting numbers into
their equivalent in written representation.

This is a wrapper for various Lingua::XXX::Num2Word modules that do the
conversions for specific languages. Output encoding is utf-8.

For further information about various limitations of the specific
modules see their documentation.

# }}}
# {{{ Functions reference

=head2 Functions Reference

=over

=item cardinal (positional)

  1   string  target language
  2   number  number to convert
  =>  string  converted string
      undef   if input number is not supported

Conversion from number to text representation in specified language.

=item get_interval (positional)

  1   string       language specification
  =>  array|arref  list with min max values
      undef        if specified language is not known

Returns the minimal and maximal number (inclusive) supported by the
conversion in a specified language. The returned value is a list of
two elements (low,high) or reference to this list depending on calling
context. In case a unsupported language is passed undef is returned.

=item known_langs

  =>  array|arref  list of supproted languages

List of all currently supported languages. Return value is a list or
a reference to a list depending on calling context.

=item langs

  =>  array|arref  list of languages known by ISO 639-3 list

List of all known language codes from iso639. Return value is list or
reference to list depending on calling context.

=item new

Constructor.

=item preprocess_code

Private.

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head2 Language codes and names

Language codes and names from iso639 can be found at L<http://www.triacom.com/archive/iso639.en.html>

=head1 EXPORT_OK

=over

=item cardinal

=item get_interval

=item known_langs

=item langs

=back

=head2 Required modules / supported languages

This module is only wrapper and requires other CPAN modules for requested
conversions eg. Lingua::AFR::Numbers for Afrikaans.

Currently supported languages/modules are:

=over

=item afr - L<Lingua::AFR::Numbers>

=item ces - L<Lingua::CES::Num2Word>

=item deu - L<Lingua::DEU::Num2Word>

=item eng - L<Lingua::ENG::Numbers>

=item eus - L<Lingua::EUS::Numbers>

=item fra - L<Lingua::FRA::Numbers>

=item ind - L<Lingua::IND::Nums2Words>

=item ita - L<Lingua::ITA::Numbers>

=item jpn - L<Lingua::JPN::Number>

=item nld - L<Lingua::NLD::Numbers>

=item nor - L<Lingua::NOR::Num2Word>

=item pol - L<Lingua::POL::Numbers>

=item por - L<Lingua::POR::Nums2Words>

=item rus - L<Lingua::RUS::Number>

=item spa - L<Lingua::SPA::Numeros>

=item swe - L<Lingua::SWE::Num2Word>

=item zho - L<Lingua::ZHO::Numbers>

=back

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek <info@petamem.com>
 initial coding after specifications by R. Jelinek:
   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2002-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
