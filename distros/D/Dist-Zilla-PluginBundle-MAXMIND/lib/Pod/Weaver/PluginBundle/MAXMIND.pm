package Pod::Weaver::PluginBundle::MAXMIND;

use strict;
use warnings;

our $VERSION = '0.84';

use namespace::autoclean -also => ['_exp'];

use Dist::Zilla::Plugin::PodWeaver;
use Module::Runtime qw( use_module );
use PadWalker qw( peek_sub );
use Pod::Elemental::Transformer::List;
use Pod::Elemental::Transformer::Verbatim;
use Pod::Weaver::Config::Assembler;
use Pod::Weaver::Plugin::SingleEncoding;
use Pod::Weaver::Plugin::Transformer;
use Pod::Weaver::Section::AllowOverride;
use Pod::Weaver::Section::Authors;
use Pod::Weaver::Section::Collect;
use Pod::Weaver::Section::Contributors;
use Pod::Weaver::Section::GenerateSection;
use Pod::Weaver::Section::Generic;
use Pod::Weaver::Section::Leftovers;
use Pod::Weaver::Section::Legal;
use Pod::Weaver::Section::Name;
use Pod::Weaver::Section::Region;
use Pod::Weaver::Section::Version;

sub _exp {
    return Pod::Weaver::Config::Assembler->expand_package( $_[0] );
}

