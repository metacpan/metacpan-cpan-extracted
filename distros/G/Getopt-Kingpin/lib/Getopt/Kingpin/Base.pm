package Getopt::Kingpin::Base;
use 5.008001;
use strict;
use warnings;
use Object::Simple -base;
use Carp;
use Path::Tiny;

our $VERSION = "0.06";
our $types;
sub AUTOLOAD {
    my $self = shift;
    my $func = our $AUTOLOAD;
    $func =~ s/.*:://;
    my $type = _camelize($func);

    $self->_set_types($type);

    $self->type($type);

    return $self;
}

sub DESTROY {
    return 1;
}

sub _set_types {
    my $self = shift;
    my ($type) = @_;

    if (not exists $types->{$type}) {
        my $module = sprintf "Getopt::Kingpin::Type::%s", $type;
        $module =~ s/List$//;
        if (not $module->can('set_value')) {
            croak "type error '$type'" unless eval "require $module"; ## no critic
        }
        $types->{$type} = {
            type      => \&{"${module}::type"},
            set_value => \&{"${module}::set_value"},
        };
    }

    if ($type eq "Bool") {
        if (not defined $self->_default) {
            $self->_default(0);
        }
    }

    if ($type =~ /List$/) {
        $self->is_cumulative(1);
    }
}

sub _camelize {
    my $c = shift;
    $c =~ s/(^|_)(.)/uc($2)/ge;
    return $c;
}

use overload (
    '""' => sub {defined $_[0]->value ? $_[0]->value : ""},
    fallback => 1,
);

has name          => undef;
has short_name    => undef;
has description   => undef;
has value         => undef;
has _defined      => 0;
has is_cumulative => 0;
has _default      => undef;
has _envar        => undef;
has type          => "String";
has _required     => 0;
has index         => 0;

sub short {
    my $self = shift;
    my ($short_name) = @_;

    $self->short_name($short_name);

    return $self;
}

sub default {
    my $self = shift;
    my ($default) = @_;

    $self->_default($default);

    return $self;
}

sub override_default_from_envar {
    my $self = shift;
    my ($envar_name) = @_;

    if (exists $ENV{$envar_name}) {
        $self->_envar($ENV{$envar_name});
    }

    return $self;
}

sub required {
    my $self = shift;
    $self->_required(1);

    return $self;
}

sub set_value {
    my $type = $_[0]->type;

    $_[0]->_set_types($type);

    if ($_[0]->is_cumulative) {
        my @values;
        if ($_[0]->_defined) {
            @values = @{$_[0]->value};
        }
        push @values, $types->{$type}->{set_value}->($_[0], $_[1]);
        $_[0]->_defined(1);
        $_[0]->value([@values]);
    } elsif ($_[0]->_defined) {
        printf STDERR "error: flag '%s' cannot be repeated, try --help", $_[0]->name;
        exit 1;
    } else {
        $_[0]->_defined(1);
        $_[0]->value($types->{$type}->{set_value}->(@_));
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Flag - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

    printf "name : %s\n", $name;

=head1 DESCRIPTION

Getopt::Kingpin::Flag は、Getopt::Kingpinから使用するモジュールです。

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Flag object.

=head2 short($short_name)

short optionを作成します。

=head2 default($default_value)

デフォルト値を設定します。

=head2 override_default_from_envar($env_var_name)

デフォルト値を環境変数で上書きします。

=head2 required()

そのオプションを必須とする。

=head2 set_value($value)

$self->valueに値を設定します。
実際の処理ではGetopt::Kingpin::Type::以下のモジュールが使われます。

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

