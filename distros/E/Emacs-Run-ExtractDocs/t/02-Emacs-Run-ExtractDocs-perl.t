# Test file which can be run this like so:
#   perl 02-Emacs-Run-ExtractDocs-perl.t
#
#   doom@kzsu.stanford.edu     2008/03/08 10:01:55

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;
use Date::Calc qw{ Today Month_to_Text };

use File::Path     qw( mkpath );
use File::Basename qw( fileparse basename dirname );
use File::Copy     qw( copy move );

use Test::Differences;
use Test::More;

use FindBin qw( $Bin );
use lib ("$Bin/../lib");
use lib ("$Bin/../../Emacs-Run/lib");  # actually needed for development only

my $emacs_found = `emacs --version 2>/dev/null`;

if( not( $emacs_found ) ) {
  plan skip_all => 'emacs was not found in PATH';
} else {
  plan tests => 11;
}

use_ok( 'Emacs::Run::ExtractDocs' );

my $lisp_lib = "$Bin/../lisp";
my $extract_docs_el = "$lisp_lib/extract-doctrings.el"; # filename with specific, absolute path

ok(1, "Traditional: If we made it this far, we're ok.");

my $class = 'Emacs::Run::ExtractDocs';
{
  my $test_name = "Testing basic creation of object of $class";
  my $obj  = $class->new();
  my $type = ref( $obj );
  is( $type, $class, $test_name );
}

{
  print STDERR "======================\n" if $DEBUG;

  my $method = "elisp_docstrings_to_html";
  my $test_name = "Testing $method";

  my $mock_home    = "$Bin/dat/home/hollowman";
  my $code_lib     = "$Bin/lib";
  my $code_lib_alt = "$Bin/lib-alt";

  my $html_loc     = "$Bin/dat/tmp/html";
  if (-d $html_loc ) {
    unlink( "$html_loc/*" );
  } else {
    mkpath( $html_loc );
  }

  my $html_arc_loc = "$Bin/dat/arc/html";  # archive of previously generated files

  my $reed = Emacs::Run::ExtractDocs->new(
                     { html_output_location => $html_loc,
                       main_library         => $extract_docs_el,
                                          } );

  # get values from emacs for user's name and email to check generated html with
  my $er = $reed->emacs_runner;
  my $username = $er->eval_function( 'user-full-name'    );
  my $email    = $er->get_variable(  'user-mail-address' );

  my @elisp_files = qw(
      defunnery.el
      defvarsity.el
      defconstalert.el
      defcustomary.el
      );

  foreach my $elisp_file (@elisp_files) {
    my $file = "$code_lib_alt/$elisp_file";
    my $elisp = $reed->$method( $file );
  }

  my @html_files = map{ s{\.el$}{_el.html}xms; $_ } @elisp_files;

  print STDERR "Checking generated html in: $html_loc\n" if $DEBUG;

  foreach my $html_file (@html_files) {
    # test for file existance
    my $html_basename = basename( $html_file );
    print STDERR "html_file: $html_file\n" if $DEBUG;
    ok( (-e "$html_loc/$html_file"), "$test_name: does file $html_basename exists" );
  }

  # diff contents of generate html against archived copies
  foreach my $html_file (@html_files) {

    # open each file, slurp in.
    my $generated_html_file = "$html_loc/$html_file";
    local $/; # mister slurpie
    open my $fh, "<", $generated_html_file or die "$!";
    my $generated = <$fh>;

    close( $fh );

    my $expected_html_file = "$html_arc_loc/$html_file";
    open $fh, "<", $expected_html_file or die "$!";
    my $expected = <$fh>;
    close( $fh );

    $expected = expand_template_hackery( $expected, $username, $email );

    eq_or_diff( $generated, $expected,
                "$test_name: checking contents of $html_file");
  }
}


# thou shalt not write thy own template expansion code.
sub expand_template_hackery {
  my $string = shift;

  my $username = shift;
  my $email = shift;

  my ($year,$month,$day) = Today();

  # Need date in format: 05 Mar 2008
  my $current_date = sprintf "%02d %.3s %d", $day, Month_to_Text($month), $year;

  $string =~ s{ \(>>>CURDATE<<<\) }{$current_date}xmsg;
  $string =~ s{ \(>>>EMAIL_DOT_EMACS<<<\) }{$email}xmsg;
  $string =~ s{ \(>>>USER_NAME<<<\)       }{$username}xmsg;

  return $string;
}
