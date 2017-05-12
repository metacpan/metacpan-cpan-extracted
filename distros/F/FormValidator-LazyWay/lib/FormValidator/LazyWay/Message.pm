package FormValidator::LazyWay::Message;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use UNIVERSAL::require;
use base 'FormValidator::LazyWay::Rule';

__PACKAGE__->mk_accessors(qw/rule config alias lang langs rule_message base_message labels/);

sub new {
    my $class = shift;
    my $args;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    croak 'you must set config' unless exists $args->{config};
    croak 'you must set rule' unless exists $args->{rule};
    
    my $self = bless $args, $class;

    $self->_set_lang();
    $self->{labels} = $self->_get_label();
    $self->{rule_message}
        = $self->_finalize_rule_message( $self->_load_rule_message() );

    return $self;
}

sub _get_label {
    my $self   = shift;
    my $config = $self->{config}{labels} || {};
    my $labels = {};
    foreach my $lang ( keys %{$config} ) {
        for my $field ( keys %{ $config->{$lang} } ) {
            $labels->{$lang}{$field} = $config->{$lang}{$field};
        }
    }
    return $labels;
}

sub _finalize_rule_message {
    my $self         = shift;
    my $rule_message = shift;

    my $message_storage = {};
    foreach my $lang ( @{ $self->langs } ) {
        foreach my $level ( keys %{ $self->rule->setting } ) {
            foreach my $field ( keys %{ $self->rule->setting->{$level} } )
            {
                for my $item (
                    @{ $self->rule->setting->{$level}{$field} } )
                {
                    my $message = $rule_message->{$lang}{ $item->{label} };
                    foreach my $key ( keys %{ $item->{args} } ) {
                        my $regexp = '\$_\[' . $key . '\]';
                        my $value  = $item->{args}{$key};
                        $message =~ s/$regexp/$value/g;
                    }
                    $message_storage->{$lang}{$level}{$field}
                        { $item->{label} } = $message;
                }
            }
        }
    }
    return $message_storage;
}

sub get {
    my $self   = shift;
    my $params = shift;
    return $self->rule_message->{ $params->{lang} }{ $params->{level} }
        { $params->{field} }{ $params->{label} };
}

sub _set_lang {
    my $self = shift;
    $self->{lang}  = $self->config->{lang}  || 'en';
    $self->{langs} = $self->config->{langs} || [ $self->lang ];

    for my $lang ( @{ $self->{langs} } ) {
        my $pkg = __PACKAGE__ . '::' . uc $lang;
        $pkg->require;
        $self->{base_message}{$lang} = {
            invalid => $self->config->{messages}{$lang}{invalid}
                || $pkg->invalid(),
            missing => $self->config->{messages}{$lang}{missing}
                || $pkg->missing(),
        };
    }
}

sub _load_rule_message {
    my $self = shift;

    my @subs = (
        sub { $self->_load_from_config(@_) },
        sub { $self->_load_from_rule(@_) },
        sub { $self->_loading_error(@_) },
    );

    my %message = ();
LANG:
    for my $lang ( @{ $self->langs } ) {
        $self->_loading_modules($lang);
    LABEL:
        foreach my $label ( keys %{ $self->rule->labels } ) {
        MESSAGE:
            for my $sub (@subs) {
                my $message
                    = $sub->( $lang, $label, $self->rule->labels->{$label} );
                $message{$lang}{$label} = $message;
                last MESSAGE if $message;
            }
        }
    }
    return \%message;
}

sub _loading_modules {
    my $self = shift;
    my $lang = shift;
    for my $module ( @{ $self->rule->modules } ) {
        my $package = $module . '::' . uc $lang;
        $package->require;
    }
}

sub _loading_error {
    my $self  = shift;
    my $lang  = shift;
    my $label = shift;
    croak sprintf( "You need to have rule message for lang:%s label:%s",
        $lang, $label );
    return;
}

sub _load_from_config {
    my $self  = shift;
    my $lang  = shift;
    my $label = shift;

    my $config = $self->config->{messages};
    return $config->{$lang}{rule}{$label} if $config->{$lang}{rule}{$label};

    my $alias = $self->rule->labels->{$label}{alias};
    return unless $alias;
    return $config->{$lang}{rule}{$alias} if $config->{$lang}{rule}{$alias};

    return;

}

sub _load_from_rule {
    my $self         = shift;
    my $lang         = shift;
    my $label        = shift;
    my $package_info = shift;
    my $package      = $package_info->{package} . '::' . uc $lang;
    my $method       = $package . '::' . $package_info->{method};


    my $message;
    no strict 'refs';
    eval { $message = $method->(); };

    return $message;
}

1;
