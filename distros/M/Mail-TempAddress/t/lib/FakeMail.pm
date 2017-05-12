package FakeMail;

use strict;
use vars '$AUTOLOAD';
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

sub AUTOLOAD
{
	my $self  = shift;
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD eq 'DESTROY';
	return unless exists $self->{$AUTOLOAD};

	my $value = $self->{$AUTOLOAD};
	return $value if ( reftype $value || '' ) ne 'ARRAY';
	return wantarray ? @$value : $value->[0];
}

1;
