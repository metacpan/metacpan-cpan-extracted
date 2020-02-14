use v5.14;
use warnings;

package Datify v0.20.045;
# ABSTRACT: Simple stringification of data.


use mro      ();        #qw( get_linear_isa );
use overload ();        #qw( Method Overloaded );

use Carp         ();    #qw( carp croak );
use List::Util   ();    #qw( reduce sum );
use Scalar::Util ();    #qw( blessed looks_like_number refaddr reftype );
use String::Tools v0.18.277 ();    #qw( stitch stringify subst );
use Sub::Util      1.40     ();    #qw( subname );


### Constructor ###


sub new {
    my $class = shift || __PACKAGE__;

    my %self = ();
    if ( defined( my $blessed = Scalar::Util::blessed($class) ) ) {
        %self  = %$class;    # shallow copy
        $class = $blessed;
    }
    return @_ ? bless( \%self, $class )->set(@_) : bless( \%self, $class );
}



### Accessor ###




sub exists {
    my $self = shift;
    return unless my $count = scalar(@_);

    my $SETTINGS = $self->_settings;
    if ( Scalar::Util::blessed($self) ) {
        return $count == 1
            ?      exists $self->{ $_[0] }     && $self
                || exists $SETTINGS->{ $_[0] } && $SETTINGS
            : map {
                   exists $self->{ $_ }        && $self
                || exists $SETTINGS->{ $_ }    && $SETTINGS
            } @_;
    } else {
        return
            $count == 1 ? exists $SETTINGS->{ $_[0] } && $SETTINGS
            :       map { exists $SETTINGS->{ $_ }    && $SETTINGS } @_;
    }
}



sub _get_setting {
    my $setting = $_[0]->exists( local $_ = $_[1] );
    return $setting ? $setting->{$_} : do {
        Carp::carp( 'Unknown key ', $_ )
            unless $_[0]->_internal(1);
        undef
    };
}
sub get {
    my $self  = shift;
    my $count = scalar(@_);

    if ( defined( my $class = Scalar::Util::blessed($self) ) ) {
        return
              $count == 0 ? ( %{ $self->_settings }, %$self )
            : $count == 1 ? $self->_get_setting(shift)
            :         map { $self->_get_setting($_) } @_;
    } else {
        return
              $count == 0 ? %{ $self->_settings }
            : $count == 1 ? $self->_get_setting(shift)
            :         map { $self->_get_setting($_) } @_;
    }
}


### Setter ###


sub set {
    my $self = shift;
    return $self unless @_;
    my %set  = @_;

    my $return;
    my $class;
    if ( defined( $class = Scalar::Util::blessed($self) ) ) {
        # Make a shallow copy
        $self   = bless { %$self }, $class;
        $return = 0;
    } else {
        $class  = $self;
        $self   = $class->_settings;
        $return = 1;
    }

    delete $self->{keyword_set} if ( $set{keywords} );
    delete $self->{"_tr$_"} for grep { exists $set{"quote$_"} } ( 1, 2, 3 );

    my $internal = $class->_internal;
    while ( my ( $k, $v ) = each %set ) {
        Carp::carp( 'Unknown key ', $k )
            unless $internal || $class->exists($k);
        study($v) if defined($v) && !ref($v);
        $self->{$k} = $v;
    }

    return ( $self, $class )[$return];
}




sub add_handler {
    my $self = &self;
    my $code = pop;
    my $pkg  = length( $_[0] ) ? shift : caller;

    if ( my $name = _nameify($pkg) ) {
        no strict 'refs';
        *{$name} = $code;
    }
}




__PACKAGE__->set(
    # Var options
    name        => '$self',
    assign      => '$var = $value;',
    list        => '($_)',
    list_sep    => ', ',
    beautify    => undef,
);

# Name can be any of the following:
# * package name (optional) followed by:
#   * normal word
#   * ::
# * Perl special variable:
#   * numbers
#   * punctuation
#   * control character
#   * control word
my $sigils     = '[\\x24\\x25\\x40]'; # $%@
my $package    = '[[:alpha:]]\w*(?:\::\w+)*';
my $word       = '[[:alpha:]_]\w*';
my $digits     = '\d+';
my $punct      = '[[:punct:]]';
my $cntrl      = '(?:[[:cntrl:]]|\^[[:upper:]])';
my $cntrl_word = "$cntrl$word";
my $varname
    = '(?:' . join( '|', $word, $digits, $punct, $cntrl, $cntrl_word ) . ')';
$varname .= "|\\{\\s*$varname\\s*\\}";
$varname  = "(?:$varname)";


sub varify {
    my $self = &self;
    my ($sigil, $name);
    if ( defined $_[0] && !ref $_[0] ) {
        ( $sigil, $name )
            = $_[0] =~ /^($sigils)?((?:$package\::)?$varname|$package\::)$/;
        shift if length $name;
    }
    my $value = 1 == @_ ? shift : \@_;

    if ( length $name ) {
        if ( $name =~ /[[:cntrl:]]/ ) {
            $name =~ s/([[:cntrl:]])/'^' . chr(64 + ord($1) % 64)/e;
            $name =~ s/($cntrl_word)(?!\s*\})/\{$1\}/;
        }
    } else {
        if ( defined( my $ref = Scalar::Util::blessed($value) ) ) {
            $name = _nameify($ref);
        } else {
            $name = $self->get('name');
        }
    }
    Carp::croak "Missing name" unless ( length $name );

    unless ($sigil) {
        my $ref = ref $value;
        $sigil
            = $ref eq 'ARRAY' ? '@'
            : $ref eq 'HASH'  ? '%'
            :                   '$';
    }
    $name = $sigil . $name;
    $self = $self->set( name => $name );

    $value
        = $sigil eq '$' ?                             $self->scalarify($value)
        : $sigil eq '@' ? _subst( $self->get('list'), $self->listify($value) )
        : $sigil eq '%' ? _subst( $self->get('list'), $self->pairify($value) )
        :                                             $self->scalarify($value)
        ;

    $value = _subst( $self->get('assign'), var => $name, value => $value );
    if ( my $beautify = $self->get('beautify') ) {
        return $beautify->($value);
    } else {
        return $value;
    }
}



### Scalar: undef ###


__PACKAGE__->set(
    # Undef options
    null => 'undef',
);


sub undefify {
    my $self = &self;
    return $self->scalarify(shift) if @_ and defined($_[0]);
    return $self->get('null');
}



### Scalar: boolean ###


__PACKAGE__->set(
    # Boolean options
    true    => 1,
    false   => "''",
);


sub booleanify {
    my $self = &self;
    local $_ = shift if @_;
    return $self->undefify unless defined;
    return $_ ? $self->get('true') : $self->get('false');
}



### Scalar: single-quoted string ###


