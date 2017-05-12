package Mail::Karmasphere::Query;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $ID);
use Carp;
use Exporter;

BEGIN {
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(guess_identity_type);
	%EXPORT_TAGS = (
		'all'	=> \@EXPORT_OK,
	);
}

use Mail::Karmasphere::Client qw(:all);

$ID = 0;

sub new {
	my $class = shift;
	my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	#use Data::Dumper;
	#print Dumper($args);

	my $self = bless { }, $class;

	if (exists $args->{Id}) {
		$self->id(delete $args->{Id});
	}

	if (exists $args->{Identities}) {
		my $identities = delete $args->{Identities};
		die "Identities must be a listref, not " . ref($identities)
						unless ref($identities) eq 'ARRAY';
		for my $identity (@$identities) {
			if (ref($identity) eq 'ARRAY') {
				$self->identity(@$identity);
			}
			else {
				$self->identity($identity);
			}
		}
	}

	if (exists $args->{Composites}) {
		my $composites =  delete $args->{Composites};
		die "Composites must be a listref"
						unless ref($composites) eq 'ARRAY';
		$self->composite($_) for @$composites;
	}

	if (exists $args->{Composite}) {
		$self->composite(delete $args->{Composite});
	}

	if (exists $args->{Feeds}) {
		my $feeds =  delete $args->{Feeds};
		die "Feeds must be a listref"
						unless ref($feeds) eq 'ARRAY';
		$self->feed($_) for @$feeds;
	}

	if (exists $args->{Combiners}) {
		my $combiners = delete $args->{Combiners};
		die "Combiners must be a listref"
						unless ref($combiners) eq 'ARRAY';
		$self->combiner($_) for @$combiners;
	}

	if (exists $args->{Combiner}) {
		$self->combiner(delete $args->{Combiner});
	}

	if (exists $args->{Flags}) {
		$self->flags(delete $args->{Flags});
	}

	my @remain = keys %$args;
	if (@remain) {
		carp "Unrecognised arguments to constructor: @remain";
	}

	return $self;
}

sub guess_identity_type {
	my $identity = shift;

	if ($identity =~ /^[0-9\.]{7,15}$/) {
		return IDT_IP4;
	}
	elsif ($identity =~ /^[0-9a-f:]{2,64}$/i) {
		return IDT_IP6;
	}
	elsif ($identity =~ /^https?:\/\//) {
		return IDT_URL;
	}
	elsif ($identity =~ /@/) {
		return IDT_EMAIL;
	}
	elsif ($identity =~ /\./) {
		return IDT_DOMAIN;
	}

	return undef;
}

sub id {
	my $self = shift;
	if (@_) {
		$self->{Id} = shift;
	}
	elsif (!defined $self->{Id}) {
		$self->{Id} = 'mkc' . $ID++ . "-" . time();
	}
	return $self->{Id};
}

sub identity {
	my ($self, $identity, @tags) = @_;
	unless (ref($identity) eq 'ARRAY') {
		my $type;
		if (@tags) {
			$type = shift @tags;
		}
		else {
			warn "Guessing identity type for $identity";
			$type = guess_identity_type($identity);
		}
		$identity = [ $identity, $type ];
	}
	push(@$identity, @tags) if @tags;
	for (@{ $self->{Identities} }) {
		# If the data and the type match
		if (($_->[0] eq $identity->[0]) &&
				($_->[1] eq $identity->[1])) {
			# Combine the tags from the new identity;
			shift @$identity; shift @$identity;
			push(@{ $_ }, @$identity);
			return;
		}
	}
	push(@{ $self->{Identities} }, $identity);
}

sub identities {
	my $self = shift;
	if (@_) {
		$self->{Identities} = [ ];
		$self->identity($_) for @_;
	}
	return $self->{Identities};
}

sub has_identities {
	my $self = shift;
	return undef unless exists $self->{Identities};
	return undef unless @{ $self->{Identities} };
	return 1;
}

sub composite {
	my ($self, @composites) = @_;
	for my $composite (@composites) {
		# Validate
		if (ref($composite)) {
			die "Composite may not be a reference";
		}
		elsif ($composite =~ /^[0-9]+$/) {
			warn "Using numeric ids for composites should be avoided.";
		}
		elsif ($composite =~ /\./) {
		}
		else {
			warn "Composite name does not contain a dot. Invalid?";
		}
		push(@{ $self->{Composites} }, $composite);
	}
}

sub composites {
	my $self = shift;
	if (@_) {
		$self->{Composites} = [ ];
		$self->composite(@_);
	}
	return $self->{Composites};
}

sub has_composites {
	my $self = shift;
	return undef unless exists $self->{Composites};
	return undef unless @{ $self->{Composites} };
	return 1;
}

sub feed {
	my ($self, @feeds) = @_;
	for my $feed (@feeds) {
		# Validate.
#		if ($feed =~ /^[0-9]+$/) {
#			warn "Numeric feed ids are deprecated.";
#		}
		push(@{ $self->{Feeds} }, $feed);
	}
}

