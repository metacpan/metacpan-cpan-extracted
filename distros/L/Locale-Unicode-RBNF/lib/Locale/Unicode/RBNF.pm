##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/10/22
## Modified 2026/10/26
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# Port of ICU4C RuleBasedNumberFormat (icu4c/source/i18n/rbnf.cpp, ICU 79.1)
package Locale::Unicode::RBNF;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $VERSION $ERROR $FATAL_EXCEPTIONS $IsPurePerl $K_MAX_DOUBLE $NV_IS_WIDE
        %GROUPINGS %ROUNDING_MODES %CAPITALIZATION %DEFAULT_SYMBOLS
    );
    use Locale::Unicode v0.4.4;
    use Locale::Unicode::RBNF::CLDR;
    use Locale::Unicode::RBNF::DecimalFormat;
    use Locale::Unicode::RBNF::PluralFormat;
    use Locale::Unicode::RBNF::PluralRules;
    use Locale::Unicode::RBNF::Rule;
    use Locale::Unicode::RBNF::RuleSet;
    use Locale::Unicode::RBNF::Util qw( :all );
    use Config;
    use Scalar::Util ();
    use Wanted;
    # kMaxDouble in rbnf.cpp: (1 << 22) * (1 << 22)
    $K_MAX_DOUBLE = 4194304.0 * 4194304.0;
    # True when perl uses a long double or a __float128 for its NVs.
    # Parsed results, which are doubles in ICU, must then be rounded to double so that
    # both engines return the same values.
    $NV_IS_WIDE = ( $Config{nvsize} > 8 ) ? 1 : 0;
    %GROUPINGS = (
        spellout            => 'SpelloutRules',
        ordinal             => 'OrdinalRules',
        duration            => 'DurationRules',
        numbering_system    => 'NumberingSystemRules',
    );
    %ROUNDING_MODES = map{ $_ => 1 } qw( ceiling floor down up half_even half_down half_up unnecessary half_odd half_ceiling half_floor );
    %CAPITALIZATION = map{ $_ => 1 } qw( none middle_of_sentence beginning_of_sentence ui_list_or_menu standalone );
    # Root symbols, used when no CLDR directory is available
    %DEFAULT_SYMBOLS = (
        decimal             => '.',
        group               => ',',
        minus               => '-',
        plus                => '+',
        percent             => '%',
        per_mille           => "\x{2030}",
        infinity            => "\x{221E}",
        nan                 => 'NaN',
        digits              => [0..9],
        numbering_system    => 'latn',
    );
    our $VERSION = 'v0.1.1';
};

# Load XS; fall back to pure-Perl implementations if unavailable.
{
    my $loaded = 0;
    unless( $ENV{PERL_LOCALE_UNICODE_RBNF_PP} )
    {
        local $@;
        eval
        {
            require XSLoader;
            XSLoader::load( __PACKAGE__, $VERSION );
            $loaded     = 1;
            $IsPurePerl = 0;
        };
        if( $@ )
        {
            # Fall back to pure-Perl silently on:
            # - version mismatch ("object version")
            # - not a shared lib ("loadable object")
            # - missing compiler builtin not available on old GCC/platforms ("Undefined symbol")
            die( $@ ) if( $@ && $@ !~ /object version|loadable object|Undefined symbol/i );
        }
    }
    unless( $loaded )
    {
        require Locale::Unicode::RBNF::PP;
        $IsPurePerl = 1;
    }
}

# sub _parse_text is implemented in the XS code in Locale-Unicode-RBNF.xs, through the
# compiled engine returned by _xs_engine()
# Pure-Perl fallback: provided by Locale::Unicode::RBNF::PP, used when XS is not available
# (PERL_LOCALE_UNICODE_RBNF_PP=1, or when the shared object cannot be loaded).
if( !$IsPurePerl )
{
    no warnings 'once';
    *_parse_text = sub
    {
        my( $self, $text ) = @_;
        return( $self->_xs_engine->parse( $text, $self->{lenient} ) );
    };
}

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $opts = ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) ? shift( @_ ) : { @_ };
    my $self = bless(
    {
        capitalization              => 'none',
        capitalization_for_ui_list  => 0,
        capitalization_for_standalone => 0,
        case_fold_turkic            => 0,
        cldr                        => undef,
        default_infinity_rule       => undef,
        default_nan_rule            => undef,
        default_rule_set            => undef,
        fatal                       => ( $FATAL_EXCEPTIONS // 0 ),
        lenient                     => 0,
        lenient_parse_rules         => undef,
        locale                      => 'root',
        locale_object               => undef,
        localizations               => undef,
        max_fraction_digits         => 3,
        numbering_system            => undef,
        original_description        => undef,
        rounding_mode               => 'unnecessary',
        rule_sets                   => [],
        symbols                     => undef,
        unparseable                 => 0,
        valid_locale                => undef,
    }, ( ref( $this ) || $this ) );
    my $st;
    $self->{fatal} = ( $opts->{fatal} ? 1 : 0 ) if( exists( $opts->{fatal} ) );

    # The CLDR data directory: the option, or the environment, which is optional when the
    # rules are provided.
    my $dir = $opts->{cldr} // $ENV{LOCALE_UNICODE_RBNF_CLDR};
    if( defined( $dir ) )
    {
        $self->{cldr} = Locale::Unicode::RBNF::CLDR->new( $dir, \$st );
        return( $self->error( $st ) ) if( $st );
    }
    # The locale is parsed by Locale::Unicode. The CLDR file identifier, such as
    # fr_CH, is kept internally to find the data, and the canonical Locale::Unicode
    # object, such as fr-CH, is what locale() returns.
    # Ref:
    # - <https://www.unicode.org/reports/tr35/#BCP_47_Conformance>
    # - <https://www.unicode.org/reports/tr35/#Unicode_locale_identifier>
    # = <https://www.unicode.org/reports/tr35/#Unicode_Locale_Identifier_CLDR_to_BCP_47>
    my( $locale, $nu, $locale_object ) = Locale::Unicode::RBNF::CLDR->canonical_locale( $opts->{locale}, \$st );
    return( $self->error( $st ) ) if( $st );
    $self->{locale} = $locale;
    $self->{locale_object} = $locale_object;
    $self->{numbering_system} = $opts->{numbering_system} // $nu // ( $self->{cldr} ? $self->{cldr}->default_numbering_system( $locale ) : 'latn' );
    $self->{lenient} = $opts->{lenient} ? 1 : 0;
    $self->{max_fraction_digits} = $opts->{max_fraction_digits} if( defined( $opts->{max_fraction_digits} ) );
    if( defined( $opts->{rounding_mode} ) )
    {
        return( $self->error( "Unknown rounding mode '$opts->{rounding_mode}'" ) ) if( !$ROUNDING_MODES{ $opts->{rounding_mode} } );
        $self->{rounding_mode} = $opts->{rounding_mode};
    }

    my $rules = $opts->{rules};
    if( !defined( $rules ) )
    {
        my $type = $opts->{type} // 'spellout';
        my $grouping = $GROUPINGS{ $type } || return( $self->error( "U_ILLEGAL_ARGUMENT_ERROR: unknown rule type '$type'" ) );
        return( $self->error( 'U_MISSING_RESOURCE_ERROR: no CLDR directory was provided with the cldr option or the LOCALE_UNICODE_RBNF_CLDR environment variable' ) ) if( !$self->{cldr} );
        my $found;
        ( $rules, $found ) = $self->{cldr}->rbnf_rules( $locale, $grouping );
        return( $self->error( "U_MISSING_RESOURCE_ERROR: no $grouping found for locale '$locale'" ) ) if( !defined( $rules ) );
        $self->{valid_locale} = $found;
    }
    my $localizations;
    if( defined( $opts->{localizations} ) && length( $opts->{localizations} ) )
    {
        $localizations = $self->_parse_localizations( $opts->{localizations}, \$st );
        return( $self->error( $st ) ) if( $st );
    }
    $self->_init( $rules, $localizations, \$st );
    return( $self->error( $st ) ) if( $st );
    if( defined( $opts->{default_rule_set} ) )
    {
        $self->default_rule_set( $opts->{default_rule_set} ) || return( $self->error( $self->{error} ) );
    }
    if( defined( $opts->{capitalization} ) )
    {
        $self->capitalization( $opts->{capitalization} ) || return( $self->error( $self->{error} ) );
    }
    return( $self );
}

