# Test file. Run this like so:
#   perl 06-setting_redirector.t
# or use 'make test'
#   doom@kzsu.stanford.edu     2008/03/24 22:15:53

use warnings;
use strict;
$|=1;
my $DEBUG = 0; # TODO set to 0 before ship
use Data::Dumper;
use File::Copy qw( copy );
use File::Basename qw( fileparse basename dirname );
use File::Spec;
use Test::More;
use Test::Differences;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use lib "$Bin/lib";
use Emacs::Run::Testorama qw( :all );

# Globals
my $CLASS   = 'Emacs::Run';
my $SRC_LOC = "$Bin/dat/src";
my $USR     = "$Bin/dat/usr";

my $devnull = File::Spec->devnull;
my $emacs_found;
eval {
  $emacs_found = qx{ emacs --version 2>$devnull };
};
if($@) {
  $emacs_found = '';
  print STDERR "Problem with qx of emacs: $@\n" if $DEBUG;
}

if( not( $emacs_found ) ) {
  plan skip_all => 'emacs was not found in PATH';
} else {
  plan tests => 20;
}

if ($DEBUG) {
  print STDERR "$0 using emacs version:\n$emacs_found\n";
  print "$0 using emacs version:\n$emacs_found\n";
}


use_ok( $CLASS );

ok(1, "Traditional: If we made it this far, we're ok."); #2

{
  my $test_name = "Testing redirector, with eval_elisp";

  my $mock_home = "$Bin/dat/home/mockingbird";
  my $code_lib = "$USR/lib";
  my $code_lib_alt = "$USR/lib-alt";
  my $dot_emacs_tpl = "$SRC_LOC/templates/.emacs-template";

  create_dot_emacs_in_mock_home( $mock_home, $code_lib, $code_lib_alt, $dot_emacs_tpl );

  # change the environment variable $HOME to point at the $mock_home
  $ENV{HOME} = $mock_home;
  ($DEBUG) && echo_home();

  my $stderr_mess = "i am stderr";
  my $stdout_mess = "i am stdout";

  my $elisp = "(message \"$stderr_mess\") (prin1 \"$stdout_mess\")";

  {
    my $sub_test = "default behavior";
    my ($er, $result);
    $er = Emacs::Run->new;
    $result = $er->eval_elisp( $elisp );
    ($DEBUG) && print STDERR "$sub_test, result: \n$result\n\n";

    # default behavior is both stdout and stderr: stderr *should* be first,
    # but here we allow either order.
    ok( ( $result =~ /\Q$stderr_mess\E/ )&&
        ( $result =~ /\Q$stdout_mess\E/ ),
        "$test_name: $sub_test" ) or
          print STDERR "$test_name: $sub_test, result is: $result";
  }

  {
    my $sub_test = "stdout_only set on method";
    my ($er, $result);
    $er = Emacs::Run->new;
    $result = $er->eval_elisp( $elisp, { redirector => 'stdout_only' });
    ($DEBUG) && print STDERR "$sub_test, result: $result\n";
    is( $result, $stdout_mess, "$test_name: $sub_test" );
  }

  {
    my $sub_test = "stderr_only set on method";
    my ($er, $result);
    $er = Emacs::Run->new;
    $result = $er->eval_elisp( $elisp, { redirector => 'stderr_only' });
    ($DEBUG) && print STDERR "$sub_test, result: $result\n";
    is( $result, $stderr_mess, "$test_name: $sub_test" );
  }

  {
    my $sub_test = "all_output";
    my ($er, $result);
    $er = Emacs::Run->new;
    $result = $er->eval_elisp( $elisp );
    ($DEBUG) && print STDERR "$sub_test, result: $result\n";

    # stderr *should* be first, but here we allow either order.
    ok( $result =~ /\Q$stderr_mess\E/ &&
        $result =~ /\Q$stdout_mess\E/,
        "$test_name: $sub_test" ) or
          print STDERR "$test_name: $sub_test, result is: $result";
  }


  {
    my $sub_test = "stderr_only set on object";
    my ($er, $result);
    $er = Emacs::Run->new({
                           redirector => 'stderr_only',
                          });
    $result = $er->eval_elisp( $elisp, { redirector => 'stderr_only' });
    ($DEBUG) && print STDERR "$sub_test, result: $result\n";
    is( $result, $stderr_mess, "$test_name: $sub_test" );
  }

  {
    my $sub_test = "stdout_only set on object";
    my ($er, $result);
    $er = Emacs::Run->new({
                           redirector => 'stdout_only',
                          });
    $result = $er->eval_elisp( $elisp, { redirector => 'stdout_only' });
    ($DEBUG) && print STDERR "$sub_test, result: $result\n";
    is( $result, $stdout_mess, "$test_name: $sub_test" );
  }
}

