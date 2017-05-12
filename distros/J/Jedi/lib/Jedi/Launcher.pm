#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Launcher;

# ABSTRACT: Launcher for Jedi App

use Moo;
our $VERSION = '1.008';    # VERSION
use MooX::Options
    authors  => ['Celogeek <me@celogeek.com>'],
    synopsis => <<'__EOF__'

  jedi -c myApp.yml -c myAppProd.yml

In myApp.yml:

  Jedi:
    Roads:
      t::lib::configs::myConfigRoot: /
      t::lib::configs::myConfigAdmin: /admin

In myAppProd.yml:

  Plack:
    server: Starman
    env: production
  Starman:
    workers: 2
    port: 9999

__EOF__
    ;
use feature 'say';
use Config::Any;
use Jedi;
use Carp;
use Plack::Runner;
use lib ();

option 'config' => (
    is       => 'ro',
    format   => 's@',
    required => 1,
    short    => 'c',
    doc      => 'config files to load',
    isa      => sub {
        my $files = shift;
        for my $file ( @{$files} ) {
            next if -f $file;
            __PACKAGE__->options_usage( 1, "'$file' doesn't exist !\n" );
        }
        return;
    }
);

option 'lib' => (
    is      => 'ro',
    format  => 's@',
    short   => 'I',
    doc     => 'library to include',
    default => sub { [] },
);

sub run {
    my ($self) = @_;

    for my $lib ( @{ $self->lib } ) {
        lib->import($lib);
    }

    my $config = $self->parse_config;
    my $jedi   = $self->jedi_initialize($config);
    my ( $runner, $options ) = $self->plack_initialize($config);

    say "Loading : plackup ", join( " ", @$options );

    return $runner->run( $jedi->start );
}

sub parse_config {
    my ($self) = @_;

    my $config
        = Config::Any->load_files( { files => $self->config, use_ext => 1 } );
    my $config_merged = {};
    for my $c ( map { values %$_ } @$config ) {
        %$config_merged = ( %$config_merged, %$c );
    }

    croak "Jedi section is missing" if !defined $config_merged->{Jedi};
    croak "Jedi/Roads section is missing"
        if !defined $config_merged->{Jedi}{Roads};
    croak "Jedi/Roads shoud be 'module: path'"
        if ref $config_merged->{Jedi}{Roads} ne 'HASH';

    return $config_merged;
}

sub jedi_initialize {
    my ( $self, $config ) = @_;

    my $jedi = Jedi->new( config => $config );
    my %roads = %{ $config->{Jedi}{Roads} };
    for my $module ( keys %roads ) {
        $jedi->road( $roads{$module}, $module );
    }

    return $jedi;
}

sub plack_initialize {
    my ( $self, $config ) = @_;

    my $plack_config = $config->{Plack} // {};
    my $server_config
        = $plack_config->{server}
        ? $config->{ $plack_config->{server} } // {}
        : {};
    my @options = (
        ( map { "--" . $_ => $plack_config->{$_} } sort keys %$plack_config ),
        (   map { "--" . $_ => $server_config->{$_} }
            sort keys %$server_config
        ),
    );

    my $runner = Plack::Runner->new;

    $runner->parse_options( @options );

    return $runner, \@options;
}

1;

=pod

=head1 NAME

Jedi::Launcher - Launcher for Jedi App

=head1 VERSION

version 1.008

=head1 DESCRIPTION

This app load config files and start your jedi app.

=head1 SYNOPSIS

myBlog.yml:

  Jedi:
    Roads:
      Jedi::App::MiniCPAN::Doc: "/"
      Jedi::App::MiniCPAN::Doc::Admin: "/admin"
  Plack:
    env: production
    server: Starman
  Starman
    workers: 2
    port: 9999
  Jedi::App::MiniCPAN::Doc:
    path: /var/lib/minicpan

The Jedi is init with the roads inside the config.

The server plack is started using the config option. In that case it is equivalent to :

  plackup --env=production --server=Starman --workers=2 --port=9999 myjedi.psgi

Take a look at the L<plackup> option to see all possible config.

=head1 ATTRIBUTES

=head2 config

config files to load

=head2 lib

Include directory before starting include

=head1 METHODS

=head2 run

load config, init jedi and plack and start your apps

=head2 parse_config

load and merge all configs

=head2 jedi_initialize

initialize the jedi apps from configs

=head2 plack_initialize

initialize the plack runner from the option in the configs

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

