###################################################################################
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
#   $Id: Cmd.xs 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################



MODULE = Embperl::Cmd      PACKAGE = Embperl::Cmd     PREFIX = embperl_


#void
#embperl_InputText (xDomTree, xNode, sName)
#    int xDomTree
#    int xOldChild
#    char * sName
#CODE:
    


void
embperl_InputCheck (xDomTree, xNode, sName, sValue, bSetInSource)
    int xDomTree
    int xNode
    SV * sName
    SV * sValue
    SV * bSetInSource 
CODE:
    STRLEN nName ;
    STRLEN nValue ;
    char * sN = SV2String (sName, nName) ;
    char * sV = SV2String (sValue, nValue) ;
    embperlCmd_InputCheck (CurrReq, DomTree_self (xDomTree), xNode, CurrReq -> Component.nCurrRepeatLevel, sN, nName, sV, nValue, SvOK (bSetInSource)?1:0) ;
    

void
embperl_Option (xDomTree, xNode, sName, sValue, bSetInSource)
    int xDomTree
    int xNode
    SV * sName
    SV * sValue
    SV * bSetInSource 
CODE:
    STRLEN nName ;
    STRLEN nValue ;
    char * sN = SV2String (sName, nName) ;
    char * sV = SV2String (sValue, nValue) ;
    embperlCmd_Option (CurrReq, DomTree_self (xDomTree), xNode, CurrReq -> Component.nCurrRepeatLevel, sN, nName, sV, nValue,  SvOK (bSetInSource)?1:0) ;
    

void
embperl_Hidden (xDomTree, xNode, sArg)
    int xDomTree
    int xNode
    char * sArg
CODE:
    embperlCmd_Hidden (CurrReq, DomTree_self (xDomTree), xNode, CurrReq -> Component.nCurrRepeatLevel, sArg) ;
    

void
embperl_AddSessionIdToLink (xDomTree, xNode, nAddSess, ...)
    int xDomTree
    int xNode
    int nAddSess
PREINIT:
    int i ;
    STRLEN l ;
CODE:
    if (nAddSess == 2)
        {
        embperlCmd_AddSessionIdToHidden (CurrReq, DomTree_self (xDomTree), xNode, CurrReq -> Component.nCurrRepeatLevel) ;
        }
    else
        {
        for (i = 3; i < items; i++)
            {
            embperlCmd_AddSessionIdToLink (CurrReq, DomTree_self (xDomTree), xNode, CurrReq -> Component.nCurrRepeatLevel, (char *)SvPV(ST(i), l)) ;
            }
        }

void
embperl_SubStart (pDomTreeSV, xDomTree, pSaveAV)
    SV * pDomTreeSV 
    int  xDomTree
    AV * pSaveAV
CODE:
    embperl_ExecuteSubStart (CurrReq, pDomTreeSV, xDomTree, pSaveAV) ;


void
embperl_SubEnd (pDomTreeSV, pSaveAV)
    SV * pDomTreeSV 
    AV * pSaveAV
CODE:
    embperl_ExecuteSubEnd (CurrReq, pDomTreeSV, pSaveAV) ;

