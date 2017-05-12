package Math::Telephony::ErlangB;

use version; our $VERSION = qv('1.0.2');

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

use base 'Exporter';
our %EXPORT_TAGS =
  ('all' => [qw( blocking_probability gos servers traffic )]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT    = qw();

# Module implementation here

# Workhorse functions, no check on input value is done!
sub _blocking_probability {
   my ($traffic, $servers) = @_;
   my $gos = 1;
   for my $m (1 .. $servers) {
      my $tmp = $gos * $traffic;
      $gos = $tmp / ($m + $tmp);
   }
   return $gos;
} ## end sub _blocking_probability

sub _generic_servers {
   my $cost = shift;

   # Exponential "backoff"
   my $servers = 1;
   $servers *= 2 while ($cost->($servers) > 0);
   return $servers if ($servers <= 2);

   # Binary search
   my ($minservers, $maxservers) = ($servers / 2, $servers);
   while ($maxservers - $minservers > 1) {
      $servers = int(($maxservers + $minservers) / 2);
      if ($cost->($servers) > 0) {
         $minservers = $servers;
      }
      else {
         $maxservers = $servers;
      }
   } ## end while ($maxservers - $minservers...
   return $maxservers;
} ## end sub _generic_servers

sub _generic_traffic {
   my ($cond, $prec, $hint) = @_;

   # Establish some upper limit
   my ($inftraffic, $suptraffic) = (0, $hint || 1);
   while ($cond->($suptraffic)) {
      $inftraffic = $suptraffic;
      $suptraffic *= 2;
   }

   # Binary search
   while (($suptraffic - $inftraffic) / $suptraffic > $prec) {
      my $traffic = ($suptraffic + $inftraffic) / 2;
      if ($cond->($traffic)) {
         $inftraffic = $traffic;
      }
      else {
         $suptraffic = $traffic;
      }
   } ## end while (($suptraffic - $inftraffic...
   return $inftraffic;
} ## end sub _generic_traffic

our $default_precision;

BEGIN {    # Ok, a little overkill to use a BEGIN block...
   $default_precision = 0.001;
}

sub blocking_probability {
   my ($traffic, $servers) = @_;

   return undef
     unless defined($traffic)
     && ($traffic >= 0)
     && defined($servers)
     && ($servers >= 0)
     && (int($servers) == $servers);
   return 0 unless $traffic > 0;
   return 1 unless $servers > 0;

   return _blocking_probability($traffic, $servers);
} ## end sub blocking_probability

sub gos { return blocking_probability(@_) }

sub servers {
   my ($traffic, $gos) = @_;

   return undef
     unless defined($traffic)
     && ($traffic >= 0)
     && defined($gos)
     && ($gos >= 0)
     && ($gos <= 1);
   return 0 unless ($traffic > 0 && $gos < 1);
   return undef unless ($gos > 0);

   return _generic_servers(
      sub { _blocking_probability($traffic, $_[0]) > $gos });
} ## end sub servers

sub traffic {
   my ($servers, $gos, $prec) = @_;

   return undef
     unless defined($servers)
     && ($servers >= 0)
     && (int($servers) == $servers)
     && defined($gos)
     && ($gos >= 0)
     && ($gos <= 1);
   return 0 unless ($servers > 0 && $gos > 0);
   return undef unless ($gos < 1);

   $prec = $default_precision unless defined $prec;
   return undef unless ($prec > 0);

   return _generic_traffic(
      sub { _blocking_probability($_[0], $servers) < $gos },
      $prec, $servers);
} ## end sub traffic

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

Math::Telephony::ErlangB - Erlang B calculations from Perl


=head1 VERSION

I'm too lazy to track the VERSION in two places (the module and the doc).
You can get the version with:

 perl -MMath::Telephony::ErlangB \
   -le 'print $Math::Telephony::ErlangB::VERSION'


=head1 SYNOPSIS

  use Math::Telephony::ErlangB qw( :all );

  # Evaluate blocking probability
  $bprob = blocking_probability($traffic, $servers);
  $gos = gos($traffic, $servers); # Same result as above

  # Dimension minimum number of needed servers
  $servers = servers($traffic, $gos);

  # Calculate maximum serveable traffic
  $traffic = traffic($servers, $gos); # Default precision 0.001
  $traffic = traffic($servers, $gos, 1e-10);

  
=head1 DESCRIPTION

This module contains various functions to deal with Erlang B calculations.

The Erlang B model allows dimensioning the number of servers in a
M/M/S/0/inf model (Kendall notation):

=over

=item *

The input process is Markovian (Poisson in this case)

=item *

The serving process is Markovian (ditto)

=item *

There are S servers

=item *

There's no wait line (pure loss)

=item *

The input population is infinite

=back

=head1 INTERFACE 

=head2 EXPORT

None by default. Following functions can be imported at once via the
":all" keyword.

=head2 VARIABLES

These variables control different aspects of this module, such as
default values.

=over

=item B<$default_precision = 0.001;>

This variable is the default precision used when evaluating the maximum
traffic sustainable using the B<traffic()> function below.

=back


=head2 FUNCTIONS

The following functions are available for exporting. Three "concepts"
are common to them all:

=over

=item *

B<traffic> is the offered traffic expressed in Erlang. When an input
parameter, this value must be defined and greater or equal to 0.

=item *

B<servers> is the number of servers in the queue. When an input parameter,
this must be a defined value, greater or equal to 0.

=item *

B<blocking probability> is the probability that a given service request
will be blocked due to congestion.

=item *

B<gos> is the I<grade of service>, that corresponds to the blocking
probability for Erlang B calculation. The concept of Grade of Service is
a little different in perspective: in general, it should give us an
estimate of how the service is good (or bad). In the Erlang B model
this role is played by the blocking probability, thus the B<gos> is
equal to it.

=back


=over

=item B<$bprob = blocking_probability($traffic, $servers);>

Evaluate the blocking probability from given traffic and numer of
servers.

=item B<$gos = gos($traffic, $servers);>

Evaluate the grade of service from given traffic and number of servers.
For Erlang B, the GoS figure corresponds to the blocking probability.

=item B<$servers = servers($traffic, $bprob);>

Calculate minimum number of servers needed to serve the given traffic
with a blocking probability not greater than that given.

=item B<$traffic = traffic($servers, $bprob);>

=item B<$traffic = traffic($servers, $bprob, $prec);>

Calculate the maximum offered traffic that can be served by the given
number of serves with a blocking probability not greater than that given.

The prec parameter allows to set the precision in this traffic calculation.
If undef it defaults to $default_precision in this package.

=back


=head1 DIAGNOSTICS

All public functions return undef upon invalid input, so there should 
be nothing to complain with. In a future version we could stick to a more
exception-oriented interface.

=head1 CONFIGURATION AND ENVIRONMENT

Math::Telephony::ErlangB requires no configuration files or environment variables.


=head1 DEPENDENCIES

Among the non-standard modules, only B<version>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


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
