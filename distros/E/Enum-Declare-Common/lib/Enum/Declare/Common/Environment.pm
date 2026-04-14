package Enum::Declare::Common::Environment;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Env :Str :Type :Export {
	Development = "development",
	Staging     = "staging",
	Production  = "production",
	Testing     = "testing"
};

1;

=head1 NAME

Enum::Declare::Common::Environment - Application environment name constants

=head1 SYNOPSIS

    use Enum::Declare::Common::Environment;

    say Development;  # "development"
    say Production;   # "production"

    if ($env eq Production) { ... }

=head1 ENUMS

=head2 Env :Str :Export

Development="development", Staging="staging", Production="production",
Testing="testing".

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
