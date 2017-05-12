#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/lib/FileGatherer.pm
#
#   This file is part of perl-Dist-Zilla-Role-ErrorLogger.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#   This is a trivial plugin which allows a test to execute arbitrary code at `gather files` phase.
#   Test should save reference to code to be executed in `$FileGatherer::Hook` variable.

package FileGatherer;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::ErrorLogger';

our $Hook;

sub gather_files {
    my ( $self ) = @_;
    if ( defined( $Hook ) ) {
        $Hook->( $self );
    };
    return;
};

__PACKAGE__->meta->make_immutable;

1;

# end of file #
