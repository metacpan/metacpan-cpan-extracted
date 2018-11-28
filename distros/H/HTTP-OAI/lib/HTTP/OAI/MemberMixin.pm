package HTTP::OAI::MemberMixin;

@ISA = qw( LWP::MemberMixin );

our $VERSION = '4.08';

sub new
{
	my( $class, %self ) = @_;
	return bless \%self, $class;
}

sub harvester { shift->_elem("harvester",@_) }

sub _multi
{
	my( $self, $elem ) = splice(@_, 0, 2);
	if( ref($_[0]) eq "ARRAY" )
	{
		$self->{$elem} = $_[0];
	}
	elsif( @_ )
	{
		push @{$self->{$elem}}, @_;
	}
	return @{$self->{$elem} || []};
}

1;

__END__

=head1 NAME

HTTP::OAI::MemberMixin

=head1 DESCRIPTION

Subclasses L<LWP::MemberMixin> to provide attribute utility methods.

=head1 METHODS

=over 4

=item $obj->_elem( FIELD [, VALUE ] )

See L<LWP::MemberMixin/_elem>.

=item $obj->_multi( FIELD [, VALUE ] )

Same as L</_elem> but if you pass a non-ARRAY reference appends the given value(s).

In list context returns a list of all the items.

=back
