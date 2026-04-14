package Enum::Declare::Common::Status;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Lifecycle :Str :Type :Export {
	Pending   = "pending",
	Active    = "active",
	Inactive  = "inactive",
	Suspended = "suspended",
	Deleted   = "deleted",
	Archived  = "archived"
};

1;

=head1 NAME

Enum::Declare::Common::Status - Lifecycle status string constants

=head1 SYNOPSIS

    use Enum::Declare::Common::Status;

    say Pending;    # "pending"
    say Active;     # "active"
    say Archived;   # "archived"

    my $meta = Lifecycle();
    ok($meta->valid('active'));

=head1 ENUMS

=head2 Lifecycle :Str :Export

Pending="pending", Active="active", Inactive="inactive",
Suspended="suspended", Deleted="deleted", Archived="archived".

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
