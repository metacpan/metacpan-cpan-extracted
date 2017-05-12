package Dist::Zilla::PluginBundle::RBO;
BEGIN {
  $Dist::Zilla::PluginBundle::RBO::VERSION = '0.002';
}

# ABSTRACT: Dist::Zilla plugins for RBO 

use Moose;
use Moose::Autobox;
use Dist::Zilla 4.102346;    # TestRelease
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Basic;

sub configure {
    my ($self) = @_;

    $self->add_bundle('@Basic');

    $self->add_plugins(
        qw(
          MetaConfig
          MetaJSON
          Git::NextVersion
          Git::Tag
          PkgVersion
          PodVersion
          )
    );

    $self->add_plugins(
        [
            AutoMetaResources => {
                'bugtracker.rt'     => 1,
                'repository.github' => 'user:rbo',
                'homepage'          => 'http://search.cpan.org/dist/%{dist}',
            }
        ]
    );

    $self->add_bundle( '@Git' => { tag_format => 'v%v', } );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=head1 NAME

Dist::Zilla::PluginBundle::RBO - Dist::Zilla plugins for RBO

=head1 VERSION

version 0.002

=head1 SYNOPSIS 

    # dist.ini
    [@RBO]

=head1 DESCRIPTION 

This is the plugin bundle for RBO. It's an equivalent to:

    [@Basic]

    [MetaConfig]
    [MetaJSON]
    [Git::NextVersion]
    [Git::Tag]
    [PkgVersion]
    [PodVersion]

    [AutoMetaResources]
    bugtracker.rt = 1
    repository.github = user:rbo
    homepage = http://search.cpan.org/dist/%{dist}

    [@Git]
    tag_format = v%v
    
=head1 DESCRIPTION

This is the plugin bundle that RBO uses.  

=cut