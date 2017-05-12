
###################################################################################
#
#   Embperl - Copyright (c) 1997-2001 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Embperl.pm,v 1.177.2.2 2003/01/22 09:08:19 richter Exp $
#
###################################################################################


package HTML::Embperl;



require Cwd ;

require Exporter;
require DynaLoader;

use strict ;
use vars qw(
    $DefaultLog 
    $DebugDefault
    
    %cache
    %mtime
    %filepack
    $packno

    @cleanups
    
    $LogOutputFileno
    %LogFileColors
    %NameSpace
    @ISA
    $VERSION
    
    %watchval

    $cwd
    
    $evalpackage

    $SessionMgnt
    $DefaultIDLength

    $pathsplit

    @AliasScalar 
    @AliasHash 
    @AliasArray

    $dummy
    ) ;


@ISA = qw(Exporter DynaLoader);


$VERSION = '1.3.6';

# HTML::Embperl cannot be bootstrapped in nonlazy mode except
# under mod_perl, because its dependencies import symbols like ap_palloc
# from apache.
# DynaLoader checks PERL_DL_NONLAZY only in its boot function, which
# may have been called previously.  This causes "make test" to fail
# on certain platforms in modules that use Embperl after loading some
# other module that also uses DynaLoader.
# Here we detect this unfortunate situation and correct it by re-executing
# DynaLoader's boot function. 
if ($ENV{PERL_DL_NONLAZY}
	&& substr($ENV{GATEWAY_INTERFACE} || '', 0, 8) ne 'CGI-Perl'
	&& defined &DynaLoader::boot_DynaLoader)
    {
    $ENV{PERL_DL_NONLAZY} = '0';
    DynaLoader::boot_DynaLoader ('DynaLoader');
    }


bootstrap HTML::Embperl $VERSION;



# Default logfilename

$DefaultLog = '/tmp/embperl.log' ;

%cache    = () ;    # cache for evaled code
%filepack = () ;    # translate filename to packagename
$packno   = 1 ;     # for assigning unique packagenames

@cleanups = () ;    # packages which need a cleanup
$LogOutputFileno = 0 ;
$pathsplit = $^O eq 'MSWin32'?';':';|:' ;   # separators for path

# setup constans

use constant dbgAll                 => -1 ;
use constant dbgAllCmds             => 1024 ;
use constant dbgCmd                 => 8 ;
use constant dbgDefEval             => 16384 ;
use constant dbgEarlyHttpHeader     => 65536 ;
use constant dbgEnv                 => 16 ;
use constant dbgEval                => 4 ;
use constant dbgFlushLog            => 512 ;
use constant dbgFlushOutput         => 256 ;
use constant dbgForm                => 32 ;
use constant dbgFunc                => 4096 ;
use constant dbgHeadersIn           => 262144 ;
use constant dbgImport              => 0x400000 ;
use constant dbgInput               => 128 ;
use constant dbgLogLink             => 8192 ;
use constant dbgMem                 => 2 ;
use constant dbgProfile             => 0x100000 ;
use constant dbgShowCleanup         => 524288 ;
use constant dbgSource              => 2048 ;
use constant dbgStd                 => 1 ;
use constant dbgSession             => 0x200000 ;
use constant dbgTab                 => 64 ;
use constant dbgWatchScalar         => 131072 ;
use constant dbgParse               => 0x1000000 ; # reserved for Embperl 2.x
use constant dbgObjectSearch        => 0x2000000 ;

use constant epIOCGI                => 1 ;
use constant epIOMod_Perl           => 3 ;
use constant epIOPerl               => 4 ;
use constant epIOProcess            => 2 ;

use constant escHtml                => 1 ;
use constant escNone                => 0 ;
use constant escStd                 => 3 ;
use constant escUrl                 => 2 ;
use constant escEscape              => 4 ;


use constant optDisableChdir            => 128 ;
use constant optDisableEmbperlErrorPage => 2 ;
use constant optReturnError	        => 0x40000 ;
use constant optDisableFormData         => 256 ;
use constant optDisableHtmlScan         => 512 ;
use constant optDisableInputScan        => 1024 ;
use constant optDisableMetaScan         => 4096 ;
use constant optDisableTableScan        => 2048 ;
use constant optDisableSelectScan       => 0x800000 ;
use constant optDisableVarCleanup       => 1 ;
use constant optEarlyHttpHeader         => 64 ;
use constant optOpcodeMask              => 8 ;
use constant optRawInput                => 16 ;
use constant optSafeNamespace           => 4 ;
use constant optSendHttpHeader          => 32 ;
use constant optAllFormData             => 8192 ;
use constant optRedirectStdout          => 16384 ;
use constant optUndefToEmptyValue       => 32768 ;
use constant optNoHiddenEmptyValue      => 0x10000 ;
use constant optAllowZeroFilesize       => 0x20000 ;
use constant optKeepSrcInMemory         => 0x80000 ;
use constant optKeepSpaces	        => 0x100000 ;
use constant optOpenLogEarly            => 0x200000 ;
use constant optNoUncloseWarn	        => 0x400000 ;


use constant ok                     => 0 ;
use constant rcArgStackOverflow => 23 ;
use constant rcArrayError => 11 ;
use constant rcCannotUsedRecursive => 19 ;
use constant rcCmdNotFound => 7 ;
use constant rcElseWithoutIf => 4 ;
use constant rcEndifWithoutIf => 3 ;
use constant rcEndtableWithoutTable => 6 ;
use constant rcEndtableWithoutTablerow => 20 ;
use constant rcEndtextareaWithoutTextarea => 22 ;
use constant rcEndwhileWithoutWhile => 5 ;
use constant rcEvalErr => 24 ;
use constant rcExecCGIMissing => 27 ;
use constant rcFileOpenErr => 12 ;
use constant rcHashError => 10 ;
use constant rcInputNotSupported => 18 ;
use constant rcIsDir => 28 ;
use constant rcLogFileOpenErr => 26 ;
use constant rcMagicError => 15 ;
use constant rcMissingRight => 13 ;
use constant rcNoRetFifo => 14 ;
use constant rcNotCompiledForModPerl => 25 ;
use constant rcNotFound => 30 ;
use constant rcOutOfMemory => 8 ;
use constant rcPerlVarError => 9 ;
use constant rcPerlWarn => 32 ;
use constant rcStackOverflow => 1 ;
use constant rcStackUnderflow => 2 ;
use constant rcUnknownNameSpace => 17 ;
use constant rcUnknownVarType => 31 ;
use constant rcVirtLogNotSet => 33 ;
use constant rcWriteErr => 16 ;
use constant rcXNotSet => 29 ;
use constant rcCallInputFuncFailed => 40 ;
use constant rcCallOutputFuncFailed => 41 ;
use constant rcSubNotFound => 42 ;
use constant rcImportStashErr => 43 ;
use constant rcCGIError => 44 ;
use constant rcUnclosedHtml => 45 ;
use constant rcUnclosedCmd => 46 ;
use constant rcNotAllowed => 47 ;

$DebugDefault = dbgStd ;

# Color definition for logfile output

%LogFileColors = (
    'EVAL<' => '#FF0000',
    'EVAL>' => '#FF0000',
    'FORM:' => '#0000FF',
    'CMD:'  => '#FF8000',
    'SRC:'  => '#808080',
    'TAB:'  => '#FF0080',
    'INPU:' => '#008040',
                ) ;
#######################################################################################

BEGIN
    {
    @AliasScalar = qw{row col cnt maxrow maxcol tabmode escmode req_rec  
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
                        } ;
    @AliasHash   = qw{fdat udat mdat sdat idat http_headers_out fsplitdat} ;
    @AliasArray  = qw{ffld} ;
    } ;

use vars (map { "\$$_" } @AliasScalar) ;
use vars (map { "\%$_" } @AliasHash) ;
use vars (map { "\@$_" } @AliasArray) ;


no strict ;
foreach (@HTML::Embperl::AliasScalar)
    {
    $dummy = ${"HTML::Embperl\:\:$_"} ; # necessary to make sure variable exists!
    $dummy = ${"HTML::Embperl\:\:$_"} ; # necessary to make sure variable exists!
    }
use strict ;

