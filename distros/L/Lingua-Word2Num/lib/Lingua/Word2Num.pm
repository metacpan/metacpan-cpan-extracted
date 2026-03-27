# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::Word2Num;
# ABSTRACT: Word to number conversion

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ var block

my  Readonly::Scalar $COPY    = 'Copyright (c) PetaMem, s.r.o. 2004-present';
our $VERSION = '0.2603260';

# templates for functional and object interface

my $template_func = 'use __PACKAGE_WITH_VERSION__ ();'."\n".
                    '$result = __PACKAGE__::__FUNCTION__($word);'."\n";

my $template_obj  = 'use __PACKAGE_WITH_VERSION__ ();'."\n".
                    'my $tmp_obj = new __PACKAGE__;'."\n".
                    '$result = $tmp_obj->__FUNCTION__("$word");'."\n";

# {{{ ISO 639-1 to 639-3 mapping
my %iso1_to_3 = (
    af => 'afr', ar => 'ara', bg => 'bul', ca => 'cat',
    cs => 'ces', da => 'dan', de => 'deu', el => 'ell',
    en => 'eng', es => 'spa', et => 'est', eu => 'eus',
    fa => 'fas', fi => 'fin', fr => 'fra', he => 'heb',
    hi => 'hin', hr => 'hrv', hu => 'hun', id => 'ind',
    is => 'isl', it => 'ita', ja => 'jpn', ko => 'kor',
    lt => 'lit', lv => 'lav', nl => 'nld', 'no' => 'nor',
    pl => 'pol', pt => 'por', ro => 'ron', ru => 'rus',
    sk => 'slk', sv => 'swe', sw => 'swa', th => 'tha',
    tr => 'tur',
    uk => 'ukr', vi => 'vie', zh => 'zho',
);
# }}}

# {{{ %known — auto-discovered from lib/Lingua/*/Word2Num.pm

# Override table for legacy modules with non-standard API
my %w2n_override = (
    ind => { package => 'Words2Nums', function => 'words2nums' },
    por => { package => 'Words2Nums', function => 'word2num'   },
);

our %known;

# auto-discover: scan for Lingua::*::Word2Num modules
{
    my $lingua_dir;
    for my $inc (@INC) {
        my $try = "$inc/Lingua";
        if (-d $try) { $lingua_dir = $try; last; }
    }

    if ($lingua_dir) {
        for my $dir (glob "$lingua_dir/*/") {
            my ($lang) = $dir =~ m{/([A-Z]{3})/\z};
            next unless $lang;
            $lang = lc $lang;

            if (-e "$dir/Word2Num.pm" || exists $w2n_override{$lang}) {
                my $ov = $w2n_override{$lang} // {};
                $known{$lang} = {
                    package  => $ov->{package}  // 'Word2Num',
                    version  => $ov->{version}  // '',
                    function => $ov->{function} // 'w2n',
                    code     => $ov->{code}     // $template_func,
                };
            }
        }
    }
}

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

    $lang = lc $lang;
    $lang = $iso1_to_3{$lang} if exists $iso1_to_3{$lang};

    my @langs = ($lang eq '*')
              ? sort keys %known
              : ($lang)
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

Lingua::Word2Num - Word to number conversion


=head1 VERSION

version 0.2603260

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

 # convert Czech text to number
 my $number = $words->cardinal( 'cs', 'sto dvacet' );

 # or procedural usage
 my $number = Lingua::Word2Num::cardinal( 'de', 'zweiundvierzig');

 print $number // "sorry, can't convert this text into a number.";

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

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding (until 2005):
   Roman Vasicek E<lt>info@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
