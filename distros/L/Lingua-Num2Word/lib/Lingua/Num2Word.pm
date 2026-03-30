# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2002-present
#
package Lingua::Num2Word;
# ABSTRACT: Multi-language number to word conversion wrapper

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Encode;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
our %known;

# }}}

# {{{ templates for functional and object interface

my $template_func = q{ use __PACKAGE_WITH_VERSION__ ();
                       $result = __PACKAGE__::__FUNCTION__($number);
                     };

my $template_obj  = q{ use __PACKAGE_WITH_VERSION__ ();
                       my $tmp_obj = new __PACKAGE__;
                       $result = $tmp_obj->__FUNCTION__($number);
                     };

# ISO 639-1 to 639-3 mapping for supported languages
# {{{ ISO 639-1 to 639-3 mapping
my %iso1_to_3 = (
    af => 'afr', ar => 'ara', az => 'aze', bg => 'bul', ca => 'cat',
    cs => 'ces', da => 'dan', de => 'deu', el => 'ell',
    en => 'eng', es => 'spa', et => 'est', eu => 'eus',
    fa => 'fas', fi => 'fin', fr => 'fra', he => 'heb',
    hi => 'hin', hr => 'hrv', hu => 'hun', hy => 'hye',
    id => 'ind', is => 'isl', it => 'ita', ja => 'jpn',
    kk => 'kaz', ko => 'kor', ky => 'kir', la => 'lat',
    lt => 'lit', lv => 'lav', mn => 'mon', nl => 'nld',
    'no' => 'nor',
    pl => 'pol', pt => 'por', ro => 'ron', ru => 'rus',
    sk => 'slk', sv => 'swe', sw => 'swa', th => 'tha',
    be => 'bel', cy => 'cym', ga => 'gle', gl => 'glg',
    lb => 'ltz', mk => 'mkd', mt => 'mlt', oc => 'oci',
    sc => 'srd',
    sl => 'slv', so => 'som', sq => 'sqi', sr => 'srp',
    tr => 'tur', ug => 'uig', uk => 'ukr', vi => 'vie',
    yi => 'yid', zh => 'zho',
);
# }}}

# {{{ %known — auto-discovered from lib/Lingua/*/Num2Word.pm

# Override table for legacy modules with non-standard API
# Override table: only for modules with non-default limits or legacy function names.
# All modules now live in Num2Word.pm with num2XXX_cardinal as canonical function.
my %n2w_override = (
    afr => { limit_hi => 99_999_999_999 },
    eng => { limit_lo => 1, limit_hi => 999_999_999_999_999 },
    eus => { limit_hi => 999_999_999_999 },
    fra => { limit_hi => 999_999_999_999_999 },
    ind => { limit_hi => 999_999_999_999_999 },
    ita => { limit_hi => 999_999_999_999 },
    jpn => { limit_lo => 1, limit_hi => 999_999_999_999_999,
             code => q{ use __PACKAGE_WITH_VERSION__ ();
                        my @words = __PACKAGE__::to_string($number);
                        $result = join ' ', @words;
                      },
           },
    nor => { function => 'num2no_cardinal', code => $template_obj },
    pol => { limit_hi => 9_999_999_999_999 },
    por => { limit_hi => 999_999_999_999_999 },
    rus => { limit_hi => 999_999_999_999_999 },
    spa => { limit_hi => 999_999_999_999_999 },
    swe => { function => 'num2sv_cardinal' },
    zho => { limit_lo => 1, limit_hi => 999_999_999_999_999,
             code => q{ use Lingua::ZHO::Num2Word qw(traditional);
                        $result = Lingua::ZHO::Num2Word::number_to_zh($number);
                      },
           },
);

