package GPS::Garmin::Connect;

use warnings;
use strict;


use LWP::UserAgent;
use HTML::Form;
use JSON;
use Error;


=head1 NAME

GPS::Garmin::Connect - Allows simple fetching of 
activities from http://connect.garmin.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module is a simple helper to fetch and parse activities
from http://connect.garmin.com



    use GPS::Garmin::Connect;

    my $connect = GPS::Garmin::Connect->new();
    my $json = $connect->fetchdata( $username, $password );

    my $activities = $connect->parse( $json );

    foreach my $activity (@$activities) {
        print "My activity $activity->{activity} - HR: $activity->{heartrate}\n";
    }


=head1 FUNCTIONS

=head2 new

=cut

sub new {
  my $self = shift;
  return bless {
                _loginurl => 'http://connect.garmin.com/signin',
               }, $self;
}

=head2 fetchdata

    $connect->fetchdata( $username, $password );

Logins into connect.garmin.com and fetches all activities and returns 
a JSON string which can be parsed using L<parse>.

=cut

sub fetchdata {
  my ($pkg, $username, $password) = @_;
  my $loginurl = $pkg->{_loginurl};
  my $ua = LWP::UserAgent->new();
  $ua->cookie_jar( { } );
  push @{ $ua->requests_redirectable }, 'POST';



  # Fetch login form to get a session id ..
  my $loginformreq = HTTP::Request->new(GET => $loginurl);
  my $loginformres = $ua->request($loginformreq);

  throw Error::Simple('Error while requesting login form: ' . $loginformres->status_line)
    unless $loginformres->is_success;
  
  my $loginform = HTML::Form->parse($loginformres->content, $loginurl);
  $loginform->value( 'login:loginUsernameField' => $username );
  $loginform->value( 'login:password' => $password );
  
  # Send login request ..
  my $loginres = $ua->request($loginform->click);
  
  if ($loginres->is_success) {
    # we successfully logged in (probably)
  } else {
    throw Error::Simple("Error while trying to log in: ".$loginres->status_line);
  }

  # We can now retrieve our activity ...
  my $req = HTTP::Request->new(GET => 'http://connect.garmin.com/proxy/activity-search-service-1.0/json/activities?_dc=1220170621856&start=0&limit=50');

  my $res = $ua->request($req);

  if ($res->is_success) {
    return $res->content;
  } else {
    throw Error::Simple("error while requesting activities (".$res->status_line.")");
  }
}

=head2 parse

method responsible for parsing the json data and returning a simplified array ref of hash refs:

    $VAR1 = [
         {
            'begindate' => '2009-02-17',
            'distance' => 3156,
            'name' => 'Untitled',
            'heartrate' => 162,
            'duration' => 1980,
            'activity' => 'Untitled',
            'activityid' => '2194739',
            'id' => '2194739',
            'type' => 'Uncategorized',
            'begin' => 'Tue, Feb 17 \'09 08:27 AM'
          },
         {
            'begindate' => '2009-02-17',
            'distance' => 2200,
            'name' => 'Untitled',
            'heartrate' => 157,
            'duration' => 1500,
            'activity' => 'Untitled',
            'activityid' => '2194738',
            'id' => '2194738',
            'type' => 'Uncategorized',
            'begin' => 'Tue, Feb 17 \'09 08:02 AM'
          },


=cut

sub parse {
  my ($pkg, $content) = @_;
  my $json = JSON->new();

  my $results = $json->decode($content);


  my $activities = $results->{results}->{activities};


  my $simpleactivities = [];
  foreach my $activity (@$activities) {
    my $a = $activity->{activity};
    # convert it to something more "userfriendly"
    my $hr = undef;
    if ($a->{weightedMeanHeartRate}) {
      $hr = int($a->{weightedMeanHeartRate}->{value});
    }
    my $durstr = $a->{sumDuration}->{display};
    my ($hrs, $min, $sec) = split(/:/,$durstr);
    my $duration = (($hrs * 60) + $min) * 60 + $sec;
    my $ac = { 'id' => $a->{activityId},
               'activityid' => $a->{activityId},
               'activity' => $a->{activityName}->{value},
               'name' => $a->{activityName}->{value},
               'type' => $a->{activityType}->{display},
               'distance' => int($a->{sumDistance}->{value}*1000),#sprintf("%.2f",$a->{sumDistance}->{value}),
               'duration' => $duration,
               'begin' => $a->{beginTimestamp}->{display},
               'begindate' => $a->{beginTimestamp}->{value},
               'heartrate' => $hr,
             };
    
    push(@$simpleactivities, $ac);
  }
  return $simpleactivities;
}



=head1 AUTHOR

Herbert Poul, C<< <hpoul at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gps-garmin-connect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GPS-Garmin-Connect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GPS::Garmin::Connect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GPS-Garmin-Connect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GPS-Garmin-Connect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GPS-Garmin-Connect>

=item * Search CPAN

L<http://search.cpan.org/dist/GPS-Garmin-Connect>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Herbert Poul, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of GPS::Garmin::Connect