#######################################################################################
#
# tie for logfile output
#

    {
    package HTML::Embperl::Log ;


    sub TIEHANDLE 

        {
        my $class ;
        
        return bless \$class, shift ;
        }


    sub PRINT

        {
        shift ;
        HTML::Embperl::log(join ('', @_)) ;
        }

    sub PRINTF

        {
        shift ;
        my $fmt = shift ;
        HTML::Embperl::log(sprintf ($fmt, @_)) ;
        }

    sub CLOSE

	{
	}


    }



#######################################################################################
#
# tie for output
#

    {
    package HTML::Embperl::Out ;


    sub TIEHANDLE 

        {
        my $class ;
        
        return bless \$class, shift ;
        }


    sub PRINT

        {
        shift ;
        HTML::Embperl::output(join ('', @_)) ;
        }

    sub PRINTF

        {
        shift ;
        my $fmt = shift ;
        HTML::Embperl::output(sprintf ($fmt, @_)) ;
        }

    sub CLOSE

	{
	}

    }




#######################################################################################
#
# init on startup
#

$DefaultLog = $ENV{EMBPERL_LOG} || $DefaultLog ;
if (defined ($ENV{MOD_PERL}))
    { 
    eval 'use Apache' ; # make sure Apache.pm is loaded (is not at server startup in mod_perl < 1.11)
    die "use Apache failed: $@" if ($@); 
    eval 'use Apache::Constants qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN &NOT_FOUND) ;' ;
    die "use Apache::Constants failed: $@" if ($@); 

    XS_Init (epIOMod_Perl, $DefaultLog, $DebugDefault) ;
    }
else
    {
    eval 'sub OK        { 0 ;   }' ;
    eval 'sub NOT_FOUND { 404 ; }' ;
    eval 'sub FORBIDDEN { 403 ; }' ;
    eval 'sub DECLINED  { 403 ; }' ; # in non mod_perl environment, same as FORBIDDEN
no strict ;
    XS_Init (epIOPerl, $DefaultLog, $DebugDefault) ;
use strict ;
    }

$cwd       = Cwd::fastcwd();

tie *LOG, 'HTML::Embperl::Log' ;
tie *OUT, 'HTML::Embperl::Out' ;

# ----------------------------------------------------------------------------
#
# Setup Sessionhandling
#

use Text::ParseWords ;

$SessionMgnt = 0 ;

{
my %sargs = (
    lazy	   => 1,
    create_unknown => 1,
    ) ;
my $session_handler = $ENV{EMBPERL_SESSION_HANDLER_CLASS} || 'Apache::SessionX' ; 
my $ver = ''  ;

if (defined ($ENV{EMBPERL_SESSION_ARGS}))
    {
    my @arglist = quotewords ('\s+', 0, $ENV{EMBPERL_SESSION_ARGS}) ;
    foreach (@arglist)
	{
	/^(.*?)\s*=\s*(.*?)$/ ;
	$sargs{$1} = $2 ;
	}
    }

if (defined ($ENV{EMBPERL_SESSION_CLASSES}))
    { # Apache::Session 1.xx
    my ($os, $lm, $ser, $gen) = split /\s*,\s*|\s+/, $ENV{EMBPERL_SESSION_CLASSES} ;
    if (!$os || !$lm)
        {
        warn "[$$]SES:  EMBPERL_SESSION_CLASSES must be set properly (is $ENV{EMBPERL_SESSION_CLASSES})" ;
        $session_handler = 'no' ;
        }
    else
        {
	$ser ||= 'Storable' ;
	$gen ||= 'MD5' ;
        
        if ($Apache::Session::VERSION =~ /^1\.0\d$/)
            {
	    $sargs{object_store} = $os ;
	    $sargs{lock_manager} = $lm ;
            $ver = '1.0x' ;
	    $DefaultIDLength = 16 ; 	
            }
        else
            { # Apache::Session >= 1.50
	    $sargs{Store} = $os ;
	    $sargs{Lock} = $lm ;
	    $sargs{Generate} = $gen ;
	    $sargs{Serialize} = $ser ;
            $ver = '>= 1.50' ;
	    $DefaultIDLength = 32 ; 	
            }
        }
    }

if (defined ($ENV{EMBPERL_SESSION_CONFIG}))
    {
    $sargs{config} = $ENV{EMBPERL_SESSION_CONFIG} ;
    }

if ($session_handler ne 'no') 
    { 
    eval "require $session_handler" ;
    if ($@)
        { 
        warn "[$$]SES:  Embperl Session management DISABLED beause of following error: $@\n" .
             "Set \$ENV{EMBPERL_SESSION_HANDLER_CLASS} to 'no' before loading Embperl to avoid this message" if ($ENV{GATEWAY_INTERFACE}) ;
        $SessionMgnt = 0 ;
        }
    else
        {             
        tie %mdat, $session_handler, undef, {%sargs, Transaction => 1} ;
        tie %udat, $session_handler, undef, {%sargs, recreate_id => 1} ;
        tie %sdat, $session_handler, undef, {%sargs, recreate_id => 1, newid => 1} ;
        $SessionMgnt = 2 ;
        warn "[$$]SES:  Embperl Session management enabled ($ver)\n" if ($ENV{MOD_PERL}) ;
        }
    }
}


#######################################################################################

sub Warn 
    {
    local $^W = 0 ;
    my $msg = $_[0] ;
    chop ($msg) ;
    
    my $lineno = getlineno () ;
    my $Inputfile = Sourcefile () ;
    if ($msg =~ /HTML\/Embperl/)
        {
        $msg =~ s/at (.*?) line (\d*)/at $Inputfile in block starting at line $lineno/ ;
        }
    logerror (rcPerlWarn, $msg);
    }

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

sub SendLogFile ($$$)

    {
    my ($fn, $info, $req_rec) = @_ ;
    
    my $lastpid = 0 ;
    my ($filepos, $pid, $src) = split (/&/, $info) ;
    my $cnt = 0 ;
    my $ecnt = 0 ;
    my $tag ;
    my $fontcol ;

    if (defined ($req_rec))
        {
        $req_rec -> content_type ('text/html') ;
        $req_rec -> send_http_header ;
        }
        
    open (LOGFILE, $fn) || return 500 ;

    seek (LOGFILE, $filepos, 0) || return 500 ;

    print "<HTML><HEAD><TITLE>Embperl Logfile</TITLE></HEAD><BODY bgcolor=\"#FFFFFF\">\r\n" ;
    print "<font color=0>" ;
    print "Logfile = $fn, Position = $filepos, Pid = $pid<BR><CODE>\r\n" ;
    $fontcol = 0 ;

    while (<LOGFILE>)
        {
        $cnt++ ;
        if (!(/^\[(\d+)\](.*?)\s/) || ($1 == $pid && (!defined($src) || $2 eq $src)))
            {
            $tag = $2 ;
            if (defined ($LogFileColors{$tag}))
                {
                if ($fontcol ne $LogFileColors{$tag})
                    {
                    $fontcol = $LogFileColors{$tag} ;
                    print "</font><font color=\"$fontcol\">" ;
                    }
                }
            else
                {
                if ($fontcol ne '0')
                    {
                    $fontcol = '0' ;
                    print "</font><font color=0>" ;
                    }
                }
            #s/\n/\\<BR\\>\r\n/ ;
            s/&/&amp;/g;
            s/\"/&quot;/g;
            s/>/&gt;/g;
            s/</&lt;/g;
            s/\n/\<BR\>\r\n/ ;
            if (defined($src) && ($tag eq $src || $tag eq 'ERR:'))
                {
                if ($tag eq 'ERR:')
                    { print "<A HREF=\"$ENV{EMBPERL_VIRTLOG}?$filepos&$pid#E$ecnt\">" ; $ecnt++ ; }
                else
                    { print "<A HREF=\"$ENV{EMBPERL_VIRTLOG}?$filepos&$pid#N$cnt\">" ;  }
                }
            else
                {
                if ($tag eq 'ERR:')
                    { print "<A NAME=\"E$ecnt\">" ; $ecnt++; }
                else
                    { print "<A NAME=\"N$cnt\">" ; }
                }

            
            print $_ ;
            print '</A>' ;
            last if (/\]Request finished/) ;
            }
        }

    print "</CODE></BODY></HTML>\r\n\r\n" ;

    close (LOGFILE) ;

    return 200 ;
    }



##########################################################################################

