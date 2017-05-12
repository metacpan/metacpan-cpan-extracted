package Locale::Maketext::Utils;

# these work fine, but are not used in production
# use strict;
# use warnings;
$Locale::Maketext::Utils::VERSION = '0.42';

use Locale::Maketext 1.21 ();
use Locales 0.26          ();
use Locales::DB::CharacterOrientation::Tiny ();
use Locales::DB::LocaleDisplayPattern::Tiny ();

@Locale::Maketext::Utils::ISA = qw(Locale::Maketext);

my %singleton_stash = ();

# This is necessary to support embedded arguments (e.g. '... [output,foo,bar _1 baz] ...') and not interpolate things in the arguments that look like embedded args (e.g. argument #1 is '_2')
sub _compile {
    my ( $lh, $string, @args ) = @_;
    $string =~ s/_TILDE_/~~/g;    # this helps make parsing easier (via code or visually)

    my $compiled = $lh->SUPER::_compile($string);
    return $compiled if ref($compiled) ne 'CODE';

    return sub {
        my ( $lh, @ref_args ) = @_;

        # Change embedded-arg-looking-string to a not-likley-to-exist-but-if-it-does-then-you-have-bigger-problems placeholder (i.e. '_1 -!-1-!-' would act wonky, so don't do that)
        @ref_args = map { s/\_(\-?[0-9]+|\*)/-!-$1-!-/g if defined; $_ } @ref_args;
        my $built = $compiled->( $lh, @ref_args );    # if an method that supported embedded args ever looked for /\_(\-?[0-9]+|\*)/ and acted upon it then it'd need to be aware of this convention and operate on /-!-(\-?[0-9]+|\*)-!-/ instead (or better yet don't have it look for an act upon things that look like bracket notation arguments)
        $built =~ s/-!-(\-?[0-9]+|\*)-!-/_$1/g;       # Change placeholders back to their original

        return $built;
    };
}

# surgically alter a part of L::M::_langtag_munging() that is buggy but cannot otherwise be overridden
no warnings 'redefine';
*I18N::LangTags::panic_languages = sub {              # make it CLDR based instead of arbitrary
    my (@languages) = @_;

    my @tags;

    for my $arg (@languages) {
        next if substr( $arg, 0, 2 ) =~ m/i[-_]/;

        my $loc = Locales->new($arg);
        next if !$loc;
        push @tags, $loc->get_fallback_list();
    }

    return @tags, @languages, 'en';    # same results but CLDR based instead of arbitrary (e.g. it falling back to es, whaaaa?)
};

sub get_handle {
    my ( $class, @langtags ) = @_;

    # order is important so we don't sort() in an attempt to normalize (i.e. fr, es is not the same as es, fr)
    my $args_sig = join( ',', @langtags ) || 'no_args';

    if ( exists $singleton_stash{$class}{$args_sig} ) {
        $singleton_stash{$class}{$args_sig}->{'_singleton_reused'}++;
    }
    else {
        $singleton_stash{$class}{$args_sig} = $class->SUPER::get_handle(@langtags);
    }

    return $singleton_stash{$class}{$args_sig};
}

sub get_locales_obj {
    my ( $lh, $tag ) = @_;
    $tag ||= $lh->get_language_tag();

    if ( !exists $lh->{'Locales.pm'}{$tag} ) {
        $lh->{'Locales.pm'}{$tag} =
             Locales->new($tag)
          || ( $tag ne substr( $tag, 0, 2 ) ? Locales->new( substr( $tag, 0, 2 ) ) : '' )
          || (
            $lh->{'fallback_locale'}
            ?        ( Locales->new( $lh->{'fallback_locale'} )
                  || ( $lh->{'fallback_locale'} ne substr( $lh->{'fallback_locale'}, 0, 2 ) ? Locales->new( substr( $lh->{'fallback_locale'}, 0, 2 ) ) : '' ) )
            : ''
          )
          || Locales->new('en');
    }

    return $lh->{'Locales.pm'}{$tag};
}

sub init {
    my ($lh) = @_;

    $ENV{'maketext_obj'} = $lh if !$ENV{'maketext_obj_skip_env'};

    $lh->SUPER::init();
    $lh->remove_key_from_lexicons('_AUTO');

    # use the base class if available, then the class itself if available
    no strict 'refs';
    for my $ns ( $lh->get_base_class(), $lh->get_language_class() ) {
        if ( defined ${ $ns . '::Encoding' } ) {
            $lh->{'encoding'} = ${ $ns . '::Encoding' } if ${ $ns . '::Encoding' };
        }
    }

    # This will happen on the first call to get_context() or context_is*() so we do not do it here to avoid doing the work unless we actually need it.
    # $lh->set_context();

    $lh->fail_with(
        sub {
            my ( $lh, $key, @args ) = @_;

            my $lookup;
            if ( exists $lh->{'_get_key_from_lookup'} ) {
                if ( ref $lh->{'_get_key_from_lookup'} eq 'CODE' ) {
                    $lookup = $lh->{'_get_key_from_lookup'}->( $lh, $key, @args );
                }
            }

            return $lookup if defined $lookup;

            if ( exists $lh->{'_log_phantom_key'} ) {
                if ( ref $lh->{'_log_phantom_key'} eq 'CODE' ) {
                    $lh->{'_log_phantom_key'}->( $lh, $key, @args );
                }
            }

            if ( $lh->{'use_external_lex_cache'} ) {
                local $lh->{'_external_lex_cache'}{'_AUTO'} = 1;

                # _AUTO does not short circuit _ keys so we can get a loop
                if ( $key =~ m/^_/s ) {
                    return $lh->{'_external_lex_cache'}{$key} = $key;
                }
                return $lh->maketext( $key, @args );
            }
            else {
                no strict 'refs';
                local ${ $lh->get_base_class() . '::Lexicon' }{'_AUTO'} = 1;

                # _AUTO does not short circuit _ keys so we can get a loop
                if ( $key =~ m/^_/s ) {
                    return ${ $lh->get_base_class() . '::Lexicon' }{$key} = $key;
                }

                return $lh->maketext( $key, @args );
            }
        }
    );
}

sub makevar {
    my ( $lh, $phrase, @args ) = @_;
    @_ = ( $lh, @{$phrase} ) if !@args && ref($phrase) eq 'ARRAY';    # Feature per rt 85588
    goto &Locale::Maketext::maketext;
}

# TODO Normalize White Space [into key form] (name? export, do meth/function or just funtion?, etc), needs POD and tests once finalized (update parser also: rt 80489)
# sub _NWS {
#
#     # $lh->_NWS($str) || _NWS($str)
#     my $string = @_ > 1 ? $_[1] : $_[0];
#
#     $string =~ s/\s+/ /g;
#     $string =~ s/\A(?:\x20|\xc2\xa0)+//g;      # remove leading white space
#     $string =~ s/(?:\x20|\xc2\xa0){2,}/ /g;    # collapse multiple internal white space
#     $string =~ s/(?:\x20|\xc2\xa0)+\z//g;      # remove trailing white space
#     if ( substr( $string, 0, 3 ) eq "\xE2\x80\xA6" ) {
#         $string = " $string";
#     }
#     return $string;
# }

