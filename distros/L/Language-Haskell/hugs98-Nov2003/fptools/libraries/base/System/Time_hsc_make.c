#include "template-hsc.h"
#line 99 "Time.hsc"
#ifndef __HUGS__
#line 100 "Time.hsc"
#include "HsBase.h"
#line 101 "Time.hsc"
#endif 
#line 109 "Time.hsc"
#ifdef __HUGS__
#line 111 "Time.hsc"
#else 
#line 114 "Time.hsc"
#endif 
#line 209 "Time.hsc"
#ifdef __HUGS__
#line 214 "Time.hsc"
#elif HAVE_GETTIMEOFDAY
#line 222 "Time.hsc"
#elif HAVE_FTIME
#line 230 "Time.hsc"
#else /* use POSIX time() */
#line 235 "Time.hsc"
#endif 
#line 311 "Time.hsc"
#ifndef __HUGS__
#line 321 "Time.hsc"
#if HAVE_TM_ZONE
#line 325 "Time.hsc"
#else /* ! HAVE_TM_ZONE */
#line 326 "Time.hsc"
#if HAVE_TZNAME || defined(_WIN32)
#line 327 "Time.hsc"
#if cygwin32_TARGET_OS
#line 328 "Time.hsc"
#define tzname _tzname
#line 329 "Time.hsc"
#endif 
#line 330 "Time.hsc"
#ifndef mingw32_TARGET_OS
#line 332 "Time.hsc"
#else 
#line 335 "Time.hsc"
#endif 
#line 339 "Time.hsc"
#else /* ! HAVE_TZNAME */
#line 341 "Time.hsc"
#error "Don't know how to get at timezone name on your OS."
#line 342 "Time.hsc"
#endif /* ! HAVE_TZNAME */
#line 345 "Time.hsc"
#if HAVE_DECL_ALTZONE
#line 352 "Time.hsc"
#else /* ! HAVE_DECL_ALTZONE */
#line 354 "Time.hsc"
#if !defined(mingw32_TARGET_OS)
#line 356 "Time.hsc"
#endif 
#line 369 "Time.hsc"
#endif /* ! HAVE_DECL_ALTZONE */
#line 370 "Time.hsc"
#endif /* ! HAVE_TM_ZONE */
#line 371 "Time.hsc"
#endif /* ! __HUGS__ */
#line 382 "Time.hsc"
#ifdef __HUGS__
#line 384 "Time.hsc"
#elif HAVE_LOCALTIME_R
#line 386 "Time.hsc"
#else 
#line 388 "Time.hsc"
#endif 
#line 391 "Time.hsc"
#ifdef __HUGS__
#line 393 "Time.hsc"
#elif HAVE_GMTIME_R
#line 395 "Time.hsc"
#else 
#line 397 "Time.hsc"
#endif 
#line 399 "Time.hsc"
#ifdef __HUGS__
#line 422 "Time.hsc"
#else /* ! __HUGS__ */
#line 474 "Time.hsc"
#endif /* ! __HUGS__ */
#line 477 "Time.hsc"
#ifdef __HUGS__
#line 483 "Time.hsc"
#else /* ! __HUGS__ */
#line 525 "Time.hsc"
#endif /* ! __HUGS__ */
#line 667 "Time.hsc"
#ifndef __HUGS__
#line 673 "Time.hsc"
#if HAVE_LOCALTIME_R
#line 675 "Time.hsc"
#else 
#line 677 "Time.hsc"
#endif 
#line 678 "Time.hsc"
#if HAVE_GMTIME_R
#line 680 "Time.hsc"
#else 
#line 682 "Time.hsc"
#endif 
#line 686 "Time.hsc"
#if HAVE_GETTIMEOFDAY
#line 689 "Time.hsc"
#endif 
#line 691 "Time.hsc"
#if HAVE_FTIME
#line 693 "Time.hsc"
#ifndef mingw32_TARGET_OS
#line 695 "Time.hsc"
#else 
#line 697 "Time.hsc"
#endif 
#line 698 "Time.hsc"
#endif 
#line 699 "Time.hsc"
#endif /* ! __HUGS__ */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
#line 99 "Time.hsc"
#ifndef __HUGS__
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsBase.h\"");
#line 101 "Time.hsc"
#endif 
#line 109 "Time.hsc"
#ifdef __HUGS__
#line 111 "Time.hsc"
#else 
#line 114 "Time.hsc"
#endif 
#line 209 "Time.hsc"
#ifdef __HUGS__
#line 214 "Time.hsc"
#elif HAVE_GETTIMEOFDAY
#line 222 "Time.hsc"
#elif HAVE_FTIME
#line 230 "Time.hsc"
#else /* use POSIX time() */
#line 235 "Time.hsc"
#endif 
#line 311 "Time.hsc"
#ifndef __HUGS__
#line 321 "Time.hsc"
#if HAVE_TM_ZONE
#line 325 "Time.hsc"
#else /* ! HAVE_TM_ZONE */
#line 326 "Time.hsc"
#if HAVE_TZNAME || defined(_WIN32)
#line 327 "Time.hsc"
#if cygwin32_TARGET_OS
    printf ("{-# OPTIONS %s #-}\n", "-optc-Dtzname=_tzname");
