package _locales_build_utils;

use Cwd;
use XML::Simple;
use XML::Twig;
use File::Path::Tiny;
use lib Cwd::realpath('lib');
use Locales;
use File::Slurp;
use Encode ();    # to be stringified properly from hash value bug: s{\|\|\s*(\$fallback_lang_misc_info\-\>\S*)\,}{|| Encode::decode_utf8($1),}
use String::Unquotemeta;
use JSON::Syck;
use JavaScript::Minifier::XS;

#### this ugliness will be spruced up when we go to CLDR-via-JSON in rt 69340 (no XML voo doo and we can move to TT for mod building) ##

# datetime.json
our $tripped;
use Test::Carp sub { $tripped = 1 if $_[0]; };
use DateTime::Locale;
use Class::Inspector;
my $en_dt_loc = DateTime::Locale->load('en');
my @dt_methods;
for my $meth ( @{ Class::Inspector->methods( ref($en_dt_loc), "public" ) } ) {
    next if $meth eq 'new' || $meth eq 'carp' || $meth eq 'format_for' || $meth eq 'validate_pos';
    next if $meth =~ m/^(:?set_|STORABLE_)/;

    *DateTime::Locale::Base::carp = sub { Carp::carp( $_[0] ) };
    local $tripped = 0;
    Test::Carp::does_carp_that_matches(
        sub {
            eval { $en_dt_loc->$meth() };
        },
        qr/The $meth method in DateTime::Locale::Base has been deprecated/
    );
    next if $tripped;

    push @dt_methods, $meth;
}
my @dt_available_formats = $en_dt_loc->available_formats();

# /datetime.json

