# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::Word2Num;
# ABSTRACT: Lingua::Word2Num converts number words in natural language text into their numeric values. It supports 44 languages via auto-discovered Lingua::XXX::Word2Num modules and accepts both ISO 639-1 (de) and ISO 639-3 (deu) language codes.

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
our $VERSION = '0.2603270';

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
    be => 'bel', cy => 'cym', ga => 'gle', gl => 'glg',
    lb => 'ltz', mk => 'mkd', mt => 'mlt', oc => 'oci',
    sc => 'srd',
    sl => 'slv', sq => 'sqi', sr => 'srp', tr => 'tur',
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

# {{{ overload

use overload
    '+'    => \&_add,
    '-'    => \&_sub,
    '*'    => \&_mul,
    '/'    => \&_div,
    '%'    => \&_mod,
    '++'   => \&_inc,
    '--'   => \&_dec,
    '0+'   => sub { $_[0]->{value} },
    '""'   => sub { $_[0]->{value} },
    '<=>'  => sub { $_[0]->{value} <=> (ref $_[1] ? $_[1]->{value} : $_[1]) },
    'cmp'  => sub { $_[0]->{value} <=> (ref $_[1] ? $_[1]->{value} : $_[1]) },
    fallback => 1;

# }}}
# {{{ new                       constructor — accepts number or text

sub new {
    my $class = shift;
    my $input = shift;

    my $self = bless { value => 0, lang => undef }, $class;

    if (!defined $input) {
        return $self;
    }
    elsif ($input =~ /\A-?\d+\z/) {
        $self->{value} = $input;
    }
    else {
        my ($val, $lang) = $self->cardinal_detect($input);
        if (defined $val) {
            $self->{value} = $val;
            $self->{lang}  = $lang;
        }
        else {
            carp "Could not parse '$input' as a numeral in any known language";
        }
    }

    return $self;
}

# }}}
# {{{ as                        convert to word form in given language

sub as {
    my $self = shift;
    my $lang = shift // $self->{lang} // return;

    require Lingua::Num2Word;
    return Lingua::Num2Word::cardinal($lang, $self->{value});
}

# }}}
# {{{ value                     return numeric value

sub value { return $_[0]->{value} }

# }}}
# {{{ lang                      return detected language

sub lang { return $_[0]->{lang} }

# }}}
# {{{ as_ordinal                convert to ordinal word form in given language

sub as_ordinal {
    my $self = shift;
    my $lang = shift // $self->{lang} // return;

    require Lingua::Num2Word;
    return Lingua::Num2Word::ordinal($lang, $self->{value});
}

# }}}
# {{{ _arith helpers            arithmetic with overloading

sub _binop {
    my ($self, $other, $swap, $op) = @_;
    my $a = $self->{value};
    my $b = ref $other ? $other->{value} : $other;
    my $result = $swap ? $op->($b, $a) : $op->($a, $b);
    return (ref $self)->new(int $result);
}

sub _add { _binop(@_, sub { $_[0] + $_[1] }) }
sub _sub { _binop(@_, sub { $_[0] - $_[1] }) }
sub _mul { _binop(@_, sub { $_[0] * $_[1] }) }
sub _div { _binop(@_, sub { $_[1] ? int($_[0] / $_[1]) : 0 }) }
sub _mod { _binop(@_, sub { $_[1] ? $_[0] % $_[1] : 0 }) }

sub _inc { $_[0]->{value}++; $_[0] }
sub _dec { $_[0]->{value}--; $_[0] }

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
# {{{ cardinal_detect            convert text to number, also return detected language

sub cardinal_detect :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $result = '';
    my $word   = shift // return;

    for my $lang (sort keys %known) {
        $result = '';
        eval $self->preprocess_code($lang);                     ## no critic 'eval'
        next if $@;

        if (defined $result && $result ne '') {
            return wantarray ? ($result, $lang) : $result;
        }
    }

    return;
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

