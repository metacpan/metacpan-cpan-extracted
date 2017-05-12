#!/usr/bin/perl --

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
#   $Id: test.pl 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# version =>
# errors  =>
# noerrtest => 
# sleep4err =>
# query_string =>
# repeat =>
# cmpext =>
# option =>
# debug =>
# cgi =>
# offline =>
# modperl =>
# package =>
# compartment =>
# cookie =>
# condition =>
# param =>
# reqbody =>
# respheader => \%
# recipe =>
# xsltstylesheet =>
# syntax =>
# msg =>
# app_handler_class =>
# input_escmode =>
# portadd =>

@testdata = (
    'ascii' => { },
    'pure.htm' => {
#        'noloop'     => 1,
     },
    'nooutput.htm' => {
        repeat => 2,
        version => 2,
        },
    'plain.htm' => {
        repeat => 3,
        },
    'plainblock.htm' => { 
        repeat => 2,
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 8,
        'version'    => 1,
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 5,
        'version'    => 2,
        'cgi'        => 0,
        'condition'  => '$] < 5.010000',
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 6,
        'version'    => 2,
        'cgi'        => 0,
        'condition'  => '$] >= 5.010000',
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 5,
        'version'    => 2,
        'cgi'        => 1,
        'condition'  => '!$MP2',
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 6,
        'version'    => 2,
        'cgi'        => 1,
        'condition'  => '$MP2 && $] < 5.010000',
        },
    'error.htm' => { 
        'repeat'     => 3,
        'errors'     => 7,
        'version'    => 2,
        'cgi'        => 1,
        'condition'  => '$MP2 && $] >= 5.010000',
        },
    'errormismatch.htm' => { 
        'errors'     => '1',
        'version'    => 2,
        },
    'errormismatchcmd.htm' => { 
        'errors'     => '1',
        'version'    => 2,
        },
    'errorfirstrun.htm' => { 
        'errors'     => 1,
        'version'    => 2,
        'condition'  => '$] < 5.006000',
        },
    'errorfirstrun.htm' => { 
        'errors'     => 2,
        'version'    => 2,
        'condition'  => '$] >= 5.006000',
        },
    'unclosed.htm' => { 
        'errors'     => '1',
        },
    'notfound.htm' => { 
        'errors'     => '1',
        'cgi'        => 1,
        'condition'  => '$EPAPACHEVERSION !~ /2\.4\./',
        },
    'notfound.htm' => { 
        'errors'     => '1',
        'cgi'        => 0,
        },
    'notallow.xhtm' => { 
        'errors'     => '1',
        },
    'noerr/noerrpage.htm' => { 
        'option'     => 2,
        'errors'     => 8,
        'version'    => 1,
        'cgi'        => 0,
        },
    'errdoc/errdoc.htm' => { 
        'option'     => '262144',
        'errors'     => 6,
        'version'    => 1,
        'cgi'        => 0,
        },
    'errdoc/errdoc.htm' => { 
        'option'     => '262144',
        'errors'     => 5,
        'version'    => 2,
        'modperl'    => 1,
        'condition'  => '$] < 5.010000',
        },
    'errdoc/errdoc.htm' => { 
        'option'     => '262144',
        'errors'     => 6,
        'version'    => 2,
        'modperl'    => 1,
        'condition'  => '$] >= 5.010000', 
        },
    'errdoc/epl/errdoc2.htm' => { 
        'option'     => '262144',
        'errors'     => 6,
        'version'    => 1,
        'cgi'        => 0,
        'noloop'     => 1,
        'modperl'    => 1,
        },
    'errdoc/epl/errdoc2.htm' => { 
        'option'     => '262144',
        'errors'     => 5,
        'version'    => 2,
        'cgi'        => 0,
        'noloop'     => 1,
        'modperl'    => 1,
        'condition'  => '$] < 5.010000',
        },
    'errdoc/epl/errdoc2.htm' => { 
        'option'     => '262144',
        'errors'     => 6,
        'version'    => 2,
        'cgi'        => 0,
        'noloop'     => 1,
        'modperl'    => 1,
        'condition'  => '$] >= 5.010000',
        },
    'rawinput/rawinput.htm' => { 
        'option'     => '16',
        'cgi'        => 0,
        'input_escmode' => 0,
        },
    'var.htm' => { },
    'varerr.htm' => { 
        'errors'     => -1,
        'noloop'     => 1,
        'condition'  => '$] < 5.006000', 
        offline      => 1,
        },
    'varerr.htm' => { 
        'errors'     => -1,
        'noloop'     => 1,
        'condition'  => '$] < 5.006000', 
        cgi          => 1,
        'version'    => 1,
        },
    'varerr.htm' => { 
        'errors'     => -1,
        'noloop'     => 1,
        'condition'  => '$] < 5.006000', 
        modperl      => 1,
        'version'    => 1,
        },
    'varerr.htm' => { 
        'errors'     => 7,
        'noloop'     => 1,
        'condition'  => '$] >= 5.006000', 
        'cmpext'     => '56',
        'version'    => 1,
        },
    'varerr.htm' => { 
        'errors'     => 7,
        'noloop'     => 1,
        'condition'  => '$] >= 5.006000', 
        'cmpext'     => '56',
        'version'    => 2,
        },
    'varerr.htm' => { 
        'errors'     => 2,
        'version'    => 1,
        'cgi'        => 0,
        'condition'  => '$] < 5.006000', 
        },
    'varerr.htm' => { 
        'errors'     => 7,
        'version'    => 1,
        'cgi'        => 0,
        'condition'  => '$] >= 5.006000', 
        'cmpext'     => '56',
        },
    'varepvar.htm' => {
	'query_info' => 'a=1&b=2',
        'offline'    => 0,
        'cgi'        => 0,
	 },
    'escape.htm' => { 
        repeat => 2,
        },
    'escraw.htm' => { 
        'version'    => 1,
        },
    'escutf8.htm' => { 
        'query_info' => "poststd=abcäöü&postutf8=abcÃ¤Ã¶Ã¼",
        'offline'    => 1,
        'condition'  => '$] >= 5.008000', 
        },
    'spaces.htm' => { 
        'version'    => 1,
        },
    'tagscan.htm' => { },
    'tagscan.htm' => { 
        'debug'      => '1',
        },
    'tagscandisable.htm' => { 
        'version'    => 1,
        },
    'if.htm' => { },
    'ifperl.htm' => { },
    'loop.htm' => { 
        'query_info' => 'erstes=Hallo&zweites=Leer+zeichen&drittes=%21%22%23%2a%2B&erstes=Wert2',
        },
    'loopperl.htm' => { 
        'query_info' => 'erstes=Hallo&zweites=Leer+zeichen&drittes=%21%22%23&erstes=Wert2',
        },
    'table.htm' => { },
    'table.htm' => { 
        'debug'      => '1',
        },
    'tabmode.htm' => { 
        'version'    => 1,
        },
    'lists.htm' => { 
        'query_info' => 'sel=2&SEL1=B&SEL3=D&SEL4=cc',
        },
    'select.htm' => {},
    'selecttab.htm' => {},
    'selecttab2.htm' => {},
    'mix.htm' => { },
    'binary.htm' => { 
        'version'    => 1,  # needs print OUT
        },
    'nesting.htm' => { 
        },
    'nesting2.htm' => { 
        },
    'object.htm' => { 
        'version'    => 1,
        'errors'     => '2',
        },
    'object.htm' => { 
        'version'    => 2,
        },
    'discard.htm' => { ###
        'errors'     => '12',
        'version'    => 1,
        },
    'input.htm' => { 
        'query_info' => 'feld5=Wert5&feld5a=Wert4\'y\'r&feld5b="Wert5"&feld6=Wert6&feld7=Wert7&feld8=Wert8&cb5=cbv5&cb6=cbv6&cb7=cbv7&cb8=cbv8&cb9=ncbv9&cb10=ncbv10&cb11=ncbv11&mult=Wert3&mult=Wert6&esc=a<b&escmult=a>b&escmult=Wert3',
        'repeat' => 2,
        },
    'hidden.htm' => { 
        'query_info' => 'feld1=Wert1&feld2=Wert2&feld3=Wert3&feld4=Wert4?foo=bar',
        },
    'java.htm' => { },
    'inputjava.htm' => { },
    'inputjs2.htm' => {
        'version'    => 2,
     },
    'inputattr.htm' => { },
    'heredoc.htm' => { },
    'epglobals.htm' => {},
    'keepspaces.htm' => { 
        'option'     => 0x100000,
        'offline'    => 1,
        },
    'post.htm' => {
        'offline'    => 0,
        'reqbody'    => "f1=abc1&f2=1234567890&f3=" . 'X' x 8192,
        },
    'upload.htm' => { 
        'query_info' => 'multval=A&multval=B&multval=C&single=S',
        'offline'    => 0,
        'noloop'     => 1,
        'reqbody'    => "Hi there!",
        },
    'reqrec.htm' => {
        'offline'    => 0,
        'cgi'        => 0,
        'repeat'     => 2,
        },
    'keepreq.htm' => {
        'cgi'        => 0,
        'errors'     => 1,
        'condition'  => '!$EPWIN32', 
        'sleep4err'  => 1,
        },
    'keepreq.htm' => {
        'cgi'        => 0,
        'errors'     => 1,
        'cmpext'     => '.2',
        'condition'  => '!$EPWIN32', 
        'sleep4err'  => 1,
        },
    'keepreq.htm' => {
        'modperl'    => 0,
        'errors'     => 1,
        'condition'  => '$EPWIN32', 
        'sleep4err'  => 1,
        },
    'keepreq.htm' => {
        'modperl'    => 0,
        'errors'     => 1,
        'cmpext'     => '.2',
        'condition'  => '$EPWIN32', 
        'sleep4err'  => 1,
        },
    'keepreq.htm' => {
        'modperl'    => 1,
        'errors'     => 0,
        'condition'  => '$EPWIN32', 
        'sleep4err'  => 1,
        },
    'keepreq.htm' => {
        'modperl'    => 1,
        'errors'     => 0,
        'cmpext'     => '.2',
        'condition'  => '$EPWIN32', 
        'sleep4err'  => 1,
        },
    'hostconfig.htm' => {
        'modperl'    => 1,
        },
    'hostconfig.htm' => {
        'modperl'    => 1,
        'cmpext'     => '.3',
        'portadd'    => 3,
        },
    'hostconfig.htm' => {
        'modperl'    => 1,
        'cmpext'     => '.4',
        'portadd'    => 4,
        },
    'hostconfig.htm' => {
        'modperl'    => 1,
        'cmpext'     => '.5',
        'portadd'    => 5,
        },
    'include.htm' => { 
        'version'    => 1,
        },
    'rawinput/include.htm' => { 
        'option'     => '16',
        'version'    => 2,
        'cgi'        => 0,
        'repeat'     => 2,
        'input_escmode' => 0,
        },
    'execnotfound.htm' => { 
        'errors'     => '1',
        },
    'includeerr1.htm' => { 
        'errors'     => '1',
        'repeat'     => 2,
        },
    'includeerr2.htm' => { 
        'errors'     => 4,
        'version'    => 1,
        'condition'  => '$] >= 5.006001', 
        },
    'includeerr2.htm' => { 
        'errors'     => 5,
        'version'    => 2,
        'repeat'     => 2,
        'condition'  => '$] >= 5.006001 && $] < 5.014000', 
        },
    'includeerr2.htm' => { 
        'errors'     => 3,
        'version'    => 2,
        'repeat'     => 2,
        'condition'  => '$] >= 5.014000 && $] < 5.018000', 
        'cmpext'     => '514',
        },
    'includeerr2.htm' => { 
        'errors'     => 9,
        'version'    => 2,
        'repeat'     => 2,
        'condition'  => '$] >= 5.018000', 
        'cmpext'     => '518',
        },
    'includeerr3.htm' => { 
        'errors'     => 2,
        'condition'  => '$] < 5.014000', 
        'cgi'        => 0,         
        },
    'includeerr3.htm' => { 
        'errors'     => 2,
        'condition'  => '$] >= 5.014000', 
        'cmpext'     => '514',
        'cgi'        => 0,         
        },
    'includeerr3.htm' => { 
        'errors'     => 2,
        'cgi'        => 1,         
        },
    'includeerrbt.htm' => { 
        'errors'     => 3,
        'version'    => 2,
        },
    'incif.htm' => { 
        'version'    => 2,
        },
    'registry/hello.htm' => {
        'modperl'    => 1,
        },
    'registry/Execute.htm' => {
        'modperl'    => 1,
        },
    'registry/errpage.htm' => { ###
        'modperl'    => 1,
        'errors'     => '16',
        'version'    => 1,
        },
    'registry/tied.htm' => { 
        'modperl'    => 1,
        'errors'     => 3,
        'condition'  => '!$EPWIN32', 
        },
    'registry/tied.htm' => { 
        'modperl'    => 1,
        'errors'     => 3,
        'condition'  => '!$EPWIN32', 
        },
    'registry/tied.htm' => { 
        'modperl'    => 1,
        'errors'     => 0,
        'condition'  => '$EPWIN32', 
        },
    'registry/tied.htm' => { 
        'modperl'    => 1,
        'errors'     => 0,
        'condition'  => '$EPWIN32', 
        },
    'callsub.htm' => { 
        'repeat'     => 2,
        },
    'sub2.htm' => { 
        'repeat'     => 2,
        },
    'subargs.htm' => { 
        'repeat'     => 2,
        },
    'subout.htm' => { 
        'repeat'     => 2,
        },
    'subouttab.htm' => { 
        'repeat'     => 2,
        },
    'subempty.htm' => { 
        },
    'executesub.htm' => { 
        'version'    => 2,
        'repeat'     => 2,
        },
    'execfirst.htm' => { 
        'version'    => 2,
        },
    'execsecond.htm' => { 
        'version'    => 2,
        },
    'execprint.htm' => { 
        'version'    => 2,
        },
    'execviamod.htm' => { 
        'version'    => 2,
        },
#    'execinside.htm' => { 
#        },
    'importsub.htm' => { 
        'repeat'     => 2,
        },
    'importsub2.htm' => { 
        },
###    'importmodule.htm' => { 
###        },
    'subtextarea.htm' => { 
        'repeat'     => 2,
        'query_info' => 'summary=a1&title=b2&pubdate=c3&content=d4&more=e5',
        },
    'subtextarea.htm' => { 
        'repeat'     => 2,
        'query_info' => 'summary=a1&title=b2&pubdate=c3&content=d4&more=e5',
        },
    'execwithsub.htm' => { 
        },
    'nph/div.htm' => { 
        'option'     => '64',
        },
    'nph/npherr.htm' => { 
        'option'     => '64',
        'errors'     => '8',
        'version'    => 1,
        'cgi'        => 0,
        },
    'nph/nphinc.htm' => { 
        'option'     => '64',
        'cgi'        => 0,
        },
    'sub.htm' => { },
    'sub.htm' => { },
    'subtab.htm' => {
            'version'    => 2,
        },
    'exit.htm' => { 
        'cgi'        => 0,
        },
    'exit2.htm' => { 
        },
    'exit3.htm' => { 
        'version'    => 1,
        'offline'    => 0,
        },
    'exitreq.htm' => { 
        },
    'exitcomp.htm' => { 
        },
    'chdir.htm' => { 
        'query_info' => 'a=1&b=2&c=&d=&f=5&g&h=7&=8&=',
        },
    'chdir.htm' => { 
        'query_info' => 'a=1&b=2&c=&d=&f=5&g&h=7&=8&=',
        },
    'chdir/chdir2src.htm' => { 
        'query_info' => 'a=1&b=2&c=&d=&f=5&g&h=7&=8&=',
        'option'     => 0x10000000,
        'cgi'        => 0,
        },
    'allform/allform.htm' => { 
        'query_info' => 'a=1&b=2&c=&d=&f=5&g&h=7&=8&=',
        'option'     => '8192',
        'cgi'        => 0,
        },
    'stdout/stdout.htm' => { 
        'option'     => '16384',
        'version'    => 1,
        'cgi'        => 0,
        },
    'nochdir/nochdir.htm' => { 
        'query_info' => 'a=1&b=2',
        'option'     => '384',
        'cgi'        => 0,
        },
    'match/div.htm' => {
        'offline'    => 0,
     },
    'match/div.asc' => {
        'offline'    => 0,
     },
    'http.htm' => { 
        'offline'    => 0,
        'version'    => 1,
        'reqbody'    => "a=b",  # Force POST, so no redirect happens
        'respheader' => { 'locationx' => 'http://www.ecos.de/embperl/', 'h1' => 'v0', h2 => [ 'v1', 'v2'] },
        },
    'div.htm' => { 
        'repeat'    => 2,
        },
    'taint.htm' => { 
        'offline'    => 0,
        'cgi'        => 0,
        'errors'     => '1',
        },
    'ofunc/div.htm' => { },
    'safe/safe.htm' => { 
        'option'     => '4',
        'errors'     => '-1',
        'version'    => 1,
        'cgi'        => 0,
        },
    'safe/safe.htm' => { 
        'option'     => '4',
        'errors'     => '-1',
        'version'    => 1,
        'cgi'        => 0,
        },
    'safe/safe.htm' => { 
        'option'     => '4',
        'errors'     => '-1',
        'version'    => 1,
        'cgi'        => 0,
        },
    'opmask/opmask.htm' => { 
        'option'     => '12',
        'errors'     => '-1',
        'compartment'=> 'TEST',
        'package'    => 'TEST',
        'version'    => 1,
        'cgi'        => 0,
        },
    'opmask/opmasktrap.htm' => { 
        'option'     => '12',
        'errors'     => '2',
        'compartment'=> 'TEST',
        'version'    => 1,
        'cgi'        => 0,
        'condition'  => '$] < 5.006001', 
        },
    'opmask/opmasktrap.htm' => { 
        'option'     => '12',
        'errors'     => '1',
        'compartment'=> 'TEST',
        'version'    => 1,
        'cgi'        => 0,
        'condition'  => '$] >= 5.006001', 
        'cmpext'     => '.561',
        },
    'cookieexpire.htm' => { 
        'offline'    => 1,
        },
    'mdatsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'cnt=0',
        'cookie'     => 'expectno',
        },
    'setsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'a=1',
        'cookie'     => 'expectnew',
        },
    'mdatsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'cnt=1',
        'cookie'     => 'expectno',
        },
    'getnosess.htm' => { 
        'offline'    => 0,
        'query_info' => 'nocookie=2',
        'cookie'     => 'expectnew,nocookie,nosave',
        },
    'mdatsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'cnt=2',
        'cookie'     => 'expectno',
        },
    'getsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'mdatsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'cnt=3',
        'cookie'     => 'expectno',
        },
    'execgetsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'registry/reggetsess.htm' => { 
        'modperl'    => 1,
        'cgi'        => 0,
        'cookie'     => 'expectno',
        },
    'getsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'delwrsess.htm' => { 
        'offline'    => 0,
        'cookie'     => 'expectnew',
        },
    'getbsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'delrdsess.htm' => { 
        'offline'    => 0,
        'cookie'     => 'expectexpire',
        },
    'getdelsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'setsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'a=1',
        'cookie'     => 'expectnew',
        },
    'delsess.htm' => { 
        'offline'    => 0,
        'cookie'     => 'expectexpire',
        },
    'getdelsess.htm' => { 
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'clearsess.htm' => {
        'offline'    => 0,
        'cookie'     => 'expectno',
        },
    'setbadsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'val=2',
        'cookie'     => 'expectnew,cookie=/etc/passwd',
        },
    'setunknownsess.htm' => { 
        'offline'    => 0,
        'query_info' => 'val=3',
        'cookie'     => 'expectnew,cookie=1234567890abcdefABCDEF',
        },
    'uidurl/seturlsess.htm' => { 
        'modperl'    => 1,
        'query_info' => 'a=1',
        'cookie'     => 'expectnew,url',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'uidurl/getnourlsess.htm' => { 
        'modperl'    => 1,
        'query_info' => 'nocookie=2',
        'cookie'     => 'nocookie,nosave,url',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'uidurl/geturlsess.htm' => {
        'modperl'    => 1,
        'cookie'     => 'expectsame,url',
        'query_info' => 'foo=1',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'suidurl/seturlsess.htm' => { 
        'modperl'    => 1,
        'query_info' => 'a=1',
        'cookie'     => 'expectnew,url,nocookie',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'suidurl/getnourlsess.htm' => { 
        'modperl'    => 1,
        'query_info' => 'nocookie=2',
        'cookie'     => 'nocookie,nosave,url',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'suidurl/geturlsess.htm' => {
        'modperl'    => 1,
        'cookie'     => 'url',
        'query_info' => 'foo=1',
        'aliasdir'   => 1,
        #'version'    => 1,
        },
    'sidurl/setsdaturlsess.htm' => { 
        'modperl'    => 1,
        'query_info' => 'sdat=99',
        'cookie'     => 'expectnew,url,nocookie',
        #'version'    => 1,
        },
    'sidurl/getsdaturlsess.htm' => {
        'modperl'    => 1,
        'cookie'     => 'expectnew,url',
        #'version'    => 1,
        },
    'EmbperlObject/epopage1.htm' => {
        'offline'    => 0,
        'repeat'     => 2,
        },
    'EmbperlObject/epoincdiv.htm' => { 
        'offline'    => 0,
        'cgi'        => 0, # input_escmode is not passed automaticly to included script in cgi mode
        },
    'EmbperlObject/epofdat.htm' => {
        'offline'    => 0,
        'query_info' => 'a=1&b=2',
        'cgi'        => 0, # input_escmode is not passed automaticly to included script in cgi mode
        },
    'EmbperlObject/epodiv.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/sub/epopage2.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/sub/epopage2.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/sub/subsub/eposubsub.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/sub/subsub/subsubsub/eposubsub.htm' => { 
        'offline'    => 0,
        'cmpext'     => '3',      
        },
    'EmbperlObject/sub/subsub/subsubsub/eposubsub2.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/sub/eponotfound.htm' => { 
        'offline'    => 0,
        'cgi'        => 0,
        },
    'EmbperlObject/sub/epobless.htm' => { 
        'offline'    => 0,
        'repeat'     => 2,
        },
    'EmbperlObject/sub/epobless2.htm' => { 
        'offline'    => 0,
        'repeat'     => 2,
        },
    'EmbperlObject/sub/epobless3.htm' => { 
        'offline'    => 0,
        'repeat'     => 2,
        },
    'EmbperlObject/obj/epoobj1.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/obj/epoobj2.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/obj/epoobj3.htm' => { 
        'offline'    => 0,
        },
    'EmbperlObject/obj/epoobj4.htm' => { 
        'offline'    => 0,
        'version'    => 1,
        },
    'EmbperlObject/base2/epostopdir.htm' => { 
        'offline'    => 0,
        'cgi'        => 0,
        },
    'EmbperlObject/base3/epobaselib.htm' => { 
        'offline'    => 0,
        'cgi'        => 0,
        },
    'EmbperlObject/errdoc/epoerrdoc.htm' => {
        'offline'    => 0,
        'cgi'        => 0,
        'errors'     => 1,
        },

    'EmbperlObject/errdoc/epoerrdoc2.htm' => {
        'offline'    => 0,
        'cgi'        => 0,
        'errors'     => 2, # 2-8
        'noerrtest'  => 1,
        },
    'EmbperlObject/epobase.htm' => {
        'offline'    => 0,
        'cgi'        => 0,
        'errors'     => 1,
        },
    'SSI/ssibasic.htm' => { 
        'version'    => 2,
        'syntax'     => 'SSI',
        'cgi'        => 0,
        },
    'SSIEP/ssiep.htm' => { 
        'version'    => 2,
        'syntax'     => 'Embperl SSI',
        'cgi'        => 0,
        },
    'inctext.htm' => { 
        'ep1compat'    => 0,
#	'version'      => 2,
        },
    'incperl.htm' => { 
        'version'    => 2,
        },
    'asp.htm' => { 
        'version'    => 2,
        },
    'syntax.htm' => { 
        'version'    => 2,
        'repeat'     => 2,
        },
    'changeattr.htm' => { 
        'version'    => 2,
        'repeat'     => 2,
        },
    'tagintag.htm' => { 
        'version'    => 2,
        },
    'rtf/rtfbasic.asc' => { 
        'version'    => 2,
        'syntax'     => 'RTF',
        'offline'    => 1,
        'param'      => { one => 1, hash => { a => 111, b => 222, c => [1111,2222,3333,4444]}, array => [11,22,33], uml => 'ÄÖÜ', brace => 'open { close } end' },
        },
    'rtf/rtffull.asc' => { 
        'version'    => 2,
        'syntax'     => 'RTF',
        'offline'    => 1,
        'param'      => { 'Nachname' => 'Richter', Vorname => 'Gerald' },
        },
#    'rtf/rtfadv.asc' => { 
#        'version'    => 2,
#        'syntax'     => 'RTF',
#        'offline'    => 1,
#        'condition'  => '$] < 5.016000', 
#        'param'      => [
#                        { 'adressen_anrede' => 'Herr', 'adressen_name' => 'Richter', 'adressen_vorname'  => 'Gerald', anschreiben_typ => 'Dienstadresse', adressen_dienststelle => 'adr dienst', adressen_dienstbezeichnung => 'DBEZ', adressen_dienst_strasse => 'dstr 1', adressen_priv_strasse => 'pstr 1' },
#                        { 'adressen_anrede' => 'Herr', 'adressen_name' => 'Richter2', 'adressen_vorname'  => 'Gerald2', anschreiben_typ => 'Dienstadresse', adressen_dienststelle => 'adr dienst 2', adressen_dienstbezeichnung => 'DBEZ2' },
#                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'adressen_vorname'  => 'Ulrike' },
#                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'adressen_vorname'  => 'Sarah' },
#                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'adressen_vorname'  => 'Marissa' },
#                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'adressen_vorname'  => 'Gerald2', anschreiben_typ => 'Dienstadresse', adressen_dienststelle => 'adr dienst 2', adressen_dienstbezeichnung => 'DBEZ2' },
#                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'adressen_vorname'  => 'Gerald2', anschreiben_typ => 'Privatadresse', adressen_dienststelle => 'adr dienst 2', adressen_dienstbezeichnung => 'DBEZ2', adressen_dienst_strasse => 'dstr 2', adressen_priv_strasse => 'pstr 2'  },
#                        ]
#        },
    'rtf/rtfloop.asc' => { 
        'version'    => 2,
        'syntax'     => 'RTF',
        'offline'    => 1,
        'param'      => [
                        { 'Kunde' => 'blabla', Kurs => 'blubblub', 'Nachname' => 'Richter', Vorname => 'Gerald' },
                        { 'Kunde' => 'blabla', Kurs => 'blubblub', 'Nachname' => 'Richter2', Vorname => 'Gerald2' },
                        { 'Kunde' => 'blabla', Kurs => 'blubblub', 'Nachname' => 'Richter3', Vorname => 'Gerald3' },
                        { 'Kunde' => 'blabla', Kurs => 'blubblub', 'Nachname' => 'Richter4', Vorname => 'Gerald4' },
                        { 'Kunde' => 'blabla', Kurs => 'blubblub', 'Nachname' => 'Richter5', Vorname => 'Gerald5' },
                        ]
        },
    'rtf/rtfmeta.asc' => { 
        'version'    => 2,
        'syntax'     => 'RTF',
        'offline'    => 1,
        'param'      => [
                        { 'adressen_anrede' => 'Herr', 'adressen_name' => 'Richter', 'nr' => 11 },
                        { 'adressen_anrede' => 'Herr', 'adressen_name' => 'Richter', 'nr' => 12 },
                        { 'adressen_anrede' => 'Herr', 'adressen_name' => 'Richter', 'nr' => 13 },
                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'nr' => 21 },
                        { 'adressen_anrede' => 'Frau', 'adressen_name' => 'Weis',    'nr' => 22 },
                        ]
        },
    'crypto.htm' => { 
        'condition'  => '$EPC_ENABLE', 
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'condition'  => '!$EPWIN32', 
        'cgi'        => 0,
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'condition'  => '$EPWIN32', 
        'cmpext'     => '.win32',
        'cgi'        => 0,
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'EmbperlLibXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'condition'  => '$LIBXSLTVERSION', 
        'msg'        => ' embperl -> libxslt',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'EmbperlXalanXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'condition'  => '$XALANPATH', 
        'cmpext'     => '.xalan',
        'msg'        => ' embperl -> xalan',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'EmbperlXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'xsltproc'   => 'libxslt',
        'offline'    => 1,
        'condition'  => '$LIBXSLTVERSION', 
        'msg'        => ' embperl -> xslt (libxslt)',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'EmbperlXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'xsltproc'   => 'xalan',
        'condition'  => '$XALANPATH', 
        'cmpext'     => '.xalan',
        'msg'        => ' embperl -> xslt (xalan)',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'LibXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'condition'  => '$LIBXSLTVERSION', 
        'msg'        => ' libxslt',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'XalanXSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'condition'  => '$XALANPATH', 
        'cmpext'     => '.xalan',
        'msg'        => ' xalan',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'XSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'xsltproc'   => 'libxslt',
        'offline'    => 1,
        'condition'  => '$LIBXSLTVERSION', 
        'msg'        => ' xslt (libxslt)',
        },
    'xml/pod.xml' => { 
        'version'    => 2,
        'recipe'     => 'XSLT',
        'xsltstylesheet'     => "$inpath/xml/podold.xsl",
        'offline'    => 1,
        'xsltproc'   => 'xalan',
        'condition'  => '$XALANPATH', 
        'cmpext'     => '.xalan',
        'msg'        => ' xslt (xalan)',
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'recipe'     => 'EmbperlLibXSLT',
        'xsltstylesheet'     => "$inpath/xml/pod.xsl",
        'cmpext'     => '.htm',
        'offline'    => 1,
        'msg'        => ' libxslt',
        'condition'  => '$LIBXSLTVERSION && !$EPWIN32', 
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'recipe'     => 'EmbperlLibXSLT',
        'xsltstylesheet'     => "$inpath/xml/pod.xsl",
        'cmpext'     => '.htm.win32',
        'offline'    => 1,
        'msg'        => ' libxslt',
        'condition'  => '$LIBXSLTVERSION && $EPWIN32', 
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'recipe'     => 'EmbperlXalanXSLT',
        'xsltstylesheet'     => "$inpath/xml/pod.xsl",
        'cmpext'     => '.xalan.htm',
        'offline'    => 1,
        'msg'        => ' xalan',
        'condition'  => '$XALANPATH && !$EPWIN32', 
        },
    'pod/pod.asc' => { 
        'version'    => 2,
        'syntax'     => 'POD',
        'recipe'     => 'EmbperlXalanXSLT',
        'xsltstylesheet'     => "$inpath/xml/pod.xsl",
        'cmpext'     => '.xalan.htm.win32',
        'offline'    => 1,
        'msg'        => ' xalan',
        'condition'  => '$XALANPATH && $EPWIN32', 
        },
    'libxslt/pod.xml' => { 
        'version'    => 2,
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' libxslt',
        'condition'  => '$LIBXSLTVERSION', 
        },
    'xalan/pod.xml' => { 
        'version'    => 2,
        'cmpext'     => '.xalan',
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' xalan',
        'condition'  => '$XALANPATH', 
        },
    'asclibxslt/pod.asc' => { 
        'version'    => 2,
        'cmpext'     => '.htm',
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' libxslt',
        'condition'  => '$LIBXSLTVERSION && !$EPWIN32', 
        },
    'asclibxslt/pod.asc' => { 
        'version'    => 2,
        'cmpext'     => '.htm.win32',
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' libxslt',
        'condition'  => '$LIBXSLTVERSION && $EPWIN32', 
        },
    'ascxalan/pod.asc' => { 
        'version'    => 2,
        'cmpext'     => '.xalan.htm',
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' xalan',
        'condition'  => '$XALANPATH && !$EPWIN32', 
        },
    'ascxalan/pod.asc' => { 
        'version'    => 2,
        'cmpext'     => '.xalan.htm.win32',
        'modperl'    => 1,
        'aliasdir'   => 1,
        'msg'        => ' xalan',
        'condition'  => '$XALANPATH && $EPWIN32', 
        },
    'incxmlLibXSLT.htm' => { 
        'version'    => 2,
        'condition'  => '$LIBXSLTVERSION', 
        'msg'        => ' libxslt',
        },
#    'incxmlLibXSLT2.htm' => { 
#        'version'    => 2,
#        'condition'  => '$LIBXSLTVERSION', 
#        'msg'        => ' libxslt',
#        },
    'incxmlXalanXSLT.htm' => { 
        'version'    => 2,
        'condition'  => '$XALANPATH', 
        'msg'        => ' xalan',
        },
    'app/i18n.htm' => { 
        'version'    => 2,
        'app_handler_class' => 'Embperl::TEST::App',
        'cgi'        => 0,
        },
    'xhtml.htm' => { 
        'version'    => 2,
        },
    'epform.htm' => { 
        'version'    => 2,
        'query_info' => 'datum=23.12.2002&stunden=x',
        },
    'subreq.htm' => { 
        'version'    => 2,
        'modperl'    => 1,
        'condition'  => '$MP2',
        },
) ;

for ($i = 0 ; $i < @testdata; $i += 2)
    { 
    for ($j = 0; $j < ($testdata[$i+1]->{repeat} || 1); $j++)
        { push @tests, $i ; }
    }



# avoid some warnings:

use vars qw ($httpconfsrc $httpconf $EPPORT $EPPORT2 *SAVEERR *ERR $EPHTTPDDLL $EPSTARTUP $EPDEBUG
             $testshare $keepspaces
            $EPSESSIONDS $EPSESSIONCLASS $EPSESSIONVERSION $EPSESSIONXVERSION $EP1COMPAT $EPAPACHEVERSION $EPC_ENABLE
            $opt_offline $opt_ep1 $opt_cgi $opt_modperl $opt_execute $opt_nokill $opt_loop
            $opt_multchild $opt_memcheck $opt_exitonmem $opt_exitonsv $opt_config $opt_nostart $opt_uniquefn
            $opt_quite $opt_qq $opt_ignoreerror $opt_tests $opt_blib $opt_help $opt_dbgbreak $opt_finderr
            $opt_ddd $opt_gdb $opt_ab $opt_abpre $opt_abverbose $opt_start $opt_startinter $opt_kill $opt_showcookie $opt_cache
            $opt_cfgdebug $opt_verbosecmp) ;

    {
    local $^W = 0 ;
    eval " use Win32::Process; " ;
    $win32loaderr = $@ ;
    eval " use Win32; " ;
    $win32loaderr ||= $@ ;
    }

use File::Spec ;
use FindBin ;

BEGIN 
    { 
    $fatal  = 1 ;
    $^W     = 1 ;
    $|      = 1;
    
    $ENV{EMBPERL_COOKIE_EXPIRES} = '+120s' ;

    if (($ARGV[0] || '') eq '--testlib') 
        {
        eval 'use ExtUtils::testlib' ;
        shift @ARGV ;
        $opt_testlib = 1 ;
        }

    if ($INC[0] =~ /^(\.\/)?blib/)
        {
        my $i = 0 ;
        foreach (@INC)
            {
            $INC[$i++] = File::Spec -> rel2abs ($_) if ($_) ;
            }
        }

    #### install handler which kill httpd when terminating ####

    $SIG{__DIE__} = sub { 
	return unless $_[0] =~ /^\*\*\*/ ;
	return if ($opt_nokill)  ;

	print $_[0] ;

	if ($EPWIN32)
	    {
	    $HttpdObj->Kill(-1) if ($HttpdObj) ;
	    }
	else
	    {
	    system "kill `cat $tmppath/httpd.pid` 2> /dev/null" if ($EPHTTPD ne '') ;
	    }
	} ;

    print "\nloading...                    ";
    

    $defaultdebug = 0x7fffdffd ;
    #$defaultdebug = 1 ;

    #### setup paths #####

    $inpath  = 'test/html' ;
    $tmppath = 'test/tmp' ;
    $cmppath = 'test/cmp' ;

    $logfile    = "$tmppath/test.log" ;

    $ENV{EMBPERL_LOG} = $logfile ;
    $ENV{EMBPERL_DEBUG} = $defaultdebug ;
    $ENV{DMALLOC_OPTIONS} = "log=$tmppath/dmalloc.log,debug=0x3f03" ;
    $ENV{EMBPERL_SESSION_HANDLER_CLASS} = "no" ;
    $Embperl::initparam{use_env} = 1 ;

    unlink ($logfile) ;

    my $um = umask 0 ;
    mkdir $tmppath, 0777 ;
    chmod 0777, $tmppath ;
    umask $um ;
    }

END 
    { 
    print "\nTest terminated with fatal error\n" if ($fatal) ; 
    system "kill `cat $tmppath/httpd.pid 2> /dev/null` > /dev/null 2>&1" if ($EPHTTPD ne '' && !$opt_nokill && !$EPWIN32) ;
    $? = $fatal || $err ;	
    }


use Getopt::Long ;

@ARGVSAVE = @ARGV ;

eval { Getopt::Long::Configure ('bundling') } ;
$@ = "" ;
$ret = GetOptions ("offline|o", "ep1|1", "cgi|c", "cache|a", "modperl|httpd|h", "execute|e", "nokill|r", "loop|l:i",
            "multchild|m", "memcheck|v", "exitonmem|g", "exitonsv", "config|f=s", "nostart|x", "uniquefn|u",
            "quite|q",  "qq", "ignoreerror|i", "tests|t", "blib|b", "help", "dbgbreak", "finderr",
	    "ddd", "gdb", "ab:s", "abverbose", "abpre", "start", "startinter", "kill", "showcookie",
            "cfgdebug", "verbosecmp|V") ;

$opt_help = 1 if ($ret == 0) ;



$confpath = 'test/conf' ;


#### read config ####

do ($opt_config || "$confpath/config.pl") ; 

die $@ if ($@) ;


$EPPORT2 = ($EPPORT || 0) + 1 ;
$EPSESSIONCLASS = $ENV{EMBPERL_SESSION_CLASS} || (($EPSESSIONVERSION =~ /^0\.17/)?'Win32':'0')  || ($EPSESSIONVERSION >= 1.00?'Embperl':'0') ;
$EPSESSIONDS    = $ENV{EMBPERL_SESSION_DS} || 'dbi:mysql:session' ;

die "You must install libwin32 first" if ($EPWIN32 && $win32loaderr && $EPHTTPD) ;


#### setup files ####

$httpdconf = "$confpath/httpd.conf" ;
$httpdstopconf = "$confpath/httpd.stop.conf" ;
$httpdminconf = "$confpath/httpd.min.conf" ;
$httpderr   = "$tmppath/httpd.err.log" ;
$offlineerr = "$tmppath/test.err.log" ;
$outfile    = "$tmppath/out.htm" ;

#### setup path in URL ####

$embploc     = 'embperl' ;
$cgiloc      = 'cgi-bin' ; 
$fastcgiloc  = 'fastcgi-bin' ; 

$port    = $EPPORT ;
$host    = 'localhost' ;
$httpdpid = 0 ;

if ($opt_help)
    {
    print "\n\n" ;
    print "test.pl [options] [files]\n" ;
    print "files: <filename>|<testnumber>|-<testnumber>\n\n" ;
    print "options:\n" ;
    print "-o       test offline\n" ;
    print "-1       test Embperl 1.x compatibility\n" ;
    print "-c       test cgi\n" ;
    print "-h       test mod_perl\n" ;
    print "-e       test execute\n" ;
    print "-a       test output cache\n" ;
    print "-r       don't kill httpd at end of test\n" ;
    print "-l       loop forever\n" ;
    print "-m       start httpd with mulitple childs\n" ;
    print "-v       memory check (needs proc filesystem)\n" ;
    print "-g       exit if httpd grows after 2 loop\n" ;   
    print "-f       file to use for config.pl\n" ;
    print "-x       do not start httpd\n" ;
    print "-u       use unique filenames\n" ;
    print "-q       set debug to 0\n" ;
    print "-i       ignore errors\n" ;
    print "-t       list tests\n" ;
    print "-V       verbose compare, show diff\n" ;
#    print "-b      use uninstalled version (from blib/..)\n" ;
    print "--ddd    start apache under ddd\n" ;
    print "--gdb    start apache under gdb\n" ;
    print "--ab <numreq|options>  run test thru ApacheBench\n" ;
    print "--abverbose   show whole ab output\n" ;
    print "--abpre       prefetch first request\n" ;
    print "--start  start apache only\n" ;
    print "--startinter  start apache only for interactive session\n" ;
    print "--kill   kill apache only\n" ;
    print "--showcookie  shows sent and received cookies\n" ;
    print "--cfgdebug    shows processing of configuration directives\n" ;
    print "\n\n" ;
    print "path\t$EPPATH\n" ;
    print "httpd\t" . ($EPHTTPD || '') . "\n" ;
    print "port\t" . ($port || '') . "\n" ;
    $fatal = 0 ;
    exit (1) ;
    }

if ($opt_tests)
    {
    $i = 0 ;
    foreach $t (@tests)
	{
	print "$i = $testdata[$t]\n" ;
	$i++ ;
	}
    $fatal = 0 ;
    exit (1) ;
    }

if ($opt_finderr && !$opt_testlib)
    {
    my $x = find_error () ;
    $fatal = 0 ;
    exit ($x) ;
    }

$opt_quite = 1 if (defined ($opt_ab)) ;	

$vmmaxsize = 0 ;
$vminitsize = 0 ;
$vmhttpdsize = 0 ;
$vmhttpdinitsize = 0 ;

require 'test/testapp.pl' ;


#####################################################
#
# test for output tie
#

    {
    package Embperl::Test::STDOUT ;

    sub TIEHANDLE 

        {
        my $class ;
        
        return bless \$class, shift ;
        }


    sub PRINT

        {
        shift ;
        $output .= shift ;
        }
    }



#####################################################

sub s1 { 1 } ;
sub s0 { 0 } ;

#####################################################

sub chompcr

    {
    local $^W = 0 ;

    chomp ($_[0]) ;
    if (!$keepspaces)
        {
        if ($_[0] =~ /(.*?)\s*\r$/) 
	    {
	    $_[0] = $1
	    }
        elsif ($_[0] =~ /(.*?)\s*$/) 
	    {
	    $_[0] = $1
	    }
        $_[0] =~ s/\s+/ /g ;
        $_[0] =~ s/\s+>/>/g ;
        }
    }

#####################################################

sub CmpInMem

    {

    my ($out, $cmp, $parm) = @_ ;

    local $p = $parm ;

    $out =~ s/\r//g ;
    chomp ($out) ;

    if ($out ne eval ($cmp))
	{
	print "\nError\nIs:\t>$out<\nShould:\t>" . eval ($cmp) . "<\n" ;
	return 1 ;
	}

    return 0 ;
    }



#####################################################

sub CmpFiles 
    {
    my ($f1, $f2, $errin) = @_ ;
    my $line = 0 ;
    my $line2 = 0 ;
    my $err  = 0 ;
    local $^W = 0 ;

    open F1, $f1 || die "***Cannot open $f1" ; 
    binmode (F1, ":encoding(iso-8859-1)") if ($] >= 5.008000) ;
    if (!$errin)
	{
	open F2, $f2 || die "***Cannot open $f2" ; 
        binmode (F2, ":encoding(iso-8859-1)") if ($] >= 5.008000) ;
	}

    while (defined ($l1 = <F1>))
	{
	$line++ ;
        chompcr ($l1) ;
        printf ("<<<#%3d: %s\n", $line, $l1) if ($opt_verbosecmp) ;
        while (($l1 =~ /^\s*$/) && defined ($l1 = <F1>))
            { 
	    $line++ ;
            chompcr ($l1) ; 
            printf ("<<<#%3d: %s\n", $line, $l1) if ($opt_verbosecmp) ;
            } 


	if (!$errin) 
	    {
	    $l2 = <F2> ;
	    chompcr ($l2) ;
	    $line2++ ;
            printf ("-->#%3d: %s\n", $line2, $l2) if ($opt_verbosecmp) ;
            while (($l2 =~ /^\s*$/) && defined ($l2 = <F2>))
                { 
                chompcr ($l2) ; 
	        $line2++ ;
                printf ("-->#%3d: %s\n", $line2, $l2) if ($opt_verbosecmp) ;
                } 
	    }
	last if (!defined ($l2) && !defined ($l1)) ;

	if (!defined ($l2))
	    {
	    print "\nError in Line $line\nIs:\t$l1\nShould:\t<EOF>\n" ;
	    return $line?$line:-1 ;
	    }

	
	$eq = 0 ;
	while (((!$notseen && ($l2 =~ /^\^\^(.*?)$/i)) || ($l2 =~ /^\^\-(.*?)$/i)) && !$eq)
	    {
	    $l2 = $1 ;
	    if (($l1 =~ /^\s*$/) && ($l2 =~ /^\s*$/))
                { 
                $eq = 1 ;
                }
            else
                {
                $eq = $l1 =~ /$l2/ ;
                }
            $l2 = <F2> if (!$eq) ;
	    chompcr ($l2) ;
            $line2++ ;
            printf ("-->#%3d: %s\n", $line2, $l2) if ($opt_verbosecmp) ;
	    }

	if (!$eq)
	    {
	    if ($l2 =~ /^\^(.*?)$/i)
		{
		$l2 = $1 ;
		$eq = $l1 =~ /$l2/i ;
		}
	    else
		{
	        if (!$keepspaces)
                    {
        	    $l1 =~ s/\s//g ;
		    $l2 =~ s/\s//g ;
                    }
		$eq = lc ($l1) eq lc ($l2) ;
		}
	    }

	if (!$eq)
	    {
	    print "\nError in Line $line\nIs:\t>$l1<\nShould:\t>$l2<\n" ;
	    return $line?$line:-1 ;
	    }
	}

    if (!$errin)
	{
	while (defined ($l2 = <F2>))
	   {
	   chompcr ($l2) ;
           $line2++ ;
           printf ("-->#%3d: %s\n", $line2, $l2) if ($opt_verbosecmp) ;
	   if (!($l2 =~ /^\s*$/))
		{
		print "\nError in Line $line\nIs:\t\nShould:\t$l2\n" ;
	        return $line?$line:-1 ;
		}
	    $line++ ;
	    }
	}

    close F1 ;
    close F2 ;

    return $err ; 
    }

#########################
#
# GET/POST via HTTP.
#

sub REQ

    {
    my ($loc, $file, $query, $ofile, $content, $upload, $cookieaction, $respheader) = @_ ;
    
    eval 'require LWP::UserAgent' ;
    return "LWP not installed\n" if ($@) ;
    eval 'use HTTP::Request::Common'  ;
    return "HTTP::Request::Common not installed\n" if ($@) ;
    eval 'require URI::URL';
    return "URI::URL not installed\n" if ($@) ;
    
    $query          ||= '' ;     
    $cookieaction   ||= '' ;
	
    my $ua = new LWP::UserAgent;    # create a useragent to test

    my($request,$response,$url);
    my $sendcookie = '' ;

    if (!$upload)
	{
	$url = new URI::URL("http://$host:$port/$loc/$file?$query");

        if ($cookie && ($cookieaction =~ /url/) && !($cookieaction =~ /nocookie/) ) 
            {
            if ($url =~ /\?/)
                {
                $url .= "&$cookie" ;
                }
            else
                {
                $url .= "?$cookie" ;
                }
            $sendcookie = $cookie ;
            }

	$request = new HTTP::Request($content?'POST':'GET', $url);
        if ($cookieaction =~ /cookie=(.*?)$/)
            {
            $request -> header ('Cookie' => $1) ;
            $sendcookie = $1 ;
            }
        elsif ($cookie && !($cookieaction =~ /nocookie/) && !($cookieaction =~ /url/)) 
            {             
            $request -> header ('Cookie' => $cookie) ;
            $sendcookie = $cookie ;
            }
        
	$request -> content ($content) if ($content) ;
	}
    else
	{
	my @q = split (/\&|=/, $query) ;
        
        $request = POST ("http://$host:$port/$loc/$file",
					Content_Type => 'form-data',
					Content      => [ upload => [undef, '12upload-filename', 
								    'Content-type' => 'test/plain',
								    Content => $upload],
							  content => $content,
                                                          @q ]) ;
	}
	    
    #print "Request: " . $request -> as_string () ;
	    

    $response = $ua->request($request, undef, undef);

    open FH, ">$ofile" ;
    { local $^W = 0 ; binmode (FH, ":encoding(iso-8859-1)") if ($] >= 5.008000) ; }
    print FH $response -> content ;
    close FH ;

    my $c ;
    if ($cookieaction =~ /url/)
        {
        $response -> content =~ /(EMBPERL_UID=.*?)\"/ ;
        $c = $1 || '' ;
        }
    else
        {
        $c = $response -> header ('Set-Cookie') || '' ;
        }
    $cookie = $c if (($c =~ /EMBPERL_UID/) && !($cookieaction =~ /nosave/)) ;  
    $cookie = undef if (($c =~ /EMBPERL_UID=;/) && !($cookieaction =~ /nosave/)) ;  
    $cookie =~ s/;.*$// if ($cookie) ;

    $sendcookie ||= '' ;
    print "\nSent: $sendcookie, Got: " , ($c||''), "\n" if ($opt_showcookie) ;
    
    #print $response -> headers -> as_string () ;

    return $response -> message if (!($response->is_success || ($response->is_redirect && $respheader && $respheader ->{location}) )) ;

    my $m = 'ok' ;
    print "\nExpected new cookie:  Sent: $sendcookie, Got: " , ($c||''), "\n", $m = '' if (($cookieaction =~ /expectnew/) && ($sendcookie eq $c || !$c)) ;
    print "\nExpected same cookie: Sent: $sendcookie, Got: " , ($c||''), "\n", $m = ''  if (($cookieaction =~ /expectsame/) && ($sendcookie ne $c || !$c)) ;
    print "\nExpected no cookie:   Sent: $sendcookie, Got: " , ($c||''), "\n", $m = ''  if (($cookieaction =~ /expectno/) && $c) ;
    print "\nExpected expire cookie: Sent: $sendcookie, Got: " , ($c||''), "\n", $m = ''  if (($cookieaction =~ /expectexpire/) && !($c =~ /^EMBPERL_UID=; expires=/)) ;
    

    if ($respheader)
        {
        local $^W = 0 ;
        while (my ($k, $v) = each (%$respheader))
            {
            my @x ;
            my $i ;
        
            if (ref ($v) eq 'ARRAY')
                {
                @x = split (/\s*,\s*/, $response -> header ($k)) ;
                $i = 0 ;
                foreach (@$v)
                    {
                    if ($x[$i] ne $_)
                        {
                        print "\nExpected HTTP header #$i $k: $_, Got value $x[$i]" ;
                        $m = 'header missing' ;
                        }
                    $i++ ;
                    }                
                } 
            elsif (($x = $response -> header ($k)) ne $v)
                {
                print "\nExpected HTTP header $k: $v, Got value $x" ;
                $m = 'header missing' ;
                }
            }
        }


    return $m ;
    }

