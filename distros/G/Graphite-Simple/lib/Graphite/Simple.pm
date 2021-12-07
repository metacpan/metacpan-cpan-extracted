package Graphite::Simple;

use 5.026;
use strict;
use warnings;
use base qw/ Exporter /;

our %EXPORT_TAGS = ( 'all' => [ ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.08';

our %avg_counters;
our %bulk;
our %invalid;

require XSLoader;
XSLoader::load('Graphite::Simple', $VERSION);

1;
__END__
=encoding utf8

=head1 NAME

Graphite::Simple - Perl XS package provides methods to collect metrics and send them to Graphite server.

=head1 SYNOPSIS

  use Graphite::Simple ();

  my $graphite = Graphite::Simple->new(\%options);

  $graphite->connect();

  $graphite->disconnect();

  my $bulk = $graphite->get_bulk_metrics();

  my $status = $graphite->send_bulk();

  my $status = $graphite->send_bulk_delegate();

  my $metrics = $graphite->get_metrics();

  my $avg_counters = $graphite->get_average_counters();

  my $invalid = $graphite->get_invalid_metrics();

  $graphite->clear_bulk();

  $graphite->incr_bulk($key, $value);
  $graphite->incr_bulk($key);

  $graphite->append_bulk($hash, $prefix);
  $graphite->append_bulk($hash);

  my $is_valid = $graphite->is_valid_key();

  my $counter = $graphite->get_invalid_key_counter();

  $graphite->check_and_bump_invalid_metric($key);

  my $is_blocked = $graphite->is_metric_blocked($key);

  $graphite->set_blocked_metrics_re($re);

  $graphite->DESTROY();

  # the following is actual only if C<use_global_storage> was set
  my %metrics      = %Graphite::Simple::bulk;
  my %avg_counters = %Graphite::Simple::avg_counters;

=head1 DESCRIPTION

  This package provides methods to collect metrics and send them to Graphite server over UDP socket.

=head2 $class->new(\%options)

It's a class constructor.
Takes a hash reference as argument.
The possible keys of this hash are described below.

=over

=item enabled

By default this option equals to 0.
The connection to Graphite host will be established if this value is true.

If value is 0, then it will be still possible to collect mertrics in internal or public structures.
But you won't allowed to send them to Graphite server via native C<send_bulk> method.
In this case you can use C<send_bulk_delegate> method to do this work by other code.

=item host

Sets the hostname or IPv4 address of Graphite server.
This option is mandatory if C<enabled> is true.

=item port

Sets the port number of Graphite server.
This option is mandatory if C<enabled> is true.

=item project

Sets a project's name (global prefix for all metrics).
This prefix will be applied to each metric before sending to server.

=item sender_name

Sets the method's name in format "package::method".

This method will be called from C<send_bulk_delegate> sub.
The hash reference with result metrics will be passed as arguments.

Be aware that the invocation of this method can lead to some performance penalties.

Optional.

=item store_invalid_metrics

Optional. By default takes false value.
Turns on the collecting of invalid metrics into C<invalid> hash.

=item block_metrics_re

The compiled regular expression.
If any metric matches, then it will be ignored and won't be stored in the resulted hash.

Optional.

=item use_global_storage

This flag is optional.
If flag is set then the package global hashes will be used to store collected data.

  my %metrics      = %Graphite::Simple::bulk;
  my %avg_counters = %Graphite::Simple::avg_counters;

In case of C<store_invalid_metrics> true value the following hash will be available too:

  my %invalid = %Graphite::Simple::invalid;

Otherwise internal hashes will be used.

=back

=head2 $self->connect()

Establishes the connection to Graphite server if C<enabled> was set as true.

=head2 $self->disconnect()

Closes the connection.

=head2 $self->send_bulk_delegate()

Calculates the result metrics and passes them to specified method in C<sender_name>.

Previously stored keys will be used as average counters while getting the result. Example:

  $graphite->incr_bulk("avg,key", 4);
  $graphite->incr_bulk("avg,key", 8);

Here "avg.key" counter will be equal to 2. And the result value for "avg.key" is 6: (4 + 8) / 2

Be aware that the invocation of this method can lead to some performance penalties.

=head2 $self->send_bulk()

Calculates the result metrics and send them to Graphite server via direct connection.

Previously stored keys will be used as average counters while getting the result. Example:

  $graphite->incr_bulk("avg,key", 4);
  $graphite->incr_bulk("avg,key", 8);

Here "avg.key" counter will be equal to 2. And result value for "avg.key" is 6: (4 + 8) / 2

=head2 $self->get_average_counters()

Returns the hash reference with counters of average metrics.
Average metric is a metric started with "avg." string.

=head2 $self->get_invalid_metrics()

Returns hsh with invalid metrics.
It doesn't contain any blocked metric by reqular expressions.

=head2 $self->get_metrics()

Returns the hash reference with result metrics.
Each metric started with "avg." string is divided by its counter from C<average_counter>.

=head2 $self->clear_bulk()

Clears all collected metrics;

=head2 $self->incr_bulk($key, $value = 1)

Increments metric C<$key> by value C<$value>.
If C<$value> is unspecified then 1 will be used.

=head2 $self->append_bulk($hash, $prefix = undef)

Increments metrics specified in C<$hash>.

The C<$hash> format:

$hash = {key1 => $value1, key2 => $value2, ...};

The second argument is optional and it specifies the common prefix.
If prefix doesn't contain a dot at the end, then it will be added automatically.

=head2 $self->is_valid_key($key)

Returns 1 if C<$key> is valid for usage as Graphite metric path.
Otherwise returns 0.

=head2 $self->get_invalid_key_counter()

Returns the amount of invalid metrics detected by C<is_valid_key> method.

=head2 $self->check_and_bump_invalid_metric($key)

If C<get_invalid_key_counter> returns a non-zero value, then this value will be written into passed C<$key>.
IF passed C<$key> is invalid, then invalid key counter will be bumped by 1.

=head2 $self->is_metric_blocked($key)

Returns 1 if C<$key> matches with regular expression set with C<set_blocked_metrics_re>
or C<block_metrics_re>.

Otherwise returns 0.

=head2 $self->set_blocked_metrics_re($re = undef)

Sets regular expression to detect blocked metrics.
Such metrics won't be added to result.

If C<$re> is omitted or undefined then no any detection for blocked metrics will be used.

=head2 DESTROY

Destructor. Destroys object.

=head1 AUTHOR

Chernenko Dmitiry cdn@cpan.org

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0).

=cut