sub makethis {
    my ( $lh, $phrase, @phrase_args ) = @_;

    $lh->{'cache'}{'makethis'}{$phrase} ||= $lh->_compile($phrase);

    my $type = ref( $lh->{'cache'}{'makethis'}{$phrase} );

    if ( $type eq 'SCALAR' ) {
        return ${ $lh->{'cache'}{'makethis'}{$phrase} };
    }
    elsif ( $type eq 'CODE' ) {
        return $lh->{'cache'}{'makethis'}{$phrase}->( $lh, @phrase_args );
    }
    else {

        # ? carp() ?
        return $lh->{'cache'}{'makethis'}{$phrase};
    }
}

# We do this because we do not want the language semantics of $lh
sub makethis_base {
    my ($lh) = @_;
    $lh->{'cache'}{'makethis_base'} ||= $lh->get_base_class()->get_handle( $lh->{'fallback_locale'} || 'en' );    # this allows to have a seperate cache of compiled phrases (? get_handle() explicit or base_locales() (i.e. en en_us i_default || L::M->fallback_languages) ?)
    return $lh->{'cache'}{'makethis_base'}->makethis( @_[ 1 .. $#_ ] );
}

sub make_alias {
    my ( $lh, $pkgs, $is_base_class ) = @_;

    my $ns = $lh->get_language_class();
    return if $ns !~ m{ \A \w+ (::\w+)* \z }xms;
    my $base = $is_base_class ? $ns : $lh->get_base_class();

    no strict 'refs';
    for my $pkg ( ref $pkgs ? @{$pkgs} : $pkgs ) {
        next if $pkg !~ m{ \A \w+ (::\w+)* \z }xms;
        *{ $base . '::' . $pkg . '::VERSION' }  = *{ $ns . '::VERSION' };
        *{ $base . '::' . $pkg . '::Encoding' } = *{ $ns . '::Encoding' };
        *{ $base . '::' . $pkg . '::Lexicon' }  = *{ $ns . '::Lexicon' };
        @{ $base . '::' . $pkg . '::ISA' }      = ($ns);
    }
}

sub remove_key_from_lexicons {
    my ( $lh, $key ) = @_;
    my $idx = 0;

    for my $lex_hr ( @{ $lh->_lex_refs() } ) {
        $lh->{'_removed_from_lexicons'}{$idx}{$key} = delete $lex_hr->{$key} if exists $lex_hr->{$key};
        $idx++;
    }
}

sub get_base_class {
    my $ns = shift->get_language_class();
    $ns =~ s{::\w+$}{};
    return $ns;
}

sub append_to_lexicons {
    my ( $lh, $appendage ) = @_;
    return if ref $appendage ne 'HASH';

    no strict 'refs';
    for my $lang ( keys %{$appendage} ) {
        my $ns = $lh->get_base_class() . ( $lang eq '_' ? '' : "::$lang" ) . '::Lexicon';
        %{$ns} = ( %{$ns}, %{ $appendage->{$lang} } );
    }
}

sub langtag_is_loadable {
    my ( $lh, $wants_tag ) = @_;
    $wants_tag = Locale::Maketext::language_tag($wants_tag);

    # why doesn't this work ?
    # no strict 'refs';
    # my $tag_obj = ${ $lh->get_base_class() }->get_handle( $wants_tag );
    my $tag_obj = eval $lh->get_base_class() . q{->get_handle( $wants_tag );};

    my $has_tag = $tag_obj->language_tag();
    return $wants_tag eq $has_tag ? $tag_obj : 0;
}

sub get_language_tag {
    return ( split '::', shift->get_language_class() )[-1];
}

sub print {
    local $Carp::CarpLevel = 1;
    print shift->maketext(@_);
}

sub fetch {
    local $Carp::CarpLevel = 1;
    return shift->maketext(@_);
}

sub say {
    local $Carp::CarpLevel = 1;
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/;    # otherwise assume they are not stupid
    print $text . $/ if $text;
}

sub get {
    local $Carp::CarpLevel = 1;
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/;    # otherwise assume they are not stupid
    return $text . $/ if $text;
    return;
}

sub get_language_tag_name {
    my ( $lh, $tag, $in_locale_tongue ) = @_;
    $tag ||= $lh->get_language_tag();

    my $loc_obj = $lh->get_locales_obj( $in_locale_tongue ? () : ($tag) );

    return $loc_obj->get_language_from_code($tag);
}

sub get_html_dir_attr {
    my ( $lh, $raw_cldr, $is_tag ) = @_;

    if ($is_tag) {
        $raw_cldr = $lh->get_language_tag_character_orientation($raw_cldr);
    }
    else {
        $raw_cldr ||= $lh->get_language_tag_character_orientation();
    }

    if ( $raw_cldr eq 'left-to-right' ) {
        return 'ltr';
    }
    elsif ( $raw_cldr eq 'right-to-left' ) {
        return 'rtl';
    }

    return;
}

sub get_locale_display_pattern {

    # my ( $lh, $tag ) = @_;
    # $tag ||= $lh->get_language_tag();

    return Locales::DB::LocaleDisplayPattern::Tiny::get_locale_display_pattern( $_[1] || $_[0]->{'fallback_locale'} || $_[0]->get_language_tag() );
}

sub get_language_tag_character_orientation {

    # my ( $lh, $tag ) = @_;
    # $tag ||= $lh->get_language_tag();

    return Locales::DB::CharacterOrientation::Tiny::get_orientation( $_[1] || $_[0]->{'fallback_locale'} || $_[0]->get_language_tag() );
}

sub text {
    require Carp;
    Carp::carp('text() is deprecated, use lextext() instead');
    goto &lextext;
}

sub lextext {

    require Carp;

    # Remember, this can fail.  Failure is controllable many ways.
    Carp::croak 'lextext() requires a single parameter' unless @_ == 2;

    my ( $handle, $phrase ) = splice( @_, 0, 2 );
    Carp::confess('No handle/phrase') unless ( defined($handle) && defined($phrase) );

    if ( !$handle->{'use_external_lex_cache'} ) {
        Carp::carp("lextext() requires you to have 'use_external_lex_cache' enabled.");
        return;
    }

    # backup $@ in case it is still being used in the calling code.
    # If no failures, we'll re-set it back to what it was later.
    my $at = $@;

    # Copy @_ case one of its elements is $@.
    @_ = @_;

    # Look up the value:

    my $value;
    foreach my $h_r ( @{ $handle->_lex_refs } ) {    # _lex_refs() caches itself

        # DEBUG and warn "* Looking up \"$phrase\" in $h_r\n";
        if ( exists $h_r->{$phrase} ) {

            if ( ref( $h_r->{$phrase} ) ) {
                Carp::carp("Previously compiled phrase ('use_external_lex_cache' enabled after phrase was compiled?)");
            }

            # DEBUG and warn "  Found \"$phrase\" in $h_r\n";
            $value = $h_r->{$phrase};
            last;
        }

        # extending packages need to be able to localize _AUTO and if readonly can't "local $h_r->{'_AUTO'} = 1;"
        # but they can "local $handle->{'_external_lex_cache'}{'_AUTO'} = 1;"
        elsif ( $phrase !~ m/^_/s and $h_r->{'_AUTO'} ) {

            # it is an auto lex, and this is an autoable key!
            # DEBUG and warn "  Automaking \"$phrase\" into $h_r\n";
            $value = $phrase;
            last;
        }

        # DEBUG > 1 and print "  Not found in $h_r, nor automakable\n";

        # else keep looking
    }

    unless ( defined($value) ) {

        # DEBUG and warn "! Lookup of \"$phrase\" in/under ", ref($handle) || $handle, " fails.\n";
    }

    $@ = $at;    # Put $@ back in case we altered it along the way.
    return $phrase if !defined $value || $value eq '';
    return $value;
}

sub lang_names_hashref {
    my ( $lh, @langcodes ) = @_;

    if ( !@langcodes ) {    # they havn't specified any langcodes...
        require File::Spec;    # only needed here, so we don't use() it

        my @search;
        my $path = $lh->get_base_class();
        $path =~ s{::}{/}g;    # !!!! make this File::Spec safe !! File::Spec->separator() !-e

        if ( ref $lh->{'_lang_pm_search_paths'} eq 'ARRAY' ) {
            @search = @{ $lh->{'_lang_pm_search_paths'} };
        }

        @search = @INC if !@search;    # they havn't told us where they are specifically

      DIR:
        for my $dir (@search) {
            my $lookin = File::Spec->catdir( $dir, $path );
            next DIR if !-d $lookin;
            if ( opendir my $dh, $lookin ) {
              PM:
                for my $pm ( grep { /^\w+\.pm$/ } grep !/^\.+$/, readdir($dh) ) {
                    $pm =~ s{\.pm$}{};
                    next PM if !$pm;
                    next PM if $pm eq 'Utils';
                    push @langcodes, $pm;
                }
                closedir $dh;
            }
        }
    }

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $lh->{'Locales.pm'}{'_main_'} ||= $lh->get_locales_obj();

    my $langname  = {};
    my $native    = wantarray && $Locales::VERSION > 0.06 ? {} : undef;
    my $direction = wantarray && $Locales::VERSION > 0.09 ? {} : undef;

    for my $code ( 'en', @langcodes ) {    # en since it is "built in"

        $langname->{$code} = $lh->{'Locales.pm'}{'_main_'}->get_language_from_code( $code, 1 );

        if ( defined $native ) {
            $native->{$code} = $lh->{'Locales.pm'}{'_main_'}->get_native_language_from_code( $code, 1 );
        }

        if ( defined $direction ) {
            $direction->{$code} = $lh->{'Locales.pm'}{'_main_'}->get_character_orientation_from_code_fast($code);
        }
    }

    return wantarray ? ( $langname, $native, $direction ) : $langname;
}

sub loadable_lang_names_hashref {
    my ( $lh, @langcodes ) = @_;

    my $langname = $lh->lang_names_hashref(@langcodes);

    for my $tag ( keys %{$langname} ) {
        delete $langname->{$tag} if !$lh->langtag_is_loadable($tag);
    }

    return $langname;
}

sub add_lexicon_override_hash {
    my ( $lh, $langtag, $name, $hr ) = @_;
    if ( @_ == 3 ) {
        $hr      = $name;
        $name    = $langtag;
        $langtag = $lh->get_language_tag();
    }

    my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

    no strict 'refs';
    if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
        return 1 if $lh->{'add_lex_hash_silent_if_already_added'} && exists $ref->{'hashes'} && exists $ref->{'hashes'}{$name};
        if ( $ref->can('add_lookup_override_hash') ) {
            return $ref->add_lookup_override_hash( $name, $hr );
        }
    }

    my $cur_errno = $!;
    if ( eval { require Sub::Todo } ) {
        goto &Sub::Todo::todo;
    }
    else {
        $! = $cur_errno;
        return;
    }
}

sub add_lexicon_fallback_hash {
    my ( $lh, $langtag, $name, $hr ) = @_;
    if ( @_ == 3 ) {
        $hr      = $name;
        $name    = $langtag;
        $langtag = $lh->get_language_tag();
    }

    my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

    no strict 'refs';
    if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
        return 1 if $lh->{'add_lex_hash_silent_if_already_added'} && exists $ref->{'hashes'} && exists $ref->{'hashes'}{$name};
        if ( $ref->can('add_lookup_fallback_hash') ) {
            return $ref->add_lookup_fallback_hash( $name, $hr );
        }
    }

    my $cur_errno = $!;
    if ( eval { require Sub::Todo } ) {
        goto &Sub::Todo::todo;
    }
    else {
        $! = $cur_errno;
        return;
    }
}

