package I22r::Translate::Result;
use Moose;

our $VERSION = '0.96';

has id => ( is => 'ro', isa => 'Str', required => 1 );
has olang => ( is => 'ro', isa => 'Str', required => 1,  );
has otext => ( is => 'ro', isa => 'Str', required => 1 );
has lang => ( is => 'ro', isa => 'Str', required => 1, );
has text => ( is => 'ro', isa => 'Str', required => 1 );
has source => ( is => 'ro', isa => 'Str', required => 1,
    default => sub {
	my $name = caller(1);
	$name =~ s/.*:://;
	$name;
		} );
has length => ( is => 'ro', isa => 'Int' );
has time => ( is => 'ro', isa => 'Int' );

sub to_hash {
    my $self = shift;
    my $h = { };
    $h->{uc $_} = $self->{$_} for keys %$self;
    return $h;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

I22r::Translate::Result - translation result object

=head1 DESCRIPTION

Internal translation result object for the
L<I22r::Translate> distribution. 
If you're not developing a backend for this distribution,
you probably don't need to worry about what this class does.
If you are developing a backend, you can just look at
the source.

=head1 SEE ALSO

L<I22r::Translate>

=cut
