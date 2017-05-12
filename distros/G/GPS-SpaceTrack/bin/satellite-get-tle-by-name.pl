#!/usr/bin/perl -w

use strict;
use Astro::SpaceTrack;

sub usage {
  die("Syntax: $0 login password [data_set_name]\n");
}

my $account=shift() || usage();
my $passwd=shift() || usage();
my $name=shift()||'navstar';

my $st = Astro::SpaceTrack->new(username=>$account,
                                password=>$passwd,
                                with_name=>1) or die();
my $rslt = $st->search_name($name);
print $rslt->is_success ? $rslt->content : $rslt->status_line;

__END__

=head1 NAME

satellite-get-tle-by-name.pl - Application to retrive TLE data with Astro::SpaceTrack package

=head1 SAMPLE OUTPUT

  GPS BIIA-11 (PRN 24)    
  1 21552U 91047A   07024.74935505  .00000033  00000-0  10000-3 0  3407
  2 21552  54.8480 256.1991 0088500 315.8552  43.5043  2.00358418113969
  GPS BIIA-12 (PRN 25)    
  1 21890U 92009A   07024.17110927 -.00000036  00000-0  10000-3 0  3146
  2 21890  54.8611  67.8717 0127244 284.0658  74.5735  2.00378414109321
  GPS BIIA-14 (PRN 26)    
  1 22014U 92039A   07024.89979786 -.00000066  00000-0  10000-3 0  3113
  2 22014  56.8303  15.0910 0175314  46.9379 314.5258  2.00571394100102

=head2 SYNTAX

./satellite-get-tle-by-name.pl login password [data_set_name]

=head2 EXAMPLES

  ./satellite-get-tle.pl login password navstar
  ./satellite-get-tle.pl login password inmarsat
  ./satellite-get-tle.pl login password artemis
  ./satellite-get-tle.pl login password galaxy
  ./satellite-get-tle.pl login password mtsat

=head2 ACCOUNT

Obtain and account at http://www.space-track.org/

=head2 ALTERNATIVE

http://celestrak.com/NORAD/elements/gps-ops.txt

=cut
