package Facebook;
BEGIN {
  $Facebook::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Facebook::VERSION = '0.102';
}
# ABSTRACT: Facebook SDK in Perl

use Moose;
use Carp qw/croak/;

use namespace::autoclean;


has desktop => (
	isa => 'Bool',
	is => 'ro',
	required => 1,
	lazy => 1,
	default => sub { 0 },
);

has uid => (
	isa => 'Maybe[Str]',
	is => 'rw',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->signed->uid;
	},
);

has app_id => (
	isa => 'Maybe[Str]',
	is => 'rw',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->signed->app_id;
	},
);

has api_key => (
	isa => 'Maybe[Str]',
	is => 'rw',
	lazy => 1,
	default => sub { croak 'api_key is required' },
);

has secret => (
	isa => 'Maybe[Str]',
	is => 'rw',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->signed->secret;
	},
);

has access_token => (
	isa => 'Maybe[Str]',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->signed->access_token;
	},
);

has access_token_secret => (
	isa => 'Maybe[Str]',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->signed->access_token_secret;
	},
);

has signed => (
	isa => 'Facebook::Signed',
	is => 'ro',
	lazy => 1,
	default => sub { croak 'signed values are required' },
	predicate => 'has_signed',
);

has graph_class => (
	isa => 'Str',
	is => 'ro',
	default => sub { 'Facebook::Graph' },
);

has graph_api => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $graph_class_file = $self->graph_class;
		$graph_class_file =~ s/::/\//g;
		require $graph_class_file.'.pm';
		$self->graph_class->import;
		$self->graph_class->new(
			app_id => $self->app_id,
			secret => $self->secret,
			access_token => $self->access_token,
		);
	},
);

has rest_class => (
	isa => 'Str',
	is => 'ro',
	required => 1,
	default => sub { 'WWW::Facebook::API' },
);

has rest_api => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $rest_class_file = $self->rest_class;
		$rest_class_file =~ s/::/\//g;
		require $rest_class_file.'.pm';
		$self->rest_class->import;
		$self->rest_class->new(
			desktop => $self->desktop ? 0 : 1,
			api_key => $self->api_key,
			secret => $self->secret,
		);
	},
);


sub graph {
	my ( $self ) = @_;
	$self->graph_api;
}


sub rest {
	my ( $self ) = @_;
	$self->rest_api;
}


1;
__END__
=pod

=head1 NAME

Facebook - Facebook SDK in Perl

=head1 VERSION

version 0.102

=head1 SYNOPSIS

  use Facebook;

  my $fb = Facebook->new(
    app_id => $app_id,
    api_key => $api_key,
    secret => $secret,
  );

  use Facebook::Signed;

  my $logged_in_fb = Facebook->new(
    signed => Facebook::Signed->new(
      secret => $secret,
      facebook_data => $facebook_cookie_for_your_application_as_text,
    ),
    app_id => $app_id,
    secret => $secret,
	api_key => $api_key,
  );

  # If you dont provide secret, it will try to fetch it from signed values
  my $shorter_logged_in_fb = Facebook->new(
    signed => Facebook::Signed->new(
      secret => $secret,
      facebook_data => $facebook_cookie_for_your_application_as_text,
    ),
    app_id => $app_id,
    api_key => $api_key,
  );
  
  # You need to have Facebook::Graph installed so that this works
  my $gettys_facebook_profile = $fb->graph->query
    ->find(100001153174797)
    ->include_metadata
    ->request
    ->as_hashref;

=head1 DESCRIPTION

B<If you are new to Facebook application development in Perl please read L<Facebook::Manual>!>

This package reflects an instance for your application. Depending on what API of it you use, you require to install the
needed distributions or provide alternative packages yourself.

=head1 METHODS

=head2 $obj->graph

Arguments: None

Return value: Object

B<If you want to use this, you need to install L<Facebook::Graph>!>

Returns an instance of the graph_class (by default this is L<Facebook::Graph>)

=head2 $obj->rest

Arguments: None

Return value: Object

B<If you want to use this, you need to install L<WWW::Facebook::API>!>

Returns an instance of the rest_class (by default this is L<WWW::Facebook::API>)

=encoding utf8

=head1 METHODS

=head1 LIMITATIONS

=head1 TROUBLESHOOTING

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=item *

Frank Sheiness <syndesis@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Facebook Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