use Hash::Merge;
Hash::Merge::specify_behavior(
    {
        'SCALAR' => {
            'SCALAR' => sub { !defined $_[0] ? $_[1] : $_[0] },
            'ARRAY'  => sub { !defined $_[0] ? $_[1] : $_[0] },
            'HASH'   => sub { !defined $_[0] ? $_[1] : $_[0] },
        },
        'ARRAY' => {
            'SCALAR' => sub { defined $_[0] ? $_[0] : [ @{ $_[0] }, $_[1] ] },
            'ARRAY'  => sub { defined $_[0] ? $_[0] : [ @{ $_[0] }, @{ $_[1] } ] },
            'HASH'   => sub { defined $_[0] ? $_[0] : [ @{ $_[0] }, values %{ $_[1] } ] },
        },
        'HASH' => {
            'SCALAR' => sub { $_[0] },
            'ARRAY'  => sub { $_[0] },
            'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    },
    "left undef/missing"
);

sub merge_hash {
    goto &Hash::Merge::merge;
}
use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq    = 1;
{
    no warnings 'redefine';

    sub Data::Dumper::qquote {
        my $s = shift;
        my $q = quotemeta($s);
        return $s ne $q ? qq{"$q"} : qq{'$s'};
    }
}

my $v_offset     = '0.24';
my $mod_version  = $Locales::VERSION - $v_offset;
my $cldr_version = $Locales::cldr_version;
my $cldr_db_path;
my $locales_db;
my $manifest;
our $plural_forms;

sub init_paths_from_argv {
    die "no CLDR path given" if !-d "$ARGV[0]/common/main";
    $cldr_db_path = Cwd::realpath( $ARGV[0] ) || die "need path to CLDR";
    $locales_db = Cwd::realpath( $SARGV[1] || 'lib/Locales/DB' );
    $manifest   = Cwd::realpath( $SARGV[2] || 'MANIFEST.build' );

    my $plural_forms_xml = XMLin( "$ARGV[0]/common/supplemental/plurals.xml", ForceArray => 1 );    # ,'KeyAttr' => {'pluralRules' => '+locales' });
    for my $plural ( @{ $plural_forms_xml->{'plurals'}[0]{'pluralRules'} } ) {
        for my $loc ( split( /\s+/, $plural->{'locales'} ) ) {
            $plural_forms->{$loc} = { map { $_->{'count'} => $_->{'content'} } @{ $plural->{'pluralRule'} } };
            if ( !keys %{ $plural_forms->{$loc} } ) {
                $plural_forms->{$loc} = undef();
            }
        }
    }

    # print Dumper($plural_forms);die; # _xml->{'plurals'}[0]{'pluralRules'});die;

    return ( $cldr_db_path, $locales_db, $manifest );
}

sub get_xml_file_for {
    my ( $tag, $quiet ) = @_;
    my $xml_file = "$cldr_db_path/common/main/$tag.xml";
    if ( !-e $xml_file ) {
        warn "\t1) No $xml_file ...\n" if !$quiet;
        my $tag_copy = $tag;
        $tag_copy =~ s{_(\w+)$}{_\U$1\E};
        $xml_file = "$cldr_db_path/common/main/$tag_copy.xml";
        if ( !-e $xml_file ) {
            warn "\t2) No $xml_file ...\n" if !$quiet;
            $tag_copy =~ tr/a-z/A-Z/;
            $xml_file = "$cldr_db_path/common/main/$tag_copy.xml";
            if ( !-e $xml_file ) {
                warn "\t3) No $xml_file ...\n" if !$quiet;
                return;
            }
        }
    }
    return $xml_file;

}

sub get_target_structs_from_cldr_for_tag {
    my ( $tag, $fallback_lang_code_to_name, $fallback_terr_code_to_name, $fallback_lang_misc_info ) = @_;

    # if ( $tag eq 'pt_br' ) { print Dumper( [ 'get_target_structs_from_cldr_for_tag', $fallback_lang_misc_info ] ) }
    my $xml_file = get_xml_file_for($tag);
    return if !-e $xml_file;

    print "Loading $tag XML from $xml_file...\n";

    # my $raw_struct = XMLin($xml_file, 'KeyAttr' => 'type');
    my $raw_struct = XML::Twig->new()->parsefile($xml_file)->simplify(
        'keyattr' => {
            'codePattern'     => '+type',
            'listPatternPart' => '+type',
            'characters'      => '+type',
            'ellipsis'        => '+type',
            'territory'       => '+type',
            'language'        => '+type',
        }
    );

    my ( $lang_code_to_name, $lang_name_to_code, $lang_misc_info, $terr_code_to_name, $terr_name_to_code ) = ( {}, {}, {}, {}, {} );

    #### Territories ####
    for my $trr ( keys %{ $raw_struct->{'localeDisplayNames'}{'territories'}{'territory'} } ) {

        # Do not skip ISO 3166-1-numeric (e.g. 419, as in es_419)
        # next if $trr =~ m/^\d+$/;

        my $short = $trr;
        $short =~ tr/A-Z/a-z/;

        $terr_code_to_name->{$short} = $raw_struct->{'localeDisplayNames'}{'territories'}{'territory'}{$trr}{'content'};
        $terr_name_to_code->{ Locales::normalize_for_key_lookup( $raw_struct->{'localeDisplayNames'}{'territories'}{'territory'}{$trr}{'content'} ) } = $short;
    }

    if ($fallback_terr_code_to_name) {
        for my $fb_trr ( keys %{$fallback_terr_code_to_name} ) {
            if ( !exists $terr_code_to_name->{$fb_trr} ) {
                $terr_code_to_name->{$fb_trr} = $fallback_terr_code_to_name->{$fb_trr};
                $terr_name_to_code->{ Locales::normalize_for_key_lookup( $fallback_terr_code_to_name->{$fb_trr} ) } = $fb_trr;
            }
        }
    }
    #### /Territories ####

    #### Languages ####
    my $fallback = undef;    # or [] ?
    if ( exists $raw_struct->{'fallback'} ) {
        $fallback = [];
        if ( my $type = ref( $raw_struct->{'fallback'} ) ) {
            if ( $type eq 'ARRAY' ) {
                for my $fb ( @{ $raw_struct->{'fallback'} } ) {
                    my $thing = ref($fb) ? $fb->{'content'} : $fb;
                    next if !defined $thing;
                    push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $thing );
                }
            }
            elsif ( $type eq 'HASH' ) {
                if ( $raw_struct->{'fallback'}{'content'} ) {
                    push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $raw_struct->{'fallback'}{'content'} );
                }
            }
        }
        else {
            if ( $raw_struct->{'fallback'} ) {
                push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $raw_struct->{'fallback'} );
            }
        }
    }
    elsif ( exists $fallback_lang_misc_info->{'fallback'} ) {
        $fallback = [];
        if ( my $type = ref( $fallback_lang_misc_info->{'fallback'} ) ) {
            if ( $type eq 'ARRAY' ) {
                for my $fb ( @{ $fallback_lang_misc_info->{'fallback'} } ) {
                    my $thing = ref($fb) ? $fb->{'content'} : $fb;
                    next if !defined $thing;
                    push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $thing );
                }
            }
            elsif ( $type eq 'HASH' ) {
                if ( $fallback_lang_misc_info->{'fallback'}{'content'} ) {
                    push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $fallback_lang_misc_info->{'fallback'}{'content'} );
                }
            }
        }
        else {
            if ( $fallback_lang_misc_info->{'fallback'} ) {
                push @{$fallback}, map { Locales::normalize_tag("$_") } split( /\s+/, $fallback_lang_misc_info->{'fallback'} );
            }
        }
    }

    my $symbols_index;
    if ( ref( $raw_struct->{'numbers'}{'symbols'} ) eq 'ARRAY' ) {
        my $default_numbersystem = $raw_struct->{'numbers'}{'defaultNumberingSystem'} || $raw_struct->{'numbers'}{'defaultNumberingSystem'} || 'latn';
        if ( ref($default_numbersystem) eq 'HASH' ) {
            $default_numbersystem = $default_numbersystem->{'content'};
        }

        my $idx = -1;
        for my $item ( @{ $raw_struct->{'numbers'}{'symbols'} } ) {
            $idx++;

            if ( ref($item) eq 'HASH' && $item->{'numberSystem'} eq $default_numbersystem ) {
                $symbols_index = $idx;
                last;
            }
        }
    }

    my $_decimal_format_group =
      defined $symbols_index
      ? (
          ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'group'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'group'}{'content'}
        : ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'group'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'group'}->[0]
        :                                                                               $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'group'}
      )
      : (
          ref $raw_struct->{'numbers'}{'symbols'}{'group'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}{'group'}{'content'}
        : ref $raw_struct->{'numbers'}{'symbols'}{'group'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}{'group'}->[0]
        :                                                               $raw_struct->{'numbers'}{'symbols'}{'group'}
      );
    if ( ref($_decimal_format_group) eq 'HASH' ) {
        $_decimal_format_group = $_decimal_format_group->{'content'};
    }

    my $_decimal_format_decimal = defined $symbols_index
      ? (
          ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'decimal'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'decimal'}{'content'}
        : ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'decimal'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'decimal'}->[0]
        : $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'decimal'}

      )
      : (
          ref $raw_struct->{'numbers'}{'symbols'}{'decimal'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}{'decimal'}{'content'}
        : ref $raw_struct->{'numbers'}{'symbols'}{'decimal'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}{'decimal'}->[0]
        :                                                                 $raw_struct->{'numbers'}{'symbols'}{'decimal'}
      );
    if ( ref($_decimal_format_decimal) eq 'HASH' ) {
        $_decimal_format_decimal = $_decimal_format_decimal->{'content'};
    }

    # only fallback if *both* will match
    if ( !$_decimal_format_group && !$_decimal_format_decimal ) {
        $_decimal_format_group   = $fallback_lang_misc_info->{'cldr_formats'}{'_decimal_format_group'};
        $_decimal_format_decimal = $fallback_lang_misc_info->{'cldr_formats'}{'_decimal_format_decimal'};
    }

    # if we are missing one use both it's parent's data if possible
    if ( !$_decimal_format_group || !$_decimal_format_decimal ) {
        my ( $l, $t ) = Locales::split_tag($tag);
        if ($t) {
            if ( my $parent = Locales->new($l) ) {
                no strict 'refs';
                $_decimal_format_group   = ${"Locales::DB::Language::${l}::misc_info"}{'cldr_formats'}->{'_decimal_format_group'};
                $_decimal_format_decimal = ${"Locales::DB::Language::${l}::misc_info"}{'cldr_formats'}->{'_decimal_format_decimal'};
            }
        }
    }

    if ( !$_decimal_format_group || !$_decimal_format_decimal ) {

        # not much we can (accuratly) do, I am open to suggestions :)
        warn "'$tag' is missing one or both decimal format options: _decimal_format_group ($_decimal_format_group) or _decimal_format_decimal ($_decimal_format_decimal) ...";
        if ( $_decimal_format_group eq ',' ) {
            $_decimal_format_decimal = '.';
        }
        elsif ( $_decimal_format_group eq '.' ) {
            $_decimal_format_decimal = ',';
        }
        elsif ( $_decimal_format_decimal eq ',' ) {
            $_decimal_format_group = '.';
        }
        elsif ( $_decimal_format_decimal eq '.' ) {
            $_decimal_format_group = ',';
        }

        # TODO: fallback to values in its numberSystem (e.g. <symbols numberSystem="latn">) (only trips up a few as of CLDR 2.0)
        elsif ( $tag eq 'ak' || $tag eq 'mfe' || $tag eq 'ses' || $tag eq 'khq' || $tag eq 'wal' ) {
            $_decimal_format_decimal = '.';
        }

        else {
            warn "\tCould not make worst-case-best-effort defualt from the curretn value.";
        }
    }

    my $_percent_format_percent = (
        defined $symbols_index
        ? (
              ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'percentSign'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'percentSign'}{'content'}
            : ref $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'percentSign'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'percentSign'}->[0]
            :                                                                                     $raw_struct->{'numbers'}{'symbols'}[$symbols_index]{'percentSign'}
          )
        : (
              ref $raw_struct->{'numbers'}{'symbols'}{'percentSign'} eq 'HASH'  ? $raw_struct->{'numbers'}{'symbols'}{'percentSign'}{'content'}
            : ref $raw_struct->{'numbers'}{'symbols'}{'percentSign'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'symbols'}{'percentSign'}->[0]
            :                                                                     $raw_struct->{'numbers'}{'symbols'}{'percentSign'}
        )
      )
      || $fallback_lang_misc_info->{'cldr_formats'}{'_percent_format_percent'};
    if ( !$_percent_format_percent ) {
        my ( $l, $t ) = Locales::split_tag($tag);
        if ($t) {
            if ( my $parent = Locales->new($l) ) {
                no strict 'refs';
                $_percent_format_percent = ${"Locales::DB::Language::${l}::misc_info"}{'cldr_formats'}->{'_percent_format_percent'};
            }
        }
    }

    # $fallback_lang_misc_info->{'cldr_formats'}{'delimiters'} ||= {
    #     map {
    #        my $norm = $_;
    #        $norm = lcfirst($norm);
    #        $norm =~ s/([A-Z])/_\L$1\E/g;
    #        ($norm => $raw_struct->{'delimiters'}{$_})
    #    } keys %{ $raw_struct->{'delimiters'} }
    # };

    # if ( $tag eq 'pt_br' ) { use Data::Dumper; print Dumper( $tag, $fallback_lang_misc_info ) }

    # ick
    if ( ref( $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'} ) eq 'HASH' ) {
        if ( $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'type'} eq 'short' ) {
            delete $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'};
        }
    }
    elsif ( ref( $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'} ) eq 'ARRAY' ) {
        if ( $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'type'} eq 'short' ) {
            shift @{ $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'} };
        }
    }

    my $plural_form_entry = $plural_forms->{$tag};
    if ( !$plural_form_entry ) {
        my ($parent_tag) = Locales::split_tag($tag);
        if ( $parent_tag ne $tag && exists $plural_forms->{$parent_tag} ) {
            $plural_form_entry = $plural_forms->{$parent_tag};
        }
        else {
            for my $fb ( @{$fallback} ) {
                if ( exists $plural_forms->{$fb} && ref( $plural_forms->{$fb} ) ) {
                    $plural_form_entry = $plural_forms->{$fb};
                    last;
                }
            }
        }
    }

    # DO NOT DO THIS: $plural_form_entry ||= $plural_forms->{'en'};

    $lang_misc_info = {
        'fallback'     => $fallback,
        'cldr_formats' => {
            'decimal' => (
                ref( $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'} ) eq 'ARRAY'
                ? (
                      ref $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'decimalFormat'}{'pattern'} eq 'HASH'  ? $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'decimalFormat'}{'pattern'}{'content'}
                    : ref $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'decimalFormat'}{'pattern'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'decimalFormat'}{'pattern'}->[0]
                    : $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}[0]{'decimalFormat'}{'pattern'}

                  )
                : (
                      ref $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'decimalFormat'}{'pattern'} eq 'HASH'  ? $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'decimalFormat'}{'pattern'}{'content'}
                    : ref $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'decimalFormat'}{'pattern'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'decimalFormat'}{'pattern'}->[0]
                    :                                                                                                                $raw_struct->{'numbers'}{'decimalFormats'}{'decimalFormatLength'}{'decimalFormat'}{'pattern'}
                )
              )
              || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'decimal'} ),
            '_decimal_format_group'   => $_decimal_format_group,
            '_decimal_format_decimal' => $_decimal_format_decimal,
            'percent'                 => (
                  ref $raw_struct->{'numbers'}{'percentFormats'}{'percentFormatLength'}{'percentFormat'}{'pattern'} eq 'HASH'  ? $raw_struct->{'numbers'}{'percentFormats'}{'percentFormatLength'}{'percentFormat'}{'pattern'}{'content'}
                : ref $raw_struct->{'numbers'}{'percentFormats'}{'percentFormatLength'}{'percentFormat'}{'pattern'} eq 'ARRAY' ? $raw_struct->{'numbers'}{'percentFormats'}{'percentFormatLength'}{'percentFormat'}{'pattern'}->[0]
                :                                                                                                                $raw_struct->{'numbers'}{'percentFormats'}{'percentFormatLength'}{'percentFormat'}{'pattern'}
              )
              || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'percent'} ),
            '_percent_format_percent' => $_percent_format_percent,
            'territory'               => $raw_struct->{'localeDisplayNames'}{'codePatterns'}{'codePattern'}{'territory'}{'content'}
              || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'territory'} ),
            'language' => $raw_struct->{'localeDisplayNames'}{'codePatterns'}{'codePattern'}{'language'}{'content'}
              || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'language'} ),
            'locale' => ( Encode::decode_utf8( ref( $raw_struct->{'localeDisplayNames'}{'localeDisplayPattern'}{'localePattern'} ) eq 'HASH' ? $raw_struct->{'localeDisplayNames'}{'localeDisplayPattern'}{'localePattern'}{'content'} : $raw_struct->{'localeDisplayNames'}{'localeDisplayPattern'}{'localePattern'} ) )
              || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'locale'} ),    # wx_yz has no name but wx does and xy may
                                                                                                 # {'localeDisplayNames'}{'localeDisplayPattern'}{'localePattern'}{'localeSeparator'} => ', ' (not needed since we only use territory subtag)
            'list' => {
                '2'      => $raw_struct->{'listPatterns'}{'listPattern'}{'listPatternPart'}{'2'}{'content'}      || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'list'}{'2'} ),
                'end'    => $raw_struct->{'listPatterns'}{'listPattern'}{'listPatternPart'}{'end'}{'content'}    || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'list'}{'end'} ),
                'middle' => $raw_struct->{'listPatterns'}{'listPattern'}{'listPatternPart'}{'middle'}{'content'} || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'list'}{'middle'} ),
                'start'  => $raw_struct->{'listPatterns'}{'listPattern'}{'listPatternPart'}{'start'}{'content'}  || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'list'}{'start'} ),
            },
            'ellipsis' => {

                # Encode::decode_utf8() on current fallback will keep from tripping perl's hash value bytes string bug?
                'final'   => $raw_struct->{'characters'}{'ellipsis'}{'final'}{'content'}   || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'ellipsis'}{'final'} ),
                'initial' => $raw_struct->{'characters'}{'ellipsis'}{'initial'}{'content'} || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'ellipsis'}{'initial'} ),
                'medial'  => $raw_struct->{'characters'}{'ellipsis'}{'medial'}{'content'}  || Encode::decode_utf8( $fallback_lang_misc_info->{'cldr_formats'}{'ellipsis'}{'medial'} ),
            },
        },
        'characters' => {
            'more_information' => (
                ref( $raw_struct->{'characters'}{'moreInformation'} ) eq 'HASH'
                ? ( $raw_struct->{'characters'}{'moreInformation'}{'content'} || Encode::decode_utf8( $fallback_lang_misc_info->{'characters'}{'more_information'} ) )
                : ( $raw_struct->{'characters'}{'moreInformation'} || Encode::decode_utf8( $fallback_lang_misc_info->{'characters'}{'more_information'} ) )
            )
        },
        'delimiters' => {
            map {
                my $norm = $_;
                $norm = lcfirst($norm);
                $norm =~ s/([A-Z])/_\L$1\E/g;

                # print Dumper(
                #     [
                #     $_,
                #     $norm,
                # exists $raw_struct->{'delimiters'}{$_},
                #  $raw_struct->{'delimiters'}{$_},
                #  $fallback_lang_misc_info->{'cldr_formats'}{'delimiters'}{$norm}
                # ]);
                (
                    $norm => (
                        exists $raw_struct->{'delimiters'}{$_}
                        ? ( $raw_struct->{'delimiters'}{$_} || $fallback_lang_misc_info->{'delimiters'}{$norm} )
                        : $fallback_lang_misc_info->{'delimiters'}{$norm}
                    )
                  )
            } ( 'quotationStart', 'quotationEnd', 'alternateQuotationStart', 'alternateQuotationEnd' )
        },
        'plural_forms' => {

            # Order is important for Locale::Maketext::Utils::quant():
            #   one (singular), two (dual), few (paucal), many, other, zero
            'category_list' => [
                (
                    ( grep { exists $plural_form_entry->{$_} } ( Locales::get_cldr_plural_category_list() ) ),
                    exists $plural_form_entry->{'other'} ? () : ('other')    # has to have 'other' at the end if no where else
                )
            ],
            'category_rules' => $plural_form_entry,
        },
        'orientation' => {
            'characters' => $raw_struct->{'layout'}{'orientation'}{'characters'} || $fallback_lang_misc_info->{'orientation'}{'characters'} || 'left-to-right',
            'lines'      => $raw_struct->{'layout'}{'orientation'}{'lines'}      || $fallback_lang_misc_info->{'orientation'}{'lines'}      || 'top-to-bottom',
        },
        'posix' => {
            'yesstr' => $raw_struct->{'posix'}{'messages'}{'yesstr'} || Encode::decode_utf8( $fallback_lang_misc_info->{'posix'}{'yesstr'} ),
            'nostr'  => $raw_struct->{'posix'}{'messages'}{'nostr'}  || Encode::decode_utf8( $fallback_lang_misc_info->{'posix'}{'nostr'} ),

            # TODO: yesexp/noexp
        },
    };

    for my $k ( keys %{ $lang_misc_info->{'delimiters'} } ) {
        if ( ref( $lang_misc_info->{'delimiters'}{$k} ) eq 'HASH' ) {
            $lang_misc_info->{'delimiters'}{$k} = $lang_misc_info->{'delimiters'}{$k}{'content'};
        }
    }

    for my $lng ( sort keys %{ $raw_struct->{'localeDisplayNames'}{'languages'}{'language'} } ) {
        next if $lng eq 'root';

        # if ($tag eq 'en') {
        #     next if !get_xml_file_for($lng,1);
        # }

        my $short = $lng;
        $short =~ tr/A-Z/a-z/;

        my ( $l, $t, @x ) = split( /_/, $short );
        next if @x;
        next if $t && !exists $terr_code_to_name->{$t};

        $lang_code_to_name->{$short} = $raw_struct->{'localeDisplayNames'}{'languages'}{'language'}{$lng}{'content'};
        $lang_name_to_code->{ Locales::normalize_for_key_lookup( $raw_struct->{'localeDisplayNames'}{'languages'}{'language'}{$lng}{'content'} ) } = $short;
    }

    if ($fallback_lang_code_to_name) {
        for my $fb_lng ( keys %{$fallback_lang_code_to_name} ) {
            if ( !exists $lang_code_to_name->{$fb_lng} ) {
                $lang_code_to_name->{$fb_lng} = $fallback_lang_code_to_name->{$fb_lng};
                $lang_name_to_code->{ Locales::normalize_for_key_lookup( $fallback_lang_code_to_name->{$fb_lng} ) } = $fb_lng;
            }
        }
    }
    #### /Languages ####

    # TOOD: ? merge in ant $raw_struct->{'fallback'} (sans language part of $tag or 'en' since those happen alreay) locale's ?

    return ( $lang_code_to_name, $lang_name_to_code, $lang_misc_info, $terr_code_to_name, $terr_name_to_code );
}

