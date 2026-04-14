package Enum::Declare::Common::Sort;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Direction :Str :Type :Export {
	Asc  = "asc",
	Desc = "desc"
};

enum NullHandling :Str :Type :Export {
	NullsFirst = "nulls_first",
	NullsLast  = "nulls_last"
};

1;

=head1 NAME

Enum::Declare::Common::Sort - Sort direction and null handling enums

=head1 SYNOPSIS

    use Enum::Declare::Common::Sort;

    say Asc;         # "asc"
    say Desc;        # "desc"
    say NullsFirst;  # "nulls_first"
    say NullsLast;   # "nulls_last"

=head1 ENUMS

=head2 Direction :Str :Export

Asc="asc", Desc="desc".

=head2 NullHandling :Str :Export

NullsFirst="nulls_first", NullsLast="nulls_last".

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
