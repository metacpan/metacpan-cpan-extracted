use 5.10.0;
use strict;
use warnings;

package Dist::Iller::Role::HasPlugins;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1408';

use Moose::Role;
use namespace::autoclean;
use Types::Standard qw/ArrayRef InstanceOf/;
use PerlX::Maybe qw/maybe provided/;
use Safe::Isa qw/$_can/;
use List::Util qw/none/;
use Dist::Iller::Plugin;

# packages_for_plugin should return a CodeRef that in turn returns an ArrayRef of HashRefs, see ::DocType::Dist
requires qw/
    packages_for_plugin
/;

has plugins => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Dist::Iller::Plugin']],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        add_plugin => 'push',
        all_plugins => 'elements',
        filter_plugins => 'grep',
        find_plugin => 'first',
        count_plugins => 'count',
        has_plugins => 'count',
        get_plugin => 'get',
        map_plugins => 'map',
    },
);

around add_plugin => sub {
    my $next = shift;
    my $self = shift;
    my $plugin_data = shift;
    my $plugin = (InstanceOf['Dist::Iller::Plugin'])->check($plugin_data) ? $plugin_data : Dist::Iller::Plugin->new($plugin_data);

    if($self->find_plugin(sub { $_->plugin_name eq $plugin->plugin_name })) {
        say "[Iller] ! Duplicate plugin found - skips [@{[ $plugin->plugin_name ]}]";
        return;
    }

    $self->$next($plugin);
};

sub parse_plugins {
    my $self = shift;
    my $yaml = shift;

    return if !defined $yaml;

    foreach my $item (@$yaml) {
        $self->parse_config($item) if exists $item->{'+config'}; # is in ::DocType
        $self->parse_plugin($item) if exists $item->{'+plugin'};
        $self->parse_remove($item) if exists $item->{'+remove_plugin'};
        $self->parse_replace($item) if exists $item->{'+replace_plugin'};
        $self->parse_extend($item) if exists $item->{'+extend_plugin'};
        $self->parse_add($item) if exists $item->{'+add_plugin'};
    }
}

sub parse_plugin {
    my $self = shift;
    my $plugin = shift;

    my $plugin_name = delete $plugin->{'+plugin'};

    return if !$self->check_conditionals($plugin);

    $self->add_plugin({
                plugin_name => $self->set_value_from_config($plugin_name),
          maybe base => delete $plugin->{'+base'},
          maybe in => delete $plugin->{'+in'},
          maybe version => delete $plugin->{'+version'},
          maybe documentation => delete $plugin->{'+documentation'},
          maybe prereqs => delete $plugin->{'+prereqs'},
                parameters => $self->set_values_from_config($plugin),
    });
}

sub parse_replace {
    my $self = shift;
    my $replacer = shift;

    return if !$self->check_conditionals($replacer);

    my $plugin_name = $self->set_value_from_config(delete $replacer->{'+replace_plugin'});
    my $replace_with = $self->set_value_from_config(delete $replacer->{'+with'});

    my $plugin = Dist::Iller::Plugin->new(
                plugin_name => $replace_with // $plugin_name,
          maybe base => delete $replacer->{'+base'},
          maybe in => delete $replacer->{'+in'},
          maybe version => delete $replacer->{'+version'},
          maybe documentation => delete $replacer->{'+documentation'},
                parameters => $self->set_values_from_config($replacer),
    );

    $self->insert_plugin($plugin_name, $plugin, after => 0, replace => 1);
}

sub parse_extend {
    my $self = shift;
    my $extender = shift;

    return if !$self->check_conditionals($extender);

    my $plugin_name = delete $extender->{'+extend_plugin'};

    my $plugin = Dist::Iller::Plugin->new(
                plugin_name => $self->set_value_from_config($plugin_name),
                parameters => $self->set_values_from_config($extender),
    );

    $self->extend_plugin($plugin_name, $plugin, remove => delete $extender->{'+remove'});
}

sub parse_add {
    my $self = shift;
    my $adder = shift;

    return if !$self->check_conditionals($adder);

    my $plugin_name = delete $adder->{'+add_plugin'};

    my $plugin = Dist::Iller::Plugin->new(
                plugin_name => $self->set_value_from_config($plugin_name),
          maybe base => delete $adder->{'+base'},
          maybe in => delete $adder->{'+in'},
          maybe version => delete $adder->{'+version'},
          maybe documentation => delete $adder->{'+documentation'},
                parameters => $self->set_values_from_config($adder),
    );

    my $after = delete $adder->{'+after'};
    my $before = delete $adder->{'+before'};

    $self->insert_plugin(($after ? $after : $before), $plugin, after => ($after ? 1 : 0), replace => 0);
}

sub parse_remove {
    my $self = shift;
    my $remover = shift;

    return if !$self->check_conditionals($remover);
    $self->remove_plugin($self->set_value_from_config($remover->{'+remove_plugin'}));
}

