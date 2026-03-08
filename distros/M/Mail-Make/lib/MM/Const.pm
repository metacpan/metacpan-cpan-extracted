##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/MM/Const.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/03
## Modified 2026/03/03
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package MM::Const;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use Exporter qw( import );
    our @EXPORT_OK   = qw( OVERLAP_TABLES_SET OVERLAP_TABLES_MERGE );
    our %EXPORT_TAGS = (
        table => [ @EXPORT_OK ],
    );
    # Values don't matter outside APR; they must just be stable and comparable.
    use constant {
        OVERLAP_TABLES_SET      => 0,
        OVERLAP_TABLES_MERGE    => 1,
    };
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

MM::Const - APR::Const-like constants for MM::Table

=head1 SYNOPSIS

    use MM::Const qw( :table );
    # or:
    use MM::Const qw( OVERLAP_TABLES_SET OVERLAP_TABLES_MERGE );

=head1 CONSTANTS

=over 4

=item * OVERLAP_TABLES_SET

=item * OVERLAP_TABLES_MERGE

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
