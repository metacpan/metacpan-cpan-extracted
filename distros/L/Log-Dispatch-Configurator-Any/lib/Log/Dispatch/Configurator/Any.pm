package Log::Dispatch::Configurator::Any;
{
  $Log::Dispatch::Configurator::Any::VERSION = '1.122640';
}

use strict;
use warnings FATAL => 'all';

use base 'Log::Dispatch::Configurator';
use Config::Any;
use Carp;

sub new {
    my($class, $file) = @_;
    my $self = {};

    # allow passing of hashref or filename
    if (ref $file) {
        croak "Config must be hashref or filename"
            if ref $file ne 'HASH';

        $self = bless { file => undef, _config => $file }, $class;
    }
    else {
        $self = bless { file => $file }, $class;
        $self->parse_file;
    }

    return bless $self, $class;
}

sub parse_file {
    my $self = shift;
    my $file = $self->{'file'};

    my $config = eval{ Config::Any->load_files({
        files => [$file],
        use_ext => 1,
        flatten_to_hash => 1,
    })->{$file} };

    croak "Config '$file' does not build a Hash"
        if $@ or (ref $config ne 'HASH');
    $self->{'_config'} = $config;
}

sub reload {
    my $self = shift;
    return if !defined $self->{file};
    $self->parse_file;
}

sub get_attrs_global {
    my $self = shift;
    my $attrs;

    foreach (keys %{$self->{_config}}) {
        next if ref $self->{'_config'}->{$_} eq 'HASH';
        $attrs->{$_} = $self->{'_config'}->{$_};
    }

    # fix for Config::General squashing single item list to a scalar
    $attrs->{dispatchers} = [$attrs->{dispatchers}]
        if ! ref $attrs->{dispatchers};

    return $attrs;
}

sub get_attrs {
      my($self, $name) = @_;
      return $self->{'_config'}->{$name};
}

1;


# ABSTRACT: Configurator implementation with Config::Any


__END__
=pod

=head1 NAME

Log::Dispatch::Configurator::Any - Configurator implementation with Config::Any

=head1 VERSION

version 1.122640

=head1 PURPOSE

Use this module in combination with L<Log::Dispatch::Config> to allow many
formats of configuration file to be loaded, via the L<Config::Any> module.

=head1 SYNOPSIS

In the traditional Log::Dispatch::Config way:

 use Log::Dispatch::Config; # loads Log::Dispatch
 use Log::Dispatch::Configurator::Any;
  
 my $config = Log::Dispatch::Configurator::Any->new('log.yml');
 Log::Dispatch::Config->configure($config);
  
 # nearby piece of code
 my $log = Log::Dispatch::Config->instance;
 $log->alert('Hello, world!');

Alternatively, without a config file on disk:

 use Log::Dispatch::Config; # loads Log::Dispatch
 use Log::Dispatch::Configurator::Any;
  
 my $confhash = {
     dispatchers => ['screen]',
     screen = {
         class => 'Log::Dispatch::Screen',
         min_level => 'debug',
     },
 };
  
 my $config = Log::Dispatch::Configurator::Any->new($confhash);
 Log::Dispatch::Config->configure($config);
  
 # nearby piece of code
 my $log = Log::Dispatch::Config->instance;
 $log->alert('Hello, world!');

=head1 DESCRIPTION

L<Log::Dispatch::Config> is a wrapper for L<Log::Dispatch> and provides a way
to configure Log::Dispatch objects with configuration files. Somewhat like a
lite version of log4j and L<Log::Log4perl> it allows multiple log
destinations. The standard configuration file format for Log::Dispatch::Config
is AppConfig.

This module plugs in to Log::Dispatch::Config and allows the use of other file
formats, in fact any format supported by the L<Config::Any> module. As a bonus
you can also pass in a configuration data structure instead of a file name.

=head1 USAGE

Follow the examples in the L</SYNOPSIS>. If you are using an external
configuration file, be aware that you are required to use a filename extension
(e.g.  C<.yml> for YAML).

Below are a couple of tips and tricks you may find useful.

=head2 Fall-back default config

Being able to use a configuration data structre instead of a file on disk is
handy when you want to provide application defaults which the user then
replaces with their own settings. For example you could have the following:

 my $defaults = {
     dispatchers => ['screen'],
     screen => {
         class     => 'Log::Dispatch::Screen',
         min_level => 'debug',
     },
 };
  
 my $config_file = '/etc/myapp_logging.conf';
 my $config = $ENV{MYAPP_LOGGING_CONFIG} || $ARGV[0] ||
     ( -e $config_file ? $config_file : $defaults);
 
 Log::Dispatch::Config->configure_and_watch(
     Log::Dispatch::Configurator::Any->new($config) );
 my $dispatcher = Log::Dispatch::Config->instance;

With the above code, your application will check for a filename in an
environment variable, then a filename as a command line argument, then check
for a file on disk, and finally use its built-in defaults.

=head2 Dealing with a C<dispatchers> list

L<Log::Dispatch::Config> requires that a global setting C<dispatchers> have a
list value (i.e. your list of dispatchers). A few config file formats do not
support list values at all, or list values at the global level (two examples
being L<Config::Tiny> and L<Config::General>).

This module allows you to have a small grace when there is only one dispatcher
in use. Write the configuration file normally, and the single-item
C<dispatchers> value will automatically be promoted to a list. In other words:

 # myapp.ini
 dispatchers = screen
 
 # this becomes a config of:
 $config = { dispatchers => 'screen', ... };
 
 # so this module promotes it to:
 $config = { dispatchers => ['screen'], ... };

If you want more than one dispatcher, you then need to use a config file
format which supports these lists natively, I'm afraid. A good suggestion
might be YAML.

=head1 THANKS

My thanks to C<miyagawa> for writing Log::Dispatch::Config, from where I also took
some tests. Also thanks to Florian Merges for his YAML Configurator, which was
a useful example and saved me much time.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

