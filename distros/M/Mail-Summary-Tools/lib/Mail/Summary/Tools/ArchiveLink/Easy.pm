#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink::Easy;

use strict;
use warnings;

sub google {
	my ( $class, $msg, @extra ) = @_;
	require Mail::Summary::Tools::ArchiveLink::GoogleGroups;
	Mail::Summary::Tools::ArchiveLink::GoogleGroups->new( message_id => $msg, @extra );
}

sub gmane {
	my ( $class, $msg, @extra ) = @_;
	require Mail::Summary::Tools::ArchiveLink::Gmane;
	Mail::Summary::Tools::ArchiveLink::Gmane->new( message_id => $msg, @extra );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink::Easy - Easy constructors for archive links.

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::Easy;

	# choose a service
	my $link = Mail::Summary::Tools::ArchiveLink::Easy->gmane( $msg_id );
	my $link = Mail::Summary::Tools::ArchiveLink::Easy->google( $msg_id );
	
	# link to the message/thread
	$link->thread_uri;
	$link->message_uri;

=head1 DESCRIPTION

=cut


