package Github::Score;
#ABSTRACT: Pull author contribution counts for github repos

use strict;
use warnings;
use LWP;
use JSON;
use HTTP::Request;
use URI;

use Data::Dumper;

use Moose; # automatically turns on strict and warnings

  has 'user' => (is => 'rw', );
  has 'repo' => (is => 'rw', );
  has 'timeout' => (is => 'rw', );
  has 'api_version' => (is => 'rw', );

  sub clear {
      my $self = shift;
      $self->$_(undef) for qw(ua user json uri timeout);
  }


 our $VERSION = '0.001';
 $VERSION = eval $VERSION;
 
 sub new {
     my $self = shift;
     my @args = @_;
 
     unshift @args, 'url' if @args % 2 && !ref( $args[0] );
 
     my %args = ref( $args[0] ) ? %{ $args[0] } : @args;
     if ( exists $args{url} ) {
         ( $args{user}, $args{repo} ) = ( split /\//, delete $args{url} );
     }
 
     my $timeout = $args{timeout} || 10;
 
     bless { 
     	user => $args{user}, 
     	repo => $args{repo}, 
     	timeout => $timeout,
     	api_version => ($args{api_version} || 'v2'), 
     	}, $self;
 }
 
 sub ua { 
 		LWP::UserAgent->new( 
 			timeout => $_[0]->timeout, 
 			agent => join ' ', ( __PACKAGE__, $VERSION ) 
 			); 
}


 sub uri { 
 	URI->new( sprintf( 'http://github.com/api/%s/json/repos/show/%s/%s/contributors', 
 	$_[0]->api_version,$_[0]->user, $_[0]->repo ) 
 	); 
 	}
 sub json { JSON->new->allow_nonref }
 
 sub scores {
     my $self = shift;
 
     my $response = $self->ua->request( HTTP::Request->new( GET => $self->uri->canonical ) );
     return {} unless $response->is_success;
 
     my %scores;
     my $contributors = $self->json->decode( $response->content )->{contributors};
 
     map { $scores{ $_->{login} } = $_->{contributions} } @$contributors;
     return \%scores;
 }
 
 1;


=pod

=head1 NAME

Github::Score - Pull author contribution counts for github repos

=head1 VERSION

version 0.2.0

=head1 AUTHOR

justin.d.hunter@gmail.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by AHB.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__ 


=head1 NAME 

Github::Score - Collect contributions data from the Github api.

=head1 SYNOPSIS

  use Github::Score;
  
  my $gs1 = Github::Score->new(); ##Bare constructor. Not much use without:
  $gs1->user('Getty'); ## Still need a:
  $gs1->repo('p5-www-duckduckgo');
  
  my $contributors_scores = $gs1->scores();
  ## Do stuff with an array of this sort of thing:
  #$VAR1 = [
  #          {
  #            'login' => 'doy',
  #            'contributions' => 119
  #          },
  #          {
  #            'login' => 'stevan',
  #            'contributions' => 36
  #          },
  #          {
  #            'login' => 'jasonmay',
  #            'contributions' => 5
  #          },
  #          {
  #            'login' => 'arcanez',
  #            'contributions' => 3
  #          }
  #        ];
  
  ## Save yourself a few key-strokes
  my $gs2 = Github::Score->new(user=>'Getty', repo=>'p5-www-duckduckgo'); 
  $contributors_scores = $gs2->scores();
  
  ## Save yourself a few more key-strokes
  my $gs3 = Github::Score->new('Getty/p5-www-duckduckgo'); 
  $contributors_scores = $gs3->scores();
  
  ## Can't afford to wait for up to 10 seconds?
  $gs3->timeout(9.99);
  $contributors_scores = $gs3->scores();

=head1 DESCRIPTION

  http://github-high-scores.heroku.com/ is a site with a retro-80s look and 
  feel where you can look up the author contribution counts for projecs on Github.
  Github::Score is an OO perl API to the same data from the site aimed at the 
  DuckDuckGo community platform. 

=head1 METHODS

=head2 Constructors

=head3 new

 Github::Score objects can be constructed in different ways:

=over 4

=item Empty constructor call

C<    new()>

=item Single url-style string

C<    new('contributor/github-repo')>

=item Key-value pairs

C<<   new(user=>someone, repo=>'some-repo', timeout=> $_10_if_you_leave_it_out) >>

=item Hash reference

C<<   new( {user=>someone, repo=>'some-repo', timeout=> $_10_if_you_leave_it_out)} >>

=back

=head2 Accessors

=head3 B<user>

    Will set $self->{user} to $_[0], if an argument is given.
    Returns: $self->{user}

=head3 B<repo>

    Will set $self-{repo}  to $_[0], if an argument is given.
    Returns: $self-{repo} 

=head3 B<timeout>

    Will set $self->{timeout} to $_[0], if an argument is given.
    Returns: $self->{timeout}

    Note: Defaults to 10 when the object is constructed.

=head3 B<ua>

    Returns: A LWP::UserAgent instance

    Note: Do not use this method directly. It is automatically invoked by the
    scores method.

=head3 B<uri>

    Returns: A URI instance
    
    Note: Do not use this method directly. It is automatically invoked by the
    scores method.

=head3 B<json>

    Returns: A JSON instance
    
    Note: Do not use this method directly. It is automatically invoked by the
    scores method.

=head2 Behaviour

=head3 B<scores>

    Returns: A reference to a hash of login/contribution pairs.
    
    Note: The hash could be empty if there is some error with the request,
    or example a timeout, or if the query is invalid, for example user
    does not contribute to the repository.

=head1 BUGS

    None known, but they will be there somewhere.

=head1 TODO

=over 6

=item Github api v3 support

=item Support regex user/repo queries

=item Retry on timeout?

=item Better documentation.

=back

=head1 SEE ALSO

=over 4

=item L<http://github-high-scores.heroku.com/>

=item L<Net::GitHub>

=item L<http://github.com>

=item L<App::DuckDuckGo>

=item L<WWW::DuckDuckGo>

=item L<http://duck.co/>

=back


=for
Kind of thing you get from the api:
$VAR1 = [
          {
            'gravatar_id' => 'dd9aceaf17982bc33972b3bb8701cd19',
            'location' => 'O\'Fallon, IL',
            'name' => 'Jesse Luehrs',
            'blog' => 'http://tozt.net/',
            'login' => 'doy',
            'email' => 'doy at tozt dot net',
            'type' => 'User',
            'company' => 'Infinity Interactive',
            'contributions' => 119
          },
          {
            'gravatar_id' => '0bffad37a60feece78c306af4456f53a',
            'name' => 'Stevan Little',
            'blog' => 'http://moose.perl.org',
            'login' => 'stevan',
            'email' => 'stevan.little@iinteractive.com',
            'type' => 'User',
            'company' => 'Infinity Interactive',
            'contributions' => 36
          },
          {
            'gravatar_id' => 'c68ae3a25b34be3310bd975c2036940d',
            'location' => 'Annville, PA',
            'name' => 'Jason May',
            'blog' => 'http://jarsonmar.org/',
            'login' => 'jasonmay',
            'email' => 'jason.a.may@gmail.com',
            'type' => 'User',
            'company' => 'Best Practical Solutions',
            'contributions' => 5
          },
          {
            'gravatar_id' => 'be68b0e46958d0dcb621f696f9b1bc1c',
            'location' => 'Revere, MA',
            'name' => 'Justin Hunter',
            'blog' => 'http://warpedreality.org',
            'login' => 'arcanez',
            'email' => 'justin.d.hunter@gmail.com',
            'type' => 'User',
            'company' => 'Cantella',
            'contributions' => 3
          }
        ];
=cut