sub check_conditionals {
    my $self = shift;
    my $plugin_data = shift;

    my $get_type_what = sub {
        my $from = shift;

        return () if !defined $from;
        return () if !length $from;
        return () if $from !~ m{[^.]\.[^.]};
        return split /\./ => $from;
    };

    if(exists $plugin_data->{'+if'}) {
        my($type, $what) = $get_type_what->($plugin_data->{'+if'});
        return 0 if !defined $type;
        return 0 if $type eq '$env' && !exists $ENV{ uc $what };
        return $ENV{ uc $what } if $type eq '$env';
    }
    elsif(exists $plugin_data->{'+remove_if'}) {
        my($type, $what) = $get_type_what->($plugin_data->{'+remove_if'});

        return if !defined $type;

        if($type eq '$env') {
            return 0 if !exists $ENV{ uc $what };
            return !$ENV{ uc $what };
        }
        elsif($type eq '$self' && $self->has_config_obj) {
            return 1 if !$self->config_obj->$_can($what);
            return !$self->config_obj->$what;
        }
    }
    elsif(exists $plugin_data->{'+add_if'}) {
        my($type, $what) = $get_type_what->($plugin_data->{'+add_if'});
        return if !defined $type;

        if($type eq '$env') {
            return 0 if !exists $ENV{ uc $what };
            return $ENV{ uc $what };
        }
        elsif($type eq '$self' && $self->has_config_obj) {
            return 0 if !$self->config_obj->$_can($what);
            return $self->config_obj->$what;
        }
    }

    return 1;
}

sub insert_plugin {
    my $self = shift;
    my $plugin_name = shift;
    my $new_plugin = shift;
    my %settings = @_;

    my $after = $settings{'after'} || 0;
    my $replace = $settings{'replace'} || 0;

    foreach my $index (0 .. $self->count_plugins - 1) {
        my $current_plugin = $self->get_plugin($index);

        if($current_plugin->plugin_name eq $plugin_name) {
            my @all_plugins = $self->all_plugins;
            splice @all_plugins, ($after ? $index + 1 : $index), ($replace ? 1 : 0), $new_plugin;
            $self->plugins(\@all_plugins);

            if($replace) {
                say sprintf "[Iller] Replaced [%s] with [%s]", $current_plugin->plugin_name, $new_plugin->plugin_name;
            }
            else {
                say sprintf "[Iller] Inserted [%s] %s [%s]", $new_plugin->plugin_name, ($after ? 'after' : 'before'), $current_plugin->plugin_name;
            }
            last;
        }
    }
}

sub extend_plugin {
    my $self = shift;
    my $plugin_name = shift;
    my $new_plugin = shift;
    my %settings = @_;

    my $remove = $settings{'remove'};

    $remove = $remove ? ref $remove eq 'ARRAY' ? $remove
                                               : [ $remove ]
            :                                    []
            ;
    say sprintf '[Iller] From %s remove %s', $plugin_name, join ', ' => @$remove if scalar @$remove;
    say sprintf '[Iller] Extended [%s]', $plugin_name;

    foreach my $index (0 .. $self->count_plugins - 1) {
        my $current_plugin = $self->get_plugin($index);

        if($current_plugin->plugin_name eq $plugin_name) {
            foreach my $param_to_remove (@$remove) {
                $current_plugin->delete_parameter($param_to_remove);
            }
            $current_plugin->merge_with($new_plugin);
            last;
        }
    }
}

sub remove_plugin {
    my $self = shift;
    my $remove_name = shift;

    foreach my $index (0 .. $self->count_plugins - 1) {
        my $current_plugin = $self->get_plugin($index);

        if($current_plugin->plugin_name eq $remove_name) {
            my @all_plugins = $self->all_plugins;
            splice @all_plugins, $index, 1;
            $self->plugins(\@all_plugins);
            say "[Iller] Removed [$remove_name]";
            last;
        }
    }
}

sub set_values_from_config {
    my $self = shift;
    my $parameters = shift;

    return $parameters if !$self->has_config_obj;

    foreach my $param (keys %$parameters) {
        next if $param =~ m{^\+};
        next if !defined $parameters->{ $param };

        $parameters->{ $param } = ref $parameters->{ $param } eq 'ARRAY' ? $parameters->{ $param } : [ $parameters->{ $param } ];

        VALUE:
        foreach my $i (0 .. scalar @{ $parameters->{ $param } } - 1) {
            $parameters->{ $param }[$i] = $self->set_value_from_config($parameters->{ $param }[$i]);
        }
    }
    return $parameters;
}

sub set_value_from_config {
    my $self = shift;
    my $value = shift;

    return $value if !defined $value;
    return $value if $value !~ m{[^.]\.[^.]};
    my($type, $what) = split /\./ => $value;
    return $value if none { $_ eq $type } qw/$env $self/;

    if($type eq '$env' && exists $ENV{ uc $what }) {
        return $ENV{ uc $what };
    }
    elsif($type eq '$self' && $self->config_obj->$_can($what)) {
        return $self->config_obj->$what;
    }
    return $value;
}


sub plugins_to_hash {
    my $self = shift;

    return [
        $self->map_plugins(sub {
            my $plugin = $_;
            my $parameters = {};
            $parameters->{ $_->[0] } = $_->[1] for $plugin->parameters_kv;
            +{
                                       '+plugin' => $plugin->plugin_name,
                provided $_->has_base, '+base' => $plugin->base,
                                       '+in' => $plugin->in,
                                       '+version' => $plugin->version,
             provided $_->has_prereqs, '+prereqs' => $plugin->prereqs_to_array,
                                 maybe '+documentation' => $plugin->documentation,
                                       %{ $parameters },
            }
        })
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Role::HasPlugins

=head1 VERSION

Version 0.1408, released 2016-03-12.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
