package HTTP::OAI::Record;

@ISA = qw( HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.10';

sub new {
	my ($class,%args) = @_;

	$args{header} ||= HTTP::OAI::Header->new(%args);

	return $class->SUPER::new(%args);
}

sub header { shift->_elem('header',@_) }
sub metadata { shift->_elem('metadata',@_) }
sub about { shift->_multi('about',@_) }

sub identifier { shift->header->identifier(@_) }
sub datestamp { shift->header->datestamp(@_) }
sub status { shift->header->status(@_) }
sub is_deleted { shift->header->is_deleted(@_) }

sub generate
{
	my( $self, $driver ) = @_;

	$driver->start_element('record');
	$self->header->generate( $driver );
	$self->metadata->generate( $driver ) if defined $self->metadata;
	$self->about->generate( $driver ) for $self->about;
	$driver->end_element('record');
}

sub start_element {
	my ($self,$hash, $r) = @_;

	if( !$self->{in_record} )
	{
		my $elem = lc($hash->{LocalName});
		if( $elem eq 'record' && $hash->{Attributes}->{'{}status'}->{Value} )
		{
			$self->status($hash->{Attributes}->{'{}status'}->{Value});
		}
		elsif( $elem eq "header" )
		{
			$self->set_handler(my $handler = HTTP::OAI::Header->new);
			$self->header( $handler );
			$self->{in_record} = $hash->{Depth};
		}
		elsif( $elem =~ /^metadata|about$/ )
		{
			my $class = $r->handlers->{$elem} || "HTTP::OAI::Metadata";
			$self->set_handler(my $handler = $class->new);
			$self->$elem($handler);
			$self->{in_record} = $hash->{Depth};
		}
	}

	$self->SUPER::start_element($hash, $r);
}

sub end_element {
	my ($self,$hash, $r) = @_;

	$self->SUPER::end_element($hash, $r);

	if( $self->{in_record} == $hash->{Depth} )
	{
		$self->set_handler( undef );
		$self->{in_record} = 0;
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::Record - Encapsulates an OAI record

=head1 SYNOPSIS

	use HTTP::OAI::Record;

	# Create a new HTTP::OAI Record
	my $r = new HTTP::OAI::Record();

	$r->header->identifier('oai:myarchive.org:oid-233');
	$r->header->datestamp('2002-04-01');
	$r->header->setSpec('all:novels');
	$r->header->setSpec('all:books');

	$r->metadata(new HTTP::OAI::Metadata(dom=>$md));
	$r->about(new HTTP::OAI::Metadata(dom=>$ab));

=head1 METHODS

=over 4

=item $r = new HTTP::OAI::Record( %opts )

This constructor method returns a new L<HTTP::OAI::Record> object.

Options (see methods below):

	header => $header
	metadata => $metadata
	about => [$about]

=item $r->header([HTTP::OAI::Header])

Returns and optionally sets the record header (an L<HTTP::OAI::Header> object).

=item $r->metadata([HTTP::OAI::Metadata])

Returns and optionally sets the record metadata (an L<HTTP::OAI::Metadata> object).

=item $r->about([HTTP::OAI::Metadata])

Optionally adds a new About record (an L<HTTP::OAI::Metadata> object) and returns an array of objects (may be empty).

=back

=head2 Header Accessor Methods

These methods are equivalent to C<< $rec->header->$method([$value]) >>.

=over 4

=item $r->identifier([$identifier])

Get and optionally set the record OAI identifier.

=item $r->datestamp([$datestamp])

Get and optionally set the record datestamp.

=item $r->status([$status])

Get and optionally set the record status (valid values are 'deleted' or undef).

=item $r->is_deleted()

Returns whether this record's status is deleted.

=back
