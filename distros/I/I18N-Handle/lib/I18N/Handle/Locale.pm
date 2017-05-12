package I18N::Handle::Locale;
use warnings;
use strict;
use base qw(I18N::Handle::Abstract Locale::Maketext);
use Locale::Maketext::Lexicon ();

our $loaded;

my $DynamicLH;

sub new {
    my $class = shift;
    my $args = shift || {};
    my $self = bless { } , $class;
    return $self if $loaded;

    $loaded++;

    Locale::Maketext::Lexicon->import({

        # '*' => [Gettext => 'locale/*/LC_MESSAGES/hello.mo'],
        # '*' => [Gettext => 'locale/*/LC_MESSAGES/hello.mo'],
        # 'zh-tw' => [ Gettext => 'po/zh_TW.po' ],
        # 'en' => [ Gettext => 'po/en.po' ],

        _auto   => 1,
        _decode => 1,
        _preload => 1,
        _style  => 'gettext',

        %$args,
    });
    $self->init;

    return $self;
}

sub init {
    my $self = shift;
    my $lh = $self->get_handle();
    $DynamicLH = \$lh; 
}

sub speak {
    my ( $self, $lang ) = @_;
    $$DynamicLH = $self->get_handle($lang ? $lang : ()) if $DynamicLH;
    # warn $$DynamicLH; # get I18N::Handle::Locale::zh_tw,en ...
}

sub get_current_handle { return $DynamicLH; }

sub get_loc_method {
    my $class = shift;
    my $dlh = $DynamicLH;
    return sub {
        # Borrow from Jifty::I18N.
        # Retain compatibility with people using "-e _" etc.
        return \*_ unless @_; # Needed for perl 5.8

        # When $_[0] is undef, return undef.  When it is '', return ''.
        no warnings 'uninitialized';
        return $_[0] unless (length $_[0]);

        local $@;
        # Force stringification to stop Locale::Maketext from choking on
        # things like DateTime objects.
        my @stringified_args = map {"$_"} @_;
        my $result = eval { ${$dlh}->maketext(@stringified_args) };
        if ($@) {
            # Sometimes Locale::Maketext fails to localize a string and throws
            # an exception instead.  In that case, we just return the input.
            warn $@;
            return join(' ', @stringified_args);
        }
        return $result || @_;
    };
}

1;
