package Locales;

use strict;
use warnings;

use Module::Want 0.6;

$Locales::VERSION      = '0.34';    # change in POD
$Locales::cldr_version = '2.0';     # change in POD

$Locales::_UNICODE_STRINGS = 0;

sub import {
    my ( $c, %opt ) = @_;
    if ( exists $opt{unicode} ) {
        $Locales::_UNICODE_STRINGS = $opt{unicode};
    }
    return;
}

#### class methods ####

my %singleton_stash;

sub get_cldr_version {
    return $Locales::cldr_version;
}

sub new {
    my ( $class, $tag ) = @_;
    $tag = normalize_tag($tag) || 'en';

    if ( !exists $singleton_stash{$tag} ) {

        my $locale = {
            'locale' => $tag,
        };

        if ( my $soft = tag_is_soft_locale($tag) ) {

            # return if exists $conf->{'soft_locales'} && !$conf->{'soft_locales'};
            $locale->{'soft_locale_fallback'} = $soft;
            $tag = $soft;
        }

        my $inc_class = ref($class) ? ref($class) : $class;
        $inc_class =~ s{(?:\:\:|\')}{/}g;    # per Module::Want::get_inc_key()

        have_mod("$class\::DB::Language::$tag")  || return;
        have_mod("$class\::DB::Territory::$tag") || return;

        my ( $language, $territory ) = split_tag( $locale->{'locale'} );

        no strict 'refs';                    ## no critic

        $locale->{'language'}      = $language;
        $locale->{'language_data'} = {
            'VERSION'      => \${"$class\::DB::Language::$tag\::VERSION"},
            'cldr_version' => \${"$class\::DB::Language::$tag\::cldr_version"},
            'misc_info'    => \%{"$class\::DB::Language::$tag\::misc_info"},
            'code_to_name' => \%{"$class\::DB::Language::$tag\::code_to_name"},
            'name_to_code' => \%{"$class\::DB::Language::$tag\::name_to_code"},
        };

        $locale->{'territory'}      = $territory;
        $locale->{'territory_data'} = {
            'VERSION'      => \${"$class\::DB::Territory::$tag\::VERSION"},
            'cldr_version' => \${"$class\::DB::Territory::$tag\::cldr_version"},
            'code_to_name' => \%{"$class\::DB::Territory::$tag\::code_to_name"},
            'name_to_code' => \%{"$class\::DB::Territory::$tag\::name_to_code"},
        };

        $locale->{'misc'}{'list_quote_mode'} = 'none';

        $singleton_stash{$tag} = bless $locale, $class;
    }

    return $singleton_stash{$tag};
}

#### object methods ####

sub get_soft_locale_fallback {
    return $_[0]->{'soft_locale_fallback'} if $_[0]->{'soft_locale_fallback'};
    return;
}

sub get_locale { shift->{'locale'} }

sub get_territory { shift->{'territory'} }

sub get_language { shift->{'language'} }

sub get_native_language_from_code {
    my ( $self, $code, $always_return ) = @_;

    my $class = ref($self) ? ref($self) : $self;
    if ( !exists $self->{'native_data'} ) {
        have_mod("$class\::DB::Native") || return;
        no strict 'refs';    ## no critic
        $self->{'native_data'} = {
            'VERSION'      => \${"$class\::DB::Native::VERSION"},
            'cldr_version' => \${"$class\::DB::Native::cldr_version"},
            'code_to_name' => \%{"$class\::DB::Native::code_to_name"},
        };
    }

    $code ||= $self->{'locale'};
    $code = normalize_tag($code);
    return if !defined $code;

    $always_return ||= 1 if $code eq $self->get_locale() && $self->get_soft_locale_fallback();    # force $always_return under soft locale objects
    $always_return ||= 0;

    if ( exists $self->{'native_data'}{'code_to_name'}{$code} ) {
        return $self->{'native_data'}{'code_to_name'}{$code};
    }
    elsif ($always_return) {
        my ( $l, $t ) = split_tag($code);
        my $ln = $self->{'native_data'}{'code_to_name'}{$l};
        my $tn = defined $t ? $self->{'territory_data'}{'code_to_name'}{$t} : '';

        return $code if !$ln && !$tn;

        if ( defined $t ) {
            my $tmp = Locales->new($l);    # if we even get to this point: this is a singleton so it is cheap
            if ($tmp) {
                if ( $tmp->get_territory_from_code($t) ) {
                    $tn = $tmp->get_territory_from_code($t);
                }
            }
        }

        $ln ||= $l;
        $tn ||= $t;

        my $string = get_locale_display_pattern_from_code_fast($code) || $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'locale'} || '{0} ({1})';
        $string =~ s/\{0\}/$ln/g;
        $string =~ s/\{1\}/$tn/g;

        return $string;
    }
    return;
}

sub numf {
    my ( $self, $always_return ) = @_;
    my $class = ref($self) ? ref($self) : $self;
    $always_return ||= 0;
    $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'}   = '' if !defined $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'};
    $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} = '' if !defined $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'};

    if ( !$self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} || !$self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} ) {
        if ($always_return) {
            if ( $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} || !$self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} ) {
                return 2 if $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} eq '.';
                return 1;
            }
            elsif ( !$self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} || $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} ) {
                return 2 if $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} eq ',';
                return 1;
            }
            else {
                return 1;
            }
        }
    }

    if ( $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'decimal'} eq "\#\,\#\#0\.\#\#\#" ) {
        if ( $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} eq ',' && $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} eq '.' ) {
            return 1;
        }
        elsif ( $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} eq '.' && $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} eq ',' ) {
            return 2;
        }
    }
    elsif ( $always_return && $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} && $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} ) {
        return 2 if $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} eq ',';
        return 2 if $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} eq '.';
        return 1;
    }

    return [
        $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'decimal'},
        $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'},
        $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'},
    ];
}

my $get_locale_display_pattern_from_code_fast = 0;

sub get_locale_display_pattern_from_code_fast {
    if ( !$get_locale_display_pattern_from_code_fast ) {
        $get_locale_display_pattern_from_code_fast++;
        require Locales::DB::LocaleDisplayPattern::Tiny;
    }

    if ( @_ == 1 && ref( $_[0] ) ) {
        return Locales::DB::LocaleDisplayPattern::Tiny::get_locale_display_pattern( $_[0]->get_locale() );
    }
    return Locales::DB::LocaleDisplayPattern::Tiny::get_locale_display_pattern( $_[-1] );    # last arg so it works as function or class method or object method
}

sub get_locale_display_pattern_from_code {
    my ( $self, $code, $always_return ) = @_;

    my $class = ref($self) ? ref($self) : $self;
    if ( !exists $self->{'locale_display_pattern_data'} ) {
        have_mod("$class\::DB::LocaleDisplayPattern") || return;

        no strict 'refs';                                                                    ## no critic
        $self->{'locale_display_pattern_data'} = {
            'VERSION'         => \${"$class\::DB::LocaleDisplayPattern::VERSION"},
            'cldr_version'    => \${"$class\::DB::LocaleDisplayPattern::cldr_version"},
            'code_to_pattern' => \%{"$class\::DB::LocaleDisplayPattern::code_to_pattern"},
        };
    }

    $code ||= $self->{'locale'};
    $code = normalize_tag($code);
    return if !defined $code;

    $always_return ||= 1 if $code eq $self->get_locale() && $self->get_soft_locale_fallback();    # force $always_return under soft locale objects
    $always_return ||= 0;

    if ( exists $self->{'locale_display_pattern_data'}{'code_to_pattern'}{$code} ) {
        return $self->{'locale_display_pattern_data'}{'code_to_pattern'}{$code};
    }
    elsif ($always_return) {
        my ( $l, $t ) = split_tag($code);
        if ( exists $self->{'locale_display_pattern_data'}{'code_to_pattern'}{$l} ) {
            return $self->{'locale_display_pattern_data'}{'code_to_pattern'}{$l};
        }
        return '{0} ({1})';
    }
    return;
}

my $get_character_orientation_from_code_fast = 0;

sub get_character_orientation_from_code_fast {
    if ( !$get_character_orientation_from_code_fast ) {
        $get_character_orientation_from_code_fast++;
        require Locales::DB::CharacterOrientation::Tiny;
    }

    if ( @_ == 1 && ref( $_[0] ) ) {
        return Locales::DB::CharacterOrientation::Tiny::get_orientation( $_[0]->get_locale() );
    }

    return Locales::DB::CharacterOrientation::Tiny::get_orientation( $_[-1] );    # last arg so it works as function or class method or object method
}