###########################################################################
#
# Get Memory from /proc filesystem
#

sub GetMem
    {
    my ($pid) = @_ ;
    
    my @status ;
    
    return 0 if ($EPWIN32) ;

    open FH, "/proc/$pid/status" or die "Cannot open /proc/$pid/status" ;
    @status = <FH> ;
    close FH ;

    my @line = grep (/VmSize/, @status) ;
    $line[0] =~ /^VmSize\:\s+(\d+)\s+/ ;
    my $vmsize = $1 ;
    
    return $vmsize ;
    }           

###########################################################################
#
# Get output in error log
#

sub CheckError

    {
    my ($cnt, $noerrtest) = @_ ;
    my $err = 0 ;
    my $ic ;

    $cnt ||= 0 ;
    $ic    = $cnt ;

    while (<ERR>)
	{
	chomp ;
	if (!($_ =~ /^\s*$/) &&
	    !($_ =~ /\-e /) &&
	    !($_ =~ /Warning/) &&
	    !($_ =~ /mod_ssl\:/) &&
	    !($_ =~ /SES\:/) &&
	    !($_ =~ /gcache started/) &&
            !($_ =~ /EmbperlDebug: /) &&
            !($_ =~ /not available until httpd/) &&
            !($_ =~ /Init: Session Cache is not configured/) &&
            $_ ne 'Use of uninitialized value.')
	    {
		# count literal \n as newline,
		# because RedHat excapes newlines in error log
	    my @cnt = split /(?:\\n(?!ot))+/ ;	
	    $cnt -= @cnt ; 
	    if ($cnt < 0 && !$noerrtest)
		{ 
		print "\n\n" if ($cnt == -1) ;
		print "[$cnt]$_\n" if (!defined ($opt_ab) || !(/Warn/));
		$err = 1 ;
		}
	    }
	}
    
    if ($cnt > 0)
	{
	$err = 1 ;
	print "\n\nExpected $cnt more error(s) in logfile\n" ;
	}

    print "\n" if $err ;

    return $err ;
    }

