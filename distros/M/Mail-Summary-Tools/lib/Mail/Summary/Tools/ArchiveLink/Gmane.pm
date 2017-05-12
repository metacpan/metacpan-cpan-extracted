#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink::Gmane;
use Moose;

use URI;
use URI::QueryParam;

with "Mail::Summary::Tools::ArchiveLink::Base";

sub message_uri {
	my $self = shift;

	my $uri = URI->new( 'http://mid.gmane.org/' );
	$uri->path( $self->message_id );

	return $uri;
}

sub thread_uri {
	my $self = shift;

	my $uri = URI->new( 'http://news.gmane.org/find-root.php' );
	$uri->query_param( message_id => sprintf( '<%s>', $self->message_id ) );

	return $uri;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink::Gmane - Link to Gmane archives via message ID.

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::Gmane;

	my $link = Mail::Summary::Tools::ArchiveLink::Gmane->new(
		message_id => ".....",
	);

	$link->thread_uri;
	$link->message_uri;

=head1 DESCRIPTION

=cut


