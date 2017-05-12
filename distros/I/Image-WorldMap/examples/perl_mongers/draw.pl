#!/usr/bin/perl

use strict;
use Getopt::Long;
use LWP::Simple;
use Image::WorldMap;
use XML::Simple;

$| = 1;

my $opt_huge;
my $opt_help;

if (not GetOptions("huge!" => \$opt_huge, "help" => \$opt_help)
    or $opt_help) {
  exec "perldoc $0";
}

my ($filein, $fileout, $label);

if ($opt_huge) {
  $filein = '../earth-huge.ppm';

  $fileout = 'mongers.png';
  $label = "maian/6";

} else {
  $filein = '../earth-small.png';
  $fileout = 'mongers-small.png';
}

mirror("http://www.pm.org/groups/perl_mongers.xml", "perl_mongers.xml") unless -f "perl_mongers.xml";

my $map = Image::WorldMap->new($filein, $label);

my $xml = XMLin('./perl_mongers.xml', cache => 'storable');
$xml = $xml->{group};

# Array of the group names for which we don't know the location
my @missing;

# Array containing all the group names
my @groups;

foreach my $name (keys %$xml) {
  my $group = $xml->{$name};
  my $status = $group->{status} || 'not-specified-in-xml-file';
  next unless $status eq 'active' || $status eq 'sleeping';

#  next unless $group->{location}->{continent} eq 'Europe'; # SKIP

  my $longitude = $group->{location}->{longitude};
  my  $latitude = $group->{location}->{latitude};

  push @groups, $name;

  if (ref($longitude) =~ /HASH/) {
    push @missing, $name;
    next;
  }

#  $name =~ s|&amp;|&|g;
#  $name =~ s|&(.)acute;|$1|g;
  $name =~ s|&(.).+?;|$1|g;   # Get rid of HTML accents
  $map->add($longitude, $latitude, $name);
}

$map->draw($fileout);

print "Missing location information for " . scalar(@missing) . " of " . 
  scalar(@groups) . " groups:\n";
print join ', ', sort @missing;
print ".\n";

__END__
=head1 NAME

draw.pl - draw the master copies of the Perl Monger World Maps

=head1 SYNOPSIS

draw.pl [-huge]

=head1 DESCRIPTION

This uses the two large earth.png, earth-small.png, and the Perl Monger
Group XML file, perl_mongers.xml. It takes the longitude and latitude 
location information contained in the XML file and produces one of
two image files: mongers.png and mongers-small.png.

It also outputs a list of all the groups which do not current have
location information.

=head1 AUTHOR

Leon Brocard, leon@astray.com

=cut

__END__
Example data structure for a group:

$VAR1 = {
          'location' => {
                          'state' => {},
                          'country' => 'Ireland',
                          'latitude' => '52.664',
                          'region' => {},
                          'city' => 'Limerick',
                          'longitude' => '-8.623',
                          'continent' => 'Europe'
                        },
          'web' => {},
          'tsar' => {
                      'email' => {
                                   'content' => 'foranp@tinet.ie',
                                   'type' => 'personal'
                                 },
                      'name' => 'Paul Foran'
                    },
          'date' => {
                      'content' => '19990214',
                      'type' => 'inception'
                    },
          'id' => '134',
          'mailing-list' => {
                              'subscribe' => 'subscribe limerick-pm-list email_address',
                              'unsubscribe' => 'unsubscribe limerick-pm-list email_address',
                              'email' => [
                                           {
                                             'content' => 'limerick-pm-list@pm.org',
                                             'type' => 'list'
                                           },
                                           {
                                             'content' => 'majordomo@pm.org',
                                             'type' => 'list_admin'
                                           }
                                         ],
                              'name' => 'General Limerick.pm discussion'
                            },
          'email' => {
                       'type' => 'group'
                     }
        };
