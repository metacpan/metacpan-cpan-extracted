#!/usr/bin/perl -w
# vim:ts=4:sw=4:et:at:
#
# PROGRAM:	Math::Currency.pm	# - 04/26/00 9:10:AM
# PURPOSE:	Perform currency calculations without floating point
#
#------------------------------------------------------------------------------
#   Copyright (c) 2001-2008 John Peacock
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#------------------------------------------------------------------------------

package Math::Currency;
$Math::Currency::VERSION = '0.52';
# ABSTRACT: Exact Currency Math with Formatting and Rounding

use strict;
use utf8;
use base qw(Exporter Math::BigFloat);
use Math::BigFloat 1.60;
use POSIX qw(locale_h);
use Encode::Locale;
use Encode ();

use overload '""' => \&bstr;

our $LC_MONETARY = {
    en_US => {
        INT_CURR_SYMBOL   => 'USD ',
        CURRENCY_SYMBOL   => '$',
        MON_DECIMAL_POINT => '.',
        MON_THOUSANDS_SEP => ',',
        MON_GROUPING      => '3',
        POSITIVE_SIGN     => '',
        NEGATIVE_SIGN     => '-',
        INT_FRAC_DIGITS   => '2',
        FRAC_DIGITS       => '2',
        P_CS_PRECEDES     => '1',
        P_SEP_BY_SPACE    => '0',
        N_CS_PRECEDES     => '1',
        N_SEP_BY_SPACE    => '0',
        P_SIGN_POSN       => '1',
        N_SIGN_POSN       => '1',
    },
};
$LC_MONETARY->{USD} = $LC_MONETARY->{en_US};

our $FORMAT = $LC_MONETARY->{en_US} unless localize();

our @EXPORT_OK = qw(
    $LC_MONETARY
    $FORMAT
    Money
);

# Set class constants
our $round_mode = 'even';    # Banker's rounding obviously
our $accuracy   = undef;
our $precision = $FORMAT->{FRAC_DIGITS} > 0 ? -$FORMAT->{FRAC_DIGITS} : 0;
our $div_scale = 40;
our $use_int   = 0;
our $always_init = 0;        # should the localize() happen every time?


sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = $proto if ref($proto);

    my $value = shift || 0;

    if (eval("'1.01' ne 1.01")) { # this might be a comma locale
	$value =~ tr/,/./;
    }
    $value =~ tr/-()0-9.//cd;    #strip any formatting characters
    $value = "-$value" if $value =~ s/(^\()|(\)$)//g;    # handle parens

    if ( (caller)[0] =~ /Math\::BigInt/ )    # only when called from objectify()
    {
        return Math::BigFloat->new($value);
    }

    my $self;
    my $currency = shift;
    my $format;

    if ( not defined $currency and $class->isa('Math::Currency') ) {
        # must be one of our subclasses
        $currency = $1 if ($class =~ /Math::Currency::(\w+)/);
    }

    if ( defined $currency )    #override default currency type
    {
        unless ( defined $LC_MONETARY->{$currency} ) {
            eval "require Math::Currency::$currency";
            unknown_currency($currency) if $@;
        }
        $format = $LC_MONETARY->{$currency};
    }

    if ($format) {
        $self =
          Math::BigFloat->new( $value, undef, -( $format->{FRAC_DIGITS} + 2 ) );
        bless $self, $class;
        $self->format($format);
    }
    elsif ( $parent
        and defined $parent->{format} ) # if we are cloning an existing instance
    {
        $self =
          Math::BigFloat->new( $value, undef,
            -( $parent->format->{FRAC_DIGITS} + 2 ) );
        bless $self, $class;
        $self->format( $parent->format );
    }
    else {
        $self =
          Math::BigFloat->new( $value, undef, -( $FORMAT->{FRAC_DIGITS} + 2 ) );
        bless $self, $class;
    }
    return $self;
}    ##new


sub Money {
    return __PACKAGE__->new(@_);
}