sub configure {
    my $self = shift;

    # this sub behaves somewhat like a Dist::Zilla pluginbundle's configure()
    # -- it returns a list of strings or 1, 2 or 3-element arrayrefs
    # containing plugin specifications. The goal is to make this look as close
    # to what weaver.ini looks like as possible.

    # I wouldn't have to do this ugliness if I could have some configuration
    # values passed in from weaver.ini or the [PodWeaver] plugin's use of
    # config_plugin (where I could define a 'licence' option)

    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    my $podweaver_plugin
        = ${ peek_sub( \&Dist::Zilla::Plugin::PodWeaver::weaver )->{'$self'}
        };

    my $zilla = $podweaver_plugin->zilla;
    my $bundle_prefix;
    for my $name ( map { $_->plugin_name } @{ $zilla->plugins } ) {

        # We want a plugin that was added by our bundle.
        next unless ($bundle_prefix) = $name =~ m{^(.+)/};
        last;
    }

    my $license_plugin = $zilla->plugin_named( $bundle_prefix . '/License' );
    my $license_filename
        = $license_plugin ? $license_plugin->filename : 'LICENSE';

    my $config
        = $zilla->plugin_named( $bundle_prefix . '/MAXMIND::WeaverConfig' );

    my @config = (
        '@CorePrep',
        [ '-SingleEncoding' => { encoding => 'UTF-8' } ],
        [ '-Transformer'    => List     => { transformer => 'List' } ],
        [ '-Transformer'    => Verbatim => { transformer => 'Verbatim' } ],
        [ 'Region'          => 'header' ],
        'Name',
        'Version',
        [ 'Region'  => 'prelude' ],
        [ 'Generic' => 'SYNOPSIS' ],
        [ 'Generic' => 'DESCRIPTION' ],
        [ 'Generic' => 'OVERVIEW' ],
        [ 'Collect' => 'ATTRIBUTES' => { command => 'attr' } ],
        [ 'Collect' => 'METHODS'    => { command => 'method' } ],
        [ 'Collect' => 'FUNCTIONS'  => { command => 'func' } ],
        [ 'Collect' => 'TYPES'      => { command => 'type' } ],
        'Leftovers',
        [ 'Region' => 'postlude' ],
        [
            'GenerateSection' => 'generate SUPPORT' => {
                title            => 'SUPPORT',
                main_module_only => 0,
                text             => [
                    <<'SUPPORT',
{{ join("\n\n",
    ($bugtracker_email && $bugtracker_email =~ /rt\.cpan\.org/)
    ? "Bugs may be submitted through L<the RT bug tracker|$bugtracker_web>\n(or L<$bugtracker_email|mailto:$bugtracker_email>)."
    : $bugtracker_web
    ? "Bugs may be submitted through L<$bugtracker_web>."
    : (),

    $distmeta->{resources}{x_MailingList} ? 'There is a mailing list available for users of this distribution,' . "\nL<mailto:" . $distmeta->{resources}{x_MailingList} . '>.' : (),

    $distmeta->{resources}{x_IRC}
        ? 'This distribution also has an IRC channel at' . "\nL<"
            . do {
                # try to extract the channel
                if (my ($network, $channel) = ($distmeta->{resources}{x_IRC} =~ m!(?:://)?(\w+(?:\.\w+)*)/?(#\w+)!)) {
                    'C<' . $channel . '> on C<' . $network . '>|' . $distmeta->{resources}{x_IRC}
                }
                else {
                    $distmeta->{resources}{x_IRC}
                }
            }
            . '>.'
        : (),
) }}
SUPPORT
                ]
            },
        ],
        [
            'AllowOverride' => 'allow override SUPPORT' => {
                header_re      => '^(SUPPORT|BUGS)\b',
                action         => 'prepend',
                match_anywhere => 0,
            },
        ],
    );

    push @config, (
        'Authors',
        [ 'Contributors' => { ':version' => '0.008' } ],
        [
            'Legal' => {
                ':version' => '4.011',
                header     => 'COPYRIGHT AND ' . $license_filename
            }
        ],
        [ 'Region' => 'footer' ],
    );

    return @config;
}

sub mvp_bundle_config {
    my $self = shift || __PACKAGE__;

    return map { $self->_expand_config($_) } $self->configure;
}

{
    my $prefix;

    sub _prefix {
        my $self = shift;
        return $prefix if defined $prefix;
        ( $prefix = ( ref($self) || $self ) )
            =~ s/^Pod::Weaver::PluginBundle:://;
        return $prefix;
    }
}

sub _expand_config {
    my ( $self, $this_spec ) = @_;

    die 'undefined config' if not $this_spec;
    die 'unrecognized config format: ' . ref($this_spec)
        if ref($this_spec)
        and ref($this_spec) ne 'ARRAY';

    my ( $name, $class, $payload );

    if ( not ref $this_spec ) {
        ( $name, $class, $payload ) = ( $this_spec, _exp($this_spec), {} );
    }
    elsif ( @$this_spec == 1 ) {
        ( $name, $class, $payload )
            = ( $this_spec->[0], _exp( $this_spec->[0] ), {} );
    }
    elsif ( @$this_spec == 2 ) {
        $name = ref $this_spec->[1] ? $this_spec->[0] : $this_spec->[1];
        $class
            = _exp( ref $this_spec->[1] ? $this_spec->[0] : $this_spec->[0] );
        $payload = ref $this_spec->[1] ? $this_spec->[1] : {};
    }
    else {
        ( $name, $class, $payload )
            = ( $this_spec->[1], _exp( $this_spec->[0] ), $this_spec->[2] );
    }

    $name =~ s/^[@=-]//;

    # Region plugins have the custom plugin name moved to 'region_name' parameter,
    # because we don't want our bundle name to be part of the region name.
    if ( $class eq _exp('Region') ) {
        $name    = $this_spec->[1];
        $payload = { region_name => $this_spec->[1], %$payload };
    }

    use_module( $class, $payload->{':version'} ) if $payload->{':version'};

    # prepend '@MAXMIND/' to each class name,
    # except for Generic and Collect which are left alone.
    $name = '@' . $self->_prefix . '/' . $name
        if $class ne _exp('Generic')
        and $class ne _exp('Collect');

    return [ $name => $class => $payload ];
}

1;

# ABSTRACT: A plugin bundle for pod woven by MAXMIND

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::MAXMIND - A plugin bundle for pod woven by MAXMIND

=head1 VERSION

version 0.84

=head1 SYNOPSIS

In your F<weaver.ini>:

    [@MAXMIND]

Or in your F<dist.ini>

    [PodWeaver]
    config_plugin = @MAXMIND

It is also used automatically when your F<dist.ini> contains:

    [@MAXMIND]
    :version = 0.094

=head1 DESCRIPTION

The contents of this bundle were mostly copied from
L<Pod::Weaver::PluginBundle::Author::ETHER>.

This is a L<Pod::Weaver> plugin bundle. It is I<approximately> equal to the
following F<weaver.ini>, minus some optimizations:

    [@CorePrep]

    [-SingleEncoding]

    [-Transformer / List]
    transformer = List

    [-Transformer / Verbatim]
    transformer = Verbatim

    [Region / header]
    [Name]
    [Version]

    [Region / prelude]

    [Generic / SYNOPSIS]
    [Generic / DESCRIPTION]
    [Generic / OVERVIEW]

    [Collect / ATTRIBUTES]
    command = attr

    [Collect / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = func

    [Collect / TYPES]
    command = type

    [Leftovers]

    [Region / postlude]

    [GenerateSection / generate SUPPORT]
    title = SUPPORT
    main_module_only = 0
    text = <template>

    [AllowOverride / allow override SUPPORT]
    header_re = ^(SUPPORT|BUGS)
    action = prepend
    match_anywhere = 0

    [Authors]
    [Contributors]
    :version = 0.008

    [Legal]
    :version = 4.011
    header = COPYRIGHT AND <license filename>

    [Region / footer]

This is also equivalent (other than section ordering) to:

    [-Transformer / List]
    transformer = List
    [-Transformer / Verbatim]
    transformer = Verbatim

    [Region / header]
    [@Default]

    [Collect / TYPES]
    command = type

    [GenerateSection / generate SUPPORT]
    title = SUPPORT
    main_module_only = 0
    text = <template>

    [AllowOverride / allow override SUPPORT]
    header_re = ^(SUPPORT|BUGS)
    action = prepend
    match_anywhere = 0

    [Contributors]
    :version = 0.008

    [Region / footer]

=for Pod::Coverage .*

=head1 OPTIONS

None at this time. (The bundle is never instantiated, so this doesn't seem to
be possible without updates to L<Pod::Weaver>.)

=head1 OVERRIDING A SPECIFIC SECTION

This F<weaver.ini> will let you use a custom C<COPYRIGHT AND LICENSE> section
and still use the plugin bundle:

    [@MAXMIND]
    [AllowOverride / OverrideLegal]
    header_re = ^COPYRIGHT
    match_anywhere = 1

=head1 ADDING STOPWORDS FOR SPELLING TESTS

As noted in L<Dist::Zilla::PluginBundle::MAXMIND>, stopwords for
spelling tests can be added by adding a directive to pod:

    =for stopwords foo bar baz

However, if the stopword appears in the module's abstract, it is moved to the
C<NAME> section, which will be above your stopword directive. You can handle
this by declaring the stopword in the special C<header> section, which will be
woven ahead of everything else:

    =for :header
    =for stopwords foo bar baz

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::PluginBundle::Default>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::PluginBundle::MAXMIND>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
