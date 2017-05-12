package Google::Plus;
{
  $Google::Plus::VERSION = '0.004';
}
use Mojo::Base -base;
use v5.10.1;

use Mojo::URL;
use Mojo::UserAgent;
use IO::Socket::SSL 1.37;
use Carp;

has [qw/key ua/];

our $service = 'https://www.googleapis.com/plus/v1';

our %API = (
  person     => '/people/ID',
  activities => '/people/ID/activities/COLLECTION',
  activity   => '/activities/ID'
);

# transform our api dispatch above into an HTTPS request
# returns JSON decoded result or throws exception otherwise
sub _request {
  my ($self, $api, $id, $args) = @_;

  my $key = $self->key;
  my $ua  = $self->ua;

  $api =~ s/ID/$id/;

  my $url = Mojo::URL->new(join '', $service => $api);

  # $args is a hashref corresponding to optional query parameters (such
  # as nextPageToken)
  if (ref $args eq 'HASH') {
  PARAM: while (my ($k, $v) = each %$args) {
      $k eq 'collection' and do {
        my $p = $url->path->to_string;
        $p =~ s/COLLECTION/$v/;
        $url = $url->path($p);
        next PARAM;
      };
      $url = $url->query({$k => $v});
    }
  }
  $url = $url->query({key => $key});

  my $tx = $ua->get($url);
  $tx->success and return $tx->res->json;

  # we never get here, unless something went wrong
  my $message = $tx->error;
  $tx->res->json and do {
    my $json_err = $tx->res->json->{error}->{message};
    $message = join ' ', $message => $json_err;
  };
  die "Error: $message";
}

sub new {
  my $self = bless {}, shift;

  croak "API key required" unless $_[0] and $_[0] eq 'key';

  $self->key($_[1]);
  $self->ua(Mojo::UserAgent->new->detect_proxy);

  $self;
}

sub person {
  my ($self, $user_id, $fields) = @_;

  croak 'user ID required' unless $user_id;
  croak 'Invalid user ID' unless $user_id =~ /[0-9]+/;

  $fields
    ? $self->_request($API{person} => $user_id, {fields => $fields})
    : $self->_request($API{person} => $user_id);
}

sub activities {
  my ($self, $user_id, $collection, $next, $fields) = @_;

  croak 'user ID required' unless $user_id;
  croak 'Invalid user ID' unless $user_id =~ /[0-9]+/;

  $collection //= 'public';

  my %args = (collection => $collection);
  $args{pageToken} = $next   if $next;
  $args{fields}    = $fields if $fields;

  $self->_request($API{activities} => $user_id, \%args);
}

sub activity {
  my ($self, $activity_id, $fields) = @_;

  croak 'activity ID required' unless $activity_id;
  croak 'Invalid activity ID' unless $activity_id =~ /\w+/;

  $fields
    ? $self->_request($API{activity} => $activity_id, {fields => $fields})
    : $self->_request($API{activity} => $activity_id);
}

"Inspired by tempire's Google::Voice :3";

__END__

=head1 NAME

Google::Plus - simple interface to Google+

=head1 SYNOPSIS

  use Google::Plus;
  use v5.10.1;

  my $plus = Google::Plus->new(key => $your_gplus_api_key);

  # get a person's profile
  my $user_id = '112708775709583792684';
  my $person  = $plus->person($user_id);
  say "Name: ", $person->{displayName};

  # get this person's activities
  my $activities = $plus->activities($user_id);
  while ($activities->{nextPageToken}) {
    my $next = $activities->{nextPageToken};
    for my $item (@{$activities->{items}}) {
      ...;
    }
    $activities = $plus->activities($user_id, $next);
  }

  # get a specific activity
  my $post = 'z13uxtsawqqwwbcjt04cdhsxcnfyir44xeg';
  my $act  = $plus->activity($post);
  say "Activity: ", $act->{title};

=head1 DESCRIPTION

This module lets you access Google+ people profiles and activities from
Perl.  Currently, only access to public data is supported; authenticated
requests for C<me> and other private data will follow in a future
release.

This module is B<alpha> software, use at your own risk.

=head1 ATTRIBUTES

=head2 C<key>

  my $key = $plus->key;
  my $key = $plus->key('xxxxNEWKEYxxxx');

Google+ API key, used for retrieving content.  Usually set using L</new>.

=head2 C<ua>

  my $ua = $plus->ua;
  my $ua = $plus->ua(Mojo::UserAgent->new);

User agent object that retrieves JSON from the Google+ API endpoint.
Defaults to a L<Mojo::UserAgent> object.  This object will use
HTTP/HTTPS proxies when available (via C<HTTP_PROXY> and C<HTTPS_PROXY>
environment variables.)

=head1 METHODS

L<Google::Plus> implements the following methods:

=head2 C<new>

  my $plus = Google::Plus->new(key => $google_plus_api_key);

Construct a new L<Google::Plus> object.  Needs a valid Google+ API key,
which you can get at L<https://code.google.com/apis/console>.

=head2 C<person>

  my $person = $plus->person('userId');
  my $person = $plus->person('userId', 'fields');

Get a Google+ person's public profile.  Returns a L<Mojo::JSON> decoded
hashref describing the person's profile in L<Portable
Contacts|http://portablecontacts.net/draft-spec.html> format.  If
C<fields> is given, limit response to the specified fields; see the
Partial Responses section of L<https://developers.google.com/+/api>.

=head2 C<activities>

  my $acts = $plus->activities('userId');
  my $acts = $plus->activities('userId', 'collection');
  my $acts = $plus->activities('userId', 'collection', nextPage');
  my $acts = $plus->activities('userId', 'collection', nextPage', 'fields');

Get person's list of public activities, returning a L<Mojo::JSON>
decoded hashref describing the person's activities in L<Activity
Streams|http://activitystrea.ms/specs/json/1.0> format; this method also
accepts requesting partial responses if C<fields> is given.  If
C<collection> is given, use that as the collection of activities to
list; the default is to list C<public> activities instead.  If a
C<nextPage> token is given, this method retrieves the next page of
activities this person has.

=head2 C<activity>

  my $post = $plus->activity('activityId')
  my $post = $plus->activity('activityId', fields');

Get a specific activity/post.  Returns a L<Mojo::JSON> decoded hashref
describing the activity in L<Activity
Streams|http://activitystrea.ms/specs/json/1.0> format.  If C<fields> is
given, limit response to specified fields.

=head1 SEE ALSO

=over

=item * L<Google+ API|http://developers.google.com/+/api>

=item * L<Google+|https://plus.google.com>

=item * L<Portable Contacts|http://portablecontacts.net>

=item * L<Activity Streams|http://activitystrea.ms>

=back

=cut

=head1 DEVELOPMENT

This project is hosted on Github, at
L<https://github.com/zakame/perl-google-plus>.  Post issues to L<CPAN
RT|https://rt.cpan.org/Public/Dist/Display.html?Name=Google-Plus>.

=head1 AUTHOR

Zak B. Elep, C<zakame@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011, Zak B. Elep.

This is free software, you can redistribute it and/or modify it under
the same terms as Perl language system itself.

=cut
