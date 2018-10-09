package IO::Handle::Util::Overloading;

use strict;
use warnings;

our $VERSION = '0.02';

use asa 'IO::Handle';

use overload (
    '*{}' => sub {
        my $self = shift;
        require IO::Handle::Util;
        return IO::Handle::Util::io_to_glob($self);
    },

    # to quote overload.pm
    #
    #   BUGS Even in list context, the iterator is currently called only
    #   once and with scalar context.
    #
    #'<>' => sub {
    #    if ( wantarray ) {
    #        shift->getlines;
    #    } else {
    #        shift->getline;
    #    }
    #},

    fallback => 1,
);

# ex: set sw=4 et:

__PACKAGE__

__END__
