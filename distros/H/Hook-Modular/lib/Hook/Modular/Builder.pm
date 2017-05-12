use 5.008;
use strict;
use warnings;

package Hook::Modular::Builder;
BEGIN {
  $Hook::Modular::Builder::VERSION = '1.101050';
}
# ABSTRACT: Domain-specific language for building configurations
use Exporter qw(import);
our @EXPORT = qw(builder enable global log_level cache_base);
use Carp ();

sub new {
    my $class = shift;
    bless { config => {} }, $class;
}

sub do_enable {
    my ($self, $plugin, %args) = @_;
    $self->{config}{plugins} ||= [];
    push @{ $self->{config}{plugins} },
      { module => $plugin,
        config => \%args
      };
}

sub do_global (&) {
    my ($self, $global) = @_;
    $self->{config}{global} = $global;
}

# convenience subs to get at more specific but often used config locations

sub do_log_level {
    my ($self, $log_level) = @_;
    $self->{config}{global}{log}{level} = $log_level;
}

sub do_cache_base {
    my ($self, $cache_base) = @_;
    $self->{config}{global}{cache}{base} = $cache_base;
}

our $_enable = sub {
    Carp::croak("enable should be called inside builder {} block");
};
our $_global = sub {
    Carp::croak("global should be called inside builder {} block");
};
our $_log_level = sub {
    Carp::croak("log_level should be called inside builder {} block");
};
our $_cache_base = sub {
    Carp::croak("cache_base should be called inside builder {} block");
};
sub enable { $_enable->(@_) }
sub global { $_global->(@_) }
sub log_level { $_log_level->(@_) }
sub cache_base { $_cache_base->(@_) }

sub builder(&) {
    my $block = shift;
    my $self  = __PACKAGE__->new;
    local $_enable = sub {
        $self->do_enable(@_);
    };
    local $_global = sub {
        $self->do_global(@_);
    };
    local $_log_level = sub {
        $self->do_log_level(@_);
    };
    local $_cache_base = sub {
        $self->do_cache_base(@_);
    };
    $block->();
    $self->{config};
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::Builder - Domain-specific language for building configurations

=head1 VERSION

version 1.101050

=head1 SYNOPSIS

    use Hook::Modular::Builder;

    my $config = builder {
        global {
            log     => { level => 'error' },
              cache => { base  => '/tmp/test-hook-modular' },
        };

        # or:
        # log_level 'error';
        enable 'Some::Printer',
          indent => 4, indent_char => '*', text => 'this is some printer';
        enable 'Another::Plugin', foo => 'bar' if $ENV{BAZ};
    };
    main->bootstrap(config => $config);

=head1 DESCRIPTION

With this module you can use a domain-specific language (DSL) to build
L<Hook::Modular> configurations. The functions are exported automatically.

This package is also a class in disguise. The methods are not intended for
public consumption, but they are documented nevertheless.

=head1 METHODS

=head2 new

Creates a new object. This method is called by C<builder()> so it can be used
by functions like C<enable()> and C<global()>.

=head2 do_enable

Does the actual work of the C<enable()> function. It is called from
C<enable()> with the object constructed by C<builder()>.

=head2 do_global

Does the actual work of the C<global()> function. It is called from
C<global()> with the object constructed by C<builder()>.

=head2 do_log_level

Does the actual work of the C<log_level()> function. It is called from
C<log_level()> with the object constructed by C<builder()>.

=head2 do_cache_base

Does the actual work of the C<cache_base()> function. It is called from
C<cache_base()> with the object constructed by C<builder()>.

=head1 FUNCTIONS

=head2 builder

Takes a block in which you can enable plugins and define global configuration.
It is normal Perl code, so you could, for example, only enable a plugin if a
certain environment variable is set:

    my $config = builder {
        # ...
        enable 'Another::Plugin', foo => 'bar' if $ENV{BAZ};
    };

It returns a configuration hash that can be passed to L<Hook::Modular>
objects.

=head2 enable

Adds a plugin to the configuration. It takes as arguments the plugin name and
an optional list of plugin configuration arguments. Plugins are added in the
order in which they are defined in the C<builder()> block.

Example:

    my $config = builder {
        enable 'Some::Printer',
          indent => 4, indent_char => '*', text => 'this is some printer';
    };

This is equivalent to having the following in a YAML configuration file:

    plugins:
      - module: Some::Printer
        config:
          indent: 4
          indent_char: '*'
          text: 'this is some printer'

If you call this function outside a C<builder()> block, you will get an error.

=head2 global

Defines the global configuration. Takes as arguments a hash of options.

Example:

    my $config = builder {
        global {
            log     => { level => 'error' },
              cache => { base  => '/tmp/test-hook-modular' };
        };

This is equivalent to having the following in a YAML configuration file:

    global:
      log:
        level: error
      cache:
        base: /tmp/test-hook-modular

If you call this function outside a C<builder()> block, you will get an error.

=head2 log_level

Takes as an argument a log level string - for example, C<error> - and sets the
global log level configuration value; any other global configuration is left
untouched.

Example:

    my $config = builder {
        log_level 'error';
    };

This is equivalent to the following C<global()> call:

    my $config = builder {
        global {
            log => { level => 'error' },
        };

And it is equivalent to having the following in a YAML configuration file:

    global:
      log:
        level: error

If you call this function outside a C<builder()> block, you will get an error.

=head2 cache_base

Takes as an argument a path string and sets the global cache base
configuration value; any other global configuration is left untouched.

Example:

    my $config = builder {
        cache_base '/tmp/test-hook-modular';
    };

This is equivalent to the following C<global()> call:

    my $config = builder {
        global {
            cache => { base => 'error' },
        };

And it is equivalent to having the following in a YAML configuration file:

    global:
        cache:
            base: error

If you call this function outside a C<builder()> block, you will get an error.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

