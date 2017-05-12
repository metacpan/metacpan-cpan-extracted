package Math::Telephony::ErlangC;

use version; our $VERSION = qv('1.0.2');

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

use base 'Exporter';
our %EXPORT_TAGS = (
   'all' => [
      qw(
        wait_probability servers_waitprob traffic_waitprob
        maxtime_probability servers_maxtime traffic_maxtime
        service_time_maxtime service_time2_maxtime max_time_maxtime
        average_wait_time servers_waittime traffic_waittime
        service_time_waittime  service_time2_waittime
        )
   ]
);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT    = qw();

use Math::Telephony::ErlangB;

# Module implementation here
{
   my %validators = (
      traffic => sub { defined($_[0]) && $_[0] >= 0 },
      servers =>
        sub { defined($_[0]) && $_[0] >= 0 && $_[0] == int($_[0]) },
      probability => sub { defined($_[0]) && $_[0] >= 0 && $_[0] <= 1 },
      time => sub { defined($_[0]) && $_[0] >= 0 },
      precision => sub { !defined($_[0]) || ($_[0] > 0) },
   );

   sub _validate {
      while (@_) {
         my $type  = shift;
         my $value = shift;
         return undef unless $validators{$type}($value);
      }
      return 1;
   } ## end sub _validate
}

sub _cross {
   my ($asc, $desc, $v_begin, $v_end, $prec) = @_;
   return ($v_begin + $v_end) / 2 if ($v_end - $v_begin) < $prec;

   my $v;
   my $diff = $prec;
   while ($v_end - $v_begin >= $prec) {
      $v    = ($v_begin + $v_end) / 2;
      my $d = $desc->($v);
      my $a = $asc->($v);
      $diff = $desc->($v) - $asc->($v);
      if ($diff > 0) { $v_begin = $v }
      else { $v_end = $v }
   } ## end while ($v_end - $v_begin ...
   return ($v_begin + $v_end) / 2;
} ## end sub _cross

##########################################################################
sub wait_probability {
   my ($traffic, $servers) = @_;
   my $bprob =
     Math::Telephony::ErlangB::blocking_probability($traffic, $servers);
   return undef unless defined $bprob;
   return $bprob if $bprob == 0 || $bprob == 1;

   return $bprob / (1 - (1 - $bprob) * $traffic / $servers);
} ## end sub wait_probability

sub servers_waitprob {
   my ($traffic, $wait_probability) = @_;
   return undef
     unless _validate(
      traffic     => $traffic,
      probability => $wait_probability
     );
   return 0     unless $traffic > 0;
   return undef unless $wait_probability > 0;
   return 0     unless $wait_probability < 1;

   Math::Telephony::ErlangB::_generic_servers(
      sub {
         my $v = wait_probability($traffic, $_[0]);
         return defined $v && $v > $wait_probability;
      }
   );
} ## end sub servers_waitprob

sub traffic_waitprob {
   my ($servers, $wait_probability, $prec) = @_;
   return undef
     unless _validate(
      servers     => $servers,
      probability => $wait_probability,
      precision   => $prec,
     );
   return 0     unless $servers > 0;
   return 0     unless $wait_probability > 0;
   return undef unless $wait_probability < 1;

   $prec = $Math::Telephony::ErlangB::default_precision
     unless defined $prec;

   Math::Telephony::ErlangB::_generic_traffic(
      sub {
         my $v = wait_probability($_[0], $servers);
         return defined $v && $v < $wait_probability;
      },
      $prec,
      $servers
   );
} ## end sub traffic_waitprob

##########################################################################
sub maxtime_probability {
   my ($traffic, $servers, $mst, $maxtime) = @_;
   return undef
     unless _validate(
      traffic => $traffic,
      servers => $servers,
      time    => $mst,
      time    => $maxtime,
     );
   return 1     unless $traffic;
   return 0     unless $servers;
   return 1     unless $mst;
   return 0     unless $maxtime;
   return undef unless $servers > $traffic;

   my $wprob = wait_probability($traffic, $servers);
   return undef unless defined $wprob;

   return 1 - $wprob * exp(-($servers - $traffic) * $maxtime / $mst);
} ## end sub maxtime_probability

