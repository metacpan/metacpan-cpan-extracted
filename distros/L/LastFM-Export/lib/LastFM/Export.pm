package LastFM::Export;
BEGIN {
  $LastFM::Export::AUTHORITY = 'cpan:DOY';
}
{
  $LastFM::Export::VERSION = '0.03';
}
use Moose;
# ABSTRACT: data exporter for last.fm

use Data::Stream::Bulk::Callback;
use Net::LastFM;



has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has api_key => (
    is       => 'ro',
    isa      => 'Str',
    default  => '30b55f2e2e78056b16dbb15cb0899c2d',
);

has lastfm => (
    is      => 'ro',
    isa     => 'Net::LastFM',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Net::LastFM->new(
            api_key    => $self->api_key,
            api_secret => '',
        );
    },
);


sub track_count {
    my $self = shift;
    my (%params) = @_;

    $params{method} = 'user.getRecentTracks';
    $params{user}   = $self->user;
    $params{limit}  = 1;

    return $self->lastfm->request(%params)->{recenttracks}{'@attr'}{total};
}


sub tracks {
    my $self = shift;
    my (%params) = @_;

    $params{method}   = 'user.getRecentTracks';
    $params{user}     = $self->user;
    $params{limit}  ||= 200;
    $params{page}   ||= 1;

    return Data::Stream::Bulk::Callback->new(
        callback => sub {
            my $data = $self->lastfm->request(%params);

            return if $params{page} > $data->{recenttracks}{'@attr'}{totalPages};
            $params{page}++;

            return $data->{recenttracks}{track};
        },
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=head1 NAME

LastFM::Export - data exporter for last.fm

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use LastFM::Export;

  my $exporter = LastFM::Export->new(user => 'doyster');
  my $stream = $exporter->tracks;

  while (my $block = $stream->next) {
      for my $track (@$block) {
          # ...
      }
      sleep 1;
  }

=head1 DESCRIPTION

This module uses the L<http://last.fm/> API to allow you to export your
scrobbling data from your account. Currently, the only thing this lets you
export is your actual scrobble data, but more features may be added in the
future (especially if the feature requests come with patches!).

=head1 ATTRIBUTES

=head2 user

last.fm user to export data for. Required.

=head1 METHODS

=head2 track_count(%params)

Returns the number of tracks the user has scrobbled.

C<%params> can contain C<from> and C<to> keys, as documented
L<here|http://www.last.fm/api/show/user.getRecentTracks>.

=head2 tracks(%params)

Returns a L<Data::Stream::Bulk> object, which will stream the entire list of
tracks that the user has scrobbled. Note that calling C<all> on this object is
B<not> recommended, since you will likely hit the last.fm API's rate limit.
Each call to C<next> on this stream will require a separate API call.

C<%params> can contain C<page>, C<limit>, C<from>, and C<to> keys, as
documented L<here|http://www.last.fm/api/show/user.getRecentTracks>. C<page>
will default to C<1> and C<limit> will default to C<200> if not specified.

Returns

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/lastfm-export/issues>.

=head1 SEE ALSO

L<Net::LastFM>

L<http://last.fm/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc LastFM::Export

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/LastFM-Export>

=item * Github

L<https://github.com/doy/lastfm-export>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LastFM-Export>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LastFM-Export>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
