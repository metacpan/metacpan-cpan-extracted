package Geo::GoogleEarth::Document::TimeSpan;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::TimeSpan - Geo::GoogleEarth::Document::TimeSpan

=head1 SYNOPSIS

  use Geo::GoogleEarth::Document;
  my $document=Geo::GoogleEarth::Document->new();
  my $placemark = $document->placemark();
  $placemark->TimeSpan( begin => timestamp, end => timestamp);

=head1 DESCRIPTION

Geo::GoogleEarth::Document::TimeSpan is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

  my $TimeSpan = $placemark->TimeSpan( begin => timestamp , end => timestamp );

=head1 CONSTRUCTOR

=head2 new

  my $TimeSpan = $placemark->TimeSpan( begin => timestamp , end => timestamp );

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$TimeSpan->type;

=cut

sub type {
  my $self=shift();
  return "TimeSpan";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

my $structure = $TimeSpan->structure;
<TimeSpan id="ID">
  <begin>...</begin>     <!-- kml:dateTime -->
	 <end>...</end>         <!-- kml:dateTime -->
	 </TimeSpan>

Note that KML timestamp format is YYYY-MM-DDTHH24:MM:SSZ.  For example, 
2009-01-17T19:13:24Z.  "T" is a separator, and "Z" indicates the timezone, in this case, GMT.

=cut

sub structure {
	my $self = shift();
	my $structure = { id=>$self->id };
	my %skip=map {$_=>1} (qw{id});

	foreach my $key (keys %$self) {
		next if exists $skip{$key};
		$structure->{$key} = {content=>$self->function($key)};	 
	}
	return $structure;
}

=head2 id

=cut

sub id {
  my $self=shift();
  $self->{'id'}=shift() if (@_);
  return $self->{'id'};
}

=head1 BUGS

=head1 SUPPORT

	Contact the author.

=head1 AUTHOR

	David Hillman
	CPAN: DAHILLMA

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Document> creates a GoogleEarth KML Document.

=cut

1;
