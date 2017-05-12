# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp@psyphi.net
# Created: 2016-12-31
#
package Ham::NOAA::Sunspot;
use strict;
use warnings;
use LWP::UserAgent;

our $DEFAULT_URL = q[http://services.swpc.noaa.gov/text/predicted-sunspot-radio-flux.txt];
our $VERSION = q[0.0.2];

sub new {
  my ($class, $ref) = @_;
  if(!ref $ref) {
    $ref = {};
  }

  bless $ref, $class;
  return $ref;
}

sub url {
  my ($self, $url) = @_;
  if(defined $url) {
    $self->{url} = $url;
  }
  return $self->{url} || $DEFAULT_URL;
}

sub _data {
  my ($self) = @_;
  if($self->{_data}) {
    return $self->{_data};
  }

  my $ua = LWP::UserAgent->new();
  $ua->agent(qq[Ham::NOAA::Sunspot $VERSION]);
  $ua->env_proxy();

  my $res = $ua->get($self->url);
  if(!$res->is_success) {
    return;
  }

  my $content = $res->decoded_content;
  my $lines   = [split /[\r\n]+/smx, $content];
  my $data    = [];

  for my $line (@{$lines}) {
    if($line =~ m{^\s*[#:]}smx) {
      next;
    }

    my ($year, $month, $sunspot_predicted, $sunspot_high, $sunspot_low, $flux_predicted, $flux_high, $flux_low) = $line =~ m{(\S+)}smxg;
    push @{$data}, {
		    year    => 0+$year,
		    month   => 0+$month,
		    sunspot => {
				predicted => $sunspot_predicted,
				high      => $sunspot_high,
				low       => $sunspot_low,
			       },
		    flux    => {
				predicted => $flux_predicted,
				high      => $flux_high,
				low       => $flux_low,
			       },
		   };
  }

  $self->{_data} = $data;
  return $data;
}

sub _by_year_month {
  my $self = shift;
  if($self->{_year_month}) {
    return $self->{_year_month};
  }

  my $data = $self->_data;
  for my $i (@{$data}) {
    $self->{_year_month}->{$i->{year}}->{$i->{month}} = {
							 sunspot => $i->{sunspot},
							 flux    => $i->{flux},
							};
  }

  return $self->{_year_month};
}

sub sunspot_by_year_month {
  my ($self, $year, $month) = @_;

  return $self->_by_year_month->{0+$year}->{0+$month}->{sunspot};
}

sub flux_by_year_month {
  my ($self, $year, $month) = @_;

  return $self->_by_year_month->{0+$year}->{0+$month}->{flux};
}

1;

__END__

=head1 NAME

Ham::NOAA::Sunspot - process sunspot prediction data from NOAA FTP/Website

=head1 VERSION

$VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - constructor, takes a hashref of options

  my $oHNS = Ham::NOAA::Sunspot->new();

  my $oHNS = Ham::NOAA::Sunspot->new({
    url => 'http://services.swpc.noaa.gov/text/predicted-sunspot-radio-flux.txt',
  });

=head2 url - get/set URL to use for sunspot data

=head2 sunspot_by_year_month - fetch sunspot data for a given numeric year and month

  my $hrSunspotData = $oHNS->sunspot_by_year_month(2017, 1);

=head2 flux_by_year_month - fetch 10GHz flux data for a given numeric year and month

  my $hrFluxData = $oHNS->flux_by_year_month(2017, 1);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

 Honours http_proxy, https_proxy and no_proxy settings as per
 LWP::UserAgent

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item LWP::UserAgent

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 Roger Pettett

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