sub del_lexicon_hash {
    my ( $lh, $langtag, $name ) = @_;

    if ( @_ == 2 ) {
        return if $langtag eq '*';
        $name    = $langtag;
        $langtag = '*';
    }

    return if !$langtag;

    my $count = 0;
    if ( $langtag eq '*' ) {
        no strict 'refs';
        for my $ns ( $lh->get_base_class(), $lh->get_language_class() ) {
            if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
                if ( $ref->can('del_lookup_hash') ) {
                    $ref->del_lookup_hash($name);
                    $count++;
                }
            }
        }

        return 1 if $count;

        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            goto &Sub::Todo::todo;
        }
        else {
            $! = $cur_errno;
            return;
        }
    }
    else {
        my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

        no strict 'refs';
        if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
            if ( $ref->can('del_lookup_hash') ) {
                return $ref->del_lookup_hash($name);
            }
        }

        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            goto &Sub::Todo::todo;
        }
        else {
            $! = $cur_errno;
            return;
        }
    }
}

sub get_language_class {
    my ($lh) = @_;
    return ( ref($lh) || $lh );
}

# $Autoalias is a bad idea, if we did this method we'd need to do a proper symbol/ISA traversal
# sub get_alias_list {
#    my ($lh, $ns) = @_;
#    $ns ||= $lh->get_base_class();
#
#    no strict 'refs';
#    if (defined @{ $ns . "::Autoalias"}) {
#        return @{ $ns . "::Autoalias"};
#    }
#
#    return;
# }

sub get_base_class_dir {
    my ($lh) = @_;
    if ( !exists $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} ) {
        $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} = undef;

        my $inc_key = $lh->get_base_class();

        # require File::Spec;  # only needed here, so we don't use() it
        $inc_key =~ s{::}{/}g;    # TODO make portable via File::Spec
        $inc_key .= '.pm';
        if ( exists $INC{$inc_key} ) {
            if ( -e $INC{$inc_key} ) {
                $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} = $INC{$inc_key};
                $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} =~ s{\.pm$}{};
            }
        }
    }

    return $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'};
}

