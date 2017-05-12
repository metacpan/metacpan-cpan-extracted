package Games::EveOnline::EveCentral::Request::QuickLook;
{
  $Games::EveOnline::EveCentral::Request::QuickLook::VERSION = '0.001';
}


# ABSTRACT: Create a request for the quicklook endpoint.


use Moo 1.003001;
use MooX::Types::MooseLike 0.25;
use MooX::StrictConstructor 0.006;
use MooX::Types::MooseLike::Base qw(AnyOf ArrayRef Int Str);

use 5.012;

extends 'Games::EveOnline::EveCentral::Request';

use Readonly 1.03;


Readonly::Scalar my $ENDPOINT => 'quicklook';


has 'hours' => (
  is => 'ro',
  isa => Int,
  default => 360
);

has 'type_id' => (
  is => 'ro',
  isa => Int,
  required => 1
);

has 'min_q' => (
  is => 'ro',
  isa => Int,
  default => 1
);

has 'regions' => (
  is => 'ro',
  isa => AnyOf[Int, ArrayRef[Int]],
  default => -1
);

has 'system' => (
  is => 'ro',
  isa => Int,
  default => -1
);

has '_path' => (
  is => 'lazy',
  isa => Str,
);



sub request {
  my $self = shift;
  my $path = $self->_path;

  return $self->http_request($path);
}



sub _build__path {
  my $self = shift;

  my $path = $ENDPOINT . '?';

  $path .= 'typeid=' . $self->type_id;

  if (defined $self->hours) {
    my $hours = $self->hours;
    $path .= "&sethours=$hours";
  }

  if (defined $self->min_q) {
    my $min_q = $self->min_q;
    $path .= "&setminQ=$min_q";
  }

  my $system = $self->system;
  if (defined $system && $system > 0) {
    $path .= "&usesystem=$system";
  }

  my $regions = $self->regions;
  if (defined $regions && $regions > 0) {
    if (ref $regions eq 'ARRAY') {
      for my $region (@$regions) {
        $path .= "&regionlimit=$region";
      }
    }
    else {
      $path .= "&regionlimit=$regions";
    }
  }

  return $path;
}


1; # End of Games::EveOnline::EveCentral::Request::QuickLook

__END__

=pod

=head1 NAME

Games::EveOnline::EveCentral::Request::QuickLook - Create a request for the quicklook endpoint.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $req = Games::EveOnline::EveCentral::Request::QuickLook->new(
    type_id => 34, # Mandatory.
    hours => 1, # defaults to 360
    min_q => 10000, # defaults to 1
    system => 30000142,
    regions => 10000002, # or [10000002, 10000003],
  )->request;

=head1 DESCRIPTION

This class is used to create HTTP::Request objects suitable to call the
`quicklook` method on EVE Central.

Please take care to only use valid type ids.

Examples:

=over 4

=item * L<http://api.eve-central.com/api/quicklook?typeid=34>

=back

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 request

Returns an HTTP::Request object which can be used to call the 'quicklook'
endpoint.

=begin private

=end private

=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/pfig/games-eveonline-evecentral/issues>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::EveOnline::EveCentral

You can also look for information at:

=over 4

=item * GitHub Issues (report bugs here)

L<https://github.com/pfig/games-eveonline-evecentral/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-EveOnline-EveCentral>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-EveOnline-EveCentral>

=item * CPAN

L<http://metacpan.org/module/Games::EveOnline::EveCentral>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * The people behind EVE Central.

L<http://eve-central.com/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pedro Figueiredo.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Pedro Figueiredo <me@pedrofigueiredo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Pedro Figueiredo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