sub CheckFile

    {
    my ($filename, $req_rec, $AllowZeroFilesize, $allow, $pathref, $pathndxref, $debug) = @_ ;

    my $path = $$pathref ;
    my $pathndx = $$pathndxref ;

    if ($filename eq '')
        {
        logerror (rcNotFound, '<no filename>');
	return &NOT_FOUND ;
        }

    if (-d $filename)
        {
	#logerror (rcIsDir, $filename);
	return &DECLINED ; # let Apache handle directories
	}                 

    if (defined ($allow) && !($filename =~ /$allow/))
        {
	logerror (rcNotAllowed, $filename, $req_rec);
	return &FORBIDDEN ;
 	}
	
    if (defined ($req_rec) && !($req_rec->allow_options & &OPT_EXECCGI))
        {
	logerror (rcExecCGIMissing, $filename);
	return &FORBIDDEN ;
 	}

    if ($path && !($filename =~ m{^(/|\\|\w:/|\w:\\|\./|\.\\)}))
        {
        my $skip = 0 ;
        if ($filename =~ m{^(\.\./|\.\.\\)+?.*?(/|\\)*?(.*?)$}) 
            {
            $filename = $3 ;
            $skip = length ($1) / 3  ;
            }
        my $pathskip = $skip ;
        $skip += $pathndx if ($skip) ;
	$pathndx = 0 if (!$skip) ;
        my @path = split /$pathsplit/o, $path ;
        shift @path while (!$path[0]) ;
        shift @path while ($skip--) ;
        my $fn = '' ;
        print LOG "[$$]Embperl path search Path: " . join (';',@path) . " Filename: $filename\n" if ($debug);
        print LOG "[$$]Embperl path search pathskip = $pathskip  pathndx = $pathndx\n" if ($debug);

        #$$pathref = join (';', @path) ;

        foreach (@path)
            {
            next if (!$_) ;
            $fn = "$_/$filename" ;
            print LOG "[$$]Embperl path search Check: $fn\n" if ($debug);
            if (-r $fn && (-s _ || $AllowZeroFilesize))
                {
                $$pathndxref = $pathndx + $pathskip ;
                if (defined ($allow) && !($fn =~ /$allow/))
                    {
	            logerror (rcNotAllowed, $fn, $req_rec);
	            return &FORBIDDEN ;
 	            }
                $_[0] = $fn ;
                return ok ;
                }
            $pathndx++  ;
            }

        -r $filename ;
        }            

    unless (-r _ && (-s _ || $AllowZeroFilesize))
        {
        logerror (rcNotFound, $filename);
	return &NOT_FOUND ;
        }

    return ok ;
    }


##########################################################################################

sub ScanEnvironment

    {
    my ($req, $req_rec) = @_ ; 

    if (defined ($req_rec))
	{
	my $k ;
	my $v ;
	my %cgienv = $req_rec->cgi_env ;
        while (($k, $v) = each %cgienv)
		{
                #warn "env $k = ->$v<->env=$ENV{$k}<-" ;
                $ENV{$k} = $v if (!exists $ENV{$k}) ;
		}
	}

    $$req{'virtlog'}     = $ENV{EMBPERL_VIRTLOG}     if (exists ($ENV{EMBPERL_VIRTLOG})) ;
    $$req{'compartment'} = $ENV{EMBPERL_COMPARTMENT} if (exists ($ENV{EMBPERL_COMPARTMENT})) ;
    $$req{'package'}     = $ENV{EMBPERL_PACKAGE}     if (exists ($ENV{EMBPERL_PACKAGE})) ;
    $$req{'input_func'}  = $ENV{EMBPERL_INPUT_FUNC}  if (exists ($ENV{EMBPERL_INPUT_FUNC})) ;
    $$req{'output_func'} = $ENV{EMBPERL_OUTPUT_FUNC} if (exists ($ENV{EMBPERL_OUTPUT_FUNC})) ;
    $$req{'allow'}       = $ENV{EMBPERL_ALLOW}       if (exists ($ENV{EMBPERL_ALLOW})) ;
    $$req{'filesmatch'}  = $ENV{EMBPERL_FILESMATCH}  if (exists ($ENV{EMBPERL_FILESMATCH})) ;
    $$req{'decline'}     = $ENV{EMBPERL_DECLINE}     if (exists ($ENV{EMBPERL_DECLINE})) ;
    $$req{'debug'}       = $ENV{EMBPERL_DEBUG}   || 0 ;
    $$req{'debug'} = oct($$req{'debug'}) if ($$req{'debug'} =~ /^0/) ; 
    $$req{'options'}     = $ENV{EMBPERL_OPTIONS} || 0 ;
    $$req{'options'} = oct($$req{'options'}) if ($$req{'options'} =~ /^0/) ; 
    $$req{'log'}         = $ENV{EMBPERL_LOG}     || $DefaultLog ;
    $$req{'path'}        = $ENV{EMBPERL_PATH}    || '' ;

    if (defined($ENV{EMBPERL_ESCMODE}))
        { $$req{'escmode'}    = $ENV{EMBPERL_ESCMODE} }
    else
        { $$req{'escmode'}    = escStd ; }
    
    $$req{'cookie_name'}    = $ENV{EMBPERL_COOKIE_NAME} if (exists ($ENV{EMBPERL_COOKIE_NAME})) ;
    $$req{'cookie_domain'}  = $ENV{EMBPERL_COOKIE_DOMAIN} if (exists ($ENV{EMBPERL_COOKIE_DOMAIN})) ;
    $$req{'cookie_path'}    = $ENV{EMBPERL_COOKIE_PATH} if (exists ($ENV{EMBPERL_COOKIE_PATH})) ;
    $$req{'cookie_expires'} = $ENV{EMBPERL_COOKIE_EXPIRES} if (exists ($ENV{EMBPERL_COOKIE_EXPIRES})) ;
    }


*ScanEnvironement = \&ScanEnvironment ; # for backward compatibility (was typo)



#######################################################################################

sub CleanCallExecuteReq

    {
    $_[0] -> ExecuteReq ($_[1]) ;
    }

#######################################################################################