{
  my $test_name = "Testing run_elisp_on_file";

  my $mock_home     = "$Bin/dat/home/penguindust";
  my $code_lib      = "$USR/lib";
  my $code_lib_alt  = "$USR/lib-alt";
  my $dot_emacs_tpl = "$SRC_LOC/templates/.emacs-5-template";
  my $src           = "$Bin/dat/src/text";
  my $arc           = "$Bin/dat/arc/text";

  create_dot_emacs_in_mock_home( $mock_home, $code_lib, $code_lib_alt, $dot_emacs_tpl );

  my $test_subject = "chesterson.txt";
  my $source_file = "$src/$test_subject";
  my $test_subject_base = ( fileparse( $test_subject, qw{\.txt} ) )[0];
  my $result_file = "$mock_home/$test_subject_base-uc.txt";
  my $expected_file = "$arc/$test_subject_base-uc.txt";
  copy($source_file, $result_file) or die "$!";

  # we will now act on the "result" file
  my $filename = $result_file;

  # change the environment variable $HOME to point at the $mock_home
  $ENV{HOME} = $mock_home;
  ($DEBUG) && echo_home();

  my $er = Emacs::Run->new;

  # Make the text upper case
  my $elisp = q{ (upcase-region (point-min) (point-max)) };

  my $ret = $er->run_elisp_on_file( $filename, $elisp );

  my ($result, $expected) = slurp_files( $result_file, $expected_file );

  eq_or_diff( $result, $expected,
              "$test_name: upcase-region on penguindust/chesterson.txt") or
                print STDERR "using emacs version: $emacs_found";

  # But that's not what we really care about just now... the return value is the thing:
  print STDERR "ret: $ret\n" if $DEBUG;

  my $expected_stderr_pat =
    qr{ \QYow! I am spewing to STDERR!  Can I register as an Anarchist?\E .*? \Q$result_file\E }xms;
  # The message used to be "Wrote", now it's "Saving file"  -- Sun Mar 29 17:17:44 2009

  like( $ret, qr{ $expected_stderr_pat }xms,
        "$test_name: captured message sent to stderr.");

  $er = Emacs::Run->new({
                         redirector => 'stdout_only',
                        });

  $ret = $er->run_elisp_on_file( $filename, $elisp );
  is( $ret, '', "$test_name: no messages from stderr (cut off at new).");

  $er = Emacs::Run->new();
  $ret = $er->run_elisp_on_file( $filename, $elisp,
                                 {
                                  redirector => 'stdout_only',
                                 } );

  is( $ret, '', "$test_name: no messages from stderr (cut off at method).");
}

# eval_function has a complicated expanded interface which must
# distinguish between these four cases:
#   scalar
#   scalar aref
#   scalar href
#   scalar aref href
# The aref can be used to pass (simple?) arguments to the function
# The options href can, of course, change the sod.

{
  my $test_name = "Testing eval_function interface";

  my $mock_home     = "$Bin/dat/home/honestpol";
  my $code_lib      = "$USR/lib";
  my $code_lib_alt  = "$USR/lib-alt";
  my $dot_emacs_tpl = "$SRC_LOC/templates/.emacs-7-template";
  my $src           = "$Bin/dat/src/text";
  my $arc           = "$Bin/dat/arc/text";

  create_dot_emacs_in_mock_home( $mock_home, $code_lib, $code_lib_alt, $dot_emacs_tpl );

  my $funclib       = "$mock_home/a_poor_thing.el";

  my $funcname1 = "emacs-run-testorama-23-sched-dolittle";
  my $funcname2 = "emacs-run-testorama-23-sched-doless";

  my $func1 =<<"ENDFUNC1";
  (defun $funcname1 (fing fang)
    \"Talks to stderr and stdout, fixed spew plus two echoes: FING and FANG.\"
    (message \"think blue\")
    (print \"count two\")
    (message \"%s\" fing)
    (print   fang))
ENDFUNC1

  my $func2 =<<"ENDFUNC2";
  (defun $funcname2 ()
    \"Talks to stderr and stdout, spew only.\"
    (message \"%s\" \"think blue\")
    (print \"count two\"))
ENDFUNC2

  open my $fh, '>', $funclib or die "$!";
  print {$fh} $func1, "\n";
  print {$fh} $func2, "\n";
  close $fh;

  # change the environment variable $HOME to point at the $mock_home
  $ENV{HOME} = $mock_home;
  ($DEBUG) && echo_home();

  my $er = Emacs::Run->new({
                            emacs_libs => [ $funclib ],
                           });

  # Need to cover roughly four cases:
  #   $er->eval_function( $funcname );
  #   $er->eval_function( $funcname, $args_aref );
  #   $er->eval_function( $funcname, $args_aref, $opts_href );
  #   $er->eval_function( $funcname, $opts_href );
  # Note these dump STDERR by default, so we'll use '2>&1' to mix in STDERR

  my $args_aref = ["oink", "proper campaign contributions to key races will ensure that business needs can be met"];

  my $opts_href = { redirector => 'all_output',
                  };

  my $ret;
  $ret = $er->eval_function( $funcname2 );
  print STDERR "ret: $ret\n" if $DEBUG;
  unlike( $ret, qr{think blue}, "$test_name with no args or opts: ignores stderr (the default)");
  like(   $ret, qr{count two},        "$test_name with no args or opts: sees stdout");

  $ret = $er->eval_function( $funcname1, $args_aref );
  print STDERR "ret: $ret\n" if $DEBUG;
  unlike( $ret, qr{think blue|oink}, "$test_name with args: ignores stderr (the default)");
  like(   $ret, qr{$args_aref->[1]}, "$test_name with args: passes through an arg to stdout");

  $ret = $er->eval_function( $funcname1, $args_aref, $opts_href );
  print STDERR "ret: $ret\n" if $DEBUG;
  like( $ret, qr{think blue|oink}, "$test_name with args & opts: sees stderr now");
  like( $ret, qr{$args_aref->[1]}, "$test_name with args & opts: gets an arg to stdout");

  $ret = $er->eval_function( $funcname2, $opts_href );
  print STDERR "ret: $ret\n" if $DEBUG;
  like( $ret, qr{think blue}, "$test_name with opts: sees stderr");
  like( $ret, qr{count two},  "$test_name with opts: also sees stdout");
}
