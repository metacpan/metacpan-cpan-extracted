{{
    $name = $dist->name =~ s/-/::/gr; ''
}}package {{ $name }}::Builder;

use Moose;
use File::ShareDir;
extends 'OpusVL::FB11::Builder';

use Try::Tiny;

override _build_superclasses => sub {
    return ['OpusVL::FB11'];
};

override _build_plugins => sub {
    my $plugins = super();

    push @$plugins, qw(
    );

    return $plugins;
};

override _build_config => sub 
{
    my $self   = shift;
    my $config = super();

    $self->_setup_static_dir($config);

    $config->{'View::CMS::Page'}->{AUTO_FILTER} = 'html';
    
    return $config;
};

sub _setup_static_dir {
    my ($self, $config) = @_;

    my $moduledir = try {
        File::ShareDir::module_dir('{{ $name }}');
    }
    catch {
        return if (/does not exist/);
        die $_;
    };
    return unless $moduledir;

    my $static_dirs = $config->{'Plugin::Static::Simple'}->{include_path};
    unshift(@$static_dirs, File::ShareDir::module_dir( '{{ $name }}' ) . '/root');
    $config->{'Plugin::Static::Simple'}->{include_path} = $static_dirs;
}

1;

=head1 NAME

{{ $name }}::Builder

=head1 DESCRIPTION

=head1 METHODS

=head1 ATTRIBUTES

=head1 LICENSE AND COPYRIGHT

Copyright 2015 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

