########################################################################
# housekeeping
########################################################################
use v5.36;

use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# Only the #! code may supply a filter.  A caller in any other file is
# simulated by compiling the import call under a different file name
# with a #line directive, which is what caller reports.  Every call
# here is refused, so this file ends with no filter set.

use File::Util::SecureDir;

my $pkg     = 'File::Util::SecureDir';
my $script  = $0;

########################################################################
# filter from a file other than the #! code
########################################################################

my @casez
= (
    {
        name    => 'filter=all from a module is refused'
      , file    => 'Other/Module.pm'
      , arg     => 'filter=all'
    }
  , {
        name    => 'filter=same_owner from a module is refused'
      , file    => 'Other/Module.pm'
      , arg     => 'filter=same_owner'
    }
  , {
        name    => 'bare filter from a module is refused'
      , file    => 'Other/Module.pm'
      , arg     => 'filter'
    }
  , {
        name    => 'filter=all from a similar name (script plus a suffix)'
      , file    => "${script}.pm"
      , arg     => 'filter=all'
    }
  , {
        name    => 'filter=all from a similar name (script minus a suffix)'
      , file    => substr( $script, 0, -1 )
      , arg     => 'filter=all'
    }
  , {
        name    => 'filter=all from a string eval'
      , file    => '(eval 1)'
      , arg     => 'filter=all'
    }
);

for my $case ( @casez )
{
    my ( $name, $file, $arg ) = @{ $case }{ qw( name file arg ) };

    eval "\n#line 1 \"$file\"\n$pkg->import( '$arg' ); 1";

    like $@, qr{ can \s only \s be \s set \s from }x, $name;
}

########################################################################
# the message names the expected file
########################################################################

eval "\n#line 1 \"Other/Module.pm\"\n$pkg->import( 'filter=all' ); 1";

like $@, qr{ from \s '\Q$script\E' }x, 'refusal names the #! file';

like $@, qr{ not \s 'Other/Module[.]pm' }x, 'refusal names the caller';

########################################################################
# a refused import leaves nothing behind
########################################################################

is $pkg->filter, '', 'refused imports: no filter was chosen';

done_testing;
