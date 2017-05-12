# Declare our package
package Games::AssaultCube::MasterserverQuery;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# get some utility stuff
use Games::AssaultCube::MasterserverQuery::Response;
use LWP::UserAgent;
use HTTP::Request;

# TODO make validation so we accept a *real* URI
has 'server' => (
	isa		=> 'Str',
	is		=> 'ro',
	default		=> 'http://masterserver.cubers.net/cgi-bin/AssaultCube.pl/retrieve.do?item=list',
);

has 'timeout' => (
	isa		=> 'Int',
	is		=> 'rw',
	default 	=> 30,
);

has 'useragent' => (
	isa		=> 'LWP::UserAgent',
	is		=> 'rw',
	default		=> sub { return LWP::UserAgent->new },
);

has 'request' => (
	isa		=> 'HTTP::Request',
	is		=> 'rw',
	lazy		=> 1,
	default		=> sub { return HTTP::Request->new( GET => $_[0]->server ) },
);

sub BUILDARGS {
	my $class = shift;

	if ( @_ == 1 && ! ref $_[0] ) {
		# set the server as the first argument
		return { server => $_[0] };
	} else {
		# normal hash/hashref way
		return $class->SUPER::BUILDARGS(@_);
	}
}

sub run {
	my $self = shift;

	# set the alarm, and wait for the response
	my( $res );
	eval {
		# perldoc -f alarm says I need to put \n in the die... weird!
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm $self->timeout;
		$res = $self->useragent->request( $self->request );
		alarm 0;
	};
	if ( $@ ) {
		if ( $@ =~ /^alarm/ ) {
			die "Unable to query server: Timed out";
		} else {
			die "Unable to query server: $@";
		}
	} else {
		if ( defined $res and $res->is_success ) {
			return Games::AssaultCube::MasterserverQuery::Response->new( $self, $res );
		} else {
			return;
		}
	}
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords masterserver CubeStats.net HTTP URI XML hostname ip useragent

=head1 NAME

Games::AssaultCube::MasterserverQuery - Queries an AssaultCube masterserver for the list of servers

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

This module queries an AssaultCube masterserver for the list of servers.

=head1 DESCRIPTION

This module queries an AssaultCube masterserver for the list of servers. It has been tested extensively
on the AssaultCube masterserver and the CubeStats.net masterserver.

WARNING: This module doesn't parse the XML output, only the regular "list" format! In the future XML parsing
will be added as XML support gets stable in the masterserver.

=head2 Constructor

This module uses Moose, so you can pass either a hash, hashref, or a server to the constructor. Passing
a string means we're passing in a server URI. If you want to specify more options, please use the
hash/hashref method.

The attributes are:

=head3 server

The server hostname or ip in HTTP URI format.

Defaults to the AssaultCube masterserver: L<http://masterserver.cubers.net/cgi-bin/AssaultCube.pl/retrieve.do?item=list>

=head3 timeout

The timeout waiting for the server response in seconds. Defaults to 30.

WARNING: We use alarm() internally to do the timeout. If you used it somewhere else, it will cause conflicts
and potentially render it useless. Please inform me if there's conflicts in your script and we can try to
work around it.

=head3 useragent

The LWP::UserAgent object we will use. Handy if you want to override it's configuration.

=head2 Methods

Currently, there is only one method: run(). You call this and get the response object back. For more
information please look at the L<Games::AssaultCube::MasterserverQuery::Response> class. You can call run() as
many times as you want, no need to re-instantiate the object for each query.

WARNING: run() will die() if errors happen. For sanity, you should wrap it in an eval.

=head2 Attributes

You can modify some attributes before calling run() on the object. They are:

=head3 timeout

Same as the constructor

=head3 useragent

Same as the constructor

=head3 request

You can modify the HTTP::Request object, if needed to override stuff.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
