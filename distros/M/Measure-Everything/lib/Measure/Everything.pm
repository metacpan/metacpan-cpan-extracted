package Measure::Everything;
use 5.010;
use strict;
use warnings;
use Module::Runtime qw(use_module);

our $VERSION = '1.002';

# ABSTRACT: Log::Any for Stats

our $global_stats;

sub import {
    my $class  = shift;
    my $target = shift;
    my $caller = caller();

    $target ||= '$stats';
    $target =~ s/^\$//;

    if ( !$global_stats ) {
        $global_stats = use_module('Measure::Everything::Adapter::Null')->new;
    }

    {
        no strict 'refs';
        my $varname = "$caller\::" . $target;
        *$varname = \$global_stats;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything - Log::Any for Stats

=head1 VERSION

version 1.002

=head1 SYNOPSIS

In a module where you want to count some stats:

  package Foo;
  use Measure::Everything qw($stats);

  $stats->write('jigawats', 1.21, { source=>'Plutonium', location=>'Hill Valley' });

In your application:

  use Foo;
  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('InfluxDB::File', %args);

=head1 DESCRIPTION

C<Measure::Everything> tries to provide a standard measuring API for
modules (like L<Log::Any|https://metacpan.org/pod/Log::Any> does for
logging). C<Measure::Everything::Adapter>s allow applications to
choose the mechanism for measuring stats (for example
L<InfluxDB|https://influxdb.com>, L<OpenTSDB|http://opentsdb.net/>,
Graphite, etc).

For now, C<Measure::Everything> only supports C<InfluxDB>, because
that's what we're using. But I hope that other time series databases
(or other storage backends) can be added to C<Measure::Everything>.
Unfortunately, measuring stats is not such a well-established domain
like logging (where we have a set of common log levels, and basically
"just" need to pass some string to some logging sink). So it is very
likely that C<Measure::Everything> cannot provide a generic API, where
you can switch out Adapters without changing the measuring code. But
we can try!

C<Measure::Everything> currently provides a way to access a global
object C<$stats>, on which you can call the C<write> method. The
currently active C<Adapter> decides what to do with the data passed to
C<write>. In contrast to C<Log::Any>, there can be only one active
C<Adapter>.

=head1 PRODUCING STATS (FOR MODULES)

=head2 Getting a stats handler

  use Measure::Everything qw($stats);

This will import a C<$stats> object into your current namespace. What
this object will do depends on the active Adapter (see section
CONSUMING STATS)

=head2 Counting

For now, C<Measure::Everything> provides one method to write stats,
C<write>:

  $stats->write($measurement, $value | \%values, \%tags?, $timestamp?);

It is still a bit uncertain whether this API will work for all
possible time series databases and other storage backends. But it
works for C<InfluxDB>!

C<$measurement> is the name of the thing you want to count.

C<$value> or C<\%values> is the value you want to count. Not all
databases can handle multiple values. In this case it should be the
job of the Adapter to convert the hashref of values into something the
storage backend can handle.

C<\%tags> is a hashref of further tags. InfluxDB uses them, not sure
about other systems.

C<$timestamp> is the time of the measurement. In general you should
not pass a timestamp and instead let the Adapter figure out the
current time and format it in a way the backend can understand. But if
you want to record stats for past (or future?) events, you will need
to pass in the timestamp in the correct format (or hope that the
Adapter will convert it for you).

=head1 CONSUMING STATS (FOR APPLICATIONS)

C<Application> here means the script running your modules. Could be a
daemon, a cron-job, a command line script, whatever. In this script
you will have to define what to do with stats generated in your
modules. You could throw them away (by using
C<Measure::Everything::Adapter::Null>), which is the default. Or you
define an adapter, that will handle the data passed via C<write>.

  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('InfluxDB::File', file => '/tmp/my_app.stats');

=head1 TODO

=over

=item * tests

=item * docs

=item * Measure::Everything::Adapter::Memory

=item * Measure::Everything::Adapter::Test

=item * more InfluxDB Adapters: Direct, ZeroMQ, UDP, ..

=item * move Measure::Everything::Adapter::InfluxDB::* into seperate distribution(s)

=back

=head1 SEE ALSO

The basic concept is stolen from
<Log::Any|https://metacpan.org/pod/Log::Any>. If you have troubles
understanding this set of modules, please read the excellent Log::Any
docs, and substitue "logging" with "writing stats".

For more information on measuring & stats, and the obvious inspiration
for this module's name, read the interesting article L<Measure
    Anything, Measure
    Everything|https://codeascraft.com/2011/02/15/measure-anything-measure-everything/>
    by Ian Malpass from L<Etsy|http://etsy.com/>.

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|http://www.validad.com/> for funding the
development of this code.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
