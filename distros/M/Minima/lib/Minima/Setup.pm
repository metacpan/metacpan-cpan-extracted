use v5.40;

package Minima::Setup;

use Carp;
use Minima::App;
use Path::Tiny;
use Plack::Test;
use YAML::XS 'LoadFile';

our $config = {};
our $app;
our $base;

sub import
{
    shift; # discard package name

    # If we were called from a .psgi, save
    # its parent as the base directory
    my $caller = path( (caller)[1] );
    if ($caller->basename =~ /\.psgi$/) {
        $base = $caller->absolute->parent;
    } else {
        $base = path('.')->absolute;
    }

    prepare(@_);
}

sub prepare ($file = undef)
{
    my $default_prefix = $base->child('etc/config');
    my @files = map { "$default_prefix.$_" } qw/ yaml yml pl /;

    if ($file) {
        my $file_abs = path($file)->absolute;

        croak "Config file `$file` does not exist.\n"
            unless -e $file_abs;

        $file = $file_abs;
    }
    unshift @files, $file;

    my $adjective;

    for (my $i = 0; $i < @files; $i++) {

        my $f = $files[$i];
        next unless defined $f && -e $f;

        $adjective = $i ? 'default ' : '';

        if ($f =~ /\.ya?ml$/) {
            try {
                $config = LoadFile $f;
            } catch ($e) {
                croak "Failed to parse ${adjective}config file "
                    . "`$f`:\n$e\n";
            }
        } else {
            $config = do $f;
            croak "Failed to parse ${adjective}config file "
                . "`$f`: $@\n" if $@;
        }

        last;
    }

    croak "Config is not a hash reference.\n"
        unless ref $config eq ref {};

    # If the loaded config does not set base_dir,
    # set it to the saved .psgi directory
    $config->{base_dir} = $base->stringify
        unless defined $config->{base_dir};

    # Initialize app
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
    use Minima::Setup 'config.yaml';
    \&Minima::Setup::init;

=head1 DESCRIPTION

This package is dedicated to the initial setup of a web application
using L<Minima>. It provides the main L<C<init>|/init> subroutine which
runs the app and can be passed (as a reference) as the starting
subroutine of a PSGI application. Additionally, it includes
L<C<prepare>|/prepare>, responsible for loading the configuration file
and preparing the main objects.

During its import, Minima::Setup also captures the path of the caller
file. If this file has a F<.psgi> extension, its directory will be used
as the default base for the application. Otherwise, the current
directory will be used, unless the configuration explicitly sets
C<base_dir>.

=head1 CONFIG FILE

An optional argument may be optionally passed when C<use>-ing this
module, representing the configuration file. This argument is forwarded
to L<C<prepare>|/prepare> which can also be called directly.
Minima::Setup will attempt to read the file and use it to initialize
L<Minima::App>.

By default, Minima::Setup searches for configuration files in this
order: F<etc/config.yaml>, F<etc/config.yml>, then F<etc/config.pl>. The
first file found is loaded; files with F<.yaml> or F<.yml> extensions
are parsed as YAML, other extensions are treated as Perl. If no
configuration file is found and no custom file was passed, the
application is initialized with an empty configuration hash.

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
the created app (after importing the module) with C<$Minima::Setup::app>.

=head1 SEE ALSO

L<Minima>, L<Plack>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