sub list_available_locales {
    my ($lh) = @_;

    # all comments in this function relate to get_alias_list() above
    # my ($lh, $include_fileless_aliases) = @_;

    # my $base;
    # if ($include_fileless_aliases) {
    #     $base = $lh->get_base_class_dir();
    # }

    my $main_ns_dir = $lh->get_base_class_dir() || return;

    # glob() is disabled in some environments
    my @glob;
    if ( opendir my $dh, $main_ns_dir ) {
        @glob = map { ( m{([^/]+)\.pm$} && $1 ne 'Utils' ) ? $1 : () } readdir($dh);    #de-taint
        closedir $dh;
    }

    # return ($lh->get_alias_list($base)), grep { $_ ne 'Utils' }
    return sort @glob;
}

sub get_asset {
    my ( $lh, $code, $tag ) = @_;                                                       # No caching since $code can do anything.

    my $loc_obj = $lh->get_locales_obj($tag);

    my $root = $tag || $lh->get_language_tag;
    my $ret;
    my $loc;                                                                            # buffer
    for $loc ( ( substr( $root, 0, 2 ) eq 'i_' ? $root : () ), $loc_obj->get_fallback_list( $lh->{'Locales.pm'}{'get_fallback_list_special_lookup_coderef'} ) ) {

        # allow $code to be a soft ref?
        # no strict 'refs';
        $ret = $code->($loc);
        last if defined $ret;
    }

    return $ret if defined $ret;
    return;
}

sub get_asset_file {
    my ( $lh, $find, $return ) = @_;
    $return = $find if !defined $return;

    return $lh->{'cache'}{'get_asset_file'}{$find}{$return} if exists $lh->{'cache'}{'get_asset_file'}{$find}{$return};

    $lh->{'cache'}{'get_asset_file'}{$find}{$return} = $lh->get_asset(
        sub {
            return sprintf( $return, $_[0] ) if -f sprintf( $find, $_[0] );
            return;
        }
    );

    return $lh->{'cache'}{'get_asset_file'}{$find}{$return} if defined $lh->{'cache'}{'get_asset_file'}{$find}{$return};
    return;
}

sub get_asset_dir {
    my ( $lh, $find, $return ) = @_;
    $return = $find if !defined $return;

    return $lh->{'cache'}{'get_asset_dir'}{$find}{$return} if exists $lh->{'cache'}{'get_asset_dir'}{$find}{$return};

    $lh->{'cache'}{'get_asset_dir'}{$find}{$return} = $lh->get_asset(
        sub {
            return sprintf( $return, $_[0] ) if -d sprintf( $find, $_[0] );
            return;
        }
    );

    return $lh->{'cache'}{'get_asset_dir'}{$find}{$return} if defined $lh->{'cache'}{'get_asset_dir'}{$find}{$return};
    return;
}

sub delete_cache {
    my ( $lh, $which ) = @_;
    if ( defined $which ) {
        return delete $lh->{'cache'}{$which};
    }
    else {
        return delete $lh->{'cache'};
    }
}

#### CLDR aware quant()/numerate ##

sub quant {
    my ( $handle, $num, @forms ) = @_;

    my $max_decimal_places = 3;

    if ( ref($num) eq 'ARRAY' ) {
        $max_decimal_places = $num->[1];
        $num                = $num->[0];
    }

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $handle->{'Locales.pm'}{'_main_'} ||= $handle->get_locales_obj();

    # numerate() is scalar context get_plural_form(), we need array context get_plural_form() here
    my ( $string, $spec_zero ) = $handle->{'Locales.pm'}{'_main_'}->get_plural_form( $num, @forms );

    # If you find a need for more than 1 %s please submit an rt w/ details
    if ( $string =~ m/%s\b/ ) {
        return sprintf( $string, $handle->numf( $num, $max_decimal_places ) );
    }
    elsif ( $num == 0 && $spec_zero ) {
        return $string;
    }
    else {
        $handle->numf( $num, $max_decimal_places ) . " $string";
    }
}

sub numerate {
    my ( $handle, $num, @forms ) = @_;

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $handle->{'Locales.pm'}{'_main_'} ||= $handle->get_locales_obj();

    return scalar( $handle->{'Locales.pm'}{'_main_'}->get_plural_form( $num, @forms ) );
}

#### CLDR aware quant()/numerate ##

#### CLDR aware numf() w/ decimal ##

sub numf {
    my ( $handle, $num, $max_decimal_places ) = @_;

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $handle->{'Locales.pm'}{'_main_'} ||= $handle->get_locales_obj();

    return $handle->{'Locales.pm'}{'_main_'}->get_formatted_decimal( $num, $max_decimal_places ) || 0;
}

#### / CLDR aware numf() w/ decimal/formatter ##

#### more BN methods ##

# W1301 revision 1:
#   [value] was a proposed way to avoid ambiguous '_thisthing' keys by "tagging" a phrase
#   as having a value different from the key while keeping it self-documenting:
#     '[value] Description of foo, arguments are …'
# sub value {
#      my ($lh, @contexts) = @_;
#
#      return '' if !@contexts; # must be for all contexts, cool
#
#      my $context = $lh->get_context();
#
#      if (!grep { $context eq $_ } @contexts) {
#          require Carp;
#          local $Carp::CarpLevel = 1;
#          my $context_csv = join(',',@contexts);
#          Carp::carp("The current context “$context” is not supported by the phrase ([value,$context_csv])");
#      }
#      return '';
# }

sub join {
    shift;
    return CORE::join( shift, map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @_ );
}

sub list_and {
    my $lh = shift;

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $lh->{'Locales.pm'}{'_main_'} ||= $lh->get_locales_obj();
    return $lh->{'Locales.pm'}{'_main_'}->get_list_and( map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @_ );
}

sub list_or {
    my $lh = shift;

    # Even though get_locales_obj() memoizes/caches/singletons itself we can still avoid a
    # method call if we already have the Locales object that belongs to the handle's locale.
    $lh->{'Locales.pm'}{'_main_'} ||= $lh->get_locales_obj();
    return $lh->{'Locales.pm'}{'_main_'}->get_list_or( map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @_ );
}

sub list_and_quoted {
    my ( $lh, @args ) = @_;

    $lh->{'Locales.pm'}{'_main_'} ||= $lh->get_locales_obj();
    local $lh->{'Locales.pm'}{'_main_'}{'misc'}{'list_quote_mode'} = 'all';
    return $lh->list_and(@args);
}

sub list_or_quoted {
    my ( $lh, @args ) = @_;

    $lh->{'Locales.pm'}{'_main_'} ||= $lh->get_locales_obj();
    local $lh->{'Locales.pm'}{'_main_'}{'misc'}{'list_quote_mode'} = 'all';
    return $lh->list_or(@args);
}