sub servers_maxtime {
   my ($traffic, $maxtime_probability, $mst, $maxtime) = @_;
   return undef
     unless _validate(
      traffic     => $traffic,
      probability => $maxtime_probability,
      time        => $mst,
      time        => $maxtime,
     );
   return 0     unless $traffic > 0;
   return 1     unless $mst > 0;
   return undef unless $maxtime_probability > 0;
   return undef unless $maxtime > 0;

   Math::Telephony::ErlangB::_generic_servers(
      sub {
         my $v = maxtime_probability($traffic, $_[0], $mst, $maxtime);
         return 1 unless defined $v;
         return $v < $maxtime_probability;
      }
   );
} ## end sub servers_maxtime

sub traffic_maxtime {
   my ($servers, $maxtime_probability, $mst, $maxtime, $prec) = @_;
   return undef
     unless _validate(
      servers     => $servers,
      probability => $maxtime_probability,
      time        => $mst,
      time        => $maxtime,
      precision   => $prec,
     );
   return 0     unless $servers > 0;
   return 0     unless $maxtime_probability > 0;
   return undef unless $mst > 0;
   return undef unless $maxtime > 0;

   $prec = $Math::Telephony::ErlangB::default_precision
     unless defined $prec;

   Math::Telephony::ErlangB::_generic_traffic(
      sub {
         my $v = maxtime_probability($_[0], $servers, $mst, $maxtime);
         return defined $v && $v > $maxtime_probability;
      },
      $prec,
      $servers
   );
} ## end sub traffic_maxtime

sub service_time_maxtime {
   my ($traffic, $servers, $mprob, $maxtime) = @_;
   return undef
     unless _validate(
      traffic     => $traffic,
      servers     => $servers,
      probability => $mprob,
      time        => $maxtime,
     );
   return 0     unless $traffic > 0;
   return undef unless $servers > 0;
   return 0     unless $mprob > 0;
   return undef unless $mprob < 1;
   return 0     unless $maxtime > 0;
   return undef unless $servers > $traffic;

   # Input already _validated, use private "fast" function
   my $wprob = wait_probability($traffic, $servers);

   return -($servers - $traffic) * $maxtime / log((1 - $mprob) / $wprob);
} ## end sub service_time_maxtime

sub service_time2_maxtime {
   my ($frequency, $servers, $mprob, $maxtime, $prec) = @_;
   return undef
     unless _validate(
      traffic     => $frequency,    # Validate like a traffic
      servers     => $servers,
      probability => $mprob,
      time        => $maxtime,
     );
   return 0     unless $frequency > 0;
   return undef unless $servers > 0;
   return 0     unless $mprob > 0;
   return undef unless $mprob < 1;
   return 0     unless $maxtime > 0;

   $prec = $Math::Telephony::ErlangB::default_precision
     unless defined $prec;

   my $theLog   = log(1 - $mprob);
   my $lambdaTm = $frequency * $maxtime;
   my $traffic  = _cross(
      sub { log(wait_probability($_[0], $servers)) },
      sub { $theLog + $lambdaTm * ($servers - $_[0]) / $_[0] },
      $servers * $lambdaTm / ($lambdaTm - $theLog),
      $servers,
      $prec * $frequency # Adjusted precision for traffic domain
   );
   return $traffic / $frequency;
} ## end sub service_time2_maxtime

sub max_time_maxtime {
   my ($traffic, $servers, $mprob, $mst) = @_;
   return undef
     unless _validate(
      traffic     => $traffic,
      servers     => $servers,
      probability => $mprob,
      time        => $mst,
     );
   return 0     unless $traffic > 0;
   return undef unless $servers > 0;
   return 0     unless $mst;
   return 0     unless $mprob > 0;
   return undef unless $mprob < 1;
   return undef unless $servers > $traffic;

   my $wprob = wait_probability($traffic, $servers);

   return -$mst / (log((1 - $mprob) / $wprob) * ($servers - $traffic));
} ## end sub max_time_maxtime

##########################################################################
sub average_wait_time {
   my ($traffic, $servers, $mst) = @_;
   return undef
     unless _validate(
      traffic => $traffic,
      servers => $servers,
      time    => $mst,
     );
   return 0     unless $traffic > 0;
   return undef unless $servers > 0;
   return 0     unless $mst > 0;
   return undef unless ($servers > $traffic);

   # Use private calculation function, input already _validated
   my $wprob = wait_probability($traffic, $servers);

   return $wprob * $mst / ($servers - $traffic);
} ## end sub average_wait_time

