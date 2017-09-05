package HTTP::OAI::GetRecord;

require HTTP::OAI::ListRecords;
@ISA = qw( HTTP::OAI::ListRecords );

use strict;

our $VERSION = '4.06';

sub record
{
	my $self = shift;
	$self->{item} = [@_] if @_;
	return $self->{item}->[0];
}

sub generate_body {
	my ($self, $driver) = @_;

	for( $self->record ) {
		$_->generate( $driver );
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::GetRecord - An OAI GetRecord response

=head1 DESCRIPTION

HTTP::OAI::GetRecord is derived from L<HTTP::OAI::Response|HTTP::OAI::Response> and provides access to the data contained in an OAI GetRecord response in addition to the header information provided by OAI::Response.

=head1 SYNOPSIS

	use HTTP::OAI::GetRecord();

	$res = new HTTP::OAI::GetRecord();
	$res->record($rec);

=head1 METHODS

=over 4

=item $gr = new HTTP::OAI::GetRecord

This constructor method returns a new HTTP::OAI::GetRecord object.

=item $rec = $gr->next

Returns the next record stored in the response, or undef if no more record are available. The record is returned as an L<OAI::Record|OAI::Record>.

=item @recs = $gr->record([$rec])

Returns the record list, and optionally adds a record to the end of the queue. GetRecord will only store one record at a time, so this method will replace any existing record if called with argument(s).

=item $dom = $gr->toDOM()

Returns an XML::DOM object representing the GetRecord response.

=back