sub list {
    require Carp;
    Carp::carp('list() is deprecated, use list_and() or list_or() instead');

    my $lh      = shift;
    my $com_sep = ', ';
    my $oxford  = ',';
    my $def_sep = '&';

    if ( ref($lh) ) {
        $com_sep = $lh->{'list_separator'}   if exists $lh->{'list_separator'};
        $oxford  = $lh->{'oxford_separator'} if exists $lh->{'oxford_separator'};
        $def_sep = $lh->{'list_default_and'} if exists $lh->{'list_default_and'};
    }

    my $sep = shift || $def_sep;
    return if !@_;

    my @expanded = map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @_;
    if ( @expanded == 1 ) {
        return $expanded[0];
    }
    elsif ( @expanded == 2 ) {
        return CORE::join( " $sep ", @expanded );
    }
    else {
        my $last = pop @expanded;
        return CORE::join( $com_sep, @expanded ) . "$oxford $sep $last";
    }
}

sub output_asis {
    return $_[1];
}

sub asis {
    return $_[0]->output( 'asis', $_[1] );    # this allows for embedded methods but still called via [asis,...] instead of [output,asis,...]
}

sub comment {
    return '';
}

sub is_future {
    my ( $lh, $dt, $future, $past, $current, $current_type ) = @_;

    if ( $dt !~ m/\A[0-9]+\z/ ) {
        $dt = __get_dt_obj_from_arg( $dt, 0 );
        $dt = $dt->epoch();
    }

    if ($current) {
        if ( !ref $dt ) {
            $dt = __get_dt_obj_from_arg( $dt, 0 );
        }
        $current_type ||= 'hour';

        if ( $current_type eq 'day' ) {

            # TODO implement
        }
        elsif ( $current_type eq 'minute' ) {

            # TODO implement
        }
        else {

            # TODO implement
        }
    }

    return ref $dt ? $dt->epoch() : $dt > time() ? $future : $past;
}

sub __get_dt_obj_from_arg {
    require DateTime;
    return
       !defined $_[0] || $_[0] eq '' ? DateTime->now()
      : ref $_[0] eq 'HASH' ? DateTime->new( %{ $_[0] } )
      : $_[0] =~ m{ \A (\d+ (?: [.] \d+ )? ) (?: [:] (.*) )? \z }xms ? DateTime->from_epoch( 'epoch' => $1, 'time_zone' => ( $2 || 'UTC' ) )
      : !ref $_[0] ? DateTime->now( 'time_zone' => ( $_[0] || 'UTC' ) )
      : $_[1]      ? $_[0]->clone()
      :              $_[0];
}

sub current_year {
    $_[0]->datetime( '', 'YYYY' );
}

sub datetime {
    my ( $lh, $dta, $str ) = @_;
    my $dt = __get_dt_obj_from_arg( $dta, 1 );

    $dt->{'locale'} = DateTime::Locale->load( $lh->language_tag() );
    my $format = ref $str eq 'CODE' ? $str->($dt) : $str;
    if ( defined $format ) {
        if ( $dt->{'locale'}->can($format) ) {
            $format = $dt->{'locale'}->$format();
        }
    }

    $format = '' if !defined $format;
    return $dt->format_cldr( $dt->{'locale'}->format_for($format) || $format || $dt->{'locale'}->date_format_long() );
}

sub output_amp  { return $_[0]->output_chr(38) }    # TODO: ? make the rest of these embeddable like amp() ?
sub output_lt   { return $_[0]->output_chr(60) }
sub output_gt   { return $_[0]->output_chr(62) }
sub output_apos { return $_[0]->output_chr(39) }
sub output_quot { return $_[0]->output_chr(34) }
sub output_shy  { return $_[0]->output_chr(173) }

# sub output_codepoint {
#     my $cp = $_[1];
#     $cp =~ s/[^0-9a-fA-F]+//g;
#     return if !$cp;
#     return "U+$cp";
# }
#
# my %latin = (
#     'etc'   => 'etc.',            # et cetera: And [more|the rest|so on]
#     'ie'    => 'i.e.',            # id est: that is
#     'eg'    => 'e.g.',            # exempli gratia: for the sake of example
#     'ps'    => 'p.s.',            # after what has been written
#     'pps'   => 'p.p.s.',          # post post scriptum
#     'etal'  => 'et al.',          # et alii: and others
#     'cf'    => 'cf.',             # compare to
#     'vs'    => 'vs',              # versus
#     'v'     => 'v.',              # shorter version of vs
#     'adhoc' => 'ad hoc',          # for this (improvised or made for a specific, immediate purpose)
#     'adinf' => 'ad infinitum',    # to infinity
#     'adint' => 'ad interim',      # or the meantime
#     're'    => 'Re',              # by the thing, in the matter of
#     'rip'   => 'R.I.P.',          # requiescat in pace
#     'qv'    => 'q.v.',            # quod vide
# );
#
# sub output_latin {
#    return if !exists $latin{$_[1]};
#    return $_[0]->makethis($latin{$_[1]}); # makethis() would allow for [output,abbr,…] and [output,acronym,…]
# }

sub output_nbsp {

    # Use grapheme here since the NO-BREAK SPACE is visually ambiguous when typed (e.g. OSX option-space)

    # The character works the same as the entity so checking the context doesn't gain us much.
    # Any interest in being able to specify a mode that you might want the entity under HTML mode?
    # my ($lh, $context_aware) = @_;
    # if ($context_aware) {
    #     return $lh->context_is_html() ? '&nbsp;' : "\xC2\xA0";
    # }
    # else {
    #     return "\xC2\xA0";
    # }
    # or simply do the entity:
    # return $_[0]->context_is_html() ? '&nbsp;' : "\xC2\xA0";

    return "\xC2\xA0";
}

my $space;