# Contextual capitalisation of the result, as UDISPCTX_TYPE_CAPITALIZATION does in ICU.
sub capitalization
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $value = shift( @_ );
        return( $self->error( "Unknown capitalization context '$value'" ) ) if( !$CAPITALIZATION{ $value } );
        $self->{capitalization} = $value;
        if( ( $value eq 'ui_list_or_menu' || $value eq 'standalone' ) && !$self->{capitalization_info_set} )
        {
            my $info = $self->{cldr} ? $self->{cldr}->context_transforms( $self->{locale} ) : [ 0, 0 ];
            ( $self->{capitalization_for_ui_list}, $self->{capitalization_for_standalone} ) = @$info;
            $self->{capitalization_info_set} = 1;
        }
        return( $self );
    }
    return( $self->{capitalization} );
}

sub default_rule_set
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $name = shift( @_ );
        my $st;
        if( !defined( $name ) || !length( $name ) )
        {
            if( $self->{localizations} )
            {
                $self->{default_rule_set} = $self->_find_rule_set( $self->{localizations}->{rule_sets}->[0], \$st );
            }
            else
            {
                $self->_init_default_rule_set;
            }
        }
        elsif( index( $name, '%%' ) == 0 )
        {
            return( $self->error( "U_ILLEGAL_ARGUMENT_ERROR: cannot use the internal rule set '$name'" ) );
        }
        else
        {
            my $rs = $self->_find_rule_set( $name, \$st );
            $self->{default_rule_set} = $rs if( $rs );
        }
        return( $self->error( $st ) ) if( $st );
        return( $self );
    }
    my $rs = $self->{default_rule_set};
    return( ( $rs && $rs->is_public ) ? $rs->get_name : undef );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        my $e = Locale::Unicode::RBNF::Exception->new({
            skip_frames => 1,
            message     => $msg,
        });
        $ERROR = $e;
        $self->{error} = $e if( ref( $self ) );
        if( $self->fatal )
        {
            die( $e );
        }
        else
        {
            warn( $msg ) if( warnings::enabled() );
            rreturn( Locale::Unicode::RBNF::NullObject->new ) if( want( 'OBJECT' ) );
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub fatal
{
    my $this = shift( @_ );
    if( @_ )
    {
        if( ref( $this ) )
        {
            return( $this->_set_get_prop( 'fatal', @_ ) );
        }
        else
        {
            # Called as a class method, this sets the default of new objects, and the
            # behaviour of the errors of class methods, such as those of the constructor.
            $FATAL_EXCEPTIONS = ( shift( @_ ) ? 1 : 0 );
        }
    }
    return( ref( $this ) ? $this->_set_get_prop( 'fatal' ) : $FATAL_EXCEPTIONS );
}

# Formats a number with the given public rule set, or the default one. Integers that fit
# in an int64 take the integer path, any other number the double path, exactly like the
# int64_t and double overloads of ICU's format().
sub format
{
    my( $self, $number, $rule_set_name ) = @_;
    return( $self->error( 'No number was provided to format.' ) ) if( !defined( $number ) );
    my $s = "$number";
    if( $s =~ /^\s*([+-]?\d+)\s*$/ )
    {
        my $digits = $1;
        if( _fits_int64( $digits ) )
        {
            return( $self->format_int( $digits + 0, $rule_set_name ) );
        }
        # Outside of the range this framework can handle, ICU uses a decimal format instead.
        $self->{error} = undef;
        return( $self->_default_number_format->format( $digits, 1 ) );
    }
    return( $self->error( "The value '$s' is not a number." ) ) if( !Scalar::Util::looks_like_number( $number ) );
    return( $self->format_double( $number + 0, $rule_set_name ) );
}

sub format_double
{
    my( $self, $number, $rule_set_name ) = @_;
    $self->{error} = undef;
    my $st;
    my $rs = $self->_rule_set_for_format( $rule_set_name, \$st );
    return( $self->error( $st ) ) if( $st );
    return( $self->error( 'No rule set available.' ) ) if( !$rs );
    if( $self->{rounding_mode} ne 'unnecessary' && !is_nan( $number ) && !is_infinite( $number ) )
    {
        my $d = dec_from_number( $number, 0 );
        dec_round( $d, -$self->{max_fraction_digits}, $self->{rounding_mode} );
        $number = dec_to_number( $d );
    }
    my $out = '';
    $rs->format_double( $number, \$out, 0, 0, \$st );
    return( $self->error( $st ) ) if( $st );
    return( $self->_adjust_for_capitalization( $out ) );
}

sub format_int
{
    my( $self, $number, $rule_set_name ) = @_;
    $self->{error} = undef;
    my $st;
    my $rs = $self->_rule_set_for_format( $rule_set_name, \$st );
    return( $self->error( $st ) ) if( $st );
    return( $self->error( 'No rule set available.' ) ) if( !$rs );
    # INT64_MIN cannot be negated, so ICU provides an accurate value with a decimal format.
    return( $self->_default_number_format->format( $number, 1 ) ) if( "$number" eq '-9223372036854775808' );
    my $out = '';
    $rs->format_int( $number, \$out, 0, 0, \$st );
    return( $self->error( $st ) ) if( $st );
    return( $self->_adjust_for_capitalization( $out ) );
}

sub lenient
{
    my $self = shift( @_ );
    $self->{lenient} = ( shift( @_ ) ? 1 : 0 ) if( @_ );
    return( $self->{lenient} );
}

sub locale { return( $_[0]->{locale_object} ); }

sub max_fraction_digits
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $n = int( shift( @_ ) // 0 );
        $self->{max_fraction_digits} = $n < 0 ? 0 : $n;
    }
    return( $self->{max_fraction_digits} );
}

sub numbering_system { return( $_[0]->{numbering_system} ); }

# RuleBasedNumberFormat::parse(): every public and parseable rule set is tried, and the
# one matching the most characters wins. In list context, returns ($value, $index,
# $error_index), with $error_index at -1 on success. In scalar context, returns the
# value, or undef if nothing could be parsed.
sub parse
{
    my( $self, $text, $start ) = @_;
    $self->{error} = undef;
    $start //= 0;
    $text //= '';
    if( !@{$self->{rule_sets}} || $self->{unparseable} )
    {
        $self->error( 'This formatter is not parseable.' );
        return( wantarray() ? ( undef, $start, $start ) : undef );
    }
    my $working = substr( $text, $start > length( $text ) ? length( $text ) : $start );
    # The parse itself is done in C, or in pure Perl by Locale::Unicode::RBNF::PP.
    my( $result, $high_index, $high_error ) = $self->_parse_text( $working );
    my $index = $start + $high_index;
    my $error = $high_index > 0 ? -1 : $start + ( $high_error > 0 ? $high_error : 0 );
    my $value = $high_index > 0 ? _normalise_result( $result ) : undef;
    return( $value, $index, $error ) if( wantarray() );
    return( $value );
}

sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my( $err, $class, $code );
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error();
        # or an hash with a single property: {class => 'Some::ExceptionClass'}
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    # We set $class only if the hash provided is a one-element hash and not an
    # error-defining hash
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );

    # called with no argument, most likely from the same class to pass on an error set up
    # earlier by another method; or with an hash containing just one argument
    # class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        # $error is a previous erro robject
        my $error = ref( $self ) ? $self->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $err = ( defined( $class ) ? bless( $err => $class ) : $err );
        ${ $pack . '::ERROR' } = $err;
        # pass_error() can also be called as a class method.
        $self->{error} = $err if( ref( $self ) );
        $err->code( $code ) if( defined( $code ) && $err->can( 'code' ) );
        if( $self->fatal )
        {
            die( $err );
        }
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }

    if( want( 'OBJECT' ) )
    {
        rreturn( Locale::Unicode::RBNF::NullObject->new );
    }
    return;
}

sub rounding_mode
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $mode = shift( @_ );
        return( $self->error( "Unknown rounding mode '$mode'" ) ) if( !$ROUNDING_MODES{ $mode } );
        $self->{rounding_mode} = $mode;
    }
    return( $self->{rounding_mode} );
}

# The display name of a rule set in a given locale, when localisations were provided.
sub rule_set_display_name
{
    my( $self, $rule_set, $locale ) = @_;
    my $loc = $self->{localizations} || return;
    my $index = $rule_set;
    if( $rule_set !~ /^\d+$/ )
    {
        ( $index ) = grep( $loc->{rule_sets}->[ $_ ] eq $rule_set, 0..$#{$loc->{rule_sets}} );
        return if( !defined( $index ) );
    }
    return if( $index < 0 || $index > $#{$loc->{rule_sets}} );
    # Trim trailing portions of the locale name, skipping over omitted sections.
    my $name = defined( $locale ) ? $locale : $self->{locale};
    $name =~ tr/-/_/;
    while(1)
    {
        my( $entry ) = grep( $_->[0] eq $name, @{$loc->{locales}} );
        return( $entry->[ $index + 1 ] ) if( $entry );
        last if( !length( $name ) );
        $name =~ s/_*[^_]*$//;
    }
    return( $loc->{rule_sets}->[ $index ] );
}

sub rule_set_display_name_locales
{
    my $self = shift( @_ );
    return( [] ) if( !$self->{localizations} );
    return( [ map( $_->[0], @{$self->{localizations}->{locales}} ) ] );
}

# The names of the public rule sets, or of the rule sets listed in the localisations.
sub rule_set_names
{
    my $self = shift( @_ );
    return( [ @{$self->{localizations}->{rule_sets}} ] ) if( $self->{localizations} );
    return( [ map( $_->get_name, grep( $_->is_public, @{$self->{rule_sets}} ) ) ] );
}

# Splits a rule description into its rule sets and rules, without compiling them,
# exactly as RuleBasedNumberFormat::init(), NFRuleSet and NFRuleSet::parseRules()
# divide it. This is meant for storing the rules, for instance in a database. Can be
# called as a class method.
sub rule_sets_from_description
{
    my( $this, $description ) = @_;
    my $st;
    my( $lenient_rules, $descs ) = _split_description( $description, \$st );
    return( $this->error( $st ) ) if( $st );
    my @rule_sets;
    for( my $i = 0; $i < scalar( @$descs ); $i++ )
    {
        # The rule set constructor extracts the name, and removes it from the description.
        my $rs = Locale::Unicode::RBNF::RuleSet->new( undef, $descs, $i, \$st );
        return( $this->error( $st ) ) if( $st );
        my $body = $descs->[$i];
        my @rules;
        # NFRuleSet::parseRules(): the rules are separated by semicolons, with no escape.
        my $old_p = 0;
        my $len = length( $body );
        while( $old_p < $len )
        {
            my $p = index( $body, ';', $old_p );
            $p = $len if( $p == -1 );
            my $rule = substr( $body, $old_p, $p - $old_p );
            # NFRule::parseRuleDescriptor(): the descriptor is optional, and ends at the
            # first colon; whitespace after the colon is not part of the rule text.
            my $c = index( $rule, ':' );
            if( $c == -1 )
            {
                push( @rules, { descriptor => undef, text => $rule } );
            }
            else
            {
                my $q = $c + 1;
                ++$q while( $q < length( $rule ) && is_pattern_ws( substr( $rule, $q, 1 ) ) );
                push( @rules, { descriptor => substr( $rule, 0, $c ), text => substr( $rule, $q ) } );
            }
            $old_p = $p + 1;
        }
        my $name = $rs->get_name;
        ( my $type = $name ) =~ s/^%%?//;
        push( @rule_sets,
        {
            name        => $name,
            type        => $type,
            private     => ( $rs->is_public ? 0 : 1 ),
            parseable   => ( $rs->is_parseable ? 1 : 0 ),
            rules       => \@rules,
        });
    }
    return( { rule_sets => \@rule_sets, lenient_parse => $lenient_rules } );
}

# RuleBasedNumberFormat::getRules(): a textual description equivalent to the rules in use.
sub rules
{
    my $self = shift( @_ );
    return( join( '', map( $_->to_string, @{$self->{rule_sets}} ) ) );
}

# The decimal format symbols. Setting them reapplies them to every rule, as
# adoptDecimalFormatSymbols() does.
sub symbols
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $new = shift( @_ );
        return( $self->error( 'The symbols must be provided as a hash reference.' ) ) if( ref( $new ) ne 'HASH' );
        my $sym = { %{$self->{symbols}}, %$new };
        $self->{symbols} = $sym;
        my $st;
        $self->_init_default_special_rules( \$st );
        $_->set_decimal_format_symbols( $sym, \$st ) for( @{$self->{rule_sets}} );
        $self->{default_number_format} = undef;
        # The C engine holds copies of the symbols and of the fraction rules chosen.
        $self->{xs_engine} = undef;
        return( $self->error( $st ) ) if( $st );
        return( $self );
    }
    return( { %{$self->{symbols}} } );
}

# The CLDR file identifier is used, with its rules, such as fr or root, to produce a
# Locale::Unicode object.
sub valid_locale
{
    my $self = shift( @_ );
    return if( !defined( $self->{valid_locale} ) );
    return( $self->{valid_locale_object} ) if( $self->{valid_locale_object} );
    my $id = $self->{valid_locale};
    my $obj = Locale::Unicode->new( $id ) || return( $self->pass_error( Locale::Unicode->error ) );
    # The canonical form of root is und, so root is kept as it is.
    $obj = $obj->canonical if( $id ne 'root' );
    return( $self->{valid_locale_object} = $obj );
}

# Titlecases the first character when the capitalisation context calls for it.
sub _adjust_for_capitalization
{
    my( $self, $out ) = @_;
    my $ctx = $self->{capitalization};
    return( $out ) if( $ctx eq 'none' || !length( $out ) );
    return( $out ) if( substr( $out, 0, 1 ) !~ /^\p{Ll}$/ );
    if( $ctx eq 'beginning_of_sentence' ||
        ( $ctx eq 'ui_list_or_menu' && $self->{capitalization_for_ui_list} ) ||
        ( $ctx eq 'standalone' && $self->{capitalization_for_standalone} ) )
    {
        $out = ucfirst( $out );
    }
    return( $out );
}

sub _create_plural_format
{
    my( $self, $type, $pattern, $st ) = @_;
    my $rules = $self->{plural_rules}->{ $type } //= Locale::Unicode::RBNF::PluralRules->new( ( $self->{cldr} ? $self->{cldr}->plural_rules( $self->{locale}, $type ) : [] ), $st );
    return if( $$st );
    return( Locale::Unicode::RBNF::PluralFormat->new( $rules, $pattern, $self->_default_number_format, $st ) );
}