#########################


sub CheckSVs

    {
    my ($loopcnt, $n) = @_ ;
    
    open SVLOG, $logfile or die "Cannot open $logfile ($!)" ;

    seek SVLOG, ($EP2?-10000:-3000), 2 ;

    while (<SVLOG>)
	{
	if (/Exit-SVs: (\d+)/)
	    {
	    $num_sv = $1 || 0;
	    $last_sv[$n] ||= 0 ;
	    print "SVs=$num_sv/$last_sv[$n]/$max_sv " ;
	    if ($num_sv > $max_sv) 
		{
		print "GROWN " ;
		$max_sv = $num_sv ;
		
		}
	    die "\n\nMemory problem (SVs)" if ($opt_exitonsv && $loopcnt > 3 &&
					       $testnum == $startnumber && 
                                               $last_sv[$n] < $num_sv && 
                                               $last_sv[$n] != 0 && 
                                               $num_sv != 0) ;
	    $last_sv[$n] = $num_sv  ;
	    last ;
	    }
	 }

     close SVLOG ;
     }

#########################


sub run_check

    {
    my ($cmd, $cmp) = @_ ;


    $cmd =~ s/\//\\/g if ($EPWIN32) ;

    
    open STFH, "$cmd 2>&1 |" ; 

    my @x = <STFH> ; 

    close STFH ;

    grep (/$cmp/, @x) or die "ERROR: $cmp not found\nGot @x\n" ;
    print "ok\n" ;
    }