sub format_bytes {
    my ( $lh, $bytes, $max_decimal_place ) = @_;
    $bytes ||= 0;

    if ( !defined $max_decimal_place ) {
        $max_decimal_place = 2;
    }
    else {
        $max_decimal_place = int( abs($max_decimal_place) );
    }

    my $absnum = abs($bytes);

    $space ||= $lh->output_nbsp();    # avoid method call if we already have it

    # override if you want different behavior or more flexibility, as-is these are the ideas behind it:
    #     * Calculate via 1024's not 1000's
    #     * Max decimals set to 2 (this is for human consumption not math operation)
    #     * Either 'n byte/n bytes' (since there is no good universal suffix for "byte")
    #       or 'n . non-breaking-space . SI-SUFFIX' (Yes technically MiB is more accurate
    #         here than MB, but for now it has to remain this way for legacy reasons)
    #     * simple math/logic is done here so that there is no need to bring in a module
    if ( $absnum < 1024 ) {

        # This is a special, internal-to-format_bytes, phrase: developers will not have to deal with this phrase directly.
        return $lh->maketext( '[quant,_1,%s byte,%s bytes]', [ $bytes, $max_decimal_place ] );    # the space between the '%s' and the 'b' is a non-break space (e.g. option-spacebar, not spacebar)
                                                                                                    # We do not use $space or \xC2\xA0 since:
                                                                                                    #   * parsers would need to know how to interpolate them in order to work with the phrase in the context of the system
                                                                                                    #   * the non-breaking space character behaves as you'd expect its various representations to.
                                                                                                    # Should a second instance of this sort of thing happen we can revisit the idea of adding [comment] in the phrase itself or perhaps supporting an embedded call to [output,nbsp].
    }
    elsif ( $absnum < 1048576 ) {
        return $lh->numf( ( $bytes / 1024 ), $max_decimal_place ) . $space . 'KB';
    }
    elsif ( $absnum < 1073741824 ) {
        return $lh->numf( ( $bytes / 1048576 ), $max_decimal_place ) . $space . 'MB';
    }
    elsif ( $absnum < 1099511627776 ) {
        return $lh->numf( ( $bytes / 1073741824 ), $max_decimal_place ) . $space . 'GB';
    }
    elsif ( $absnum < 1125899906842624 ) {
        return $lh->numf( ( $bytes / 1099511627776 ), $max_decimal_place ) . $space . 'TB';
    }
    elsif ( $absnum < ( 1125899906842624 * 1024 ) ) {
        return $lh->numf( ( $bytes / 1125899906842624 ), $max_decimal_place ) . $space . 'PB';
    }
    elsif ( $absnum < ( 1125899906842624 * 1024 * 1024 ) ) {
        return $lh->numf( ( $bytes / ( 1125899906842624 * 1024 ) ), $max_decimal_place ) . $space . 'EB';
    }
    elsif ( $absnum < ( 1125899906842624 * 1024 * 1024 * 1024 ) ) {
        return $lh->numf( ( $bytes / ( 1125899906842624 * 1024 * 1024 ) ), $max_decimal_place ) . $space . 'ZB';
    }
    else {

        # any reason to do the commented out code? if so please rt w/ details!
        # elsif ( $absnum < ( 1125899906842624 * 1024 * 1024 * 1024 * 1024 ) ) {
        return $lh->numf( ( $bytes / ( 1125899906842624 * 1024 * 1024 * 1024 ) ), $max_decimal_place ) . $space . 'YB';

        # }
        # else {
        #
        #    # This should never happen but just in case lets show something:
        #    return $lh->maketext( '[quant,_1,%s byte,%s bytes]', $bytes ); # See info about this above/incorporate said info should this ever be uncommented
    }
}

sub convert {
    shift;
    require Math::Units;
    return Math::Units::convert(@_);
}

sub is_defined {
    my ( $lh, $value, $is_defined, $not_defined, $is_defined_but_false ) = @_;

    return __proc_string_with_embedded_under_vars($not_defined) if !defined $value;

    if ( defined $is_defined_but_false && !$value ) {
        return __proc_string_with_embedded_under_vars($is_defined_but_false);
    }
    else {
        return __proc_string_with_embedded_under_vars($is_defined);
    }
}

sub boolean {
    my ( $lh, $boolean, $true, $false, $null ) = @_;
    if ($boolean) {
        return __proc_string_with_embedded_under_vars($true);
    }
    else {
        if ( !defined $boolean && defined $null ) {
            return __proc_string_with_embedded_under_vars($null);
        }
        return __proc_string_with_embedded_under_vars($false);
    }
}

sub __proc_string_with_embedded_under_vars {
    my $str = $_[0];
    return if !defined $str;

    return $str if $str !~ m/\_(\-?[0-9]+)/;
    my @args = __caller_args( $_[1] );    # this way be dragons
    $str =~ s/\_(\-?[0-9]+)/$args[$1]/g;
    return $str;
}

# sweet sweet magic stolen from Devel::Caller
sub __caller_args {

    package DB;
    () = caller( $_[0] + 3 );
    return @DB::args;
}

sub __proc_emb_meth {
    my ( $lh, $str ) = @_;

    return if !defined $str;

    $str =~ s/(su[bp])\(((?:\\\)|[^\)])+?)\)/my $s=$2;my $m="output_$1";$s=~s{\\\)}{\)}g;$lh->$m($s)/eg;
    $str =~ s/chr\(((?:\d+|[\S]))\)/$lh->output_chr($1)/eg;
    $str =~ s/numf\((\d+(?:\.\d+)?)\)/$lh->numf($1)/eg;
    $str =~ s/amp\(\)/$lh->output_amp()/eg;

    return $str;
}

sub output {
    my ( $lh, $output_function, $string, @output_function_args ) = @_;

    if ( defined $string && $string ne '' && $string =~ tr/(// ) {
        $string = __proc_emb_meth( $lh, $string );
    }

    if ( my $cr = $lh->can( 'output_' . $output_function ) ) {
        return $cr->( $lh, $string, @output_function_args );
    }
    else {
        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            $! = Sub::Todo::get_errno_func_not_impl();
        }
        else {
            $! = $cur_errno;
        }
        return $string;
    }
}

sub output_encode_puny {
    my ( $lh, $utf8 ) = @_;    # ? TODO or YAGNI ? accept either unicode ot utf8 string (i.e. via String::UnicodeUTF8 instead of utf8::- if so, use in output_decode_puny also)
    return $utf8 if $utf8 =~ m/xn--/;    # do not encode it if it is already punycode

    require Net::IDN::Encode;

    my $res;
    if ( $utf8 =~ m/(?:\@|\xef\xbc\xa0|\xef\xb9\xab)/ ) {    # \x{0040}, \x{FF20}, \x{FE6B} no need for \x{E0040} right?
        my ( $nam, $dom ) = split( /(?:\@|\xef\xbc\xa0|\xef\xb9\xab)/, $utf8, 2 );

        # TODO: ? multiple @ signs ...
        # my ($dom,$nam) = split(/\@/,reverse($_[1]),2);
        #        $dom = reverse($dom);
        #        $nam = reverse($nam);
        utf8::decode($nam);    # turn utf8 bytes into a unicode string
        utf8::decode($dom);    # turn utf8 bytes into a unicode string

        eval { $res = Net::IDN::Encode::domain_to_ascii($nam) . '@' . Net::IDN::Encode::domain_to_ascii($dom); };
        return 'Error: invalid string for punycode' if $@;
    }
    else {
        utf8::decode($utf8);    # turn utf8 bytes into a unicode string
        eval { $res = Net::IDN::Encode::domain_to_ascii($utf8); };
        return 'Error: invalid string for punycode' if $@;
    }

    return $res;
}

sub output_decode_puny {
    my ( $lh, $puny ) = @_;
    return $puny if $puny !~ m/xn--/;    # do not decode it if it isn't punycode

    require Net::IDN::Encode;

    my $res;
    if ( $puny =~ m/\@/ ) {
        my ( $nam, $dom ) = split( /@/, $puny, 2 );

        # TODO: ? multiple @ signs ...
        # my ($dom,$nam) = split(/\@/,reverse($_[1]),2);
        #        $dom = reverse($dom);
        #        $nam = reverse($nam);
        eval { $res = Net::IDN::Encode::domain_to_unicode($nam) . '@' . Net::IDN::Encode::domain_to_unicode($dom); };
        return "Error: invalid punycode" if $@;
    }
    else {
        eval { $res = Net::IDN::Encode::domain_to_unicode($puny); };
        return "Error: invalid punycode" if $@;
    }

    utf8::encode($res);    # turn unicode string back into utf8 bytes
    return $res;
}

