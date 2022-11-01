# t/set.t - set_* methods (for TCX.pm)
use strict;
use warnings;

use Test::More tests => 33;
use Geo::TCX;
use File::Temp qw/ tempfile tempdir /;
use Cwd qw(cwd abs_path);

my $cwd     = abs_path( cwd() );
my $tmp_dir = tempdir( CLEANUP => 1 );

my $o  = Geo::TCX->new('t/2014-08-11-10-25-15.tcx');
my $oo = Geo::TCX->new('t/2022-08-21-00-34-06_rwg_course.tcx');
isa_ok ($o,  'Geo::TCX');
isa_ok ($oo, 'Geo::TCX');

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
is($o->set_filename($fname_initial),  $cwd  . '/t/2014-08-11-10-25-15.tcx', "    set_filename(): back to original name");
# is($o->set_filename('../../../../../../foo.txt'), 'no result, should croak',     "    set_filename(): should croack, would be below /");
# is($o->set_filename($cwd . '/wrong_folder/foo.tcx'),  'no result, should croak', "    set_filename(): should croak as folder does not exist");

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

# without a filename, no work_dir
my $course_str = $o->save_laps([1], nosave => 1);
my $course1 = Geo::TCX->new( \$course_str );
is($course1->set_wd(),        $cwd  . '/',        "    set_wd(): Cwd::cwd if no filename nor work_dir");

# behaviour of work_dir field if not user-specified and empty (we need to define it, can't be empty)
is($oo->set_wd(),             $cwd  . '/t/',  "    set_wd(): directory of current file if fname is relative path");
$oo = Geo::TCX->new($cwd . '/t/2022-08-21-00-34-06_rwg_course.tcx');
is($oo->set_wd(),             $cwd  . '/t/',  "    set_wd(): directory of current file if fname is absolute path");

mkdir 'tmp_rel_dir';

# save() and effect on set_filename() and set_wd() when saving with different filename
$oo->save(filename => '../tmp_rel_dir/test_save.tcx', force => 1);
is($oo->set_wd(),             $cwd  . '/t/',                        "    set_wd():       work_dir should not have changed");
is($oo->set_filename(),       $cwd  . '/tmp_rel_dir/test_save.tcx', "    set_filename(): but file should still point to the file in the new location");

my $oo2 = Geo::TCX->new ('t/2014-08-11-10-25-15.tcx', work_dir => $tmp_dir );
is($oo2->set_wd(),            $tmp_dir . '/',                       "    set_wd(): set the working directory");
is($oo2->set_filename(),      $cwd  . '/t/2014-08-11-10-25-15.tcx', "    set_filename(): should be the name of the file with the absolute path from where it was open");

my $oo3 = Geo::TCX->new ('t/2014-08-11-10-25-15.tcx', work_dir => '..');
# The following 1 test(s) pass on my system but will fail on others
# is($oo3->set_wd(),            $home . '/Dev/',                                     "    set_wd(): should be one level up from the cwd");
is($oo3->set_filename(),      $cwd  . '/t/2014-08-11-10-25-15.tcx', "    set_filename(): should be the name of the file with the absolute path from where it was open");

my $oo5 = Geo::TCX->new ('t/2014-08-11-10-25-15.tcx', work_dir => 'tmp_rel_dir');
is($oo5->set_wd(),            $cwd  . '/tmp_rel_dir/',              "    set_wd(): should be one level up from the cwd");
is($oo5->set_filename(),      $cwd  . '/t/2014-08-11-10-25-15.tcx', "    set_filename(): should be the name of the file with the absolute path from where it was open");

unlink $oo->set_filename or die "can't remove $oo->set_filename $!";
rmdir 'tmp_rel_dir'      or die "can't remove tmp_rel_dir: $!";

print "so debugger doesn't exit\n";
