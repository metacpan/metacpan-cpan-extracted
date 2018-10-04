package Meetup::API;
use strict;
our $VERSION = '0.02';

=head1 NAME

Meetup::API - interface to the Meetup API

=head1 SYNOPSIS

  use Meetup::API;
  my $meetup = Meetup::API->new();
  my $events = $meetup->group_events($groupname)->get;



=head1 METHODS

=head2 C<< Meetup::API->new %options >>

=over 4

=item B<< version >>

Allows you to specify the API version. The current
default is C<< v3 >>, which corresponds to the
Meetup API version 3 as documented at
L<http://www.meetup.com/en-EN/meetup_api/docs/>.

=back

=cut

sub new {
    my( $class, %options ) = @_;
    $options{ version } ||= 'v3';
    $class = "$class\::$options{ version }";
    # Once we spin ut v3 from this file
    (my $fn = $class) =~ s!::!/!g;
    require "$fn.pm";
    $class->new( %options );
};

=head1 SETUP

=over 4

=item 0. Register with meetup.com

=item 1. Click on their verification email link

=item 2. Visit L<https://secure.meetup.com/de-DE/meetup_api/key/>
to get the API key

=item 4. Create a JSON file named C<meetup.credentials>

This file should live in your
home directory
with the API key:

    {
      "applicationKey": ".............."
    }

=back

=head1 SEE ALSO

L<Meetup::API::v3>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Meetup-API>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;