my $has_encode;            # checking for Encode this way facilitates only checking @INC once for the module on systems that do not have Encode

sub output_chr {
    my ( $lh, $chr_num ) = @_;

    if ( $chr_num !~ m/\A\d+\z/ ) {
        return if length($chr_num) != 1;
        return $chr_num if !$lh->context_is_html();

        return
            $chr_num eq '"' ? '&quot;'
          : $chr_num eq '&' ? '&amp;'
          : $chr_num eq "'" ? '&#39;'
          : $chr_num eq '<' ? '&lt;'
          : $chr_num eq '>' ? '&gt;'
          :                   $chr_num;
    }
    return if $chr_num !~ m/\A\d+\z/;
    my $chr = chr($chr_num);

    # perldoc chr: Note that characters from 128 to 255 (inclusive) are by default internally not encoded as UTF-8 for backward compatibility reasons.
    if ( $chr_num > 127 ) {

        # checking for Encode this way facilitates only checking @INC once for the module on systems that do not have Encode
        if ( !defined $has_encode ) {
            $has_encode = 0;
            eval { require Encode; $has_encode = 1; };
        }

        # && $chr_num < 256) { # < 256 still needs Encode::encode()d in order to avoid "Wide character" warning
        if ($has_encode) {
            $chr = Encode::encode( $lh->encoding(), $chr );
        }

        # elsif (defined &utf8::???) { ??? }
        else {

            # This binmode trick can cause chr() to render and not have a "Wide character" warning but ... yikes ...:
            #     eval { binmode(STDOUT, ":utf8") } - eval beacuse perl 5.6 "Unknown discipline ':utf8' at ..." which means this would be pointless in addition to scary

            # warn "Encode.pm is not available so chr($chr_num) may or may not be encoded properly.";

            # chr() has issues (e.g. display problems) on any perl with or without Encode.pm (esspecially when $chr_num is 128 .. 255).
            # On 5.6 perl (i.e. no Encode.pm) \x{00AE} works so:
            #    sprintf('%04X', $chr_num); # e.g. turn '174' into '00AE'
            # It could be argued that this only needs done when $chr_num < 256 but it works so leave it like this for consistency and in case it is needed under specific circumstances

            $chr = eval '"\x{' . sprintf( '%04X', $chr_num ) . '}"';
        }
    }

    if ( !$lh->context_is_html() ) {
        return $chr;
    }
    else {
        return
            $chr_num == 34 || $chr_num == 147 || $chr_num == 148 ? '&quot;'
          : $chr_num == 38 ? '&amp;'
          : $chr_num == 39 || $chr_num == 145 || $chr_num == 146 ? '&#39;'
          : $chr_num == 60  ? '&lt;'
          : $chr_num == 62  ? '&gt;'
          : $chr_num == 173 ? '&shy;'
          :                   $chr;
    }
}