sub Execute
    
    {
    my $rc ;
    my $req = shift ;
    
    if (!ref ($req)) 
        {    
        my @parameter = @_ ;
	my ($fn, $sub) = split (/\#/, $req) ;

	$req = { 'inputfile' => $fn, 'sub' => $sub, 'param' => \@parameter }
        } 
    
    my $req_rec ;
    if (defined ($$req{req_rec})) 
        { $req_rec = $$req{'req_rec'} }
    elsif (exists $INC{'Apache.pm'})
        { $req_rec = Apache->request }

    if (defined ($$req{'virtlog'}) && $$req{'virtlog'} eq $$req{'uri'})
        {
        return SendLogFile ($DefaultLog, $ENV{QUERY_STRING}, $$req{'req_rec'}) ;
        }

    my $ns ;
    my $opcodemask ;

    if (defined ($ns = $$req{'compartment'}))
        {
        my $cp = AddCompartment ($ns) ;
        $opcodemask = $cp -> mask ;
        }

    if (exists ($req -> {'cookie_expires'}) && ($$req{'cookie_expires'} =~ /^\+|\-/))
        {
        require CGI ;

        $req -> {'cookie_expires'} = CGI::expires($req -> {'cookie_expires'}, 'cookie') ;
        }


    my $conf = SetupConfData ($req, $opcodemask) ;

    
    my $Outputfile = $$req{'outputfile'} ;
    my $In         = $$req{'input'} ;
    my $Out        = $$req{'output'}  ;
    my $filesize ;
    my $mtime ;
    my $OutData ;
    my $InData ;
    my $import     = exists ($req -> {'import'})?$req -> {'import'}:($$req{'isa'} || $$req{'object'})?0:undef ;

    if (exists $$req{'input_func'})  
        {
        my @p ;
        $In = \$InData ;
        $$req{mtime} = 0 ;
        my $ifreq = $$req{'input_func'} ;
        if (ref $ifreq)
            {
            @p = (ref ($ifreq) eq 'ARRAY')?@$ifreq:($$ifreq) ;
            }
        else
            {
            @p = split (/\s*\,\s*/, $ifreq) ;
            }

        my $InFunc = shift @p ;
        my $cacheargs ;
no strict ;
        eval {$rc = &{$InFunc} ($req_rec, $In, \$cacheargs, @p)} ;
use strict ;
        if ($rc || $@)
            {
            if ($@) 
                {
                $rc = 500 ;
                logerror (rcCallInputFuncFailed, $@, $req_rec) ;
                }

            return $rc ;
            }
        if (ref ($cacheargs) eq 'HASH')
            {
            $req -> {'mtime'}     = $cacheargs -> {'mtime'} ;
            $req -> {'inputfile'} = $cacheargs -> {'inputfile'} ;
            }
        else
            {
            $req -> {'mtime'}     = $cacheargs ;
            }
        }

    $Out = \$OutData if (exists $$req{'output_func'}) ;

    my $Inputfile    = $$req{'inputfile'} || $$req{'isa'} || $$req{'object'} || '?' ;
    my $Sub          = $$req{'sub'} || '' ;
    my $lastreq      = CurrReq () ;
    my $pathndx      = 0 ;

    if ($lastreq)
        {
        if ($Inputfile eq '*') 
            {
            $Inputfile = $lastreq -> ReqFilename ;
            }
        elsif ($Inputfile eq '../*') 
            {
            my $fn = $lastreq -> ReqFilename ;
            $fn =~ m{^.*/(.*?)$} ;
            $Inputfile = "../$1" ;
            }
        $$req{'path'} ||= $lastreq -> Path  ;
        $$req{'debug'} ||= $lastreq -> Debug  ;
        $pathndx = $lastreq -> PathNdx ;
        }
    
    if (defined ($In))
        {
        $filesize = -1 ;
        $mtime    = $$req{'mtime'} || 0 ;
        }
   elsif (!$Sub || $Inputfile ne '?')
        {
        #my ($k, $v) ;
        #while (($k, $v) = each (%$req))
        #    { warn "$k = $v" ; }
        if ($rc = CheckFile ($Inputfile, $req_rec, (($$req{options} || 0) & optAllowZeroFilesize), $$req{'allow'}, \$req -> {path}, \$pathndx, (($$req{debug} || 0) & dbgObjectSearch))) 
            {
	    FreeConfData ($conf) ;
            return $rc ;
            }
        $filesize = -s _ ;
        $mtime = -M _ ;
        }
    else
	{
        $filesize = -1 ;
        $mtime = 0 ;
	}


    my $package ;
    my $ar  ;
    $ar = Apache->request if (defined ($req_rec)) ; # workaround that Apache::Request has another C Interface, than Apache
    my $r = SetupRequest ($ar, $Inputfile, $mtime, $filesize, ($$req{firstline} || 1), $Outputfile, $conf,
                          &epIOMod_Perl, $In, $Out, $Sub, 
			   defined ($import)?scalar(caller ($import > 0?$import - 1:0)):'',
                          $SessionMgnt, $req -> {'syntax'} || '') ;
    
    eval
        {
        if (exists ($$req{'bless'})) 
            {
            bless $r, $$req{'bless'} ;
            warn "\@ISA corrupted HTML::Embperl::Req must be a base class of $$req{'bless'}" if (!$r -> isa ('HTML::Embperl::Req')) ; 
            }

        $r -> Path ($req->{path}) if ($req->{path}) ;
        $r -> PathNdx ($pathndx) ;

        $package = $r -> CurrPackage ;
        $evalpackage = $package ;   
        my $exports ;

        $r -> CreateAliases () ;

        if (defined ($import) && ($exports = $r -> ExportHash))
    	    {
            $r -> Export ($exports, caller ($import - 0)) if ($import) ;
	    $rc = 0 ;
	    }
        else
	    {
	    #local $^W = 0 ;
	    @ffld = @{$$req{'ffld'}} if (defined ($$req{'ffld'})) ;
	    if (defined ($$req{'fdat'})) 
	        {
	        %fdat = %{$$req{'fdat'}} ;
	        @ffld = keys %fdat if (!defined ($$req{'ffld'})) ;
	        }
	    else
                {
                my $content_type = $req_rec?$req_rec -> header_in('Content-type'):$ENV{'CONTENT_TYPE'} ;
                if (!defined ($import) && 
                   !($optDisableFormData) &&
	           !($r -> SubReq) &&
	           $content_type &&
	           ($content_type=~m|^multipart/form-data|))
	            { # just let CGI.pm read the multipart form data, see cgi docu
	            require CGI ;

	            my $cgi ;
	            eval { $cgi = new CGI } ;
	            if ($@ || !$cgi)
                        {
                        $r -> logerror (rcCGIError, $@)  ;
                        $@ = '' ;
                        }
                    else
                        {
	                @ffld = $cgi->param;
    
	                my $params ;
    	                foreach ( @ffld )
		            {
    		            # the param_fetch needs CGI.pm 2.43
		            #$params = $cgi->param_fetch( $_ ) ;
    		            $params = $cgi->{$_} ;
		            if ($#$params > 0)
		                {
		                $fdat{ $_ } = join ("\t", @$params) ;
		                }
		            else
		                {
		                $fdat{ $_ } = $params -> [0] ;
		                }
		            
		            ##print LOG "[$$]FORM: $_=" . (ref ($fdat{$_})?ref ($fdat{$_}):$fdat{$_}) . "\n" if ($dbgForm) ; 
		            print LOG "[$$]FORM: $_=$fdat{$_}\n" if ($dbgForm) ; 

		            if (ref($fdat{$_}) eq 'Fh') 
		                {
		                $fdat{"-$_"} = $cgi -> uploadInfo($fdat{$_}) ;
		                }
            	            }
                        }
	            }
                }

	    my $saved_param = undef;
	    if ( ref $$req{'param'} eq 'ARRAY') {
	        no strict 'refs';
	        # pass parameters via @param
	        $saved_param = \@{"$package\:\:param"} 
		    if defined @{"$package\:\:param"};
	        *{"$package\:\:param"}   = $$req{'param'};
	    }


            $r -> SetupSession ($req_rec, $Inputfile) ;

	        {
	        local $SIG{__WARN__} = \&Warn ;
	        local *0 = \$Inputfile;
	        my $oldfh = select (OUT) if ($optRedirectStdout) ;
	        my $saver = $r ;
        
	        $@ = undef ;
                $rc = CleanCallExecuteReq ($r, $$req{'param'}) ;
        
	        $r = $saver ;
	        select ($oldfh) if ($optRedirectStdout) ;
        
	        if (exists $$req{'output_func'}) 
		    {
		    my @p ;
                    my $ofreq = $$req{'output_func'} ;
                    if (ref $ofreq)
                        {
                        @p = (ref ($ofreq) eq 'ARRAY')?@$ofreq:($$ofreq) ;
                        }
                    else
                        {
                        @p = split (/\s*\,\s*/, $ofreq) ;
                        }

                    my $OutFunc = shift @p ;
        no strict ;
		    eval { &$OutFunc ($req_rec, $Out,@p) } ;
        use strict ;
		    $r -> logerror (rcCallOutputFuncFailed, $@) if ($@) ;
		    }
	        }



	    if ( defined $saved_param ) {
	        no strict 'refs';
	        *{"$package\:\:param"} = $saved_param;
	    }


            $r -> CleanupSession ;

            $r -> Export ($exports, caller ($import - 0)) if ($import && ($exports = $r -> ExportHash)) ;

	    my $cleanup    = $$req{'cleanup'}    || ($optDisableVarCleanup?-1:0) ;

	    if ($cleanup == -1)
	        { ; } 
	    elsif ($cleanup == 0)
	        {
	        if ($#cleanups == -1) 
		    {
		    push @cleanups, 'dbgShowCleanup' if ($dbgShowCleanup) ;
		    $req_rec -> register_cleanup(\&HTML::Embperl::cleanup) if (defined ($req_rec)) ;
		    }
	        push @cleanups, $package ;
        
	        cleanup () if (!$r -> SubReq () && !$req_rec) ;
	        }
	    else
	        {
	        push @cleanups, 'dbgShowCleanup' if ($dbgShowCleanup) ;
	        push @cleanups, $package ;
	        cleanup () ;
	        }

	    $rc = $r -> Error?500:0 ;
	    }

        if ($req -> {'isa'})
            {
            no strict ;
            my $callerisa = \@{caller (1) . '::ISA'} ;
            push @$callerisa, $package  if (!grep ($_ eq $package, @$callerisa)) ;
            use strict ;
            }

        @{$req -> {errors}} = @{$r -> ErrArray()} if (ref ($req -> {errors}) eq 'ARRAY')  ;
    } ; # eval
    if ($@)
	{
	my $err = $@ ;
        #require Devel::Symdump ;
	#warn "[$$] " . scalar (localtime) .  Devel::Symdump -> isa_tree ;
	HTML::Embperl::Req::FreeRequest ($r) ; # try to Free the Request data ($r may not be an objectref!)
	die $err ;
	}

    $r -> FreeRequest () ;
    
    if ($rc == 0 && $req -> {'object'})
        {
        my $object = {} ;
        bless $object, $package ;
        return $object ;
        }


    return $rc ;
    }

#######################################################################################


sub Init

    {
    my $Logfile   = shift ;
    $DebugDefault = shift ;
    $DebugDefault = dbgStd if (!defined ($DebugDefault)) ;
        
    XS_Init (epIOPerl, $Logfile || $DefaultLog, $DebugDefault) ;
    
    tie *LOG, 'HTML::Embperl::Log' ;
    }

#######################################################################################


sub Term

    {
    cleanup () ;
    XS_Term () ;
    }


#######################################################################################


sub run (\@)
    
    {
    my ($args) = @_ ;
    my $Logfile    = $ENV{EMBPERL_LOG} || $DefaultLog ;
    my $Daemon     = 0 ;
    my $Cgi        = $#{$args} >= 0?0:1 ;
    my $rc         = 0 ;
    my $log ;
    my $cgi ;
    my $ioType ;
    my %req ;
    my @param ;

    ScanEnvironment (\%req) ;
    

    if (defined ($$args[0]) && $$args[0] eq 'dbgbreak') 
    	{
    	shift @$args ;
    	dbgbreak () ;
    	}

    while ($#{$args} >= 0)
    	{
    	if ($$args[0] eq '-o')
    	    {
    	    shift @$args ;
    	    $req{'outputfile'} = shift @$args ;	
            }
    	if ($$args[0] eq '-p')
    	    {
    	    shift @$args ;
    	    push @param, shift @$args ;	
            }
    	elsif ($$args[0] eq '-l')
    	    {
    	    shift @$args ;
    	    $Logfile = shift @$args ;	
            }
    	elsif ($$args[0] eq '-d')
    	    {
    	    shift @$args ;
    	    $req{'debug'} = shift @$args ;	
	    }
    	elsif ($$args[0] eq '-D')
    	    {
    	    shift @$args ;
    	    $Daemon = 1 ;	
	    }
	else
	    {
	    last ;
	    }
	}
    
    if ($#{$args} >= 0)
    	{
    	$req{'inputfile'} = shift @$args ;
    	}		
    if ($#{$args} >= 0)
    	{
        $ENV{QUERY_STRING} = shift @$args ;
        undef $ENV{CONTENT_LENGTH} if (defined ($ENV{CONTENT_LENGTH})) ;
    	}		
	
    if ($Daemon)
        {
        $Logfile = '' || $ENV{EMBPERL_LOG};   # log to stdout
        $ioType = epIOProcess ;
        $req{'outputfile'} = $ENV{__RETFIFO} ;
        }
    elsif ($Cgi)
        {
        $req{'inputfile'} = $ENV{PATH_TRANSLATED} ;
        $ioType = epIOCGI ;
        }
    else
        {
        $ioType = epIOPerl ;
        }


    XS_Init ($ioType, $Logfile, $DebugDefault) ;

    
    tie *LOG, 'HTML::Embperl::Log' ;

    $req{'uri'} = $ENV{SCRIPT_NAME} ;

    $req{'cleanup'} = 0 ;
    $req{'cleanup'} = -1 if (($req{'options'} & optDisableVarCleanup)) ;
    $req{'options'} |= optSendHttpHeader ;
    $req{'param'} = \@param ;

    $rc = Execute (\%req) ;

    #close LOG ;
    XS_Term () ;

    return $rc ;
    }

#######################################################################################


sub runcgi ()
    
    {
    my $Logfile    = $ENV{EMBPERL_LOG} || $DefaultLog ;
    my $rc  ; 
    my $ioType ;
    my %req ;

    ScanEnvironment (\%req) ;
    
    $req{'inputfile'} = $ENV{PATH_TRANSLATED} ;
    $ioType = epIOCGI ;

    XS_Init ($ioType, $Logfile, $DebugDefault) ;

    tie *LOG, 'HTML::Embperl::Log' ;

    $req{'uri'} = $ENV{SCRIPT_NAME} ;

    $req{'cleanup'} = 0 ;
    $req{'cleanup'} = -1 if (($req{'options'} & optDisableVarCleanup)) ;
    $req{'options'} |= optSendHttpHeader ;

    $rc = Execute (\%req) ;

    #close LOG ;
    XS_Term () ;

    return $rc ;
    }


#######################################################################################



sub handler 
    
    {
    #log_svs ("handler entry") ;

    my $req_rec = shift ;

    my %req ;

    ScanEnvironment (\%req, $req_rec) ;
    
    $req{'uri'}       = $req_rec -> Apache::uri ;

    #warn "1 uri = $req{'uri'}\n" ;
    if (exists $ENV{EMBPERL_FILESMATCH} && 
                         !($req{'uri'} =~ m{$ENV{EMBPERL_FILESMATCH}})) 
        {
        # Reset the perl-handler to work with older mod_perl versions
        ResetHandler ($req_rec) ;
        return &DECLINED ;
        }


    $req{'inputfile'} = $ENV{PATH_TRANSLATED} = $req_rec -> filename ;

    #warn "ok inputfile = $req{'inputfile'}\n" ;

    $req{'cleanup'} = -1 if (($req{'options'} & optDisableVarCleanup));
    $req{'options'} |= optSendHttpHeader ;
    $req{'req_rec'} = $req_rec ;
    my @errors ;
    $req{'errors'} = \@errors ;
    $req_rec -> pnotes ('EMBPERL_ERRORS', \@errors) if (defined (&Apache::pnotes)) ;      

    my $rc = Execute (\%req) ;

    #print LOG "errors1=@errors\n" ;

    my $e = $req_rec -> pnotes ('EMBPERL_ERRORS') ;
    #print LOG "errors2=@$e\n" ;

    #log_svs ("handler exit") ;
    return $rc ;
    }

#######################################################################################

no strict ;


sub cleanup 
    {
    #log_svs ("cleanup entry") ;
    my $glob ;
    my $val ;
    my $key ;
    local $^W = 0 ;
    my $package ;
    my %seen ;
    my $Debugflags ;
    my $packfile ;
    my %addcleanup ;
    my $varfile ;
    my ($k, $v) ;
    
    $seen{''}      = 1 ;
    $seen{'dbgShowCleanup'} = 1 ;
    foreach $package (@cleanups)
        {
        $Debugflags = dbgShowCleanup if ($package eq 'dbgShowCleanup') ;
        next if ($seen{$package}) ;

	$seen{$package} = 1 ;
        
        #print LOG "GVFile $package\::__ANON__\n" ;
	$packfile = GVFile (*{"$package\::__ANON__"}) ;
        $packfile = '-> No Perl in Source <-' if ($packfile eq ('_<' . __FILE__) || $packfile eq __FILE__) ;
	$addcleanup = \%{"$package\:\:CLEANUP"} ;
	$addcleanup -> {'CLEANUP'} = 0 ;
	$addcleanup -> {'ISA'} = 0 ;
	if ($Debugflags & dbgShowCleanup)
	    {
	    print LOG "[$$]CUP:  ***** Cleanup package: $package  *****\n" ;
	    print LOG "[$$]CUP:  Source $packfile\n" ;
	    }
	if (defined (&{"$package\:\:CLEANUP"}))
	    {
    	    #$package =~ /^([a-zA-Z0-9\:\:\_]+)$/ ;
	    #eval "\&$1\:\:CLEANUP;" ;
	    eval "\&$package\:\:CLEANUP;" ;
	    print LOG "[$$]CUP:  Call \&$package\:\:CLEANUP;\n" if ($Debugflags & dbgShowCleanup);
	    logevalerr ($@) if ($@) ;
	    }


        if ($Debugflags & dbgShowCleanup)
            {
	    my @vars = sort keys %{*{"$package\::"}} ;
            my $cleanfile = \%{"$package\:\:CLEANUPFILE"} ;
	    foreach $key (@vars)
		{
                next if ($key =~ /^::/) ;
		$val =  ${*{"$package\::"}}{$key} ;
		local(*ENTRY) = $val;
		#print LOG "$key = " . GVFile (*ENTRY) . "\n" ;
		$varfile = GVFile (${*{"$package\::"}}{$key}) ;
		#$varfile = GVFile (*ENTRY) ;
                $glob = $package.'::'.$key ;
		if (defined (*ENTRY{SCALAR}) && defined (${$glob}) && ref (${$glob}) eq 'DBIx::Recordset' &&
                        !(defined ($addcleanup -> {$key}) && $addcleanup -> {$key} == 0))
		    {
		    print LOG "[$$]CUP:  Recordset $key\n" ;
		    eval { DBIx::Recordset::Undef ($glob) ; } ;
		    print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
		    } 
		elsif (($packfile eq $varfile || $addcleanup -> {$key} ||
                        $cleanfile->{$varfile}) &&  
		     (!($key =~ /\:\:$/) && !(defined ($addcleanup -> {$key}) && $addcleanup -> {$key} == 0)))
		    { # Only cleanup vars which are defined in the sourcefile
		      # ignore all imported vars, unless they are in the CLEANUP hash which is set by VARS
                    if (defined (*ENTRY{SCALAR}) && defined (${$glob})) 
			{
			print LOG "[$$]CUP:  \$$key = ${$glob}\n" ;
			eval { undef ${$glob} } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			}
		    if (defined (*ENTRY{IO})) 
			{
			print LOG "[$$]CUP:  IO     $key\n" ;
			eval { close *{$glob} ; } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			}
		    if (defined (*ENTRY{HASH})) 
			{
			print LOG "[$$]CUP:  \%$key = (" ;           
			my $i = 0 ;
			my $k ;
			my $v ;
                        eval { # ignore errors here (for ActiveState Perl)
                        while (($k, $v) = each (%{$glob}))
			    {
			    if ($i++ > 5) 
				{
				print LOG '...' ;
				last 
				}
			    print LOG "$k => $v, "
			    } } ;
			print LOG ")\n" ;
			eval { untie %{$glob} ; } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			eval { undef %{$glob} ; } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			}
		    if (defined (*ENTRY{ARRAY})) 
			{
			print LOG "[$$]CUP:  \@$key = ("  ;          
			my $i = 0 ;
			my $v ;
			foreach $v (@{$glob})
			    {
			    if ($i++ > 5) 
				{
				print LOG '...' ;
				last 
				}
			    print LOG "$v, "
			    }
			print LOG ")\n" ;
			eval { untie @{$glob} ; } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			eval { undef @{$glob} ; } ;
			print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
			}
		    print LOG "[$$]CUP:  leave unchanged LVALUE $key\n"       if (defined (*ENTRY{LVALUE})) ;
		    print LOG "[$$]CUP:  leave unchanged FORMAT $key\n"       if (defined (*ENTRY{FORMAT})) ;
		    print LOG "[$$]CUP:  leave unchanged \&$key\n"	      if (defined (*ENTRY{CODE})) ;
                    }
		}
            }
        else
            {
            my $cleanfile = \%{"$package\:\:CLEANUPFILE"} ;
            while (($key,$val) = each(%{*{"$package\::"}}))
                {
                next if ($key =~ /^::/) ;
	        local(*ENTRY) = $val;
	        $glob = $package.'::'.$key ;
		if (defined (*ENTRY{SCALAR}) && defined (${$glob}) && ref (${$glob}) eq 'DBIx::Recordset' &&
                         !(defined ($addcleanup -> {$key}) && $addcleanup -> {$key} == 0))
		    {
		    eval { DBIx::Recordset::Undef ($glob) ; } ;
		    print LOG "[$$]CUP:  Error: $@\n" if ($@) ;
		    } 
		else
                    {
		    #$varfile = GVFile (*ENTRY) ;
		    $varfile = GVFile (${*{"$package\::"}}{$key}) ;
	            if (($packfile eq $varfile || $addcleanup -> {$key} || 
                        $cleanfile->{$varfile}) &&  
		         (!($key =~ /\:\:$/) && !(defined ($addcleanup -> {$key}) && $addcleanup -> {$key} == 0)))
		        { # Only cleanup vars which are defined in the sourcefile
		          # ignore all imported vars, unless they are in the CLEANUP hash which is set by VARS
                        if (defined (*ENTRY{SCALAR}) && defined (${$glob})) 
			    {
			    eval { undef ${$glob} ; } ;
			    print LOG "[$$]CUP:  Error while cleanup \$$glob: $@\n" if ($@) ;
			    }
		        if (defined (*ENTRY{IO})) 
			    {
			    eval { close *{"$package\:\:$key"} ; } ;
			    print LOG "[$$]CUP:  Error while closing $glob: $@\n" if ($@) ;
			    }
		        if (defined (*ENTRY{HASH})) 
			    {
			    eval { untie %{$glob} ; } ;
			    print LOG "[$$]CUP:  Error while cleanup \%$glob: $@\n" if ($@) ;
			    eval { undef %{$glob} ; } ;
			    print LOG "[$$]CUP:  Error while cleanup \%$glob: $@\n" if ($@) ;
			    }
		        if (defined (*ENTRY{ARRAY})) 
			    {
			    eval { untie @{$glob} ; } ;
			    print LOG "[$$]CUP:  Error while cleanup \@$glob: $@\n" if ($@) ;
			    eval { undef @{$glob} ; } ;
			    print LOG "[$$]CUP:  Error while cleanup \@$glob: $@\n" if ($@) ;
			    }
                        }
		    }
		}
            }
        }

    @cleanups = () ;


    if ($^O eq 'MSWin32' && $ENV{MOD_PERL})
        {
        # workaround for mod_perl problems with environment
        foreach my $k (keys %ENV)
            {
            delete $ENV{$k} if ($k =~ /^EMBPERL/) ;
            }
        delete $ENV{'QUERY_STRING'} ;
        delete $ENV{'CONTENT_LENGTH'} ;
        delete $ENV{'CONTENT_TYPE'} ;
        delete $ENV{'HTTP_COOKIE'} ;
        }
        



    flushlog () ;

    #log_svs ("cleanup exit") ;
    #return &OK ;
    return 0 ;
    }

use strict ;

#######################################################################################

sub watch 
    {
    my ($package) = @_ ;

    my $glob ;
    my $key  ;
    my $val  ;

    while (($key,$val) = each(%{*{"$package\::"}})) {
	    local(*ENTRY) = $val;
        $glob = $package.'::'.$key ;
        if (defined (*ENTRY{SCALAR}) && ${$glob} ne $watchval{$key}) 
            {
            print LOG "[$$]VAR:  \$$key = ${$glob}\n" ;
            $watchval{$key} = ${$glob} ;
            } 
        }
    }


#######################################################################################

sub MailFormTo

    {
    my ($to, $subject, $returnfield) = @_ ;
    my $v ;
    my $k ;
    my $ok ;
    my $smtp ;
    my $ret ;

    $ret = $fdat{$returnfield} ;

    #eval 'require Net::SMTP' ;
    #die "require Net::SMTP failed: $@" if ($@); 
    require Net::SMTP ;

    $smtp = Net::SMTP->new($ENV{'EMBPERL_MAILHOST'} || 'localhost', 
                           Debug => $ENV{'EMBPERL_MAILDEBUG'} || 0,
                           $ENV{'EMBPERL_MAILHELO'}?(Hello => $ENV{'EMBPERL_MAILDEBUG'}):()) 
             or die "Cannot connect to mailhost" ;
    
    $smtp->mail($ENV{'EMBPERL_MAILFROM'} || "WWW-Server\@$ENV{SERVER_NAME}");
    $smtp->to($to);
    $ok = $smtp->data();
    $ok = $smtp->datasend("Reply-To: $ret\n") if ($ok && $ret) ;
    $ok and $ok = $smtp->datasend("To: $to\n");
    $ok and $ok = $smtp->datasend("Subject: $subject\n");
    $ok and $ok = $smtp->datasend("\n");
    foreach $k (@ffld)
        { 
        $v = $fdat{$k} ;
        if (defined ($v) && $v ne '')
            {
            $ok and $ok = $smtp->datasend("$k\t= $v \n" );
            }
        }
    $ok and $ok = $smtp->datasend("\nClient\t= $ENV{REMOTE_HOST} ($ENV{REMOTE_ADDR})\n\n" );
    $ok and $ok = $smtp->dataend() ;
    $smtp->quit; 

    return $ok ;
    }    


#######################################################################################



sub ProxyInput

    {
    my ($r, $in, $mtime, $src, $dest) = @_ ;

    my $url ;

    if (defined ($src))
        {
        $url = $dest . $1 if ($r -> uri =~ m{^$src(.*?)$}) ;
        }
    else
        {
        return &NOT_FOUND ;
        }

    my $q = $r -> args ;
    $url .= "?$q" if ($q) ;
    
    my ($request, $response, $ua);

    #eval 'require LWP::UserAgent' ;
    #die "require LWP::UserAgent failed: $@" if ($@); 
    require LWP::UserAgent ;

    $ua = new LWP::UserAgent;  
    $ua -> use_eval (0) ;
    $request  = new HTTP::Request($r -> method, $url);

    if ($ENV{CONTENT_LENGTH})
        { # pass posted data
        my $content ;

        read STDIN, $content, $ENV{CONTENT_LENGTH} ;
        delete $ENV{CONTENT_LENGTH} ;

        $request -> content($content) ;
        }

    my %headers_in = $r->headers_in;
    my $key ;
    my $val ;
    while (($key,$val) = each %headers_in)
        {
 	$request->header($key,$val) if (lc ($key) ne 'connection') ;
        }

    $response = $ua->request($request);

    my $code = $response -> code ;
    my $mod  = $response -> last_modified || undef ;

    #if ($Debugflags) 
    #    { 
    #    print LOG "[$$]PXY: uri=" . $r->uri . "\n" ;
    #    print LOG "[$$]PXY: src=$src, dest=$dest\n" ;
    #    print LOG "[$$]PXY: -> url=$url\n" ;
    #    print LOG "[$$]PXY: code=$code,  last modified = $mod\n" ;
    #    print LOG "[$$]PXY: msg =". $response -> message . "\n" ;
    #    }
            
    $$in    = $response -> content ;
    $$mtime = { mtime => $mod, inputfile => $url} ;

    return $code == 200?0:$code;
    }


#######################################################################################


sub LogOutput

    {
    my ($r, $out, $basepath) = @_ ;

    #$basepath =~ s*[^a-zA-Z0-9./-]*-* ;
    $basepath =~ /^(.*?)$/ ;

    $basepath = $1 ;

    $LogOutputFileno++ ;

    $r -> send_http_header ;

    $r -> print ($$out) ;
    
    open L, ">$basepath.$$.$LogOutputFileno" ;
    print L $$out ;
    close L ;

    #if ($Debugflags) 
    #    { 
    #    print LOG "[$$]OUT:  Logged output to $basepath.$$.$LogOutputFileno\n" ;
    #    }

    return 0 ;
    }

#######################################################################################

package HTML::Embperl::Req ; 


#######################################################################################

use strict ;


if (defined ($ENV{MOD_PERL}))
    { 
    eval 'use Apache::Constants qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN)' ;
    die "use Apache::Constants failed: $@" if ($@); 
    }


#######################################################################################

sub SetupSession

    {
    my $r ;
    $r = shift if (!(ref ($_[0]) =~ /^Apache/)) ;
    my ($req_rec, $Inputfile) = @_ ;
    local $^W = 0 ;

    if ($HTML::Embperl::SessionMgnt && (!defined ($r) || !$r -> SubReq))
	{
	my $udat = tied(%HTML::Embperl::udat) ;
	my $mdat = tied(%HTML::Embperl::mdat) ;
	my $sdat = tied(%HTML::Embperl::sdat) ;
	my $cookie_name = $r?$r -> CookieName:$ENV{EMBPERL_COOKIE_NAME} || 'EMBPERL_UID' ;
        my $cookie_val  = $ENV{HTTP_COOKIE} || ($req_rec?$req_rec->header_in('Cookie'):undef) ;

	if ((defined ($cookie_val) && ($cookie_val =~ /$cookie_name=(.*?)(\;|\s|$)/)) || ($ENV{QUERY_STRING} =~ /$cookie_name=.*?:(.*?)(\;|\s|&|$)/) || $ENV{EMBPERL_UID} )
	    {
	    print HTML::Embperl::LOG "[$$]SES:  Received user session id $1\n" if ($HTML::Embperl::dbgSession) ;
	    $udat -> setid ($1) if (!$udat -> getid) ;
            }

	$mdat -> setidfrom ($Inputfile) if ($Inputfile && !$mdat -> getid) ;

	if (($ENV{QUERY_STRING} =~ /${cookie_name}=(.*?)(\;|\s|&|:|$)/))
	    {
	    print HTML::Embperl::LOG "[$$]SES:  Received state session id $1\n" if ($HTML::Embperl::dbgSession) ;
	    $sdat -> setid ($1) if (!$sdat -> getid) ;
            }
	}
    else
        {
        return undef ; # No session Management
        }

    return wantarray?(\%HTML::Embperl::udat, \%HTML::Embperl::mdat, \%HTML::Embperl::sdat):\%HTML::Embperl::udat ;
    }

#######################################################################################

sub GetSession

    {
    if ($HTML::Embperl::SessionMgnt)
	{
	my $udat = tied(%HTML::Embperl::udat) ;

        return wantarray?(\%HTML::Embperl::udat, \%HTML::Embperl::mdat, \%HTML::Embperl::sdat):\%HTML::Embperl::udat ;
	}
    else
        {
        return undef ; # No session Management
        }
    }

#######################################################################################

sub DeleteSession

    {
    my $r = shift || HTML::Embperl::CurrReq () ;
    my $disabledelete = shift ;

    my $udat = tied (%HTML::Embperl::udat) ;
    if (!$disabledelete)  # Delete session data
        {
        $udat -> delete  ;
        }
    else
        {
        $udat-> {data} = {} ; # for make test only
        $udat->{initial_session_id} = "!DELETE" ;
        }
    $udat->{status} = 0;
    }


#######################################################################################

sub RefreshSession

    {
    my $r = shift || HTML::Embperl::CurrReq () ;

    $r -> SessionMgnt ($HTML::Embperl::SessionMgnt | 4) ; # resend cookie 
    }

#######################################################################################

sub CleanupSession

    {
    my $r = shift ;
    $r = HTML::Embperl::CurrReq () if (!(ref ($r) =~ /^HTML::Embperl/));

    if ($HTML::Embperl::SessionMgnt && (!defined ($r) || !$r -> SubReq))
	{
	my $udat = tied(%HTML::Embperl::udat) ;
	my $mdat = tied(%HTML::Embperl::mdat) ;
	my $sdat = tied(%HTML::Embperl::sdat) ;

	$udat -> cleanup ;
	$mdat -> cleanup ;
	$sdat -> cleanup ;
	}
    }


#######################################################################################

sub SetSessionCookie

    {
    my $r = shift ;
    $r = undef if (!(ref ($r) =~ /^HTML::Embperl/));

    if ($HTML::Embperl::SessionMgnt)
        {
        my $udat   = tied (%HTML::Embperl::udat) ;
        my ($initialid, $id, $modified)  = $udat -> getids ;
        
        my $name   = $ENV{EMBPERL_COOKIE_NAME} || 'EMBPERL_UID' ;
        my $domain = "; domain=$ENV{EMBPERL_COOKIE_DOMAIN}" if (exists ($ENV{EMBPERL_COOKIE_DOMAIN})) ;
        my $path   = "; path=$ENV{EMBPERL_COOKIE_PATH}" if (exists ($ENV{EMBPERL_COOKIE_PATH})) ;
        my $expires = "; expires=$ENV{EMBPERL_COOKIE_EXPIRES}" if (exists ($ENV{EMBPERL_COOKIE_EXPIRES})) ;
                        
        if ($id || $initialid)
            {    
            Apache -> request -> header_out ("Set-Cookie" => "$name=$id$domain$path$expires") ;
            }
        }
    }





#######################################################################################

sub CreateAliases

    {
    my ($self) = @_ ;
    
    my $package = $self -> CurrPackage ;

    my $dummy ;
    
    no strict ;


    if (!defined(${"$package\:\:row"}))
        { # create new aliases for Embperl magic vars

        foreach (@HTML::Embperl::AliasScalar)
            {
            *{"$package\:\:$_"}    = \${"HTML::Embperl\:\:$_"} ;
            $dummy = ${"$package\:\:$_"} ; # necessary to make sure variable exists!
            }

        foreach (@HTML::Embperl::AliasHash)
            {
            *{"$package\:\:$_"}    = \%{"HTML::Embperl\:\:$_"} ;
            }
        foreach (@HTML::Embperl::AliasArray)
            {
            *{"$package\:\:$_"}    = \@{"HTML::Embperl\:\:$_"} ;
            }

    	if (defined (&Apache::exit))
            {
            *{"$package\:\:exit"}    = \&Apache::exit 
            }
        else
            {
            *{"$package\:\:exit"}    = \&HTML::Embperl::exit 
            }
                    

        *{"$package\:\:MailFormTo"} = \&HTML::Embperl::MailFormTo ;
        *{"$package\:\:Execute"} = \&HTML::Embperl::Execute ;

        tie *{"$package\:\:LOG"}, 'HTML::Embperl::Log' ;
        tie *{"$package\:\:OUT"}, 'HTML::Embperl::Out' ;

        #warn  "[$$]MEM:  Created Aliases for $package\n" ;
        }


     ${"$package\:\:req_rec"} = $self -> ApacheReq ;
#    print HTML::Embperl::LOG  "[$$]MEM:  " . $self -> ApacheReq . "\n" ;

    use strict ;
    }

#######################################################################################

sub Export

    {
    my ($self, $exports, $caller) = @_ ;
    
    my $package = $self -> CurrPackage ;
    
    print HTML::Embperl::LOG  "[$$]IMP:  Create Imports for $caller from $package ($exports)\n" ;
    no strict ;

    foreach $k (keys %$exports)
	{
        *{"$caller\:\:$k"}    = $exports -> {$k} ; #\&{"$package\:\:$k"} ;
        print HTML::Embperl::LOG  "[$$]IMP:  Created Import for $package\:\:$k -> $caller\n" ;
        }

    use strict ;
    }

#######################################################################################

sub SendErrorDoc ()

    {
    my ($self) = @_ ;
    local $SIG{__WARN__} = 'Default' ;
    
    my $virtlog = $self -> VirtLogURI || '' ;
    my $logfilepos = $self -> LogFileStartPos () ;
    my $url     = $HTML::Embperl::dbgLogLink?"<A HREF=\"$virtlog\?$logfilepos\&$$\">Logfile</A>":'' ;    
    my $req_rec = $self -> ApacheReq ;
    my $err ;
    my $cnt = 0 ;
    local $HTML::Embperl::escmode = 0 ;
    my $time = localtime ;
    my $mail = $req_rec -> server -> server_admin if (defined ($req_rec)) ;
    $mail ||= '' ;

    $req_rec -> content_type('text/html') if (defined ($req_rec)) ;

    $self -> output ("<HTML><HEAD><TITLE>Embperl Error</TITLE></HEAD><BODY bgcolor=\"#FFFFFF\">\r\n$url") ;
    $self -> output ("<H1>Internal Server Error</H1>\r\n") ;
    $self -> output ("The server encountered an internal error or misconfiguration and was unable to complete your request.<P>\r\n") ;
    $self -> output ("Please contact the server administrator, $mail and inform them of the time the error occurred, and anything you might have done that may have caused the error.<P><P>\r\n") ;

    my $errors = $self -> ErrArray() ;
    if ($virtlog ne '' && $HTML::Embperl::dbgLogLink)
        {
        foreach $err (@$errors)
            {
            $self -> output ("<A HREF=\"$virtlog?$logfilepos&$$#E$cnt\">") ; #<tt>") ;
            $HTML::Embperl::escmode = 3 ;
            $err =~ s|\\|\\\\|g;
            $err =~ s|\n|\n\\<br\\>\\&nbsp;\\&nbsp;\\&nbsp;\\&nbsp;|g;
            $err =~ s|(Line [0-9]*:)|$1\\</a\\>|;
            $self -> output ($err) ;
            $HTML::Embperl::escmode = 0 ;
            $self -> output ("<p>\r\n") ;
            #$self -> output ("</tt><p>\r\n") ;
            $cnt++ ;
            }
        }
    else
        {
        $HTML::Embperl::escmode = 3 ;
        foreach $err (@$errors)
            {
            $err =~ s|\\|\\\\|g;
            $err =~ s|\n|\n\\<br\\>\\&nbsp;\\&nbsp;\\&nbsp;\\&nbsp;|g;
            $self -> output ("$err\\<p\\>\r\n") ;
            #$self -> output ("\\<tt\\>$err\\</tt\\>\\<p\\>\r\n") ;
            $cnt++ ;
            }
        $HTML::Embperl::escmode = 0 ;
        }
         
    my $server = $ENV{SERVER_SOFTWARE} || 'Offline' ;

    $self -> output ("$server HTML::Embperl $HTML::Embperl::VERSION [$time]<P>\r\n") ;
    $self -> output ("</BODY></HTML>\r\n\r\n") ;

    }

#######################################################################################

sub MailErrorsTo ()

    {
    my ($self) = @_ ;
    local $SIG{__WARN__} = 'Default' ;
    
    my $to = $ENV{'EMBPERL_MAIL_ERRORS_TO'} ;
    return undef if (!$to) ;

    $self -> log ("[$$]ERR:  Mail errors to $to\n") ;

    my $time = localtime ;

    #eval 'require Net::SMTP' ;
    #die "require Net::SMTP failed: $@" if ($@); 
    require Net::SMTP ;

    my $smtp = Net::SMTP->new($ENV{'EMBPERL_MAILHOST'} || 'localhost', Debug => $ENV{'EMBPERL_MAILDEBUG'}) or die "Cannot connect to mailhost" ;
    $smtp->mail("Embperl\@$ENV{SERVER_NAME}");
    $smtp->to($to);
    my $ok = $smtp->data();
    $ok and $ok = $smtp->datasend("To: $to\r\n");
    $ok and $ok = $smtp->datasend("Subject: ERROR in Embperl page $ENV{SCRIPT_NAME} on $ENV{HTTP_HOST}\r\n");
    $ok and $ok = $smtp->datasend("\r\n");

    $ok and $ok = $smtp->datasend("ERROR in Embperl page $ENV{HTTP_HOST}$ENV{SCRIPT_NAME}\r\n");
    $ok and $ok = $smtp->datasend("\r\n");

    $ok and $ok = $smtp->datasend("-------\r\n");
    $ok and $ok = $smtp->datasend("Errors:\r\n");
    $ok and $ok = $smtp->datasend("-------\r\n");
    my $errors = $self -> ErrArray() ;
    my $err ;
        
    foreach $err (@$errors)
        {
	$ok and $ok = $smtp->datasend("$err\r\n");
        }
    
    $ok and $ok = $smtp->datasend("-----------\r\n");
    $ok and $ok = $smtp->datasend("Formfields:\r\n");
    $ok and $ok = $smtp->datasend("-----------\r\n");
    
    my $ffld = $self -> FormArray() ;
    my $fdat = $self -> FormHash() ;
    my $k ;
    my $v ;
    
    foreach $k (@$ffld)
        { 
        $v = $fdat->{$k} ;
        $ok and $ok = $smtp->datasend("$k\t= \"$v\" \n" );
        }
    $ok and $ok = $smtp->datasend("-------------\r\n");
    $ok and $ok = $smtp->datasend("Environment:\r\n");
    $ok and $ok = $smtp->datasend("-------------\r\n");

    my $env = $self -> EnvHash() ;

    foreach $k (sort keys %$env)
        { 
        $v = $env -> {$k} ;
        $ok and $ok = $smtp->datasend("$k\t= \"$v\" \n" );
        }

    my $server = $ENV{SERVER_SOFTWARE} || 'Offline' ;

    $ok and $ok = $smtp->datasend("-------------\r\n");
    $ok and $ok = $smtp->datasend("$server HTML::Embperl $HTML::Embperl::VERSION [$time]\r\n") ;

    $ok and $ok = $smtp->dataend() ;
    $smtp->quit; 

    return $ok ;
    }    


#######################################################################################


###############################################################################    
#
# This package is only here that HTML::Embperl also shows up under module/by-module/Apache/ .
#

package Apache::Embperl; 

*handler = \&HTML::Embperl::handler ;

#
#
###############################################################################    
            

1;


# for documentation see Embperl.pod
