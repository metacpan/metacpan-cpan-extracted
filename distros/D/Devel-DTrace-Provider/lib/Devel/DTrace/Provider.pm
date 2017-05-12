package Devel::DTrace::Provider;

use 5.008;
use strict;
use warnings;
use vars qw/ $DTRACE_AVAILABLE /;

use JSON;

BEGIN {
	our $VERSION = '1.11';
	require XSLoader;
	eval {
            XSLoader::load('Devel::DTrace::Provider', $VERSION);
	};

	$DTRACE_AVAILABLE = 1;
	if ($@ && $@ =~ /Can't locate loadable object/) {
		# No object - assume it wasn't built, and we should noop everything.
		$DTRACE_AVAILABLE = 0;
	}

	sub DTRACE_AVAILABLE { $DTRACE_AVAILABLE };
}

sub probe {
    my ($self, $name, $function, @types) = @_;
    $self->add_probe($name, $function, \@types);
}

1;

__END__

=pod

=head1 NAME

Devel::DTrace::Provider - Create DTrace providers for Perl programs.

=head1 SYNOPSIS

  # Listen for the probe we'll fire:

  sudo dtrace -qZn 'provider1*::: { printf("%s:%s:%s:%s\n", probeprov, probemod, probefunc, probename) }'

  # Create a provider and fire a probe:

  use Devel::DTrace::Provider;

  my $provider = Devel::DTrace::Provider->new('provider1', 'perl');
  my $probe = $provider->add_probe('probe1', 'function', ['string']);
  $provider->enable;

  $probe->fire('foo');

  # DTrace output:

  provider15949:perl:function:probe1

  (5949 is the pid of the Perl process)

=head1 DESCRIPTION

This module lets you create DTrace providers for your Perl programs,
from Perl - no further native code is required.

When you create a provider and call its C<enable> method, the following
happens:

Native functions are created for each probe, containing the DTrace
tracepoints to be enabled later by the kernel. DOF (DTrace Object
Format) is then generated representing the provider and the
tracepoints generated, and is inserted into the kernel via the DTrace
helper device. Perl functions are created for each probe, so they can
be fired from Perl code.

Your program does not need to run as root to create providers.

Providers created by this module should survive fork(), and become
visible from both parent and child processes separately.

=head2 Using Perl providers

=over 4

=item Listing probes available

To list the probes created by your providers, invoke dtrace(1):

  $ sudo /usr/sbin/dtrace -l -n 'myprovider*:::'

where "myprovider" is the name of your provider. To restrict this to a
specific process by PID, replace the * by the pid:

  $ sudo /usr/sbin/dtrace -l -n 'myprovider1234:::'

=item Observing probe activity

To just see the probes firing, use a command like:

  $ sudo /usr/sbin/dtrace -n 'myprovider*:::'

If your script is not already running when you run dtrace(1), use the
-Z flag, which indicates that dtrace(1) should wait for the probes to
be created, rather than exiting with an error:

  $ sudo /usr/sbin/dtrace -Z -n 'myprovider*:::'

=item Collecting probe arguments

To collect arguments from a specific probe, you can use the trace()
action:

  $ sudo /usr/sbin/dtrace -n 'myprovider*:::myprobe{ trace(arg0); }'

for an integer argument, and:

  $ sudo /usr/sbin/dtrace -n 'myprovider*:::myprobe{ trace(copyinstr(arg0)); }'

for a string argument.

There are numerous other actions and predicates - see the DTrace guide
for full details:

  http://docs.sun.com/app/docs/doc/817-6223

=back

=head1 CAVEATS

=head2 Platform support

This module is supported only on platforms where libusdt is available.

See: https://github.com/chrisa/libusdt

=head1 METHODS

=head2 new($provider_name, $module_name)

Create a provider. Takes the name of the provider, and the name of the
module it should appear to be in to DTrace (in native code this would
be the library, kernel module, executable etc).

Returns an empty provider object.

=head2 probe($probe_name, @argument_types...)

Adds a probe to the provider, named $probe_name. Arguments are set up
with the types specified. Supported types are 'string' (char *) and
'integer' (int). A maximum of 32 arguments is supported.

Returns a probe object.

=head2 enable()

Actually adds the provider to the running system. Croaks if there was
an error inserting the provider into the kernel, or if memory could
not be allocated for the tracepoint functions.

=head1 DEVELOPMENT

The source to Devel::DTrace::Provider is in github:

  https://github.com/chrisa/perl-Devel-DTrace-Provider

=head1 AUTHOR

Chris Andrews <chris@nodnol.org>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2008-2012, Chris Andrews <chris@nodnol.org>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
