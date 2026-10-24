##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/CLDR.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/10/22
## Modified 2026/10/22
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# Reads, from a CLDR "common" directory, everything a rule-based number format needs:
# the RBNF rules (current CDATA format and the legacy <ruleset>/<rbnfrule> format),
# the decimal format symbols, the default numbering system and its digits, the decimal
# pattern, the contextual capitalisation of spelled-out numbers, and the cardinal and
# ordinal plural rules.
package Locale::Unicode::RBNF::CLDR;
BEGIN
{
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'Locale::Unicode::RBNF' );
    use vars qw( $VERSION $CACHE @SYMBOLS );
    use File::Spec ();
    use Locale::Unicode v0.4.4;
    use Scalar::Util ();
    use XML::LibXML ();
    $CACHE = {};
    # Map of our symbol keys to the CLDR element names
    @SYMBOLS = (
        [ decimal   => 'decimal' ],
        [ group     => 'group' ],
        [ minus     => 'minusSign' ],
        [ plus      => 'plusSign' ],
        [ percent   => 'percentSign' ],
        [ per_mille => 'perMille' ],
        [ infinity  => 'infinity' ],
        [ nan       => 'nan' ],
    );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub new
{
    my( $this, $dir, $st ) = @_;
    my $self = bless( { dir => $dir }, ( ref( $this ) || $this ) );
    if( !defined( $dir ) || !-d( File::Spec->catdir( $dir, 'rbnf' ) ) )
    {
        $$st = 'U_MISSING_RESOURCE_ERROR: "' . ( $dir // '' ) . '" is not a CLDR common directory with an rbnf sub-directory';
        return( $self );
    }
    # Parsed documents and resolved values are shared by all objects using the same directory.
    $self->{cache} = ( $CACHE->{ $dir } //= {} );
    return( $self );
}

# Converts a locale, given as a BCP 47 or CLDR identifier, or as a Locale::Unicode object, into
# the CLDR file identifier: language_Script_REGION_VARIANT. Locale::Unicode parses and
# canonicalises it. Returns ( $file_id, $numbering_system, $locale ), where the numbering
# system is the one requested with a "-u-nu-xxxx" extension, if any, and $locale is the
# canonical Locale::Unicode object; or an empty list, with the error in $st, if the locale is
# invalid.
sub canonical_locale
{
    my( $self, $locale, $st ) = @_;
    $locale = 'root' if( !defined( $locale ) || !length( "$locale" ) );
    my $obj;
    if( Scalar::Util::blessed( $locale ) && $locale->isa( 'Locale::Unicode' ) )
    {
        $obj = $locale->canonical;
    }
    else
    {
        # The error is reported through $st, so Locale::Unicode does not need to warn about it too.
        my $parsed = do { no warnings 'Locale::Unicode'; Locale::Unicode->new( "$locale" ) };
        if( !$parsed )
        {
            my $err = Locale::Unicode->error;
            $$st = 'U_ILLEGAL_ARGUMENT_ERROR: invalid locale "' . $locale . '": ' . ( ( Scalar::Util::blessed( $err ) && $err->can( 'message' ) ) ? $err->message : ( $err // 'unknown error' ) ) if( $st );
            return;
        }
        $obj = $parsed->canonical;
    }
    # An extended language subtag, such as yue in zh-yue-HK, is the actual language: BCP 47
    # canonicalisation replaces zh-yue with yue, and CLDR has the data under yue.
    my $lang = $obj->extended || $obj->language_id;
    if( !defined( $lang ) || !length( $lang ) )
    {
        $$st = 'U_ILLEGAL_ARGUMENT_ERROR: locale "' . $locale . '" has no language subtag' if( $st );
        return;
    }
    # CLDR file names use upper case variants, such as en_US_POSIX, whereas the canonical BCP 47
    # form has them in lower case.
    my @parts = ( $lang );
    push( @parts, $obj->script ) if( $obj->script );
    push( @parts, $obj->territory ) if( $obj->territory );
    push( @parts, map( uc( $_ ), split( /-/, $obj->variant ) ) ) if( $obj->variant );
    my $id = join( '_', @parts );
    # The canonical form of "root" is "und", which CLDR names "root" when it has no other subtag.
    if( $id eq 'und' || $id eq 'root' )
    {
        $id = 'root';
        $obj->language( 'root' );
    }
    return( $id, ( $obj->number || undef ), $obj );
}

# The locale inheritance chain, from the locale itself up to and including root.
sub chain
{
    my( $self, $locale ) = @_;
    my @chain;
    my $loc = $locale;
    my %seen;
    while( defined( $loc ) && !$seen{ $loc }++ )
    {
        push( @chain, $loc );
        last if( $loc eq 'root' );
        $loc = $self->parent_locale( $loc );
    }
    push( @chain, 'root' ) if( $chain[-1] ne 'root' );
    return( @chain );
}

# Returns [ uiListOrMenu, stand-alone ], each true when spelled-out numbers must have their
# first word titlecased in that context.
sub context_transforms
{
    my( $self, $locale ) = @_;
    my $result = [ 0, 0 ];
    my @types = ( 'uiListOrMenu', 'stand-alone' );
    for my $i ( 0..1 )
    {
        foreach my $loc ( $self->chain( $locale ) )
        {
            my $doc = $self->_main_doc( $loc ) || next;
            my( $node ) = $doc->findnodes( qq{/ldml/contextTransforms/contextTransformUsage[\@type='number-spellout']/contextTransform[\@type='$types[$i]'][not(\@alt)]} );
            next if( !$node || _is_draft( $node ) );
            my $val = $node->textContent;
            next if( $val eq "\x{2191}\x{2191}\x{2191}" );
            $result->[$i] = $val eq 'titlecase-firstword' ? 1 : 0;
            last;
        }
    }
    return( $result );
}

# The standard decimal pattern of the locale for the given numbering system.
sub decimal_pattern
{
    my( $self, $locale, $ns ) = @_;
    my $key = "decimal_pattern:$locale:$ns";
    return( $self->{cache}->{ $key } ) if( exists( $self->{cache}->{ $key } ) );
    my $pattern;
    my @try = ( $ns );
    push( @try, 'latn' ) if( $ns ne 'latn' );
    NS: foreach my $n ( @try )
    {
        foreach my $loc ( $self->chain( $locale ) )
        {
            my $doc = $self->_main_doc( $loc ) || next;
            my( $fmt ) = $doc->findnodes( qq{/ldml/numbers/decimalFormats[\@numberSystem='$n']} );
            next if( !$fmt );
            # An alias in root means the pattern of another numbering system, looked up from
            # the original locale again.
            next NS if( $fmt->findnodes( 'alias' )->size );
            my( $node ) = $fmt->findnodes( q{decimalFormatLength[not(@type)]/decimalFormat[not(@type) or @type='standard']/pattern[not(@alt) and not(@type)]} );
            next if( !$node || _is_draft( $node ) );
            my $val = $node->textContent;
            next if( $val eq "\x{2191}\x{2191}\x{2191}" );
            $pattern = $val;
            last NS;
        }
    }
    return( $self->{cache}->{ $key } = $pattern // '#,##0.###' );
}

sub default_numbering_system
{
    my( $self, $locale ) = @_;
    foreach my $loc ( $self->chain( $locale ) )
    {
        my $doc = $self->_main_doc( $loc ) || next;
        my( $node ) = $doc->findnodes( q{/ldml/numbers/defaultNumberingSystem[not(@alt)]} );
        next if( !$node || _is_draft( $node ) );
        my $val = $node->textContent;
        next if( $val eq "\x{2191}\x{2191}\x{2191}" );
        return( $val );
    }
    return( 'latn' );
}

# The ten digits of a numeric numbering system, or undef if it is unknown or algorithmic.
sub digits
{
    my( $self, $ns ) = @_;
    my $map = ( $self->{cache}->{numbering_systems} //= $self->_load_numbering_systems );
    return( $map->{ $ns } );
}

sub dir { return( $_[0]->{dir} ); }

sub parent_locale
{
    my( $self, $locale ) = @_;
    return if( $locale eq 'root' );
    my $parents = ( $self->{cache}->{parents} //= $self->_load_parent_locales );
    return( $parents->{ $locale } ) if( exists( $parents->{ $locale } ) );
    my @parts = split( /_/, $locale );
    return( 'root' ) if( @parts <= 1 );
    pop( @parts );
    return( join( '_', @parts ) );
}

# Returns an array reference of [ keyword, condition ] for 'cardinal' or 'ordinal' rules.
sub plural_rules
{
    my( $self, $locale, $type ) = @_;
    my $all = ( $self->{cache}->{ "plurals:$type" } //= $self->_load_plurals( $type ) );
    # Plural rules are looked up using truncation of the locale, just like ICU does:
    # the parentLocales of supplementalData.xml only apply to the main data, so
    # sr_Latn uses the rules of sr, not those of root.
    my @parts = split( /_/, $locale );
    while( @parts )
    {
        my $loc = join( '_', @parts );
        return( $all->{ $loc } ) if( exists( $all->{ $loc } ) );
        pop( @parts );
    }
    return( $all->{root} ) if( exists( $all->{root} ) );
    return( [] );
}

# Returns an array reference of hash reference containing the following keys:
# - grouping
# - rule_sets
# - lenient_parse
# for every rule set grouping of an RBNF file, given as an XML::LibXML document or as
# a locale, without inheritance. The rule sets are those of 
# Locale::Unicode::RBNF->rule_sets_from_description().
sub rbnf_groupings
{
    my( $self, $what ) = @_;
    my $doc = ( Scalar::Util::blessed( $what ) && $what->isa( 'XML::LibXML::Node' ) ) ? $what : $self->_rbnf_doc( $what );
    return( [] ) if( !$doc );
    # Loaded here rather than at compile time, since Locale::Unicode::RBNF uses this module.
    require Locale::Unicode::RBNF;
    my @result;
    foreach my $group ( $doc->findnodes( '/ldml/rbnf/rulesetGrouping' ) )
    {
        my $desc = _grouping_description( $group );
        next if( !defined( $desc ) || !length( $desc ) );
        my $sets = Locale::Unicode::RBNF->rule_sets_from_description( $desc ) ||
            die( 'Unable to divide the rules of grouping ' . $group->getAttribute( 'type' ) . ': ' . Locale::Unicode::RBNF->error );
        push( @result, { grouping => $group->getAttribute( 'type' ), %$sets } );
    }
    return( \@result );
}

# The locales that have an RBNF file
sub rbnf_locales
{
    my $self = shift( @_ );
    my $dir = File::Spec->catdir( $self->{dir}, 'rbnf' );
    opendir( my $dh, $dir ) || return( [] );
    my @locales = sort( map( substr( $_, 0, -4 ), grep( /\.xml$/, readdir( $dh ) ) ) );
    return( \@locales );
}

# Returns ( $rules, $locale_found ) for a rule set grouping such as 'SpelloutRules',
# 'OrdinalRules' or 'NumberingSystemRules', following the locale inheritance chain.
sub rbnf_rules
{
    my( $self, $locale, $grouping ) = @_;
    foreach my $loc ( $self->chain( $locale ) )
    {
        my $doc = $self->_rbnf_doc( $loc ) || next;
        my( $group ) = $doc->findnodes( qq{/ldml/rbnf/rulesetGrouping[\@type='$grouping']} );
        next if( !$group );
        my $desc = _grouping_description( $group );
        return( $desc, $loc ) if( defined( $desc ) && length( $desc ) );
    }
    return;
}

# The decimal format symbols of a locale for a numbering system, resolved with inheritance.
sub symbols
{
    my( $self, $locale, $ns ) = @_;
    my $key = "symbols:$locale:$ns";
    return( { %{$self->{cache}->{ $key }} } ) if( exists( $self->{cache}->{ $key } ) );
    my $sym = {};
    foreach my $def ( @SYMBOLS )
    {
        my( $name, $element ) = @$def;
        $sym->{ $name } = $self->_symbol( $locale, $ns, $element, {} );
    }
    # Root values, should the data be incomplete
    my %defaults = ( decimal => '.', group => ',', minus => '-', plus => '+', percent => '%', per_mille => "\x{2030}", infinity => "\x{221E}", nan => 'NaN' );
    $sym->{ $_ } //= $defaults{ $_ } for( keys( %defaults ) );
    my $digits = $self->digits( $ns );
    $sym->{digits} = $digits ? [ split( //, $digits ) ] : [ 0..9 ];
    $sym->{numbering_system} = $ns;
    $self->{cache}->{ $key } = $sym;
    return( { %$sym } );
}

# Returns the rules of a <rulesetGrouping> element in the ICU syntax.
# Legacy format of earlier CLDR releases (CLDR 44 uses it) was:
# one <ruleset> per rule set, one <rbnfrule> per rule, with arrows
# instead of angle brackets, and the radix in its own attribute.
sub _grouping_description
{
    my $group = shift( @_ );
    my( $cdata ) = $group->findnodes( 'rbnfRules' );
    return( $cdata->textContent ) if( $cdata );
    my @lines;
    foreach my $rs ( $group->findnodes( 'ruleset' ) )
    {
        my $access = $rs->getAttribute( 'access' ) // '';
        push( @lines, ( $access eq 'private' ? '%%' : '%' ) . $rs->getAttribute( 'type' ) . ':' );
        foreach my $r ( $rs->findnodes( 'rbnfrule' ) )
        {
            my $value = $r->getAttribute( 'value' );
            my $radix = $r->getAttribute( 'radix' );
            my $text = $r->textContent;
            # Exponent markers in the value, such as "100>", are also written as arrows.
            $value =~ s/\x{2192}/>/g;
            $value .= '/' . $radix if( defined( $radix ) && length( $radix ) );
            $text =~ tr/\x{2190}\x{2192}/<>/;
            # The lenient-parse rule set holds collation rules, not number format rules, so its
            # content has no rule descriptor.
            push( @lines, ( $rs->getAttribute( 'type' ) eq 'lenient-parse' ? $text : $value . ': ' . $text ) );
        }
    }
    return( @lines ? join( "\n", @lines ) : undef );
}

sub _is_draft
{
    my $node = shift( @_ );
    my $draft = $node->getAttribute( 'draft' ) // '';
    # ICU only takes approved and contributed data.
    return( ( $draft eq 'unconfirmed' || $draft eq 'provisional' ) ? 1 : 0 );
}

sub _load_doc
{
    my( $self, $file ) = @_;
    return( $self->{cache}->{docs}->{ $file } ) if( exists( $self->{cache}->{docs}->{ $file } ) );
    my $doc;
    if( -e( $file ) )
    {
        $doc = XML::LibXML->load_xml( location => $file, no_network => 1, load_ext_dtd => 0, expand_entities => 1 );
    }
    return( $self->{cache}->{docs}->{ $file } = $doc );
}

sub _load_numbering_systems
{
    my $self = shift( @_ );
    my $doc = $self->_load_doc( File::Spec->catfile( $self->{dir}, 'supplemental', 'numberingSystems.xml' ) ) || return( { latn => '0123456789' } );
    my $map = {};
    foreach my $node ( $doc->findnodes( q{//numberingSystem[@type='numeric']} ) )
    {
        my $digits = $node->getAttribute( 'digits' );
        $map->{ $node->getAttribute( 'id' ) } = $digits if( defined( $digits ) && length( $digits ) == 10 );
    }
    return( $map );
}

sub _load_parent_locales
{
    my $self = shift( @_ );
    my $doc = $self->_load_doc( File::Spec->catfile( $self->{dir}, 'supplemental', 'supplementalData.xml' ) ) || return( {} );
    my $map = {};
    # Only the general parent locales apply, not those specific to a component.
    foreach my $node ( $doc->findnodes( q{//parentLocales[not(@component)]/parentLocale} ) )
    {
        my $parent = $node->getAttribute( 'parent' );
        $map->{ $_ } = $parent for( split( ' ', $node->getAttribute( 'locales' ) // '' ) );
    }
    return( $map );
}

sub _load_plurals
{
    my( $self, $type ) = @_;
    my $file = File::Spec->catfile( $self->{dir}, 'supplemental', ( $type eq 'ordinal' ? 'ordinals.xml' : 'plurals.xml' ) );
    my $doc = $self->_load_doc( $file ) || return( {} );
    my $all = {};
    foreach my $set ( $doc->findnodes( qq{//plurals[\@type='$type']/pluralRules} ) )
    {
        my @rules = map( [ $_->getAttribute( 'count' ), $_->textContent ], $set->findnodes( 'pluralRule' ) );
        $all->{ $_ } = \@rules for( split( ' ', $set->getAttribute( 'locales' ) // '' ) );
    }
    return( $all );
}

sub _main_doc
{
    my( $self, $locale ) = @_;
    return( $self->_load_doc( File::Spec->catfile( $self->{dir}, 'main', "${locale}.xml" ) ) );
}

sub _rbnf_doc
{
    my( $self, $locale ) = @_;
    return( $self->_load_doc( File::Spec->catfile( $self->{dir}, 'rbnf', "${locale}.xml" ) ) );
}

# Resolves one symbol. An alias to another numbering system restarts the lookup from the
# original locale with that numbering system.
sub _symbol
{
    my( $self, $locale, $ns, $element, $seen ) = @_;
    return if( $seen->{ $ns }++ );
    foreach my $loc ( $self->chain( $locale ) )
    {
        my $doc = $self->_main_doc( $loc ) || next;
        my( $symbols ) = $doc->findnodes( qq{/ldml/numbers/symbols[\@numberSystem='$ns']} );
        next if( !$symbols );
        if( my( $alias ) = $symbols->findnodes( 'alias' ) )
        {
            if( ( $alias->getAttribute( 'path' ) // '' ) =~ /numberSystem='([^']+)'/ )
            {
                return( $self->_symbol( $locale, $1, $element, $seen ) );
            }
            next;
        }
        my( $node ) = $symbols->findnodes( qq{${element}[not(\@alt)]} );
        next if( !$node || _is_draft( $node ) );
        my $val = $node->textContent;
        next if( $val eq "\x{2191}\x{2191}\x{2191}" );
        return( $val );
    }
    return;
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::CLDR - CLDR data loader for Locale::Unicode::RBNF

=head1 SYNOPSIS

    use Locale::Unicode::RBNF::CLDR;
    my $st;
    my $cldr = Locale::Unicode::RBNF::CLDR->new( '/path/to/cldr/common', \$st );
    my( $rules, $found ) = $cldr->rbnf_rules( 'fr_CH', 'SpelloutRules' );

=head1 DESCRIPTION

This module loads the data required by L<Locale::Unicode::RBNF> from a CLDR F<common> directory: F<rbnf/*.xml>, F<main/*.xml>, F<supplemental/supplementalData.xml>, F<supplemental/numberingSystems.xml>, F<supplemental/plurals.xml> and F<supplemental/ordinals.xml>.

Both the current RBNF XML format, where a rule set grouping holds the rules in ICU syntax in a C<rbnfRules> element, and the legacy format of earlier releases (such as CLDR 44), with C<ruleset> and C<rbnfrule> elements, are supported.

The parsed files are cached per CLDR directory, for the duration of the process.

The methods in this class use locales as a CLDR file identifier, such as C<fr_CH>, which is the file names format used in the CLDR data. L</canonical_locale> converts a BCP 47 identifier, such as C<fr-CH>, or a L<Locale::Unicode> object, into that form.

=head1 CONSTRUCTOR

=head2 new

    my $st;
    my $cldr = Locale::Unicode::RBNF::CLDR->new( '/path/to/cldr/common', \$st );
    die( $st ) if( $st );

Takes the path to a CLDR F<common> directory and a scalar reference that receives an error status, and returns a new object.

The object is always returned. If the directory does not exist or has no F<rbnf> sub-directory, the status is set to a C<U_MISSING_RESOURCE_ERROR> message, and the caller must check it.

=head1 METHODS

=head2 canonical_locale

    my $st;
    my( $file_id, $numbering_system, $locale ) = $cldr->canonical_locale( 'zh-hant-tw-u-nu-hanidec', \$st );
    # zh_Hant_TW, hanidec, and the Locale::Unicode object zh-Hant-TW-u-nu-hanidec
    die( $st ) if( $st );

Takes a locale, as a BCP 47 identifier, such as C<fr-CH>, as a CLDR identifier, such as C<fr_CH>, or as a L<Locale::Unicode> object, and an optional scalar reference that receives an error status. It can be called as a class method.

The locale is parsed and canonicalised with L<Locale::Unicode>, and converted to the CLDR file identifier, C<language_Script_REGION_VARIANT>, such as C<fr_CH>, C<zh_Hant_TW> or C<en_US_POSIX>, which is the form the other methods of this class take. Extensions are not part of it.

It returns a list of 3 elements: the CLDR file identifier; the numbering system requested with a C<-u-nu-> extension, or C<undef> if there is none; and the canonical L<Locale::Unicode> object. An undefined or empty locale, C<root> and C<und> all yield C<root>, and the object is then C<root> rather than its canonical form C<und>.

If the locale cannot be parsed, or has no language subtag, such as C<x-private>, it returns an empty list, and sets the status to a C<U_ILLEGAL_ARGUMENT_ERROR> message. The ICU keyword syntax, such as C<fr_CH@numbers=latn>, is not supported.

=head2 chain

    my @chain = $cldr->chain( 'fr_CH' );
    # fr_CH, fr, root

Returns the list of locales of the inheritance chain, from the locale itself up to and including C<root>, following L</parent_locale>.

=head2 context_transforms

    my $transforms = $cldr->context_transforms( 'fr' );

Returns an array reference of 2 booleans, for the C<uiListOrMenu> and C<stand-alone> contexts respectively, each true when the C<number-spellout> context transform of the locale is C<titlecase-firstword>, that is when the first word of a spelled-out number must be titlecased in that context. The values are resolved with inheritance, and draft values that ICU ignores, C<unconfirmed> and C<provisional>, are ignored here too.

=head2 decimal_pattern

    my $pattern = $cldr->decimal_pattern( 'hi', 'deva' );

Returns the standard decimal pattern of the locale for the given numbering system, resolved with inheritance. If the numbering system has none, the pattern of C<latn> is used, and failing that C<#,##0.###>. Results are cached.

=head2 default_numbering_system

    my $ns = $cldr->default_numbering_system( 'ar_EG' );

Returns the default numbering system of the locale, resolved with inheritance, or C<latn> if none is found.

=head2 digits

    my $digits = $cldr->digits( 'arab' );

Returns the ten digits of a numeric numbering system as a string, as found in F<supplemental/numberingSystems.xml>, or C<undef> if the numbering system is unknown or algorithmic.

=head2 dir

Returns the CLDR F<common> directory given to L</new>.

=head2 parent_locale

    my $parent = $cldr->parent_locale( 'en_AU' );
    # en_001

Returns the parent locale, as defined by the C<parentLocales> of F<supplemental/supplementalData.xml> that are not specific to a component, or otherwise by truncation of the last subtag. It returns C<root> for a language-only locale, and an empty list for C<root>.

=head2 plural_rules

    my $rules = $cldr->plural_rules( 'fr', 'cardinal' );
    my $rules = $cldr->plural_rules( 'fr', 'ordinal' );

Returns an array reference of array references C<[ keyword, condition ]>, in the order of the CLDR data, for the C<cardinal> rules of F<supplemental/plurals.xml> or the C<ordinal> rules of F<supplemental/ordinals.xml>. This is suitable for L<Locale::Unicode::RBNF::PluralRules/new>.

As ICU does, the rules are looked up by truncation of the locale, not through the C<parentLocales>, which only apply to the main data: C<sr_Latn> uses the rules of C<sr>. If nothing is found, the rules of C<root> are returned, or an empty array reference.

=head2 rbnf_groupings

    my $groupings = $cldr->rbnf_groupings( 'ja' );
    my $groupings = $cldr->rbnf_groupings( $xml_libxml_document );

Returns an array reference of hash references, one per C<rulesetGrouping> of an RBNF file, in document order, with the keys C<grouping> (such as C<SpelloutRules>), C<rule_sets> and C<lenient_parse>, as returned by L<Locale::Unicode::RBNF/rule_sets_from_description>. There is no locale inheritance here: only the given file is read.

It accepts an L<XML::LibXML> document, for instance one loaded and patched by a build script, or a locale.

It returns an empty array reference if the RBNF file does not exist, and dies if the rules of a grouping cannot be divided into rule sets.

=head2 rbnf_locales

    my $locales = $cldr->rbnf_locales;

Returns an array reference of the locales that have a file in the F<rbnf> directory, sorted.

=head2 rbnf_rules

    my( $description, $locale_found ) = $cldr->rbnf_rules( 'fr_CH', 'SpelloutRules' );

Returns the rule description of a grouping, such as C<SpelloutRules>, C<OrdinalRules> or C<NumberingSystemRules>, in the ICU syntax, following the locale inheritance chain, together with the locale where it was found. It returns an empty list if no locale of the chain has that grouping.

Rules provided in the legacy format, with C<ruleset> and C<rbnfrule> elements, are converted to the ICU syntax.

=head2 symbols

    my $symbols = $cldr->symbols( 'fr', 'latn' );

Returns an hash reference of the decimal format symbols of the locale for the given numbering system, resolved with inheritance, and following the aliases to other numbering systems. The keys are C<decimal>, C<group>, C<minus>, C<plus>, C<percent>, C<per_mille>, C<infinity>, C<nan>, C<digits> (an array reference of the 10 digits of the numbering system) and C<numbering_system>.

The values of C<root> are used for any symbol the data does not provide. A new hash reference is returned on each call, so it can be modified freely.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
