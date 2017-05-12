#!/usr/bin/perl

package Log::Dispatch::Binlog::Base;

use strict;

use Storable qw(nstore_fd);

sub new { die "abstract class" }

sub _storable_print {
	my ( $self, $fh, $p ) = @_;
	nstore_fd( $p, $fh );
}

__PACKAGE__

__END__