######################### We start with some black magic to print on failure.


#use Config qw (myconfig);
#print myconfig () ;


##################


use Embperl;
use Embperl::Object ;
use Embperl::Util ;
use Embperl::Run ;
#require Embperl::Module ;

print "ok\n";

#### check commandline options #####

if (!$opt_modperl && !$opt_cgi && !$opt_offline && !$opt_execute && !$opt_cache && !$opt_ep1)
    {
    if (defined ($opt_ab))
	{
	$opt_modperl = 1 ;	
	}
    elsif ($EPAPACHEVERSION)
        { $opt_cache = $opt_modperl = $opt_cgi =  $opt_offline = $opt_execute = 1 }
    else
        { $opt_cache = $opt_offline = $opt_execute = 1 }
    #$opt_ep1 = 1 ;
    }


$opt_ep1 = $opt_modperl = $opt_cgi = $opt_offline = $opt_execute = $opt_cache = 0 if ($opt_start || $opt_startinter || $opt_kill) ;

$opt_nokill = 1 if ($opt_nostart || $opt_start || $opt_startinter) ;
$looptest  = defined ($opt_loop)?1:0 ; # endless loop tests

$outfile .= ".$$" if ($opt_uniquefn) ;
$defaultdebug = 1 if ($opt_quite) ;
$defaultdebug = 0 if ($opt_qq) ;
$opt_ep1 = 0 if (!$EP2) ;
$EP1COMPAT = 1 if ($opt_ep1) ;

