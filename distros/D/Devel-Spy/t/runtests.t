#!perl -w
use strict;
use warnings;

use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir );
use Cwd qw( abs_path );
use constant DIR => dirname( __FILE__ );
use lib abs_path( catdir( DIR, 'lib' ) );

use Carp ();

BEGIN { $SIG{__WARN__} = \&Carp::cluck }

use Devel::Spy::Test;

Test::Class->runtests;
