package Testophile;

use v5.8;

use Test::More tests => 2;

BEGIN   { mkdir './blib/foo', 0555  }
END     { rmdir './blib/foo'        }

require FindBin::libs;

FindBin::libs->import( qw( base=blib subdir=foo subonly ) );

# Note: Old test uses File::Spec::catpath to compose a subdir
# for comparision. Catch is that windoze can't decide which
# slashes to use and end returning with C:/foo/bar on some
# systems C:\foo\bar on others and catpath is consistent. 
# Fix is replacing the literal with a regex; less specific 
# test but should work well enough for the purpose.

for my $expect ( qr{ \W blib \W foo $ }x )
{
    like $INC[0], $expect, "Found only foo subdir ($INC[0])";
}

FindBin::libs->import;

for my $expect ( qr{ \W lib $ }x )
{
    like $INC[0], $expect, "Added lib dir ($INC[0])";
}

__END__
