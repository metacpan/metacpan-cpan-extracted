package FakeIn;

use Symbol 'gensym';

sub new
{
	my $class  = shift;
	my $symbol = gensym();
	tie *$symbol, $class, @_;
	return $symbol;
}

sub TIEHANDLE
{
	my ($class, @lines) = @_;
	bless [ map { "$_$/"} @lines ], $class;
}

sub READLINE
{
	my $self = shift;
	return unless @$self;

	if (wantarray())
	{
		my @lines = @$self;
		@$self    = ();
		return @lines;
	}

	return join('', @$self) unless defined $/;
	return shift @$self;
}

sub FILENO
{
	1;
}

1;
