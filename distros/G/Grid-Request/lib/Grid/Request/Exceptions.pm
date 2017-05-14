package Grid::Request::Exceptions;

use strict;
our $VERSION = '0.11';

use Exception::Class ( 'Grid::Request::Exception',
  'Grid::Request::InvalidArgumentException'=> { isa => "Grid::Request::Exception" },
  'Grid::Request::DRMAAException'=> { isa    => "Grid::Request::Exception",
                                      fields => [ "drmaa", "diagnosis" ],
                                    },

);

package Grid::Request::Exception;
use base qw(Exception::Class);

sub err_println {
    my $self = shift;
    warn $self->error() . "\n";
}

package Grid::Request::InvalidArgumentException;
use base qw(Grid::Request::Exception);

package Grid::Request::DRMAAException;
use base qw(Grid::Request::Exception);


1;