#line 329 "Time.hsc"
#endif 
#line 330 "Time.hsc"
#ifndef mingw32_TARGET_OS
#line 332 "Time.hsc"
#else 
#line 335 "Time.hsc"
#endif 
#line 339 "Time.hsc"
#else /* ! HAVE_TZNAME */
#line 341 "Time.hsc"
#error "Don't know how to get at timezone name on your OS."
#line 342 "Time.hsc"
#endif /* ! HAVE_TZNAME */
#line 345 "Time.hsc"
#if HAVE_DECL_ALTZONE
#line 352 "Time.hsc"
#else /* ! HAVE_DECL_ALTZONE */
#line 354 "Time.hsc"
#if !defined(mingw32_TARGET_OS)
#line 356 "Time.hsc"
#endif 
#line 369 "Time.hsc"
#endif /* ! HAVE_DECL_ALTZONE */
#line 370 "Time.hsc"
#endif /* ! HAVE_TM_ZONE */
#line 371 "Time.hsc"
#endif /* ! __HUGS__ */
#line 382 "Time.hsc"
#ifdef __HUGS__
#line 384 "Time.hsc"
#elif HAVE_LOCALTIME_R
#line 386 "Time.hsc"
#else 
#line 388 "Time.hsc"
#endif 
#line 391 "Time.hsc"
#ifdef __HUGS__
#line 393 "Time.hsc"
#elif HAVE_GMTIME_R
#line 395 "Time.hsc"
#else 
#line 397 "Time.hsc"
#endif 
#line 399 "Time.hsc"
#ifdef __HUGS__
#line 422 "Time.hsc"
#else /* ! __HUGS__ */
#line 474 "Time.hsc"
#endif /* ! __HUGS__ */
#line 477 "Time.hsc"
#ifdef __HUGS__
#line 483 "Time.hsc"
#else /* ! __HUGS__ */
#line 525 "Time.hsc"
#endif /* ! __HUGS__ */
#line 667 "Time.hsc"
#ifndef __HUGS__
#line 673 "Time.hsc"
#if HAVE_LOCALTIME_R
#line 675 "Time.hsc"
#else 
#line 677 "Time.hsc"
#endif 
#line 678 "Time.hsc"
#if HAVE_GMTIME_R
#line 680 "Time.hsc"
#else 
#line 682 "Time.hsc"
#endif 
#line 686 "Time.hsc"
#if HAVE_GETTIMEOFDAY
#line 689 "Time.hsc"
#endif 
#line 691 "Time.hsc"
#if HAVE_FTIME
#line 693 "Time.hsc"
#ifndef mingw32_TARGET_OS
#line 695 "Time.hsc"
#else 
#line 697 "Time.hsc"
#endif 
#line 698 "Time.hsc"
#endif 
#line 699 "Time.hsc"
#endif /* ! __HUGS__ */
    hsc_line (1, "Time.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "", stdout);
    hsc_line (2, "Time.hsc");
    fputs ("-- |\n"
           "-- Module      :  System.Time\n"
           "-- Copyright   :  (c) The University of Glasgow 2001\n"
           "-- License     :  BSD-style (see the file libraries/core/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  portable\n"
           "--\n"
           "-- The standard Time library.\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "{-\n"
           "Haskell 98 Time of Day Library\n"
           "------------------------------\n"
           "\n"
           "The Time library provides standard functionality for clock times,\n"
           "including timezone information (i.e, the functionality of \"time.h\",\n"
           "adapted to the Haskell environment), It follows RFC 1129 in its use of\n"
           "Coordinated Universal Time (UTC).\n"
           "\n"
           "2000/06/17 <michael.weber@post.rwth-aachen.de>:\n"
           "RESTRICTIONS:\n"
           "  * min./max. time diff currently is restricted to\n"
           "    [minBound::Int, maxBound::Int]\n"
           "\n"
           "  * surely other restrictions wrt. min/max bounds\n"
           "\n"
           "\n"
           "NOTES:\n"
           "  * printing times\n"
           "\n"
           "    `showTime\' (used in `instance Show ClockTime\') always prints time\n"
           "    converted to the local timezone (even if it is taken from\n"
           "    `(toClockTime . toUTCTime)\'), whereas `calendarTimeToString\'\n"
           "    honors the tzone & tz fields and prints UTC or whatever timezone\n"
           "    is stored inside CalendarTime.\n"
           "\n"
           "    Maybe `showTime\' should be changed to use UTC, since it would\n"
           "    better correspond to the actual representation of `ClockTime\'\n"
           "    (can be done by replacing localtime(3) by gmtime(3)).\n"
           "\n"
           "\n"
           "BUGS:\n"
           "  * add proper handling of microsecs, currently, they\'re mostly\n"
           "    ignored\n"
           "\n"
           "  * `formatFOO\' case of `%s\' is currently broken...\n"
           "\n"
           "\n"
           "TODO:\n"
           "  * check for unusual date cases, like 1970/1/1 00:00h, and conversions\n"
           "    between different timezone\'s etc.\n"
           "\n"
           "  * check, what needs to be in the IO monad, the current situation\n"
           "    seems to be a bit inconsistent to me\n"
           "\n"
           "  * check whether `isDst = -1\' works as expected on other arch\'s\n"
           "    (Solaris anyone\?)\n"
           "\n"
           "  * add functions to parse strings to `CalendarTime\' (some day...)\n"
           "\n"
           "  * implement padding capabilities (\"%_\", \"%-\") in `formatFOO\'\n"
           "\n"
           "  * add rfc822 timezone (+0200 is CEST) representation (\"%z\") in `formatFOO\'\n"
           "-}\n"
           "\n"
           "module System.Time\n"
           "     (\n"
           "        Month(..)\n"
           "     ,  Day(..)\n"
           "\n"
           "     ,  ClockTime(..) -- non-standard, lib. report gives this as abstract\n"
           "\t-- instance Eq, Ord\n"
           "\t-- instance Show (non-standard)\n"
           "\n"
           "     ,\tgetClockTime\n"
           "\n"
           "     ,  TimeDiff(..)\n"
           "     ,  noTimeDiff      -- non-standard (but useful when constructing TimeDiff vals.)\n"
           "     ,  diffClockTimes\n"
           "     ,  addToClockTime\n"
           "\n"
           "     ,  normalizeTimeDiff -- non-standard\n"
           "     ,  timeDiffToString  -- non-standard\n"
           "     ,  formatTimeDiff    -- non-standard\n"
           "\n"
           "     ,  CalendarTime(..)\n"
           "     ,\ttoCalendarTime\n"
           "     ,  toUTCTime\n"
           "     ,  toClockTime\n"
           "     ,  calendarTimeToString\n"
           "     ,  formatCalendarTime\n"
           "\n"
           "     ) where\n"
           "\n"
           "", stdout);
#line 99 "Time.hsc"
#ifndef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (100, "Time.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (101, "Time.hsc");
    fputs ("", stdout);
#line 101 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (102, "Time.hsc");
    fputs ("\n"
           "import Prelude\n"
           "\n"
           "import Data.Ix\n"
           "import System.Locale\n"
           "import System.IO.Unsafe\n"
           "\n"
           "", stdout);
#line 109 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (110, "Time.hsc");
    fputs ("import Hugs.Time ( getClockTimePrim, toCalTimePrim, toClockTimePrim )\n"
           "", stdout);
#line 111 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (112, "Time.hsc");
    fputs ("import Foreign\n"
           "import Foreign.C\n"
           "", stdout);
#line 114 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (115, "Time.hsc");
    fputs ("\n"
           "-- One way to partition and give name to chunks of a year and a week:\n"
           "\n"
           "data Month\n"
           " = January   | February | March    | April\n"
           " | May       | June     | July     | August\n"
           " | September | October  | November | December\n"
           " deriving (Eq, Ord, Enum, Bounded, Ix, Read, Show)\n"
           "\n"
           "data Day \n"
           " = Sunday   | Monday | Tuesday | Wednesday\n"
           " | Thursday | Friday | Saturday\n"
           " deriving (Eq, Ord, Enum, Bounded, Ix, Read, Show)\n"
           "\n"
           "-- @ClockTime@ is an abstract type, used for the internal clock time.\n"
           "-- Clock times may be compared, converted to strings, or converted to an\n"
           "-- external calendar time @CalendarTime@.\n"
           "\n"
           "data ClockTime = TOD Integer \t\t-- Seconds since 00:00:00 on 1 Jan 1970\n"
           "\t\t     Integer\t\t-- Picoseconds with the specified second\n"
           "\t       deriving (Eq, Ord)\n"
           "\n"
           "-- When a ClockTime is shown, it is converted to a CalendarTime in the current\n"
           "-- timezone and then printed.  FIXME: This is arguably wrong, since we can\'t\n"
           "-- get the current timezone without being in the IO monad.\n"
           "\n"
           "instance Show ClockTime where\n"
           "    showsPrec _ t = showString (calendarTimeToString \n"
           "\t  \t\t\t (unsafePerformIO (toCalendarTime t)))\n"
           "\n"
           "{-\n"
           "@CalendarTime@ is a user-readable and manipulable\n"
           "representation of the internal $ClockTime$ type.  The\n"
           "numeric fields have the following ranges.\n"
           "\n"
           "\\begin{verbatim}\n"
           "Value         Range             Comments\n"
           "-----         -----             --------\n"
           "\n"
           "year    -maxInt .. maxInt       [Pre-Gregorian dates are inaccurate]\n"
           "mon           0 .. 11           [Jan = 0, Dec = 11]\n"
           "day           1 .. 31\n"
           "hour          0 .. 23\n"
           "min           0 .. 59\n"
           "sec           0 .. 61           [Allows for two leap seconds]\n"
           "picosec       0 .. (10^12)-1    [This could be over-precise\?]\n"
           "wday          0 .. 6            [Sunday = 0, Saturday = 6]\n"
           "yday          0 .. 365          [364 in non-Leap years]\n"
           "tz       -43200 .. 43200        [Variation from UTC in seconds]\n"
           "\\end{verbatim}\n"
           "\n"
           "The {\\em tzname} field is the name of the time zone.  The {\\em isdst}\n"
           "field indicates whether Daylight Savings Time would be in effect.\n"
           "-}\n"
           "\n"
           "data CalendarTime \n"
           " = CalendarTime  {\n"
           "     ctYear    :: Int,\n"
           "     ctMonth   :: Month,\n"
           "     ctDay     :: Int,\n"
           "     ctHour    :: Int,\n"
           "     ctMin     :: Int,\n"
           "     ctSec     :: Int,\n"
           "     ctPicosec :: Integer,\n"
           "     ctWDay    :: Day,\n"
           "     ctYDay    :: Int,\n"
           "     ctTZName  :: String,\n"
           "     ctTZ      :: Int,\n"
           "     ctIsDST   :: Bool\n"
           " }\n"
           " deriving (Eq,Ord,Read,Show)\n"
           "\n"
           "-- The @TimeDiff@ type records the difference between two clock times in\n"
           "-- a user-readable way.\n"
           "\n"
           "data TimeDiff\n"
           " = TimeDiff {\n"
           "     tdYear    :: Int,\n"
           "     tdMonth   :: Int,\n"
           "     tdDay     :: Int,\n"
           "     tdHour    :: Int,\n"
           "     tdMin     :: Int,\n"
           "     tdSec     :: Int,\n"
           "     tdPicosec :: Integer -- not standard\n"
           "   }\n"
           "   deriving (Eq,Ord,Read,Show)\n"
           "\n"
           "noTimeDiff :: TimeDiff\n"
           "noTimeDiff = TimeDiff 0 0 0 0 0 0 0\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- getClockTime returns the current time in its internal representation.\n"
           "\n"
           "getClockTime :: IO ClockTime\n"
           "", stdout);
#line 209 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (210, "Time.hsc");
    fputs ("getClockTime = do\n"
           "  (sec,usec) <- getClockTimePrim\n"
           "  return (TOD (fromIntegral sec) ((fromIntegral usec) * 1000000))\n"
           "\n"
           "", stdout);
#line 214 "Time.hsc"
#elif HAVE_GETTIMEOFDAY
    fputs ("\n"
           "", stdout);
    hsc_line (215, "Time.hsc");
    fputs ("getClockTime = do\n"
           "  allocaBytes (", stdout);
#line 216 "Time.hsc"
    hsc_const (sizeof(struct timeval));
    fputs (") $ \\ p_timeval -> do\n"
           "", stdout);
    hsc_line (217, "Time.hsc");
    fputs ("    throwErrnoIfMinus1_ \"getClockTime\" $ gettimeofday p_timeval nullPtr\n"
           "    sec  <- (", stdout);
#line 218 "Time.hsc"
    hsc_peek (struct timeval,tv_sec);
    fputs (")  p_timeval :: IO CTime\n"
           "", stdout);
    hsc_line (219, "Time.hsc");
    fputs ("    usec <- (", stdout);
#line 219 "Time.hsc"
    hsc_peek (struct timeval,tv_usec);
    fputs (") p_timeval :: IO CTime\n"
           "", stdout);
    hsc_line (220, "Time.hsc");
    fputs ("    return (TOD (fromIntegral sec) ((fromIntegral usec) * 1000000))\n"
           " \n"
           "", stdout);
#line 222 "Time.hsc"
#elif HAVE_FTIME
    fputs ("\n"
           "", stdout);
    hsc_line (223, "Time.hsc");
    fputs ("getClockTime = do\n"
           "  allocaBytes (", stdout);
#line 224 "Time.hsc"
    hsc_const (sizeof(struct timeb));
    fputs (") $ \\ p_timeb -> do\n"
           "", stdout);
    hsc_line (225, "Time.hsc");
    fputs ("  ftime p_timeb\n"
           "  sec  <- (", stdout);
#line 226 "Time.hsc"
    hsc_peek (struct timeb,time);
    fputs (") p_timeb :: IO CTime\n"
           "", stdout);
    hsc_line (227, "Time.hsc");
    fputs ("  msec <- (", stdout);
#line 227 "Time.hsc"
    hsc_peek (struct timeb,millitm);
    fputs (") p_timeb :: IO CUShort\n"
           "", stdout);
    hsc_line (228, "Time.hsc");
    fputs ("  return (TOD (fromIntegral sec) (fromIntegral msec * 1000000000))\n"
           "\n"
           "", stdout);
#line 230 "Time.hsc"
#else /* use POSIX time() */
    fputs ("\n"
           "", stdout);
    hsc_line (231, "Time.hsc");
    fputs ("getClockTime = do\n"
           "    secs <- time nullPtr -- can\'t fail, according to POSIX\n"
           "    return (TOD (fromIntegral secs) 0)\n"
           "\n"
           "", stdout);
#line 235 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (236, "Time.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- addToClockTime d t adds a time difference d and a\n"
           "-- clock time t to yield a new clock time.  The difference d\n"
           "-- may be either positive or negative.  diffClockTimes t1 t2 returns \n"
           "-- the difference between two clock times t1 and t2 as a TimeDiff.\n"
           "\n"
           "addToClockTime  :: TimeDiff  -> ClockTime -> ClockTime\n"
           "addToClockTime (TimeDiff year mon day hour min sec psec) \n"
           "\t       (TOD c_sec c_psec) = \n"
           "\tlet\n"
           "\t  sec_diff = toInteger sec +\n"
           "                     60 * toInteger min +\n"
           "                     3600 * toInteger hour +\n"
           "                     24 * 3600 * toInteger day\n"
           "\t  cal      = toUTCTime (TOD (c_sec + sec_diff) (c_psec + psec))\n"
           "                                                       -- FIXME! ^^^^\n"
           "          new_mon  = fromEnum (ctMonth cal) + r_mon \n"
           "\t  (month\', yr_diff)\n"
           "\t    | new_mon < 0  = (toEnum (12 + new_mon), (-1))\n"
           "\t    | new_mon > 11 = (toEnum (new_mon `mod` 12), 1)\n"
           "\t    | otherwise    = (toEnum new_mon, 0)\n"
           "\t    \n"
           "\t  (r_yr, r_mon) = mon `quotRem` 12\n"
           "\n"
           "          year\' = ctYear cal + year + r_yr + yr_diff\n"
           "\tin\n"
           "\ttoClockTime cal{ctMonth=month\', ctYear=year\'}\n"
           "\n"
           "diffClockTimes  :: ClockTime -> ClockTime -> TimeDiff\n"
           "-- diffClockTimes is meant to be the dual to `addToClockTime\'.\n"
           "-- If you want to have the TimeDiff properly splitted, use\n"
           "-- `normalizeTimeDiff\' on this function\'s result\n"
           "--\n"
           "-- CAVEAT: see comment of normalizeTimeDiff\n"
           "diffClockTimes (TOD sa pa) (TOD sb pb) =\n"
           "    noTimeDiff{ tdSec     = fromIntegral (sa - sb) \n"
           "                -- FIXME: can handle just 68 years...\n"
           "              , tdPicosec = pa - pb\n"
           "              }\n"
           "\n"
           "\n"
           "normalizeTimeDiff :: TimeDiff -> TimeDiff\n"
           "-- FIXME: handle psecs properly\n"
           "-- FIXME: \?should be called by formatTimeDiff automagically\?\n"
           "--\n"
           "-- when applied to something coming out of `diffClockTimes\', you loose\n"
           "-- the duality to `addToClockTime\', since a year does not always have\n"
           "-- 365 days, etc.\n"
           "--\n"
           "-- apply this function as late as possible to prevent those \"rounding\"\n"
           "-- errors\n"
           "normalizeTimeDiff td =\n"
           "  let\n"
           "      rest0 = tdSec td \n"
           "               + 60 * (tdMin td \n"
           "                    + 60 * (tdHour td \n"
           "                         + 24 * (tdDay td \n"
           "                              + 30 * (tdMonth td \n"
           "                                   + 365 * tdYear td))))\n"
           "\n"
           "      (diffYears,  rest1)    = rest0 `quotRem` (365 * 24 * 3600)\n"
           "      (diffMonths, rest2)    = rest1 `quotRem` (30 * 24 * 3600)\n"
           "      (diffDays,   rest3)    = rest2 `quotRem` (24 * 3600)\n"
           "      (diffHours,  rest4)    = rest3 `quotRem` 3600\n"
           "      (diffMins,   diffSecs) = rest4 `quotRem` 60\n"
           "  in\n"
           "      td{ tdYear = diffYears\n"
           "        , tdMonth = diffMonths\n"
           "        , tdDay   = diffDays\n"
           "        , tdHour  = diffHours\n"
           "        , tdMin   = diffMins\n"
           "        , tdSec   = diffSecs\n"
           "        }\n"
           "\n"
           "", stdout);
#line 311 "Time.hsc"
#ifndef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (312, "Time.hsc");
    fputs ("-- -----------------------------------------------------------------------------\n"
           "-- How do we deal with timezones on this architecture\?\n"
           "\n"
           "-- The POSIX way to do it is through the global variable tzname[].\n"
           "-- But that\'s crap, so we do it The BSD Way if we can: namely use the\n"
           "-- tm_zone and tm_gmtoff fields of struct tm, if they\'re available.\n"
           "\n"
           "zone   :: Ptr CTm -> IO (Ptr CChar)\n"
           "gmtoff :: Ptr CTm -> IO CLong\n"
           "", stdout);
#line 321 "Time.hsc"
#if HAVE_TM_ZONE
    fputs ("\n"
           "", stdout);
    hsc_line (322, "Time.hsc");
    fputs ("zone x      = (", stdout);
#line 322 "Time.hsc"
    hsc_peek (struct tm,tm_zone);
    fputs (") x\n"
           "", stdout);
    hsc_line (323, "Time.hsc");
    fputs ("gmtoff x    = (", stdout);
#line 323 "Time.hsc"
    hsc_peek (struct tm,tm_gmtoff);
    fputs (") x\n"
           "", stdout);
    hsc_line (324, "Time.hsc");
    fputs ("\n"
           "", stdout);
#line 325 "Time.hsc"
#else /* ! HAVE_TM_ZONE */
    fputs ("\n"
           "", stdout);
    hsc_line (326, "Time.hsc");
    fputs ("", stdout);
#line 326 "Time.hsc"
#if HAVE_TZNAME || defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (327, "Time.hsc");
    fputs ("", stdout);
#line 327 "Time.hsc"
#if cygwin32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (328, "Time.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (329, "Time.hsc");
    fputs ("", stdout);
#line 329 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (330, "Time.hsc");
    fputs ("", stdout);
#line 330 "Time.hsc"
#ifndef mingw32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (331, "Time.hsc");
    fputs ("foreign import ccall unsafe \"&tzname\" tzname :: Ptr (Ptr CChar)\n"
           "", stdout);
#line 332 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (333, "Time.hsc");
    fputs ("foreign import ccall unsafe \"__hscore_timezone\" timezone :: Ptr CLong\n"
           "foreign import ccall unsafe \"__hscore_tzname\"   tzname :: Ptr (Ptr CChar)\n"
           "", stdout);
#line 335 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (336, "Time.hsc");
    fputs ("zone x = do \n"
           "  dst <- (", stdout);
#line 337 "Time.hsc"
    hsc_peek (struct tm,tm_isdst);
    fputs (") x\n"
           "", stdout);
    hsc_line (338, "Time.hsc");
    fputs ("  if dst then peekElemOff tzname 1 else peekElemOff tzname 0\n"
           "", stdout);
#line 339 "Time.hsc"
#else /* ! HAVE_TZNAME */
    fputs ("\n"
           "", stdout);
    hsc_line (340, "Time.hsc");
    fputs ("-- We\'re in trouble. If you should end up here, please report this as a bug.\n"
           "", stdout);
#line 341 "Time.hsc"
#error "Don't know how to get at timezone name on your OS."
    fputs ("\n"
           "", stdout);
    hsc_line (342, "Time.hsc");
    fputs ("", stdout);
#line 342 "Time.hsc"
#endif /* ! HAVE_TZNAME */
    fputs ("\n"
           "", stdout);
    hsc_line (343, "Time.hsc");
    fputs ("\n"
           "-- Get the offset in secs from UTC, if (struct tm) doesn\'t supply it. */\n"
           "", stdout);
#line 345 "Time.hsc"
#if HAVE_DECL_ALTZONE
    fputs ("\n"
           "", stdout);
    hsc_line (346, "Time.hsc");
    fputs ("foreign import ccall \"&altzone\"  altzone  :: Ptr CTime\n"
           "foreign import ccall \"&timezone\" timezone :: Ptr CTime\n"
           "gmtoff x = do \n"
           "  dst <- (", stdout);
#line 349 "Time.hsc"
    hsc_peek (struct tm,tm_isdst);
    fputs (") x\n"
           "", stdout);
    hsc_line (350, "Time.hsc");
    fputs ("  tz <- if dst then peek altzone else peek timezone\n"
           "  return (-fromIntegral tz)\n"
           "", stdout);
#line 352 "Time.hsc"
#else /* ! HAVE_DECL_ALTZONE */
    fputs ("\n"
           "", stdout);
    hsc_line (353, "Time.hsc");
    fputs ("\n"
           "", stdout);
#line 354 "Time.hsc"
#if !defined(mingw32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (355, "Time.hsc");
    fputs ("foreign import ccall unsafe \"timezone\" timezone :: Ptr CLong\n"
           "", stdout);
#line 356 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (357, "Time.hsc");
    fputs ("\n"
           "-- Assume that DST offset is 1 hour ...\n"
           "gmtoff x = do \n"
           "  dst <- (", stdout);
#line 360 "Time.hsc"
    hsc_peek (struct tm,tm_isdst);
    fputs (") x\n"
           "", stdout);
    hsc_line (361, "Time.hsc");
    fputs ("  tz  <- peek timezone\n"
           "   -- According to the documentation for tzset(), \n"
           "   --   http://www.opengroup.org/onlinepubs/007908799/xsh/tzset.html\n"
           "   -- timezone offsets are > 0 west of the Prime Meridian.\n"
           "   --\n"
           "   -- This module assumes the interpretation of tm_gmtoff, i.e., offsets\n"
           "   -- are > 0 East of the Prime Meridian, so flip the sign.\n"
           "  return (- (if dst then (fromIntegral tz - 3600) else tz))\n"
           "", stdout);
#line 369 "Time.hsc"
#endif /* ! HAVE_DECL_ALTZONE */
    fputs ("\n"
           "", stdout);
    hsc_line (370, "Time.hsc");
    fputs ("", stdout);
#line 370 "Time.hsc"
#endif /* ! HAVE_TM_ZONE */
    fputs ("\n"
           "", stdout);
    hsc_line (371, "Time.hsc");
    fputs ("", stdout);
#line 371 "Time.hsc"
#endif /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (372, "Time.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- toCalendarTime t converts t to a local time, modified by\n"
           "-- the current timezone and daylight savings time settings.  toUTCTime\n"
           "-- t converts t into UTC time.  toClockTime l converts l into the \n"
           "-- corresponding internal ClockTime.  The wday, yday, tzname, and isdst fields\n"
           "-- are ignored.\n"
           "\n"
           "\n"
           "toCalendarTime :: ClockTime -> IO CalendarTime\n"
           "", stdout);
