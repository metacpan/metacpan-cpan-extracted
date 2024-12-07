#!/user/bin/perl

# Program:  90-foreign_language.t
# Finds out where each Date::Language::${lang} module is installed and
# uses some of the languages in the tests.

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Glob qw (bsd_glob);

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

my $start_level;
my $warn_found = 0;

sub my_warn
{
   dbug_ok (0, "There was an expected warning!  Check fish.");
   $warn_found = 1;
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) { # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Uses options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => ${off}, allow_utf8 => 1 );

   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC (@ARGV);

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");
   DBUG_PRINT ("PURPOSE", "\nJust verifying that we can handle the UTF8 character set!\n.");

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}

sub find_installed_languages
{
   DBUG_ENTER_FUNC (@_);

   my $search;

   # Find out where each Date::Language::${lang} is installed ...
   foreach my $k ( sort keys %INC ) {
      my @dirs = File::Spec->splitdir ($k);
      if ( $dirs[-1] eq "Language.pm" && $dirs[-2] eq "Date" ) {
         my $path = $INC{$k};
         $path =~ s/[.]pm$//;
         $search = File::Spec->catdir ( $path, "*.pm" );
         last;
      }
   }

   my @langs;
   if ( $search ) {
      DBUG_PRINT ("PATTERN", $search);
      foreach my $f ( bsd_glob ($search) ) {
         my @dirs = File::Spec->splitdir ($f);
         $dirs[-1] =~ s/[.]pm//;
         push (@langs, $dirs[-1]);
      }
   }

   DBUG_RETURN (@langs)
}

# Doesn't use fish on purpose ...
sub load_language_data
{
   my $module = shift;

   my $lang = (split ("::", $module))[-1];

   # @Dsuf isn't always available for some modules.
   my @lMoY  = eval "\@${module}::MoY";     # The fully spelled out Months.
   my @lMoYs = eval "\@${module}::MoYs";    # The legal Abbreviations.
   my @lDsuf = eval "\@${module}::Dsuf";    # The suffix for the Day of Month.
   my @lDoW  = eval "\@${module}::DoW";     # The Day of Week.
   my @lDoWs = eval "\@${module}::DoWs";    # The Day of Week Abbreviations.

#  DBUG_PRINT ("INFO", "MoY: %d, MoYs: %d, Dsuf: %d, DoW: %d, DoWs: %d, Module: %s",
#              scalar (@lMoY), scalar (@lMoYs), scalar (@lDsuf), scalar (@lDoW), scalar (@lDoWs), $module);

   # Fix so that uc() & lc() will always work on these 5 arrays ...
   foreach (@lMoY, @lMoYs, @lDsuf, @lDoW, @lDoWs ) {

      # Proves both tests are equivalent ...
      my $utf8 = utf8::is_utf8 ($_) || 0;
      my $wide = ( $_ =~ m/[^\x00-\xff]/ ) ? 1 : 0;
      if ( $wide != $utf8 ) {
         DBUG_PRINT ("ERROR", "My wide/utf8 tests give different results for %s.  W:%d, U:%d", $lang, $wide, $utf8);
      }

      unless ( $utf8 ) {
         my $save = $_;
         utf8::encode ($_);
         utf8::decode ($_);

         # Now just doing some sanity checks ...
         if ( $_ ne $save ) {
            DBUG_PRINT ("DIFF", "(%s) vs (%s)", $_, $save);
            ok (0, "The UTF8 fix backfired.  ($lang)");
         }
         if ( utf8::is_utf8 ($_) ) {
            if ( uc($_) eq lc($_) ) {
#              DBUG_PRINT ("INFO", "Reset the UTF8 flag to true for %s (%s) uc & lc are the same.", $lang, $save);
#           } else {
#              DBUG_PRINT ("INFO", "Reset the UTF8 flag to true for %s (%s) (%s) (%s)", $lang, $save, uc($_), lc($_));
            }
         }
      }
   }

   my %data = ( MoY  => \@lMoY,  MoYs => \@lMoYs,
                Dsuf => \@lDsuf,
                DoW  => \@lDoW,  DoWs => \@lDoWs );

   return (\%data);
}

