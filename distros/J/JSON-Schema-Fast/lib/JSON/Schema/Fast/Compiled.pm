package JSON::Schema::Fast::Compiled;

use strict;
use warnings;

our $VERSION = '0.03';

# A compiled schema: a blessed scalar holding the C arena IR pointer (the
# ecosystem convention for C-backed objects). Its methods are defined in XS
# (see Fast.xs) - validate/is_valid/errors arrive in later phases; DESTROY
# frees the arena. This file exists so the class has a home for POD and so the
# distribution is self-documenting; it deliberately contains no Perl-level
# method logic.

1;

__END__

=head1 NAME

JSON::Schema::Fast::Compiled - a compiled JSON Schema validator object

=head1 DESCRIPTION

Returned by C<< JSON::Schema::Fast->compile >>. Holds the arena IR for one
schema and validates Perl data against it. All behaviour lives in XS; see
L<JSON::Schema::Fast>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0 (GPL Compatible).

=cut
