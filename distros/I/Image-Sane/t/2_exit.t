use warnings;
use strict;
use English;
use Test::Requires qw( v5.10 );
use Test::More tests => 1;

#########################

my $pl = <<'END';
use strict;
use warnings;
use Image::Sane ':all';
$Image::Sane::DEBUG = 1;
Image::Sane->get_version_scalar;
END

my $fname = 'examples/exit.pl';
open my $fh, '>', $fname;
print $fh $pl;
close $fh;
my $exe = "PERL5LIB=\"blib:blib/arch:lib:\$PERL5LIB\" $EXECUTABLE_NAME $fname";
my $output = `$exe`;
like $output, qr/Exiting via sane_exit/, 'sane_exit() reached';
unlink $fname;