sub bstr {
    my $self     = shift;
    my $myformat = $self->format();
    my $value    = $self->as_float();
    my $neg      = ( $value =~ tr/-//d );
    my $dp       = index( $value, "." );
    my $sign     = $neg
      ? $myformat->{NEGATIVE_SIGN}
      : $myformat->{POSITIVE_SIGN};
    my $curr = $use_int
      ? $myformat->{INT_CURR_SYMBOL}
      : $myformat->{CURRENCY_SYMBOL};
    my $digits = $use_int
      ? $myformat->{INT_FRAC_DIGITS}
      : $myformat->{FRAC_DIGITS};
    my $formtab = [
        [
            [ '($value$curr)',    '($value $curr)',    '($value $curr)' ],
            [ '$sign$value$curr', '$sign$value $curr', '$sign$value $curr' ],
            [ '$value$curr$sign', '$value $curr$sign', '$value$curr $sign' ],
            [ '$value$sign$curr', '$value $sign$curr', '$value$sign $curr' ],
            [ '$value$curr$sign', '$value $curr$sign', '$value$curr $sign' ],
        ],
        [
            [ '($curr$value)',    '($curr $value)',    '($curr $value)' ],
            [ '$sign$curr$value', '$sign$curr $value', '$sign $curr$value' ],
            [ '$curr$value$sign', '$curr $value$sign', '$curr$value $sign' ],
            [ '$sign$curr$value', '$sign$curr $value', '$sign $curr$value' ],
            [ '$curr$sign$value', '$curr$sign $value', '$curr $sign$value' ],
        ],
    ];

    if ( $dp < 0 ) {
        $value .= '.' . '0' x $digits;
    }
    elsif ( ( length($value) - $dp - 1 ) < $digits ) {
        $value .= '0' x ( $digits - $dp );
    }

    ( $value = reverse "$value" ) =~ s/\+//;

    # make sure there is a leading 0 for values < 1
    if ( substr( $value, -1, 1 ) eq '.' ) {
        $value .= "0";
    }
    $value =~ s/\./$myformat->{MON_DECIMAL_POINT}/;
    $value =~
s/(\d{$myformat->{MON_GROUPING}})(?=\d)(?!\d*\.)/$1$myformat->{MON_THOUSANDS_SEP}/g;
    $value = reverse $value;

    eval '$value = "'
      . (
          $neg
        ? $formtab->[ $myformat->{N_CS_PRECEDES} ][ $myformat->{N_SIGN_POSN} ]
          [ $myformat->{N_SEP_BY_SPACE} ]
        : $formtab->[ $myformat->{P_CS_PRECEDES} ][ $myformat->{P_SIGN_POSN} ]
          [ $myformat->{P_SEP_BY_SPACE} ]
      )
      . '"';

    if ( substr( $value, -1, 1 ) eq '.' ) {    # trailing bare decimal
        chop($value);
    }

    return $value;
}    ##stringify



sub format {
    my $self  = shift;
    my $key   = shift;    # do they want to display or set?
    my $value = shift;    # did they supply a value?
    localize() if $always_init;    # always reset the global format?
    my $source = \$FORMAT;         # default format rules

    if ( ref($self) ) {
        if ( defined $self->{format} ) {
            if ( defined $key and $key eq '' ) {
                delete $self->{format};
                $source = \$FORMAT;
            }
            else {
                $source = \$self->{format};
            }
        }
        elsif ( defined $key )     # get/set a parameter
        {
            if ( defined $value
                or ref($key) eq "HASH" )    # have to copy global format
            {
                while ( my ( $k, $v ) = each %{$FORMAT} ) {
                    $self->{format}{$k} = $v;
                }
                $source = \$self->{format};
            }
        }
    }
    else { # called as class method to set the default currency
	if ( defined $key && not exists $FORMAT->{$key} ) {
	    unless ( defined $LC_MONETARY->{$key} ) {
		eval "require Math::Currency::$key";
		unknown_currency($key) if $@;
	    }
	    $FORMAT = $LC_MONETARY->{$key};
	    return $FORMAT;
	}
    }


    if ( defined $key )                     # otherwise just return
    {
        if ( ref($key) eq "HASH" )          # must be trying to replace all
        {
            $$source = $key;
        }
        else                                # get/set just one parameter
        {
            return $$source->{$key} unless defined $value;
            $$source->{$key} = $value;
        }
    }
    return $$source;
}    ##format


sub as_float {
    my $self   = shift;
    my $format = $self->format;
    my $string = $self->copy->bfround( -$format->{FRAC_DIGITS} )->SUPER::bstr();
    return $string;
}


sub copy {
    my $self = shift;

    # grab the builtin formatting
    my $myformat = ( defined $self->{format} ? $self->{format} : undef );

    # let Math::BigFloat do it's thing
    my $new = $self->SUPER::copy(@_);

    if ($myformat) {

        # make sure we keep the original formatting
        $new->format($myformat);
    }

    # done...
    return $new;
}



sub as_int {
    my $self = shift;
    (my $str = $self->as_float) =~ s/\.//o;
    $str =~ s/^(\-?)0+/$1/o;
    return $str eq '' ? '0' : $str;
}

# we override the default here because we only want to compare the precision of
# the currency we're dealing with, not the precision of the underlying object
sub bcmp {
    # See RT #115247, #115761
    # bcmp() might get called in comparison overoad as an object method with
    # one arg, or, as a class method with two args depending on the version of
    # Math::BigInt that is installed. Workaround is to check if @_ has three
    # args, and if so, the first one is the class name.  Otherwise, the first
    # arg is the left side is an object that bcmp() is called on.
    # An alternate solution to this is to require Math::BigInt >= 1.999718
    # which always uses bcmp() as an object method.
    my $class = (@_ == 3) ? shift : __PACKAGE__;

    # make sure we're dealing with two Math::Currency objects
    my ( $x, $y ) =
        map { ref $_ ne $class ? $class->new($_) : $_ } @_[ 0, 1 ];

    return $x->as_float <=> $y->as_float;
}


sub localize {
    my $self   = shift;
    my $format = shift || \$FORMAT;

    my $localeconv = POSIX::localeconv(); 

    # localeconv()'s character encoding depends on the current locale setting,
    # so it is necessary to decode the currency symbol.
    Encode::Locale::reinit(); # neede in case locale was changed with setlocale()

    for my $key (keys %$localeconv) {
        # POSIX::localeconv() changed behaviour between 5.20 and 5.22.  As of
        # 5.22, it sets the UTF-8 flag for localeconv() returned data if hte
        # data is in UTF-8 format, so if POSIX::localeconv() already turned on
        # the UTF-8 flag, we should not decode the data.
        unless (utf8::is_utf8($$localeconv{$key})) {
            $$localeconv{$key} = Encode::decode(locale => $$localeconv{$key});
        }
    }

    # so you can test to see if locale was effective
    return 0 if ! exists $localeconv->{'currency_symbol'};

    $$format = {
        INT_CURR_SYMBOL   => $localeconv->{'int_curr_symbol'}   || '',
        CURRENCY_SYMBOL   => $localeconv->{'currency_symbol'}   || '',
        MON_DECIMAL_POINT => $localeconv->{'mon_decimal_point'} || '',
        MON_THOUSANDS_SEP => $localeconv->{'mon_thousands_sep'} || '',
        MON_GROUPING      => (
            exists $localeconv->{'mon_grouping'}
              and defined $localeconv->{'mon_grouping'}
              and ord( $localeconv->{'mon_grouping'} ) < 47
            ? ord( $localeconv->{'mon_grouping'} )
            : $localeconv->{'mon_grouping'}
          )
          || 0,
        POSITIVE_SIGN   => $localeconv->{'positive_sign'}   || '',
        NEGATIVE_SIGN   => $localeconv->{'negative_sign'}   || '-',
        INT_FRAC_DIGITS => $localeconv->{'int_frac_digits'} || 0,
        FRAC_DIGITS     => $localeconv->{'frac_digits'}     || 0,
        P_CS_PRECEDES   => $localeconv->{'p_cs_precedes'}   || 0,
        P_SEP_BY_SPACE  => $localeconv->{'p_sep_by_space'}  || 0,
        N_CS_PRECEDES   => $localeconv->{'n_cs_precedes'}   || 0,
        N_SEP_BY_SPACE  => $localeconv->{'n_sep_by_space'}  || 0,
        P_SIGN_POSN     => $localeconv->{'p_sign_posn'}     || 1,
        N_SIGN_POSN     => $localeconv->{'n_sign_posn'}     || 0,
    };

    return 1;
}


{
    my $locales;
    sub available_locales {
        return if $^O =~ /Win32/; # cant run locale -a on windows

        unless (defined $locales) {
            $locales = [];

            open my $fh, '-|', 'locale -a' or die $!;

            while (my $locale = <$fh>) {
                chomp $locale;
                push @$locales, $locale;
            }

            close $fh;
        }

        return @$locales;
    }
}

# if no currency module exists for the requested currency, this function tries
# to find the currency settings from the available locales
sub unknown_currency {
    my ($currency) = @_;

    # remember current locale
    my $original_locale = setlocale( LC_ALL );

    # we need to save a copy of $VERSION here becuase the effective locale can
    # render $VERSION as X,YY instead of Y.YY for exmaple
    my $version = "$Math::Currency::VERSION";

    for my $LOCALE (available_locales()) {
        setlocale( LC_ALL, $LOCALE );
        my $localeconv = POSIX::localeconv();
        if ( $LOCALE eq $currency or
            ($localeconv->{int_curr_symbol} || '') =~ /$currency/ )
        {
            my $format = \$LC_MONETARY->{$currency};
            Math::Currency->localize($format);
            (my $int_curr = $$format->{INT_CURR_SYMBOL}) =~  s/ //g;
            $LC_MONETARY->{$int_curr} = $LC_MONETARY->{$currency}
                unless exists $LC_MONETARY->{$int_curr};
            eval <<"EOP";
package Math::Currency::${LOCALE};

use base 'Math::Currency';
our \$VERSION = $version;
our \$LANG  = '$LOCALE';

1;

package Math::Currency::${int_curr};

use base 'Math::Currency';

our \$VERSION = $version;
our \$LANG  = '$LOCALE';

1;
EOP
            last;
        }
    }

    # restore the original locale
    setlocale( LC_ALL, $original_locale );
}

# additional methods needed to get/set package globals


sub always_init {
    my $class = shift;

    if (@_) {
        $always_init = shift;
    }

    return $always_init;
}


sub use_int {
    my $class = shift;

    if (@_) {
        $use_int = shift;
    }

    return $use_int;
}

1;

__END__

=pod

=head1 NAME

Math::Currency - Exact Currency Math with Formatting and Rounding

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 use Math::Currency qw(Money $LC_MONETARY);

 my $dollar = Math::Currency->new("$12,345.67");
 my $taxamt = $dollar * 0.28;

 # this sets the default format for all objects w/o their own format
 Math::Currency->format('EUR');

 my $euro = Money(12345.67);
 my $euro_string = Money(12345.67)->bstr();

 # or if you already have a Math::Currency object
 $euro_string = "$euro";

=head1 DESCRIPTION

Currency math is actually more closely related to integer math than it is to
floating point math.  Rounding errors on addition and subtraction are not
allowed and division/multiplication should never create more accuracy than the
original values.  All currency values should round to the closest cent or
whatever the local equivalent should happen to be.

However, repeated mathematical operations on currency values can lead to
inaccurate results, if rounding is performed at each intermediate step.
In order to preserve appropriate accuracy, the Math::Currency values are
stored with an additional two places of accuracy internally and only
rounded to the "correct" precision when the value is displayed (either by
the default stringification or through the use of L<as_float> or L<as_int>).

All common mathematical operations are overloaded, so once you initialize a
currency variable, you can treat it like any number and the module will do
the right thing.  This module is a thin layer over Math::BigFloat which
is itself a layer over Math::BigInt.

=head1 METHODS

=head2 new

Create a new currency object.  This can be called a number of ways:

=over 4

=item *

new()

Creates a new currency object with value "0".

=item *

new($value)

Creates a new currency object with the given value. Note that C<$value> should
be quoted to avoid locale formatting issues.  E.g.: C<< new('1234.56') >>.

=item *

new($value, $curency)

Creates a new currency object in the given locale.  See L<Predefined Locales>.

=back

=head2 format($key, $value)

Set object or global formatting.  See L<Object Formats> for more information.

=head2 as_float

Bare floating point notation without currency formatting.

When storing the value into a database, you often need a string which
corresponds to the value of the currency as a floating point number, but
without the special currency formatting.  That is what this object method
produces.  Be sure and use e.g. DECIMAL(10,2) in MySQL, or NUMERIC(10,3) in
PostgreSQL to ensure that you don't have any floating point rounding issues
going from/to the database.

=head2 copy

Returns a copy of the current Math::Currency object.

=head2 as_int

Some US credit card gateways require all transactions to be expressed in
pennies.  This object method returns an integer value that corresponds to the
currency value multiplied by 10 to the power of the number of decimal places of
precision.  Essentially, this expresses the currency amount in the smallest
discrete value allowed with that currency, so for currency expressed in 
dollars, this method returns the same value in pennies.

=head2 localize

Reinitialize the global (if called with no arguments), or local (if called with
a reference to a hashref) format hash.

If you don't want to always have to remember to reinitialize the POSIX settings
when you switch locales, see L<always_init>

Examples:

=over 4

=item *

C<< Math::Currency->localize() >>

Renitialize the global internal format hash using the current locale

=item *

C<< Math::Currency->localize(\$format) >>

Renitialize the hashref C<$format> using the current locale.

=back

=head2 available_locales

Get the list of available locales on this system

=head2 always_init

If you don't want to always have to remember to reinitialize the POSIX settings
when you switch locales, you can call this with a true value.

 Math::Currency->always_init(1);

Alternatively, you can set the global variable:

 $Math::Currency::always_init = 1;

and every single time a Math::Currency object is printed, the global $FORMAT
will be updated to the locale current at that time.  This may be a performance
hit.  It would be better if you followed the method of manually updating the
global format immediately after you reset the locale.

=head3 Notes

=over 4

=item *

This function will reset only the global format and will not have effect on
objects created with their own overridden formats, even if they were
originally based on the global format.

=item *

You must have all the locale files in question already loaded; the list
reported by C<locale -a> is not always a reliable judge of what files you might
actually have installed.  If you try and set a nonexistant locale, or set the
same locale as is already active, the module will silently retain the current
locale settings.

=back

=head2 use_int

Default: false

Pass a true value to this to indicate that the international currency symbol
(C<INT_CURR_SYMBOL>) should be used instead of local currency symbol
(C<CURRENCY_SYMBOL>).  Note that this is a global setting for the library and
will affect all objects.  For example, in the C<USD> locale, stringification of
C<1234.56> looks like:

=over 4

=item *

use_int(0)

$1,234.56

=item *

use_int(1)

USD 1,234.56

=back

=head1 FUNCTIONS

=head2 Money

This an exportable function that constructs a new object.  Takes the same arguments
as C<new()>.

=encoding UTF-8

=for Pod::Coverage unknown_currency

=head1 Important Note on Input Values

Since the point of this module is to perform currency math and not floating
point math, it is important to understand how the initial value passed to new()
may have nasty side effects if done improperly.  Most of the time, the following
two objects are identical:

        $cur1 = new Math::Currency 1000.01;
        $cur2 = new Math::Currency "1000.01";

However, only the second is guaranteed to do what you think it should do.  The
reason for that lies in how Perl treats bare numbers as opposed to strings.  The
first new() will receive the Perl-stringified representation of the number
1000.01, whereas the second new() will receive the string "1000.01" instead.
With most locale settings, this will be largely identical.  However, with many
European locales (like fr_FR), the first new() will receive the string
"1 000,01" and this will cause Math::BigFloat to report this as NAN (Not A
Number) because of the odd posix driven formatting.

For this reason, it is always recommended that input values be quoted at all
times, even if your POSIX locale does not have this unfortunate side effect.

=head1 Output Formatting

Each currency value can have an individual format or the global currency
format can be changed to reflect local usage.  I used the suggestions in Tom
Christiansen's L<PerlTootC|http://www.perl.com/language/misc/perltootc.html#Translucent_Attributes>
to implement translucent attributes.  If you have set your locale values
correctly, this module will pick up your local settings or US standards if you
haven't.  You can also specify an output format using one of the predefined
Locale formats or your own custom format.

=head2 Locale Support

This module uses the builtin locale support provided by your operating system
to generate the appropriate currency formatting.  Much of this support will
happen automagically if you have your LANG environment setting correct.  If you
chose not to install multiple locales when you installed your operating system,
you will only be able to use your default locale format or one of the
L<Predefined Locales> included in the distribution.

The automatic locale support will take effect if you request a locale by name
in the for lc_CC (language/country code) like fr_CA (French Canadian) or 
en_NZ (English New Zealand).  If you pregenerate your L<Custom Locale>, an 
alias class will be added so that you can refer to the currency by either
the locale name or the INT_CURR_SYMBOL (e.g. USD or GBP).

B<IMPORTANT NOTE>: there are multiple locales which implement the EUR (Euro)
currency, each with slightly different formatting rules (aren't standards
wonderful).  If you C<use> multiple currencies that represent EUR, the last
one loaded will be available as the INT_CURR_SYMBOL shortcut.  You should
always use the locale name to refer to these currencies, if you are mixing
them in a single program.

=head2 Predefined Locales

There are currently four predefined Locale formats:

    en_US = United States dollars (the default if no locale)
    en_GB = British Pounds Sterling
    ja_JP = Japanese Yen 
    de_DE = German Euro

These currency formats are implemented using subclasses for easy extension 
(see L<Custom Locales> for details on creating new subclasses for
unsupported locales).  If you are using a locale in a country that uses the
Euro, you should create your own local format file using your default LANG 
setting, since the Euro formatting rules are country specific.

If you want to use any locale other than your default in a single script, there
are two different ways to specify which currency format you wish to use, with
somewhat subtle differences:

=over 4

=item * Additional parameter to new()

If you need a single currency of a different type than the others in your
program, use this mode:

  use Math::Currency;
  my $dollars = Math::Currency->new("1.23"); # default behavior
  my $euros = Math::Currency->new("1.23", "de_DE"); # different format

The last line above will automatically load the applicable subclass and
use that formatting for that specific object.  These formats can either use
a pre-generated subclass or will automatically generate an automatic
L<Custom Locale>,

=back

=over 4

=item * Directly calling the subclass

If all (or most) of your currency values should be formatted using the same
rules, create the objects directly using the subclass:

  use Math::Currency::ja_JP; # Japanese Yen
  my $yen = Math::Currency::JPY->new("1.345"); # compatibility class
  my $yen2 = $yen->new("3.456"); # you can use an existing object

=back

=head2 Currency Symbol

The locale definition includes two different Currency Symbol strings: one
is the native character(s), like $ or £ or ¥; the other is the three
character string defined by the ISO4217 specification followed by the
normal currency separation character (frequently space).  The default
behavior is to always display the native CURRENCY_SYMBOL unless a global
parameter is set:

    $Math::Currency::use_int = 1; # print the currency symbol text

where the INT_CURR_SYMBOL text will used instead.

=head2 Custom Locales 

The included file, scripts/new_currency, will automatically create a new
currency formatting subclass, based on your current locale, or any
arbitrary locale supported by your operating system.  For most unix-like
O/S's, the following command will list the locale files installed:

    locale -a

and any of those installed locales can [potentially] be used to create a
new locale formatting file. 

It is not I<necessary> to do this, since using the L<format> command to
switch to a locale which doesn't already have a subclass defined for it
will attempt to generate a locale format on the fly.  However, it should be
noted that the automated generation method will merely look for the first
locales that uses the requested INT_CURR_SYMBOL.  There may be several locales
which use that same currency symbol, with subtle differences (this is
especially true of the EUR format), so it is best to pre-generate all
of the POSIX currency subclasses you expect, based on the locales you wish
to support, to utilize when installing this module, instead of relying on
the autogeneration methods.

To create a new locale formatting subclass, change to the top level build
directory for Math::Currency and run the following command:

    scripts/new_currency [xx_XX]

where xx_XX is the locale name obtained from the `locale -a` command.  This
will create a new locale subclass in the lib/Math/Currency/ directory, and
this file will be installed when `./Build install` is next run.

If you run the script without any commandline option, it will take the contents
of your LANG environment variable and generate your default locale.  NOTE that
if you are using a UTF-8 locale, the generated file will also be UTF-8 (which
may not be what you want).  You probably always want to specify the locale
name when generating new classes.

The new_currency script will function from within the current build
directory, and doesn't depend the current version of Math::Currency 
being already installed, so you can build all of your commonly used
locale files and install them at once.

=head2 Global Format

Global formatting can be changed by setting the package global format like
this:

    Math::Currency->format('USD');

=head2 POSIX Locale Global Formatting

In addition to the four predefined formats listed above, you can also use
the POSIX monetary format for a locale which you are not currently running
(e.g. for a web site).  You can set the global monetary format in effect
at any time by using:

    use POSIX qw( locale_h );
    setlocale(LC_ALL,"en_GB");   # some locale alias
    Math::Currency->localize;    # reinitialize global format

If you don't want to always have to remember to reinitialize the POSIX settings
when you switch locales, see L<always_init>

=head2 Object Formats

Any object can have it's own format different from the current global format,
like this:

    $pounds  = Math::Currency->new(1000, 'GBP');
    $dollars = Math::Currency->new(1000); # inherits default US format
    $dollars->format( 'USD' ); # explicit object format

=head2 Format Parameters

The format must contains all of the commonly configured LC_MONETARY
Locale settings.  For example, these are the values of the default US format
(with comments):
  {
    INT_CURR_SYMBOL    => 'USD',  # ISO currency text
    CURRENCY_SYMBOL    => '$',    # Local currency character
    MON_DECIMAL_POINT  => '.',    # Decimal seperator
    MON_THOUSANDS_SEP  => ',',    # Thousands seperator
    MON_GROUPING       => '3',    # Grouping digits
    POSITIVE_SIGN      => '',     # Local positive sign
    NEGATIVE_SIGN      => '-',    # Local negative sign
    INT_FRAC_DIGITS    => '2',    # Default Intl. precision
    FRAC_DIGITS        => '2',    # Local precision
    P_CS_PRECEDES      => '1',    # Currency symbol location
    P_SEP_BY_SPACE     => '0',    # Space between Currency and value
    N_CS_PRECEDES      => '1',    # Negative version of above
    N_SEP_BY_SPACE     => '0',    # Negative version of above
    P_SIGN_POSN        => '1',    # Position of positive sign
    N_SIGN_POSN        => '1',    # Position of negative sign
  }

See chart below for how the various sign character and location settings
interact.

Each of the formatting parameters can be individually changed at the object
or class (global) level; if an object is currently sharing the global format,
all the global parameters will be copied prior to setting the overrided
parameters.  For example:

    $dollars = Math::Currency->new(1000); # inherits default US format
    $dollars->format('CURRENCY_SYMBOL',' Bucks'); # now has its own format
    $dollars->format('P_CS_PRECEDES',0); # now has its own format
    print $dollars; # displays as "1000 Bucks"

Or you can also set individual elements of the current global format:

    Math::Currency->format('CURRENCY_SYMBOL',' Bucks'); # global changed

The [NP]_SIGN_POSN parameter determines how positive and negative signs are
displayed.  [NP]_CS_PRECEEDS determines where the currency symbol is shown.
[NP]_SEP_BY_SPACE determines whether the currency symbol cuddles the value
or not.  The following table shows the relationship between these three
parameters:

                                               p_sep_by_space
                                         0          1          2

 p_cs_precedes = 0   p_sign_posn = 0    (1.25$)    (1.25 $)   (1.25 $)
                     p_sign_posn = 1    +1.25$     +1.25 $    +1.25 $
                     p_sign_posn = 2     1.25$+     1.25 $+    1.25$ +
                     p_sign_posn = 3     1.25+$     1.25 +$    1.25+ $
                     p_sign_posn = 4     1.25$+     1.25 $+    1.25$ +

 p_cs_precedes = 1   p_sign_posn = 0   ($1.25)   ($ 1.25)   ($ 1.25)
                     p_sign_posn = 1   +$1.25    +$ 1.25    + $1.25
                     p_sign_posn = 2    $1.25+    $ 1.25+     $1.25 +
                     p_sign_posn = 3   +$1.25    +$ 1.25    + $1.25
                     p_sign_posn = 4   $+1.25    $+ 1.25    $ +1.25

(the negative variants are similar).

=head1 HISTORY

Created by John Peacock E<lt>jpeacock@cpan.orgE<gt> who maintained this module up to
version 0.4502.  Versions 0.48 and later were maintained by Michael Schout
E<lt>mschout@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item *

perllocale

=item *

L<Math::BigFloat>

=item *

L<Math::BigInt>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/perl-math-currency>
and may be cloned from L<git://github.com/mschout/perl-math-currency.git>

=head1 BUGS

Please report any bugs or feature requests to bug-math-currency@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Currency

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by John Peacock <jpeacock@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