sub write_language_module {
    my ( $tag, $code_to_name, $name_to_code, $misc_info ) = @_;

    # init 'category_rules_compiled' key
    Locales::plural_rule_hashref_to_code( $misc_info->{'plural_forms'} );

    my $code_to_name_str = _stringify_hash($code_to_name);
    my $name_to_code_str = _stringify_hash($name_to_code);
    my $misc_info_str;
    {

        # make values in plural_forms->category_rules_compiled be sub { ...} instead of 'sub \{ \.\.\. \}'
        #
        # this adds a package thing, maybe investigate?
        # local $Data::Dumper::Deparse = 1;
        # for my $k (keys %{$misc_info->{plural_forms}{category_rules_compiled}}) {
        #     print "RULE $k: $misc_info->{plural_forms}{category_rules_compiled}{$k}\n";
        #     $misc_info->{plural_forms}{category_rules_compiled}{$k} = eval "$misc_info->{plural_forms}{category_rules_compiled}{$k}";
        # }

        $misc_info_str = _stringify_hash($misc_info);

        for my $k ( keys %{ $misc_info->{'plural_forms'}{category_rules_compiled} } ) {
            $misc_info_str =~ s/(\'\Q$k\E\' \=\>) \"(sub\\ \\\{.*)\"/"$1" . String::Unquotemeta::unquotemeta("$2")/e;
        }

        # print "DEBUG:\n$misc_info_str\n";exit;
    }
    _write_utf8_perl(
        "Language/$tag.pm", qq{package Locales::DB::Language::$tag;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::Language::$tag\::VERSION = '$mod_version';

\$Locales::DB::Language::$tag\::cldr_version = '$cldr_version';

\%Locales::DB::Language::$tag\::misc_info = (
$misc_info_str,
);

\%Locales::DB::Language::$tag\::code_to_name = ( 
$code_to_name_str,
);

\%Locales::DB::Language::$tag\::name_to_code = (
$name_to_code_str,
);

1;    
},
    );
}

sub write_territory_module {
    my ( $tag, $code_to_name, $name_to_code ) = @_;

    my $code_to_name_str = _stringify_hash($code_to_name);
    my $name_to_code_str = _stringify_hash($name_to_code);

    _write_utf8_perl(
        "Territory/$tag.pm", qq{package Locales::DB::Territory::$tag;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::Territory::$tag\::VERSION = '$mod_version';

\$Locales::DB::Territory::$tag\::cldr_version = '$cldr_version';

\%Locales::DB::Territory::$tag\::code_to_name = (
$code_to_name_str,
);

\%Locales::DB::Territory::$tag\::name_to_code = (
$name_to_code_str,
);

1;

},
    );

}

my @_get_fast_norm_test_data = ( '', 0 );

sub _get_fast_norm_test_data {
    if ( $_get_fast_norm_test_data[1] == 0 ) {
        my $loc = Locales->new();
        my $cnt = 12;
        for my $l ( sort $loc->get_language_codes() ) {
            $_get_fast_norm_test_data[0] .= qq{is(\$self_obj->get_locale_display_pattern_from_code('$l'), \$self_obj->get_locale_display_pattern_from_code_fast('$l'), 'get_locale_display_pattern_from_code[_fast] same result for $l');\n};
            $_get_fast_norm_test_data[1]++;

            $_get_fast_norm_test_data[0] .= qq{is(\$self_obj->get_character_orientation_from_code('$l'), \$self_obj->get_character_orientation_from_code('$l'), 'get_character_orientation_from_code[_fast] same result for $l');\n};
            $_get_fast_norm_test_data[1]++;

            $_get_fast_norm_test_data[0] .= "\n";
        }
    }

    return @_get_fast_norm_test_data;
}

sub write_locale_test {
    my ($tag) = @_;

    my ( $fast_norm_str, $fast_norm_cnt ) = _get_fast_norm_test_data();

    _write_utf8_perl(
        "../../../t/042.$tag.t", qq{
# Auto generated during CLDR build

use Test::More tests => 13 + $fast_norm_cnt;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Locales::DB::Language::$tag' );
use_ok( 'Locales::DB::Territory::$tag' );
}

diag( "Sanity checking Locales::DB::Language::$tag \$Locales::DB::Language::$tag\::VERSION DB" );

use Locales;
use Locales::DB::Language::en;
use Locales::DB::Territory::en;

my \@en_lang_codes = sort(keys \%Locales::DB::Language::en::code_to_name);
my \@en_terr_codes = sort(keys \%Locales::DB::Territory::en::code_to_name);

my \@my_lang_codes = sort(keys \%Locales::DB::Language::$tag\::code_to_name);
my \@my_terr_codes = sort(keys \%Locales::DB::Territory::$tag\::code_to_name);
my \%lang_lu;
my \%terr_lu;
\@lang_lu{ \@my_lang_codes } = ();
\@terr_lu{ \@my_terr_codes } = ();
ok(\$Locales::DB::Language::$tag\::cldr_version eq \$Locales::cldr_version, 'CLDR version is correct');
ok(\$Locales::DB::Language::$tag\::VERSION eq (\$Locales::VERSION - $v_offset), 'VERSION is correct');

ok(!(grep {!exists \$lang_lu{\$_} } \@en_lang_codes), '$tag languages contains en');
ok(!(grep {!exists \$terr_lu{\$_} } \@en_terr_codes), '$tag territories contains en');

my \%uniq = ();
grep { not \$uniq{\$_}++ } \@{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_list'} };
is_deeply(
    [ sort \@{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_list'} }],
    [ sort keys \%uniq ],
    "'category_list' contains no duplicates"
);

ok(grep(m/^other\$/, \@{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_list'} }), "'category_list' has 'other'");

is_deeply(
    [ grep !m/^other\$/, sort \@{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_list'} }],
    [ grep !m/^other\$/, sort keys \%{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules'} } ],
    "'category_rules' has necessary 'category_list' items"
);

is_deeply(
    [ sort keys \%{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules'} } ],
    [ sort keys \%{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules_compiled'} } ],
    "each 'category_rules' has a 'category_rules_compiled'"
);
my \$ok_rule_count = 0;
my \$error = '';
for my \$rule (keys \%{\$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules_compiled'}}) {
    if (ref(\$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules_compiled'}{\$rule}) eq 'CODE') {
        \$ok_rule_count++;
        next;
    }
    eval \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules_compiled'}{\$rule};
    if (\$@) {
        \$error .= \$@;
        next;
    }
    else {
        \$ok_rule_count++;
    }
}
ok(\$ok_rule_count == keys \%{ \$Locales::DB::Language::$tag\::misc_info{'plural_forms'}->{'category_rules_compiled'} }, "each 'category_rules_compiled' eval without error - count");
is(\$error, '', "each 'category_rules_compiled' is a code ref or evals without error - errors");

my \$self_obj = Locales->new('$tag');
ok(ref(\$self_obj), '$tag object created OK');

$fast_norm_str

        },
        "t/042.$tag.t",
    );
}

sub write_get_plural_form_test {
    my ($tag) = @_;

    my $loc = Locales->new($tag) || die die "Could not create object for $tag: \$@";

    my $arg_tests_count = 2;
    if ( $loc->get_plural_form(0) eq 'other' ) {
        $arg_tests_count = 4;
    }

    _write_utf8_perl(
        "../../../t/06.$tag.t", qq{
# Auto generated during CLDR build

use lib 'lib', '../lib';
use Test::More;

use Locales;

diag( "Verifying perl and js get_plural_form() behave the same for $tag." );

if (!\$ENV{'RELEASE_TESTING'}) {
    plan 'skip_all' => 'These tests are only run under RELEASE_TESTING.';
}

my \$obj = Locales->new('$tag') || die "Could not create object for $tag: \$@";

my \@nums = ( 0, 1.6, 2.2, 3.14159, 42.78, 0 .. 256 );

eval 'use JE ()';
plan \$@ ? ( 'skip_all' => 'JE.pm required for testing JS/Perl plural behavior tests' ) : ( 'tests' => ( scalar(\@nums) * (4 + $arg_tests_count) ) );
my \$js = JE->new();

use File::Slurp;
my \$root = '.';    # TODO: make me portable
if ( -d '../share/' ) {
    \$root = '..';
}
if ( !-d "\$root/share/" ) {
    die "Can not determine share directory.";
}

my \@cats = map { "args_\$_" } \$obj->get_plural_form_categories();
my \$cats_args = join(', ', map { "'\$_'" } \@cats);

my \$jsfile = File::Slurp::read_file("\$root/share/functions/\$obj->{'locale'}.js") or die "Could not read '\$root/share/functions/\$obj->{'locale'}.js': \$!";

for my \$n (\@nums) {
    my \$res = \$js->eval("var X = \$jsfile;return X.get_plural_form(\$n)");
    is_deeply(
        [ \$res->[0], \$res->[1] ],    # have to do this to stringify JE object properly
        [ \$obj->get_plural_form(\$n) ],
        "perl and js get_plural_form() behave the same. Tag: \$obj->{'locale'} Number: \$n"
    );
    is(\$res->[1], 0, "using special is 0 for \$n (no args)");
    
    my \$res_n = \$js->eval("var X = \$jsfile;return X.get_plural_form(-\$n)");
    is_deeply(
        [ \$res_n->[0], \$res_n->[1] ],    # have to do this to stringify JE object properly
        [ \$obj->get_plural_form("-\$n") ],
        "perl and js get_plural_form() behave the same. Tag: \$obj->{'locale'} Number: -\$n"
    );
    is(\$res_n->[1], 0, "using special is 0 for -\$n (no args)");
    
    my \$res_s = \$js->eval("var X = \$jsfile;return X.get_plural_form(\$n,\$cats_args)");
    is_deeply(
        [ \$res_s->[0], \$res_s->[1] ],    # have to do this to stringify JE object properly
        [ \$obj->get_plural_form(\$n,\@cats) ],
        "perl and js get_plural_form() behave the same. Tag: \$obj->{'locale'} Number: \$n"
    );
    is(\$res_s->[1], 0, "using special is 0 for \$n (args w/ no spec zero)");

    if ($arg_tests_count == 4) {
        my \$res_n = \$js->eval("var X = \$jsfile;return X.get_plural_form(\$n, \$cats_args, 'spec_zeroth')");
        is_deeply(
            [ \$res_n->[0], \$res_n->[1] ],    # have to do this to stringify JE object properly
            [ \$obj->get_plural_form("\$n",\@cats, 'spec_zeroth') ],
            "perl and js get_plural_form() behave the same. Tag: \$obj->{'locale'} Number: \$n"
        );
        my \$spec_bool = \$n == 0 ? 1 : 0;
        is(\$res_n->[1], \$spec_bool, "using special is \$spec_bool for \$n (args w/ spec zero)");
    }
    
     # TODO: ? too many/too few args and check for carp ?
}
        },
        "t/06.$tag.t",
    );
}

sub write_native_module {
    my ( $native_map, $fallback_lookup ) = @_;

    my $code_to_name_str    = _stringify_hash_no_dumper($native_map);
    my $fallback_lookup_str = _stringify_hash_no_dumper($fallback_lookup);

    # nerd alert! TODO: verify during next build
    if ( $code_to_name_str->{'tlh'} eq 'Klingon' ) {    # i.e. no CLDR data for tlh

        # "\x{f8e4}\x{f8d7}\x{f8dc}\x{f8d0}\x{f8db}"
        # "\xef\xa3\xa4\xef\xa3\x97\xef\xa3\x9c\xef\xa3\x90\xef\xa3\x9b"
        $code_to_name_str->{'tlh'} = "";    # need a font to see this, like Bengali
    }

    _write_utf8_perl(
        "$locales_db/Native.pm", qq{package Locales::DB::Native;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::Native::VERSION = '$mod_version';

\$Locales::DB::Native::cldr_version = '$cldr_version';

\%Locales::DB::Native::code_to_name = ( 
$code_to_name_str);

\%Locales::DB::Native::value_is_fallback = (
$fallback_lookup_str);

1;    
},
        'lib/Locales/DB/Native.pm',
        1,
    );
}

sub write_db_loadable_module {
    my $en = Locales->new('en');

    my $code_hr;
    my $terr_hr;

    for my $t ( $en->get_territory_codes() ) {
        $terr_hr->{$t} = 1;
    }

    for my $c ( $en->get_language_codes() ) {
        next if Locales::is_non_locale($c);

        if ( Locales->new($c) ) {
            $code_hr->{$c} = 1;
        }
    }

    my $code_str = _stringify_hash_no_dumper($code_hr);
    my $terr_str = _stringify_hash_no_dumper($terr_hr);

    _write_utf8_perl(
        "$locales_db/Loadable.pm", qq{package Locales::DB::Loadable;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::Loadable::VERSION = '$mod_version';

\$Locales::DB::Loadable::cldr_version = '$cldr_version';

\%Locales::DB::Loadable::code = ( 
$code_str);

\%Locales::DB::Loadable::territory = (
$terr_str);

1;    
        },
        'lib/Locales/DB/Loadable.pm',
        1,
    );

}

sub write_character_orientation_module {
    my ( $text_direction_map, $fallback_lookup ) = @_;

    my $code_to_name_str    = _stringify_hash_no_dumper($text_direction_map);
    my $fallback_lookup_str = _stringify_hash_no_dumper($fallback_lookup);

    _write_utf8_perl(
        "$locales_db/CharacterOrientation.pm", qq{package Locales::DB::CharacterOrientation;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::CharacterOrientation::VERSION = '$mod_version';

\$Locales::DB::CharacterOrientation::cldr_version = '$cldr_version';

\%Locales::DB::CharacterOrientation::code_to_name = ( 
$code_to_name_str);

\%Locales::DB::CharacterOrientation::value_is_fallback = (
$fallback_lookup_str);

1;    
},
        'lib/Locales/DB/CharacterOrientation.pm',
        1,
    );

    File::Path::Tiny::mk("$locales_db/CharacterOrientation") || die "Could not create '$locales_db/CharacterOrientation': $!";
    my $rtl;
    for my $name ( keys %{$text_direction_map} ) {
        if ( $text_direction_map->{$name} eq 'right-to-left' ) {
            $rtl->{$name} = undef();
        }
        elsif ( $text_direction_map->{$name} ne 'left-to-right' ) {
            warn "$name is neither right-to-left or left-to-right";
        }
    }
    die "Locales::DB::CharacterOrientation::Tiny lookup hash not built" if ref($rtl) ne 'HASH';
    $rtl = _stringify_hash_no_dumper($rtl);

    _write_utf8_perl(
        "$locales_db/CharacterOrientation/Tiny.pm", qq{package Locales::DB::CharacterOrientation::Tiny;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::CharacterOrientation::Tiny::VERSION = '$mod_version';

\$Locales::DB::CharacterOrientation::Tiny::cldr_version = '$cldr_version';

my \%rtl = (
$rtl);

sub get_orientation {
    if ( exists \$rtl{ \$_[0] } ) {
        return 'right-to-left';
    }
    else {
        require Locales;
        my (\$l) = Locales::split_tag(\$_[0]);
        if (\$l ne \$_[0]) {
            return 'right-to-left' if exists \$rtl{ \$l };
        }
        return 'left-to-right';
    }
}

1;
},
        'lib/Locales/DB/CharacterOrientation/Tiny.pm',
        1,
    );
}

sub write_name_pattern_module {
    my ( $name_pattern, $isfallback ) = @_;

    my $name_pattern_str    = _stringify_hash_no_dumper($name_pattern);
    my $fallback_lookup_str = _stringify_hash_no_dumper($isfallback);

    _write_utf8_perl(
        "$locales_db/LocaleDisplayPattern.pm", qq{package Locales::DB::LocaleDisplayPattern;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::LocaleDisplayPattern::VERSION = '$mod_version';

\$Locales::DB::LocaleDisplayPattern::cldr_version = '$cldr_version';

\%Locales::DB::LocaleDisplayPattern::code_to_pattern = ( 
$name_pattern_str);

\%Locales::DB::LocaleDisplayPattern::value_is_fallback = (
$fallback_lookup_str);

1;    
},
        'lib/Locales/DB/LocaleDisplayPattern.pm',
        1,
    );

    # $locales_db/LocaleDisplayPattern
    File::Path::Tiny::mk("$locales_db/LocaleDisplayPattern") || die "Could not create '$locales_db/CharacterOrientation': $!";

    my $name_pattern_hr;

    require Locales::DB::Language::en;
    my $default_pattern = $Locales::DB::Language::en::misc_info{'cldr_formats'}{'locale'};
    for my $k ( keys %{$name_pattern} ) {
        next if !$name_pattern->{$k} || $name_pattern->{$k} =~ m/^\s+$/ || $name_pattern->{$k} eq $default_pattern;
        $name_pattern_hr->{$k} = $name_pattern->{$k};
    }

    die "Locales::DB::LocaleDisplayPattern::Tiny lookup hash not built" if ref($name_pattern_hr) ne 'HASH';
    $name_pattern_hr = _stringify_hash_no_dumper($name_pattern_hr);

    $default_pattern = quotemeta($default_pattern);

    # $locales_db/LocaleDisplayPattern/Tiny.pm
    _write_utf8_perl(
        "$locales_db/LocaleDisplayPattern/Tiny.pm", qq{package Locales::DB::LocaleDisplayPattern::Tiny;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::LocaleDisplayPattern::Tiny::VERSION = '$mod_version';

\$Locales::DB::LocaleDisplayPattern::Tiny::cldr_version = '$cldr_version';

my \%locale_display_lookup = (
$name_pattern_hr);

sub get_locale_display_pattern {
    if ( exists \$locale_display_lookup{ \$_[0] } ) {
        return \$locale_display_lookup{ \$_[0] };
    }
    else {
        require Locales;
        my (\$l) = Locales::split_tag(\$_[0]);
        if (\$l ne \$_[0]) {
            return \$locale_display_lookup{\$l} if exists \$locale_display_lookup{ \$l };
        }
        return "$default_pattern";
    }
}

1;
},
        'lib/Locales/DB/LocaleDisplayPattern/Tiny.pm',
        1,
    );
}

sub write_plural_forms_argument_pod {
    my ( $plural_forms, $isfallback ) = @_;
    File::Path::Tiny::mk("$locales_db/Docs") || die "Could not create '$locales_db/Docs': $!";

    my $pod_starts = '__END__';                           # this is to help prevent mis-parsing for CPAN like rt 76129 (probably not necessary)
    my $pkg        = 'Locales::DB::Docs::PluralForms';    # this is to help prevent mis-parsing for CPAN like rt 76129
    my $pod_mark   = '=';                                 # this is to help prevent mis-parsing for CPAN like rt 80546 (and not fixed *again* in 0.28)
    my $pod_items  = '';

    for my $ent ( @{$plural_forms} ) {

        if ( exists $isfallback->{ $ent->{'tag'} } ) {
            $pod_items .= "=item $ent->{'tag'}\n\nCLDR $cldr_version did not define data for “$ent->{'tag'}”, thus it will fallback to L</en> behavior.\n\nYou can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.\n\n";
        }
        else {
            $pod_items .= "=item $ent->{'tag'}\n\n$fb    get_plural_form(\$n, $ent->{'csv'})\n";
            if ( $ent->{'zero_is_not_other'} ) {
                $pod_items .= "\nNote: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for $ent->{'tag'}\n\n";
            }
            else {
                $pod_items .= "    get_plural_form(\$n, $ent->{'csv'}, special_zero)\n\n";
            }
        }
    }

    # $locales_db/Docs/PluralForms.pm
    _write_utf8_perl(
        "$locales_db/Docs/PluralForms.pm", qq{package $pkg;

use strict;
use warnings;

# Auto generated from CLDR
use if \$Locales::_UNICODE_STRINGS, 'utf8';

\$Locales::DB::Docs::PluralForms::VERSION = '$mod_version';

\$Locales::DB::Docs::PluralForms::cldr_version = '$cldr_version';

1;

$pod_starts

${pod_mark}encoding utf-8

${pod_mark}head1 NAME

Locales::DB::Docs::PluralForms - plural form details reference for all
included locales

${pod_mark}head1 VERSION

Locales.pm v$mod_version (based on CLDR v$cldr_version)

${pod_mark}head1 DESCRIPTION

CLDR L<defines a set of broad plural categories and rules|http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html> that determine which category any given number will fall under.

L<Locales> allows you to determine the plural categories applicable to a specific locale and also which category a given number will fall under in that locale.

This POD documents which categories and in what order you'd specify them in additional arguments to L<Locales/get_plural_form()> (i.e. the optional arguments after the number).

${pod_mark}head2 “Special Zero” Argument

In addition to the CLDR category value list you can also specify one additional argument of what to use for zero instead of the value for “other”.

This won't be used if 0 falls under a specific category besides “other”.

${pod_mark}head1 Plural Category Argument Order Reference

${pod_mark}over 4

$pod_items

${pod_mark}back

${pod_mark}head1 BUGS AND LIMITATIONS

Please see L<Locales/BUGS AND LIMITATIONS>

${pod_mark}head2 BEFORE YOU SUBMIT A BUG REPORT

Please see L<Locales/BEFORE YOU SUBMIT A BUG REPORT>

${pod_mark}head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

${pod_mark}head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

${pod_mark}head1 DISCLAIMER OF WARRANTY

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

},
        'lib/Locales/DB/Docs/PluralForms.pm',
        1,
    );
}

sub build_javascript_share {
    my ($tag) = @_;

    if ( -d 'share/' ) {
        File::Path::Tiny::rm('share/') || die "Could not remove 'share/': $!";
    }
    for my $d (qw(misc_info/ functions/ code_to_name/ datetime/ db/)) {
        File::Path::Tiny::mk("share/$d") || die "Could not create 'share/$d': $!";
    }

    my $loc = Locales->new();
    for my $tag ( sort $loc->get_language_codes() ) {
        my $tag_loc = Locales->new($tag) || next;

        my $guts_m = $tag_loc->{'language_data'}{'misc_info'};
        for my $k ( keys %{ $guts_m->{'plural_forms'}{'category_rules_compiled'} } ) {
            $guts_m->{'plural_forms'}{'category_rules_compiled'}{$k} = Locales::plural_rule_string_to_javascript_code( $guts_m->{'plural_forms'}{'category_rules'}{$k}, $k );
        }
        my $json = JSON::Syck::Dump($guts_m);    # no eval, lets just die
        $json =~ s/\"(function \(n\) \{)/$1/g;
        $json =~ s/(return\;\})\"/$1/g;

        open( my $fh_m, '>', "share/misc_info/$tag.js" ) or die "Could not open 'share/misc_info/$tag.js': $!";
        print {$fh_m} $json;
        close $fh_m;

        my $cats_list_js = JSON::Syck::Dump( $guts_m->{'plural_forms'}{'category_list'} );
        my $cats_proc_js = JSON::Syck::Dump( [ Locales::get_cldr_plural_category_list(1) ] );
        my $cats_rule_js = JSON::Syck::Dump( $guts_m->{'plural_forms'}{'category_rules_compiled'} );
        $cats_rule_js =~ s/"(function[^"]+)"/$1/g;

        open( my $fh_f, '>', "share/functions/$tag.js" ) or die "Could not open 'share/functions/$tag.js': $!";

        # var category_process_order = $cats_proc_js;
        # var category_rules_lookup  = $cats_rule_js;
        # var categories = $cats_list_js;

        my $js_code = <<"END_FUNC";
{
    'get_plural_form' : function (n) {
        var category;
        var category_values = Array.prototype.slice.call(arguments,1);

        var has_extra_for_zero = 0;
        var abs_n = Math.abs(n);
        var category_process_order = $cats_proc_js;
        var category_rules_lookup  = $cats_rule_js;

        for (i=0; i < category_process_order.length; i++) {
            if (category_rules_lookup[category_process_order[i]]) {
                category = category_rules_lookup[category_process_order[i]](abs_n);
                if (category) break;
            }
        }

        var categories = $cats_list_js;

        if ( category_values.length === 0 ) {
             category_values = categories; // no args will return the category name
        }
        else {
            var cat_len = categories.length;
            var val_len = category_values.length;

            var cat_len_plus_one = cat_len + 1;
            if ( val_len === cat_len_plus_one ) {
                has_extra_for_zero++;
            }
            else if ( cat_len !== val_len ) {
                if (window.console) console.warn( 'The number of given values (' + val_len + ') does not match the number of categories (' + cat_len + ').' );
            }
        }

        if ( category === undefined) {
            var cat_idx = has_extra_for_zero && abs_n !== 0 ? -2 : -1;
            var sliced = category_values.slice(cat_idx);
            return [sliced[0], has_extra_for_zero && abs_n === 0 ? 1 : 0];
        }
        else {
            var return_value;
          GET_POSITION:
            while(1) {
                var cat_pos_in_list;
                var index = -1;
               CATEGORY:
                 for (i=0; i < categories.length; i++ ) {
                     index++;
                     if ( categories[i] === category ) {
                         cat_pos_in_list = index;
                         break CATEGORY;
                     }
                 }

                 if ( cat_pos_in_list === undefined && category !== 'other' ) {
                     if (window.console) console.warn( 'The category (' + category + ') is not used by this locale.');
                     category = 'other';
                     continue GET_POSITION;
                 }
                 else if ( cat_pos_in_list === undefined) {
                     var cat_idx = has_extra_for_zero && abs_n !== 0 ? -2 : -1;
                     var sliced = category_values.slice(cat_idx);
                     return_value = [sliced[0], has_extra_for_zero && abs_n === 0 ? 1 : 0]
                     break GET_POSITION;
                 }
                 else {
                     if ( has_extra_for_zero && category === 'other' ) {
                         var cat_idx = has_extra_for_zero && abs_n === 0 ? -1 : cat_pos_in_list;
                         var sliced = category_values.slice(cat_idx);
                         return_value = [sliced[0], has_extra_for_zero && abs_n === 0 ? 1 : 0];
                         break GET_POSITION;
                     }
                     else {
                         return_value = [category_values[cat_pos_in_list], 0];
                         break GET_POSITION;
                     }
                 }
                 break GET_POSITION;
            }

            return return_value;
        }
    }
}
END_FUNC
        print {$fh_f} JavaScript::Minifier::XS::minify($js_code);
        close $fh_f;

        my $json_c = JSON::Syck::Dump( $tag_loc->{'language_data'}{'code_to_name'} );    # no eval, lets just die

        open( my $fh_c, '>', "share/code_to_name/$tag.json" ) or die "Could not open 'share/code_to_name/$tag.json': $!";
        print {$fh_c} $json_c;
        close $fh_c;

        my $dt_struct;
        my $dt_loc = eval { DateTime::Locale->load( Locales::normalize_tag_for_datetime_locale($tag) ) };
        if ($@) {

            # Locales has $tag but DateTime::Locales does not (different CLDR version probably)
            print "$tag datetime JSON will be en: $@";
            $dt_loc = DateTime::Locale->load('en');
        }

        for my $format (@dt_available_formats) {
            $dt_struct->{'format_for'}{$format} = $dt_loc->format_for($format);    # no eval, should die since it means incomplete data
        }
        for my $meth (@dt_methods) {
            my $res = $dt_loc->$meth();
            $dt_struct->{$meth} =
                ref($res) eq 'ARRAY' ? [ @{$res} ]
              : ref($res) eq 'HASH'  ? { %{$res} }
              :                        $res;
        }

        my $json_d = JSON::Syck::Dump($dt_struct);                                 # no eval, lets just die
        open( my $fh_d, '>', "share/datetime/$tag.json" ) or die "Could not open 'share/datetime/$tag.json': $!";
        print {$fh_d} $json_d;
        close $fh_d;

        append_file( $manifest, "share/misc_info/$tag.js\nshare/code_to_name/$tag.json\nshare/datetime/$tag.json\nshare/functions/$tag.js\n" );
    }

    require Locales::DB::Loadable;
    my $json_d = JSON::Syck::Dump( { 'code' => \%Locales::DB::Loadable::code, 'territory' => \%Locales::DB::Loadable::territory } );    # no eval, lets just die
    open( my $fh_d, '>', "share/db/loadable.json" ) or die "Could not open 'share/db/loadable.json': $!";
    print {$fh_d} $json_d;
    close $fh_d;

    append_file( $manifest, "share/db/loadable.json" );
}

sub build_manifest {
    my $base = $manifest;
    $base =~ s{\.build$}{};
    my @in = read_file("$base.in");
    my @bl = read_file("$base.build");
    write_file( $base, @in, @bl );
}

sub do_changelog {
    my $changelog = $manifest;
    $changelog =~ s{MANIFEST\.build$}{Changes};
    my @cl = read_file($changelog);
    return if grep /^$Locales::VERSION\s+/, @cl;

    my $time    = localtime();
    my $new_ent = <<"END_CL";
$Locales::VERSION  $time
     - Updated data to CLDR $Locales::cldr_version

END_CL
    write_file( $changelog, $new_ent, @cl );
}

sub _write_utf8_perl {
    my ( $file, $guts, $mani, $open_plain ) = @_;

    my $open = $open_plain ? '>' : '>:utf8';    #:utf8 breaks Native.pm

    open( my $fh, $open, $file ) or die "Could not open '$file': $!";
    print {$fh} $guts;
    close $fh;

    system( qw(perltidy -b), $file ) == 0 || die "perltidy failed, '$file' probably has syntax errors";
    unlink "$file.bak";

    append_file( $manifest, $mani ? "$mani\n" : "lib/Locales/DB/$file\n" );
}

sub _stringify_hash_no_dumper {
    my $string;
    for my $k ( keys %{ $_[0] } ) {
        my $qk = $k;
        my $qv = $_[0]->{$k};
        $qk =~ s{\'}{\\\'}g;
        $qv =~ s{\'}{\\\'}g;
        my $ky = $k ne $qk          ? qq{"$qk"} : qq{'$k'};
        my $vl = $_[0]->{$k} ne $qv ? qq{"$qv"} : qq{'$_[0]->{$k}'};
        $string .= "$ky => $vl,\n";
    }
    return $string;
}

sub _stringify_hash {
    my $string = Dumper( $_[0] );
    $string =~ s/^\s*\{\s*//;
    $string =~ s/\s*\}\s*$//;
    return $string;
}

1;
