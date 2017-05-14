package GSM::SMS::Transport::Transport;
use strict;

use vars qw( $VERSION $AUTOLOAD );

use Carp;

$VERSION = "0.161";

=head1 NAME

GSM::SMS::Transport::Transport - Base class for transports

=head1 DESCRIPTION

This class is a base class for all transports, i.e. all transports must
inherit from this class.

=head1 METHODS

=over 4

=item B<new> - Constructor

=cut

sub new 
{
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	my $self = {
		_name			=> $args{-name} || croak("missing name"),
		_originator		=> $args{-originator} || 'GSM::SMS',
		_match			=> $args{-match} 	|| croak("missing match regexp")
	};

	bless($self, $class);
	return $self;
}


=item B<has_valid_route> - Do we have a valid route for this msisdn

	$transport->has_valid_route( $msisdn );

=cut

sub has_valid_route {
	my ($self, $msisdn) = @_;

	foreach my $route ( split /,/, $self->get_match() ) {
		return -1 if $msisdn =~ /$route/;
	}
	return 0;
}

=back

=head1 ABSTRACT METHODS

=cut

sub METHOD::ABSTRACT
{
	my ($self) = @_;
	my $object_class = ref($self);
	my ($file, $line, $method) = (caller(1))[1..3];
	die "Call to abstract method ${method} at $file, line $line\n";
}

=over 4

=item B<send> - Send a (PDU encoded) message

=cut

sub send {	ABSTRACT METHOD @_ }


=item B<receive> - Receive a PDU encoded message


	$PDU = $transport->receive();

=cut

sub receive {	ABSTRACT METHOD @_ }	

=item B<close> - Close the transport

=cut

sub close {	ABSTRACT METHOD @_ }

=item B<ping> - return an informative string on success

=cut

sub ping {	ABSTRACT METHOD @_ }

=item B<get_info> - Returns info on the transport

=cut

sub get_info { ABSTRACT METHOD @_ }

=item B<DESTROY> - The destructor

=cut

sub DESTROY {}

=back

=cut

sub AUTOLOAD
{
	my ($self, $newval) = @_;

	# Handle get_... method
	$AUTOLOAD =~ /.*::get(_\w+)/
		and $self->_accessible($1, 'read')
		and return $self->{$1};

	# Handle set_... method
	$AUTOLOAD =~ /.*::set(_\w+)/
		and $self->_accessible($1, 'write')
		and do { $self->{$1} = $newval; return; };

	# Oops ... a mistake
	croak "No such method: $AUTOLOAD";
}

1;
__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
