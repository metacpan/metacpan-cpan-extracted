package Devel::DTrace::Provider::Builder;
use strict;
use warnings;

use Sub::Install qw/ install_sub /;
use Sub::Exporter -setup => {
    exports => [
        qw/ as /,
        probe => \&build_probe,
        provider => \&build_provider,
        import => \&build_import
    ],
    groups  => {
        default => [
            qw/ as probe provider import /
        ],
    },
    collectors => {
        INIT => \&capture_caller
    }
};

use Devel::DTrace::Provider;

{
    my $caller;
    my $providers;
    my $coderef;
    my $provider_name;

    sub capture_caller {
        my (undef, $args) = @_;
        $caller = $args->{into};
    }

    sub as (&) {
        $coderef = shift;
    }

    sub build_provider {
        sub ($$) {
            $provider_name = shift;
            my $provider;
            $provider = Devel::DTrace::Provider->new($provider_name, 'perl')
                 if Devel::DTrace::Provider::DTRACE_AVAILABLE();

            $providers->{$caller}->{$provider_name} = {
                args => {},
                provider => $provider
            };

            $coderef->();

            for my $probe_name (keys %{$providers->{$caller}->{$provider_name}->{args}}) {
                my $args = $providers->{$caller}->{$provider_name}->{args}->{$probe_name};
                $provider->add_probe($probe_name, 'func', $args)
                     if Devel::DTrace::Provider::DTRACE_AVAILABLE();
                export_probe_functions($caller, $provider, $provider_name, $probe_name);
            }

            $provider->enable
                 if Devel::DTrace::Provider::DTRACE_AVAILABLE();
        }
    }

    sub build_probe {
        sub ($;@) {
            my $name = shift;
            $providers->{$caller}->{$provider_name}->{args}->{$name} = \@_;
        }
    }

    sub build_import {
        sub {
            my $package = caller(0);
            for my $provider_name (keys %{$providers->{$caller}}) {
                my $provider = $providers->{$caller}->{$provider_name}->{provider};
                for my $probe_name (keys %{$providers->{$caller}->{$provider_name}->{args}}) {
                    export_probe_functions($package, $provider, $provider_name, $probe_name);
                }
            }
        }
    }
}

sub export_probe_functions {
    my ($package, $provider, $provider_name, $probe_name) = @_;

    my $probe = probe_function($provider, $probe_name);
    my $isenabled = probe_enabled_function($provider, $probe_name);

    $provider_name =~ tr/-/_/;
    $probe_name =~ tr/-/_/;

    my $enabled_name = $probe_name . '_enabled';
    my $provider_probe_name = $provider_name . '_' .$probe_name;
    my $provider_enabled_name = $provider_probe_name . '_enabled';

    install_sub({
        code => $probe,
        into => $package,
        as => $probe_name
    });
    install_sub({
        code => $isenabled,
        into => $package,
        as => $enabled_name
    });
    install_sub({
        code => $probe,
        into => $package,
        as => $provider_probe_name
    });
    install_sub({
        code => $isenabled,
        into => $package,
        as => $provider_enabled_name
    });
}

sub probe_function {
    my ($provider, $probe_name) = @_;

    if (Devel::DTrace::Provider::DTRACE_AVAILABLE()) {
        my $stub = $provider->probes->{$probe_name};
        return sub (&) { shift->($stub) if $stub->is_enabled };
    }
    else {
        return sub (&) { 1 };
    }
}

sub probe_enabled_function {
    my ($provider, $probe_name) = @_;

    if (Devel::DTrace::Provider::DTRACE_AVAILABLE()) {
        my $stub = $provider->probes->{$probe_name};
        return sub { $stub->is_enabled };
    }
    else {
        return sub { 0 };
    }
}

1;

__END__

=pod

=head1 NAME

Devel::DTrace::Provider::Builder - declaratively create DTrace USDT providers

=head1 SYNOPSIS

  package MyApp::DTraceProviders;
  use strict;
  use warnings;

  use Devel::DTrace::Provider::Builder;

  provider 'backend' => as {
      probe 'process_start', 'integer';
      probe 'process_end',   'integer';
  };

  provider 'frontend' => as {
      probe 'render_start', 'string';
      probe 'render_end',   'string';
  };

  # elsewhere

  use MyApp::DTraceProviders;

  process_start

  # Or use probes immediately in the same package.

  use Devel::DTrace::Provider::Builder;
  use strict;
  use warnings;

  BEGIN {
    provider 'provider1' => as {
      probe 'probe1', 'string';
      probe 'probe2', 'string';
  };

  probe1 { shift->fire('foo') } if probe1_enabled;
  probe2 { shift->fire('foo') } if probe2_enabled;

=head1 DESCRIPTION

This module provides a declarative way of creating DTrace providers,
in packages which export their probes on import. This is typically
what you want when creating a provider for use in a large application:

Providers created with this module may be used on systems where DTrace
is not supported: the probes will be optimised away entirely -- see
"DISABLED PROBE EFFECT", below.

=over 4

=item Declare your provider in its own package

=item Use the provider in your application

=item Fire the probes imported

=back

=head2 Declare the providers

You can declare any number of providers in a single package: they will
all be enabled and their probes imported when the package is used.

The general syntax of a provider declaration is:

  provider 'provider_name' => as {
    probe 'probe_name', [ 'argument-type', ... ];
    ...
  };

The supported argument types are 'integer' and 'string', corresponding
to native int and char * probe arguments.

=head2 Use the provider

Just use the package where you defined the provider:

  use MyApp::DTraceProviders;

This will import all the probe subs defined in the package into your
namespace.

=head2 Fire the probes

To fire a probe, call the function, passing a coderef in which you
call the C<fire> method on C<$_[0]>:

  probe { shift->fire };

The coderef is only called if the probe is enabled by DTrace, so you
can do whatever work is necessary to gather probe arguments and know
that code will not run when DTrace is not active:

  probe {
    my @args = gather_expensive_args();
    shift->fire(@args);
  };

=head1 DISABLED PROBE EFFECT

Two features allow you to reduce the disabled probe effect:

=over 4

=item Argument-gathering coderef

=item *_enabled functions

=back

=head2 Argument-gathering coderef

This applies to code on DTrace enabled systems: the coderef is
only executed if the probe is enabled, so you can put code there which
only runs when tracing is active.

=head2 *_enabled functions

This applies to systems without DTrace: if you form your probe
tracepoints with a postfix if, like this:

  fooprobe { shift->fire } if fooprobe_enabled;

on a system without DTrace, fooprobe_enabled will be a constant sub
returning 0, and the entire line will be optimised away, which means
probes embedded in code have zero overhead. This feature is taken from
Tim Bunce's DashProfiler:

http://search.cpan.org/~timb/DashProfiler-1.13/lib/DashProfiler/Import.pm

=cut
