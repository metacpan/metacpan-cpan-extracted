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

# Every import here is refused, so no filter is ever chosen: this file
# ends with none set.  The calls come from this file, which is the #!
# code, so only the argument checks are exercised (see 04- for callers).

use File::Util::SecureDir;

my $pkg = 'File::Util::SecureDir';

########################################################################
# unknown arguments
########################################################################

my @argz_casez
= (
    {
        name    => 'unknown argument: bare word'
      , arg     => 'bogus'
    }
  , {
        name    => 'unknown argument: wrong case'
      , arg     => 'Filter=all'
    }
  , {
        name    => 'unknown argument: leading space'
      , arg     => ' filter'
    }
  , {
        name    => 'unknown argument: colon in place of ='
      , arg     => 'filter:all'
    }
  , {
        name    => 'unknown argument: empty string'
      , arg     => ''
    }
  , {
        name    => 'unknown argument: key with a suffix'
      , arg     => 'verbosity'
    }
);

for my $case ( @argz_casez )
{
    my ( $name, $arg ) = @{ $case }{ qw( name arg ) };

    eval { $pkg->import( $arg ); 1 };

    like $@, qr{ unknown \s '\Q$arg\E' }x, $name;
}

########################################################################
# unknown filter names
########################################################################

my @name_casez
= (
    {
        name    => 'unknown filter: bogus'
      , arg     => 'filter=bogus'
      , like    => qr{ unknown \s 'bogus' }x
    }
  , {
        name    => 'unknown filter: wrong case'
      , arg     => 'filter=ALL'
      , like    => qr{ unknown \s 'ALL' }x
    }
  , {
        name    => 'unknown filter: same_group does not exist'
      , arg     => 'filter=same_group'
      , like    => qr{ unknown \s 'same_group' }x
    }
  , {
        name    => 'unknown filter: the message lists the valid names'
      , arg     => 'filter=bogus'
      , like    => qr{ valid: \s all \s other_no_write
                       \s group_no_write \s same_owner }x
    }
);

for my $case ( @name_casez )
{
    my ( $name, $arg, $like ) = @{ $case }{ qw( name arg like ) };

    eval { $pkg->import( $arg ); 1 };

    like $@, $like, $name;
}

########################################################################
# a refused import leaves nothing behind
########################################################################

is $pkg->filter, '', 'refused imports: no filter was chosen';

done_testing;
