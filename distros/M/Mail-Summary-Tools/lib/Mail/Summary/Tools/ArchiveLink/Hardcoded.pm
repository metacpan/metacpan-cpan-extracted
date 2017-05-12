#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink::Hardcoded;
use Moose;
use Moose::Util::TypeConstraints;

use URI;

subtype __PACKAGE__ . "::URI"
	=> as "Object"
	=> where { $_->isa("URI") };

coerce __PACKAGE__ . "::URI"
	=> from "Str"
	=> via { URI->new($_[0]) };

has thread_uri => (
	isa => __PACKAGE__ . "::URI",
	is  => "rw",
	coerce => 1,
);

has message_uri => (
	isa => __PACKAGE__ . "::URI",
	is  => "rw",
	coerce => 1,
);

with "Mail::Summary::Tools::ArchiveLink";

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink::Hardcoded - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::Hardcoded;

=head1 DESCRIPTION

=cut