sub feeds {
	my $self = shift;
	if (@_) {
		$self->{Feeds} = [ ];
		$self->feed(@_);
	}
	return $self->{Feeds};
}

sub has_feeds {
	my $self = shift;
	return undef unless exists $self->{Feeds};
	return undef unless @{ $self->{Feeds} };
	return 1;
}

sub combiner {
	my ($self, @combiners) = @_;
	for my $combiner (@combiners) {
		# Validate.
		push(@{ $self->{Combiners} }, $combiner);
	}
}

sub combiners {
	my $self = shift;
	if (@_) {
		$self->{Combiners} = [ ];
		$self->combiner(@_);
	}
	return $self->{Combiners};
}

sub has_combiners {
	my $self = shift;
	return undef unless exists $self->{Combiners};
	return undef unless @{ $self->{Combiners} };
	return 1;
}

sub flags {
	my $self = shift;
	if (@_) {
		my $flags = shift;
		die "Flags must be an integer" unless $flags =~ /^[0-9]+$/;
		$self->{Flags} = $flags;
	}
	return $self->{Flags};
}

sub has_flags {
	my $self = shift;
	return undef unless exists $self->{Flags};
	return undef unless defined $self->{Flags};
	return 1;
}

sub identities_as_humanreadable_string {
	my $self = shift;
	my @identities = @{ $self->{Identities} || [] };
	return join ",", (map { join "=", ($_->[1], $_->[0], ($_->[2] || ())) } @identities);
}

sub _as_string_sizeof {
	my $ref = shift;
	return "0" unless defined $ref;
	return scalar(@$ref);
}

sub as_string {
	my ($self) = @_;
	my $out = "Query id '" . $self->id . "': ";
	$out .= _as_string_sizeof($self->{Identities}) . ' identities, ';
	$out .= _as_string_sizeof($self->{Feeds}) . ' feeds, ';
	$out .= _as_string_sizeof($self->{Composites}) . " composites, ";
	$out .= _as_string_sizeof($self->{Combiners}) . " combiners\n";
	if ($self->{Identities}) {
		for (@{ $self->{Identities} }) {
			my ($id, $t, @t) = @$_;
			$out .= "Identity: $id ($t)";
			$out .= " (= @t)" if @t;
			$out .= "\n";
		}
	}
	if ($self->{Composites}) {
		$out .= "Composites: " .
				join(' ', sort @{ $self->{Composites} } ) .
				"\n";
	}
	if ($self->{Feeds}) {
		$out .= "Feeds: " .
				join(' ', sort @{ $self->{Feeds} } ) .
				"\n";
	}
	if ($self->{Combiners}) {
		$out .= "Combiners: " .
				join(' ', sort @{ $self->{Combiners} } ) .
				"\n";
	}
	return $out;
}

=head1 NAME

Mail::Karmasphere::Query - Karmasphere Query Object

=head1 SYNOPSIS

	my $query = new Mail::Karmasphere::Query(...);

=head1 DESCRIPTION

The Perl Karma Client API consists of three objects: The Query, the
Response and the Client. The user constructs a Query and passes it to
a Client, which returns a Response. See L<Mail::Karmasphere::Client>
for more information.

=head1 CONSTRUCTOR

The class method new(...) constructs a new Query object. All arguments
are optional. The following parameters are recognised as arguments
to new():

=over 4

=item Identities

A listref of identities, each of which is an [ identity, type ] pair.

=item Composites

A listref of composite keynames.

=item Composite

A single composite keyname.

=item Flags

The query flags.

=item Id

The id of this query, returned in the response. The id is autogenerated
in a new query if not provided, and may be retrieved using $query->id.

=item Feeds

A listref of feed ids.

=item Combiners

A listref of combiner names.

=item Combiner

A single combiner name.

=back

=head1 METHODS

=head2 PRIMARY METHODS

These methods are the ones you must understand in order to use
Mail::Karmashere::Client.

=over 4

=item $query->identity($data, $type, @tags)

Adds an identity to this query.

=item $query->composite(@composites)

Adds one or more composites to this query.

=item $query->flags($flags)

Sets or returns the flags of this query.

=back

=head2 OTHER METHODS

These methods permit more flexibility and access to more features.

=over 4

=item $query->id([$id])

Sets or returns the id of this query. If the query has no id, an id
will be generated by the client and will appear in the response.

=item $query->identities(@identities)

Sets or returns the identities of this query.

=item $query->composites(@composites)

Sets or returns the composites of this query.

=item $query->feeds(@feeds)

Sets or returns the feeds of this query.

=item $query->feeds(@feeds)

Adds a feed to this query.

=item $query->combiners(@combiners)

Sets or returns the combiners of this query.

=item $query->combiner(@combiners)

Adds combiners to this query.

=back

=head1 BUGS

This document is incomplete.

=head1 SEE ALSO

L<Mail::Karmasphere::Client>
L<Mail::Karmasphere::Response>
http://www.karmasphere.com/

=head1 COPYRIGHT

Copyright (c) 2005 Shevek, Karmasphere. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