#line 382 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (383, "Time.hsc");
    fputs ("toCalendarTime =  toCalTime False\n"
           "", stdout);
#line 384 "Time.hsc"
#elif HAVE_LOCALTIME_R
    fputs ("\n"
           "", stdout);
    hsc_line (385, "Time.hsc");
    fputs ("toCalendarTime =  clockToCalendarTime_reentrant (throwAwayReturnPointer localtime_r) False\n"
           "", stdout);
#line 386 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (387, "Time.hsc");
    fputs ("toCalendarTime =  clockToCalendarTime_static localtime False\n"
           "", stdout);
#line 388 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (389, "Time.hsc");
    fputs ("\n"
           "toUTCTime :: ClockTime -> CalendarTime\n"
           "", stdout);
#line 391 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (392, "Time.hsc");
    fputs ("toUTCTime      =  unsafePerformIO . toCalTime True\n"
           "", stdout);
#line 393 "Time.hsc"
#elif HAVE_GMTIME_R
    fputs ("\n"
           "", stdout);
    hsc_line (394, "Time.hsc");
    fputs ("toUTCTime      =  unsafePerformIO . clockToCalendarTime_reentrant (throwAwayReturnPointer gmtime_r) True\n"
           "", stdout);
#line 395 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (396, "Time.hsc");
    fputs ("toUTCTime      =  unsafePerformIO . clockToCalendarTime_static gmtime True\n"
           "", stdout);
#line 397 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (398, "Time.hsc");
    fputs ("\n"
           "", stdout);
#line 399 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (400, "Time.hsc");
    fputs ("toCalTime :: Bool -> ClockTime -> IO CalendarTime\n"
           "toCalTime toUTC (TOD s psecs)\n"
           "  | (s > fromIntegral (maxBound :: Int)) || \n"
           "    (s < fromIntegral (minBound :: Int))\n"
           "  = error ((if toUTC then \"toUTCTime: \" else \"toCalendarTime: \") ++\n"
           "           \"clock secs out of range\")\n"
           "  | otherwise = do\n"
           "    (sec,min,hour,mday,mon,year,wday,yday,isdst,zone,off) <- \n"
           "  \t\ttoCalTimePrim (if toUTC then 1 else 0) (fromIntegral s)\n"
           "    return (CalendarTime{ ctYear=1900+year\n"
           "  \t\t        , ctMonth=toEnum mon\n"
           "\t\t        , ctDay=mday\n"
           "\t\t        , ctHour=hour\n"
           "\t\t        , ctMin=min\n"
           "\t\t        , ctSec=sec\n"
           "\t\t        , ctPicosec=psecs\n"
           "\t\t        , ctWDay=toEnum wday\n"
           "\t\t        , ctYDay=yday\n"
           "\t\t        , ctTZName=(if toUTC then \"UTC\" else zone)\n"
           "\t\t        , ctTZ=(if toUTC then 0 else off)\n"
           "\t\t        , ctIsDST=not toUTC && (isdst/=0)\n"
           "\t\t        })\n"
           "", stdout);
#line 422 "Time.hsc"
#else /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (423, "Time.hsc");
    fputs ("throwAwayReturnPointer :: (Ptr CTime -> Ptr CTm -> IO (Ptr CTm))\n"
           "                       -> (Ptr CTime -> Ptr CTm -> IO (       ))\n"
           "throwAwayReturnPointer fun x y = fun x y >> return ()\n"
           "\n"
           "clockToCalendarTime_static :: (Ptr CTime -> IO (Ptr CTm)) -> Bool -> ClockTime\n"
           "\t -> IO CalendarTime\n"
           "clockToCalendarTime_static fun is_utc (TOD secs psec) = do\n"
           "  withObject (fromIntegral secs :: CTime)  $ \\ p_timer -> do\n"
           "    p_tm <- fun p_timer \t-- can\'t fail, according to POSIX\n"
           "    clockToCalendarTime_aux is_utc p_tm psec\n"
           "\n"
           "clockToCalendarTime_reentrant :: (Ptr CTime -> Ptr CTm -> IO ()) -> Bool -> ClockTime\n"
           "\t -> IO CalendarTime\n"
           "clockToCalendarTime_reentrant fun is_utc (TOD secs psec) = do\n"
           "  withObject (fromIntegral secs :: CTime)  $ \\ p_timer -> do\n"
           "    allocaBytes (", stdout);
#line 438 "Time.hsc"
    hsc_const (sizeof(struct tm));
    fputs (") $ \\ p_tm -> do\n"
           "", stdout);
    hsc_line (439, "Time.hsc");
    fputs ("      fun p_timer p_tm\n"
           "      clockToCalendarTime_aux is_utc p_tm psec\n"
           "\n"
           "clockToCalendarTime_aux :: Bool -> Ptr CTm -> Integer -> IO CalendarTime\n"
           "clockToCalendarTime_aux is_utc p_tm psec = do\n"
           "    sec   <-  (", stdout);
#line 444 "Time.hsc"
    hsc_peek (struct tm,tm_sec  );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (445, "Time.hsc");
    fputs ("    min   <-  (", stdout);
#line 445 "Time.hsc"
    hsc_peek (struct tm,tm_min  );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (446, "Time.hsc");
    fputs ("    hour  <-  (", stdout);
#line 446 "Time.hsc"
    hsc_peek (struct tm,tm_hour );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (447, "Time.hsc");
    fputs ("    mday  <-  (", stdout);
#line 447 "Time.hsc"
    hsc_peek (struct tm,tm_mday );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (448, "Time.hsc");
    fputs ("    mon   <-  (", stdout);
#line 448 "Time.hsc"
    hsc_peek (struct tm,tm_mon  );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (449, "Time.hsc");
    fputs ("    year  <-  (", stdout);
#line 449 "Time.hsc"
    hsc_peek (struct tm,tm_year );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (450, "Time.hsc");
    fputs ("    wday  <-  (", stdout);
#line 450 "Time.hsc"
    hsc_peek (struct tm,tm_wday );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (451, "Time.hsc");
    fputs ("    yday  <-  (", stdout);
#line 451 "Time.hsc"
    hsc_peek (struct tm,tm_yday );
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (452, "Time.hsc");
    fputs ("    isdst <-  (", stdout);
#line 452 "Time.hsc"
    hsc_peek (struct tm,tm_isdst);
    fputs (") p_tm :: IO CInt\n"
           "", stdout);
    hsc_line (453, "Time.hsc");
    fputs ("    zone  <-  zone p_tm\n"
           "    tz    <-  gmtoff p_tm\n"
           "    \n"
           "    tzname <- peekCString zone\n"
           "    \n"
           "    let month  | mon >= 0 && mon <= 11 = toEnum (fromIntegral mon)\n"
           "    \t       | otherwise             = error (\"toCalendarTime: illegal month value: \" ++ show mon)\n"
           "    \n"
           "    return (CalendarTime \n"
           "\t\t(1900 + fromIntegral year) \n"
           "\t\tmonth\n"
           "\t\t(fromIntegral mday)\n"
           "\t\t(fromIntegral hour)\n"
           "\t\t(fromIntegral min)\n"
           "\t\t(fromIntegral sec)\n"
           "\t\tpsec\n"
           "            \t(toEnum (fromIntegral wday))\n"
           "\t\t(fromIntegral yday)\n"
           "\t\t(if is_utc then \"UTC\" else tzname)\n"
           "\t\t(if is_utc then 0     else fromIntegral tz)\n"
           "\t\t(if is_utc then False else isdst /= 0))\n"
           "", stdout);
#line 474 "Time.hsc"
#endif /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (475, "Time.hsc");
    fputs ("\n"
           "toClockTime :: CalendarTime -> ClockTime\n"
           "", stdout);
#line 477 "Time.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (478, "Time.hsc");
    fputs ("toClockTime (CalendarTime yr mon mday hour min sec psec\n"
           "\t\t\t  _wday _yday _tzname tz _isdst) =\n"
           "  unsafePerformIO $ do\n"
           "    s <- toClockTimePrim (yr-1900) (fromEnum mon) mday hour min sec tz\n"
           "    return (TOD (fromIntegral s) psec)\n"
           "", stdout);
#line 483 "Time.hsc"
#else /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (484, "Time.hsc");
    fputs ("toClockTime (CalendarTime year mon mday hour min sec psec \n"
           "\t\t\t  _wday _yday _tzname tz isdst) =\n"
           "\n"
           "     -- `isDst\' causes the date to be wrong by one hour...\n"
           "     -- FIXME: check, whether this works on other arch\'s than Linux, too...\n"
           "     -- \n"
           "     -- so we set it to (-1) (means `unknown\') and let `mktime\' determine\n"
           "     -- the real value...\n"
           "    let isDst = -1 :: CInt in   -- if isdst then (1::Int) else 0\n"
           "\n"
           "    if psec < 0 || psec > 999999999999 then\n"
           "        error \"Time.toClockTime: picoseconds out of range\"\n"
           "    else if tz < -43200 || tz > 43200 then\n"
           "        error \"Time.toClockTime: timezone offset out of range\"\n"
           "    else\n"
           "      unsafePerformIO $ do\n"
           "      allocaBytes (", stdout);
#line 500 "Time.hsc"
    hsc_const (sizeof(struct tm));
    fputs (") $ \\ p_tm -> do\n"
           "", stdout);
    hsc_line (501, "Time.hsc");
    fputs ("        (", stdout);
#line 501 "Time.hsc"
    hsc_poke (struct tm,tm_sec  );
    fputs (") p_tm\t(fromIntegral sec  :: CInt)\n"
           "", stdout);
    hsc_line (502, "Time.hsc");
    fputs ("        (", stdout);
#line 502 "Time.hsc"
    hsc_poke (struct tm,tm_min  );
    fputs (") p_tm\t(fromIntegral min  :: CInt)\n"
           "", stdout);
    hsc_line (503, "Time.hsc");
    fputs ("        (", stdout);
#line 503 "Time.hsc"
    hsc_poke (struct tm,tm_hour );
    fputs (") p_tm\t(fromIntegral hour :: CInt)\n"
           "", stdout);
    hsc_line (504, "Time.hsc");
    fputs ("        (", stdout);
#line 504 "Time.hsc"
    hsc_poke (struct tm,tm_mday );
    fputs (") p_tm\t(fromIntegral mday :: CInt)\n"
           "", stdout);
    hsc_line (505, "Time.hsc");
    fputs ("        (", stdout);
#line 505 "Time.hsc"
    hsc_poke (struct tm,tm_mon  );
    fputs (") p_tm\t(fromIntegral (fromEnum mon) :: CInt)\n"
           "", stdout);
    hsc_line (506, "Time.hsc");
    fputs ("        (", stdout);
#line 506 "Time.hsc"
    hsc_poke (struct tm,tm_year );
    fputs (") p_tm\t(fromIntegral year - 1900 :: CInt)\n"
           "", stdout);
    hsc_line (507, "Time.hsc");
    fputs ("        (", stdout);
#line 507 "Time.hsc"
    hsc_poke (struct tm,tm_isdst);
    fputs (") p_tm\tisDst\n"
           "", stdout);
    hsc_line (508, "Time.hsc");
    fputs ("\tt <- throwIf (== -1) (\\_ -> \"Time.toClockTime: invalid input\")\n"
           "\t\t(mktime p_tm)\n"
           "        -- \n"
           "        -- mktime expects its argument to be in the local timezone, but\n"
           "        -- toUTCTime makes UTC-encoded CalendarTime\'s ...\n"
           "        -- \n"
           "        -- Since there is no any_tz_struct_tm-to-time_t conversion\n"
           "        -- function, we have to fake one... :-) If not in all, it works in\n"
           "        -- most cases (before, it was the other way round...)\n"
           "        -- \n"
           "        -- Luckily, mktime tells us, what it *thinks* the timezone is, so,\n"
           "        -- to compensate, we add the timezone difference to mktime\'s\n"
           "        -- result.\n"
           "        -- \n"
           "        gmtoff <- gmtoff p_tm\n"
           "\tlet res = fromIntegral t - tz + fromIntegral gmtoff\n"
           "\treturn (TOD (fromIntegral res) psec)\n"
           "", stdout);
#line 525 "Time.hsc"
#endif /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (526, "Time.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Converting time values to strings.\n"
           "\n"
           "calendarTimeToString  :: CalendarTime -> String\n"
           "calendarTimeToString  =  formatCalendarTime defaultTimeLocale \"%c\"\n"
           "\n"
           "formatCalendarTime :: TimeLocale -> String -> CalendarTime -> String\n"
           "formatCalendarTime l fmt (CalendarTime year mon day hour min sec _\n"
           "                                       wday yday tzname _ _) =\n"
           "        doFmt fmt\n"
           "  where doFmt (\'%\':\'-\':cs) = doFmt (\'%\':cs) -- padding not implemented\n"
           "        doFmt (\'%\':\'_\':cs) = doFmt (\'%\':cs) -- padding not implemented\n"
           "        doFmt (\'%\':c:cs)   = decode c ++ doFmt cs\n"
           "        doFmt (c:cs) = c : doFmt cs\n"
           "        doFmt \"\" = \"\"\n"
           "\n"
           "        decode \'A\' = fst (wDays l  !! fromEnum wday) -- day of the week, full name\n"
           "        decode \'a\' = snd (wDays l  !! fromEnum wday) -- day of the week, abbrev.\n"
           "        decode \'B\' = fst (months l !! fromEnum mon)  -- month, full name\n"
           "        decode \'b\' = snd (months l !! fromEnum mon)  -- month, abbrev\n"
           "        decode \'h\' = snd (months l !! fromEnum mon)  -- ditto\n"
           "        decode \'C\' = show2 (year `quot` 100)         -- century\n"
           "        decode \'c\' = doFmt (dateTimeFmt l)           -- locale\'s data and time format.\n"
           "        decode \'D\' = doFmt \"%m/%d/%y\"\n"
           "        decode \'d\' = show2 day                       -- day of the month\n"
           "        decode \'e\' = show2\' day                      -- ditto, padded\n"
           "        decode \'H\' = show2 hour                      -- hours, 24-hour clock, padded\n"
           "        decode \'I\' = show2 (to12 hour)               -- hours, 12-hour clock\n"
           "        decode \'j\' = show3 yday                      -- day of the year\n"
           "        decode \'k\' = show2\' hour                     -- hours, 24-hour clock, no padding\n"
           "        decode \'l\' = show2\' (to12 hour)              -- hours, 12-hour clock, no padding\n"
           "        decode \'M\' = show2 min                       -- minutes\n"
           "        decode \'m\' = show2 (fromEnum mon+1)          -- numeric month\n"
           "        decode \'n\' = \"\\n\"\n"
           "        decode \'p\' = (if hour < 12 then fst else snd) (amPm l) -- am or pm\n"
           "        decode \'R\' = doFmt \"%H:%M\"\n"
           "        decode \'r\' = doFmt (time12Fmt l)\n"
           "        decode \'T\' = doFmt \"%H:%M:%S\"\n"
           "        decode \'t\' = \"\\t\"\n"
           "        decode \'S\' = show2 sec\t\t\t     -- seconds\n"
           "        decode \'s\' = show2 sec\t\t\t     -- number of secs since Epoch. (ToDo.)\n"
           "        decode \'U\' = show2 ((yday + 7 - fromEnum wday) `div` 7) -- week number, starting on Sunday.\n"
           "        decode \'u\' = show (let n = fromEnum wday in  -- numeric day of the week (1=Monday, 7=Sunday)\n"
           "                           if n == 0 then 7 else n)\n"
           "        decode \'V\' =                                 -- week number (as per ISO-8601.)\n"
           "            let (week, days) =                       -- [yep, I\'ve always wanted to be able to display that too.]\n"
           "                   (yday + 7 - if fromEnum wday > 0 then \n"
           "                               fromEnum wday - 1 else 6) `divMod` 7\n"
           "            in  show2 (if days >= 4 then\n"
           "                          week+1 \n"
           "                       else if week == 0 then 53 else week)\n"
           "\n"
           "        decode \'W\' =\t\t\t\t     -- week number, weeks starting on monday\n"
           "            show2 ((yday + 7 - if fromEnum wday > 0 then \n"
           "                               fromEnum wday - 1 else 6) `div` 7)\n"
           "        decode \'w\' = show (fromEnum wday)            -- numeric day of the week, weeks starting on Sunday.\n"
           "        decode \'X\' = doFmt (timeFmt l)               -- locale\'s preferred way of printing time.\n"
           "        decode \'x\' = doFmt (dateFmt l)               -- locale\'s preferred way of printing dates.\n"
           "        decode \'Y\' = show year                       -- year, including century.\n"
           "        decode \'y\' = show2 (year `rem` 100)          -- year, within century.\n"
           "        decode \'Z\' = tzname                          -- timezone name\n"
           "        decode \'%\' = \"%\"\n"
           "        decode c   = [c]\n"
           "\n"
           "\n"
           "show2, show2\', show3 :: Int -> String\n"
           "show2 x\n"
           " | x\' < 10   = \'0\': show x\'\n"
           " | otherwise = show x\'\n"
           " where x\' = x `rem` 100\n"
           "\n"
           "show2\' x\n"
           " | x\' < 10   = \' \': show x\'\n"
           " | otherwise = show x\'\n"
           " where x\' = x `rem` 100\n"
           "\n"
           "show3 x = show (x `quot` 100) ++ show2 (x `rem` 100)\n"
           " where x\' = x `rem` 1000\n"
           "\n"
           "to12 :: Int -> Int\n"
           "to12 h = let h\' = h `mod` 12 in if h\' == 0 then 12 else h\'\n"
           "\n"
           "-- Useful extensions for formatting TimeDiffs.\n"
           "\n"
           "timeDiffToString :: TimeDiff -> String\n"
           "timeDiffToString = formatTimeDiff defaultTimeLocale \"%c\"\n"
           "\n"
           "formatTimeDiff :: TimeLocale -> String -> TimeDiff -> String\n"
           "formatTimeDiff l fmt td@(TimeDiff year month day hour min sec _)\n"
           " = doFmt fmt\n"
           "  where \n"
           "   doFmt \"\"         = \"\"\n"
           "   doFmt (\'%\':\'-\':cs) = doFmt (\'%\':cs) -- padding not implemented\n"
           "   doFmt (\'%\':\'_\':cs) = doFmt (\'%\':cs) -- padding not implemented\n"
           "   doFmt (\'%\':c:cs) = decode c ++ doFmt cs\n"
           "   doFmt (c:cs)     = c : doFmt cs\n"
           "\n"
           "   decode spec =\n"
           "    case spec of\n"
           "      \'B\' -> fst (months l !! fromEnum month)\n"
           "      \'b\' -> snd (months l !! fromEnum month)\n"
           "      \'h\' -> snd (months l !! fromEnum month)\n"
           "      \'c\' -> defaultTimeDiffFmt td\n"
           "      \'C\' -> show2 (year `quot` 100)\n"
           "      \'D\' -> doFmt \"%m/%d/%y\"\n"
           "      \'d\' -> show2 day\n"
           "      \'e\' -> show2\' day\n"
           "      \'H\' -> show2 hour\n"
           "      \'I\' -> show2 (to12 hour)\n"
           "      \'k\' -> show2\' hour\n"
           "      \'l\' -> show2\' (to12 hour)\n"
           "      \'M\' -> show2 min\n"
           "      \'m\' -> show2 (fromEnum month + 1)\n"
           "      \'n\' -> \"\\n\"\n"
           "      \'p\' -> (if hour < 12 then fst else snd) (amPm l)\n"
           "      \'R\' -> doFmt \"%H:%M\"\n"
           "      \'r\' -> doFmt (time12Fmt l)\n"
           "      \'T\' -> doFmt \"%H:%M:%S\"\n"
           "      \'t\' -> \"\\t\"\n"
           "      \'S\' -> show2 sec\n"
           "      \'s\' -> show2 sec -- Implementation-dependent, sez the lib doc..\n"
           "      \'X\' -> doFmt (timeFmt l)\n"
           "      \'x\' -> doFmt (dateFmt l)\n"
           "      \'Y\' -> show year\n"
           "      \'y\' -> show2 (year `rem` 100)\n"
           "      \'%\' -> \"%\"\n"
           "      c   -> [c]\n"
           "\n"
           "   defaultTimeDiffFmt (TimeDiff year month day hour min sec _) =\n"
           "       foldr (\\ (v,s) rest -> \n"
           "                  (if v /= 0 \n"
           "                     then show v ++ \' \':(addS v s)\n"
           "                       ++ if null rest then \"\" else \", \"\n"
           "                     else \"\") ++ rest\n"
           "             )\n"
           "             \"\"\n"
           "             (zip [year, month, day, hour, min, sec] (intervals l))\n"
           "\n"
           "   addS v s = if abs v == 1 then fst s else snd s\n"
           "\n"
           "", stdout);
#line 667 "Time.hsc"
#ifndef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (668, "Time.hsc");
    fputs ("-- -----------------------------------------------------------------------------\n"
           "-- Foreign time interface (POSIX)\n"
           "\n"
           "type CTm = () -- struct tm\n"
           "\n"
           "", stdout);
#line 673 "Time.hsc"
#if HAVE_LOCALTIME_R
    fputs ("\n"
           "", stdout);
    hsc_line (674, "Time.hsc");
    fputs ("foreign import ccall unsafe localtime_r :: Ptr CTime -> Ptr CTm -> IO (Ptr CTm)\n"
           "", stdout);
#line 675 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (676, "Time.hsc");
    fputs ("foreign import ccall unsafe localtime   :: Ptr CTime -> IO (Ptr CTm)\n"
           "", stdout);
#line 677 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (678, "Time.hsc");
    fputs ("", stdout);
#line 678 "Time.hsc"
#if HAVE_GMTIME_R
    fputs ("\n"
           "", stdout);
    hsc_line (679, "Time.hsc");
    fputs ("foreign import ccall unsafe gmtime_r    :: Ptr CTime -> Ptr CTm -> IO (Ptr CTm)\n"
           "", stdout);
#line 680 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (681, "Time.hsc");
    fputs ("foreign import ccall unsafe gmtime      :: Ptr CTime -> IO (Ptr CTm)\n"
           "", stdout);
#line 682 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (683, "Time.hsc");
    fputs ("foreign import ccall unsafe mktime      :: Ptr CTm   -> IO CTime\n"
           "foreign import ccall unsafe time        :: Ptr CTime -> IO CTime\n"
           "\n"
           "", stdout);
#line 686 "Time.hsc"
#if HAVE_GETTIMEOFDAY
    fputs ("\n"
           "", stdout);
    hsc_line (687, "Time.hsc");
    fputs ("type CTimeVal = ()\n"
           "foreign import ccall unsafe gettimeofday :: Ptr CTimeVal -> Ptr () -> IO CInt\n"
           "", stdout);
#line 689 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (690, "Time.hsc");
    fputs ("\n"
           "", stdout);
#line 691 "Time.hsc"
#if HAVE_FTIME
    fputs ("\n"
           "", stdout);
    hsc_line (692, "Time.hsc");
    fputs ("type CTimeB = ()\n"
           "", stdout);
#line 693 "Time.hsc"
#ifndef mingw32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (694, "Time.hsc");
    fputs ("foreign import ccall unsafe ftime :: Ptr CTimeB -> IO CInt\n"
           "", stdout);
#line 695 "Time.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (696, "Time.hsc");
    fputs ("foreign import ccall unsafe ftime :: Ptr CTimeB -> IO ()\n"
           "", stdout);
#line 697 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (698, "Time.hsc");
    fputs ("", stdout);
#line 698 "Time.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (699, "Time.hsc");
    fputs ("", stdout);
#line 699 "Time.hsc"
#endif /* ! __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (700, "Time.hsc");
    fputs ("", stdout);
    return 0;
}