sub get_character_orientation_from_code {
    my ( $self, $code, $always_return ) = @_;

    my $class = ref($self) ? ref($self) : $self;
    if ( !exists $self->{'character_orientation_data'} ) {
        have_mod("$class\::DB::CharacterOrientation") || return;

        no strict 'refs';                                                         ## no critic
        $self->{'character_orientation_data'} = {
            'VERSION'      => \${"$class\::DB::CharacterOrientation::VERSION"},
            'cldr_version' => \${"$class\::DB::CharacterOrientation::cldr_version"},
            'code_to_name' => \%{"$class\::DB::CharacterOrientation::code_to_name"},
        };
    }

    $code ||= $self->{'locale'};
    $code = normalize_tag($code);
    return if !defined $code;

    $always_return ||= 1 if $code eq $self->get_locale() && $self->get_soft_locale_fallback();    # force $always_return under soft locale objects
    $always_return ||= 0;

    if ( exists $self->{'character_orientation_data'}{'code_to_name'}{$code} ) {
        return $self->{'character_orientation_data'}{'code_to_name'}{$code};
    }
    elsif ($always_return) {
        my ( $l, $t ) = split_tag($code);
        if ( exists $self->{'character_orientation_data'}{'code_to_name'}{$l} ) {
            return $self->{'character_orientation_data'}{'code_to_name'}{$l};
        }
        return 'left-to-right';
    }
    return;
}

sub get_plural_form_categories {
    return @{ $_[0]->{'language_data'}{'misc_info'}{'plural_forms'}{'category_list'} };
}

sub supports_special_zeroth {
    return 1 if $_[0]->get_plural_form(0) eq 'other';
    return;
}

sub plural_category_count {
    return scalar( $_[0]->get_plural_form_categories() );
}

sub get_plural_form {
    my ( $self, $n, @category_values ) = @_;
    my $category;
    my $has_extra_for_zero = 0;

    # This negative value behavior makes sense but is not defined either way in the CLDR.
    # We've asked for clarification via http://unicode.org/cldr/trac/ticket/4049
    # If CLDR introduces negatives then the rule parser needs to factor in those new rules
    #     and also perl's modulus-on-negative-values behavior
    my $abs_n = abs($n);    # negatives keep same category as positive

    if ( !$self->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules_function'} ) {
        $self->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules_function'} = Locales::plural_rule_hashref_to_code( $self->{'language_data'}{'misc_info'}{'plural_forms'} );
        if ( !defined $self->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules_function'} ) {
            require Carp;
            Carp::carp("Could not determine plural logic.");
        }
    }

    $category = $self->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules_function'}->($abs_n);

    my @categories = $self->get_plural_form_categories();

    if ( !@category_values ) {

        # no args will return the category name
        @category_values = @categories;
    }
    else {
        my $cat_len = @categories;
        my $val_len = @category_values;
        if ( $val_len == ( $cat_len + 1 ) ) {
            $has_extra_for_zero++;
        }
        elsif ( $cat_len != $val_len && $self->{'verbose'} ) {
            require Carp;
            Carp::carp("The number of given values ($val_len) does not match the number of categories ($cat_len).");
        }
    }

    if ( !defined $category ) {
        my $cat_idx = $has_extra_for_zero && $abs_n != 0 ? -2 : -1;
        return wantarray ? ( $category_values[$cat_idx], $has_extra_for_zero && $abs_n == 0 ? 1 : 0 ) : $category_values[$cat_idx];
    }
    else {
      GET_POSITION:
        my $cat_pos_in_list;
        my $index = -1;
      CATEGORY:
        for my $cat (@categories) {
            $index++;
            if ( $cat eq $category ) {
                $cat_pos_in_list = $index;
                last CATEGORY;
            }
        }

        if ( !defined $cat_pos_in_list && $category ne 'other' ) {
            require Carp;
            Carp::carp("The category ($category) is not used by this locale.");
            $category = 'other';
            goto GET_POSITION;
        }
        elsif ( !defined $cat_pos_in_list ) {
            my $cat_idx = $has_extra_for_zero && $abs_n != 0 ? -2 : -1;
            return wantarray ? ( $category_values[$cat_idx], $has_extra_for_zero && $abs_n == 0 ? 1 : 0 ) : $category_values[$cat_idx];
        }
        else {
            if ( $has_extra_for_zero && $category eq 'other' ) {    # and 'other' is at the end of the list? nah...  && $cat_pos_in_list + 1 == $#category_values
                my $cat_idx = $has_extra_for_zero && $abs_n == 0 ? -1 : $cat_pos_in_list;
                return wantarray ? ( $category_values[$cat_idx], $has_extra_for_zero && $abs_n == 0 ? 1 : 0 ) : $category_values[$cat_idx];
            }
            else {
                return wantarray ? ( $category_values[$cat_pos_in_list], 0 ) : $category_values[$cat_pos_in_list];
            }
        }
    }
}

# pending http://unicode.org/cldr/trac/ticket/4051
sub get_list_or {
    my ( $self, @items ) = @_;

    # I told you it was stub in the changelog, POD, test, and here!
    $self->_quote_get_list_items( \@items );

    return                          if !@items;
    return $items[0]                if @items == 1;
    return "$items[0] or $items[1]" if @items == 2;

    my $last = pop(@items);
    return join( ', ', @items ) . ", or $last";
}

sub _quote_get_list_items {
    my ( $self, $items_ar ) = @_;

    my $cnt = 0;

    if ( exists $self->{'misc'}{'list_quote_mode'} && $self->{'misc'}{'list_quote_mode'} ne 'none' ) {
        if ( $self->{'misc'}{'list_quote_mode'} eq 'all' ) {
            @{$items_ar} = ('') if @{$items_ar} == 0;

            for my $i ( 0 .. scalar( @{$items_ar} ) - 1 ) {
                $items_ar->[$i] = '' if !defined $items_ar->[$i];
                $items_ar->[$i] = $self->quote( $items_ar->[$i] );
                $cnt++;
            }
        }
        elsif ( $self->{'misc'}{'list_quote_mode'} eq 'some' ) {
            @{$items_ar} = ('') if @{$items_ar} == 0;

            for my $i ( 0 .. scalar( @{$items_ar} ) - 1 ) {
                $items_ar->[$i] = '' if !defined $items_ar->[$i];
                if ( $items_ar->[$i] eq '' || $items_ar->[$i] =~ m/\A(?: |\xc2\xa0)+\z/ ) {
                    $items_ar->[$i] = $self->quote( $items_ar->[$i] );
                    $cnt++;
                }
            }
        }
        else {
            require Carp;
            Carp::carp('$self->{misc}{list_quote_mode} is set to an unknown value');
        }
    }

    return $cnt;
}

sub get_list_and {
    my ( $self, @items ) = @_;

    $self->_quote_get_list_items( \@items );

    return if !@items;
    return $items[0] if @items == 1;

    if ( @items == 2 ) {
        my $two = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'list'}{'2'};
        $two =~ s/\{([01])\}/$items[$1]/g;
        return $two;
    }
    else {
        @items = map { my $c = $_; $c =~ s/\{([01])\}/__\{__${1}__\}__/g; $c } @items;    # I know ick, patches welcome

        my $aggregate = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'list'}{'start'};
        $aggregate =~ s/\{([01])\}/$items[$1]/g;

        for my $i ( 2 .. $#items ) {
            next if $i == $#items;
            my $middle = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'list'}{'middle'};
            $middle =~ s/\{0\}/$aggregate/g;
            $middle =~ s/\{1\}/$items[$i]/g;
            $aggregate = $middle;
        }

        my $end = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'list'}{'end'};
        $end =~ s/\{0\}/$aggregate/g;
        $end =~ s/\{1\}/$items[-1]/g;

        $end =~ s/__\{__([01])__\}__/\{$1\}/g;    # See "I know ick, patches welcome" above

        return $end;
    }
}

sub quote {
    my ( $self, $value ) = @_;
    $value = '' if !defined $value;

    return $self->{'language_data'}{'misc_info'}{'delimiters'}{'quotation_start'} . $value . $self->{'language_data'}{'misc_info'}{'delimiters'}{'quotation_end'};
}

sub quote_alt {
    my ( $self, $value ) = @_;
    $value = '' if !defined $value;

    return $self->{'language_data'}{'misc_info'}{'delimiters'}{'alternate_quotation_start'} . $value . $self->{'language_data'}{'misc_info'}{'delimiters'}{'alternate_quotation_end'};
}

