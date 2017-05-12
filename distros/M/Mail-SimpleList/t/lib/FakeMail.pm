package FakeMail;

use strict;
use vars '$AUTOLOAD';

use Email::Address;
use Scalar::Util 'reftype';

sub new
{
	bless {}, $_[0];
}

sub open
{
	my ($self, $headers)     = @_;
	@$self{ keys %$headers } = values %$headers;
}

sub print
{
	my $self = shift;
	$self->{body} = join('', @_ );
}

sub close {}

sub raw_message
{
	my $self    = shift;
	my $body    = delete $self->{body};
	my $message;

	while (my ($header, $value) = each %{ $self })
	{
		$message .= "$header: $value\n";
	}

	$message .= "\n" . $body;

	return $message;
}

sub canonicalize_address
{
	my ($self, $address) = @_;

	return unless $address;

	if ( ( reftype( $address ) || '' ) eq 'ARRAY')
	{
		return [
			map {
				$_->address()
			}
			map {
				$_ ? Email::Address->parse( $_ ) : ()
			} @$address
		];
	}
	return ( Email::Address->parse( $address ) )[0]->address();
}

sub AUTOLOAD
{
	my $self  = shift;
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD eq 'DESTROY';

	my %address = map { $_ => 1 } qw( From To Bcc Cc Reply-To CC BCC );

	return                    unless        $self->{$AUTOLOAD};
	return $self->{$AUTOLOAD} unless exists $address{$AUTOLOAD};
	return $self->canonicalize_address( $self->{$AUTOLOAD} );
}

1;