# The decimal format of the locale, used where ICU creates a NumberFormat instance.
sub _default_number_format
{
    my $self = shift( @_ );
    return( $self->{default_number_format} ) if( $self->{default_number_format} );
    my $pattern = $self->{cldr} ? $self->{cldr}->decimal_pattern( $self->{locale}, $self->{numbering_system} ) : '#,##0.###';
    my $st;
    my $fmt = Locale::Unicode::RBNF::DecimalFormat->new( $pattern, $self->{symbols}, \$st );
    $fmt = Locale::Unicode::RBNF::DecimalFormat->new( '#,##0.###', $self->{symbols}, \$st ) if( $st );
    return( $self->{default_number_format} = $fmt );
}

sub _default_rule_set_object { return( $_[0]->{default_rule_set} ); }

sub _find_rule_set
{
    my( $self, $name, $st ) = @_;
    foreach my $rs ( @{$self->{rule_sets}} )
    {
        return( $rs ) if( $rs->is_named( $name ) );
    }
    $$st = "U_ILLEGAL_ARGUMENT_ERROR: no rule set named '$name'";
    return;
}

sub _fits_int64
{
    my $digits = shift( @_ );
    my $neg = $digits =~ s/^([+-])// ? ( $1 eq '-' ) : 0;
    $digits =~ s/^0+//;
    return(1) if( length( $digits ) < 19 );
    return(0) if( length( $digits ) > 19 );
    return( ( $digits cmp ( $neg ? '9223372036854775808' : '9223372036854775807' ) ) <= 0 ? 1 : 0 );
}

# RuleBasedNumberFormat::init()
sub _init
{
    my( $self, $rules, $localizations, $st ) = @_;
    # Turkic case folding for Turkish and Azerbaijani
    my( $lang ) = split( /_/, $self->{locale} );
    $self->{case_fold_turkic} = ( $lang eq 'tr' || $lang eq 'az' ) ? 1 : 0;
    $self->{symbols} = $self->{cldr} ? $self->{cldr}->symbols( $self->{locale}, $self->{numbering_system} ) : { %DEFAULT_SYMBOLS, digits => [0..9] };
    $self->_init_default_special_rules( $st );
    return if( $$st );
    $self->{localizations} = $localizations;

    my( $lenient_rules, $descs ) = _split_description( $rules, $st );
    return if( $$st );
    $self->{lenient_parse_rules} = $lenient_rules;
    my @descriptions = @$descs;
    my $rule_sets = $self->{rule_sets} = [];
    for( my $i = 0; $i < scalar( @descriptions ); $i++ )
    {
        push( @$rule_sets, Locale::Unicode::RBNF::RuleSet->new( $self, \@descriptions, $i, $st ) );
        return if( $$st );
    }

    # Initialising a fraction rule set requires the default rule set to be known; for that
    # purpose it is always the last public rule set, whatever the localisations say.
    $self->_init_default_rule_set;
    for( my $i = 0; $i < scalar( @descriptions ); $i++ )
    {
        $rule_sets->[$i]->parse_rules( $descriptions[$i], $st );
        return if( $$st );
    }

    # The localisations may now adjust the default rule set; every name they list must exist.
    if( $localizations )
    {
        for( my $i = 0; $i < scalar( @{$localizations->{rule_sets}} ); $i++ )
        {
            my $rs = $self->_find_rule_set( $localizations->{rule_sets}->[$i], $st );
            return if( $$st );
            $self->{default_rule_set} = $rs if( $i == 0 );
        }
    }
    $self->{original_description} = $rules;
    return;
}