sub servers_waittime {
   my ($traffic, $average_wait_time, $mst) = @_;

   return undef
     unless _validate(
      traffic => $traffic,
      time    => $average_wait_time,
      time    => $mst,
     );
   return 0     unless $traffic > 0;
   return 1     unless $mst > 0;
   return undef unless $average_wait_time > 0;

   Math::Telephony::ErlangB::_generic_servers(
      sub {
         my $v = average_wait_time($traffic, $_[0], $mst);
         return 1 unless defined $v;
         return $v > $average_wait_time;
      }
   );
} ## end sub servers_waittime

sub traffic_waittime {
   my ($servers, $average_wait_time, $mst, $prec) = @_;
   return undef
     unless _validate(
      servers   => $servers,
      time      => $average_wait_time,
      time      => $mst,
      precision => $prec,
     );
   return 0     unless $servers > 0;
   return undef unless $average_wait_time > 0;
   return undef unless $mst > 0;

   $prec = $Math::Telephony::ErlangB::default_precision
     unless defined $prec;

   Math::Telephony::ErlangB::_generic_traffic(
      sub {
         my $v = average_wait_time($_[0], $servers, $mst);
         return defined $v && $v < $average_wait_time;
      },
      $prec,
      $servers
   );
} ## end sub traffic_waittime

sub service_time_waittime {
   my ($traffic, $servers, $awt) = @_;
   return undef
     unless _validate(
      traffic => $traffic,
      servers => $servers,
      time    => $awt,
     );
   return 0     unless $traffic > 0;
   return undef unless $servers > 0;
   return 0     unless $awt > 0;
   return undef unless ($servers > $traffic);

   my $bprob = wait_probability($traffic, $servers);

   return $awt * ($servers - $traffic) / $bprob;
} ## end sub service_time_waittime

sub service_time2_waittime {
   my ($frequency, $servers, $awt, $prec) = @_;
   return undef
     unless _validate(
      traffic   => $frequency,    # Validate exactly as a traffic
      servers   => $servers,
      time      => $awt,
      precision => $prec,
     );
   return undef unless $frequency > 0;    # No calls...
   return undef unless $servers > 0;
   return 0     unless $awt > 0;

   $prec = $Math::Telephony::ErlangB::default_precision
     unless defined $prec;

   my $lambdaTa = $frequency * $awt;
   my $traffic  = _cross(
      sub { wait_probability($_[0], $servers) },    # Ascending
      sub { $lambdaTa * ($servers / $_[0] - 1) },   # Descending
      $servers * $lambdaTa / (1 + $lambdaTa), $servers,
      $prec * $frequency
   );
   return $traffic / $frequency;
} ## end sub service_time2_waittime

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

Math::Telephony::ErlangC - Erlang C calculations in Perl

=head1 VERSION

Please check version directly inside the module:

 perl -MMath::Telephony::ErlangC \
   -le 'print $Math::Telephony::ErlangC::VERSION'


=head1 SYNOPSIS

  use Math::Telephony::ErlangC;

  # Evaluate probability that a service request will have to wait
  $wprob = wait_probability($traffic, $servers);

  # Probability that the wait time will be less than a fixed maximum
  # $mst is the mean service time
  $mwprob = maxtime_probability($traffic, $servers, $mst, $maxtime);

  # Average time waiting in queue
  # $mst is the mean service time
  $awtime = average_wait_time($traffic, $servers, $mst);

=head1 DESCRIPTION

This module contains various functions to deal with Erlang C calculations.

The Erlang C model allows dimensioning the number of servers in a
M/M/S/inf/inf model (Kendall notation):

=over

=item *

The input process is Markovian (Poisson in this case)

=item *

The serving process is Markovian (ditto)

=item *

There are S servers

=item *

The wait line is infinite (pure wait, no loss, no renounce)

=item *

The input population is infinite

=back



=head2 CONCEPTS

Some concepts are common to the the following functions:

=over

=item *

B<traffic> is the offered traffic expressed in Erlang. When an input
parameter, this value must be defined and greater or equal to 0. As
per definition, this value is given by the product of the service
request arrival and the average service time (see below for this).

=item *

