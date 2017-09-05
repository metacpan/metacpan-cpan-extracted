package HTTP::OAI::SAX::Trace;

#use base XML::SAX::Base;

our $AUTOLOAD;

our $VERSION = '4.06';

sub new
{
	my( $class, %self ) = @_;
	bless \%self, $class;
}

sub DESTROY {}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
HTTP::OAI::Debug::sax( $AUTOLOAD . ": " . Data::Dumper::Dumper( @_[1..$#_] ) );
	shift->{Handler}->$AUTOLOAD( @_ );
}

1;