=pod

=encoding utf-8

=head1 NAME

Lingua::Word2Num - Multi-language word to number conversion with numeral arithmetic

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

Lingua::Word2Num converts number words in natural language text into
their numeric values. It supports 44 languages via auto-discovered
Lingua::XXX::Word2Num modules and accepts both ISO 639-1 (C<de>) and
ISO 639-3 (C<deu>) language codes.

The module also provides overloaded numeral objects that support
arithmetic across languages with on-demand rendering into any
supported language.

=head1 SYNOPSIS

=head2 Procedural Interface

 use Lingua::Word2Num qw(cardinal);

 # convert with explicit language code
 my $num = cardinal('de', 'zweiundvierzig');    # 42
 my $num = cardinal('cs', 'sto dvacet');        # 120

 # auto-detect language
 my $num = cardinal('*', 'quarante-deux');       # 42

=head2 Language Detection

 use Lingua::Word2Num qw(cardinal_detect);

 my ($value, $lang) = cardinal_detect('zwanzig');
 # $value = 20, $lang = 'deu'

=head2 Object Interface with Numeral Arithmetic

 use Lingua::Word2Num;

 my $a = Lingua::Word2Num->new("zwanzig");      # German 20
 my $b = Lingua::Word2Num->new("šestnáct");     # Czech 16

 say $a + $b;                # 36
 say ($a + $b)->as('de');    # sechsunddreissig
 say ($a + $b)->as('cs');    # třicet šest
 say ($a + $b)->as('fr');    # trente-six

 $a++;
 say $a->as('de');           # einundzwanzig
 say $a->value;              # 21
 say $a->lang;               # deu

 # construct from number
 my $c = Lingua::Word2Num->new(100);
 say ($c - $b)->as('ja');    # hachi ju yon

=head1 METHODS

=over 2

=item B<new> (positional)

  1   str|num  text in any language, or a number
  =>  obj      Lingua::Word2Num object

Constructor. If given text, auto-detects the language and converts
to a number. If given a number, stores it directly. The detected
language is available via C<< ->lang >>.

=item B<cardinal> (positional)

  1   str    language code (ISO 639-1 or 639-3, or '*' for auto-detect)
  2   str    text to convert
  =>  num    converted number
  =>  ''     if the input string is not recognized

Procedural conversion from text in the specified language to a number.

=item B<cardinal_detect> (positional)

  1   str    text to convert (any language)
  =>  (num, str)  in list context: (value, iso639-3 code)
  =>  num         in scalar context: just the value
  =>  undef       if no language matched

Auto-detects the language and converts to number.

=item B<as> (positional)

  1   str    language code (ISO 639-1 or 639-3)
  =>  str    number rendered as words in the requested language

Converts the object's numeric value to word form.
If no language is given, uses the originally detected language.

=item B<value> (void)

  =>  num    the numeric value stored in the object

=item B<lang> (void)

  =>  str    the ISO 639-3 code of the detected source language
  =>  undef  if constructed from a number

=item B<known_langs> (void)

  =>  lref   sorted list of all supported ISO 639-3 codes

=back

=head1 OVERLOADED OPERATORS

Lingua::Word2Num objects support the following operators. All
arithmetic operations return new Lingua::Word2Num objects.

  +   addition          $a + $b, $a + 5
  -   subtraction       $a - $b
  *   multiplication    $a * $b
  /   integer division  $a / $b
  %   modulo            $a % $b
  ++  increment         $a++
  --  decrement         $a--
  0+  numification      0 + $a, int($a)
  ""  stringification   "$a" (returns the number)
  <=> numeric compare   $a <=> $b, sort

=head1 EXPORT_OK

=over 2

=item cardinal

=item cardinal_detect

=item known_langs

=back

=head1 SEE ALSO

L<Lingua::Num2Word> — the reverse direction (number to words).

L<Task::Lingua::PetaMem> — install all supported languages.

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
