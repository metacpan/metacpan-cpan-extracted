use 5.014;  # because we use the 'non-destructive substitution' feature (s///r)
use strict;
use warnings;
package Banal::Dist::Zilla::Role::PluginBundle::Easier;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: The base class for TABULO's plugin bundle for distributions built by TABULO
# BASED_ON: Dist::Zilla::PluginBundle::Author::ETHER
# KEYWORDS: author bundle distribution tool

our $VERSION = '0.198';
# AUTHORITY

use Moose::Role;
requires qw( _extra_args payload );
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

use Data::Printer;
use Object::Tiny;

#use Dist::Zilla::PluginBundle::Author::TABULO::Config qw(configuration detect_settings);
use Banal::Dist::Util;
use Dist::Zilla::Util;
#use Types::Standard;
#use Type::Utils qw(enum subtype where class_type);
use Moose::Util::TypeConstraints qw(enum subtype where class_type);
use Scalar::Util qw(refaddr);
use List::Util 1.45 qw(first all any none pairs uniq);
use List::MoreUtils qw(arrayify);
use Module::Runtime qw(require_module use_module);
use Devel::CheckBin 'can_run';
use CPAN::Meta::Requirements;
use Config;

# TABULO : a custom 'has' to save some typing and lines ... :-)
# The '*' in the prototype allows bareword attribute names.
sub haz (*@) { my $name=shift; has ( $name => ( is => 'ro', init_arg => undef, lazy => 1, @_)); }

use namespace::autoclean;

# haz zilla => ( # DOES NOT WORK because we have no way of getting at it!!!
#     is => 'rw',
#     isa => class_type('Dist::Zilla'),
#     weak_ref => 1,
#     lazy => 0,    # Would be set to '1' if we had a 'default'
#     #default => sub { Object::Tiny->new() },   # TODO: FIXME
# );


haz _detected_bash => (
    isa => 'Bool',
    default => sub { !!can_run('bash') },
);

haz _detected_xs => (
    isa => 'Bool',
    default => sub { glob('*.xs') ? 1 : 0 },
);

# note this is applied to the plugin list in Dist::Zilla::Role::PluginBundle::PluginRemover,
# but we also need to use it here to be sure we are not adding configs that are only needed
# by plugins that will be subsequently removed.
haz _removed_plugin => (
    isa => 'HashRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $remove = $self->payload->{ $self->plugin_remover_attribute } // [];
        my %removed; @removed{@$remove} = (!!1) x @$remove;
        \%removed;
    },
    traits => ['Hash'],
    handles => { _plugin_removed => 'exists', _removed_plugins => 'keys'},
);


# this attribute and its supporting code is a candidate to be extracted out into its own role,
# for re-use in other bundles
haz _develop_suggests => (
    isa => class_type('CPAN::Meta::Requirements'),
    lazy => 1,
    default => sub { CPAN::Meta::Requirements->new },
    handles => {
        _add_minimum_develop_suggests => 'add_minimum',
        _develop_suggests_as_string_hash => 'as_string_hash',
    },
);


#######################################
sub bundle_config { # OVERRIDES 'Dist::Zilla::Role::PluginBundle::Easy'
#######################################
  my ($class, $section) = @_;

  my $self = $class->new($section);

  # TAU: Save zilla in an attribute. This is the only difference with the overriden version.
  # TODO : Remove, since it does NOT work.
  # This is because, unlike elsewhere, here '$section 'is just a plain unblessed hash which does NOT contain any 'sequence'.
  # $self->zilla($section->sequence->assembler->zilla);

  # say STDERR "bundle_config called with SECTION : " . np $section;

  $self->configure;

  return @{ $self->plugins };
}



#######################################
around add_plugins => sub {
#######################################
    my ($orig, $self, @plugins) = @_;

    @plugins = grep {
        my $plugin = $_;
        my $plugin_package = Dist::Zilla::Util->expand_config_package_name($plugin->[0]);
        none {
             $plugin_package eq Dist::Zilla::Util->expand_config_package_name($_)   # match by package name
             or ($plugin->[1] and not ref $plugin->[1] and $plugin->[1] eq $_)      # match by moniker
        } $self->_removed_plugins
    } map { ref $_ ? $_ : [ $_ ] } @plugins;

    foreach my $plugin_spec (@plugins)
    {
        # these should never be added to develop prereqs
        next if $plugin_spec->[0] eq 'BlockRelease'     # temporary use during development
            or $plugin_spec->[0] eq 'VerifyPhases';     # only used by TABULO, not others

        my $plugin = Dist::Zilla::Util->expand_config_package_name($plugin_spec->[0]);
        require_module($plugin);

        push @$plugin_spec, {} if not ref $plugin_spec->[-1];
        my $payload = $plugin_spec->[-1];

        my %extra_args = %{ $self->_extra_args };
        foreach my $module (grep { $plugin->isa($_) or $plugin->does($_) } keys %extra_args)
        {
            my %configs = %{ $extra_args{$module} };    # copy, not reference!

            # don't keep :version unless it matches the package exactly, but still respect the prereq
            $self->_add_minimum_develop_suggests($module => delete $configs{':version'})
                if exists $configs{':version'} and $module ne $plugin;

            # we don't need to worry about overwriting the payload with defaults, as
            # ConfigSlicer will copy them back over later on.
            @{$payload}{keys %configs} = values %configs;
        }

        # record develop prereq
        $self->_add_minimum_develop_suggests($plugin => $payload->{':version'} // 0);
    }

    return $self->$orig(@plugins);
};



#######################################
around add_bundle => sub
#######################################
{
    my ($orig, $self, $bundle, $payload) = @_;

    return if $self->_plugin_removed($bundle);

    my $package = Dist::Zilla::Util->expand_config_package_name($bundle);
    &use_module(
        $package,
        $payload && $payload->{':version'} ? $payload->{':version'} : (),
    );

    # default configs can be passed in directly - no need to consult %extra_args

    # record develop prereq of bundle only, not its components (it should do that itself)
    $self->_add_minimum_develop_suggests($package => $payload->{':version'} // 0);

    # allow config slices to propagate down from the user
    $payload = {
        %$payload,      # caller bundle's default settings for this bundle, passed to this sub
        # custom configs from the user, which may override defaults
        (map { $_ => $self->payload->{$_} } grep { /^(.+?)\.(.+?)/ } keys %{ $self->payload }),
    };

    # allow the user to say -remove = <plugin added in subbundle>, but also do not override
    # any removals that were passed into this sub directly.
    push @{$payload->{-remove}}, @{ $self->payload->{ $self->plugin_remover_attribute } }
        if $self->payload->{ $self->plugin_remover_attribute };

    return $self->$orig($bundle, $payload);
};



1;

=pod

=encoding UTF-8

=head1 NAME

Banal::Dist::Zilla::Role::PluginBundle::Easier - The base class for TABULO's plugin bundle for distributions built by TABULO

=head1 VERSION

version 0.198

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::TABULO]

=head1 DESCRIPTION

=for stopwords TABULO
=for stopwords GitHub DZIL

This is a practical utility role that attempts to simplify writing DZIL plugin bundles.

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::TABULO>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod


#endregion pod
