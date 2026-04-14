package Enum::Declare::Common::Permission;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Bit :Flags :Type :Export {
	Execute,
	Write,
	Read
};

enum Mask :Type :Export {
	OwnerRead     = 256,
	OwnerWrite    = 128,
	OwnerExecute  = 64,
	GroupRead     = 32,
	GroupWrite    = 16,
	GroupExecute  = 8,
	OtherRead     = 4,
	OtherWrite    = 2,
	OtherExecute  = 1
};

1;

=head1 NAME

Enum::Declare::Common::Permission - Unix permission bits and masks

=head1 SYNOPSIS

    use Enum::Declare::Common::Permission;

    # Flags
    my $rwx = Read | Write | Execute;  # 7
    my $rw  = Read | Write;            # 6

    # Mask constants for chmod-style values
    my $mode = OwnerRead | OwnerWrite | OwnerExecute
             | GroupRead | GroupExecute
             | OtherRead | OtherExecute;  # 0755

=head1 ENUMS

=head2 Bit :Flags :Export

Execute=1, Write=2, Read=4. Combinable with bitwise OR.

=head2 Mask :Export

OwnerRead=256, OwnerWrite=128, OwnerExecute=64, GroupRead=32,
GroupWrite=16, GroupExecute=8, OtherRead=4, OtherWrite=2,
OtherExecute=1.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
