package Finance::GDAX::API::URL;
our $VERSION = '0.02';
use 5.20.0;
use warnings;
use Moose;

=head1 NAME

Finance::GDAX::API::URL - URL assembly for GDAX REST API

=head1 SYNOPSIS

  use Finanace::GDAX::API::URL;
  my $url = Finance::GDAX::API::URL->new->testing;
  `wget $url/test_thing`;

=head1 DESCRIPTION

This class builds URLs for Finance::GDAX::API classes

=head1 ATTRIBUTES

=head2 C<debug>

Bool that sets debug mode (will use sandbox). Defaults to true (1).

=head2 C<production>

The base URI for production requests, including the https://

=head2 C<testing>

The base URI for testing requests to the GDAX sandbox, including the
https://

=cut

has 'production' => (is  => 'rw',
		     isa => 'Str',
		     default => 'https://api.gdax.com',
    );
has 'testing' => (is  => 'rw',
		  isa => 'Str',
		  default => 'https://api-public.sandbox.gdax.com',
    );
has 'debug' => (is  => 'rw',
		isa => 'Bool',
		default => 1,
    );
has '_sections' => (is  => 'rw',
		    isa => 'ArrayRef',
		    default => sub {[]},
    );
		    

=head1 METHODS

=head2 C<get>

Returns a string of the assembled URL

=cut

sub get {
    my $self = shift;
    my $url = join '/', @{$self->_sections};
    $url = '/'.$url;
    if ($self->debug) {
	return $self->testing.$url;
    } else {
	return $self->production.$url;
    }
}

=head2 C<add>

Adds to the URL, each will be separated with a '/'

  $url->add('products');

=cut

sub add {
    my ($self, $thing) = @_;
    $thing =~ s/^\/+//;
    push @{$self->_sections}, $thing;
}

__PACKAGE__->meta->make_immutable;
1;


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

