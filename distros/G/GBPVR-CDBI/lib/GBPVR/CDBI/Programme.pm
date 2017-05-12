package GBPVR::CDBI::Programme;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'GBPVR::CDBI';

__PACKAGE__->table('programme');
__PACKAGE__->columns(Primary => qw/oid/ );
__PACKAGE__->columns(All => qw/
	oid
	name
	sub_title
	description
	start_time
	end_time
	channel_oid
	unique_identifier
/ );
__PACKAGE__->has_a( channel_oid => 'GBPVR::CDBI::Channel');

1;

__END__

=head1 NAME

GBPVR::CDBI::Programme - GBPVR.programme table

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

=head1 ATTRIBUTES

oid, name, sub_title, description, start_time, end_time, channel_oid, unique_identifier

=head1 FOREIGN KEYS

        channel_oid => L<GBPVR::CDBI::Channel>

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

