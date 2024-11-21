use v5.40;

package Minima::Setup;

use Carp;
use Minima::App;
use Path::Tiny;
use Plack::Test;

our $config = {};
our $app;

sub import
{
    shift; # discard package name
    prepare(@_);
}

sub prepare ($file = undef)
{
    my $default_config = './etc/config.pl';

    if ($file) {
        my $file_abs = path($file)->absolute;

        croak "Config file `$file` does not exist.\n"
            unless -e $file_abs;

        $config = do $file_abs;
        croak "Failed to parse config file `$file`: $@\n" if $@;

    } elsif (-e $default_config) {
        $config = do $default_config;
        croak "Failed to parse default config file `$default_config`: "
            . "$@\n" if $@;
    }
    croak "Config is not a hash reference.\n"
        unless ref $config eq ref {};

    # initialize app
    $app = Minima::App->new(
        configuration => $config,
    );
}

sub init ($env)
{
    $app->set_env($env);
    $app->run;
}

sub test
{
    Plack::Test->create(\&init);
}

1;

__END__

=head1 NAME

Minima::Setup - Setup a Minima web application

=head1 SYNOPSIS

    # app.psgi
    use Minima::Setup 'config.pl';
    \&Minima::Setup::init;

=head1 DESCRIPTION

This package is dedicated to the initial setup of a web application
using L<Minima>. It provides the main L<C<init>|/init> subroutine which
runs the app and can be passed (as a reference) as the starting
subroutine of a PSGI application. Additionally, it includes
L<C<prepare>|/prepare>, responsible for loading the configuration file
and preparing the main objects.

=head1 CONFIG FILE

An optional argument may be optionally passed when C<use>-ing this
module, representing the configuration file. This argument is forwarded
to L<C<prepare>|/prepare> which can also be called directly.
Minima::Setup will attempt to read the file and use it to initialize
L<Minima::App>.

By default, the configuration file is assumed to be F<etc/config.pl>. If
this file exists and no other location is provided, it will be used. If
nothing was passed and no file exists at the default location, the app
will be loaded with an empty configuration hash.

=head1 SUBROUTINES

=head2 init

    sub init ($env)

Receives the Plack environment and runs the L<Minima::App> object. A
reference to this subroutine can be passed as the starting point of the
PSGI application.

=head2 prepare

    sub prepare ($file = undef)

Reads the provided configuration file, or the default one (see L<"Config
File"|/"CONFIG FILE">) and initializes the internal L<Minima::App>
object.

=head2 test

    sub test ()

Creates and returns a L<Plack::Test> object with the current
Minima::App. See L<Minima::Manual::Testing> for more on testing.

=head1 TESTING

For testing purposes, you may want to have Minima::Setup load the
configuration and create a L<Minima::App>. You can access a reference to
the created app (after importing the module) with C<Minima::Setup::app>.

=head1 SEE ALSO

L<Minima>, L<Plack>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