# RuleBasedNumberFormat::initDefaultRuleSet()
sub _init_default_rule_set
{
    my $self = shift( @_ );
    $self->{default_rule_set} = undef;
    my $rule_sets = $self->{rule_sets};
    return if( !@$rule_sets );
    foreach my $rs ( @$rule_sets )
    {
        if( $rs->is_named( '%spellout-numbering' ) || $rs->is_named( '%digits-ordinal' ) || $rs->is_named( '%duration' ) )
        {
            $self->{default_rule_set} = $rs;
            return;
        }
    }
    # Otherwise the last public rule set
    for( my $i = $#$rule_sets; $i >= 0; $i-- )
    {
        if( $rule_sets->[$i]->is_public )
        {
            $self->{default_rule_set} = $rule_sets->[$i];
            return;
        }
    }
    $self->{default_rule_set} = $rule_sets->[-1];
    return;
}

sub _init_default_special_rules
{
    my( $self, $st ) = @_;
    $self->{default_infinity_rule} = Locale::Unicode::RBNF::Rule->new( $self, 'Inf: ' . $self->{symbols}->{infinity}, $st );
    $self->{default_nan_rule} = Locale::Unicode::RBNF::Rule->new( $self, 'NaN: ' . $self->{symbols}->{nan}, $st );
    return;
}

# Parse results are doubles in ICU; integral values are returned as integers.
sub _normalise_result
{
    my $v = shift( @_ );
    return( $v ) if( is_nan( $v ) || is_infinite( $v ) );
    # The C engine computes with doubles, whereas the pure-Perl engine uses the
    # precision of the perl numbers (NVs). A non-integral value is therefore rounded to
    # the nearest double. Integral values are kept as they are, since beyond 2^53 the
    # pure-Perl engine may hold them as integers.
    $v = unpack( 'd', pack( 'd', $v ) ) if( $NV_IS_WIDE && $v != int( $v ) );
    return( int( $v ) ) if( $v == int( $v ) && abs( $v ) < 9007199254740992 );
    return( $v );
}

# Port of LocDataParser: <<%rs1, %rs2>, <locale, name1, name2>, ...>
sub _parse_localizations
{
    my( $self, $data, $st ) = @_;
    my $p = 0;
    my $len = length( $data );
    my $skip_ws = sub { $p++ while( $p < $len && is_pattern_ws( substr( $data, $p, 1 ) ) ); };
    my $fail = sub
    {
        $$st = 'U_PARSE_ERROR: ' . $_[0] . ' at offset ' . $p . ' of the localization data';
        return;
    };
    my $next_string = sub
    {
        $skip_ws->();
        return if( $p >= $len );
        my $c = substr( $data, $p, 1 );
        my $quote = ( $c eq '"' || $c eq "'" ) ? $c : undef;
        $p++ if( $quote );
        my $start = $p;
        if( $quote )
        {
            $p++ while( $p < $len && substr( $data, $p, 1 ) ne $quote );
        }
        else
        {
            $p++ while( $p < $len && substr( $data, $p, 1 ) !~ /^[,<>'"]$/ && !is_pattern_ws( substr( $data, $p, 1 ) ) );
        }
        return( $fail->( 'Unexpected end of data' ) ) if( $p >= $len );
        my $str = substr( $data, $start, $p - $start );
        if( $quote )
        {
            return( $fail->( 'Empty string' ) ) if( !length( $str ) );
            $p++;
        }
        elsif( substr( $data, $p, 1 ) =~ /^[<'"]$/ )
        {
            return( $fail->( 'Unexpected character in string' ) );
        }
        return( length( $str ) ? $str : undef );
    };
    my $required;
    my $next_array = sub
    {
        $skip_ws->();
        return( $fail->( 'Missing open angle' ) ) if( substr( $data, $p, 1 ) ne '<' );
        $p++;
        my @array;
        while(1)
        {
            my $elem = $next_string->();
            return if( $$st );
            $skip_ws->();
            my $comma = substr( $data, $p, 1 ) eq ',';
            if( defined( $elem ) )
            {
                push( @array, $elem );
                if( $comma )
                {
                    $p++;
                    next;
                }
            }
            elsif( $comma )
            {
                return( $fail->( 'Unexpected comma' ) );
            }
            last;
        }
        $skip_ws->();
        return( $fail->( substr( $data, $p, 1 ) eq '<' ? 'Missing close angle bracket in inner array' : 'Missing comma in inner array' ) ) if( substr( $data, $p, 1 ) ne '>' );
        $p++;
        # The first array lists the rule sets; each following one holds a locale and
        # then one display name per rule set, hence one more element.
        if( !defined( $required ) ) { $required = scalar( @array ) + 1; }
        elsif( scalar( @array ) != $required ) { return( $fail->( 'Array not of required length' ) ); }
        return( \@array );
    };
    $skip_ws->();
    return( $fail->( 'Missing open angle' ) ) if( substr( $data, $p, 1 ) ne '<' );
    $p++;
    my @arrays;
    while(1)
    {
        my $elem = $next_array->();
        return if( $$st );
        $skip_ws->();
        my $comma = substr( $data, $p, 1 ) eq ',';
        if( $elem )
        {
            push( @arrays, $elem );
            if( $comma )
            {
                $p++;
                next;
            }
        }
        elsif( $comma )
        {
            return( $fail->( 'Unexpected character' ) );
        }
        last;
    }
    $skip_ws->();
    return( $fail->( substr( $data, $p, 1 ) eq '<' ? 'Missing comma in outer array' : 'Missing close angle bracket in outer array' ) ) if( substr( $data, $p, 1 ) ne '>' );
    $p++;
    $skip_ws->();
    return( $fail->( 'Extra text after close of localization data' ) ) if( $p != $len );
    my $names = shift( @arrays );
    return( { rule_sets => $names, locales => \@arrays } );
}

sub _rule_set_for_format
{
    my( $self, $name, $st ) = @_;
    return( $self->{default_rule_set} ) if( !defined( $name ) || !length( $name ) );
    if( index( $name, '%%' ) == 0 )
    {
        $$st = "U_ILLEGAL_ARGUMENT_ERROR: cannot use the internal rule set '$name'";
        return;
    }
    return( $self->_find_rule_set( $name, $st ) );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

# The first steps of RuleBasedNumberFormat::init(): whitespace stripping, extraction of
# the %%lenient-parse rules, and division into rule set descriptions.
# Returns ($lenient_rules, \@descriptions ). It is shared by _init() and
# rule_sets_from_description(), so that both see the rules exactly the same way.
sub _split_description
{
    my( $rules, $st ) = @_;
    my $description = $rules // '';
    if( !length( $description ) )
    {
        $$st = 'U_ILLEGAL_ARGUMENT_ERROR: empty rule description';
        return;
    }
    # Stripping the whitespace following each semicolon lets us find rule set boundaries
    # by searching for ";%".
    $description = _strip_whitespace( $description );

    # Lenient-parse rules are pulled out of the description before it is parsed, unless
    # the name occurs in the middle of a rule, where it would be rule text.
    my $lenient_rules;
    my $lp_name = '%%lenient-parse:';
    my $lp = index( $description, $lp_name );
    if( $lp != -1 && ( $lp == 0 || substr( $description, $lp - 1, 1 ) eq ';' ) )
    {
        my $lp_end = index( $description, ';%', $lp );
        $lp_end = length( $description ) - 1 if( $lp_end == -1 );
        my $lp_start = $lp + length( $lp_name );
        ++$lp_start while( is_pattern_ws( substr( $description, $lp_start, 1 ) ) );
        $lenient_rules = substr( $description, $lp_start, $lp_end - $lp_start );
        substr( $description, $lp, $lp_end + 1 - $lp, '' );
    }

    # Divide the description into rule set descriptions (";%" marks the end of one rule
    # set and the beginning of the next).
    my @descriptions;
    my $start = 0;
    for( my $p = index( $description, ';%' ); $p != -1; $p = index( $description, ';%', $start ) )
    {
        push( @descriptions, substr( $description, $start, $p + 1 - $start ) );
        $start = $p + 1;
    }
    push( @descriptions, substr( $description, $start ) );
    return( $lenient_rules, \@descriptions );
}

# RuleBasedNumberFormat::stripWhitespace(): removes the whitespace, and empty rules,
# following each semicolon.
sub _strip_whitespace
{
    my $description = shift( @_ );
    my $len = length( $description );
    my $result = '';
    my $start = 0;
    while( $start < $len )
    {
        while( $start < $len )
        {
            my $c = substr( $description, $start, 1 );
            last if( !is_pattern_ws( $c ) && $c ne ';' );
            ++$start;
        }
        my $p = index( $description, ';', $start );
        if( $p == -1 )
        {
            $result .= substr( $description, $start );
            last;
        }
        $result .= substr( $description, $start, $p + 1 - $start );
        $start = $p + 1;
    }
    return( $result );
}

# Flattens the rule sets, rules, substitutions, plural patterns and decimal formats into
# arrays of hashes, from which Locale::Unicode::RBNF::XS builds its C structures.
sub _xs_engine
{
    my $self = shift( @_ );
    return( $self->{xs_engine} ) if( $self->{xs_engine} );
    my( %rs_idx, %rule_idx, %sub_idx, %nf_idx, %pl_idx );
    my( @rule_sets, @rules, @subs, @plurals, @number_formats );
    my $addr = \&Scalar::Util::refaddr;
    for( my $i = 0; $i < scalar( @{$self->{rule_sets}} ); $i++ )
    {
        $rs_idx{ $addr->( $self->{rule_sets}->[$i] ) } = $i;
    }
    my $nf_index = sub
    {
        my $nf = shift( @_ );
        return( -1 ) if( !$nf );
        my $a = $addr->( $nf );
        return( $nf_idx{ $a } ) if( exists( $nf_idx{ $a } ) );
        my $sym = $nf->{symbols};
        my $group = $sym->{group} // '';
        push( @number_formats,
        {
            pos_prefix      => $nf->{positive}->{prefix},
            pos_suffix      => $nf->{positive}->{suffix},
            has_negative    => ( $nf->{negative} ? 1 : 0 ),
            neg_prefix      => ( $nf->{negative} ? $nf->{negative}->{prefix} : '' ),
            neg_suffix      => ( $nf->{negative} ? $nf->{negative}->{suffix} : '' ),
            minus           => $sym->{minus} // '',
            decimal         => $sym->{decimal} // '',
            group           => $group,
            infinity        => $sym->{infinity} // '',
            grouping        => ( $nf->{grouping} ? 1 : 0 ),
            group_is_space  => ( ( length( $group ) && $group =~ /^\p{Zs}$/ ) ? 1 : 0 ),
            multiplier_exp  => $nf->{multiplier_exp} // 0,
        });
        return( $nf_idx{ $a } = $#number_formats );
    };
    # Rules first, so that substitutions can refer to them by index.
    foreach my $rs ( @{$self->{rule_sets}} )
    {
        foreach my $rule ( @{$rs->{rules}}, grep( defined( $_ ), @{$rs->{non_numerical_rules}} ) )
        {
            my $a = $addr->( $rule );
            next if( exists( $rule_idx{ $a } ) );
            push( @rules, $rule );
            $rule_idx{ $a } = $#rules;
        }
    }
    my %types = (
        'Locale::Unicode::RBNF::Substitution::SameValue'        => 0,
        'Locale::Unicode::RBNF::Substitution::Multiplier'       => 1,
        'Locale::Unicode::RBNF::Substitution::Modulus'          => 2,
        'Locale::Unicode::RBNF::Substitution::IntegralPart'     => 3,
        'Locale::Unicode::RBNF::Substitution::FractionalPart'   => 4,
        'Locale::Unicode::RBNF::Substitution::AbsoluteValue'    => 5,
        'Locale::Unicode::RBNF::Substitution::Numerator'        => 6,
    );
    my $sub_index = sub
    {
        my $sub = shift( @_ );
        return( -1 ) if( !$sub );
        my $a = $addr->( $sub );
        return( $sub_idx{ $a } ) if( exists( $sub_idx{ $a } ) );
        my $type = $types{ ref( $sub ) };
        die( "Unknown substitution class " . ref( $sub ) ) if( !defined( $type ) );
        push( @subs,
        {
            type        => $type,
            pos         => $sub->{pos},
            rs          => ( $sub->{rule_set} ? ( $rs_idx{ $addr->( $sub->{rule_set} ) } // -1 ) : -1 ),
            nf          => $nf_index->( $sub->{number_format} ),
            divisor     => $sub->{divisor} // 1,
            rule_to_use => ( $sub->{rule_to_use} ? ( $rule_idx{ $addr->( $sub->{rule_to_use} ) } // -1 ) : -1 ),
            by_digits   => ( $sub->{by_digits} ? 1 : 0 ),
            with_zeros  => ( $sub->{with_zeros} ? 1 : 0 ),
            denominator => $sub->{denominator} // 0,
        });
        return( $sub_idx{ $a } = $#subs );
    };
    my @rule_specs;
    foreach my $rule ( @rules )
    {
        my $spec = { base => $rule->{base_value}, text => $rule->{rule_text}, sub1 => $sub_index->( $rule->{sub1} ), sub2 => $sub_index->( $rule->{sub2} ), plural => -1 };
        if( my $pf = $rule->{plural_format} )
        {
            my $text = $rule->{rule_text};
            $spec->{pl_start} = index( $text, '$(' );
            $spec->{pl_suffix} = index( $text, ')$', $spec->{pl_start} ) + 2;
            # parse_type() only considers the keyword variants.
            push( @plurals, [ map( $_->{raw}, grep( !defined( $_->{explicit} ), @{$pf->{variants}} ) ) ] );
            $spec->{plural} = $#plurals;
        }
        push( @rule_specs, $spec );
    }
    foreach my $rs ( @{$self->{rule_sets}} )
    {
        push( @rule_sets,
        {
            is_fraction     => ( $rs->{is_fraction} ? 1 : 0 ),
            is_public       => ( $rs->{is_public} ? 1 : 0 ),
            is_parseable    => ( $rs->{is_parseable} ? 1 : 0 ),
            rules           => [ map( $rule_idx{ $addr->( $_ ) }, @{$rs->{rules}} ) ],
            nnr             => [ map( ( defined( $_ ) ? $rule_idx{ $addr->( $_ ) } : undef ), @{$rs->{non_numerical_rules}} ) ],
        });
    }
    my $default_nf = $nf_index->( $self->_default_number_format );
    $self->{xs_engine} = Locale::Unicode::RBNF::XS->new(
    {
        rule_sets       => \@rule_sets,
        rules           => \@rule_specs,
        subs            => \@subs,
        plurals         => \@plurals,
        number_formats  => \@number_formats,
        default_nf      => $default_nf,
        turkic          => ( $self->{case_fold_turkic} ? 1 : 0 ),
        cb_fold         => \&Locale::Unicode::RBNF::Rule::_fold_case,
        cb_sep          => \&Locale::Unicode::RBNF::Rule::_is_lenient_separator,
        cb_boundary     => \&Locale::Unicode::RBNF::Rule::_has_nfc_boundary_before,
        cb_nfc          => \&Unicode::Normalize::NFC,
        cb_digit        => \&Locale::Unicode::RBNF::DecimalFormat::_digit_value,
    });
    return( $self->{xs_engine} );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, %hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# CBOR will call the THAW method with the stored classname as first argument, the
# constant string CBOR as second argument, and all values returned by FREEZE as remaining
# arguments.
# Storable calls it with a blessed object it created followed with $cloning and any
# other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a
    # new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my $hash = { %$self };
    return( $hash );
}

# NOTE: Locale::Unicode::RBNF::Exception class
package Locale::Unicode::RBNF::Exception;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use overload (
        '""'    => 'as_string',
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};
use strict;
use warnings;
use overloading;

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    my @info = caller;
    @$self{ qw( package file line ) } = @info[0..2];
    my $args = {};
    if( scalar( @_ ) == 1 &&
        ( ref( $_[0] ) || '' ) eq 'HASH' )
    {
        $args = shift( @_ );
        if( $args->{skip_frames} )
        {
            @info = caller( int( $args->{skip_frames} ) );
            @$self{ qw( package file line ) } = @info[0..2];
        }
        $args->{message} ||= '';
        foreach my $k ( qw( package file line message code type retry_after ) )
        {
            $self->{ $k } = $args->{ $k } if( CORE::exists( $args->{ $k } ) );
        }
    }
    elsif( scalar( @_ ) == 1 &&
           defined( $_[0] ) &&
           ref( $_[0] ) &&
           $_[0]->isa( 'Locale::Unicode::RBNF::Exception' ) )
    {
        my $o = shift( @_ );
        $self->{message}     = $o->message;
        $self->{code}        = $o->code;
        $self->{type}        = $o->type;
        $self->{retry_after} = $o->retry_after;
    }
    else
    {
        $self->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    }
    return( $self );
}

# This is important as stringification is called by die, so as per the manual page, we
# need to end with new line and will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
    my $str = $self->message;
    $str = "$str";
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s", ( $self->{package} // 'undef' ), ( $self->{line} // 'undef' ), ( $self->{file} // 'undef' ) );
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub clone
{
    my $self = shift( @_ );
    # Safeguard
    die( "$self->clone() cannot be called as a class function" ) unless( ref( $self ) );
    my $new = bless( { %$self } => ref( $self ) );
    CORE::delete( $new->{_cache_value} );
    return( $new );
}

sub code { return( shift->reset(@_)->_set_get_prop( 'code', @_ ) ); }

sub file { return( shift->reset(@_)->_set_get_prop( 'file', @_ ) ); }

sub line { return( shift->reset(@_)->_set_get_prop( 'line', @_ ) ); }

sub message { return( shift->reset(@_)->_set_get_prop( 'message', @_ ) ); }

sub package { return( shift->reset(@_)->_set_get_prop( 'package', @_ ) ); }

# From perlfunc docmentation on "die":
# "If LIST was empty or made an empty string, and $@ contains an
# object reference that has a "PROPAGATE" method, that method will
# be called with additional file and line number parameters. The
# return value replaces the value in $@; i.e., as if "$@ = eval {
# $@->PROPAGATE(__FILE__, __LINE__) };" were called."
sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    if( defined( $file ) && defined( $line ) )
    {
        my $clone = $self->clone;
        $clone->file( $file );
        $clone->line( $line );
        return( $clone );
    }
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub rethrow 
{
    my $self = shift( @_ );
    return if( !ref( $self ) );
    die( $self );
}

sub retry_after { return( shift->_set_get_prop( 'retry_after', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $e;
    if( @_ )
    {
        my $msg  = shift( @_ );
        $e = $self->new({
            skip_frames => 1,
            message => $msg,
        });
    }
    else
    {
        $e = $self;
    }
    die( $e );
}

sub type { return( shift->reset(@_)->_set_get_prop( 'type', @_ ) ); }

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# CBOR will call the THAW method with the stored classname as first argument, the
# constant string CBOR as second argument, and all values returned by FREEZE as remaining
# arguments.
# Storable calls it with a blessed object it created followed with $cloning and any other
# arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a
    # new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_string ); }

{
    # NOTE: Locale::Unicode::RBNF::NullObject class
    package
        Locale::Unicode::RBNF::NullObject;
    BEGIN
    {
        use strict;
        use warnings;
        use overload (
            '""'    => sub{ '' },
            fallback => 1,
        );
        use Wanted;
    };
    use strict;
    use warnings;

    sub new
    {
        my $this = shift( @_ );
        my $ref = @_ ? { @_ } : {};
        return( bless( $ref => ( ref( $this ) || $this ) ) );
    }

    sub AUTOLOAD
    {
        my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
        my $self = shift( @_ );
        if( want( 'OBJECT' ) )
        {
            rreturn( $self );
        }
        # Otherwise, we return undef; Empty return returns undef in scalar context and
        # empty list in list context
        return;
    };
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF - Unicode CLDR Rule-Based Number Format, ported from ICU4C

=head1 SYNOPSIS

    use Locale::Unicode::RBNF;
    my $fmt = Locale::Unicode::RBNF->new(
        locale  => 'fr',
        type    => 'spellout',
        cldr    => '/path/to/cldr/common',
    ) || die( Locale::Unicode::RBNF->error );
    say $fmt->format( 1980 );
    # mille neuf cent quatre-vingts
    say $fmt->format( 71, '%spellout-cardinal-feminine' );
    # soixante-et-onze
    say $fmt->format( 3.14 );
    # trois virgule un quatre
    my $n = $fmt->parse( 'deux mille vingt-six' );
    # 2026

    # Japanese, for instance for amounts written in kanji
    my $ja = Locale::Unicode::RBNF->new( locale => 'ja', cldr => '/path/to/cldr/common' );
    say $ja->format( 3000000, '%spellout-cardinal-financial' );

    # Custom rules, as with ICU's RuleBasedNumberFormat( description, locale )
    my $custom = Locale::Unicode::RBNF->new(
        locale  => 'en',
        rules   => "%main: 0: zero; 1: one; 2: two; 3: =#,##0=;",
    );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This is a port from ICU4C C<RuleBasedNumberFormat> (ICU 79.1), that is F<rbnf.cpp>, F<nfrs.cpp>, F<nfrule.cpp> and F<nfsubs.cpp>, using the RBNF data of the Unicode CLDR.

It formats numbers using rules, typically to spell them out ("one thousand two hundred"), to produce ordinals ("1st", "1er"), or to write them in numbering systems such as Roman numerals or Hebrew numbers, and it parses such text back into numbers, in strict or lenient mode.

The rules, decimal format symbols, numbering system digits and plural rules are read from a CLDR F<common> directory; see L<Locale::Unicode::RBNF::CLDR>.

=head1 CONSTRUCTOR

=head2 new

Takes a hash or an hash reference of options, and returns a new object, or, upon error, sets an error that can be retrieved with L</error> and returns C<undef> in scalar context, or an empty list in list context.

=over 4

=item * C<capitalization>

The capitalisation context. See L</capitalization>.

=item * C<cldr>

The path to the CLDR F<common> directory. It defaults to the environment variable C<LOCALE_UNICODE_RBNF_CLDR>. It is required, unless C<rules> are provided, in which case root symbols and plural rules are used without it.

=item * C<default_rule_set>

The name of the public rule set to use by default.

=item * C<fatal>

Boolean. If true, errors are fatal, which means that the L<Locale::Unicode::RBNF::Exception> object is passed to C<die> instead of being returned.
The default follows the value set with C<$Locale::Unicode::RBNF::FATAL_EXCEPTIONS>, which is false by default.
See L</ERROR HANDLING>.

=item * C<lenient>

Boolean. Enables lenient parsing. Default false.

=item * C<locale>

A locale, can be a BCP 47 identifier such as C<fr>, C<fr-CH> or C<zh-Hant-TW>, but also a CLDR identifier such as C<fr_CH>, or also a L<Locale::Unicode> object.

It is parsed and canonicalised with L<Locale::Unicode>, thus C<fr-ch> becomes C<fr-CH>.
A C<-u-nu-> extension selects the numbering system, as in C<ja-JP-u-nu-hanidec>.
The default is C<root>.

If L<Locale::Unicode> cannot parse a given locale, or if that locale does not have a language subtag, it will return an error.

The ICU keyword syntax, such as C<fr_CH@numbers=latn>, is not supported. You must use the BCP 47 extension instead.

=item * C<localizations>

Localised display names of the rule sets, in the ICU syntax, such as C<< <<%main, %other>, <en, Main, Other>, <fr, Principal, Autre>> >>. When provided, the first rule set listed becomes the default one.

=item * C<max_fraction_digits>

The maximum number of fraction digits used when rounding, if a rounding mode other than C<unnecessary> is set. Default 3.

=item * C<numbering_system>

Overrides the numbering system whose symbols and digits are used by decimal patterns in the rules. Default: the locale's default numbering system.

=item * C<rounding_mode>

One of C<ceiling>, C<floor>, C<down>, C<up>, C<half_even>, C<half_down>, C<half_up>, C<half_odd>, C<half_ceiling>, C<half_floor> or C<unnecessary> (the default, under which numbers are not rounded before formatting).

=item * C<rules>

A rule description in the ICU syntax, instead of the CLDR rules.

=item * C<type>

The CLDR rule set grouping: C<spellout> (the default), C<ordinal>, C<numbering_system> or C<duration>.

=back

=head1 METHODS

=head2 capitalization

Sets or gets the capitalisation context: C<none> (default), C<middle_of_sentence>, C<beginning_of_sentence>, C<ui_list_or_menu> or C<standalone>. For the last two, the first word is titlecased only if the CLDR C<number-spellout> context transforms of the locale say so.

=head2 default_rule_set

Sets or gets the name of the default rule set. An empty string restores the original default.

=head2 error

    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr', type => 'nonsense' ) ||
        die( Locale::Unicode::RBNF->error );
    say $fmt->error->message;

In accessor mode, this returns the last error, as a L<Locale::Unicode::RBNF::Exception> object, or possibly C<undef> if there were none.

When called as a class method, this returns the last error of any object.

When called mutator mode the arguments provided are concatenated, and a new error is set.
It then returns C<undef> in scalar context, or an empty list in list context. In object context, such as C<< $fmt->format( 'abc' )->length >>, it returns a L<Locale::Unicode::RBNF::NullObject> instead, so that the chain of method calls does not die.

If L</fatal> is true, it dies with the exception instead.

See L</ERROR HANDLING>.

=head2 fatal

Sets or gets the boolean value for this option.
If true, the exceptions will be fatal. By default, it follows the value set with C<$Locale::Unicode::RBNF::FATAL_EXCEPTIONS>, which itself is false by default.

See L</ERROR HANDLING>.

=head2 format

    my $text = $fmt->format( $number );
    my $text = $fmt->format( $number, '%spellout-ordinal' );

Formats a number, using the given public rule set or the default one. Integers within the C<int64> range use ICU's integer code path, other numbers its double code path. Larger integers are formatted with the locale's decimal pattern, as ICU does.

=head2 format_double

Formats a number with ICU's double code path, even if it is integral.

=head2 format_int

Formats an integer with ICU's integer code path.

=head2 lenient

Sets or gets the lenient parsing mode.

=head2 locale

    my $locale = $fmt->locale;
    say $locale;
    # fr-CH

Returns the canonical locale of the formatter as a L<Locale::Unicode> object, which stringifies as a BCP 47 identifier, such as C<fr-CH> or C<ja-JP-u-nu-hanidec>, extensions included.

The locale C<root> is returned as C<root>, rather than as its canonical form C<und>.

=head2 max_fraction_digits

Sets or gets the maximum number of fraction digits used for rounding.

=head2 numbering_system

Returns the numbering system used.

=head2 parse

    my $n = $fmt->parse( $text );
    my( $n, $index, $error_index ) = $fmt->parse( $text, $start );

Parses text into a number, trying every public and parseable rule set, and keeping the result that consumed the most characters. In list context, it returns the value, the index after the parsed text, and the error index (C<-1> on success).

=head2 pass_error

    return( $self->pass_error( $other->error ) );
    return( $self->pass_error );

Propagates the error stored in another object (or the class-level error) into the current object's error slot, without constructing a new exception, and then returns C<undef> in scalar context, or an empty list in list context, or a L<Locale::Unicode::RBNF::NullObject> in object context, just like L</error> does.

Without any argument, the last error is passed on.

If the error is not an object, L</error> is called with it.

If an hash reference is passed with the key C<class> it will bless the error into that exception class provided.

Supported options are:

=over 4

=item * C<class>

The name of a class name to re-bless the error object provided.

=item * C<code>

The error code to set in the error object being passed.

=item * C<error>

The error object to be passed on.

If this is not provided, it will get it with the object C<error> method, or the class global variable C<$ERROR>

=back

=head2 rounding_mode

Sets or gets the rounding mode.

=head2 rule_set_display_name

    my $name = $fmt->rule_set_display_name( '%main', 'fr' );

Returns the localised name of a rule set, given by name or index, when C<localizations> were provided.

=head2 rule_set_display_name_locales

Returns an array reference of the locales of the localised names.

=head2 rule_set_names

Returns an array reference of the public rule set names.

=head2 rule_sets_from_description

    my $r = Locale::Unicode::RBNF->rule_sets_from_description( $description );
    # {
    #     lenient_parse => undef,
    #     rule_sets => [
    #         {
    #             name      => '%spellout-numbering-year',
    #             type      => 'spellout-numbering-year',
    #             private   => 0,
    #             parseable => 1,
    #             rules     => [ { descriptor => 'x.x', text => '=0.0=' }, ... ],
    #         },
    #         ...
    #     ],
    # }

Divides a rule description into its rule sets and rules, without compiling them, exactly as ICU does when it reads them: same whitespace stripping, same extraction of the C<%%lenient-parse> rules, same division into rule sets and rules, and same separation of the rule descriptor from the rule text. It uses the very code of the constructor. This is meant for storing the rules, for instance in a database. It can be called as a class method, and returns C<undef> upon error.

The rule text is kept as it is in the description, including a leading apostrophe, but without the terminating semicolon. See also L<Locale::Unicode::RBNF::CLDR/rbnf_groupings>.

=head2 rules

Returns a textual description of the rules in use, equivalent to the original one.

=head2 symbols

Sets or gets the decimal format symbols, as an hash reference with the keys C<decimal>, C<group>, C<minus>, C<plus>, C<percent>, C<per_mille>, C<infinity>, C<nan> and C<digits> (an array reference of 10 digits).

=head2 valid_locale

    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr-FR', cldr => $cldr );
    say $fmt->valid_locale;
    # fr

Returns the locale built using the CLDR rules, and found by following the locale inheritance chain, as a L<Locale::Unicode> object, such as C<fr> or C<root>.

It returns C<undef> when the rules were provided with the C<rules> option.

=head1 ERROR HANDLING

Exceptions are built as L<Locale::Unicode::RBNF::Exception> objects, which stringify as their message followed by the package, line and file where they occurred.

By default, a method that fails sets an error, retrievable with L</error>, emits it as a warning if the warnings category C<Locale::Unicode::RBNF> is enabled in the caller, and returns C<undef> in scalar context, an empty list in list context, or a L<Locale::Unicode::RBNF::NullObject> in object context.

If the C<fatal> option, or L</fatal>, is true, the error is raised with C<die> instead, and can be caught with C<eval> or C<try-catch> if you are using Perl version C<5.34.0>, or higher. The global variable C<$Locale::Unicode::RBNF::FATAL_EXCEPTIONS> sets the default for new objects, and applies to errors of class methods, such as those of the constructor.

    {
        local $Locale::Unicode::RBNF::FATAL_EXCEPTIONS = 1;
        my $fmt = eval{ Locale::Unicode::RBNF->new( locale => 'x-private' ) };
        warn( $@->message ) if( $@ );
    }

=head1 PARSING ENGINE

Parsing is costly: as in ICU, it tries every rule of every public rule set, recursively. This distribution therefore includes a port to C of the parsing code path (F<Locale-Unicode-RBNF.xs>), built when a C compiler is available, and used automatically. Formatting remains in Perl, since it is fast.

The pure Perl implementation, in L<Locale::Unicode::RBNF::PP>, is the fallback: it is loaded automatically when the XS shared object cannot be loaded, such as when the distribution was installed without a C compiler, or when the environment variable C<PERL_LOCALE_UNICODE_RBNF_PP> is set to a true value before the module is loaded. The variable C<$Locale::Unicode::RBNF::IsPurePerl> tells which one is in use. Both give the same results; the test suite checks it.

The C engine is the internal class C<Locale::Unicode::RBNF::XS>, created by the formatter when parsing first needs it. Its constructor C<new> takes an hash reference of the rule sets, rules, substitutions, plural patterns and decimal formats of the formatter, flattened into arrays of hashes, together with the Perl callbacks it uses for lenient matching (case folding, separators, NFC boundaries and normalisation, and digit values), whose results it caches per code point. Its method C<parse>, given the text and the lenient flag, returns the value, the number of characters matched and the error index. You should not normally use this class directly.

=head1 DIFFERENCES WITH ICU

=over 4

=item * Lenient parsing uses ICU 79's NFC and case-folding matching. ICU additionally falls back on a collator tailored with C<%%lenient-parse> rules when a rule description provides some; collation tailoring is not available here, so that fallback never matches. Current CLDR data has no such rules.

=item * Where ICU creates a C<NumberFormat> for the default locale, during lenient parsing, the decimal format of the formatter's locale is used.

=item * Decimal patterns support the subset needed by rule-based formats: C<#>, C<0>, C<,>, C<.>, literal affixes, percent and per mille. Significant digits, exponents and rounding increments are rejected.

=item * Contextual capitalisation titlecases the first character, without a sentence break iterator.

=item * Parse results are computed with doubles, as ICU does. Beyond 2^53, the pure Perl engine may keep integer precision where ICU and the C engine round.

On a perl whose numbers are long doubles or C<__float128> (C<nvsize> greater than 8), a non-integral parsed result is rounded to the nearest double, whichever engine is in use, so that both return the same value.
Such a perl prints that value with more digits: C<3,2> parsed in French gives C<3.20000000000000017763568394002505>, which is exactly the double ICU returns.

=item * A perl with 64-bit integers (C<ivsize> of 8) is required, since the C<int64_t> arithmetic of ICU is reproduced with native perl integers.

=item * Where ICU converts an out of range double to an C<int32_t> to select a plural form, which is undefined behaviour in C++, the saturating semantics of Java and aarch64 are used.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://unicode-org.github.io/icu/userguide/format_parse/numbers/rbnf.html>, L<https://www.unicode.org/reports/tr35/tr35-numbers.html#Rule-Based_Number_Formatting>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License (L<https://www.unicode.org/copyright.html>). Its text is in the F<LICENSE-UNICODE> file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
