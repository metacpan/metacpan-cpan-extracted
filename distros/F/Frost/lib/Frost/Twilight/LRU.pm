package Frost::Twilight::LRU;

use strict;
use warnings;

use base qw(Tie::Cache::LRU::Array);

use constant SUCCESS	=> Tie::Cache::LRU::Array::SUCCESS;
use constant FAILURE	=> Tie::Cache::LRU::Array::FAILURE;

use constant KEY		=> Tie::Cache::LRU::Array::KEY;
use constant VALUE	=> Tie::Cache::LRU::Array::VALUE;
use constant PREV		=> Tie::Cache::LRU::Array::PREV;
use constant NEXT		=> Tie::Cache::LRU::Array::NEXT;

our $VERSION	= 0.65;
our $AUTHORITY	= 'cpan:ERNESTO';

sub TIEHASH
{
	my ( $class, $max_size, $twilight ) = @_;

	my $self	= $class->SUPER::TIEHASH ( $max_size );

	$self->{twilight}	= $twilight		if defined $twilight;

	return $self;
}

sub _cull
{
	my($self) = @_;

	my $max_size = $self->max_size;
	my $cache = $self->{cache};

	$self->_reorder_cache		if $#$cache > $self->{size} * 2;

	my $idx = $self->{low_idx};
	my $cache_size = $#{$cache};

	for( ; $self->{size} > $max_size; $self->{size}-- )
	{
		my $node;
		do
		{
			$node = $cache->[++$idx];
		}
		until defined $node or $idx > $cache_size;

		if ( exists $self->{twilight} )
		{
			my $param		= $cache->[$self->{index}{$node->[KEY]}];

			$self->{twilight}->_cull_callback ( $param );
		}

		delete $self->{index}{$node->[KEY]};

		$cache->[$idx] = undef;
	}

	$self->{low_idx} = $idx;

	return SUCCESS;
}

1;

__END__

=head1 NAME

Frost::Twilight::LRU - The voice of one crying in the wilderness

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=head1 CLASS VARS

=over 4

=item SUCCESS

=item FAILURE

=item KEY

=item VALUE

=item PREV

=item NEXT

=back

=for comment CLASS METHODS

=for comment PUBLIC ATTRIBUTES

=for comment PRIVATE ATTRIBUTES

=head1 CONSTRUCTORS

=head2 Frost::Twilight::LRU->TIEHASH ( $max_size, $twilight )

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 _cull()

=for comment PRIVATE METHODS

=for comment CALLBACKS

=for comment IMMUTABLE

=head1 GETTING HELP

I'm reading the Moose mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
