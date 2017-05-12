## no critic (RequireUseStrict)
package Dist::Zilla::PluginBundle::Author::RHOELZ;
$Dist::Zilla::PluginBundle::Author::RHOELZ::VERSION = '0.07';
## use critic (RequireUseStrict)
use strict;
use warnings;

use Moose;
use Class::Load qw(load_class);

with 'Dist::Zilla::Role::PluginBundle::Easy';

my $main_section_processed;
my %global_omissions;

has omissions => (
    is      => 'ro',
    default => sub { +{ %global_omissions } },
);

sub invert_hash {
    my ( $hash ) = @_;

    my %inverted;

    foreach my $key (keys %$hash) {
        my $value = $hash->{$key};

        if(exists $inverted{$value}) {
            if(ref($inverted{$value}) eq 'ARRAY') {
                push @{ $inverted{$value} }, $key;
            } else {
                $inverted{$value} = [ $inverted{$value}, $key ];
            }
        } else {
            $inverted{$value} = $key;
        }
    }

    return \%inverted;
}

sub mvp_multivalue_args {
    my ( $class ) = @_;

    # use a dummy instance to grab our plugin list;
    # we might want to resort to a manually provided
    # list
    my $instance = $class->new(
        name    => '@Author::RHOELZ',
        payload => {},
    );
    $instance->configure;
    $main_section_processed = 0; # trick this plugin

    my $plugins = $instance->plugins;

    my %multiargs = map { $_ => 1 } ('-omit');

    # gather mvp_multivalue_args from child plugins
    # and use those
    foreach my $plugin (@$plugins) {
        $plugin = $plugin->[1];

        load_class($plugin);
        next unless $plugin->can('mvp_multivalue_args');

        my @plugin_multiargs = $plugin->mvp_multivalue_args;

        # if an option has aliases, make sure we can specify
        # multiples of that aliase as well
        if($plugin->can('mvp_aliases')) {
            my $alias_map = invert_hash($plugin->mvp_aliases);

            my @additional;
            foreach my $arg (@plugin_multiargs) {
                my $aliases = $alias_map->{$arg};
                next unless defined $aliases;
                $aliases = [ $aliases ] unless ref($aliases) eq 'ARRAY';
                push @additional, @$aliases;
            }

            push @plugin_multiargs, @additional;
        }
        @multiargs{@plugin_multiargs} = (1) x @plugin_multiargs;
    }

    return keys %multiargs;
}

around add_plugins => sub {
    my ( $orig, $self, @specs ) = @_;

    foreach my $spec (@specs) {
        my $name = ref($spec) ? $spec->[0] : $spec;

        if(delete $self->omissions->{$name}) {
            undef $spec;
        }
    }

    @_ = ( $self, grep { defined() } @specs );

    goto &$orig;
};

sub check_omissions {
    my ( $self ) = @_;

    my $omissions = $self->omissions;

    if(%$omissions) {
        die "You asked to omit the following plugins, but they were not included in the bundle:\n" .
            join('', map { "  $_\n" } sort keys %$omissions);
    }
}

