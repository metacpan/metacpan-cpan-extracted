#!perl -T

use strict;
use warnings;
use IO::Handle ();
use File::Basename ();
use File::Spec ();
use Scalar::Util qw(tainted);
use Test::More;

BEGIN {
    plan skip_all => 'Taint was always terrible. Just stop it already.';
    exit;
    # Taint mode is the devil. THE DEVIL I SAY
    unshift @INC, File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib') =~ /^(.*)$/;
    # Why on earth do we keep on with Taint mode?!? I hate all the things
}

use FileSlurpTest qw(temp_file_path trap_function trap_function_list_context);
use File::Slurp qw(read_file);

plan tests => 9;

my $path = temp_file_path();
my $data = "random junk\nline2";

# write something to that file
open(my $fh, ">", $path) or die "can't write to '$path': $!";
$fh->print($data);
$fh->close();

# read the file using File::Slurp in scalar context
my ($res, $warn, $err) = trap_function(\&read_file, $path);
ok(!$warn, "read_file: taint on - no warnings");
ok(!$err, "read_file: taint on - no exceptions");
ok($res, "read_file: taint on - got content");
ok(tainted($res), "read_file: taint on - got tainted content");

# read the file using File::Slurp in list context
my $aref;
($aref, $warn, $err) = trap_function_list_context(\&read_file, $path);
ok(!$warn, "read_file: list context, taint on - no warnings");
ok(!$err, "read_file: list context, taint on - no exceptions");
ok(@{$aref}, "read_file: list context, taint on - got content");
ok(tainted($aref->[0]), "read_file: list context, taint on - got tainted content");

is(join('', @{$aref}), $res, "list eq scalar");

unlink $path;
