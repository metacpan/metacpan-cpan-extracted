package Enum::Declare::Common::Bool;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum YesNo :Str :Type :Export {
	Yes = "yes",
	No  = "no"
};

enum OnOff :Str :Type :Export {
	On  = "on",
	Off = "off"
};

enum TrueFalse :Type :Export {
	True  = 1,
	False = 0
};

1;

=head1 NAME

Enum::Declare::Common::Bool - Boolean enum variants

=head1 SYNOPSIS

    use Enum::Declare::Common::Bool;

    say Yes;    # "yes"
    say On;     # "on"
    say True;   # 1
    say False;  # 0
    say Zero;   # 0
    say One;    # 1

=head1 ENUMS

=head2 YesNo :Str :Export

Yes="yes", No="no".

=head2 OnOff :Str :Export

On="on", Off="off".

=head2 TrueFalse :Export

True=1, False=0.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
