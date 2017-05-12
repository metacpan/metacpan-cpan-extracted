package Lingua::Translate::Google;

our $VERSION = '0.22';

use strict;
use warnings;
{
    use Carp;
    use Readonly;
    use WWW::Google::Translate;
}

my ($DEFAULT_AGENT);
{
    Readonly $DEFAULT_AGENT => __PACKAGE__ . "/v$VERSION";
}

# hack to allow 'auto' as a valid lang tag
BEGIN {

    require I18N::LangTags;

    my $is_rc = \&I18N::LangTags::is_language_tag;

    no warnings 'redefine';

    *I18N::LangTags::is_language_tag = sub {
        my ($tag) = @_;
        return 1
            if $tag eq 'auto';
        return $is_rc->($tag);
    };
}

{
    my %self = (
        src     => 'auto',
        dest    => 'en',
        api_key => 0,
        agent   => $DEFAULT_AGENT,
    );

    sub _true_self {
        my ($param_rh) = @_;

        if ($param_rh) {

            for my $key ( keys %{$param_rh} ) {

                $self{$key} = $param_rh->{$key};
            }
        }

        return \%self;
    }
}

sub new {
    my ( $class, %config ) = @_;

    my $self = _true_self();

    my $default_source 
        = $config{src}
        || $config{default_source}
        || $self->{src};

    my $default_target 
        = $config{dest}
        || $config{default_target}
        || $self->{dest};

    my $key 
        = $config{api_key}
        || $config{key}
        || $self->{api_key};

    my $agent = $config{agent}
        || $self->{agent};

    croak "key parameter must be your Google API key"
        if !$key;

    my %param = (
        key            => $key,
        default_target => $default_target,
        default_source => $default_source,
        agent          => $agent,
    );
    $self = _true_self(
        {   wgt     => WWW::Google::Translate->new( \%param ),
            src     => $default_source,
            dest    => $default_target,
            api_key => $key,
            agent   => $agent,
        }
    );

    return bless $self, $class;
}

sub config {
    my ( $self, %param );

    if ( @_ % 2 == 0 ) {

        (%param) = @_;

        $self = _true_self();
    }
    else {

        ( $self, %param ) = @_;
    }

    for my $p ( keys %param ) {

        if ( exists $self->{$p} ) {

            $self->{$p} ||= $param{$p};
        }
        else {

            carp "$p is not a supported parameter";
        }
    }

    my $src  = $param{src}  || $param{source} || $param{default_source};
    my $dest = $param{dest} || $param{target} || $param{default_target};

    if ($src) {

        croak "$src is not a valid language tag"
            if !I18N::LangTags::is_language_tag($src);

        $self->{src} = $src;
    }

    if ($dest) {

        croak "$dest is not a valid language tag"
            if !I18N::LangTags::is_language_tag($dest);

        $self->{dest} = $dest;
    }

    return;
}

sub translate {
    my ( $self, $text ) = @_;

    UNIVERSAL::isa( $self, __PACKAGE__ )
        or croak __PACKAGE__ . '::translate() called as function';

    my $true_self = _true_self();

    croak "no dest language specified\n"
        if !defined $self->{dest};

    croak "$self->{dest} is not available on Google translate"
        if !$self->available( $self->{dest} );

    if ( $self->{src} ne 'auto' ) {

        croak "$self->{src} is not available on Google translate"
            if !$self->available( $self->{src} );
    }

    if ( $self->{src} eq 'auto' ) {

        my $r = $self->{wgt}->detect( { q => $text } );

        if (   defined $r->{data}
            && defined $r->{data}->{detections}
            && defined $r->{data}->{detections}->[0] )
        {
            my $detect_rh = $r->{data}->{detections}->[0]->[0];

            if ( defined $detect_rh->{language} ) {

                $self->{src} = $detect_rh->{language};
            }
        }

        croak "failed to detect language"
            if $self->{src} eq 'auto';
    }

    my %q = (
        source => $self->{src},
        target => $self->{dest},
        q      => $text,
    );
    my $r = $self->{wgt}->translate( \%q );

    my $result;

    if (   defined $r->{data}
        && defined $r->{data}->{translations}
        && defined $r->{data}->{translations}->[0] )
    {
        my $trans_rh = $r->{data}->{translations}->[0];

        $result = $trans_rh->{translatedText};
    }
    else {

        croak 'translation failed';
    }

    if (wantarray) {

        return (
            src    => $self->{src},
            dest   => $self->{dest},
            q      => $text,
            result => $result,
        );
    }

    return $result;
}

# Returns the available language translation pairs.
sub available {
    my ( $self, $lang_inquiry, $lang_target ) = @_;

    UNIVERSAL::isa( $self, __PACKAGE__ )
        or croak __PACKAGE__ . '::available() called as function';

    if ($lang_inquiry) {

        require I18N::LangTags;

        croak "$lang_inquiry is not a valid language code"
            if !I18N::LangTags::is_language_tag($lang_inquiry);
    }

    $lang_target ||= $self->{dest};

    croak "you must specify the target language as the second argument",
        "or the default_target in the constructor"
        if $lang_inquiry && $lang_target eq 'auto';

    my $r = $self->{wgt}->languages( { target => $lang_target } );

    my @langs;

    if (   defined $r->{data}
        && defined $r->{data}->{languages}
        && defined $r->{data}->{languages}->[0] )
    {

        for my $lang_rh ( @{ $r->{data}->{languages} } ) {

            push @langs, $lang_rh->{language};

            return 1
                if $lang_inquiry && $lang_rh->{language} eq lc $lang_inquiry;
        }
    }

    return @langs
        if wantarray;

    return \@langs;
}

1;
