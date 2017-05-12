package Geo::WebService::OpenCellID;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Base};
use Geo::WebService::OpenCellID::cell;
use Geo::WebService::OpenCellID::measure;
use LWP::Simple qw{};
use XML::Simple qw{};
use URI qw{};

our $VERSION = '0.05';

=head1 NAME

Geo::WebService::OpenCellID - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use Geo::WebService::OpenCellID;
  my $gwo=Geo::WebService::OpenCellID->new(key=>$apikey);
  my $point=$gwo->cell->get(mcc=>$country,
                            mnc=>$network,
                            lac=>$locale,
                            cellid=>$cellid);
  printf "Lat:%s, Lon:%s\n", $point->latlon;

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $obj = Geo::WebService::OpenCellID->new(
                                             key=>"myapikey",                   #default
                                             url=>"http://www.opencellid.org/", #default
                                            );

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
  $self->url("http://www.opencellid.org/") unless $self->url; 
  $self->key("myapikey")                   unless $self->key;
}

=head1 METHODS

=head2 key

Sets and returns the API key.

=cut

sub key {
  my $self=shift;
  $self->{"key"}=shift if @_;
  return $self->{"key"};
}

=head2 url

Sets and returns the URL.  Defaults to http://www.opencellid.org/

=cut

sub url {
  my $self=shift;
  $self->{"url"}=shift if @_;
  return $self->{"url"};
}

=head2 cell

Returns a L<Geo::WebService::OpenCellID::cell> object.

=cut

sub cell {
  my $self=shift;
  unless (defined($self->{"cell"})) {
    $self->{"cell"}=Geo::WebService::OpenCellID::cell->new(parent=>$self);
  }
  return $self->{"cell"};
}

=head2 measure

Returns a L<Geo::WebService::OpenCellID::measure> object.

=cut

sub measure {
  my $self=shift;
  unless (defined($self->{"measure"})) {
    $self->{"measure"}=Geo::WebService::OpenCellID::measure->new(parent=>$self);
  }
  return $self->{"measure"};
}

=head1 METHODS (INTERNAL)

=head2 call

Calls the web service.

  my $data=$gwo->call($method_path, $response_class, %parameters);

=cut

sub call {
  my $self=shift;
  my $path=shift or die;
  my $class=shift or die;
  my $uri=URI->new($self->url);
  $uri->path($path);
  $uri->query_form(key=>$self->key, @_);
  my $content=LWP::Simple::get($uri->as_string);
  if ($content) {
    return $class->new(
                       content => $content,
                       url     => $uri,
                       data    => $self->data_xml($content),
                      );
  } else {
    return undef;
  }
}

=head2 data_xml

Returns a data structure given xml

  my $ref =$gwo->data_xml();

=cut

sub data_xml {
  my $self=shift;
  my $xml=shift;
  return XML::Simple->new(ForceArray=>1)->XMLin($xml);
}

=head1 BUGS

Submit to RT and email the Author

=head1 SUPPORT

Try the Author or Try 8motions.com

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<URI>, L<LWP::Simple>, L<XML::Simple>

=cut

1;
