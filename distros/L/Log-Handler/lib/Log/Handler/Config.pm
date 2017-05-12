=head1 NAME

Log::Handler::Config - The main config loader.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    # Config::General
    $log->config(config => 'file.conf');

    # Config::Properties
    $log->config(config => 'file.props');

    # YAML
    $log->config(config => 'file.yaml');

Or

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->config(
        config => 'file.conf'
        plugin => 'YAML',
    );

=head1 DESCRIPTION

This module makes it possible to load the configuration from a file.
The configuration type is determined by the file extension. It's also
possible to mix file extensions with another configuration types.

=head1 PLUGINS

    Plugin name             File extensions
    ------------------------------------------
    Config::General         cfg, conf 
    Config::Properties      props, jcfg, jconf
    YAML                    yml, yaml

If the extension is not defined then C<Config::General> is used by default.

=head1 METHODS

=head2 config()

With this method it's possible to load the configuration for your outputs.

The following options are valid:

=over 4

=item B<config>

With this option you can pass a file name or the configuration as a
hash reference.

    $log->config(config => 'file.conf');
    # or
    $log->config(config => \%config);

=item B<plugin>

With this option it's possible to say which plugin you want to use.
Maybe you want to use the file extension C<conf> with C<YAML>, which
is reserved for the plugin C<Config::General>.

Examples:

    # this would use Config::General
    $log->config(
        config => 'file.conf'
    );

    # this would force .conf with YAML
    $log->config(
        config => 'file.conf',
        plugin => 'YAML'
    );

=item B<section>

If you want to write the configuration into a global configuration file
then you can create a own section for the logger:

    <logger>
        <file>
            filename = file.log
            minlevel = emerg
            maxlevel = warning
        </file>

        <screen>
            minlevel = emerg
            maxlevel = debug
        </screen>
    </logger>

    <another_script_config>
        foo = bar
        bar = baz
        baz = foo
    </another_script_config>

Now your configuration is placed in the C<logger> section. You can load this
section with

    $log->config(
        config  => 'file.conf',
        section => 'logger',
    );

    # or if you load the configuration yourself to %config

    $log->config(
        config  => \%config,
        section => 'logger',
    );

    # or just

    $log->config( config => $config{logger} );

=back

=head1 PLUGINS

    Config::General     -  inspired by the well known apache config format
    Config::Properties  -  Java-style property files
    YAML                -  optimized for human readability

=head1 EXAMPLES

=head2 Config structures

A very simple configuration looks like:

    $log->config(config => {
        file => {
            alias    => 'file1',
            filename => 'file1.log',
            maxlevel => 'info',
            minlevel => 'warn',
        },
        screen => {
            alias    => 'screen1',
            maxlevel => 'debug',
            minlevel => 'emerg',
        }
    });

Now, if you want to add another file-output then you can pass the outputs
with a array reference:

    $log->config(config => {
        file => [
            {
                alias    => 'file1,
                filename => 'file1.log',
                maxlevel => 'info',
                minlevel => 'warn',
            },
            {
                alias    => 'file2',
                filename => 'file2.log',
                maxlevel => 'error',
                minlevel => 'emergency',
            }
        ],
        screen => {
            alias    => 'screen1',
            maxlevel => 'debug',
            minlevel => 'emerg',
        },
    });

It's also possible to pass the outputs as a hash reference.
The hash keys "file1" and "file2" will be used as aliases.

    $log->config(config => {
        file => {
            file1 => {
                filename => 'file1.log',
                maxlevel => 'info',
                minlevel => 'warn',
            },
            file2 => {
                filename => 'file2.log',
                maxlevel => 'error',
                minlevel => 'emergency',
            }
        },
        screen => {
            alias    => 'screen1',
            maxlevel => 'debug',
            minlevel => 'emerg',
        },
    });

If you pass the configuration with the alias as a hash key then
it's also possible to pass a section called "default". The options
from this section will be used as defaults.

    $log->config(config => {
        file => {
            default => { # defaults for all file-outputs
                mode    => 'append',
            },
            file1 => {
                filename => 'file1.log',
                maxlevel => 'info',
                minlevel => 'warn',
            },
            file2 => {
                filename => 'file2.log',
                maxlevel => 'error',
                minlevel => 'emergency',
            }
        },
        screen => {
            alias    => 'screen1',
            maxlevel => 'debug',
            minlevel => 'emerg',
        },
    });

=head2 Examples for the config plugins

=head3 Config::General

    <file>
        alias = file1
        fileopen = 1
        reopen = 1
        permissions = 0640
        maxlevel = info
        minlevel = warn
        mode = append
        timeformat = %b %d %H:%M:%S
        debug_mode = 2
        filename = example.log
        message_layout = '%T %H[%P] [%L] %S: %m'
    </file>

