use strict;
use warnings;

use Test::More tests => 6;

my $class = 'Mac::PropertyList::ReadBinary';
use_ok( $class );
can_ok( $class, qw(new _get_filehandle) );
use Scalar::Util qw(openhandle);

{
my $self = bless { source => 'Makefile.PL'  }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}

{
my $self = bless { source => 'not_there'  }, $class;
my $fh = eval { $self->_get_filehandle };
ok( ! openhandle( $fh ), q(Didn't get a defined filehandle) );
}


{
my $string    = '<xml>';
open my $string_fh, '<', \ $string; 
my $self = bless { source => $string_fh  }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}


{
my $self = bless { source => \ '<xml>'   }, $class;
my $fh = $self->_get_filehandle;
ok( openhandle( $fh ), 'Got a defined filehandle' );
}