my %language_data;
my $skip_encode_tests;
BEGIN {
   DBUG_ENTER_FUNC ();

   eval {
      require Date::Language;
      Date::Language->import ();
      dbug_ok (1, "use Date::Language;");
   };
   if ($@) {
      dbug_ok (1, "Date::Language not installed, so can't test alternate character sets.");
      done_testing ();
      DBUG_LEAVE (0);
   }

   my @languages = find_installed_languages ();
   if ( $#languages == -1 ) {
      dbug_ok (1, "No languages are installed, so can't test alternate character sets.");
      done_testing ();
      DBUG_LEAVE (0);
   }

   $skip_encode_tests = 1;    # Assume module not found ...
   eval {
      require Encode::Guess;
      Encode::Guess->import ();
      $skip_encode_tests = 0;
      dbug_ok (1, "use Encode::Guess;");
   };
   if ($@) {
      dbug_ok (1, "Encode::Guess is not installed, so can't guess what character sets need to be used.");
      # done_testing ();
      # DBUG_LEAVE (0);
   }

   foreach my $lang ( @languages ) {
      my $module = "Date::Language::${lang}";
      if ( use_ok ($module) ) {
         $language_data{$lang} = load_language_data ($module);
      } else {
         DBUG_PRINT ("ERROR", "Couldn't load language (%s)", $lang);
      }
   }
   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   my $lvl = test_fish_level ();
   if ( $start_level != $lvl ) {
      dbug_ok (0, "END Level Check Worked!");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_BLOCK ("main-prog-\x{263A}", @ARGV);

   dbug_ok (1, "In the MAIN program ...");

   # The progam hangs if binmode() is called multiple time.
   # my $fh = DBUG_FILE_HANDLE ();
   # binmode ($fh, "encoding(UTF-8)");   # Converts to wide-char / Unicode output.
   # binmode ($fh, ":utf8");             # Breaks some languages like German.
   # binmode ($fh, "encoding(ascii)");   # Causes wide chars to hang.

   foreach ( sort keys %language_data ) {
       my @l = guess_the_encoding ( $_, $language_data{$_} );
       $language_data{$_}->{encode} = $l[0];
   }

   DBUG_PRINT ("---", '='x40);
   foreach ( sort keys %language_data ) {
      my $code = $language_data{$_}->{encode};
      unless ( $code ) {
         DBUG_PRINT ("SKIP", "Can't encode language '%s'", $_);
         next;
      }
      my $ok = test_language ( $_, $language_data{$_} );
      dbug_ok ($ok, "Language '$_' written to fish OK!");
      DBUG_PRINT ("---", '-'x40);
   }

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "Final MAIN Level Check Worked!");

   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# I'm making my best guess on the encoding to use
# based on a limited data set.
# But in most cases the programmer will know what
# encoding he's using or can repeate this logic
# himself.
# -----------------------------------------------
# Stopped using the results of this method after
# it proved that things hung if calling binmode()
# too often.  Now always assuming UTF-8 works
# for this test case.
# -----------------------------------------------
sub guess_the_encoding
{
   DBUG_ENTER_FUNC (@_);
   my $lang = shift;
   my $data = shift;     # A hash reference ...

   if ( $skip_encode_tests ) {
      return DBUG_RETURN ("utf8");   # Assume true for all languages!
   }

   local $SIG{__DIE__} = "";
   local $SIG{__WARN__} = "";

   my %guess;
   my $bad = 0;
   foreach my $g ( @{$data->{MoY}}, @{$data->{MoYs}}, @{$data->{Dssuf}}, @{$data->{DoW}}, @{$data->{DoWs}} ) {
      my ($decoder, $name);
      my $skip = 0;
      eval {
         $decoder = Encode::Guess->guess ($g);
         $name = $decoder->name ();
         ++$guess{$name};
         $skip = 1;
      };
      next  if ( $skip );
      eval {
         $decoder = guess_encoding ($g, 'latin1');
         $name = $decoder->name ();
         ++$guess{$name};
         $skip = 1;
      };
      next  if ( $skip );

      ++$bad;
   }

   my $cnt = keys %guess;
   DBUG_PRINT ("GUESS", "%d: %s", $cnt, join (", ", sort keys %guess));

   # I don't know what encoding we should be using ...
   if ( $bad ) {
      return DBUG_RETURN (undef);
   }

   if ( $cnt == 2 && $guess{ascii} ) {
      delete ( $guess{ascii} );
      return DBUG_RETURN ( sort keys %guess );
   }

   DBUG_RETURN ( sort keys %guess );
}

# -----------------------------------------------
sub test_language
{
   DBUG_ENTER_FUNC (@_);
   my $lang = shift;
   my $data = shift;     # A hash reference ...

   $warn_found = 0;      # Assume no warnings were trapped.

   DBUG_PRINT ("ENCODING", "%s", $data->{encode});

   foreach ( @{$data->{MoY}} )   { DBUG_PRINT ("MONTH (MoY)", $_); }
   foreach ( @{$data->{MoYs}} )  { DBUG_PRINT ("MONTH (MoYs)", $_); }
   foreach ( @{$data->{Dsuf}} )  { DBUG_PRINT ("DAY SUFFIX (Dsuf)", $_); }
   foreach ( @{$data->{DoW}} )   { DBUG_PRINT ("DAY OF WEEK (DoW)", $_); }
   foreach ( @{$data->{DoWs}} )  { DBUG_PRINT ("DAY OF WEEK (DoWs)", $_); }

   # All is OK if no warnings were generated!
   DBUG_RETURN ( $warn_found ? 0 : 1 );
}

