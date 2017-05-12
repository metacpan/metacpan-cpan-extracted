package Declare::Args;
use strict;
use warnings;

our $VERSION = "0.009";

use Carp qw/croak/;

use Exporter::Declare qw{
    import
    gen_default_export
    default_export
};

gen_default_export 'ARGS_META' => sub {
    my ( $class, $caller ) = @_;
    my $meta = $class->new();
    $meta->{class} = $caller;
    return sub { $meta };
};

default_export arg        => sub { caller->ARGS_META->arg( @_ )   };
default_export parse_args => sub { caller->ARGS_META->parse( @_ ) };
default_export arg_info   => sub { caller->ARGS_META->info        };

sub class   { shift->{class}   }
sub args    { shift->{args}    }
sub default { shift->{default} }

sub new {
    my $class = shift;
    my ( %args ) = @_;

    my $self = bless { args => {}, default => {} } => $class;
    $self->arg( $_, $args{$_} ) for keys %args;

    return $self;
}

sub valid_arg_params {
    return qr/^(alias|list|bool|default|check|transform|description)$/;
}

sub arg {
    my $self = shift;
    my ( $name, %config ) = @_;

    croak "arg '$name' already defined"
        if $self->args->{$name};

    for my $prop ( keys %config ) {
        next if $prop =~ $self->valid_arg_params;
        croak "invalid arg property: '$prop'";
    }

    $config{name} = $name;

    croak "'check' cannot be used with 'bool'"
        if $config{bool} && $config{check};

    croak "'transform' cannot be used with 'bool'"
        if $config{bool} && $config{transform};

    croak "arg properties 'list' and 'bool' are mutually exclusive"
        if $config{list} && $config{bool};

    if (exists $config{default}) {
        croak "References cannot be used in default, wrap them in a sub."
            if ref $config{default} && ref $config{default} ne 'CODE';
        $self->default->{$name} = $config{default};
    }

    if ( exists $config{check} ) {
        my $ref = ref $config{check};
        croak "'$config{check}' is not a valid value for 'check'"
            if ($ref && $ref !~ m/^(CODE|Regexp)$/)
            || (!$ref && $config{check} !~ m/^(file|dir|number)$/);
    }

    if ( exists $config{alias} ) {
        my $aliases = ref $config{alias} ?   $config{alias}
                                         : [ $config{alias} ];

        $config{_alias} = { map { $_ => 1 } @$aliases };

        for my $alias ( @$aliases ) {
            croak "Cannot use alias '$alias', name is already taken by another arg."
                if $self->args->{$alias};

            $self->args->{$alias} = \%config;
        }
    }

    $self->args->{$name} = \%config;
}

sub parse {
    my $self = shift;
    my @args = @_;

    my $params = [];
    my $flags = {};
    my $no_flags = 0;

    while ( my $arg = shift @args ) {
        if ( $arg eq '--' ) {
            $no_flags++;
        }
        elsif ( $arg =~ m/^-+([^-=]+)(?:=(.+))?$/ && !$no_flags ) {
            my ( $key, $value ) = ( $1, $2 );

            my $name = $self->_flag_name( $key );
            my $values = $self->_flag_value(
                $name,
                $value,
                \@args
            );

            if( $self->args->{$name}->{list} ) {
                push @{$flags->{$name}} => @$values;
            }
            else {
                $flags->{$name} = $values->[0];
            }
        }
        else {
            push @$params => $arg;
        }
    }

    # Add defaults for args not provided
    for my $arg ( keys %{ $self->default } ) {
        next if exists $flags->{$arg};
        my $val = $self->default->{$arg};
        $flags->{$arg} = ref $val ? $val->() : $val;
    }

    return ( $params, $flags );
}

sub info {
    my $self = shift;
    return {
        map { $self->args->{$_}->{name} => $self->args->{$_}->{description} || "No Description" }
            keys %{ $self->args }
    };
}

sub _flag_value {
    my $self = shift;
    my ( $flag, $value, $args ) = @_;

    my $spec = $self->args->{$flag};

    if ( $spec->{bool} ) {
        return [$value] if defined $value;
        return [$spec->{default} ? 0 : 1];
    }

    my $val = defined $value ? $value : shift @$args;

    my $out = $spec->{list} ? [ split /\s*,\s*/, $val ]
                            : [ $val ];

    $self->_validate( $flag, $spec, $out );

    return $out unless $spec->{transform};
    return [ map { $spec->{transform}->($_) } @$out ];
}

sub _validate {
    my $self = shift;
    my ( $flag, $spec, $value ) = @_;

    my $check = $spec->{check};
    return unless $check;
    my $ref = ref $check || "";

    my @bad;

    if ( $ref eq 'Regexp' ) {
        @bad = grep { $_ !~ $check } @$value;
    }
    elsif ( $ref eq 'CODE' ) {
        @bad = grep { !$check->( $_ ) } @$value;
    }
    elsif ( $check eq 'file' ) {
        @bad = grep { ! -f $_ } @$value;
    }
    elsif ( $check eq 'dir' ) {
        @bad = grep { ! -d $_ } @$value;
    }
    elsif ( $check eq 'number' ) {
        @bad = grep { m/\D/ } @$value;
    }

    return unless @bad;
    my $type = $ref || $check;
    die "Validation Failed for '$flag=$type': " . join( ", ", @bad ) . "\n";
}

sub _flag_name {
    my $self = shift;
    my ( $key ) = @_;

    # Exact match
    return $self->args->{$key}->{name}
        if $self->args->{$key};

    my %matches = map { $self->args->{$_}->{name} => 1 }
        grep { m/^$key/ }
            keys %{ $self->args };
    my @matches = keys %matches;

    die "argument '$key' is ambiguous, could be: " . join( ", " => @matches ) . "\n"
        if @matches > 1;

    die "unknown argument '$key'\n"
        unless @matches;

    return $matches[0];
}

1;

__END__

=pod

=head1 NAME

Declare::Args - Deprecated, see L<Declare::Opts>

=head1 DESCRIPTION

Deprecated, see L<Declare::Opts>. This module was created because of a
terminology mistake. It will likely be replaced soon with new functionality.
The existing functionality can now be found in Declare::Opts

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Declare-Args is free software; Standard perl licence.

Declare-Args is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