sub output_class {
    my ( $lh, $string, @classes ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if $lh->context_is_plain();

    # my $class_str = join(' ', @classes); # in case $" is hosed?
    # TODO maybe: use @classes to get ANSI color map of some sort
    return $lh->context_is_ansi() ? "\e[1m$string\e[0m" : qq{<span class="@classes">$string</span>};
}

sub output_asis_for_tests {
    my ( $lh, $string ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string;
}

sub __make_attr_str_from_ar {
    my ( $attr_ar, $strip_hr, $addin ) = @_;
    if ( ref($attr_ar) eq 'HASH' ) {
        $strip_hr = $attr_ar;
        $attr_ar  = [];
    }

    my $attr = '';
    my $general_hr = ref( $attr_ar->[-1] ) eq 'HASH' ? pop( @{$attr_ar} ) : undef;

    my $idx    = 0;
    my $ar_len = @{$attr_ar};

    $idx = 1 if $ar_len % 2;    # handle “Odd number of elements” …

    my $did_addin;

    while ( $idx < $ar_len ) {
        if ( exists $strip_hr->{ $attr_ar->[$idx] } ) {
            $idx += 2;
            next;
        }
        my $atr = $attr_ar->[$idx];
        my $val = $attr_ar->[ ++$idx ];
        if ( exists $addin->{$atr} ) {
            $val = "$addin->{$atr} $val";
            $did_addin->{$atr}++;
        }

        $attr .= qq{ $atr="$val"};
        $idx++;
    }

    if ($general_hr) {
        for my $k ( keys %{$general_hr} ) {
            next if exists $strip_hr->{$k};
            if ( exists $addin->{$k} ) {
                $general_hr->{$k} = "$addin->{$k} $general_hr->{$k}";
                $did_addin->{$k}++;
            }
            $attr .= qq{ $k="$general_hr->{$k}"};
        }
    }

    for my $r ( keys %{$addin} ) {
        if ( !exists $did_addin->{$r} ) {
            $attr .= qq{ $r="$addin->{$r}"};
        }
    }

    return $attr;
}

sub output_inline {
    my ( $lh, $string, @attrs ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if !$lh->context_is_html();

    my $attr = __make_attr_str_from_ar( \@attrs );
    return qq{<span$attr>$string</span>};
}

*output_attr = \&output_inline;

sub output_block {
    my ( $lh, $string, @attrs ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if !$lh->context_is_html();

    my $attr = __make_attr_str_from_ar( \@attrs );
    return qq{<div$attr>$string</div>};
}

sub output_img {
    my ( $lh, $src, $alt, @attrs ) = @_;

    if ( !defined $alt || $alt eq '' ) {
        $alt = $src;
    }
    else {
        $alt = __proc_string_with_embedded_under_vars( $alt, 1 );
    }

    return $alt if !$lh->context_is_html();

    my $attr = __make_attr_str_from_ar( \@attrs, { 'alt' => 1, 'src' => 1 } );
    return qq{<img src="$src" alt="$alt"$attr/>};
}

sub output_abbr {
    my ( $lh, $abbr, $full, @attrs ) = @_;
    return !$lh->context_is_html()
      ? "$abbr ($full)"
      : qq{<abbr title="$full"} . __make_attr_str_from_ar( \@attrs, { 'title' => 1 } ) . qq{>$abbr</abbr>};
}

sub output_acronym {
    my ( $lh, $acronym, $full, @attrs ) = @_;

    # ala bootstrap: class="initialism"
    return !$lh->context_is_html()
      ? "$acronym ($full)"
      : qq{<abbr title="$full"} . __make_attr_str_from_ar( \@attrs, { 'title' => 1 }, { 'class' => 'initialism' } ) . qq{>$acronym</abbr>};
}

sub output_sup {
    my ( $lh, $string, @attrs ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return !$lh->context_is_html() ? $string : qq{<sup} . __make_attr_str_from_ar( \@attrs ) . qq{>$string</sup>};
}

sub output_sub {
    my ( $lh, $string, @attrs ) = @_;
    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return !$lh->context_is_html() ? $string : qq{<sub} . __make_attr_str_from_ar( \@attrs ) . qq{>$string</sub>};
}

sub output_underline {
    my ( $lh, $string, @attrs ) = @_;

    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if $lh->context_is_plain();
    return $lh->context_is_ansi() ? "\e[4m$string\e[0m" : qq{<span style="text-decoration: underline"} . __make_attr_str_from_ar( \@attrs ) . qq{>$string</span>};
}

sub output_strong {
    my ( $lh, $string, @attrs ) = @_;

    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if $lh->context_is_plain();
    return $lh->context_is_ansi() ? "\e[1m$string\e[0m" : '<strong' . __make_attr_str_from_ar( \@attrs ) . ">$string</strong>";
}

sub output_em {
    my ( $lh, $string, @attrs ) = @_;

    $string = __proc_string_with_embedded_under_vars( $string, 1 );
    return $string if $lh->context_is_plain();

    # italic code 3 is specified in ANSI X3.64 and ECMA-048 but are not commonly supported by most displays and emulators, but we can try!
    return $lh->context_is_ansi() ? "\e[3m$string\e[0m" : '<em' . __make_attr_str_from_ar( \@attrs ) . ">$string</em>";
}

# output,del output,strike (ick):
#     strike-though code 9 is specified in ANSI X3.64 and ECMA-048 but are not commonly supported by most displays and emulators, but we can try!

sub output_url {
    my ( $lh, $url, @args ) = @_;
    $url ||= '';    # carp() ?

    my $arb_args_hr = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    my ( $url_text, %output_config ) = @args % 2 ? @args : ( undef, @args );

    my $return = $url;

    if ( !$lh->context_is_html() ) {
        if ($url_text) {
            $url_text = __proc_emb_meth( $lh, $url_text );
            $url_text = __proc_string_with_embedded_under_vars( $url_text, 1 );
            return "$url_text ($url)";
        }

        if ( exists $output_config{'plain'} ) {
            $output_config{'plain'} ||= $url;
            my $orig = $output_config{'plain'};
            $output_config{'plain'} = __proc_emb_meth( $lh, $output_config{'plain'} );
            $output_config{'plain'} = __proc_string_with_embedded_under_vars( $output_config{'plain'}, 1 );

            $return = $orig ne $output_config{'plain'} && $output_config{'plain'} =~ m/\Q$url\E/ ? $output_config{'plain'} : "$output_config{'plain'} $url";
        }
    }
    else {
        if ( exists $output_config{'html'} ) {
            $output_config{'html'} = __proc_emb_meth( $lh, $output_config{'html'} );
            $output_config{'html'} = __proc_string_with_embedded_under_vars( $output_config{'html'}, 1 );
        }

        if ( !$output_config{'html'} ) {
            $url_text = __proc_emb_meth( $lh, $url_text );
            $url_text = __proc_string_with_embedded_under_vars( $url_text, 1 );
        }

        $output_config{'html'} ||= $url_text || $url;

        my $attr = __make_attr_str_from_ar(
            [ @args, $arb_args_hr ],
            {
                'html'  => 1,
                'href'  => 1,
                'plain' => 1,
                '_type' => 1,
            }
        );

        $return = exists $output_config{'_type'}
          && $output_config{'_type'} eq 'offsite' ? qq{<a$attr target="_blank" class="offsite" href="$url">$output_config{'html'}</a>} : qq{<a$attr href="$url">$output_config{'html'}</a>};
    }

    return $return;
}

#### / more BN methods ##

#### output context methods ##

sub set_context_html {
    my ( $lh, $empty ) = @_;
    my $cur = $lh->get_context();
    $lh->set_context('html');
    return if !$lh->context_is_html();
    return $empty ? '' : $cur;
}

sub set_context_ansi {
    my ( $lh, $empty ) = @_;
    my $cur = $lh->get_context();
    $lh->set_context('ansi');
    return if !$lh->context_is_ansi();
    return $empty ? '' : $cur;
}

sub set_context_plain {
    my ( $lh, $empty ) = @_;
    my $cur = $lh->get_context();
    $lh->set_context('plain');
    return if !$lh->context_is_plain();
    return $empty ? '' : $cur;
}

my %contexts = (
    'plain' => undef(),
    'ansi'  => 1,
    'html'  => 0,
);

sub set_context {
    my ( $lh, $context, $empty ) = @_;

    if ( !$context ) {
        require Web::Detect;
        if ( Web::Detect::detect_web_fast() ) {
            $lh->{'-t-STDIN'} = 0;
        }
        else {
            require IO::Interactive::Tiny;
            $lh->{'-t-STDIN'} = IO::Interactive::Tiny::is_interactive() ? 1 : undef();
        }
    }
    elsif ( exists $contexts{$context} ) {
        $lh->{'-t-STDIN'} = $contexts{$context};
    }
    else {
        require Carp;
        local $Carp::CarpLevel = 1;
        Carp::carp("Given context '$context' is unknown.");
        $lh->{'-t-STDIN'} = $context;
    }

    return
        $empty ? ''
      : defined $context && exists $contexts{$context} ? $context
      :                                                  $lh->{'-t-STDIN'};
}

sub context_is_html {
    return $_[0]->get_context() eq 'html';
}

sub context_is_ansi {
    return $_[0]->get_context() eq 'ansi';
}

sub context_is_plain {
    return $_[0]->get_context() eq 'plain';
}

sub context_is {
    return $_[0]->get_context() eq $_[1];
}

sub get_context {
    my ($lh) = @_;

    if ( !exists $lh->{'-t-STDIN'} ) {
        $lh->set_context();
    }

    return 'plain' if !defined $lh->{'-t-STDIN'};
    return 'ansi'  if $lh->{'-t-STDIN'} eq "1";
    return 'html'  if $lh->{'-t-STDIN'} eq "0";

    # We don't carp "Given context '...' is unknown." here since we assume if they explicitly set it then they have a good reason to.
    # If it was an accident the set_contex() will have carp()'d already, if they set the variable directly then they're doing it wrong ;)
    return $lh->{'-t-STDIN'};
}

sub maketext_html_context {
    my ( $lh, @mt_args ) = @_;
    my $cur = $lh->set_context_html();
    my $res = $lh->maketext(@mt_args);
    $lh->set_context($cur);
    return $res;
}

sub maketext_ansi_context {
    my ( $lh, @mt_args ) = @_;
    my $cur = $lh->set_context_ansi();
    my $res = $lh->maketext(@mt_args);
    $lh->set_context($cur);
    return $res;
}

sub maketext_plain_context {
    my ( $lh, @mt_args ) = @_;
    my $cur = $lh->set_context_plain();
    my $res = $lh->maketext(@mt_args);
    $lh->set_context($cur);
    return $res;
}

# TODO: how crazy do we want to go with context specific versions of maketext()ish methods?
# *makevar_html_context = \&maketext_html_context;
# *makevar_ansi_context = \&maketext_ansi_context;
# *makeavr_plain_context = \&maketext_plain_context;
#
# sub makethis_html_context {};
# sub makethis_ansi_context {};
# sub makethis_plain_context {};
#
# sub makethis_base_html_context {};
# sub makethis_base_ansi_context {};
# sub makethis_base_plain_context {};

#### / output context methods ###

1;
