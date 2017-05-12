
use strict;
use warnings;

use Test::More;

if ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{AUTHOR_TESTS} )
{                            # the tests in this file have a higher probability
   plan tests => 8;          # of failing in the wild, and so are reserved for
                             # the author/maintainers as release tests
   CORE::eval # hide the eval...
   '
use Test::NoWarnings;
   '; # ...from dist parsers
}
else
{
   plan skip_all => 'these tests are for release candidate testing';
}

use lib './lib';
use File::Util;

use vars qw( $stderr_str $callback_err $sig_warn );

# one recognized instantiation setting
my $ftl = File::Util->new( );

my $err_msg = $ftl->write_file( undef, { onfail => 'message' } );

steal_stderr();

$ftl->write_file( undef, { onfail => 'warn'  } );

return_stderr();

$ftl->write_file( undef, { onfail => \&fail_callback  } );

my $die_err   = '';

{
   local $@;

   eval { $ftl->write_file( undef, { onfail => 'die' } ); };

   $die_err = $@;
}

clean_err( \$stderr_str );
clean_err( \$err_msg );
clean_err( \$callback_err );
clean_err( \$die_err );

like $stderr_str, qr/File::Util/,
   'warning message captured';

like $err_msg, qr/File::Util/,
   'error message captured';

is $stderr_str, $err_msg,
   'warning message is the same as error message';

is $stderr_str, $callback_err,
   'callback error is the same as error message';

is $stderr_str, $die_err,
   'die() message is the same as error message';

is $ftl->write_file( undef, { onfail => 'zero' } ),
   0, 'onfail => "zero" returns 0';

is $ftl->write_file( undef, { onfail => 'undefined' } ),
   undef, 'onfail => "undefined" returns undef';

exit;

sub fail_callback {
   my ( $err, $stack ) = @_;
   $callback_err = "\n" . $err . $stack;
   return;
};

sub steal_stderr {
   $sig_warn = $SIG{__WARN__};
   $SIG{__WARN__} = sub { $stderr_str .= join '', @_; return };
   return;
}

sub return_stderr {
   $SIG{__WARN__} = $sig_warn;
   return;
}

sub clean_err {
   my $err = shift @_;
   $$err =~ s/^\n+//;
   $$err =~ s/^.*called at line.*$//mg;
   $$err =~ s/\n2\. .*//sm; # delete everything after stack frame 1
   chomp $$err;
   return;
}

