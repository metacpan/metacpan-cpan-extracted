#!/usr/bin/perl

package Mail::Summary::Tools::ArchiveLink::Base;
use Moose::Role;

with "Mail::Summary::Tools::ArchiveLink";

has message_id => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ArchiveLink::Base - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::ArchiveLink::Base;

=head1 DESCRIPTION

=cut


