# Declare our package
package Games::AssaultCube::MasterserverQuery::Response;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# get some utility stuff
use Games::AssaultCube::Utils qw( parse_masterserverresponse );

# TODO improve validation for everything here, ha!

has 'masterserver' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'servers' => (
	isa		=> 'ArrayRef[HashRef]',
	is		=> 'ro',
	default		=> sub { [] },
);

has 'num_servers' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return scalar @{ $self->servers };
	},
);

has 'response' => (
	isa		=> 'HTTP::Response',
	is		=> 'ro',
	required	=> 1,
);

has 'tohash' => (
	isa		=> 'HashRef',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		my $data = {
			masterserver	=> $self->masterserver,
			servers		=> [ map { { ip => $_->{ip}, port => $_->{port} } } @{ $self->servers } ],
		};
		return $data;
	},
);

sub BUILDARGS {
	my $class = shift;

	# Normally, we would be created by Games::AssaultCube::MasterserverQuery and contain 2 args
	if ( @_ == 2 && ref $_[0] && $_[0]->isa( 'Games::AssaultCube::MasterserverQuery' ) ) {
		# call the parse method
		return {
			masterserver	=> $_[0]->server,
			servers		=> parse_masterserverresponse( $_[1] ),
			response	=> $_[1],
		};
	} else {
		return $class->SUPER::BUILDARGS(@_);
	}
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords masterserver tohash URI hashrefs ip

=head1 NAME

Games::AssaultCube::MasterserverQuery::Response - Holds the various data from a MasterserverQuery response

=head1 SYNOPSIS

	use Games::AssaultCube::MasterserverQuery;
	my $query = Games::AssaultCube::MasterserverQuery->new;
	#my $query = Games::AssaultCube::MasterserverQuery->new( 'http://foo.com/get.do' );
	#my $query = Games::AssaultCube::MasterserverQuery->new({ server => 'http://foo.com/get.do', timeout => 5 });
	my $response = $query->run;
	if ( defined $response ) {
		print "There is a total of " . $response->num_servers " servers in the list!\n";
	} else {
		print "Masterserver is not responding!\n";
	}

=head1 ABSTRACT

This module holds the various data from a MasterserverQuery response

=head1 DESCRIPTION

This module holds the response data from an AssaultCube MasterserverQuery. Normally you will not use this class
directly, but via the L<Games::AssaultCube::MasterserverQuery> class.

=head2 Attributes

You can get the various data by fetching the attribute. Valid attributes are:

=head3 masterserver

The URI of the masterserver we queried

=head3 servers

An arrayref of hashrefs of servers in the list

The hashref contains the following keys: ip and port

=head3 num_servers

A convenience accessor returning the number of servers in the list

=head3 response

The HTTP::Response object in case you wanted to poke around

=head3 tohash

A convenience accessor returning "vital" data in a hashref for easy usage

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
