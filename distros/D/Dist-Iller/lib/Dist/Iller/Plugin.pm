use 5.14.0;
use strict;
use warnings;

package Dist::Iller::Plugin;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Handle a Dist::Zilla/Pod::Weaver plugin
our $VERSION = '0.1411';

use Dist::Iller::Elk;
use Types::Standard qw/Str Enum HashRef/;
use List::MoreUtils qw/uniq/;
use MooseX::StrictConstructor;
use Dist::Iller::Prereq;

with qw/
    Dist::Iller::Role::HasPrereqs
/;

has plugin_name => (
    is => 'ro',
    isa => Str,
);
has base => (
    is => 'ro',
    isa => Str,
    predicate => 1,
);
has in => (
    is => 'rw',
    isa => Enum[qw/Plugin PluginBundle Section Elemental/],
    default => 'Plugin',
);
has version => (
    is => 'rw',
    isa => Str,
    default => '0',
);
has documentation => (
    is => 'ro',
    isa => Str,
    predicate => 1,
);
has parameters => (
    is => 'ro',
    isa => HashRef,
    traits => [qw/Hash/],
    handles => {
        set_parameter => 'set',
        get_parameter => 'get',
        parameter_keys => 'keys',
        delete_parameter => 'delete',
        parameters_kv => 'kv',
    },
);

around BUILDARGS => sub {
    my $next = shift;
    my $self = shift;
    my $args = ref $_[0] eq 'HASH' ? shift : { @_ };

    if(exists $args->{'prereqs'}) {
        my $prereqs = [];

        for my $prereq (@{ $args->{'prereqs'} }) {
            my($phase, $relation) = split /_/ => (keys %{ $prereq })[0];
            my($module, $version) = split / / => (values %{ $prereq })[0];
            $version ||= 0;

            push @{ $prereqs } => Dist::Iller::Prereq->new(
                phase => $phase,
                relation => $relation,
                module => $module,
                version => $version,
            );
        }
        $args->{'prereqs'} = $prereqs;
    }

    $self->$next($args);
};

sub merge_with {
    my $self = shift;
    my $other_plugin = shift;

    foreach my $param ($other_plugin->parameter_keys) {
        if($self->get_parameter($param)) {
            if(ref $other_plugin->get_parameter($param) eq 'ARRAY') {
                if(ref $self->get_parameter($param) eq 'ARRAY') {
                    my $new_param_data = [ uniq @{ $self->get_parameter($param) }, @{ $other_plugin->get_parameter($param) } ];
                    $self->set_parameter($param, $new_param_data);
                }
                else {
                    my $new_param_data = [ uniq ($self->get_parameter($param)), @{ $other_plugin->get_parameter($param) } ];
                    $self->set_parameter($param, $new_param_data);
                }
            }
            else {
                $self->set_parameter($param, $other_plugin->get_parameter($param));
            }
        }
        else {
            $self->set_parameter($param, $other_plugin->get_parameter($param));
        }
    }
}

sub to_string {
    my $self = shift;
    my %options = @_;

    my @strings = $self->has_base ? (sprintf '[%s / %s]' => $self->base, $self->plugin_name)
                :                   (sprintf '[%s]' => $self->plugin_name)
                ;

    foreach my $parameter (sort $self->parameter_keys) {
        next if $parameter =~ m{^\+};
        my $value = $self->get_parameter($parameter);

        if(ref $value eq 'ARRAY') {
            foreach my $val (@$value) {
                push @strings => sprintf '%s =%s%s', $parameter, defined $val ? ' ' : '', defined $val ? $val : '';
            }
        }
        else {
            push @strings => sprintf '%s =%s%s', $parameter, defined $value ? ' ' : '', defined $value ? $value : '';
        }
    }

    return join "\n" => @strings;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Plugin - Handle a Dist::Zilla/Pod::Weaver plugin

=head1 VERSION

Version 0.1411, released 2020-01-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
