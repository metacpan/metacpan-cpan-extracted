package Geo::Demo::Zipskinny;

use strict;
use LWP::Simple qw();

our $VERSION = 0.01;

sub new {
  my ( $class, %arg ) = @_;
  return bless {}, $class;
}

sub get {
  my ( $self, $zip ) = @_;
  return undef unless $zip =~ m/^\d{5}$/;
  my $content = LWP::Simple::get(qq(http://www.zipskinny.com/index.php?zip=$zip));

  return $self->parse( $content );
}

sub parse {
  my ( $self, $content ) = @_;
  my %res = ();

  #yeah, it's crap, but it worked when i wrote it.  stop complaining.

  $content =~ m#"Demographic profile for ZIP Code \d{5} in (.+?), (\w{2})\."#;
  $res{'general'}{'city'} = $1;
  $res{'general'}{'state'} = $2;

  my ( $general ) = $content =~ m#General Information(.+?)</table>#s;
  ( $res{'general'}{'latitude'}   ) = $general =~ m#Latitude.+?>([\-\d\.]+)<#;
  ( $res{'general'}{'longitude'}  ) = $general =~ m#Longitude.+?>([\-\d\.]+)<#;
  ( $res{'general'}{'population'} ) = $general =~ m#Population.+?>(\d+)<#;
  ( $res{'general'}{'density'}    ) = $general =~ m#Density.+?>([\d\.]+)<#;
  ( $res{'general'}{'housing'}    ) = $general =~ m#Housing Units.+?>(\d+)<#;
  ( $res{'general'}{'land_area'}  ) = $general =~ m#Land Area.+?>([\d\.]+) sq\. mi\.<#;
  ( $res{'general'}{'water_area'} ) = $general =~ m#Water Area.+?>([\d\.]+) sq\. mi\.<#;

  my ( $social ) = $content =~ m#Social Indicators(.+?)</table>#s;
  ( $res{'educational'}{'0-8'}                   ) = $social =~ m#Less than 9th grade.+?>([\d\.]+)%#;
  ( $res{'educational'}{'9-12'}                  ) = $social =~ m#9th-12th grade.+?>([\d\.]+)%#;
  ( $res{'educational'}{'High school graduate'}  ) = $social =~ m#High school graduate.+?>([\d\.]+)%#;
  ( $res{'educational'}{'Some college'}          ) = $social =~ m#Some college.+?>([\d\.]+)%#;
  ( $res{'educational'}{'Associate degree'}      ) = $social =~ m#Associate.+?>([\d\.]+)%#;
  ( $res{'educational'}{'Bachelors degree'}      ) = $social =~ m#Bachelors.+?>([\d\.]+)%#;
  ( $res{'educational'}{'Graduate/Professional'} ) = $social =~ m#Graduate/Professional.+?>([\d\.]+)%#;

  ( $res{'marital'}{'Never married'}             ) = $social =~ m#Never married.+?>([\d\.]+)%#;
  ( $res{'marital'}{'Married'}                   ) = $social =~ m#Married.+?>([\d\.]+)%#;
  ( $res{'marital'}{'Separated'}                 ) = $social =~ m#Separated.+?>([\d\.]+)%#;
  ( $res{'marital'}{'Widowed'}                   ) = $social =~ m#Widowed.+?>([\d\.]+)%#;
  ( $res{'marital'}{'Divorced'}                  ) = $social =~ m#Divorced.+?>([\d\.]+)%#;

  ( $res{'stability'}{'Same home 5+ years'}      ) = $social =~ m#Same home.+?>([\d\.]+)%#;

  my ( $eco ) = $content =~ m#Economic Indicators(.+?)</table>#s;
  ( $res{'income'}{'000000-009999'}              ) = $eco =~ m#&lt;\$10,000.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'010000-014999'}              ) = $eco =~ m#\$10,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'015000-024999'}              ) = $eco =~ m#\$15,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'025000-034999'}              ) = $eco =~ m#\$25,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'035000-049999'}              ) = $eco =~ m#\$35,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'050000-074999'}              ) = $eco =~ m#\$50,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'075000-099999'}              ) = $eco =~ m#\$75,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'100000-149999'}              ) = $eco =~ m#\$100,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'150000-199999'}              ) = $eco =~ m#\$150,000-.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'200000+'}                    ) = $eco =~ m#\$200,000\+.+?>&nbsp;([\d\.]+)%#;

  ( $res{'occupation'}{'Professional'}           ) = $eco =~ m#Mgt\./Professional.+?>&nbsp;([\d\.]+)%#;
  ( $res{'occupation'}{'Service'}                ) = $eco =~ m#Service.+?>&nbsp;([\d\.]+)%#;
  ( $res{'occupation'}{'Sales/Office'}           ) = $eco =~ m#Sales/Office.+?>&nbsp;([\d\.]+)%#;
  ( $res{'occupation'}{'Agriculture'}            ) = $eco =~ m#Farm/Fishing.+?>&nbsp;([\d\.]+)%#;
  ( $res{'occupation'}{'Construction/Extraction'}    ) = $eco =~ m#Construction.+?>&nbsp;([\d\.]+)%#;
  ( $res{'occupation'}{'Production/Transportation'}  ) = $eco =~ m#Production.+?>&nbsp;([\d\.]+)%#;

  ( $res{'occupation'}{'unemployed'}             ) = $eco =~ m#Unemployed.+?>&nbsp;([\d\.]+)%#;
  ( $res{'income'}{'below poverty line'}         ) = $eco =~ m#Below Poverty Line.+?>&nbsp;([\d\.]+)%#;

  my ( $demo ) = $content =~ m#>Race<(.+?)</table>#s;
  ( $res{'race'}{'Hispanic'}                     ) = $demo =~ m#Hispanic/Latino.+?>([\d\.]+)%#;
  ( $res{'race'}{'White'}                        ) = $demo =~ m#White.+?>([\d\.]+)%#;
  ( $res{'race'}{'Black'}                        ) = $demo =~ m#Black.+?>([\d\.]+)%#;
  ( $res{'race'}{'Native American'}              ) = $demo =~ m#Native.+?>([\d\.]+)%#;
  ( $res{'race'}{'Asian'}                        ) = $demo =~ m#Asian.+?>([\d\.]+)%#;
  ( $res{'race'}{'Pacific Islander'}             ) = $demo =~ m#Islander.+?>([\d\.]+)%#;
  ( $res{'race'}{'Other'}                        ) = $demo =~ m#Other.+?>([\d\.]+)%#;
  ( $res{'race'}{'Multiracial'}                  ) = $demo =~ m#Multiracial.+?>([\d\.]+)%#;


  my ( $age ) = $content =~ m#>Age<(.+?)</table>#s;
  ( $res{'age'}{'male'}{'0-9'}  , $res{'age'}{'female'}{'0-9'}   ) = $age =~ m#>0-9 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'10-19'}, $res{'age'}{'female'}{'10-19'} ) = $age =~ m#>10-19 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'20-29'}, $res{'age'}{'female'}{'20-29'} ) = $age =~ m#>20-29 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'30-39'}, $res{'age'}{'female'}{'30-39'} ) = $age =~ m#>30-39 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'40-49'}, $res{'age'}{'female'}{'40-49'} ) = $age =~ m#>40-49 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'50-59'}, $res{'age'}{'female'}{'50-59'} ) = $age =~ m#>50-59 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'60-69'}, $res{'age'}{'female'}{'60-69'} ) = $age =~ m#>60-69 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'70-79'}, $res{'age'}{'female'}{'70-79'} ) = $age =~ m#>70-79 years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;
  ( $res{'age'}{'male'}{'80+'}  , $res{'age'}{'female'}{'80+'}   ) = $age =~ m#>80\+ years.+?%.+?>([\d\.]+)%.+?%.+?>([\d\.]+)%#;

  return \%res;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Demo::Zipskinny - Census 2000 geographic and demographic data by ZIP code, courtesy of ZIPskinny.com

=head1 SYNOPSIS

  use Geo::Demo::Zipskinny;
  my $zip = new Geo::Demo::Zipskinny();

  #get the stats page from zipskinny.com over the network
  my $stats = $zip->get('90232');
  #alternatively, read a local copy
  #my $stats = $zip->parse($html);

  #population of the zip code
  my $pop   = $stats->{'general'}{'population'};

  #fractions 0-1 inclusive
  my $asian = $stats->{'race'}{'Asian'};
  my $k250  = $stats->{'income'}{'200000+'};

  my $asian_count = $pop * $asian;
  my $k250_count  = $pop * $k250;

  use Data::Dumper;
  print Data::Dumper::Dumper( $stats );

=head1 DESCRIPTION

Use this for quick access to some ZIP code centric demographic data.
ZIPskinny.com claims to have built the site from the Census 2000 data
freely available from http://census.gov.

I chose to write this screen scraper after several unproductive hours
spent poring over the (copious and dry) census docs and unsuccessfully
trying to grok the SF3 files.

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
