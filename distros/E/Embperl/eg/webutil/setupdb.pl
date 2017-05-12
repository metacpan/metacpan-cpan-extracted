#!/usr/bin/perl
##############################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: setupdb.pl 1578075 2014-03-16 14:01:14Z richter $
#
##############################################################################


use FindBin ;
use DBIx::Recordset ;
use Getopt::Long ;

GetOptions ("debug|d:i") ;


$DBIx::Recordset::Debug = $opt_debug ;



if ($^O eq 'MSWin32')
    {
    $user = '' ;
    $suuser = '' ;
    $supass = '' ;
    $ds = 'dbi:ODBC:embperl' ;
    }
else
    {
    $user = 'www' ;
    $suuser = 'root' ;
    $supass = '' ;
    $ds = 'dbi:mysql:embperl' ;
    }

    
$DBIx::Recordset::Debug = $opt_debug ;

my $dbshema     = "$FindBin::Bin/db.schema" ;

    
my $db = DBIx::Database -> new ({'!DataSource' => $ds,
                                 '!Username'   => $suuser,
                                 '!Password'   => $supass,
                                 '!KeepOpen'   => 1,
                                 }) ;
  
die DBIx::Database->LastError . "; Datenbank muß bereits bestehen" if (DBIx::Database->LastError) ;
  

$db -> CreateTables ($dbshema, '', $user)  ;