#@tests = @tests2 if ($EP2) ;
$startnumber = 0 ;
$keepspaces  = 0 ;

if ($#ARGV >= 0)
    {
    if ($ARGV[0] =~ /^-/)
	{
	$#tests = - $ARGV[0] ;
	}
    elsif ($ARGV[0] =~ /^(\d+)-/)
	{
	my $i = $1 ;
        $startnumber = $i ;
        shift @tests while ($i-- > 0) ;
	}
    elsif ($ARGV[0] =~ /^\d/)
	{
	@savetests = @tests ;
        $startnumber = $ARGV[0] ;
	@tests = () ;
	while (defined ($t = shift @ARGV))
	    {
	    push @tests, $savetests[$t] ;
	    }
	}
    else
	{
        @tests = () ;
	@testdata = () ;
	my $i = 0 ;
	@testdata = map { push @tests, $i ; $i+=2 ; ($_ => {}) } @ARGV ;
	}
    }
    


#### preparefile systems stuff ####


unlink ($outfile) ;
unlink ($httpderr) ;
unlink ($offlineerr) ;

#remove old sessions
foreach (<$tmppath/*>)
    {
    unlink ($_) if ($_ =~ /^$tmppath\/[0-9a-f]+$/) ;
    }


-w $tmppath or die "***Cannot write to $tmppath" ;

#### some more init #####
	
$DProf = $INC{'Devel/DProf.pm'}?1:0 ;    
$err = 0 ;
$loopcnt = 0 ;
$notseen = 1 ;
%seen = () ;
$max_sv = 0 ;
$version = $EP2?2:1 ;
$frommem = 0 ;
	
$testshare = "Shared Data" ; 

$cp = Embperl::Util::AddCompartment ('TEST') ;

$cp -> deny (':base_loop') ;
$cp -> share ('$testshare') ;

$ENV{EMBPERL_ALLOW} = 'asc|\\.xml$|\\.htm$|\\.htm-1$' ;

#Embperl::log ("Start testing...\n") ; # force logfile open


if ($EPC_ENABLE)
    {
    print "\nCreate crypted source...\n" ;
    my $rc = system ("crypto/epcrypto test/html/plain.htm test/html/crypto.htm") ;
    if ($rc)
        {
        print "Source encryption failed\n" ;
        exit (1) ;
        }
    }

do  
    {
    if ($opt_offline || $opt_ep1 || $opt_execute || $opt_cache)
        {   
        no warnings ;
        open (SAVEERR, ">&STDERR")  || die "Cannot save stderr" ;  
        open (STDERR, ">$offlineerr") || die "Cannot redirect stderr" ;  
        open (ERR, "$offlineerr")  || die "Cannot open redirected stderr ($offlineerr)" ;  ;  
        }

    #############
    #
    #  OFFLINE
    #
    #############

    if ($opt_offline || $opt_ep1)
	{
	print "\nTesting offline mode...\n\n" ;

	$n = 0 ;
	$t_offline = 0 ;
	$n_offline = 0 ;
        foreach $ep1compat (($version == 2 && $opt_ep1 && $opt_offline)?(0, 1):(($version == 2 && $opt_ep1)?1:0))
            {
	    $testnum = -1 + $startnumber ;
            #next if (($ep1compat && !($opt_ep1))  || (!$ep1compat && !($opt_offline)));

            $ENV{EMBPERL_EP1COMPAT} = $ep1compat?1:0 ;
	    print "\nTesting Embperl 1.x compatibility mode...\n\n" if ($ep1compat) ;
            
            foreach $testno (@tests)
	        {
                $file = $testdata[$testno] ;
                $test = $testdata[$testno+1] ;
	        $org  = '' ;
	        $testversion = $version == 2 && !$ep1compat?2:1 ;

	        $testnum++ ;
                next if ($test->{version} && $testversion != $test->{version}) ;
                next if ((defined ($test -> {offline}) && $test -> {offline} == 0) ||
                              (!$test -> {offline} && ($test -> {modperl} || $test -> {cgi} || $test -> {http}))) ;
                next if ($version == 2 && $ep1compat && defined ($test -> {ep1compat}) && !$test -> {ep1compat}) ;

	        next if ($DProf && ($file =~ /safe/)) ;
	        next if ($DProf && ($file =~ /opmask/)) ;

                if (exists ($test -> {condition}))
                    {
                    next if (!eval ($test -> {condition})) ;
                    }
                
                $errcnt = $test -> {errors} || 0 ;

                $debug = $test -> {debug} || $defaultdebug ;  
	        $debug = 0 if ($opt_qq) ;
	        $page = "$inpath/$file" ;
	        $page = "$inpath$testversion/$file" if (-e "$inpath$testversion/$file") ;
                #$page .= '-1' if ($ep1compat && -e "$page-1") ;
    
	        $notseen = $seen{"o:$page"}?0:1 ;
	        $seen{"o:$page"} = 1 ;
    
	        delete $ENV{EMBPERL_OPTIONS} if (defined ($ENV{EMBPERL_OPTIONS})) ;
	        $ENV{EMBPERL_OPTIONS} = $test -> {option} if (defined ($test -> {option})) ;
	        delete $ENV{EMBPERL_SYNTAX} ;
                $ENV{EMBPERL_SYNTAX} = $test -> {syntax} if (defined ($test -> {syntax})) ;
	        delete $ENV{EMBPERL_RECIPE} ;
                $ENV{EMBPERL_RECIPE} = $test -> {recipe} if (defined ($test -> {recipe})) ;
	        delete $ENV{EMBPERL_XSLTSTYLESHEET} ;
                $ENV{EMBPERL_XSLTSTYLESHEET} = $test -> {xsltstylesheet} if (defined ($test -> {xsltstylesheet})) ;
	        delete $ENV{EMBPERL_XSLTPROC} ;
                $ENV{EMBPERL_XSLTPROC} = $test -> {xsltproc} if (defined ($test -> {xsltproc})) ;
	        delete $ENV{EMBPERL_COMPARTMENT} if (defined ($ENV{EMBPERL_COMPARTMENT})) ;
	        $ENV{EMBPERL_COMPARTMENT} = $test -> {compartment} if (defined ($test -> {compartment})) ;
	        delete $ENV{EMBPERL_PACKAGE}  if (defined (delete $ENV{EMBPERL_PACKAGE})) ;
	        $ENV{EMBPERL_PACKAGE}     = $test -> {'package'} if (defined ($test -> {'package'})) ;
	        delete $ENV{EMBPERL_APP_HANDLER_CLASS}  if (defined (delete $ENV{EMBPERL_APP_HANDLER_CLASS})) ;
	        $ENV{EMBPERL_APP_HANDLER_CLASS}     = $test -> {'app_handler_class'} if (defined ($test -> {'app_handler_class'})) ;
	        delete $ENV{EMBPERL_APPNAME}  if (defined (delete $ENV{EMBPERL_APPNAME})) ;
	        $ENV{EMBPERL_APPNAME}     = $test -> {'app_handler_class'} if (defined ($test -> {'app_handler_class'})) ;
                $ENV{EMBPERL_INPUT_ESCMODE} = defined ($test -> {'input_escmode'})?$test -> {'input_escmode'}:7 ;
	        @testargs = ( '-o', $outfile ,
			      '-l', $logfile,
			      '-d', $debug,
			      ##($test->{param}?(ref ($test->{param}) eq 'ARRAY'?map { ('-p', $_) } @{$test->{param}}:('-p', $test->{param})):()),
			       $page, $test -> {query_info} || '') ;
	        unshift (@testargs, 'dbgbreak') if ($opt_dbgbreak) ;
    
	        $txt = "#$testnum ". $file . ($debug != $defaultdebug ?"-d $debug ":"") . ($test->{msg} || '') . '...' ;
	        $txt .= ' ' x (30 - length ($txt)) ;
	        print $txt ; 
    
    
	        unlink ($outfile) ;

	        $n_offline++ ;
	        $t1 = 0 ; # Embperl::Clock () ;
	        $err = Embperl::Run::run (@testargs, ref $test->{param} eq 'HASH'?[$test->{param}]:$test->{param}) ;
	        $t_offline += 0 ; # Embperl::Clock () - $t1 ;

	        if ($opt_memcheck)
		    {
		    my $vmsize = GetMem ($$) ;
		    $vminitsize = $vmsize if $loopcnt == 2 ;
		    print "\#$loopcnt size=$vmsize init=$vminitsize " ;
		    print "GROWN! at iteration = $loopcnt  " if ($vmsize > $vmmaxsize) ;
		    $vmmaxsize = $vmsize if ($vmsize > $vmmaxsize) ;
		    CheckSVs ($loopcnt, $n) ;
		    }
		    
	        $errin = $err ;
                $err = CheckError ($errcnt, $test -> {noerrtest}) if ($err == 0 || ($errcnt > 0 && $err == 500) || $file eq 'notfound.htm'  || $file eq 'notallow.xhtm') ;
    
	        
	        if ($err == 0 && $errin != 500 && $file ne 'notfound.htm' && $file ne 'notallow.xhtm')
		    {
                    local $keepspaces = $test -> {option} && ($test -> {option} & 0x100000)?1:0 ;
		    $page =~ /.*\/(.*)$/ ;
		    $org = "$cmppath/$1" ;
		    $org = "$cmppath$testversion/$1" if (-e "$cmppath$testversion/$1") ;
                    $org .= $test -> {cmpext} if ($test -> {cmpext}) ;

		    $err = CmpFiles ($outfile, $org, $errin) ;
		    }

	        print "ok\n" unless ($err) ;
	        $err = 0 if ($opt_ignoreerror) ;
	        last if $err ;
	        $n++ ;
	        }
            last if $err ;
            }
	}
    
    foreach (keys %ENV)
        {
        delete $ENV{$_} if ((/^EMBPERL_/) && $_ ne 'EMBPERL_LOG'  && $_ ne 'EMBPERL_DEBUG' && $_ ne 'EMBPERL_SESSION_HANDLER_CLASS') ;
        }
    delete $ENV{PATH_TRANSLATED} ;

    if ($opt_execute)
	{
	#############
	#
	#  Execute
	#
	#############

        $ENV{EMBPERL_EP1COMPAT} = 0 ;
        delete $ENV{EMBPERL_ALLOW} ;
	delete $ENV{QUERY_STRING} ;

	if ($err == 0)
	    {
	    print "\nTesting Execute function...\n\n" ;

    
	    Embperl::Init (undef, {}) ;
    
	    $notseen = 1 ;        
	    $txt = 'div.htm' ;
	    $org = "$cmppath/$txt" ;
	    $src = "$inpath/$txt" ;
	    $errcnt = 0 ;

		{
		local $/ = undef ;
		open FH, $src or die "Cannot open $src ($!)" ;
		binmode FH ;
		$indata = <FH> ;
		close FH ;
		}


	    $txt2 = "$txt from file...";
	    $txt2 .= ' ' x (30 - length ($txt2)) ;
	    print $txt2 ; 

	    unlink ($outfile) ;
	    $t1 = 0 ; # Embperl::Clock () ;
	    $err = Embperl::Execute ({'inputfile'  => $src,
					    'mtime'      => 1,
					    'outputfile' => $outfile,
					    'debug'      => $defaultdebug,
				            input_escmode => 7, 
                                	    }) ;
		
	    $t_exec += 0 ; # Embperl::Clock () - $t1 ; 

	    $err = CheckError ($errcnt) if ($err == 0) ;
	    $err = CmpFiles ($outfile, $org)  if ($err == 0) ;
	    print "ok\n" unless ($err) ;

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "$txt from memory...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		unlink ($outfile) ;
		$t1 = 0 ; # Embperl::Clock () ;
                $err = Embperl::Execute ({'input'      => \$indata,
						'inputfile'  => 'i1',
						'mtime'      => 1,
						'outputfile' => $outfile,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
						}) ;
		$t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		    
		$err = CheckError ($errcnt) if ($err == 0) ;
		$err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		print "ok\n" unless ($err) ;
		}

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "$txt to memory...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		my $outdata ;
                my @errors ;
		unlink ($outfile) ;
		$t1 = 0 ; # Embperl::Clock () ;
		$err = Embperl::Execute ({'inputfile'  => $src,
						'mtime'      => 1,
						'output'     => \$outdata,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
						}) ;
		$t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		    
		$err = CheckError ($errcnt) if ($err == 0) ;
	
		open FH, ">$outfile" or die "Cannot open $outfile ($!)" ;
		print FH $outdata ;
		close FH ;
		$err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		print "ok\n" unless ($err) ;
		}

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "$txt to tied handle...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		my $outdata ;
                my @errors ;
		unlink ($outfile) ;
		$Embperl::Test::STDOUT::output = '' ;
                tie *STDOUT, 'Embperl::Test::STDOUT' ;
                $t1 = 0 ; # Embperl::Clock () ;
                $err = Embperl::Execute ({'inputfile'  => $src,
						'mtime'      => 1,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
						}) ;
		$t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		untie *STDOUT ;
                    
		$err = CheckError ($errcnt) if ($err == 0) ;
	
		open FH, ">$outfile" or die "Cannot open $outfile ($!)" ;
		print FH $Embperl::Test::STDOUT::output ;
		close FH ;
		$err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		print "ok\n" unless ($err) ;
		}

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "$txt from/to memory...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		my $outdata ;
		unlink ($outfile) ;
		$t1 = 0 ; # Embperl::Clock () ;
		$err = Embperl::Execute ({'input'      => \$indata,
						'inputfile'  => $src,
						'mtime'      => 1,
						'output'     => \$outdata,
		                                'errors'     => \@errors,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
						}) ;
		$t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		    
		$err = CheckError ($errcnt) if ($err == 0) ;
	
                if (@errors != 0)
                    {
                    print "\n\n\@errors does not return correct number of errors (is " . scalar(@errors) . ", should 0)\n" ;
                    $err = 1 ;
                    }

		open FH, ">$outfile" or die "Cannot open $outfile ($!)" ;
		print FH $outdata ;
		close FH ;
		$err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		print "ok\n" unless ($err) ;
		}

	    $txt = 'error.htm' ;
	    $org = "$cmppath/$txt" ;#. ($] >= 5.014000?'514':'') ;
	    $org = "$cmppath$version/$txt" if (-e "$cmppath$version/$txt") ;
	    $src = "$inpath/$txt" ;
	    $src = "$inpath$version/$txt" if (-e "$inpath$version/$txt") ;
            $page = $src ;

	    $notseen = $seen{"o:$src"}?0:1 ;
	    $seen{"o:$src"} = 1 ;


	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "$txt to memory...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		my $outdata ;
                my @errors ;
		unlink ($outfile) ;
		$t1 = 0 ; # Embperl::Clock () ;
		$err = Embperl::Execute ({'inputfile'  => $src,
						'mtime'      => 1,
						'output'     => \$outdata,
						'debug'      => $defaultdebug,
		                                'errors'     => \@errors,
                                                input_escmode => 7, 
                				}) ;
		$t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		    
                $err = CheckError ($EP2?($] >= 5.010000?6:5):8) if ($err == 0) ;

                if (@errors != ($EP2?4:12))
                    {
                    print "\n\n\@errors does not return correct number of errors (is " . scalar(@errors) . ", should 4)\n" ;
                    $err = 1 ;
                    }

		open FH, ">$outfile" or die "Cannot open $outfile ($!)" ;
		print FH $outdata ;
		close FH ;
		$err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		print "ok\n" unless ($err) ;
		}

	    if (0) #$err == 0 || $opt_ignoreerror)
		{
		$txt2 = "errornous parameter (path) ...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 

		$err = eval { Embperl::Execute ({'inputfile'  => 'xxxx0',
		                                'errors'     => \@errors,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
                                                path => "not an array ref",
                				}) ; } ;
                $err ||= 0 ;       				    
                if ($@ !~ /^Need an Array reference/)
                    {
                    print "\n\n\$@ is wrong, is = '$@', should 'Need an Array reference'\n" ;
                    $err = 1 ;
                    }

		print "ok\n" unless ($err) ;
		}

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "errornous parameter (input) ...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 
		my $out ;
		@errors = () ;
		
		$err = Embperl::Execute ({'inputfile'  => 'xxxx1',
		                                'errors'     => \@errors,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
                                                input => $out,
                                                output => \$out,
                				}) ;
                $err = CheckError (1)  ;

                if (@errors != 1)
                    {
                    print "\n\n\@errors does not return correct number of errors (is " . scalar(@errors) . ", should 1)\n" ;
                    $err = 1 ;
                    }


		print "ok\n" unless ($err) ;
		}

	    if ($err == 0 || $opt_ignoreerror)
		{
		$txt2 = "errornous parameter (output) ...";
		$txt2 .= ' ' x (30 - length ($txt2)) ;
		print $txt2 ; 
		my $out ;
		@errors = () ;

		$err = Embperl::Execute ({'inputfile'  => 'xxxx2',
		                                'errors'     => \@errors,
						'debug'      => $defaultdebug,
                                                input_escmode => 7, 
                                                output => $out,
                				}) ;
                $err = CheckError (2)  ;

                if (@errors != 2)
                    {
                    print "\n\n\@errors does not return correct number of errors (is " . scalar(@errors) . ", should 2)\n" ;
                    $err = 1 ;
                    }


		print "ok\n" unless ($err) ;
		}

            foreach $src (
                          'EmbperlObject/epopage1.htm', 'EmbperlObject/sub/epopage2.htm', 'EmbperlObject/obj/epoobj3.htm',
                          'EmbperlObject/sub/epobless.htm', 'EmbperlObject/sub/epobless.htm', 
                          'EmbperlObject/epofdat.htm',            
                          'EmbperlObject/sub/epobless2.htm', 'EmbperlObject/sub/epobless2.htm',
                          'EmbperlObject/sub/epobless3.htm', 'EmbperlObject/sub/epobless3.htm',
                          ['EmbperlObject/app/epoapp.htm', 'epoapp.pl'],   
                          ['EmbperlObject/app/epoapp2.htm', 'epoapp.pl'],   
                          ['EmbperlObject/app/epoapp.htm', 'epoapp.pl'],   
                          ['EmbperlObject/app/epoapp.htm', 'epoapp.pl'],   
                          )
                {
	        if ($err == 0 || $opt_ignoreerror) # && $version == 1)
		    {
                    my $app = '' ;

                    if (ref $src)
                        {
                        $app = $src -> [1] ;
                        $src = $src -> [0] ;
                        }

                    $src =~ m#^.*/(.*?)$# ;
		    $org = "$cmppath/$1" ;
                    $page = $src ;
                                    
                    $txt2 = "$src ...";
		    $txt2 .= ' ' x (30 - length ($txt2)) ;
		    print $txt2 ; 

		    my $outdata ;
                    my @errors ;
		    unlink ($outfile) ;
		    $t1 = 0 ; # Embperl::Clock () ;
		    $err = Embperl::Object::Execute ({'inputfile'  => "$EPPATH/$inpath/$src",
						    'object_base' => 'epobase.htm',    
						    ($app?('object_app' => $app):()),    
                                                    'app_name'     => "eo_$app",
                                                    'debug'      => $defaultdebug,
					            'outputfile' => $outfile,
		                                    'errors'     => \@errors,
                                                    'use_env'    => 1,
                				    'fdat'       => { a => 1, b => 2 },
                                                    }) ;
		    print "error $err\n" if ($err) ;
                    
                    $t_exec += 0 ; # Embperl::Clock () - $t1 ; 
		        
                    $err = CheckError (0) if ($err == 0) ;

		    $err = CmpFiles ($outfile, $org)  if ($err == 0) ;
		    print "ok\n" unless ($err) ;
		    }
                }

	    }
	}

    if ($EP2 && $opt_cache)
	{
	#############
	#
	#  Cache tests
	#
	#############

        delete $ENV{EMBPERL_ALLOW} ;
	if ($err == 0)
	    {
            $frommem = 1 ;
	    print "\nTesting Ouput Caching...\n\n" ;
    
	    #Embperl::Init ($logfile, $defaultdebug) ;
    
            my $src = '* [+ $param[0] +] *' ;
            my $cmp = '"* $p *"' ;
            my $out ;

            @cachetests = (
                    { 
                    text  => 'No cache 1',
                    param => { param => [1], },
                    'cmp'   => 1,
                    },
                    { 
                    text  => 'No cache 2',
                    param => { param => [99], },
                    'cmp'   => 99,
                    },
                    { 
                    text  => 'Expires in 1 sec',
                    param => { param => [3], expires_in => 1, },
                    'cmp'   => 3,
                    },
                    { 
                    text  => 'Expires in 1 sec (cached)',
                    param => { param => ['not cached'], expires_in => 1, },
                    'cmp'   => 3,
                    },
                    { 
                    text  => 'Wait for expire',
                    'sleep' => 3,
                    },
                    { 
                    text  => 'Expires in 1 sec (reexec)',
                    param => { param => ['reexec'], expires_in => 1, },
                    'cmp'   => 'reexec',
                    },
                    { 
                    text  => 'Expires function',
                    param => { param => [4], expires_func => sub { 1 } },
                    'cmp'   => 4,
                    },
                    { 
                    text  => 'Expires function (cached)',
                    param => { param => ['not cached func'], expires_func => sub { 0 } },
                    'cmp'   => 4,
                    },
                    { 
                    text  => 'Expires function (reexec)',
                    param => { param => ['reexec func'], expires_func => sub { 1 }, },
                    'cmp'   => 'reexec func',
                    },
                    { 
                    text  => 'Expires string function (cached)',
                    param => { param => ['not cached string func'], },
                    env   => { EMBPERL_EXPIRES_FUNC => 'sub { 0 }', },
                    'cmp'   => 'reexec func',
                    },
                    { 
                    text  => 'Expires string function (reexec)',
                    param => { param => ['reexec string func'],  },
                    env   => { EMBPERL_EXPIRES_FUNC => 'sub { 1 }', },
                    'cmp'   => 'reexec string func',
                    },
                    { 
                    text  => 'Expires named function (cached)',
                    param => { param => ['not cached named func'], expires_func => 'main::s0' },
                    'cmp'   => 'reexec string func',
                    },
                    { 
                    text  => 'Expires named function (reexec)',
                    param => { param => ['reexec named func'], expires_func => 'main::s1', },
                    'cmp'   => 'reexec named func',
                    },
                    { 
                    text  => 'Change query_info',
                    param => { param => ['query_info'], expires_func => 'main::s0' },
                    query_info => 'qi',
                    'cmp'   => 'query_info',
                    },
                    { 
                    text  => 'Change query_info (cached)',
                    param => { param => ['not cached query_info'], expires_func => 'main::s0' },
                    query_info => 'qi',
                    'cmp'   => 'query_info',
                    },
                    { 
                    text  => 'Expires named function (cached)',
                    param => { param => ['not cached named func query_info'], expires_func => 'main::s0' },
                    'cmp'   => 'reexec named func',
                    },
                    { 
                    text  => 'Change query_info (reexec)',
                    param => { param => ['reexec query_info'], expires_func => 'main::s1' },
                    query_info => 'qi',
                    'cmp'   => 'reexec query_info',
                    },
                    { 
                    text  => 'Expires named function (cached)',
                    param => { param => ['not cached named func query_info'], expires_func => 'main::s0' },
                    'cmp'   => 'reexec named func',
                    },
                    { 
                    text  => 'Change query_info (cached)',
                    param => { param => ['not cached reexec query_info 2'], expires_func => 'main::s0' },
                    query_info => 'qi',
                    'cmp'   => 'reexec query_info',
                    },
                    { 
                    text  => 'Modify source',
                    param => { param => ['mod'], expires_func => 'main::s0' },
                    mtime => 2,
                    'cmp'   => 'mod',
                    },

                    { 
                    text  => 'Modify source query_info',
                    param => { param => ['mod query_info'], expires_func => 'main::s0' },
                    query_info => 'qi',
                    mtime => 2,
                    'cmp'   => 'mod query_info',
                    },

                    { 
                    text  => '$EXPIRES in source',
                    name  => 'c2',
                    src   => \('[! $EXPIRES = 1 !]' . $src),
                    param => { param => ['expires in src'] },
                    'cmp'   => 'expires in src',
                    },
                    { 
                    text  => '$EXPIRES in source (cached)',
                    name  => 'c2',
                    src   => \('[! $EXPIRES = 1 !]' . $src),
                    param => { param => ['not cached expires in src'] },
                    'cmp'   => 'expires in src',
                    },
                    { 
                    text  => 'Wait for expire',
                    'sleep' => 3,
                    },
                    { 
                    text  => '$EXPIRES in source (reexc)',
                    name  => 'c2',
                    src   => \('[! $EXPIRES = 1 !]' . $src),
                    param => { param => ['reexec expires in src'] },
                    'cmp'   => 'reexec expires in src',
                    },
                    { 
                    text  => 'sub EXPIRES in source',
                    name  => 'c3',
                    src   => \('[! sub EXPIRES { 0 } !]' . $src),
                    param => { param => ['expires_func in src'] },
                    'cmp'   => 'expires_func in src',
                    },
                    { 
                    text  => 'sub EXPIRES in source (cached)',
                    name  => 'c3',
                    src   => \('[! sub EXPIRES { 0 } !]' . $src),
                    param => { param => ['not cached expires_func in src'] },
                    'cmp'   => 'expires_func in src',
                    },
                ) ;

            foreach $cachetest (@cachetests)
                {
                if ($err == 0)
                    {
                    printf ("%-30s", "$cachetest->{text}...") ;
                    if ($cachetest->{'sleep'})
                        {
                        sleep $cachetest->{'sleep'} ;
                        }
                    else
                        {
                        $ENV{QUERY_STRING} = $cachetest->{'query_info'} if ($cachetest->{'query_info'}) ;
                        delete $ENV{QUERY_STRING}  if (!$cachetest->{'query_info'}) ;
                        if ($cachetest->{'env'}) 
                            {
                            while (my ($k, $v) = each %{$cachetest->{'env'}})
                                {
                                $ENV{$k} = $v ;
                                }
                            }

                        $err = Embperl::Execute ({inputfile => $cachetest->{'name'} || 'c1', 
                                                        input => $cachetest->{'src'} || \$src, 
                                                        output => \$out, 
                                                        mtime => $cachetest->{'mtime'} || 1,
                                                        use_env => 1,
                                                        %{$cachetest->{param}}}) ;
                        $err = CheckError (0) if ($err == 0) ;
                        $err = CmpInMem ($out, $cmp, $cachetest->{'cmp'}) if ($err == 0) ;

                        if ($cachetest->{'env'}) 
                            {
                            while (my ($k, $v) = each %{$cachetest->{'env'}})
                                {
                                delete $ENV{$k}  ;
                                }
                            }

                        }
                    print "ok\n" if ($err == 0) ;
                    }
                }
                


            }
        $frommem = 0 if ($err == 0) ;
        }




    if ((($opt_execute) || ($opt_offline)   || ($opt_ep1)  || ($opt_cache)) && $looptest == 0)
	{
	close STDERR ;
	open (STDERR, ">&SAVEERR") ;
	}
    
    $err = 0 if ($opt_ignoreerror) ;

    #############
    #
    #  mod_perl & cgi
    #
    #############

    if ($opt_modperl)
	{ $loc = $embploc ; }
    elsif ($opt_cgi)   
	{ $loc = $cgiloc ; }
    else
	{ $loc = '' ; }


    if (($loc ne '' && $err == 0 && $loopcnt == 0 && !$opt_nostart) || $opt_start || $opt_startinter)
	{

        if ($opt_start)
            {
	    if (open FH, "$tmppath/httpd.pid")
                {
	        $httpdpid = <FH> ;
	        chop($httpdpid) ;       
	        close FH ;
                
                print "Try to kill Apache pid = $httpdpid\n" ;
                if ($EPWIN32)
                    {
                    system ("\"$EPHTTPD\" -k stop -f \"$EPPATH/$httpdstopconf\" ") ;
                    }
                else
                    {
                    kill 15, $httpdpid ;
                    }
                foreach (1..5)
                    {
                    last if (!-f "$tmppath/httpd.pid") ;
                    sleep (1) ;
                    }

	        unlink "$tmppath/httpd.pid" ;
                }
            }

	#### Configure httpd conf file
	$EPDEBUG = $defaultdebug ;

        $ENV{EMBPERL_LOG} = $logfile ;
        foreach my $src (<$confpath/*.src>)
            { 
            local $^W = 0 ;
	    my $cf ;
	    local $/ = undef ;
            my ($dest) = ($src =~ /^(.*)\.src$/) ;
	    open IFH, $src or die "***Cannot open $src" ;
	    $cf = <IFH> ;
	    close IFH ;
            open OFH, ">$dest" or die "***Cannot open $dest" ;
	    eval $cf ;
	    die "***Cannot eval $src to $dest ($@)" if ($@) ;
	    close OFH ;
            }
                
	#### Start httpd
	unlink "$tmppath/httpd.pid" ;
        unlink $httpderr ;

	chmod 0666, $logfile ;
	$XX = $opt_multchild && !($opt_gdb || $opt_ddd)?'':'-X' ;

	print "\n\nPerforming httpd syntax check 1 ...  " ;
	run_check ("\"$EPHTTPD\" " . ($opt_cfgdebug?"-D EMBPERL_APDEBUG ":'') . " -t -f \"$EPPATH/$httpdminconf\" ", 'Syntax OK') ; 
	print "\n\nPerforming httpd syntax check 2 ...  " ;
	run_check ("\"$EPHTTPD\" " . ($opt_cfgdebug?"-D EMBPERL_APDEBUG ":'') . " -t -f \"$EPPATH/$httpdconf\" ", 'Syntax OK') ; 

	print "\n\nStarting httpd...       " ;
	if ($EPWIN32)
	    {
            #$ENV{PATH} .= ";$EPHTTPDDLL;$EPHTTPDDLL\\..\\os\\win32\\release;$EPHTTPDDLL\\..\\os\\win32\\debug" if ($EPWIN32) ;

            $ENV{PERL_STARTUP_DONE} = 1 ;

            $EPAPACHEVERSION =~ m#Apache/1\.3\.(\d+) # ;

            $XX .= ' -s ' if ($1 < 13) ;

	    Win32::Process::Create($HttpdObj, $EPHTTPD,
				   "Apache $XX -f $EPPATH/$httpdconf ", 0,
				   # NORMAL_PRIORITY_CLASS,
				   0,
				    ".") or die "***Cannot start $EPHTTPD" ;
	    }
	else
	    {
	    if ($opt_gdb || $opt_ddd)
		{
		#open FH, ">dbinitembperlapache" or die "Cannot write to dbinitembperlapache ($!)" ;
		#print FH "set args $XX -f $EPPATH/$httpdconf\n" ;
		#print FH "r\n" ;
		#print FH "BT\n" if ($opt_gdb) ;
		#close FH ;
	        #system (($opt_ddd?'ddd':'gdb') . " -x dbinitembperlapache $EPHTTPD " . ($opt_startinter?'':'&')) and die "***Cannot start $EPHTTPD" ;
		print ' ' . ($opt_ddd?'ddd':'gdb') . " --args $EPHTTPD " . ($opt_cfgdebug?"-D EMBPERL_APDEBUG ":'') . " $XX -f $EPPATH/$httpdconf " . "\n" ;
		system (($opt_ddd?'ddd':'gdb') . " --args $EPHTTPD " . ($opt_cfgdebug?"-D EMBPERL_APDEBUG ":'') . " $XX -f $EPPATH/$httpdconf ") and die "***Cannot start gdb/ddd $EPHTTPD" ;
		}			
	    else
	        {
		system ("$EPHTTPD " . ($opt_cfgdebug?"-D EMBPERL_APDEBUG ":'') . " $XX -f $EPPATH/$httpdconf " . ($opt_startinter?'':'&')) and die "***Cannot start $EPHTTPD" ;
		}
	    }

        my $tries = ($opt_gdb || $opt_ddd)?30:25 ;
        $httpdpid = 0 ;
        my $herr = 0 ;

        while ($tries-- > 0)
            {
	    if (open FH, "$tmppath/httpd.pid")
                {
	        $httpdpid = <FH> ;
	        chop($httpdpid) ;       
	        close FH ;
                last ;
                }
            if ($herr || open (HERR, $httpderr))
                {  
	        seek HERR, 0, 1 ;
                print "\n" if (!$herr) ;
                $herr = 1 ;
                while (<HERR>)
                    {
                    print ;
                    }
                }

            sleep (1) ;
            }
        close HERR if ($herr) ;


        die "Cannot open $tmppath/httpd.pid" if (!$httpdpid) ;

        print "pid = $httpdpid  ok\n" ;

	close ERR ;
	if (!open (ERR, "$httpderr"))
            {
            sleep (1) ;
	    if (!open (ERR, "$httpderr"))
                {
                print "Cannot open Apache error log ($httpderr: $1)\n" ;
                }
            }
        eval {	<ERR> ;  } ; # skip first line and ignore errors

        $httpduid = getpwnam ($EPUSER) if (!$EPWIN32) ;
        }
    elsif ($err == 0 && $EPHTTPD eq '')
	{
	print "\n\nSkiping tests for mod_perl, because Embperl is not build for it.\n" ;
	print "Embperl can still be used as CGI-script, but 'make test' cannot test it\n" ;
	print "without apache httpd installed.\n" ;
	}

    $ep1compat = 0 ;
    while ($loc ne '' && $err == 0)
	{
	if ($loc eq $embploc)
	    { print "\nTesting mod_perl mode...\n\n" ; }
	elsif ($loc eq $cgiloc)
	    { print "\nTesting cgi mode...\n\n" ; }
	else
	    { print "\nTesting FastCGI mode...\n\n" ; }

	$cookie = undef ;
        $t_req = 0 ;
	$n_req = 0 ;
	$n = 0 ;
	$testnum = -1  + $startnumber;
        foreach $testno (@tests)
	    {
            $file = $testdata[$testno] ;
            $test = $testdata[$testno+1] ;
	    $org  = '' ;
            $testnum++ ;
            $testversion = $version == 2 && !$ep1compat?2:1 ;

            #last if ($testnum > 8 && $loc ne $embploc) ; 
            next if ($test->{noloop} && $loopcnt > 0) ;
            next if ($test->{version} && $testversion != $test->{version}) ;
            next if ($loc eq $embploc && 
                      ((defined ($test -> {modperl}) && $test -> {modperl} == 0) ||
                        (!$test -> {modperl} && ($test -> {offline} || $test -> {cgi})))) ;

            next if (($loc eq $cgiloc || $loc eq $fastcgiloc) && 
                      ((defined ($test -> {cgi}) && $test -> {cgi} == 0) ||
                        (!$test -> {cgi} && ($test -> {offline} || $test -> {modperl})) ||
                        ($EPWIN32 && $test -> {'errors'})
                        )) ;
            

	    next if (defined ($opt_ab) && $test -> {'errors'}) ;
            if (exists ($test -> {condition}))
                {
                next if (!eval ($test -> {condition})) ;
                }
                
 
	    #next if ($file eq 'chdir.htm' && $EPWIN32) ;
	    next if ($file eq 'notfound.htm' && ($loc eq $cgiloc || $loc eq $fastcgiloc) && $EPWIN32) ;
	    next if ($file =~ /opmask/ && $EPSTARTUP =~ /_dso/) ;
	    if ($file =~ /sess\.htm/)
                { 
                next if (($loc eq $cgiloc || $loc eq $fastcgiloc) && $EPSESSIONCLASS ne 'Embperl') ;
                if (!$EPSESSIONXVERSION)
                    {
		    $txt2 = "$file...";
		    $txt2 .= ' ' x (29 - length ($txt2)) ;
		    print "#$testnum $txt2 skip on this plattform\n" ; 
                    next ;
                    }
                }
     
            $errcnt = $test -> {errors} || 0 ;
	    $errcnt = -1 if ($EPWIN32 && ($loc eq $cgiloc || $loc eq $fastcgiloc)) ;

	    $debug = $test -> {debug} || $defaultdebug ;  
	    $page = "$inpath/$file" ;
	    $locver = '' ;
	    if (-e "$inpath$testversion/$file") 
		{
		$locver = $testversion ;
            	$page = "$inpath$testversion/$file" ;
		}
	    if ($opt_nostart)
		{
		$notseen = 0 ;
		}
	    elsif ($loc eq $embploc)
		{
		$notseen = $seen{"$loc:$page"}?0:1 ;
		$seen{"$loc:$page"} = 1 ;
		$notseen = 0 if ($file eq 'registry/errpage.htm') ;
		}
	    else
		{
		$notseen = 1 ;
		}
    
	    $txt = "#$testnum $file" . ($debug != $defaultdebug ?"-d $debug ":"") . '...' ;
	    $txt .= ' ' x (30 - length ($txt)) ;
	    print $txt ; 
	    unlink ($outfile) ;
	    
	    $content = $test -> {reqbody} || undef ;
	    $upload = undef ;
	    if ($file eq 'upload.htm') 
		{
		$upload = "f1=abc1\r\n&f2=1234567890&f3=" . 'X' x 8192 ;
		}

            if (!$EPWIN32 && !$test -> {aliasdir} && $loc eq $embploc && !($file =~ /notfound\.htm/))
                {
                print "ERROR: Missing read permission for file $inpath/$file\n" if (!-r $page) ;
                local $> = $httpduid ;
                print "ERROR: $inpath/$file must be readable by $EPUSER (uid=$httpduid)\n" if (!-r $page) ;
                }

	    $n_req++ ;
	    $t1 = 0 ; # Embperl::Clock () ;
            $file .= '-1' if ($opt_ep1 && -e "$page-1") ;
            
            $port = $EPPORT + ($test -> {portadd} || 0) ;

            if (defined ($opt_ab))
		{
	        $m = REQ ("$loc$locver", $file, $test -> {query_info}, $outfile, $content, $upload, $test -> {cookie}, $test -> {respheader}) if ($opt_abpre) ;
		$locver ||= '' ;
		$opt_ab = 10 if (!$opt_ab) ;
		my $cmd = "ab -n $opt_ab 'http://$host:$port/$loc$locver/$file" . ($test->{query_info}?"?$test->{query_info}'":"'") ;
		print "$cmd\n" if ($opt_abverbose) ;
				
		open AB, "$cmd|" or die "Cannot start ab ($!)" ;
		while (<AB>)
			{
			print $_ if ($opt_abverbose || (/Requests/)) ;
			}
		close AB ;
		}
	    else
		{				
	        $m = REQ ("$loc$locver", $file, $test -> {query_info}, $outfile, $content, $upload, $test -> {cookie}, $test -> {respheader}) ;
		}
	    $t_req += 0 ; # Embperl::Clock () - $t1 ; 

	    if ($opt_memcheck)
		{
		my $vmsize = GetMem ($httpdpid) ;
		$vmhttpdinitsize = $vmsize if $loopcnt == 2 ;
		print "\#$loopcnt size=$vmsize init=$vmhttpdinitsize " ;
		print "GROWN! at iteration = $loopcnt  " if ($vmsize > $vmhttpdsize) ;
		die "\n\nMemory problem (Total memory)" if ($opt_exitonmem && $loopcnt > 2 && $vmsize > $vmhttpdsize) ;
		$vmhttpdsize = $vmsize if ($vmsize > $vmhttpdsize) ;
		CheckSVs ($loopcnt, $n) ;
		
		}
	    if (($m || '') ne 'ok' && $errcnt == 0 && !$opt_ab)
		{
		$err = 1 ;
		print "ERR:$m\n" ;
		last ;
		}

	    #$errcnt++ if (($loc eq $cgiloc || $loc eq $fastcgiloc) && $file eq 'notallow.xhtm') ;   
	    sleep ($test->{sleep4err}) if ($test->{sleep4err}) ;
            sleep (1) if (($loc eq $cgiloc || $loc eq $fastcgiloc) && $errcnt) ;
            $err = CheckError ($errcnt, $test -> {noerrtest}) if (($err == 0 || $file eq 'notfound.htm' || $file eq 'notallow.xhtm')) ;
	    if ($err == 0 && $file ne 'notfound.htm' && $file ne 'notallow.xhtm' && !defined ($opt_ab))
		{
		$page =~ /.*\/(.*)$/ ;
		$org = "$cmppath/$1" ;
	        $org = "$cmppath$testversion/$1" if (-e "$cmppath$testversion/$1") ;
                $org .= $test -> {cmpext} if ($test -> {cmpext}) ;

		#print "Compare $page with $org\n" ;
		$err = CmpFiles ($outfile, $org) ;
		}

	    print "ok\n" unless ($err || $opt_ab) ;
	    $err = 0 if ($opt_ignoreerror) ;
	    last if ($err) ;
	    $n++ ;
	    }

	if ($loc ne $cgiloc)   
	    { 
	    $t_mp = $t_req ;
	    $n_mp = $n_req ;
	    }
	else
	    {
	    $t_cgi = $t_req ;
	    $n_cgi = $n_req ;
	    }

	if ($opt_cgi && $err == 0 && $loc eq $embploc && $loopcnt == 0)   
	    { 
            $loc = $cgiloc ; 
            }
	#elsif ($opt_cgi && $err == 0 && $loc eq $cgiloc && $loopcnt == 0)   
	#    { 
        #    eval "require FCGI" ;
        #    $loc = $@?'':$fastcgiloc ; 
        #    if (!$loc)
        #        {
        #        print "\nSkip FastCGI Tests, FCGI.pm not installed\n" ;
        #        }
        #    }
	else
	    {
	    $loc = '' ;
	    }
	}

    if ($defaultdebug == 0)
	{
	print "\n" ;
	print "Offline:  $n_offline tests takes $t_offline sec = ", int($t_offline / $n_offline * 1000) / 1000.0, " sec per test\n" if ($t_offline) ;
	print "mod_perl: $n_mp tests takes $t_mp sec = ", int($t_mp / $n_mp * 1000) / 1000.0 , " sec per test\n"  if ($t_mp) ;
	print "CGI:      $n_cgi tests takes $t_cgi sec = ", int($t_cgi / $n_cgi * 1000) / 1000.0 , " sec per test\n"  if ($t_cgi) ;
	}

    $loopcnt++ ;
    }
until ($looptest == 0 || $err != 0 || ($loopcnt >= $opt_loop && $opt_loop > 0))     ;


if ($err)
    {
    if (!$frommem)
        {
        $page ||= '???' ;
        print "Input:\t\t$page\n" ;
        print "Output:\t\t$outfile\n" ;
        print "Compared to:\t$org\n" if ($org) ;
        print "Log:\t\t$logfile\n" ;
        @p = map { " $_ = $test->{$_}\n" } keys %$test if (ref ($test) eq 'HASH') ;
        print "Testparameter:\n @p" if (@p) ;
        }
    print "\n ERRORS detected! NOT all tests have been passed successfully\n\n" ;
    }
else
    {
    if ($opt_modperl || $opt_cgi || $opt_offline || $opt_execute || $opt_cache || $opt_ep1)
        {
        print "\nAll tests have been passed successfully!\n\n" ;
        }
    elsif ($opt_start)
        {
        my $make = $EPWIN32?'nmake':'make' ;
     
        print qq{

-----------------------------------------------------------------------

        Test server has been started. 

 To view the Embperl web site direct your browser to 

    http://localhost:$EPPORT/eg/web/

 View $EPPATH/eg/web/README for more details about localy 
 setting up the Embperl website.

 To see some example of Embperl::Form use 
 
    http://localhost:$EPPORT/eg/forms/wizard/action.epl

 More information can be found at $EPPATH/eg/forms/README.txt

 To stop the test server again run

    $make stop

-----------------------------------------------------------------------

} ;
        }
    elsif ($opt_kill)
        {
        my $make = $EPWIN32?'nmake':'make' ;
     
        print qq{

-----------------------------------------------------------------------

        Test server will be stopped now. 

-----------------------------------------------------------------------

} ;
        }

    }

    {
    local $^W = 0 ;
    if (defined ($line = <ERR>) && !defined ($opt_ab))
	    {
	    print "\nFound unexpected output in httpd errorlog:\n" ;
	    print $line ;
	    while (defined ($line = <ERR>))
		    { print $line ; }
	    }
    close ERR ;
    } ;
    		
$fatal = 0 ;


if ($EPWIN32)
    {
    if (!$opt_nokill) 
        {
        if ($HttpdObj)
            {    
            $HttpdObj->Kill(-1) ;
            unlink "$tmppath/httpd.pid" ;
            }
        elsif (-f "$EPPATH/$httpdstopconf" && -f "$tmppath/httpd.pid")
            {
            system ("\"$EPHTTPD\" -k stop -f $EPPATH/$httpdstopconf ") ;
            }
        }
    }
else
    {
    system "kill `cat $tmppath/httpd.pid`  2> /dev/null" if ($EPHTTPD ne '' && !$opt_nokill) ;
    #system ("ps xau|grep http ; cat $tmppath/httpd.pid") ;
    }

exit ($err) ;


############################################################################################################

sub find_error

    {
    my $max = @tests - 1;
    my $min = 0 ;
    my $n   = $max ;

    my $ret ;
    my $cmd ;
    my $opt = " -h "if (!$opt_modperl && !$opt_cgi && !$opt_offline && !$opt_execute) ;

    while ($min + 1 < $max)
        {
        $cmd = "perl test.pl --testlib @ARGVSAVE $opt -l10 -v --exitonsv -- -$n" ;
        print "---> min = $min  max = $max\n$cmd\n" ;
        $ret = system ($cmd) ;
        last if ($ret == 0 && $n == $max) ;
        $min = $n if ($ret == 0) ;
        $max = $n if ($ret != 0) ;

        $n = $min + int (($max - $min) / 2) ;
        }

    if ($max < @tests) 
        {
        print "############## -> error at #$max $tests[$max]\n" ;
        $cmd = "perl test.pl --testlib @ARGVSAVE $opt -l10 -v --exitonsv -- $max" ;
        print "---> min = $min  max = $max\n$cmd\n" ;
        $ret = system ($cmd) ;
        print "############## -> error at #$max $tests[$max]\n" ;
        } 

    return ($max == @tests)?0:1 ;
    }