sub get_formatted_ellipsis_initial {
    my ( $self, $str ) = @_;
    my $pattern = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'ellipsis'}{'initial'} || '…{0}';
    $pattern =~ s/\{0\}/$str/;
    return $pattern;
}

sub get_formatted_ellipsis_medial {
    my ($self) = @_;    # my ($self, $first, $second) = @_;
    my $pattern = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'ellipsis'}{'medial'} || '{0}…{1}';
    $pattern =~ s/\{(0|1)\}/$_[$1 + 1]/g;    # use index instead of variable to avoid formatter confusion, e.g. $first contains the string '{1}'
    return $pattern;
}

sub get_formatted_ellipsis_final {
    my ( $self, $str ) = @_;
    my $pattern = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'ellipsis'}{'final'} || '{0}…';
    $pattern =~ s/\{0\}/$str/;
    return $pattern;
}

# TODO get_formatted_percent() get_formatted_permille() other symbols like infinity, plus sign etc

sub get_formatted_decimal {
    my ( $self, $n, $max_decimal_places, $_my_pattern ) = @_;    # $_my_pattern not documented on purpose, it is only intended for internal use, and may dropepd/changed at any time

    # Format $n per $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'decimal'}
    #   per http://cldr.unicode.org/translation/number-patterns

    # TODO: ? NaN from CLDR if undef or not d[.d] ?
    return if !defined $n;

    #### ##
    # 1) Turn $n into [0-9]+(?:\.[0-9]+)? even if scientifically large (or negative, since how negative numbers look is defined by the pattern)
    #### ##

    # Regaring $max_decimal_places: Number::Format will "Obtain precision from the length of the decimal part" of the pattern.
    # but CLDR says "The number of decimals will be set by the program" in our case the caller's input or sprintf()'s default.

    # this way we can remove any signs and still know if it was negative later on
    my $is_negative = $n < 0 ? 1 : 0;

    my $max_len = defined $max_decimal_places ? abs( int($max_decimal_places) ) : 6;    # %f default is 6
    $max_len = 14 if $max_len > 14;

    if ( $n > 10_000_000_000 || $n < -10_000_000_000 ) {

        # TODO: ? do exponential from CLDR ?
        return $n if $n =~ m/e/i;                                                       # poor man's is exponential check.

        # Emulate %f on large numbers strings
        # $n = "$n"; # turn it into a string, trailing zero's go away

        if ( $n =~ m/\.([0-9]{$max_len})([0-9])?/ ) {
            my $trim = $1;    # (defined $2 && $2 > 4) ? $1 + 1 : $1;

            if ( defined $2 && $2 > 4 ) {
                if ( ( $trim + 1 ) !~ m/e/i ) {    # poor man's is exponential check.
                    $trim++;
                }
            }

            # Yes, %f does it but why 0's only to lop them off immediately
            # while(CORE::length($trim) < $max_len) { $trim .= '0' }
            $n =~ s/\.[0-9]+/\.$trim/;
        }
    }
    else {
        $n = sprintf( '%.' . $max_len . 'f', $n );

        # TODO: ? do exponential from CLDR ?
        return $n if $n =~ m/e/i;    # poor man's is exponential check.
    }

    # [^0-9]+ will match the off chance of sprintf() using a
    # separator that is mutiple bytes or mutliple characters or both.
    # This holds true for both byte strings and Unicode strings.

    $n =~ s{([^0-9]+[0-9]*?[1-9])0+$}{$1};
    $n =~ s{[^0-9]+0+$}{};

    # [^0-9]+ will match the off chance of sprintf() using a
    # negative/positive symbol that is mutiple bytes or mutliple characters or both.
    # This holds true for both byte strings and Unicode strings.
    $n =~ s/^[^0-9]+//;    # strip signs since any would be defined in pattern

    #### ##
    # 2) Determine working format:
    #### ##

    my $format = $_my_pattern || $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'decimal'};    # from http://unicode.org/repos/cldr-tmp/trunk/diff/by_type/number.pattern.html

    my ( $zero_positive_pat, $negative_pat, $err ) = split( /(?<!\')\;(?!\')/, $format );             # semi-colon that is not literal (?<!\')\;(?!\')

    if ($err) {
        require Carp;
        Carp::carp("Format had more than 2 pos/neg sections. Using default pattern.");
        $format = '#,##0.###';
    }
    elsif ( $is_negative && $negative_pat ) {
        $format = $negative_pat;
    }
    elsif ($zero_positive_pat) {
        $format = $zero_positive_pat;
    }

    my $dec_sec_cnt = 0;
    $dec_sec_cnt++ while ( $format =~ m/(?<!\')\.(?!\')/g );
    if ( $dec_sec_cnt != 1 ) {
        require Carp;
        Carp::carp("Format should have one decimal section. Using default pattern.");
        $format = '#,##0.###';
    }

    if ( !defined $format || $format eq '' || $format =~ m/^\s+$/ ) {
        require Carp;
        Carp::carp("Format is empty. Using default pattern.");
        $format = '#,##0.###';
    }

    #### ##
    # 3) format $n per $format
    #### ##

    my $result = '';

    if ( $format eq '#,##0.###' ) {
        $result = $n;
        while ( $result =~ s/^([-+]?\d+)(\d{3})/$1,$2/s ) { 1 }    # right from perlfaq5
    }
    else {

        # period that is not literal (?<!\')\.(?!\')
        # comma that is not literal (?<!\')\,(?!\')

        # !!!! This is sort of where the CLDR documentation gets anemic, patches welcome !!

        # TODO: ? better efficiency (e.g. less/no array voo doo) w/ same results, patches ... well you know ?

        my ( $integer, $decimals ) = split( /\./, $n, 2 );

        my ( $i_pat, $d_pat ) = split( /(?<!\')\.(?!\')/, $format, 2 );
        my ( $cur_idx, $trailing_non_n, $cur_d, $cur_pat ) = ( 0, '' );    # buffer

        # integer: right to left
        my @i_pat = reverse( split( /(?<!\')\,(?!\')/, $i_pat ) );

        my $next_to_last_pattern = @i_pat == 1 ? $i_pat[0] : $i_pat[-2];
        $next_to_last_pattern =~ s/0$/#/;
        while ( $i_pat[0] =~ s/((?:\'.\')+)$// || $i_pat[0] =~ s/([^0#]+)$// ) {
            $trailing_non_n = "$1$trailing_non_n";
        }

        # my $loop_cnt = 0;
        # my $loop_max = CORE::length($i_pat . $integer) + 100;

        while ( CORE::length( $cur_d = CORE::substr( $integer, -1, 1, '' ) ) ) {

            # if ($loop_cnt > $loop_max) {
            #     require Carp;
            #     Carp::carp('Integer pattern parsing results in infinite loop.');
            #     last;
            # }
            # $loop_cnt++;

            if ( $cur_idx == $#i_pat && !CORE::length( $i_pat[$cur_idx] ) ) {
                $i_pat[$cur_idx] = $next_to_last_pattern;
            }

            if ( !CORE::length( $i_pat[$cur_idx] ) ) {    # this chunk is spent
                if ( defined $i_pat[ $cur_idx + 1 ] ) {    # there are more chunks ...
                    $cur_idx++;                            # ... next chunk please
                }
            }

            if ( CORE::length( $i_pat[$cur_idx] ) ) {

                # if the next thing is a literal:
                if ( $i_pat[$cur_idx] =~ m/(\',\')$/ ) {
                    $result = CORE::substr( $i_pat[$cur_idx], -3, 3, '' ) . $result;
                    redo;
                }

                $cur_pat = CORE::substr( $i_pat[$cur_idx], -1, 1, '' );

                if ( $cur_pat ne '0' && $cur_pat ne '#' ) {
                    $result = "$cur_pat$result";
                    redo;
                }
            }

            $result = !CORE::length( $i_pat[$cur_idx] ) && @i_pat != 1 ? ",$cur_d$result" : "$cur_d$result";

            if ( $cur_idx == $#i_pat - 1 && $i_pat[$#i_pat] eq '#' && !CORE::length( $i_pat[$cur_idx] ) ) {
                $cur_idx++;
                $i_pat[$cur_idx] = $next_to_last_pattern;
            }
        }
        if ( CORE::length( $i_pat[$cur_idx] ) ) {
            $i_pat[$cur_idx] =~ s/(?<!\')\#(?!\')//g;    # remove any left over non-literal #
            $result = $result . $i_pat[$cur_idx];        # prepend it (e.g. 0 and -)
        }
        if ( substr( $result, 0, 1 ) eq ',' ) {
            substr( $result, 0, 1, '' );
        }
        $result .= $trailing_non_n;

        if ( defined $decimals && CORE::length($decimals) ) {

            # decimal: left to right
            my @d_pat = ($d_pat);                        # TODO ? support sepeartor in decimal, !definedvia CLDR, no patterns have that ATM ? split( /(?<!\')\,(?!\')/, $d_pat );

            $result .= '.';
            $cur_idx        = 0;
            $trailing_non_n = '';

            while ( $d_pat[-1] =~ s/((?:\'.\')+)$// || $d_pat[-1] =~ s/([^0#]+)$// ) {
                $trailing_non_n = "$1$trailing_non_n";
            }

            # $loop_cnt = 0;
            # $loop_max = CORE::length($d_pat . $decimals) + 100;

            while ( CORE::length( $cur_d = CORE::substr( $decimals, 0, 1, '' ) ) ) {

                # if ($loop_cnt > $loop_max) {
                #     require Carp;
                #     Carp::carp('Decimal pattern parsing results in infinite loop.');
                #     last;
                # }
                # $loop_cnt++;

                if ( !CORE::length( $d_pat[$cur_idx] ) ) {    # this chunk is spent
                    if ( !defined $d_pat[ $cur_idx + 1 ] ) {    # there are no more chunks
                        $cur_pat = '#';
                    }
                    else {                                      # next chunk please
                        $result .= ',';
                        $cur_idx++;
                    }
                }

                if ( CORE::length( $d_pat[$cur_idx] ) ) {

                    # if the next thing is a literal:
                    if ( $d_pat[$cur_idx] =~ m/^(\'.\')/ ) {
                        $result .= CORE::substr( $d_pat[$cur_idx], 0, 3, '' );
                        redo;
                    }
                    $cur_pat = CORE::substr( $d_pat[$cur_idx], 0, 1, '' );
                    if ( $cur_pat ne '0' && $cur_pat ne '#' ) {
                        $result .= $cur_pat;
                        redo;
                    }
                }

                $result .= $cur_d;
            }
            if ( substr( $result, -1, 1 ) eq ',' ) {
                substr( $result, -1, 1, '' );
            }
            if ( defined $d_pat[$cur_idx] ) {
                $d_pat[$cur_idx] =~ s/(?<!\')\#(?!\')//g;    # remove any left over non-literal #
                $result .= $d_pat[$cur_idx];                 # append it (e.g. 0 and -)
            }
            $result .= $trailing_non_n;
        }

        # END: "This is sort of where the CLDR documentation gets anemic"
    }

    $result =~ s/(?<!\')\.(?!\')/_LOCALES-DECIMAL-PLACEHOLDER_/g;    # _LOCALES-DECIMAL-PLACEHOLDER_' not likley to be in CLDR format ;) - if that does not hold true then append "time . $$" to placeholder
    $result =~ s/(?<!\')\,(?!\')/$self->{language_data}{misc_info}{cldr_formats}{_decimal_format_group}/g;
    $result =~ s/_LOCALES-DECIMAL-PLACEHOLDER_/$self->{language_data}{misc_info}{cldr_formats}{_decimal_format_decimal}/g;

    # TODO ? turn 0-9 into non0-9 digits if defined as such in CLDR ?

    if ( $is_negative && !$negative_pat ) {

        # This is default since CLDR says to specify a special negative pattern if
        #    "your language uses different formats for negative numbers than just adding "-" at the front"
        $result = "-$result";
    }

    return $result;
}

#### territory ####

sub get_territory_codes {
    return keys %{ shift->{'territory_data'}{'code_to_name'} };
}

sub get_territory_names {
    return values %{ shift->{'territory_data'}{'code_to_name'} };
}

sub get_territory_lookup {
    return %{ shift->{'territory_data'}{'code_to_name'} };
}

sub get_territory_from_code {
    my ( $self, $code, $always_return ) = @_;

    $code ||= $self->{'territory'};
    $code = normalize_tag($code);
    return if !defined $code;

    # this is not needed in this method:
    # $always_return ||= 1 if $code eq $self->get_locale() && $self->get_soft_locale_fallback(); # force $always_return under soft locale objects

    if ( exists $self->{'territory_data'}{'code_to_name'}{$code} ) {
        return $self->{'territory_data'}{'code_to_name'}{$code};
    }
    elsif ( !defined $self->{'territory'} || $code ne $self->{'territory'} ) {
        my ( $l, $t ) = split_tag($code);
        if ( $t && exists $self->{'territory_data'}{'code_to_name'}{$t} ) {
            return $self->{'territory_data'}{'code_to_name'}{$t};
        }
    }
    return $code if $always_return;
    return;
}

sub get_code_from_territory {
    my ( $self, $name ) = @_;
    return if !$name;
    my $key = normalize_for_key_lookup($name);
    if ( exists $self->{'territory_data'}{'name_to_code'}{$key} ) {
        return $self->{'territory_data'}{'name_to_code'}{$key};
    }
    return;
}

{
    no warnings 'once';
    *code2territory = \&get_territory_from_code;
    *territory2code = \&get_code_from_territory;
}

#### language ####

sub get_language_codes {
    return keys %{ shift->{'language_data'}{'code_to_name'} };
}

sub get_language_names {
    return values %{ shift->{'language_data'}{'code_to_name'} };
}

sub get_language_lookup {
    return %{ shift->{'language_data'}{'code_to_name'} };
}

sub get_language_from_code {
    my ( $self, $code, $always_return ) = @_;

    $code ||= $self->{'locale'};
    $code = normalize_tag($code);
    return if !defined $code;

    $always_return ||= 1 if $code eq $self->get_locale() && $self->get_soft_locale_fallback();    # force $always_return under soft locale objects
    $always_return ||= 0;

    if ( exists $self->{'language_data'}{'code_to_name'}{$code} ) {
        return $self->{'language_data'}{'code_to_name'}{$code};
    }
    elsif ($always_return) {
        my ( $l, $t ) = split_tag($code);
        my $ln = $self->{'language_data'}{'code_to_name'}{$l};
        my $tn = defined $t ? $self->{'territory_data'}{'code_to_name'}{$t} : '';

        return $code if !$ln && !$tn;
        $ln ||= $l;
        $tn ||= $t;

        my $string = $self->{'language_data'}{'misc_info'}{'cldr_formats'}{'locale'} || '{0} ({1})';
        $string =~ s/\{0\}/$ln/g;
        $string =~ s/\{1\}/$tn/g;

        return $string;
    }
    return;
}

sub get_code_from_language {
    my ( $self, $name ) = @_;
    return if !$name;
    my $key = normalize_for_key_lookup($name);
    if ( exists $self->{'language_data'}{'name_to_code'}{$key} ) {
        return $self->{'language_data'}{'name_to_code'}{$key};
    }
    return;
}

{
    no warnings 'once';
    *code2language = \&get_language_from_code;
    *language2code = \&get_code_from_language;
}

#### utility functions ####

sub tag_is_soft_locale {
    my ($tag) = @_;
    my ( $l, $t ) = split_tag($tag);

    return if !defined $l;    # invalid tag is not soft

    return if !$t;                             # no territory part means it is not soft
    return if tag_is_loadable($tag);           # if it can be loaded directly then it is not soft
    return if !territory_code_is_known($t);    # if the territory part is not known then it is not soft
    return if !tag_is_loadable($l);            # if the language part is not known then it is not soft
    return $l;                                 # it is soft, so return the value suitable for 'soft_locale_fallback'
}

sub tag_is_loadable {
    my ( $tag, $as_territory ) = @_;           # not documenting internal $as_territory, just use territory_code_is_known() directly
    have_mod("Locales::DB::Loadable") || return;

    if ($as_territory) {
        return 1 if exists $Locales::DB::Loadable::territory{$tag};
    }
    else {
        return 1 if exists $Locales::DB::Loadable::code{$tag};
    }

    return;
}

sub get_loadable_language_codes {
    have_mod("Locales::DB::Loadable") || return;
    return keys %Locales::DB::Loadable::code;
}

sub territory_code_is_known {
    return tag_is_loadable( $_[0], 1 );
}

sub split_tag {
    return split( /_/, normalize_tag( $_[0] ), 2 );    # we only do language[_territory]
}

sub get_i_tag_for_string {
    my $norm = normalize_tag( $_[0] );

    if ( substr( $norm, 0, 2 ) eq 'i_' ) {
        return $norm;
    }
    else {
        return 'i_' . $norm;
    }
}

my %non_locales = (
    'und' => 1,
    'zxx' => 1,
    'mul' => 1,
    'mis' => 1,
    'art' => 1,
);

sub non_locale_list {
    return ( sort keys %non_locales );
}

sub is_non_locale {
    my $tag = normalize_tag( $_[0] ) || return;
    return 1 if exists $non_locales{$tag};
    return;
}

sub typical_en_alias_list {
    return ( 'en_us', 'i_default' );
}

sub is_typical_en_alias {
    my $tag = normalize_tag( $_[0] ) || return;
    return 1 if $tag eq 'en_us' || $tag eq 'i_default';
    return;
}

sub normalize_tag {
    my $tag = $_[0];
    return if !defined $tag;
    $tag =~ tr/A-Z/a-z/;
    $tag =~ s{\s+}{}g;
    $tag =~ s{[^a-z0-9]+$}{};    # I18N::LangTags::locale2language_tag() does not allow trailing '_'
    $tag =~ s{[^a-z0-9]+}{_}g;

    # would like to do this with a single call, backtracking or indexing ? patches welcome!
    while ( $tag =~ s/([^_]{8})([^_])/$1\_$2/ ) { }    # I18N::LangTags::locale2language_tag() only allows parts bewteen 1 and 8 character
    return $tag;
}

sub normalize_tag_for_datetime_locale {
    my ( $pre, $pst ) = split_tag( $_[0] );            # we only do language[_territory]
    return if !defined $pre;

    if ($pst) {
        return $pre . '_' . uc($pst);
    }
    else {
        return $pre;
    }
}

sub normalize_tag_for_ietf {
    my ( $pre, $pst ) = split_tag( $_[0] );            # we only do language[_territory]
    return if !defined $pre;

    if ($pst) {
        return $pre . '-' . uc($pst);
    }
    else {
        return $pre;
    }
}

sub normalize_for_key_lookup {
    my $key = $_[0];
    return if !defined $key;
    $key =~ tr/A-Z/a-z/;    # lowercase
                            # $key =~ s{^\s+}{};   # trim WS from begining
                            # $key =~ s{\s+$}{};   # trim WS from end
                            # $key =~ s{\s+}{ }g;   # collapse multi WS to one space
    $key =~ s{\s+}{}g;
    $key =~ s{[\'\"\-\(\)\[\]\_]+}{}g;
    return $key;
}

sub plural_rule_string_to_javascript_code {
    my ( $plural_rule_string, $return ) = @_;
    my $perl = plural_rule_string_to_code( $plural_rule_string, $return );
    $perl =~ s/sub \{ /function (n) {/;
    $perl =~ s/\$_\[0\]/n/g;
    $perl =~ s/ \(n \% ([0-9]+)\) \+ \(n-int\(n\)\) /n % $1/g;
    $perl =~ s/int\(/parseInt\(/g;
    return $perl;
}

sub plural_rule_string_to_code {
    my ( $plural_rule_string, $return ) = @_;
    if ( !defined $return ) {
        $return = 1;
    }

    # if you have a better way, patches welcome!!

    my %m;
    while ( $plural_rule_string =~ m/mod ([0-9]+)/g ) {

        # CLDR plural rules (http://unicode.org/reports/tr35/#Language_Plural_Rules):
        #      'mod' (modulus) is a remainder operation as defined in Java; for example, the result of "4.3 mod 3" is 1.3.
        $m{$1} = "( (\$_[0] % $1) + (\$_[0]-int(\$_[0])) )";
    }

    my $perl_code = "sub { if (";

    for my $or ( split /\s+or\s+/i, $plural_rule_string ) {
        my $and_exp;
        for my $and ( split /\s+and\s+/i, $or ) {
            my $copy = $and;
            my $n    = '$_[0]';

            $copy =~ s/ ?n is not / $n \!\= /g;
            $copy =~ s/ ?n is / $n \=\= /g;

            $copy =~ s/ ?n mod ([0-9]+) is not / $m{$1} \!\= /g;
            $copy =~ s/ ?n mod ([0-9]+) is / $m{$1} \=\= /g;

            # 'in' is like 'within' but it has to be an integer
            $copy =~ s/ ?n not in ([0-9]+)\s*\.\.\s*([0-9]+) ?/ int\($n\) \!\= $n \|\| $n < $1 \|\| $n \> $2 /g;
            $copy =~ s/ ?n mod ([0-9]+) not in ([0-9]+)\s*\.\.\s*([0-9]+) ?/ int\($n\) \!\= $n \|\| $m{$1} < $2 \|\| $m{$1} \> $3 /g;

            # 'within' is like 'in' except is inclusive of decimals
            $copy =~ s/ ?n not within ([0-9]+)\s*\.\.\s*([0-9]+) ?/ \($n < $1 \|\| $n > $2\) /g;
            $copy =~ s/ ?n mod ([0-9]+) not within ([0-9]+)\s*\.\.\s*([0-9]+) ?/ \($m{$1} < $2 \|\| $m{$1} > $3\) /g;

            # 'in' is like 'within' but it has to be an integer
            $copy =~ s/ ?n in ([0-9]+)\s*\.\.\s*([0-9]+) ?/ int\($n\) \=\= $n \&\& $n \>\= $1 \&\& $n \<\= $2 /g;
            $copy =~ s/ ?n mod ([0-9]+) in ([0-9]+)\s*\.\.\s*([0-9]+) ?/ int\($n\) \=\= $n \&\& $m{$1} \>\= $2 \&\& $m{$1} \<\= $3 /g;

            # 'within' is like 'in' except is inclusive of decimals
            $copy =~ s/ ?n within ([0-9]+)\s*\.\.\s*([0-9]+) ?/ $n \>\= $1 \&\& $n \<\= $2 /g;
            $copy =~ s/ ?n mod ([0-9]+) within ([0-9]+)\s*\.\.\s*([0-9]+) ?/ $m{$1} \>\= $2 \&\& $m{$1} \<\= $3 /g;

            if ( $copy eq $and ) {
                require Carp;
                Carp::carp("Unknown plural rule syntax");
                return;
            }
            else {
                $and_exp .= "($copy) && ";
            }
        }
        $and_exp =~ s/\s+\&\&\s*$//;

        if ($and_exp) {
            $perl_code .= " ($and_exp) || ";
        }
    }
    $perl_code =~ s/\s+\|\|\s*$//;

    $perl_code .= ") { return '$return'; } return;}";

    return $perl_code;
}

sub plural_rule_hashref_to_code {
    my ($hr) = @_;

    if ( ref( $hr->{'category_rules'} ) ne 'HASH' ) {

        # this should never happen but if it does lets default to en's version
        $hr->{'category_rules_compiled'} = {
            'one' => q{sub { return 'one' if ( ( $n == 1 ) ); return;};},
        };

        return sub {

            my ($n) = @_;
            return 'one' if $n == 1;
            return;
        };
    }
    else {
        for my $cat ( get_cldr_plural_category_list(1) ) {
            next if !exists $hr->{'category_rules'}{$cat};
            next if exists $hr->{'category_rules_compiled'}{$cat};
            $hr->{'category_rules_compiled'}{$cat} = plural_rule_string_to_code( $hr->{'category_rules'}{$cat}, $cat );
        }

        return sub {
            my ($n) = @_;
            my $match;
          PCAT:
            for my $cat ( get_cldr_plural_category_list(1) ) {    # use function instead of keys to preserve processing order
                next if !exists $hr->{'category_rules_compiled'}{$cat};

                # Does $n match $hr->{$cat} ?

                if ( ref( $hr->{'category_rules_compiled'}{$cat} ) ne 'CODE' ) {

                    local $SIG{__DIE__};                          # prevent benign eval from tripping potentially fatal sig handler, moot w/ Module::Want 0.6
                    $hr->{'category_rules_compiled'}{$cat} = eval "$hr->{'category_rules_compiled'}{$cat}";    ## no critic # As of 0.22 this will be skipped for modules included w/ the main dist
                }

                if ( $hr->{'category_rules_compiled'}{$cat}->($n) ) {
                    $match = $cat;
                    last PCAT;
                }
            }

            return $match if $match;
            return;
        };
    }
}

sub get_cldr_plural_category_list {

    return qw(zero one two few many other) if $_[0];    # check order

    # Order is important for Locale::Maketext::Utils::quant():
    #   one (singular), two (dual), few (paucal), many, other, zero
    return qw(one two few many other zero);    # quant() arg order
}

sub get_fallback_list {
    my ( $self, $special_lookup ) = @_;

    my ( $super, $ter ) = split_tag( $self->{'locale'} );
    return (
        $self->{'locale'},
        ( $super ne $self->{'locale'} && $super ne 'i' ? $super : () ),
        ( @{ $self->{'language_data'}{'misc_info'}{'fallback'} } ),
        (
            defined $special_lookup && ref($special_lookup) eq 'CODE'
            ? ( map { my $n = Locales::normalize_tag($_); $n ? ($n) : () } $special_lookup->( $self->{'locale'} ) )
            : ()
        ),
        'en'
    );
}

# get_cldr_$chart_$type_$name or better naming ?
sub get_cldr_number_symbol_decimal {
    return $_[0]->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_decimal'} || '.';
}

sub get_cldr_number_symbol_group {
    return $_[0]->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'} || ',';
}

1;

__END__

=encoding utf-8

=head1 NAME

Locales - Methods for getting localized CLDR language/territory names (and a subset of other data)

=head1 VERSION

This document describes Locales version 0.33

=head1 SYNOPSIS

    use Locales;

    my $locale = Locales->new('en_gb');

    print $locale->get_locale(); # 'en_gb'
    print $locale->get_language(); # 'en'
    print $locale->get_territory(); # 'gb'

    print $locale->get_language_from_code('fr'); # 'French'
    print $locale->get_code_from_language('French'); # 'fr'

    print $locale->get_territory_from_code('us'); # 'United States'
    print $locale->get_code_from_territory('Australia'); # 'au'

=head1 DESCRIPTION

Locales lets you create an object for a certain locale that lets you access certain data harvested directly from CLDR.

L<http://cldr.unicode.org/index/downloads>

Currently the data/methods include translated locale names and territory names.

For simplicity Locales does not work with or know about Variants or Scripts. It only knows about languages and territories.

Also it does not contain all the data contained in CLDR. For example, L<DateTime>’s localization already has all the calender/date/time info from CLDR. Other information has not had any demand yet.

For consistency all data is written in utf-8. No conversion should be necessary if you are (wisely) using utf-8 as your character set everywhere (See L<http://drmuey.com\/?do=page&id=57> for more info on that.).

Note: You probably [don't need to/should not] use L<utf8> in regards to the data contained herein.

=head1 Based on CLDR

This module is based on CLDR v2.0.

You can learn about the Unicode Common Locale Data Repository at L<http://cldr.unicode.org/>.

=head1 Supported Locale Criteria

The locale tags that can be objectified fit this criteria:

=over 4

=item the locale must have data in the CLDR

As noted in “I am using a locale code that I know exists in the CLDR but I can't use it anywhere in Locales” in L</"BEFORE YOU SUBMIT A BUG REPORT">.

=item the locale must have an entry in CLDR’s en data

As noted in “I am using a locale code that I know exists in the CLDR but I can't use it anywhere in Locales” in L</"BEFORE YOU SUBMIT A BUG REPORT">.

=item the locale can only have language and territory parts

As noted in the L</DESCRIPTION>.

=item the only exceptions are “soft locales”.

As described in L</Soft Locales>.

=back

=head1 Soft Locales

As “soft locale” is a language-territory locale that does not fit the L</Supported Locale Criteria> directly but its super does and the territory is known.

For example “es-MX” does not fit the criteria but “es” does and “MX” is a valid territory code.

=head1 To byte or not to byte, that is the question. Ok, I’ll byte …

The CLDR data is in bytes, specifically utf-8.

By default this module simply passes along the strings as bytes, which works fine in applications that don’t operate in character mode (i.e. that use utf8 byte strings instead of Unicode strings**).

If you want Unicode strings instead you can do so by bringing in the module this way:

    use Locales unicode => 1;

[**] What is the difference between Unicode strings and utf-8 bytes strings you ask? See L<String::UnicodeUTF8> for more info.

=head1 INTERFACE

=head2 new()

Takes one argument, the locale tag whose CLDR data you want to use.

No argument defaults to 'en'.

It is an argument based singleton so you can call it more than once with out it having to rebuild the object every time.

It returns false if a locale given is not available. $@ should have been set at that point by eval.

    my $en = Locales->new('en') or die $@;

=head2 Object methods

=head3 Misc methods

=over 4

=item get_cldr_version()

Takes no arguments.

Returns the version of the CLDR any data it uses comes from. Can also be called as a class method or function.

=item get_locale()

Takes no arguments.

Returns the normalized locale of the object, this is the same as the argument to new()

=item get_language()

Takes no arguments.

Returns the language portion of the object’s locale.

=item get_territory()

Takes no arguments.

Returns the territory portion of the object’s locale if any (e.g. 'en_au'), undef if there is none (e.g. 'it').

=item get_soft_locale_fallback()

Takes no arguments.

Returns the locale that the object is based on in the case that the given locale (i.e. L</get_locale()>) is a L<soft locale|/Soft Locales>.

Note: If you do not want to have soft locale objects you should simply not call new() if it is soft:

    - my $loc = Locales->new($tag) || die $@;
    + my $loc = (Locales::tag_is_soft_locale($tag) ? undef : Locales->new($tag)) || die $@;

This could be added to the constructor but for now I don't want to make it more complicated only to support something that seems odd. If you have a use case submit an rt w/ details. Thanks!

=item numf()

Note: As of v0.17 you probably want L</get_formatted_decimal()> instead of numf().

Takes one optional boolean argument.

Returns 1 if the object’ss locale’s number format is comma for thousand separator, period for decimal.

Returns 2  if the object’s locale’s number format is period for thousand separator, comma for decimal.

Otherwise it returns a reference to a 3 element array containing this CLDR data: number format, separator character, decimal character.

The boolean argument, when true will do it’s best to determine and return a 1 or a 2.

=back

=head3 Territory methods

=over 4

=item get_territory_codes()

Take no arguments.

Returns an unsorted list of known territory codes.

=item get_territory_names()

Take no arguments.

Returns an unsorted list of the display names for each known territory code.

=item get_territory_lookup()

Take no arguments.

Returns a copy of the lookup hash of the display names for each known territory code.

=item get_territory_from_code()

Takes one argument, the locale code whose territory name you want to find. Defaults to the territory of the of object’s locale, if any.

Returns the name of the given tag’s territory or, if not found, the territory portion (if any), returns false otherwise.

An optional second argument, when true, will force it to return the normalized tag if nothing else can be figured out.

=item get_code_from_territory()

Takes one argument, the territory name whose locale you want to find.

Returns the locale tag if found, false otherwise.

=item code2territory()

Alias for get_territory_from_code()

=item territory2code()

Alias for get_code_from_territory()

=back

=head3 Language Methods

=over 4

=item get_language_codes()

Take no arguments.

Returns an unsorted list of known language codes.

=item get_language_names()

Take no arguments.

Returns an unsorted list of the display names for each known language code.

=item get_language_lookup()

Take no arguments.

Returns a copy of the lookup hash of the display names for each known language code.

=item get_language_from_code()

Takes one argument, the locale code whose language name you want to find. Defaults to the object’s locale.

Returns the name of the given tag’s language, returns false otherwise.

An optional second argument, when true, will force it to return a properly formatted CLDR format display based on if we know the language and/or territory if nothing else can be figured out.

=item get_code_from_language()

Takes one argument, the language name whose locale you want to find.

Returns the locale tag if found, false otherwise.

=item get_native_language_from_code()

Like get_language_from_code() except it returns the name in the given locale’s native language.

=item get_character_orientation_from_code()

Like get_language_from_code() except it returns the character orientation identifier for the given locale. (defaulting to the locale of the object if non is given)

Typically it will be the string “left-to-right” or “right-to-left”.

See L<http://unicode.org/repos/cldr-tmp/trunk/diff/by_type/misc.layout.html> for more information.

=item get_character_orientation_from_code_fast()

Same as get_character_orientation_from_code() except it should use less-overhead. Can be called as a function also so you can use it without creating an object.

=item get_locale_display_pattern_from_code()

Like get_character_orientation_from_code() except it returns the locale display pattern for the given locale. (defaulting to the locale of the object if non is given)

Typically it will be something like '{0} ({1})'

See L<http://unicode.org/repos/cldr-tmp/trunk/diff/by_type/names.localeDisplayPattern.html> for more information.

=item get_locale_display_pattern_from_code_fast()

Same as get_locale_display_pattern_from_code() except it should use less-overhead. Can be called as a function also so you can use it without creating an object.

=item get_cldr_number_symbol_decimal()

Returns the decimal point symbol for the object’s locale. Takes no arguments.

For formatting numbers use get_formatted_decimal().

=item get_cldr_number_symbol_group()

Returns the integer grouping symbol for the object’s locale. Takes no arguments.

For formatting numbers use get_formatted_decimal().

=item get_fallback_list()

Returns a fallback list of locales in the order they apply based on the object’s locale.

The basic list will be: object’s locale, object’s super if any, the object’s CLDR fallback if any, “special lookup” if any, 'en'

    my @list = $fr_ca->get_fallback_list();
    # fr_ca fr en

"special lookup" is a code ref that can be passed in as the first optional arg.

It is given the object’s locale when called and should return a list of locale tags (they will be normalized).

    my @list = $fr_ca->get_fallback_list(sub { return $_[0] =~ m/fr/ ? qw(i_yoda i_love_rhi) : () } );
    # fr_ca fr i_yoda i_love_rhi en

=item get_plural_form()

Takes a number and returns the plural category that the number fits under for the object’s locale.

You can also add an array of items to return instead of the category name. For the details on what arguments a given local needs see L<Locales::DB::Docs::PluralForms>.

The array should be the same length of the list of plural form categories for the locale. See get_plural_form_categories().

The exception to that is when you specify the optional L<Locales::DB::Docs::PluralForms/“Special Zero” Argument>.

For example, 'en' has the plural categories “one” and “other”, so it'd work like this:

    my $cat = $en->get_plural_form(0); # 'other'
    my $str = $en->get_plural_form(0,'I am 1','I am other'); # I am other
    my $str = $en->get_plural_form(0,'I am 1','I am other','I am nothing'); # I am nothing

    my $cat = $en->get_plural_form(1); # 'one'
    my $str = $en->get_plural_form(1,'I am 1','I am other'); # I am 1
    my $str = $en->get_plural_form(1,'I am 1','I am other','I am nothing');  #I am 1

    my $cat = $en->get_plural_form(2); # 'other'
    my $str = $en->get_plural_form(2,'I am 1','I am other'); # I am other
    my $str = $en->get_plural_form(2,'I am 1','I am other','I am nothing'); # I am other

In array context the second value is a boolean for if the return value is the L<Locales::DB::Docs::PluralForms/“Special Zero” Argument> or not.

This boolean value only has meaning when called with the additional array of items to return instead of the category name.

This method can carp() a few things:

=over

=item C<< Could not determine plural logic. >>

The locale does not have plural logic data.

=item C<< The number of given values (%d) does not match the number of categories (%d). >>

You passed too many or too few values after the initial numeric argument.

You'll only see this if $locales_object->{'verbose'} is set to true.

=item C<< The category (%s) is not used by this locale. >>

The locale’s plural rules come up with a category that is not applicable to the locale. Default to “other” at this point.

=back

=item get_plural_form_categories()

Returns an array of the CLDR plural rule category names that this locale uses.

Their order corresponds to the position of the corresponding value that get_plural_form() uses.

=item supports_special_zeroth()

Takes no arguments, returns a boolean.

It is true if the locale uses the L<Locales::DB::Docs::PluralForms/"“Special Zero” Argument">.

False if it does not.

=item plural_category_count()

Takes no arguments.

Returns the number of plural categories applicable to the object’s locale.

Does not factor in support (or not) of the L<special zeroth category|/supports_special_zeroth()>.

=item get_list_and()

Stringify an "and" list of items as defined in the CLDR for the object’s locale.

Note: get_list_or() will be done once L<CLDR defines the OR-list data|http://unicode.org/cldr/trac/ticket/4051>.

    $en->get_list_and() # nothing
    $en->get_list_and(1) # 1
    $en->get_list_and(1,2) # 1 and 2
    $en->get_list_and(1,2,3) # 1, 2, and 3
    $en->get_list_and(1,2,3,4) # 1, 2, 3, and 3

    $es->get_list_and() # nothing
    $es->get_list_and(1) # 1
    $es->get_list_and(1,2) # 1 y 2
    $es->get_list_and(1,2,3) # 1, 2 y 3
    $es->get_list_and(1,2,3,4) # 1, 2, 3 y 3

To help disambiguate ambiguous arguments (none, undef, “”, all space/non-break-space) you can use $loc->{'misc'}{'list_quote_mode'}.

The default value is “none”.

Possible values:

=over 4

=item “all”

quote() all values.

=item “some”

quote() only ambiguous values (none (as if it was “”), undef, “”, all space/non-break-space).

=item “none”

do not quote() any values

=back

If another value is given or the entry does not exist you'll get “none” behavior. If it is set to an unknown value you'll get a carp() of “$self->{misc}{list_quote_mode} is set to an unknown value”.

=item get_list_or()

Stringify an "or" list of items as defined in the CLDR for the object’s locale.

This is a stub until L<CLDR defines the OR-list data|http://unicode.org/cldr/trac/ticket/4051>.

Until then it is essentially the same as L</get_list_and()>except it uses English rules/grammer for or lists.

Uses $loc->{'misc'}{'list_quote_mode'} the same way get_list_and() does.

=item get_formatted_ellipsis_initial()

Formats the given string per the initial ellipsis pattern.

Truncating for length is the caller’s responsibility since knowing how to do that correctly depends on what the string is (e.g. plain text needs to factor in the encoding or we might corrupt the text, HTML might have a broken or unclosed tag, ANSI might be unclosed or truncated, etc) so it is outside of the scope of the CLDR.

    …foo

=item get_formatted_ellipsis_medial()

Formats the given string per the medial ellipsis pattern.

Truncating for length is the caller’s responsibility since knowing how to do that correctly depends on what the string is (e.g. plain text needs to factor in the encoding or we might corrupt the text, HTML might have a broken or unclosed tag, ANSI might be unclosed or truncated, etc) so it is outside of the scope of the CLDR.

    foo…bar

=item get_formatted_ellipsis_final()

Formats the given string per the medial ellipsis pattern.

Truncating for length is the caller’s responsibility since knowing how to do that correctly depends on what the string is (e.g. plain text needs to factor in the encoding or we might corrupt the text, HTML might have a broken or includes tag, ANSI might be unclosed or truncated, etc) so it is outside of the scope of the CLDR.

    foo…

=item quote()

Quotes the argument with the CLDR delimiters quotation_start and quotation_end.

=item quote_alt()

Quotes the argument with the CLDR delimiters alternate_quotation_start and alternate_quotation_end.

=item get_formatted_decimal()

Return the given number as a string formatted per the locale’s CLDR decimal format pattern.

An optional second argument defines a maximum length of decimal places (default is 6 perl %f, max is 14, if you have a need for a larger max please open an rt w/ context and we may make the max settable in the object)

    $fr->get_formatted_decimal("1234567890.12345"); # 1 234 567 890,12345
    $fr->get_formatted_decimal("1234567890.12345",4); # 1 234 567 890,123
    $fr->get_formatted_decimal("1234567890.12345",3); # 1 234 567 890,1235

Perl number stringification caveats:

=over 4

=item You can avoid most stringification of large integers issues by passing strings.

     $l->get_formatted_decimal(99999999999999999983222787.1234); # returns 1e+26 since that is how it comes into the function
     $l->get_formatted_decimal("99999999999999999983222787.1234"); # 99,999,999,999,999,999,983,222,787.1234

=item You can avoid most formatting of large decimal parts issues by passing strings.

     $l->get_formatted_decimal(10000000001.12345678911234,12); # 10,000,000,001.1235 since it is already truncated  when it comes into the function
     $l->get_formatted_decimal("10000000001.12345678911234",12); # 10,000,000,001.123456789112

=item If the abs integer is > 10_000_000_000 and the decimal part alone stringify into an exponential number the rounding is not done.

That is OK though, since this isn't intended to be used in math and you are already aware of how large integers and decimals act oddly on computers right?

=item In general very large integers and/or very large decimal places get wonky when you want to turn them into a string like [0-9]+.[0-9]+

This is why we have a hard limit of 14 decimal places, to enforce some sense of sanity. You might consider only using the max decimal places argument to make it less than 6 digits long.

=back

This method can carp() a few (hopefully self explanatory) things regarding CLDR number format syntax errors:

=over

=item C<< Format had more than 2 pos/neg sections. Using default pattern. >>

=item C<< Format should have one decimal section. Using default pattern. >>

=item C<< Format is empty. Using default pattern. >>

=back

=item code2language()

Alias for get_language_from_code()

=item language2code()

Alias for get_code_from_language()

=back

=head2 Utility functions

These are some functions used internally that you might find useful.

=over 4

=item Locales::normalize_tag()

Takes a single argument, the locale tag to normalize.

Returns the normalized tag.

   print Locales::normalize_tag("  en-GB\n "); # 'en_gb'

=item Locales::normalize_tag_for_datetime_locale()

Like normalize_tag() except the return value should be suitable for L<DateTime::Locale>

   print Locales::normalize_tag_for_datetime_locale("  en-GB\n "); # 'en_GB'

=item Locales::normalize_tag_for_ietf()

Like normalize_tag() except the return value should be suitable for IETF.

This is not a comprehensive IETF formatter, it is intended (for now at least) for the subset of tags Locales.pm uses.

   print Locales::normalize_tag_for_ietf("  en_gb\n "); # 'en-GB'

=item Locales::split_tag()

Takes a single argument, the locale tag to split into language and territory parts.

Returns the resulting array of 1 or 2 normalized (but not validated) items.

   my ($language, $territory) = Locales::split_tag("  en-GB\n "); # ('en','gb')

   my ($language, $territory) = Locales::split_tag('fr'); # ('fr');

   my ($language, $territory) = Locales::split_tag('sr_Cyrl_YU'); # ('sr','cyrl_yu'), yes 'cyrl_yu' is invalid here since Locales doesn't work with the Script variants, good catch

=item Locales::get_i_tag_for_string()

Takes a single argument, the locale tag string to transform into "i" notation.

Returns the resulting normalized locale tag.

The standard tag for strings/tags without a standard is an "i" notation tag.

For example, the language "Yoda Speak" does not have an ISO code. You'd have to use i_yoda_speak.

    # assuming $string = "Yoda Speak"; you'd get into the if(), assuming it was 'Spanish' or 'es'
    if (!$en->get_language_from_code($string) && !$en->get_code_from_language($string) ) {
        # it is not a code or a language (at least in the language of $en) so lets create a tag for it:
        _create_locale_files( Locales::get_i_tag_for_string($string) ); # i_yoda_speak
    }
    else {
        # if it is a language name then we fetch the code otherwise, at this point, we know it is a code, so return a normailized version
        _create_locale_files( $en->get_code_from_language($yoda) || Locales::normalize_tag($yoda) );
    }

=item Locales::tag_is_soft_locale()

Takes a single argument, the locale tag you want to check to see if it is <soft locale|/Soft Locales> or not.

If it is it returns the super portion that an object would be based on. If it is not it returns false.

=item Locales::tag_is_loadable()

Returns true if the given tag can be loaded as a Locales object via new(). False otherwise.

=item Locales::territory_code_is_known()

Returns true if the given tag is a known territory. False otherwise.

=item Locales::get_loadable_language_codes()

Takes no arguments. Returns an unsorted list of codes that can be loaded as a Locales object via new().

=item Locales::non_locale_list()

Takes no arguments. Returns a list of locale tags that are not actually locales. e.g. 'mul' means “Multiple Languages”.

=item Locales::is_non_locale()

Takes a locale tag as the argument and returns true if it is a non-locale code (See L</Locales::non_locale_list()>), false otherwise.

=item Locales::typical_en_alias_list

Takes no arguments. Returns a list of locale tags that are typically aliases of 'en'.

=item Locales::is_typical_en_alias

Takes a locale tag as the argument and returns true if it is typically an alias of 'en' (See L</Locales::typical_en_alias_list()>), false otherwise.

=item Locales::normalize_for_key_lookup()

Takes a single argument, the phrase string normalize in the same way the names are stored in each locale’s lookup hash.

Returns the resulting normalized string.

This is used internally to normalize a given name in the same manner the name-to-code hash keys are normalized.

If said normalization is ever improved then using this function will ensure everything is normalized consistently.

That allows $en->get_code_from_language($name) to map to 'afa' if given these various variations of $arg:

  "Afro-Asiatic Language"
  "afroasiatic\tLanguage"
  "AFRO-Asiatic Language"
  "  Afro_Asiatic    Language"
  "afro.Asiatic Language\n"

=item Locales::get_cldr_plural_category_list()

Returns a list of plural categories that CLDR uses.

With no argument, the order is what is appropriate for some noun quantifying localization methods.

With a true argument, the order is the order it makes sense to check their corresponding rules in.

=item Locales::plural_rule_string_to_code()

This is used under the hood to facilitate get_plural_form(). That being the case there probably isn't much use for it to be used directly.

This takes the plural rule string as found in the CLDR XML and returns an eval()able perl code version of it.

It will carp "Unknown plural rule syntax" and return; if it does not understand what you sent.

A second, optional, argument is the value to return if the rule matches.

If you eval the returned string you'll have a code reference that returns true (or whatever you give it) if the rule matched the given number or not:

    my $perly = Locales::plural_rule_string_to_code("n is 42 or n mod 42 is not 7");
    my $check = eval $perly;
    my $plural_category = $check->(42);

=item Locales::plural_rule_hashref_to_code()

This is used under the hood to facilitate get_plural_form(). That being the case there probably isn't much use for it to be used directly.

This takes a hashref that contains rules, puts them in the hash, and returns an overall code ref. Its pretty internal so if you really need the details have a gander at the source.

=item Locales::plural_rule_string_to_javascript_code

Same as Locales::plural_rule_string_to_code() except it returns javascript code instead of perl code.

Used internally when building this distribution’s share/misc_info contents.

=back

=head1 DIAGNOSTICS

Throws no warning or errors of it’s own. If any function or method returns false then the arguments given (or not given) were invalid/not found.

Deviations from this are documented per function/method.

=head1 CONFIGURATION AND ENVIRONMENT

Locales requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 TODO

  - CLDR builder TODOs
  - more CLDR version/misc-info fetchers
  - generally improve get_code_from_* lookups
  - tests that misc info doesn't get odd structs from XML instead of a string
  - ? install share/ via L<File::ShareDir> mechanism ?
  - vet share/ && document better

=head1 DEPRECATED MODULES/INTERFACE

The original, non CLDR based,  '::Base' based modules/interface in this distribution were deprecated in version 0.06.

These modules were removed in version 0.15.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Locales/issues>.

Please report any bugs or feature requests regarding CLDR data as per
L<http://cldr.unicode.org/index/bug-reports>.

=head2 BEFORE YOU SUBMIT A BUG REPORT

Please read TODO, DESCRIPTION, and the information below thoroughly to see if your thought is already addressed.

=over 4

=item * A non-English object returns English names.

Data that is not defined in a locale’s CLDR data falls back to English.

Please report the missing data to the CLDR as per L<http://cldr.unicode.org/index/bug-reports>.

=item * I am using a locale code that I know exists in the CLDR but I can't use it anywhere in Locales

Only locales and territory codes that 'en' knows about are used. Only locales that have their own data set in CLDR are able to be objectified.

Additions or updates can be request as per L<http://cldr.unicode.org/index/bug-reports>.

=item * A name is misformatted, incorrect, etc.


The data is automatically harvested from CLDR. So if there is really a problem you'll have to report the problem to them. (as per L<http://cldr.unicode.org/index/bug-reports>)

Here are some things to check before submitting a report:

=over 4

=item * Corrupt text

=over 4

=item * Is your charset correct?

For example, viewing UTF-8 characters on a latin1 web page will result in garbled characters.

=item * It still looks corrupt!

Some locale’s require special fonts to be installed on your system to view them properly.

For example Bengali (bn) is like this. As per L<http://www.unicode.org/help/display_problems.html> if you install the proper font it renders correctly.

=back

=item * Incorrect data or formatting

=over 4

=item * Is it really inaccurate?

It could simply be an incomplete understanding of the context of the data, for example:

In English we capitalize proper names (e.g. French).

In other languages it may be perfectly acceptable for a language or territory name to not start with upper case letters.

In that case a report about names not being capitalized like we do in English would be unwarranted.

=item * Is it really mis-formatted?

Sometimes something might look strange to us and we'd be tempted to report the problem. Keep in mind though that sometimes locale nuances can cause things to render in a way that non-native speakers may not understand.

For example Arabic’s (ar) right-to-left text direction can seem strange when mixed with latin text. It's simply not wrong. You may be able to improve it by using the direction data to render it better (e.g. CSS or HTML attributes if the output is HTML).

Also, CLDR pattern formats can differ per locale.

In cases like this a report would be unwarranted.

=back

=back

=back

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
