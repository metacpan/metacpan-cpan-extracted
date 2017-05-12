
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Run.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Run ;

use Embperl ;
use Embperl::Constant ;
use Embperl::Log ;

use Getopt::Long ;



sub run (;\@$)
    
    {
    @ARGV = @{$_[0]} if (ref $_[0] eq 'ARRAY') ;

    eval { Getopt::Long::Configure ('bundling') } ;
    $@ = "" ;
    my %param ;
    my $ret = GetOptions (\%param, 
                          "outputfile|o=s", "inputfile|i=s", 
                          "log|l=s", "debug|d=i", "options|t=i",
                          "param|p=s@", "syntax|s=s", "fdat|f=s%") ;
    
    return undef if (!$ret) ;

    if (@ARGV)
    	{
    	$ENV{PATH_TRANSLATED} = $param{'inputfile'} = shift @ARGV ;
    	}		

    if (@ARGV)
    	{
        $ENV{QUERY_STRING} = shift @ARGV ;
        undef $ENV{CONTENT_LENGTH} if (defined ($ENV{CONTENT_LENGTH})) ;
    	}		
	
   
    $param{'param'} = $_[1] if (defined ($_[1])) ;
    $param{'use_env'} = 1 ;

    $rc = Embperl::Execute (\%param) ;

    return $rc ;
    }

1 ;

