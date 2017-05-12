#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink::GoogleGroups;
use Moose;

with "Mail::Summary::Tools::ArchiveLink::Base";

use WWW::Mechanize;
use URI;
use URI::QueryParam;

sub message_uri {
	my $self = shift;

	my $uri = URI->new("http://groups.google.com/groups");
	$uri->query_param( selm => $self->message_id );

	$uri;
}

sub thread_uri { } # FIXME Moose role composition
has thread_uri => (
	isa => "URI",
	is  => "ro",
	lazy => 1,
	default => sub { $_[0]->_thread_uri }
);

has use_frames => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has cache => (
	isa => "Object",
	is  => "rw",
	required => 0,
);

sub cache_key {
	my $self = shift;

	join(":",
		qw/archive_links google_groups/,
		$self->message_id,
	);
}

sub _munge_thread_uri {
	my ( $self, $uri ) = @_;
	$uri =~ s/browse_thread/browse_frm/ if $self->use_frames;
	return $uri;
}

sub _thread_uri {
	my $self = shift;

	my $uri = $self->_find_thread_uri || return;
	
	URI->new( $self->_munge_thread_uri($uri) );
}

sub _find_thread_uri {
	my ( $self, $message_id ) = @_;

	my $cache = $self->cache;

	my $cache_key = $self->cache_key;

	if ( my $uri = $cache && $cache->get($cache_key) ) {
		return $uri;
	} else {
		my $m = WWW::Mechanize->new;

		my $uri = $self->message_uri;

		$m->get( $uri, 'user-agent' => "Mozilla" );

		if ( my $link = $m->find_link( url_regex => qr#browse_(?:thread|frm)/thread/# ) ) {
			my $uri = $link->url_abs->as_string;
			$cache && $cache->set( $cache_key, $uri );
			return $uri
		}
	}

	warn "no thread_uri for " . $self->message_id . ", falling back to gmane";

	require Mail::Summary::Tools::ArchiveLink::Easy;
	return Mail::Summary::Tools::ArchiveLink::Easy->gmane( $self->message_id )->thread_uri;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink::GoogleGroups - Link to Google Groups via message ID.

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::GoogleGroups;

	my $link = Mail::Summary::Tools::ArchiveLink::GoogleGroups->new(
		message_id => ".....",
	);

	$link->thread_uri;
	$link->message_uri;

=head1 DESCRIPTION

=cut


