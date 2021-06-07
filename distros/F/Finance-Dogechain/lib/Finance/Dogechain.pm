package Finance::Dogechain;
$Finance::Dogechain::VERSION = '1.20210605.1754';
use strict;
use warnings;

use Finance::Dogechain::Address;
use Finance::Dogechain::Block;
use Finance::Dogechain::Transaction;

sub Address     { return Finance::Dogechain::Address->new(     @_ ) }
sub Block       { return Finance::Dogechain::Block->new(       @_ ) }
sub Transaction { return Finance::Dogechain::Transaction->new( @_ ) }

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogechain - use the dogecoin.info API from Perl

=head1 SYNOPSIS

    my $address     = Finance::Dogechain::Address(     address        => '...' );
    my $block       = Finance::Dogechain::Block(       block_id       => '...' );
    my $transaction = Finance::Dogechain::Transaction( transaction_id => '...' );

These methods are helper wrappers for constructors for the actual objects
provided by this distribution.

See L<Finance::Dogechain::Address>, L<Finance::Dogechain::Block>, and L<Finance::Dogechain::Transaction>.

=head1 COPYRIGHT & LICENSE

Copyright 2021 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.32.

If you find this useful, feel free to tip the author: DPxuFc7dhNrTvNMCE53ENGF5g7LSGrzyYs.

=cut
