package HTTP::OAI::Header;

@ISA = qw( HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.05';

use POSIX qw/strftime/;

sub identifier { shift->_elem('identifier',@_) }
sub datestamp {
	my $self = shift;
	return $self->_elem('datestamp') unless @_;
	my $ds = shift or return $self->_elem('datestamp',undef);
	if( $ds =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
		$ds = "$1-$2-$3";
	} elsif( $ds =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/ ) {
		$ds = "$1-$2-$3T$4:$5:$6Z";
	}
	return $self->_elem('datestamp',$ds);
}
sub status { shift->_elem('status',@_) }
sub setSpec { shift->_multi('setSpec',@_) }

sub now { return strftime("%Y-%m-%dT%H:%M:%SZ",gmtime()) }

sub is_deleted { my $s = shift->status(); return defined($s) && $s eq 'deleted'; }

sub generate
{
	my ($self, $driver) = @_;

	if( defined($self->status) ) {
		$driver->start_element( 'header', status => $self->status );
	} else {
		$driver->start_element( 'header' );
	}
	$driver->data_element( 'identifier', $self->identifier );
	$driver->data_element( 'datestamp', ($self->datestamp || $self->now) );
	for($self->setSpec)
	{
		$driver->data_element( 'setSpec', $_ );
	}
	$driver->end_element( 'header' );
}

sub end_element {
	my ($self,$hash) = @_;
	my $elem = lc($hash->{LocalName});
	my $text = $hash->{Text};
	if( defined $text )
	{
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
	}
	if( $elem eq 'identifier' ) {
		$self->identifier($text);
	} elsif( $elem eq 'datestamp' ) {
		$self->datestamp($text);
	} elsif( $elem eq 'setspec' ) {
		$self->setSpec($text);
	} elsif( $elem eq 'header' ) {
		$self->status($hash->{Attributes}->{'{}status'}->{Value});
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::Header - Encapsulates an OAI header structure

=head1 SYNOPSIS

	use HTTP::OAI::Header;

	my $h = new HTTP::OAI::Header(
		identifier=>'oai:myarchive.org:2233-add',
		datestamp=>'2002-04-12T20:31:00Z',
	);

	$h->setSpec('all:novels');

=head1 METHODS

=over 4

=item $h = new HTTP::OAI::Header

This constructor method returns a new C<HTTP::OAI::Header object>.

=item $h->identifier([$identifier])

Get and optionally set the record OAI identifier.

=item $h->datestamp([$datestamp])

Get and optionally set the record datestamp (OAI 2.0+).

=item $h->status([$status])

Get and optionally set the record status (valid values are 'deleted' or undef).

=item $h->is_deleted()

Returns whether this record's status is deleted.

=item @sets = $h->setSpec([$setSpec])

Returns the list of setSpecs and optionally appends a new setSpec C<$setSpec> (OAI 2.0+).

=item $dom_fragment = $id->generate()

Act as a SAX driver (use C<< $h->set_handler() >> to specify the filter to pass events to).

=back