B<servers> is the number of servers in the queue. When an input parameter,
this must be a defined value, greater or equal to 0.

=item *

B<wait probability> is the probability that a given service request will
be put inside the wait queue, which happens when all servers are busy.

=item *

B<(average) service time> is the (average) time that each server needs to
complete a service request; it's referred to as $mst most of the time
below.

=back



=head1 INTERFACE

=head2 EXPORT

None by default. Following functions can be imported at once via the
":all" keyword.

=head2 FUNCTIONS FOR WAIT PROBABILITY

=over

=item B<$wprob = wait_probability($traffic, $servers);>

Evaluate the probability that a call will have to wait in the queue
because all servers are busy.



=item B<$servers = servers_waitprob($traffic, $wait_probability)>

Evaluate the needed number of servers to handle $traffic Erlangs with
a wait probability not greater than $wait_probability.



=item B<$traffic = traffic_waitprob($servers, $wait_probability, $prec);>

Evaluate the maximum traffic that can be handled with $servers without
having a wait probability for any request that is beyond the given
value. The calculation is performed until the iteration process shows
variations below $prec, which is optional and defaults to
$Math::Telephony::ErlangB::default_precision.

=back



=head2 FUNCTIONS FOR MAXIMUM WAIT TIME PROBABILITY

=over

=item B<$mwprob = maxtime_probability($traffic, $servers, $mst, $maxtime);>

Evaluate the probability that any given service request will be handled
within the given maximum time.



=item B<$servers = servers_maxtime($traffic, $maxtime_probability, $mst, $maxtime);>

Evaluate the needed number of servers given the $traffic in erlang,
$maxtime_probability, i.e. the probability that any given request
will be served in no more than $maxtime seconds, and $mst, which represents
the mean service time for any given request.



=item B<$traffic = traffic_maxtime($servers, $maxtime_probability, $mst, $maxtime, $prec);>

Evaluate the maximum traffic that can be handled with $servers, with
$maxtime_probability that the any given request will be handled within
$maxtime. Parameter $mst represents the average time needed to serve
a request.

You can optionally specify a $prec precision for calculations, otherwise
the precision will default to $Math::Telephony::ErlangB::precision.



=item B<$mst = service_time_maxtime($traffic, $servers, $maxt_prob, $maxtime);>

Evaluate the mean service time required when other parameters are fixed.



=item B<$mst = service_time2_maxtime($frequency, $servers, $maxt_prob, $maxtime);>

Evaluate the mean service time required when other parameters are fixed.



=item B<my $maxtime = max_time_maxtime($traffic, $servers, $maxt_prob, $mst);>

Evaluate the maximum time required to process a request with a probability
of $maxt_prob.

=back



=head2 FUNCTIONS FOR AVERAGE WAIT TIME

=over

=item B<$awtime = average_wait_time($traffic, $servers, $mst);>

Evaluate the average waiting time, i.e. average time spent inside the
queue by the generic request.



=item B<$servers = servers_waittime($traffic, $average_wait_time, $mst);>

Evaluate the needed number of servers to serve the given $traffic
with an average wait time in queue not exceeding $average_wait_time
for each request. $mst is the mean service time.



=item B<$traffic = traffic_waittime($servers, $average_wait_time, $mst, $prec);>

Evaluate the maximum traffic that can be handled with $servers,
where the average wait time does not exceed $average_wait_time. $mst
is the mean service time.

You can optionally specify a $prec precision for calculations, otherwise
the precision will default to $Math::Telephony::ErlangB::precision.



=item B<$mst = service_time_waittime($traffic, $servers, $awt);>

Evaluate the mean service time for $servers being offered $traffic,
assuming that the average wait time in queue is $awt.



=item B<$mst = service_time2_waittime($frequency, $servers, $awt);>

Evaluate the mean service time for $servers loaded with requests wich
occur with $frequency, assuming that the average wait time in queue is $awt.

=back



=head1 DIAGNOSTICS

At the moment, the various functions return undef when invoked with
invalid parameters. In the future there could be a switch to a more
exception-oriented interface.


=head1 CONFIGURATION AND ENVIRONMENT

Math::Telephony::ErlangC requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module depends on the following non-standard modules:

=over

=item -

version

=item -

Math::Telephony::ErlangB

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/

The C<servers()> aggregated function isn't implemented yet.

=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut
