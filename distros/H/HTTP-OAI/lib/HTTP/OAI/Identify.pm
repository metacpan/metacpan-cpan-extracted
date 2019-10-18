package HTTP::OAI::Identify;

@ISA = qw( HTTP::OAI::Verb );

use strict;

our $VERSION = '4.10';

use HTTP::OAI::SAXHandler qw( :SAX );

sub adminEmail { shift->_elem('adminEmail',@_) }
sub baseURL { shift->_elem('baseURL',@_) }
sub compression { shift->_multi('compression',@_) }
sub deletedRecord { shift->_elem('deletedRecord',@_) }
sub description { shift->_multi('description',@_) }
sub earliestDatestamp { shift->_elem('earliestDatestamp',@_) }
sub granularity { shift->_elem('granularity',@_) }
sub protocolVersion { shift->_elem('protocolVersion',@_) }
sub repositoryName { shift->_elem('repositoryName',@_) }

sub next {
	my $self = shift;
	return shift @{$self->{description}};
}

sub generate_body
{
	my( $self, $driver ) = @_;

	for(qw( repositoryName baseURL protocolVersion adminEmail earliestDatestamp deletedRecord granularity compression ))
	{
		foreach my $value ($self->$_)
		{
			$driver->data_element( $_, $value );
		}
	}

	for($self->description) {
		$_->generate( $driver );
	}
}

sub start_element {
	my ($self,$hash,$r) = @_;
	my $elem = lc($hash->{LocalName});
	if( $elem eq 'description' && !$self->{"in_$elem"} ) {
		$self->set_handler(my $desc = HTTP::OAI::Metadata->new);
		$self->description([$self->description, $desc]);
		$self->{"in_$elem"} = $hash->{Depth};
	}
	$self->SUPER::start_element($hash,$r);
}

sub end_element {
	my ($self,$hash,$r) = @_;
	my $elem = $hash->{LocalName};
	my $text = $hash->{Text};
	if( defined $text )
	{
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
	}
	$self->SUPER::end_element($hash,$r);
	if( defined($self->get_handler) ) {
		if( $elem eq 'description' && $self->{"in_$elem"} == $hash->{Depth} ) {
			$self->set_handler( undef );
			$self->{"in_$elem"} = 0;
		}
	} elsif( $elem eq 'adminEmail' ) {
		$self->adminEmail($text);
	} elsif( $elem eq 'compression' ) {
		$self->compression($text);
	} elsif( $elem eq 'baseURL' ) {
		$self->baseURL($text);
	} elsif( $elem eq 'protocolVersion' ) {
		$text = '2.0' if $text =~ /\D/ or $text < 2.0;
		$self->protocolVersion($text);
	} elsif( defined($text) && length($text) ) {
		$self->_elem($elem,$text);
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::Identify - Provide access to an OAI Identify response

=head1 SYNOPSIS

	use HTTP::OAI::Identify;

	my $i = new HTTP::OAI::Identify(
		adminEmail=>'billg@microsoft.com',
		baseURL=>'http://www.myarchives.org/oai',
		repositoryName=>'www.myarchives.org'
	);

	for( $i->adminEmail ) {
		print $_, "\n";
	}

=head1 METHODS

=over 4

=item $i = new HTTP::OAI::Identify(-baseURL=>'http://arXiv.org/oai1'[, adminEmail=>$email, protocolVersion=>'2.0', repositoryName=>'myarchive'])

This constructor method returns a new instance of the OAI::Identify module.

=item $i->version

Return the original version of the OAI response, according to the given XML namespace.

=item $i->headers

Returns an HTTP::Headers object. Use $headers->header('headername') to retrive field values.

=item $burl = $i->baseURL([$burl])

=item $eds = $i->earliestDatestamp([$eds])

=item $gran = $i->granularity([$gran])

=item $version = $i->protocolVersion($version)

=item $name = $i->repositoryName($name)

Returns and optionally sets the relevent header. NOTE: protocolVersion will always be '2.0'. Use $i->version to find out the protocol version used by the repository.

=item @addys = $i->adminEmail([$email])

=item @cmps = $i->compression([$cmp])

Returns and optionally adds to the multi-value headers.

=item @dl = $i->description([$d])

Returns the description list and optionally appends a new description $d. Returns an array ref of L<HTTP::OAI::Description|HTTP::OAI::Description>s, or an empty ref if there are no description.

=item $d = $i->next

Returns the next description or undef if no more description left.

=item $dom = $i->toDOM

Returns a XML::DOM object representing the Identify response.

=back
