package HPC::Runner::Command::Utils::ManyConfigs;

our $VERSION = '0.03';

use 5.010;
use utf8;

use namespace::autoclean;
use MooseX::App::Role;

use Config::Any;
use File::HomeDir;
use Cwd;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPaths AbsFile/;
use Path::Tiny;
use Try::Tiny;

option 'no_configs' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => '--no_configs tells HPC::Runner not to load any configs',
);

option 'config' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    documentation => 'Override the search paths and supply your own config.',
    isa           => AbsFile,
    coerce        => 1,
    predicate     => 'has_config',
);

option 'config_base' => (
    is            => 'rw',
    isa           => 'Str',
    default       => '.config',
    documentation => 'Basename of config files',
);

option 'search' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
    handles => {
        'no_search' => 'unset',
    },
    documentation =>
'Search for config files in ~/.config.(ext) and in your current working directory.'
);

option 'search_path' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [ File::HomeDir->my_home, getcwd() ] },
    handles => {
        all_search_path     => 'elements',
        append_search_path  => 'push',
        prepend_search_path => 'unshift',
        map_search_path     => 'map',
        has_search_path     => 'count',
    },
    documentation =>
      'Enable a search path for configs. Default is the home dir and your cwd.'
);

has 'filter_keys' => (
    is      => 'rw',
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        all_filter_keys     => 'elements',
        append_filter_keys  => 'push',
        prepend_filter_keys => 'unshift',
        map_filter_keys     => 'map',
        has_filter_keys     => 'count',
    },
);

has 'config_files' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => AbsPaths,
    coerce  => 1,
    default => sub { [] },
    handles => {
        all_config_files     => 'elements',
        append_config_files  => 'push',
        prepend_config_files => 'unshift',
        map_config_files     => 'map',
        has_config_files     => 'count',
        count_config_files   => 'count',
    },
);

has '_config_data' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => 'has_config_data',
    default   => sub { [] },
);

sub BUILD { }

before 'BUILD' => sub {
    my $self = shift;

    return if $self->no_configs;
    $self->decide_search_configs;
};

sub decide_search_configs {
    my $self = shift;

    if ( $self->has_config ) {
        $self->append_config_files( $self->config );
        $self->load_configs;
    }
    elsif ( $self->search ) {
        $self->search_configs;
    }
}

sub search_configs {
    my $self      = shift;
    my $extension = shift;

    foreach my $extension ( Config::Any->extensions ) {
        foreach my $dir ( $self->all_search_path ) {
            my $dir = $dir . '/';

            #We will check with and without extensions
            my $check_file;
            $check_file = File::Spec->catfile( $dir . $self->config_base );
            $self->append_config_files($check_file) if -f $check_file;

            $check_file =
              File::Spec->catfile(
                $dir . $self->config_base . '.' . $extension );
            $self->append_config_files($check_file) if -f $check_file;
        }
    }

    $self->load_configs;

}

sub load_configs {
    my $self = shift;

    my $command_name = $self->{_original_class_name};
    my $cfg =
      Config::Any->load_files( { files => $self->config_files, use_ext => 1 } );

    $self->_config_data($cfg);

    $self->apply_configs;
}

sub apply_configs {
    my $self = shift;

    my $command_name = $self->{_original_class_name};
    for ( my $x = 0 ; $x < $self->count_config_files ; $x++ ) {
        my $c    = $self->_config_data->[$x]->{ $self->config_files->[$x] };
        my @keys = keys %{$c};

        if ( !$self->has_filter_keys ) {
            my @filter_keys = grep { $_ ne 'global' } @keys;
            $self->filter_keys( \@filter_keys );
        }

        #Global is always applied
        $self->apply_attributes( $c, 'global' ) if exists $c->{global};

        map { $self->apply_attributes( $c, $_ ) } $self->all_filter_keys;
    }

}

sub apply_attributes {
    my $self = shift;
    my $conf = shift;
    my $attr = shift;

    return unless ref($conf) eq 'HASH';
    return unless ref( $conf->{$attr} ) eq 'HASH';

    while ( my ( $key, $value ) = each %{ $conf->{$attr} } ) {

        if ( $self->can($key) ) {
            try {
                $self->$key($value);
            }
            catch {
                warn 'You tried to assign ' . $key . ' to ' . $value . "\n";

                #TODO Add logging
            };
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

HPC::Runner::Command::Utils::ManyConfigs - Load many layered configs

=head1 SYNOPSIS

  use Moose;
  with 'HPC::Runner::Command::Utils::ManyConfigs';

  #Specify search_paths with --search_path
  #Specify config base with --config_base


=head1 DESCRIPTION

HPC::Runner::Command::Utils::ManyConfigs are just some helper utilities to make it easier to layer config files

It is in the HPC::Runner::Command namespace, but it is meant to be portable for any MooseX::App.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
