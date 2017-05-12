use 5.006;    #our
use strict;
use warnings;

package My::Project::Logger;

our $VERSION = '0.001000';

use parent 'Log::Contextual';

sub arg_default_logger {
    return $_[1] if $_[1];
    require Log::Contextual::WarnLogger::Fancy;
    my $caller  = caller(3);
    my $package = uc($caller);
    $package =~ s/::/_/g;
    return Log::Contextual::WarnLogger::Fancy->new(
        env_prefix       => $package,
        group_env_prefix => 'MY_PROJECT',
        label            => $caller,
        default_upto     => 'warn',
    );
}

sub default_import { qw( :dlog :log ) }

1;
