# t/set.t - set_* methods (for Gpx.pm)
use strict;
use warnings;

use Test::More tests => 22;
use Geo::Gpx;
use File::Temp qw/ tempfile tempdir /;
use Cwd qw(cwd abs_path);

my $cwd     = abs_path( cwd() );
my $tmp_dir = tempdir( CLEANUP => 1 );

my $o  = Geo::Gpx->new( input => 't/test.gpx');
isa_ok ($o,  'Geo::Gpx');

#
# set_filename()
mkdir 't/test_set_filename';
my $fname_initial = $o->set_filename();
my $wd_initial    = $o->set_wd();
is($o->set_filename('foo.txt'),       $cwd  . '/t/foo.txt',            "    set_filename(): should be in same folder");
is($o->set_filename('test_set_filename/foo.txt'),     $cwd . '/t/test_set_filename/foo.txt',"    set_filename(): should be in folder one level up");
is($o->set_filename('./foo.txt'),     $cwd  . '/t/foo.txt',            "    set_filename(): should be in same folder");
is($o->set_filename('../foo.txt'),    $cwd  . '/foo.txt',              "    set_filename(): should be up one folder levels");
if ($^O eq 'darwin') {
    is($o->set_filename($tmp_dir . '/foo.txt'), '/private' . $tmp_dir . '/foo.txt',     "    set_filename(): with an absolute path");
} else {
    is($o->set_filename($tmp_dir . '/foo.txt'), $tmp_dir . '/foo.txt',     "    set_filename(): with an absolute path");
}
is($o->set_wd(),                      $cwd  . '/t/',                   "    set_wd(): work_dir should not have changed throughout");
is($o->set_wd('test_set_filename'),   $cwd  . '/t/test_set_filename/', "    set_wd(): going down 2-levels so we can then test saving a file up 2-levels");
is($o->set_filename('../../foo.txt'), $cwd  . '/foo.txt',              "    set_filename(): should be up two folder levels");
is($o->set_filename($fname_initial),  $cwd  . '/t/test.gpx',           "    set_filename(): back to original name");

#
# set_wd()

is($o->set_wd($wd_initial),   $cwd  . '/t/',     "    set_wd(): back to initial working directory");
is($o->set_wd(),              $cwd  . '/t/',     "    set_wd(): get the working directory");
is($o->set_wd($tmp_dir),      $tmp_dir . '/',    "    set_wd(): set the working directory");
is($o->set_wd(' - '),         $cwd  . '/t/',     "    set_wd(): and _set_wd_old(): return to the previous working directory");
is($o->set_wd('..'),          $cwd  . '/',       "    set_wd(): up a level");
is($o->set_wd(' - '),         $cwd  . '/t/',     "    set_wd(): and _set_wd_old(): return to the previous working directory");
is($o->set_wd('test_set_filename'), $cwd . '/t/test_set_filename/',   "    set_wd(): down 2 levels");
is($o->set_wd('../..'),       $cwd  . '/',       "    set_wd(): up 2 levels");
is($o->set_wd('t'),           $cwd  . '/t/',     "    set_wd(): relative path to set the working directory");
is($o->set_wd('-'),           $cwd  . '/',       "    set_wd(): and _set_wd_old(): return to the previous working directory");
is($o->set_wd('./'),          $cwd  . '/',       "    set_wd(): same working directory");
is($o->set_wd($wd_initial),   $cwd  . '/t/',     "    set_wd(): back to initial working directory");
rmdir 't/test_set_filename';

print "so debugger doesn't exit\n";
