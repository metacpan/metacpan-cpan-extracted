package FormValidator::LazyWay::Setting;

use strict;
use warnings;
use Carp;

use base qw/Class::Accessor::Fast/;
use UNIVERSAL::require;

__PACKAGE__->mk_accessors(qw/alias config setting modules labels defaults/);

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

    my $self = bless $args, $class;

    unless ( $self->init() ) {
        croak 'undefined init method?';
    }

    $self->_load_setting();

    return $self;
}

sub init { 0; }

sub parse {
    my $self  = shift;
    my $value = shift;
    my $level = shift;
    my $field = shift;
    my $modified = 0;

    if (exists $self->{setting}{$level}{$field}) {
        for my $item ( @{$self->{setting}{$level}{$field}} ) {
            $value = $item->{method}->( $value , $item->{args} );
            $modified =1;
        }
    }
    else {
        for my $regexp ( keys %{ $self->{setting}{regex_map} } ) {
            if ( $field =~ qr/$regexp/ ) {
                for my $validator ( @{$self->{setting}{regex_map}{$regexp}} ) {
                    $value = $validator->{method}->( $value, $validator->{args} );
                    $modified =1;
                }
            }
        }
    }
    return ( $value, $modified );
}

sub _load_setting {
    my $self  = shift;
    my $rules = $self->{config}{$self->name . ( $self->name =~ /x$/ ? 'es' : 's' ) } || [];

    $self->{defaults} = $self->{config}{defaults} || {};

    # * require modules and set alias
    my @modules = ();
    for my $rule ( @{$rules} ) {
        my $module = $rule;

        my @data = split( '=', $rule );
        my $alias;
        if ( scalar @data == 1 ) {
            $module = $rule;
        }
        else {
            $alias  = $data[0];
            $module = $data[1];
        }

        unless ( $module =~ s/^\+// ) {
            $module = join( '::', $self->self , $module );
        }
        $self->{alias}{$alias} = $module if $alias;

        $module->require or die $@;
        push @modules, $module;
    }
    $self->{modules} = \@modules;

    # * make setting
    foreach my $key ( keys %{ $self->config->{setting} } ) {
        $self->{setting}{$key} = $self->_make_setting($key);
    }
}

sub _make_setting {
    my $self        = shift;
    my $type        = shift;
    my $alias       = $self->alias;
    my $setting = {};
    my $config      = $self->config;

    foreach my $field ( sort keys %{ $config->{setting}{$type} } ) {
        my $validations = $config->{setting}{$type}{$field}{ $self->name } || [];
        $setting->{$field} = [];

        for my $validation ( @{$validations} ) {

            my $label;
            my $args = {};
            if ( ref $validation eq 'HASH' ) {
                ($label) = keys %{$validation};
                $args = $validation->{$label};
            }
            else {
                $label = $validation;
            }
            $label = $label ? $label : '';

            my $package = substr( $label , 0 ,  rindex( $label, '#' ) );
            my $method = substr( $label, rindex( $label, '#' ) + 1 );

            my $alias_name = undef;
            if ( $alias->{$package} ) {
                $alias_name = $package . '#' . $method;
                $package    = $alias->{$package};
                my $re = '^' . $self->self . '::(.+)';
                ($label) = $package =~ m/$re/;
                $label = '+' . $package unless $label;
                $label = $label . '#' . $method;
            }
            else {
                if ( $package =~ m/^\+/ ) {
                    $package =~ s/\++//g;
                }
                else {
                    $package = $self->self . '::' . $package;
                }
            }

            $package =~ s/#.+//g;
            $self->{labels}{$label} = {
                package => $package,
                method  => $method,
                alias   => $alias_name
            };

            my $sub = $package . '::' . $method;

            my $method_ref = sub {
                my $item  = shift;
                my $stash = shift;

                no strict;
                my $result = $sub->( $item, $args, $stash );
                return $result;
            };
            push(
                @{ $setting->{$field} },
                { label => $label, method => $method_ref, args => $args }
            );

        }
    }

    return $setting;
}

1;

=head1 NAME

FormValidator::LazyWay::Rule - FormValidator::LazyWay Validation Rule module.

=head1 DESCRIPTION

検証モジュールを読み込み、検証ルールハッシュを作成します。

=head1 METHODS

=head2 new

=head2 alias

=head2 args

=head2 setting

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut
