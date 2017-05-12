****************************************************************
The LReport module is Copyright (c) 2004,2006 Piotr Kaluski. Poland. 
All rights reserved.
You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file.
****************************************************************

This is the release 0.16 of LReport library. 

LReport is a set of tools for comparing csv files.

You can find documentation on the module on my website:
http://lreport.sourceforge.net

NOTES:
* TUNNING:
   * Done some refactoring in order to improve performance. There is still some
     space for improvement. Collection::build_one_key should be better
     tuned, rows should be stored in lists rather then in hashes
* Command line switches and environment variables
   * Handling of the most important command line switches and environment
     variables is implemented.
   * Still some minor configurability to be done
* BUG fixes
   * 1544069 - Change sign make diff output look cluttered - --#> used now.   
* Features
   * 1544070 - Diff should not pick unecessary files - only files with
               proper extension are used
* Note: Documentation needs some refinements to reflect changes
