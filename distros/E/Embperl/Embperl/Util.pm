
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
#   $Id: Util.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Util ;

use strict ;
use vars qw{@AliasScalar @AliasHash @AliasArray %NameSpace} ;

#######################################################################################

sub AddCompartment ($)

    {
    my ($sName) = @_ ;
    my $cp ;
    
    return $cp if (defined ($cp = $NameSpace{$sName})) ;

    #eval 'require Safe' ;
    #die "require Safe failed: $@" if ($@); 
    require Safe ;

    $cp = new Safe ($sName) ;
    
    $NameSpace{$sName} = $cp ;

    return $cp ;
    }

#######################################################################################

sub MailFormTo

    {
    $Embperl::req -> app -> mail_form_to (@_) ;
    }

#######################################################################################


@AliasScalar = qw{row col cnt tabmode escmode req_rec maxrow maxcol req_rec 
                    dbgAll            dbgAllCmds        dbgCmd            dbgDefEval        dbgEarlyHttpHeader
                    dbgEnv            dbgEval           dbgFlushLog       dbgFlushOutput    dbgForm           
                    dbgFunc           dbgHeadersIn      dbgImport         dbgInput          dbgLogLink        
                    dbgMem            dbgProfile        dbgShowCleanup    dbgSource         dbgStd            
                    dbgSession        dbgTab            dbgWatchScalar    dbgParse          dbgObjectSearch   
                    optDisableChdir           optDisableEmbperlErrorPage    optReturnError	       optDisableFormData        
                    optDisableHtmlScan        optDisableInputScan       optDisableMetaScan        optDisableTableScan       
                    optDisableSelectScan      optDisableVarCleanup      optEarlyHttpHeader        optOpcodeMask             
                    optRawInput               optSafeNamespace          optSendHttpHeader         optAllFormData            
                    optRedirectStdout         optUndefToEmptyValue      optNoHiddenEmptyValue     optAllowZeroFilesize      
                    optKeepSrcInMemory        optKeepSpaces	       optOpenLogEarly           optNoUncloseWarn	       
		    _ep_node
                    } ;
@AliasHash   = qw{fdat udat mdat sdat idat http_headers_out fsplitdat} ;
@AliasArray  = qw{ffld param} ;


#######################################################################################


sub CreateAliases

    {
    my $package = caller ;

    my $dummy ;
        
    no strict ;

    if (!defined(${"$package\:\:row"}))
        { # create new aliases for Embperl magic vars

        foreach (@AliasScalar)
            {
            *{"$package\:\:$_"}    = \${"Embperl\:\:$_"} ;
            $dummy = ${"$package\:\:$_"} ; # necessary to make sure variable exists!
            }
        *{"$package\:\:epreq"} = \$Embperl::req ;
        *{"$package\:\:epapp"} = \$Embperl::app ;

        foreach (@AliasHash)
            {
            *{"$package\:\:$_"}    = \%{"Embperl\:\:$_"} ;
            }
        foreach (@AliasArray)
            {
            *{"$package\:\:$_"}    = \@{"Embperl\:\:$_"} ;
            }


        my $sess ;
        $sess = $Embperl::req -> app -> udat ;
        *{"$package\:\:udat"} = $sess if ($sess) ;
        $sess = $Embperl::req -> app -> mdat ;
        *{"$package\:\:mdat"} = $sess if ($sess) ;
        $sess = $Embperl::req -> app -> sdat ;
        *{"$package\:\:sdat"} = $sess if ($sess) ;

        *{"$package\:\:exit"}       = \&Embperl::exit ;
        *{"$package\:\:MailFormTo"} = \&Embperl::Util::MailFormTo ;
        *{"$package\:\:Execute"}    = \&Embperl::Req::ExecuteComponent ;

        tie *{"$package\:\:LOG"}, 'Embperl::Log' ;
        tie *{"$package\:\:OUT"}, 'Embperl::Out' ;

	my $addcleanup = \%{"$package\:\:CLEANUP"} ;
	$addcleanup -> {'CLEANUP'} = 0 ;
	$addcleanup -> {'EXPIRES'} = 0 ;
	$addcleanup -> {'CACHE_KEY'} = 0 ;
	$addcleanup -> {'OUT'} = 0 ;
	$addcleanup -> {'LOG'} = 0 ;
        }



    use strict ;
    }

#######################################################################################

1;