# auto-discover: scan for Lingua::*::Num2Word modules
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

            # standard pattern: Num2Word.pm with num2XXX_cardinal function
            if (-e "$dir/Num2Word.pm" || exists $n2w_override{$lang}) {
                my $ov = $n2w_override{$lang} // {};
                $known{$lang} = {
                    package  => $ov->{package}  // 'Num2Word',
                    version  => $ov->{version}  // '',
                    limit_lo => $ov->{limit_lo} // 0,
                    limit_hi => $ov->{limit_hi} // 999_999_999,
                    function => $ov->{function} // "num2${lang}_cardinal",
                    code     => $ov->{code}     // $template_func,
                };
            }
        }
    }
}

# }}}
# {{{ default capabilities

my %default_capabilities = (
    cardinal => 1,
    ordinal  => 0,
    negative => 0,
    decimal  => 0,
    currency => 0,
);

# }}}
# {{{ capabilities              query what a language module can do

sub capabilities :Export {
    my $self = ref($_[0]) ? shift : undef;
    my $lang = shift // return;

    $lang = lc $lang;
    $lang = $iso1_to_3{$lang} if exists $iso1_to_3{$lang};

    return if !exists $known{$lang};

    # try to load the module's capabilities() if it has one
    my $pkg = 'Lingua::' . uc($lang) . '::' . $known{$lang}{package};
    my $caps;
    eval {
        (my $file = $pkg) =~ s{::}{/}g;
        require "$file.pm";
        if ($pkg->can('capabilities')) {
            $caps = $pkg->capabilities();
        }
    };

    # merge with defaults — module caps override defaults
    my %result = %default_capabilities;
    if ($caps && ref $caps eq 'HASH') {
        $result{$_} = $caps->{$_} for keys %{$caps};
    }

    # add range from %known
    $result{range} = [$known{$lang}{limit_lo} // 0, $known{$lang}{limit_hi} // 999_999_999];

    return \%result;
}

# }}}
# {{{ has_capability            check if a language supports a feature

sub has_capability :Export {
    my $self = ref($_[0]) ? shift : undef;
    my $lang    = shift // return 0;
    my $feature = shift // return 0;

    my $caps = capabilities($lang);
    return 0 unless $caps;
    return $caps->{$feature} ? 1 : 0;
}

# }}}
# {{{ ordinal                   convert number to ordinal text

sub ordinal :Export {
    my $self   = ref($_[0]) ? shift : Lingua::Num2Word->new();
    my $result = '';
    my $lang   = shift // return $result;
    my $number = shift // return $result;

    $lang = lc $lang;
    $lang = $iso1_to_3{$lang} if exists $iso1_to_3{$lang};

    return $result if !exists $known{$lang};
    return $result if !has_capability($lang, 'ordinal');

    my $pkg = 'Lingua::' . uc($lang) . '::' . $known{$lang}{package};
    # derive ordinal function name from cardinal (handles legacy names like num2sv_)
    my $cardinal_func = $known{$lang}{function} // "num2${lang}_cardinal";
    my $func;
    if ($cardinal_func =~ /_cardinal$/) {
        ($func = $cardinal_func) =~ s/_cardinal$/_ordinal/;
    }
    else {
        $func = "num2${lang}_ordinal";  # fallback for OO/legacy modules
    }

    eval "use $pkg (); \$result = ${pkg}::${func}(\$number);"; ## no critic
    carp $@ if $@;

    return $result;
}

# }}}
# {{{ new                       constructor

sub new {
    return bless {}, shift;
}

# }}}
# {{{ known_langs               list of currently supported languages

sub known_langs :Export {
    return wantarray ? sort keys %known : [ sort keys %known ];
}

# }}}
# {{{ get_interval              get minimal and maximal supported number

# Return:
#  undef for unsupported language
#  list or list reference (depending to calling context) with
#  minimal and maximal supported number
#
sub get_interval :Export {
    my $self = ref($_[0]) ? shift : Lingua::Num2Word->new();
    my $lang = shift // return;
    $lang = lc $lang;
    $lang = $iso1_to_3{$lang} if exists $iso1_to_3{$lang};

    return if (!defined $known{$lang});

    my @limits = ($known{$lang}{limit_lo}, $known{$lang}{limit_hi});

    return wantarray ? @limits : \@limits;
}

# }}}
# {{{ cardinal                  convert number to text

sub cardinal :Export {
    my $self   = ref($_[0]) ? shift : Lingua::Num2Word->new();
    my $result = '';
    my $lang   = shift // return $result;
    my $number = shift // return $result;

    $lang = lc $lang;
    $lang = $iso1_to_3{$lang} if exists $iso1_to_3{$lang};

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

sub preprocess_code :Export {
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

=pod

=encoding utf-8

=head1 NAME

Lingua::Num2Word - Multi-language number to word conversion wrapper


=head1 VERSION

version 0.2603300

Lingua::Num2Word is a wrapper for modules for converting numbers into
their equivalent in written representation.

This is a wrapper for various Lingua::XXX::Num2Word modules that do the
conversions for specific languages. Output encoding is utf-8.

For further information about various limitations of the specific
modules see their documentation.

=cut

# }}}
# {{{ SYNOPSIS

=pod

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
     print "Number is outside of supported range
              - <$$limit[0], $$limit[1]>.";
   }
   else {
     print Lingua::Num2Word::cardinal( 'ces', $number );
   }
 }
 else {
   print "Unsupported language.";
 }

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<cardinal> (positional)

  1   str    target language
  2   num    number to convert
  =>  str    converted string
  =>  undef  if input number is not supported

Conversion from number to text representation in specified language.

=item B<get_interval> (positional)

  1   str    language specification
  =>  any    an array/arref - list with min max values
  =>  undef  if specified language is not known

Returns the minimal and maximal number (inclusive) supported by the
conversion in a specified language. The returned value is a list of
two elements (low,high) or reference to this list depending on calling
context. In case a unsupported language is passed undef is returned.

=item B<known_langs> (void)

  =>  any  an array/arref - list of supported languages

List of all currently supported languages. Return value is a list or
a reference to a list depending on calling context.

=item B<langs> (void)

  =>  any  an array/arref - list of languages known by ISO 639-3 list

List of all known language codes from iso639. Return value is list or
reference to list depending on calling context.

=item B<new> (void)

  =>  obj  returns new object

Constructor.

=item B<ordinal> (positional)

  1   str    target language (ISO 639-3 or 639-1)
  2   num    number to convert
  =>  str    ordinal text representation
  =>  ''     if language has no ordinal support or input is out of range

Conversion from number to ordinal text representation in specified language.
Requires the language module to export a C<num2XXX_ordinal> function and
to declare C<< ordinal => 1 >> in its C<capabilities()>.

=item B<capabilities> (positional)

  1   str    language (ISO 639-3 or 639-1)
  =>  href   hashref of capabilities
  =>  undef  if language is not known

Query what a language module can do.  The returned hashref contains keys
C<cardinal>, C<ordinal>, C<negative>, C<decimal>, C<currency>, and
C<range> (an arrayref C<[$lo, $hi]>).

=item B<has_capability> (positional)

  1   str    language (ISO 639-3 or 639-1)
  2   str    feature name (e.g. 'ordinal', 'cardinal')
  =>  bool   1 if the language supports the feature, 0 otherwise

=item B<preprocess_code> (void)

  =>  undef  if lang is not specified
  =>  str    a template

Private function.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item cardinal

=item ordinal

=item capabilities

=item has_capability

=item get_interval

=item known_langs

=item langs

=back

=cut

# }}}
# {{{ REQUIRED MODULES

=pod

=head1 Supported languages

Languages are auto-discovered at load time from installed
C<Lingua::*::Num2Word> modules.  Use C<known_langs()> to obtain the
current list programmatically.

Each language is identified by its ISO 639-3 code (e.g. C<deu>, C<eng>,
C<fra>).  ISO 639-1 two-letter codes (C<de>, C<en>, C<fr>) are accepted
as aliases and mapped automatically.

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