sub stringify1 {
    my $self = &self;
    local $_ = shift if @_;
    return $self->undefify unless defined;
    $_ = String::Tools::stringify($_) if ref;
    my $quote1 = $self->get('quote1');
    my ( $open, $close ) = $self->_get_delim( shift // $quote1 );

    $self = $self->set( encode => $self->get('encode1') );
    my $to_encode = $self->_to_encode( $open, $close );
    s/([$to_encode])/$self->_encode_char($1)/eg;

    if ( $quote1 ne $open ) {
        if ( $open =~ /\w/ ) {
            $open  = ' ' . $open;
            $close = ' ' . $close;
        }
        $open = $self->get('q1') . $open;
    }

    return sprintf '%s%s%s', $open, $_, $close;
}



### Scalar: double-quoted string ###


sub stringify2 {
    my $self = &self;
    local $_ = shift if @_;
    return $self->undefify unless defined;
    $_ = String::Tools::stringify($_) if ref;
    my $quote2 = $self->get('quote2');
    my ( $open, $close ) = $self->_get_delim( shift // $quote2 );

    my @sigils;
    if ( my $sigils = $self->get('sigils') ) {
        push @sigils, split //, $sigils;
    }

    # quote char(s), sigils, and backslash.
    $self = $self->set( encode => $self->get('encode2') );
    my $to_encode = $self->_to_encode( $open, $close, @sigils );
    s/([$to_encode])/$self->_encode_char($1)/eg;

    if ( $quote2 ne $open ) {
        if ( $open =~ /\w/ ) {
            $open  = ' ' . $open;
            $close = ' ' . $close;
        }
        $open = $self->get('q2') . $open;
    }

    return sprintf '%s%s%s', $open, $_, $close;
}



### Scalar: string ###


__PACKAGE__->set(
    # String options
    quote   => undef,   # Auto
    quote1  => "'",
    #_tr1    => q!tr\\'\\'\\!,
    quote2  => '"',
    #_tr2    => q!tr\\"\\"\\!,
    q1      => 'q',
    q2      => 'qq',
    sigils  => '$@',
    longstr => 1_000,
    encode1 => {
        0x5c => '\\\\',

        byte  => '\\%c',
    },
    encode2 => {
        map( { ord( eval qq!"$_"! ) => $_ } qw( \0 \a \b \t \n \f \r \e ) ),
        #0x00 => '\\0',
        #0x07 => '\\a',
        #0x08 => '\\b',
        #0x09 => '\\t',
        #0x0a => '\\n',
        #0x0c => '\\f',
        #0x0d => '\\r',
        #0x1b => '\\e',
        0x5c => '\\\\',

        also  => '[:cntrl:]',
        byte  => '\\x%02x',
        #utf   => 8,
        wide  => '\\x{%04x}',
        #vwide => '\\x{%06x}',
    },

    do {
        no warnings 'qw';
        # To silence the warnings:
        # Possible attempt to put comments in qw() list
        # Possible attempt to separate words with commas

        qpairs  => [ qw\ () <> [] {} \ ],
        qquotes => [
            # Punctuation, excluding ", ', \, and _
            qw\ ! # % & * + , - . / : ; = ? ^ | ~ $ @ ` \
        ],
    },
);


sub stringify {
    my $self = &self;
    local $_ = shift if @_;
    return $self->undefify unless defined;
    $_ = String::Tools::stringify($_) if ref;
    local $@ = undef;

    my ( $quote, $quote1, $quote2 ) = $self->get(qw( quote quote1 quote2 ));
    if ($quote) {
        return $self->stringify1($_) if $quote1 && $quote1 eq $quote;
        return $self->stringify2($_) if $quote2 && $quote2 eq $quote;
        Carp::croak("Bad setting for quote: $quote");
    }

    # Long strings or strings with special characters
    my $longstr = $self->get('longstr');
    my $encode2 = $self->get('encode2');
    my $also    = $encode2 && $encode2->{also};
    return $self->stringify2($_)
        if ( ( $longstr && $longstr < length() ) || ( $also && /[$also]/ ) );

    my $tr1 = $self->get('_tr1');
    $self = $self->set( _tr1 => $tr1 = "tr\\$quote1\\$quote1\\" )
        if ( not $tr1 );
    my $single_quotes = eval $tr1 // die $@;
    return $self->stringify1($_) unless $single_quotes;

    my ( $sigils, $tr2 ) = $self->get(qw( sigils _tr2 ));
    $self = $self->set( _tr2 => $tr2 = "tr\\$quote2$sigils\\$quote2$sigils\\" )
        if ( not $tr2 );
    my $double_quotes = eval $tr2 // die $@;
    return $self->stringify2($_) unless $double_quotes;

    return $self->stringify1( $_, $self->_find_q($_) );
}



### Scalar: number ###
# Adapted from Perl FAQ "How can I output my numbers with commas added?"


__PACKAGE__->set(
    # Number options
    infinite  => "'inf'",
    -infinite => "'-inf'",
    nonnumber => "'nan'",
    num_sep   => '_',
);


sub is_numeric {
    my $self = &self;
    local $_ = shift if @_;

    return undef unless defined;

    if (ref) {
        if ( my $method = $self->overloaded($_) ) {
            $_ = $_->$method();
        }
        else {
            return '';
        }
    }

    # The "defined" ensures that we're not considering nan,
    # and the tests against inf/-inf ensure that those are rejected
    # (even though looks_like_number considers them valid)
    return Scalar::Util::looks_like_number($_)
        && defined( $_ <=> 0 )
        && $_ !=  'inf'
        && $_ != '-inf';
}


sub numify {
    my $self = &self;
    local $_ = shift if @_;

    return $self->undefify unless defined;

    if ( $self->is_numeric($_) ) {
        return $_ unless my $sep = $self->get('num_sep');

        # Fractional portion
                s{^(\s*[-+]?\d*\.\d\d)(\d+)}              [${1}$sep${2}];
        1 while s{^(\s*[-+]?\d*\.(?:\d+$sep)+\d\d\d)(\d+)}[${1}$sep${2}];

        # Whole portion
        1 while s{^(\s*[-+]?\d+)(\d{3})}                  [${1}$sep${2}];

        return $_;
    }
    elsif ( Scalar::Util::looks_like_number($_) ) {
        return
              $_ ==  'inf'        ? $self->get('infinite')
            : $_ == '-inf'        ? $self->get('-infinite')
            : defined( $_ <=> 0 ) ? $_
            :                       $self->get('nonnumber');
    }

    return $self->get('nonnumber');
}



### Scalar ###


__PACKAGE__->set(
    # Scalar options
    scalar_ref  => '\do{1;$_}',
);


sub scalarify {
    my $self = &self;
    local $_ = shift if @_;

    my $value = $self->_cache_get($_) // $self->_scalarify($_);
    $self->isa( scalar caller )
        ? $self->_cache_add( $_ => $value )
        : $self->_cache_reset($_);
    return $value;
}

sub _scalarify {
    my $self = &self;
    local $_ = shift if @_;

    return $self->undefify unless defined $_;

    if ( defined( my $blessed = Scalar::Util::blessed($_) ) ) {
        return
              $blessed eq 'Regexp' ? $self->regexpify($_)
            :                        $self->objectify($_);
    }

    my $ref = Scalar::Util::reftype $_;
    if ( not $ref ) {
        # Handle GLOB, LVALUE, and VSTRING
        my $ref2 = ref \$_;
        return
              $ref2 eq 'GLOB'    ? $self->globify($_)
            : $ref2 eq 'LVALUE'  ? $self->lvalueify($_)
            : $ref2 eq 'VSTRING' ? $self->vstringify($_)
            : $ref2 eq 'SCALAR'  ? (
                Scalar::Util::looks_like_number($_)
                    ? $self->numify($_)
                    : $self->stringify($_)
            )
            : $self->stringify($_);
    }

    return
          $ref eq 'ARRAY'  ? $self->arrayify(@$_)
        : $ref eq 'CODE'   ? $self->codeify($_)
        : $ref eq 'FORMAT' ? $self->formatify($_)
        : $ref eq 'HASH'   ? $self->hashify($_)
        : $ref eq 'IO'     ? $self->ioify($_)
        : $ref eq 'REF'    ? $self->refify($$_)
        : $ref eq 'REGEXP' ? $self->regexpify($_)        # ???
        : do {
            my $reference = $self->get( lc($ref) . '_reference' )
                ||          $self->get('reference');

              $ref eq 'GLOB'    ? _subst( $reference, $self->globify($$_) )
            : $ref eq 'LVALUE'  ? _subst( $reference, $self->lvalueify($$_) )
            : $ref eq 'SCALAR'  ? _subst( $reference, $self->scalarify($$_) )
            : $ref eq 'VSTRING' ? _subst( $reference, $self->vstringify($$_) )
            :                                         $self->objectify($_)
            ;
        };
}



### Scalar: LValue ###


__PACKAGE__->set(
    # LValue options
    lvalue  => 'substr($lvalue, 0)',
);


sub lvalueify {
    my $self = &self;
    return _subst( $self->get('lvalue'), lvalue => $self->stringify(shift) );
}



### Scalar: VString ###


__PACKAGE__->set(
    # VString options
    vformat => 'v%vd',
    #vformat => 'v%*vd',
    #vsep    => '.',
);


sub vstringify {
    my $self = &self;
    if ( defined( my $vsep = $self->get('vsep') ) ) {
        return sprintf $self->get('vformat'), $vsep, shift;
    } else {
        return sprintf $self->get('vformat'), shift;
    }
}



### Regexp ###


__PACKAGE__->set(
    # Regexp options
    quote3  => '/',
    #_tr3    => q!tr\\/\\/\\!,
    q3      => 'qr',

    encode3 => {
        map( { ord( eval qq!"$_"! ) => $_ } qw( \0 \a \t \n \f \r \e ) ),
        #0x00 => '\\0',
        #0x07 => '\\a',
        #0x09 => '\\t',
        #0x0a => '\\n',
        #0x0c => '\\f',
        #0x0d => '\\r',
        #0x1b => '\\e',

        also  => '[:cntrl:]',
        byte  => '\\x%02x',
        wide  => '\\x{%04x}',
        #vwide => '\\x{%06x}',
    },
);


sub regexpify {
    my $self = &self;
    local $_ = shift if @_;
    local $@ = undef;

    my ( $quote3, $tr3 ) = $self->get(qw( quote3 _tr3 ));
    $self = $self->set( _tr3 => $tr3 = "tr\\$quote3\\$quote3\\" )
        if ( not $tr3 );
    my $quoter = eval $tr3 // die $@;
    my ( $open, $close )
        = $self->_get_delim(
            shift // $quoter ? $self->_find_q($_) : $self->get('quote3') );

    # Everything but the quotes should be escaped already.
    $self = $self->set( encode => $self->get('encode3') );
    my $to_encode = $self->_to_encode( $open, $close );
    s/([$to_encode])/$self->_encode_char($1)/eg;

    if ( $open =~ /\w/ ) {
        $open  = ' ' . $open;
        $close = ' ' . $close;
    }

    $open = $self->get('q3') . $open;

    return sprintf '%s%s%s', $open, $_, $close;
}



### List/Array ###


sub listify {
    my $self = &self;
    my @values;
    for ( my $i = 0; $i < @_; $i++ ) {
        my $value = $_[$i];
        $self = $self->_push_position("[$i]");
        push @values, $self->scalarify($value);
        $self->_pop_position;
    }
    return join( $self->get('list_sep'), @values );
}




__PACKAGE__->set(
    # Array options
    array_ref   => '[$_]',
);


sub arrayify {
    my $self = &self;
    return _subst( $self->get('array_ref'), $self->listify(@_) );
}



### Hash ###


sub is_keyword {
    my $self = &self;

    my $keyword_set = $self->get('keyword_set');
    if ( not $keyword_set ) {
        my $keywords = $self->get('keywords') // [];
        return unless @$keywords;
        $keyword_set = { map { $_ => 1 } @$keywords };
        $self->{keyword_set} = $keyword_set;
    }
    return exists $keyword_set->{ +shift };
}


sub keyify {
    my $self = &self;
    local $_ = shift if @_;

    return $self->undefify unless defined;
    return $_ if ref;

    if ( $self->is_numeric($_) ) {
        return $self->numify($_);
    } elsif ( length() < $self->get('longstr')
        && !$self->is_keyword($_)
        && /\A-?[[:alpha:]_]\w*\z/ )
    {
        # If the key would be autoquoted by the fat-comma (=>),
        # then there is no need to quote it.

        return "$_"; # Make sure it's stringified.
    }
    return $self->stringify($_);
}




sub keysort($$);
BEGIN {
    no warnings 'qw';
    my $keysort = String::Tools::stitch(qw(
        sub keysort($$) {
            my ( $a, $b ) = @_;
            my $numa = Datify->is_numeric($a);
            my $numb = Datify->is_numeric($b);
            return
                  $numa && $numb ? $a <=> $b
                : $numa          ? -1
                :          $numb ?        +1
                :                  $a_cmp__b
                ;
        }
    ));
    my $a_cmp__b
        = ( $^V >= v5.16.0 ? 'CORE::fc($a) cmp CORE::fc($b) || ' : '' )
        . '$a cmp $b';
    $keysort = String::Tools::subst( $keysort, a_cmp__b => $a_cmp__b );
    eval($keysort) or $@ and die $@;
}



sub hashkeys {
    my $self = shift;
    my $hash = shift;

    my @keys = keys %$hash;
    if ( my $ref = ref( my $keyfilter = $self->get('keyfilter') ) ) {
        my $keyfilternot     = !$self->get('keyfilterdefault');
        my $keyfilterdefault = !$keyfilternot;
        if ( $ref eq 'ARRAY' || $ref eq 'HASH' ) {
            my %keyfilterhash
                = $ref eq 'ARRAY'
                ? ( map { $_ => $keyfilternot } @$keyfilter )
                : %$keyfilter;
            $self->{keyfilter} = $keyfilter = sub {
                exists $keyfilterhash{$_}
                    ? $keyfilterhash{$_}
                    : $keyfilterdefault;
            };
        } elsif ( $ref eq 'CODE' ) {
            # No-op, just use the code provided
        } elsif ( $ref eq 'Regexp' ) {
            my $keyfilterregexp = $keyfilter;
            $self->{keyfilter} = $keyfilter = sub {
                m/$keyfilterregexp/ ? $keyfilternot : $keyfilterdefault;
            };
        } elsif ( $ref eq 'SCALAR' ) {
            my $keyfiltervalue = $$keyfilter;
            $self->{keyfilter} = $keyfilter = sub {$keyfiltervalue};
        }
        @keys = grep { $keyfilter->() } @keys;
    }
    if ( my $keysort = $self->get('keysort') ) {
        @keys = sort $keysort @keys;
    }
    return @keys;
}

sub hashkeyvals {
    my $self = shift;
    my $hash = shift;

    return map { $_ => $hash->{$_} } $self->hashkeys($hash);
}


sub pairify {
    my $self = &self;
    if (1 == @_) {
        my $ref = Scalar::Util::reftype $_[0];
        if    ( $ref eq 'ARRAY' ) { @_ = @{ +shift } }
        elsif ( $ref eq 'HASH' )  { @_ = $self->hashkeyvals(shift) }
    }
    # Use for loop in order to preserve the order of @_,
    # rather than each %{ { @_ } }, which would mix-up the order.
    my @list;
    my $pair = $self->get('pair');
    for ( my $i = 0; $i < @_ - 1; $i += 2 ) {
        my ( $k, $v ) = @_[ $i, $i + 1 ];
        my $key = $self->keyify($k);
        $self = $self->_push_position("{$key}");
        my $val = $self->scalarify($v);
        $self->_pop_position;
        push @list, _subst( $pair, key => $key, value => $val );
    }
    return join( $self->get('list_sep'), @list );
}




__PACKAGE__->set(
    # Hash options
    hash_ref         => '{$_}',
    pair             => '$key => $value',
    keysort          => \&Datify::keysort,
    keyfilter        => undef,
    keyfilterdefault => 1,
    keywords         => [qw(undef)],
    #keyword_set      => { 'undef' => 1 },
);


sub hashify  {
    my $self = &self;
    return _subst( $self->get('hash_ref'), $self->pairify(@_) );
}



### Objects ###


sub overloaded {
    my $self   = &self;
    my $object = @_ ? shift : $_;

    return unless defined( Scalar::Util::blessed($object) )
        && overload::Overloaded($object);

    my $overloads = $self->get('overloads') || [];
    foreach my $overload (@$overloads) {
        if ( my $method = overload::Method( $object => $overload ) ) {
            return $method;
        }
    }
    return;
}




__PACKAGE__->set(
    # Object options
    overloads => [ '""', '0+' ],
    object    => 'bless($data, $class_str)',
    #object    => '$class->new($data)',
    #object    => '$class=$data',
);


sub objectify {
    my $self   = &self;
    my $object = @_ ? shift : $_;

    return $self->scalarify($object)
        unless defined( my $class = Scalar::Util::blessed($object) );

    my $data;
    if (0) {
    } elsif ( my $code = $self->_find_handler($class) ) {
        return $self->$code($object);
    } elsif ( my $method = $self->overloaded($object) ) {
        $data = $self->scalarify( $object->$method() );
    } elsif ( my $attrkeyvals = $object->can('_attrkeyvals') ) {
        # TODO: Look this up via meta-objects
        $data = $self->hashify( $object->$attrkeyvals() );
    } else {
        $data = Scalar::Util::reftype $object;

        $data
            = $data eq 'ARRAY'  ? $self->arrayify( @$object )
            : $data eq 'CODE'   ? $self->codeify(   $object )
            : $data eq 'FORMAT' ? $self->formatify( $object )
            : $data eq 'GLOB'   ? $self->globify(   $object )
            : $data eq 'HASH'   ? $self->hashify(   $object )
            : $data eq 'IO'     ? $self->ioify(     $object )
            : $data eq 'REF'    ? $self->refify(   $$object )
            : $data eq 'REGEXP' ? $self->regexpify( $object )
            : $data eq 'SCALAR' ? $self->refify(   $$object )
            :                     "*UNKNOWN{$data}";
    }

    return _subst(
        $self->get('object'),
        class_str => $self->stringify($class),
        class     => $class,
        data      => $data
    );
}



### Objects: IO ###


__PACKAGE__->set(
    # IO options
    io => '*$name{IO}',
);



sub ioify {
    my $self = &self;
    my $io   = @_ ? shift : $_;

    my $ioname = 'UNKNOWN';
    foreach my $ioe (qw( IN OUT ERR )) {
        no strict 'refs';
        if ( *{"main::STD$ioe"}{IO} == $io ) {
            $ioname = "STD$ioe";
            last;
        }
    }
    # TODO
    #while ( my ( $name, $glob ) = each %main:: ) {
    #    no strict 'refs';
    #    if ( defined( *{$glob}{IO} ) && *{$glob}{IO} == $io ) {
    #        keys %main::; # We're done, so reset each()
    #        $ioname = $name;
    #        last;
    #    }
    #}
    return _subst( $self->get('io'), name => $ioname );
}



### Other ###


__PACKAGE__->set(
    # Code options
    code     => 'sub {$body}',
    codename => '\&$codename',
    body     => '...',
);


sub codeify {
    my $self = &self;

    my $template = $self->get('code');
    my %data     = ( body => $self->get('body') );
    if ( @_ && defined( $_[0] ) ) {
        local $_ = shift;
        if ( my $ref = Scalar::Util::reftype($_) ) {
            if ( $ref eq 'CODE' ) {
                if ( ( my $subname = Sub::Util::subname($_) )
                    !~ /\A(?:\w+\::)*__ANON__\z/ )
                {
                    $template = $self->get('codename') // $template;
                    %data = ( codename => $subname );
                }
            } else {
                %data = ( body => $self->scalarify($_) );
            }
        } else {
            %data = ( body => $_ );
        }
    }
    return _subst( $template, %data );
}




__PACKAGE__->set(
    # Reference options
    reference   => '\\$_',
    dereference => '$referent->$place',
    nested      => '$referent$place',
);


sub refify    {
    my $self = &self;
    local $_ = shift if @_;
    return _subst( $self->get('reference'), $self->scalarify($_) );
}




__PACKAGE__->set(
    # Format options
    format  => "format UNKNOWN =\n.\n",
);


sub formatify {
    my $self = &self;
    #Carp::croak "Unhandled type: ", ref shift;
    return $self->get('format');
}




sub globify   {
    my $self = &self;
    my $name = '' . shift;
    if ( $name =~ /^\*$package\::(?:$word|$digits)?$/ ) {
        $name =~ s/^\*main::/*::/;
    } else {
        $name =~ s/^\*($package\::.+)/'*{' . $self->stringify($1) . '}'/e;
    }
    return $name;
}



sub beautify {
    my $self = &self;
    my ( $method, @params ) = @_;

    $method = $self->can($method) || die "Cannot $method";

    if ( my $beauty = $self->get('beautify') ) {
        return $beauty->( $self->$method(@params) );
    } else {
        return $self->$method(@params);
    }
}

### Private Methods & Settings ###
### Do not use these methods & settings outside of this package,
### they are subject to change or disappear at any time.
sub class {
    return scalar caller unless @_;
    my $caller = caller;
    my $class;
    if ( defined( $class = Scalar::Util::blessed( $_[0] ) )
        || ( !ref( $_[0] ) && length( $class = $_[0] ) ) )
    {
        if ( $class->isa($caller) ) {
            shift;
            return $class;
        }
    }
    return $caller;
}
sub self {
    my $self = shift;
    return defined( Scalar::Util::blessed($self) ) ? $self : $self->new();
}
sub _internal { return $_[0]->isa( scalar caller( 1 + ( $_[1] // 0 ) ) ) }
sub _private {
    Carp::croak('Illegal use of private method') unless $_[0]->_internal(1);
}
sub _settings() {
    &_private;
    \state %SETTINGS;
}

sub _nameify {
    local $_ = shift if @_;
    s/::/_/g;
    return lc() . 'ify';
}
sub _find_handler {
    my $self  = shift;
    my $class = shift;

    my $isa = mro::get_linear_isa($class);
    foreach my $c (@$isa) {
        next unless my $code = $self->can( _nameify($c) );
        return $code;
    }
    return;
}

sub _subst {
    die "Cannot subst on an undefined value"
        unless defined $_[0];
    goto &String::Tools::subst;
}

sub _get_delim {
    my $self = shift;
    my $open = shift;

    my $close;
    if ( 1 < length $open ) {
        my $qpairs = $self->get('qpairs') || [];
        my %qpairs = map { $_ => 1 } @$qpairs;
        if ( $qpairs{$open} ) {
            ( $open, $close ) = split //, $open, 2;
        } else {
            ( $open ) = split //, $open, 1
        }
    }
    $close = $open unless $close;

    return $open, $close;
}

sub _to_encode {
    my $self   = shift;

    my $encode = $self->get('encode');

    # Ignore the settings for byte, byte2, byte3, byte4, vwide, wide,
    # and utf
    my @encode
        = grep { !(/\A(?:also|byte[234]?|v?wide|utf)\z/) } keys(%$encode);

    my @ranges = ( $encode->{also} // () );
    foreach my $element (@_) {
        if ( Scalar::Util::looks_like_number($element) ) {
            push @encode, $element;
        } elsif ( length($element) == 1 ) {
            # An actual character, lets get the ordinal value and use that
            push @encode, ord($element);
        } else {
            # Something longer, it must be a range of chars,
            # like [:cntrl:], \x00-\x7f, or similar
            push @ranges, $element;
        }
    }
    @encode = map {
        # Encode characters in their \xXX or \x{XXXX} notation,
        # to get the literal values
        sprintf( $_ <= 255 ? '\\x%02x' : '\\x{%04x}', $_ )
    } sort {
        $a <=> $b
    } @encode;

    return join( '', @encode, @ranges );
}

sub _encode_ord2utf16 {
    my $self = shift;
    my $ord  = shift;

    my $encode = $self->get('encode');
    my $format = $encode->{wide};
    my @wides  = ();
    if (0) {
    } elsif ( 0x0000 <= $ord && $ord <= 0xffff ) {
        if ( 0xd800 <= $ord && $ord <= 0xdfff ) {
            die "Illegal character $ord";
        }

        @wides = ( $ord );
    } elsif ( 0x01_0000 <= $ord && $ord <= 0x10_ffff ) {
        $format = $encode->{vwide} || $format x 2;

        $ord -= 0x01_0000;
        my $ord2 = 0xdc00 + ( 0x3ff & $ord );
        $ord >>= 10;
        my $ord1 = 0xd800 + ( 0x3ff & $ord );
        @wides = ( $ord1, $ord2 );
    } else {
        die "Illegal character $ord";
    }
    return sprintf( $format, @wides );
}
sub _encode_ord2utf8 {
    my $self = shift;
    my $ord  = shift;

    my @bytes  = ();
    my $format = undef;

    my $encode = $self->get('encode');
    if (0) {
    } elsif (      0x00 <= $ord && $ord <=      0x7f ) {
        # 1 byte represenstation
        $format = $encode->{byte};
        @bytes  = ( $ord );
    } elsif (    0x0080 <= $ord && $ord <=    0x07ff ) {
        # 2 byte represenstation
        $format = $encode->{byte2} || $format x 2;

        my $ord2 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord1 = 0xc0 + ( 0x1f & $ord );
        @bytes = ( $ord1, $ord2 );
    } elsif (    0x0800 <= $ord && $ord <=    0xffff ) {
        if (     0xd800 <= $ord && $ord <=    0xdfff ) {
            die "Illegal character $ord";
        }

        # 3 byte represenstation
        $format = $encode->{byte3} || $format x 3;

        my $ord3 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord2 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord1 = 0xe0 + ( 0x0f & $ord );
        @bytes = ( $ord1, $ord2, $ord3 );
    } elsif ( 0x01_0000 <= $ord && $ord <= 0x10_ffff ) {
        # 4 byte represenstation
        $format = $encode->{byte4} || $format x 4;

        my $ord4 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord3 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord2 = 0x80 + ( 0x3f & $ord );
        $ord >>= 6;
        my $ord1 = 0xf0 + ( 0x07 & $ord );
        @bytes = ( $ord1, $ord2, $ord3, $ord4 );
    } else {
        die "Illegal character $ord";
    }
    return sprintf( $format, @bytes );
}
sub _encode_char {
    my $self = shift;
    my $ord  = ord shift;

    my $encode = $self->get('encode');
    my $utf    = $encode->{utf} // 0;
    if ( defined $encode->{$ord} ) {
        return $encode->{$ord};
    } elsif ( $utf == 8 ) {
        return $self->_encode_ord2utf8( $ord );
    } elsif ( $utf == 16 ) {
        return $self->_encode_ord2utf16( $ord );
    } elsif ( $ord <= 255 ) {
        return sprintf $encode->{byte}, $ord;
    } elsif ( $ord <= 65_535 ) {
        my $encoding = $encode->{wide} // $encode->{byte};
        return sprintf $encoding, $ord;
    } else {
        my $encoding = $encode->{vwide} // $encode->{wide} // $encode->{byte};
        return sprintf $encoding, $ord;
    }
}

# Find a good character to use for delimiting q or qq.
sub _find_q {
    my $self = shift;
    local $_ = shift if @_;

    my %counts;
    $counts{$_}++ foreach /([[:punct:]])/g;
    #$counts{$_}++ foreach grep /[[:punct:]]/, split //;
    my $qpairs = $self->get('qpairs') || [];
    foreach my $pair (@$qpairs) {
        $counts{$pair}
            = List::Util::sum 0,
                grep defined,
                    map { $counts{$_} }
                        split //, $pair;
    }

    return List::Util::reduce {
        ( ( $counts{$a} //= 0 ) <= ( $counts{$b} //= 0 ) ) ? $a : $b
    } @{ $self->get('qpairs') }, @{ $self->get('qquotes') };
}
sub _push_position {
    my $self     = shift;
    my $position = shift;
    push @{ $self->{_position} //= [] }, $position;
    return $self;
}
sub _pop_position {
    my $self = shift;
    return pop @{ $self->{_position} };
}
sub _cache_position {
    my $self = shift;

    my $nest = $self->get('nested') // $self->get('dereference');
    my $pos  = List::Util::reduce(
        sub { _subst( $nest, referent => $a, place => $b ) },
            @{ $self->{_position} //= [] }
    );

    my $var = $self->get('name');
    my $sigil = length $var ? substr $var, 0, 1 : '';
    if ( $sigil eq '@' || $sigil eq '%' ) {
        if ($pos) {
            $var = sprintf '$%s%s', substr($var, 1), $pos;
        } else {
            $var = _subst( $self->get('reference'), $var );
        }
    } elsif ($pos) {
        $var = _subst(
            $self->get('dereference') // $self->get('nested'),
            referent => $var,
            place    => $pos
        );
    }
    return $var;
}

__PACKAGE__->set(
    # _caching options
    _cache_hit => 0,
);
sub _cache_add {
    my $self  = shift;
    my $ref   = shift;
    my $value = shift;

    return $self unless my $refaddr = Scalar::Util::refaddr $ref;
    my $_cache = $self->{_cache} //= {};
    my $entry = $_cache->{$refaddr} //= [ $self->_cache_position ];
    push @$entry, $value if @$entry == $self->get('_cache_hit');

    return $self;
}
sub _cache_get {
    my $self = shift;
    my $item = shift;

    return unless my $refaddr = Scalar::Util::refaddr $item;

    my $_cache = $self->{_cache} //= {};
    if ( my $entry = $_cache->{$refaddr} ) {
        my $repr = $self->get('_cache_hit');
        return $entry->[$repr]
            // Carp::croak 'Recursive structures not allowed at ',
                           $self->_cache_position;
    } else {
        # Pre-populate the cache, so that we can check for loops
        $_cache->{$refaddr} = [ $self->_cache_position ];
        return;
    }
}
sub _cache_reset {
    my $self = shift;
    %{ $self->{_cache} //= {} } = ();
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Datify - Simple stringification of data.

=head1 SYNOPSIS

 use Datify;

 my $datify = Datify->new( ... );   # See OPTIONS below
 $datify = $datify->set( ... );     # See OPTIONS below

 print $datify->varify( data => [...] ), "\n";  # "@data = (...);\n"

 # Or

 Datify->set( ... );                # See OPTIONS below
 print Datify->varify( data => [...] ), "\n";
 # "@data = (...);\n"

=head1 DESCRIPTION

C<Datify> is very similar to L<Data::Dumper>,
except that it's easier to use, and has better formatting and options.

=head1 OPTIONS

=head2 Varify options

=over

=item I<name>       => B<'$self'>

The name of the default variable.
This is also set as the first parameter to C<varify>.

=item I<assign>     => B<'$var = $value;'>

What an assignment statement should look like.  If the generated code
is to be run under C<use strict;>, then you may want to change this to
C<'my $var = $value;'>.

=item I<list>       => B<'($_)'>

The delimiters for a list.

=item I<list_sep>    => B<', '>

The separator between list elements.

=item I<beautify>   => B<undef>

Set this to a C<CODE> reference that you would like to use to beautify
the code.  It should accept the code as the first parameter, process it,
and return the code after all the beauty modifications have been completed.

An example:

 use Datify;
 use Perl::Tidy;

 sub beautify {
     my $source = shift;

     my ($dest, $stderr);
     Perl::Tidy::perltidy(
         argv => [ qw(
             --perl-best-practices
             --noprofile
             --nostandard-output
             --standard-error-output
             --nooutdent-long-lines
         ) ],
         source      => \$source,
         destination => \$dest,
         stderr      => \$stderr,
         errorfile   => \$stderr,
     ) && die $stderr;

     return $dest;
 }

 Datify->set( beautify => \&beautify );

 say Datify->varify( var => $var );

=back

=head2 Undefify options

=over

=item I<null> => B<'undef'>

What to use as the null value.

=back

=head2 Booleanify options

=over

=item I<true>    => B<1>

=item I<false>   => B<"''">

What to use as the values for C<true> and C<false>, respectively.
Since Perl does not have native boolean values, these are placeholders.

=back

=head2 Stringify options

=over

=item I<quote>   => B<undef>

What to use as the default quote character.
If set to a false value, then use the best guess.
See L</stringify( value )>.

=item I<quote1>  => B<"'">

The default single-quoting character.

=item I<quote2>  => B<'"'>

The default double-quoting character.

=item I<q1>      => B<'q'>

The special single-quoting character starter.

=item I<q2>      => B<'qq'>

The special double-quoting character starter.

=item I<sigils>  => B<'$@'>

The characters in a double quoted sting that need to be quoted,
or they may be interpreted as variable interpolation.

=item I<longstr> => B<1_000>

How long a string needs to be before it's considered long.
See L</stringify( value )>.
Change to a false value to indicate no string is long.
Change to a negative value to indicate every string is long.

=item I<encode1>  => B<{ ... }>

=over

=item I<92>   => B<'\\\\'>

=item I<byte> => B<'\\%c'>

=back

=item I<encode2>  => B<{ ... }>

=over

=item I<0>    => B<'\0'>

=item I<7>    => B<'\a'>

=item I<8>    => B<'\b'>

=item I<9>    => B<'\t'>

=item I<10>   => B<'\n'>

=item I<12>   => B<'\f'>

=item I<13>   => B<'\r'>

=item I<27>   => B<'\e'>

=item I<92>   => B<'\\\\'>

=item I<also> => B<'[:cntrl:]'>

=item I<byte> => B<'\x%02x'>

=item I<wide> => B<'\x{%04x}'>

=back

How to encode characters that need encoding.

=over

=item I<number> => B<'encoding'>

Encode the character with ordinal C<number> as C<'encoding'>.

=item I<also>   => B<'[:cntrl:]'>

Encode this range of characters, too.

=item I<byte>   => B<'\x%02x'>

Encode characters that do not otherwise have an encoding
with this C<sprintf> expression.

=item I<byte2>  => B<undef>

Used to encode 2 byte UTF-8 sequences.
If unset, then 2-byte sequences are encoded by using they C<byte>
encoding twice.

=item I<byte3>  => B<undef>

Used to encode 3 byte UTF-8 sequences.
If unset, then 3-byte sequences are encoded by using they C<byte>
encoding three times.

=item I<byte4>  => B<undef>

Used to encode 4 byte UTF-8 sequences.
If unset, then 4-byte sequences are encoded by using they C<byte>
encoding four times.

=item I<utf>    => B<undef>

Use the internal encoding routines to encode characters.
Set it to C<8> to encode as UTF-8,
or set it to C<16> to encode as UTF-16.

=item I<vwide>  => B<undef>

Encode very wide characters that do not otherwise have an encoding
with this C<sprintf> expression.  If unset, then very wide characters
are encoded with C<wide> twice.

=item I<wide>   => B<'\x{%04x}'>

Encode wide characters that do not otherwise have an encoding
with this C<sprintf> expression.

=back

=item I<qpairs>  => B<< [ qw\ () <> [] {} \ ] >>

=item I<qquotes> => B<[ qw\ ! # % & * + , - . / : ; = ? ^ | ~ $ @ ` \ ]>

When determining the quote character to use, go through these lists to see
which character would work best.

=back

=head2 Numify options

=over

=item I<infinite>  => B<"'inf'">

What to use to indicate infinity.

=item I<-infinite>  => B<"'-inf'">

What to use to indicate negative infinity.

=item I<nonnumber> => B<"'nan'">

What to use to indicate this is not a number.

=item I<num_sep>   => B<'_'>

What character to use to seperate sets of numbers.

=back

=head2 Scalarify options

=over

=item I<scalar_ref>  => B<'\do{1;$_}'>

How to generate a reference to a scalar.

=back

=head2 LValueify options

=over

=item I<lvalue>  => B<'substr($lvalue, 0)'>

How to generate a LValue.

=back

=head2 VStringify options

=over

=item I<vformat> => B<'v%vd'>

=item I<vsep>    => B<undef>

The formatting string to use.  If I<vsep> is set, then I<vformat> should use
the C<*> format to inidicate what I<vsep> will be:
C<< vformat => 'v%*vd', vsep => '.' >>.

=back

=head2 Regexpify options

=over

=item I<quote3>  => B<'/'>

=item I<q3>      => B<'qr'>

=item I<encode3>  => B<{ ... }>

=over

=item I<0>    => B<'\0'>

=item I<7>    => B<'\a'>

=item I<9>    => B<'\t'>

=item I<10>   => B<'\n'>

=item I<12>   => B<'\f'>

=item I<13>   => B<'\r'>

=item I<27>   => B<'\e'>

=item I<also> => B<'[:cntrl:]'>

=item I<byte> => B<'\x%02x'>

=item I<wide> => B<'\x{%04x}'>

=back

How to encode characters that need encoding.
See L<< /I<encode2>  => B<{ ... }> >>

=back

=head2 Arrayify options

=over

=item I<array_ref>   => B<'[$_]'>

The representation of an array reference.

=back

=head2 Hashify options

=over

=item I<hash_ref>         => B<'{$_}'>

The representation of a hash reference.

=item I<pair>             => B<< '$key => $value' >>

The representation of a pair.

=item I<keyfilter>        => B<undef>

A reference to an C<ARRAY>, C<CODE>, C<HASH>, C<Regexp>, or C<SCALAR>,
which will be converted to a the appropriate code, and used to filter
the keys in a hash via C<grep>.

C<ARRAY> entries are changed into a C<HASH>,
with the entries set to be the inverse of C<keyfilterdefault>.

C<CODE> entires should look for the key name in C<$_>,
and return a boolean value.

C<HASH> entries should have a true or false value,
to indicate if the entry should be included.

C<Regexp> entries are matched, and if true, then return the inverse of
C<$keyfilterdefault>.

C<SCALAR> entries treat all values according to the boolean evaluation.

=item I<keyfilterdefault> => B<1>

When filtering keys in a hash, if the key is not found in the C<keyfilter>
C<HASH> or C<ARRAY>, should it pass through or not?

=item I<keysort>          => B<\&Datify::keysort>

How to sort the keys in a hash.  This has a performance hit,
but it makes the output much more readable.  See the description of
L</keysort($$)>.

=item I<keywords>         => B<[qw(undef)]>

Any keywords that should be quoted, even though they may not need to be.

=back

=head2 Objectify options

=over

=item I<overloads>  => B<[ '""', '0+' ]>

The list of overloads to check for before deconstructing the object.
See L<overload> for more information on overloading.

=item I<object>     => B<'bless($data, $class_str)'>

The representation of an object.  Other possibilities include
C<'$class($data)'> or C<< '$class->new($data)' >>.

=back

=head2 IOify options

=over

=item I<io> => B<'*$name{IO}'>

The representation of unknown IO objects.

=back

=head2 Codeify options

=over

=item I<code>     => B<'sub {$_}'>

The representation of a code reference.  This module does not currently
support decompiling code to make a complete representation, but if passed
a representation, can wrap it in this.

=item I<codename> => B<'\&$_'>

The representation of a code reference by name.

=item I<body>     => B<'...'>

The representation of the body to a code reference.
This module does not currently support decompiling code to make a
complete representation.

=back

=head2 Refify options

=over

=item I<reference>   => B<'\\$_'>

The representation of a reference.

=item I<dereference> => B<< '$referent->$place' >>

The representation of dereferencing.

=item I<nested>      => B<'$referent$place'>

The representation of dereferencing a nested reference.

=back

=head2 Formatify options

=over

=item I<format>  => B<"format UNKNOWN =\n.\n">

The representation of a format.  This module does not currently support
showing the acutal representation.

=back

=head1 METHODS

=head2 C<< new( name => value, name => value, ... ) >>

Create a C<Datify> object with the following options.

See L</OPTIONS> for a description of the options and their default values.

=head2 exists( name, name, ... )

Determine if values exists for one or more settings.

Can be called as a class method or an object method.

=head2 C<get( name, name, ... )>

Get one or more existing values for one or more settings.
If passed no names, returns all parameters and values.

Can be called as a class method or an object method.

=head2 C<< set( name => value, name => value, ... ) >>

Change the L</OPTIONS> settings.
When called as a class method, changes default options.
When called as an object method, changes the settings and returns a
new object.

See L</OPTIONS> for a description of the options and their default values.

B<NOTE:> When called as a object method, this returns a new instance
with the values set, so you will need to capture the return if you'd like to
persist the change:

 $datify = $datify->set( ... );

=head2 C<< add_handler( $class => \&code_ref ) >>

Add a handler to handle an object of type C<$class>.
C<\&code_ref> should take two parameters,
a reference to Datify,
and the object to be Datify'ed.
It should return a representation of the object.

If C<$class> is unspecified, assumes that it's handling
for the package where C<add_handler> is called from.

 # Set URI's to stringify as "URI->new('http://example.com')"
 # instead of "bless(\'http://example.com', 'URI')"
 Datify->add_handler( 'URI' => sub {
     my ( $datify, $uri ) = @_;
     my $s = $datify->stringify("$uri");
     return "URI->new($s)";
 } );

=head2 C<< varify( name => value, value, ... ) >>

Returns an assignment statement for the values.  If C<name> does not begin
with a sigil (C<$>, C<@>, or C<%>), will determine which sigil to use based
on C<values>.

Some examples:

Common case, determine the type and add the correct sigil to 'foo'.

 Datify->varify(   foo  => $foo );

Specify the type.

 Datify->varify( '$foo' => $foo );

Handle a list: C<@foo = (1, 2, 3);>

 Datify->varify( '@foo' =>   1, 2, 3   );
 Datify->varify( '@foo' => [ 1, 2, 3 ] );
 Datify->varify(   foo  =>   1, 2, 3   );
 Datify->varify(   foo  => [ 1, 2, 3 ] );

Handle a hash: C<< %foo = (a => 1, b => 2, c => 3); >>
(B<Note>: Order may be rearranged.)

 Datify->varify( '%foo' =>   a => 1, b => 2, c => 3   );
 Datify->varify( '%foo' => { a => 1, b => 2, c => 3 } );
 Datify->varify(   foo  => { a => 1, b => 2, c => 3 } );

Keep in mind that without proper hints, this would be interpretted as a list,
not a hash:

 Datify->varify(   foo  =>   a => 1, b => 2, c => 3   );
 # "@foo = ('a', 1, 'b', 2, 'c', 3);"

=head2 C<undefify>

Returns the string that should be used for an undef value.

=head2 C<booleanify( value )>

Returns the string that represents the C<true> or C<false> interpretation
of C<value>.
Will return the value for C<undefify> if C<value> is not defined.

=head2 C<stringify1( value I<, delimiters> )>

Returns the string that represents value as a single-quoted string.
The delimiters parameter is optional.

=head2 C<stringify2( value I<, delimiters> )>

Returns the string that represents value as a double-quoted string.
The delimiters parameter is optional.

=head2 C<stringify( value )>

Returns the string the represents value.  It will be a double-quoted string
if it is longer than the C<longstr> option or contains control characters.
It will be a single-quoted string unless there are single-quotes within the
string, then it will be a double-quoted string, unless it also contains
double-quotes within the string, then it will attempt to find the best quote
character.

=head2 C<is_numeric( value )>

Returns true  if value is can be numeric,
returns false if the value is not numeric (including inf and nan),
returns undef if the value is undefined.

 Datify->is_numeric(1234.5678901);       #          true
 Datify->is_numeric("inf");              #          false
 Datify->is_numeric( "inf" / "inf" );    # "nan" => false
 Datify->is_numeric(undef);              #          undef

=head2 C<numify( value )>

Returns value with seperators between the hundreds and thousands,
hundred-thousands and millions, etc.  Similarly for the fractional parts.

 Datify->numify(1234.5678901);    # "1_234.56_789_01"

Also returns the string that should be used for the C<infinite>,
C<-infinite>, and C<nonnumber> values,
the C<null> value for undefined values,
and C<nonnumber> value for all not-a-numbers.

 Datify->numify('inf');              # 'inf'
 Datify->numify( 'inf' / 'inf' );    # 'nan'
 Datify->numify(undef);              # 'undef'
 Datify->numify('apple');            # 'nan'

=head2 C<scalarify( value )>

Returns value as a scalar.  If value is not a reference, performs some magic
to correctly print vstrings and numbers, otherwise assumes it's a string.
If value is a reference, hands off to the correct function to create
the string.

Handles reference loops.

=head2 C<lvalueify( value )>

Returns an approximate representation of what the lvalue is.

=head2 C<vstringify( value )>

A representation of the VString, in dotted notation.

=head2 C<regexpify( value, delimiters )>

A representation of the C<Regexp> in C<value>.

=head2 C<listify( value, value, ... )>

Returns value(s) as a list.

 Datify->listify( 1, 2, 3 );    # '1, 2, 3'

=head2 C<arrayify( value, value, ... )>

Returns value(s) as an array.

 Datify->arrayify( 1, 2, 3 );    # '[1, 2, 3]'

=head2 C<is_keyword( word )>

Checks if C<word> has been set in the
L<< /I<keywords>         => B<[qw(undef)]> >> list.

=head2 C<keyify( value )>

Returns value as a key.  If value does not need to be quoted, it will not be.
Verifies that value is not a keyword.

=head2 C<hashkeys( $hash )>

Returns the keys of a hash,
filtered (see L<< /I<keyfilter>        => B<undef> >>),
and sorted (see L</keysort>).

=head2 C<< pairify( value => value, ... ) >>

Returns value(s) as a pair.

 Datify->pairify( a => 1, b => 2 );    # 'a => 1, b => 2'

=head2 C<hashify( value, value, ... )>

Returns value(s) as a hash.

 Datify->hashify( a => 1, b => 2 );    # '{a => 1, b => 2}'

=head2 C<overloaded( $object )>

Returns the first method from the C<overloads> list that $object
has overloaded.  If nothing is overloaded, then return nothing.

=head2 C<objectify( value )>

Returns value as an object.  Tries several different ways to find the best
representation of the object.

If a handler has been defined for the object with
L</C<< add_handler( $class => \&code_ref ) >>>, then use that.
If the object has overloaded any of
L<< /I<overloads>  => B<[ '""', '0+' ]> >>, then use that to represent
the C<$data> portion of the object.
If the object has an C<_attrkeyvals> method,
then that will be used to gather the elements of the object.
If the object has none of those things, then the object is inspected
and handled appropriately.

 Datify->objectify($object);    # "bless({}, 'Object')"

=head2 C<ioify( value )>

Returns a representation of value that is accurate if C<value> is
STDIN, STDOUT, or STDERR.  Otherwise, returns the C<io> setting.

=head2 C<codeify( value )>

Returns a representation of a reference to a subroutine.
If C<value> is not a reference,
then uses that as the body of the anonymous subroutine.
If C<value> is a C<CODE> reference, does some introspection on it,
and expresses as a reference to the named subroutine,
or to a generic anonymous function.
If C<value> is another type of reference,
then expressed as an anonymous function returning that.
Otherwise, returns a generic anonymous function.

 Datify->codeify( 'return $_' );               # 'sub { return $_ }'
 Datify->codeify( \&MyModule::subroutine );    # '\&MyModule::subroutine'
 Datify->codeify( sub {"!"} );                 # 'sub { ... }'
 Datify->codeify( [1, 2, 3] );                 # 'sub { [1, 2, 3] }'

=head2 C<refify( value )>

Returns value as reference.

=head2 C<formatify( value )>

Returns a value that is not completely unlike value.

=head2 C<globify( value )>

Returns a representation of value.
For normal values, remove the leading C<main::>.

=head2 C<< beautify( ify => values ) >>

Calls L</beautify> on the output of the C<*ify> method with C<values>.

If there has been no C<beautify> method specified, returns the raw output
from the C<*ify> method.

    say( Datify->beauitfy( scalarify => $scalar ) );

=head1 FUNCTIONS

=head2 C<keysort($$)>

Not a method, but a sorting routine that sorts numbers (using C<< <=> >>)
before strings (using C<cmp>).

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/Datify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 TODO

=over

=item *

Handle formats better.

=back

=head1 SEE ALSO

L<Data::Dumper>

=head1 VERSION

This document describes version v0.20.045 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2019 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
