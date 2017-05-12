#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink;
use Moose::Role;

# FIXME Moose 0.12

#requires "thread_uri";

#requires "message_uri";

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink - Base role for links to archives.

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::Gmane;

	my $l = Mail::Summary::Tools::ArchiveLink::Gmane->new( message_id => "..." );

	print $l->thread_uri;

=head1 DESCRIPTION

=cut