sub configure {
    my ( $self ) = @_;

    if($self->name ne '@Author::RHOELZ' && $self->name !~ /^@/) {
        if($main_section_processed) {
            die("Custom configuration sections for Author::RHOELZ sections must precede the main one\n");
        }
        $global_omissions{$self->name} = 1;
        $self->add_plugins([
            $self->name,
            $self->payload,
        ]);
        return;
    }

    $main_section_processed = 1;

    my $omit = $self->payload->{'-omit'};
    if($omit) {
        foreach my $plugin (@$omit) {
            $self->omissions->{$plugin} = 1;
        }
    }

    $self->add_plugins([
        GithubMeta => {
            issues => 1,
        },
    ]);

    $self->add_plugins([
        'Git::Check' => {
            allow_dirty => ['dist.ini', 'README.pod'],
        },
    ]);

    $self->add_plugins([
        NextRelease => {
            format => '%v %{MMMM dd yyyy}d',
        },
    ]);

    $self->add_plugins([
        'Git::Commit' => {
            allow_dirty => [
                'dist.ini',
                'README.pod',
                'Changes',
            ],
        },
    ]);

    $self->add_plugins([
        'Git::Tag' => {
            tag_format  => '%v',
            tag_message => '%v',
            signed      => 1,
        },
    ]);

    $self->add_plugins([
        'Git::NextVersion' => {
            first_version  => '0.01',
            version_regexp => '^(\d+\.\d+)$',
        },
    ]);

    $self->add_plugins([
        ReadmeAnyFromPod => {
            type     => 'pod',
            filename => 'README.pod',
            location => 'root',
        },
    ]);

    $self->add_plugins([
        'Git::GatherDir' => {
            include_dotfiles => 1,
        },
    ]);

    $self->add_plugins([
        PruneCruft => {
            except => '\.perlcriticrc',
        },
    ]);

    $self->add_plugins(
        'MetaYAML',
        'License',
        'Readme',
        'ModuleBuild',
        'Manifest',
        'PodCoverageTests',
        'PodSyntaxTests',
        'Test::DistManifest',
        'Test::Kwalitee',
        'Test::Compile',
        'Test::Perl::Critic',
        'TestRelease',
    );

    $self->add_plugins([
        PruneFiles => {
            filename => ['dist.ini', 'weaver.ini'],
        },
    ]);

    $self->add_plugins(
        'CheckChangesHasContent',
        'ConfirmRelease',
        'UploadToCPAN',
        'PkgVersion',
        'PodWeaver',
    );

    $self->check_omissions;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::RHOELZ - BeLike::RHOELZ when you build your distributions.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  ; in your dist.ini
  [@Author::RHOELZ]

=head1 DESCRIPTION

This is the plugin bundle that RHOELZ uses to build distributions.  It is
equivalent to the following:

  [GithubMeta]
  issues = 1
  [Git::Check]
  allow_dirty = dist.ini
  allow_dirty = README.pod
  [NextRelease]
  format = %v %{MMMM dd yyyy}d
  [Git::Commit]
  allow_dirty = dist.ini
  allow_dirty = README.pod
  allow_dirty = Changes
  [Git::Tag]
  tag_format  = %v
  tag_message = %v
  signed      = 1
  [Git::NextVersion]
  first_version  = 0.01
  version_regexp = ^(\d+\.\d+)$
  [ReadmeAnyFromPod]
  type     = pod
  filename = README.pod
  location = root
  [Git::GatherDir]
  include_dotfiles = 1
  [PruneCruft]
  except = \.perlcriticrc
  [MetaYAML]
  [License]
  [Readme]
  [ModuleBuild]
  [Manifest]
  [PodCoverageTests]
  [PodSyntaxTests]
  [Test::DistManifest]
  [Test::Kwalitee]
  [Test::Compile]
  [Test::Perl::Critic]
  [TestRelease]
  [PruneFiles]
  filename = dist.ini
  filename = weaver.ini
  [CheckChangesHasContent]
  [ConfirmRelease]
  [UploadToCPAN]
  [PkgVersion]
  [PodWeaver]

=head1 CUSTOMIZATION

You may omit a plugin using C<-omit>:

  [@Author::RHOELZ]
  -omit = UploadToCPAN

You may also provide a custom configuration for a plugin; this B<must> precede
the main C<@Author::RHOELZ> section.

  [@Author::RHOELZ / Test::Kwalitee]
  skiptest = use_strict
  [@Author::RHOELZ]

=head1 SEE ALSO

L<Dist::Zilla>

=begin comment

=over

=item configure

=item mvp_multivalue_args

=item check_omissions

=item invert_hash

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/dist-zilla-pluginbundle-author-rhoelz/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT:  BeLike::RHOELZ when you build your distributions.