Or

    <file>
        <file1>
            fileopen = 1
            reopen = 1
            permissions = 0640
            maxlevel = info
            minlevel = warn
            mode = append
            timeformat = %b %d %H:%M:%S
            debug_mode = 2
            filename = example.log
            message_layout = '%T %H[%P] [%L] %S: %m'
        </file1>
    </file>

=head3 YAML

    ---
    file:
      alias: file1
      debug_mode: 2
      filename: example.log
      fileopen: 1
      maxlevel: info
      minlevel: warn
      mode: append
      permissions: 0640
      message_layout: '%T %H[%P] [%L] %S: %m'
      reopen: 1
      timeformat: '%b %d %H:%M:%S'

Or

    ---
    file:
      file1:
        debug_mode: 2
        filename: example.log
        fileopen: 1
        maxlevel: info
        minlevel: warn
        mode: append
        permissions: 0640
        message_layout: '%T %H[%P] [%L] %S: %m'
        reopen: 1
        timeformat: '%b %d %H:%M:%S'

=head3 Config::Properties

    file.alias = file1
    file.reopen = 1
    file.fileopen = 1
    file.maxlevel = info
    file.minlevel = warn
    file.permissions = 0640
    file.mode = append
    file.timeformat = %b %d %H:%M:%S
    file.debug_mode = 2
    file.filename = example.log
    file.message_layout = '%T %H[%P] [%L] %S: %m'

Or

    file.file1.alias = file1
    file.file1.reopen = 1
    file.file1.fileopen = 1
    file.file1.maxlevel = info
    file.file1.minlevel = warn
    file.file1.permissions = 0640
    file.file1.mode = append
    file.file1.timeformat = %b %d %H:%M:%S
    file.file1.debug_mode = 2
    file.file1.filename = example.log
    file.file1.message_layout = '%T %H[%P] [%L] %S: %m'

=head1 PREREQUISITES

    Carp
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Config;

use strict;
use warnings;
our $VERSION = '0.09';

use Carp;
use File::Spec;
use Params::Validate;

sub config {
    my $self   = shift;
    my $params = $self->_validate(@_);
    my $config = $self->_get_config($params);

    if (ref($config) ne 'HASH') {
        croak "Bad config structure!";
    }

    # Structure:
    #   $log_config{file} = [ \%a, \%b, \%c ]
    #   $log_config{dbi}  = [ \%a, \%b, \%c ]
    my %log_config;

    foreach my $type (keys %$config) {
        my $output = $config->{$type};
        my $ref = ref($output);

        if ($ref eq 'HASH') {
            push @{$log_config{$type}}, $self->_get_hash_config($output);
        } elsif ($ref eq 'ARRAY') {
            push @{$log_config{$type}}, @$output;
        } else {
            croak "Bad config structure for '$type'";
        }
    }

    return \%log_config;
}

#
# private stuff
#

sub _get_config {
    my ($self, $params) = @_;
    my $config = ();
    my $plugin = $params->{plugin};

    if (ref($params->{config})) {
        $config = $params->{config};
    } elsif ($params->{config}) {
        eval "require $plugin";
        if ($@) {
            croak "unable to load plugin '$plugin' - $@";
        }
        $config = $plugin->get_config($params->{config});
    }

    if ($params->{section}) {
        return $config->{ $params->{section} };
    }

    return $config;
}

sub _get_hash_config {
    my ($self, $config) = @_;
    my @config  = ();
    my %default = ();

    if (exists $config->{default}) {
        %default = %{ $config->{default} };
    }

    foreach my $alias (keys %$config) {
        next if $alias eq "default";
        my $param = $config->{$alias};

        if (ref($param) ne 'HASH') {
            push @config, $config;
            last;
        }

        $param->{alias} = $alias;
        my %config = (%default, %$param);
        push @config, \%config;
    }

    return @config;
}

sub _validate {
    my $self = shift;

    my %options = Params::Validate::validate(@_, {
        config => {
            type => Params::Validate::SCALAR
                  | Params::Validate::HASHREF
                  | Params::Validate::ARRAYREF,
            optional => 1,
        },
        plugin => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        section => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
    });

    my $ref = ref($options{config});

    if ($ref ne 'HASH') {
        if ($ref eq 'ARRAY') {
            $options{config} = File::Spec->catfile(@{$options{config}});
        }

        if (!$options{plugin}) {
            if ($options{config} =~ /\.ya{0,1}ml\z/) {
                $options{plugin} = 'Log::Handler::Plugin::YAML';
            } elsif ($options{config} =~ /\.(?:props|jc(?:onf|fg))\z/) {
                $options{plugin} = 'Log::Handler::Plugin::Config::Properties';
            } else {
                $options{plugin} = 'Log::Handler::Plugin::Config::General';
            }
        }
    }

    return \%options;
}

1;
