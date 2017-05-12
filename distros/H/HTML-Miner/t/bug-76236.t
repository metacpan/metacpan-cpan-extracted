#!perl 

use strict                 ;
use warnings               ;
use HTML::Miner            ;

use Test::More             ;


######################################################################################################################
#  NOTE:                                                                                                             #
#   This test uses an amazon.com link and HTML from a page on that site. This is used for tests and checks only.     #
#      Use of this does not in anyway encorage the access of amazon.com or any other site.                           #
#                                                                                                                    #
######################################################################################################################


my @page_html  = <DATA>                   ;
my $page_html  = join( '\n', @page_html ) ;

plan tests => 2 ;

test_OO( $page_html ) ;
test_FU( $page_html ) ;

done_testing()  ;

exit() ;


sub test_OO { 

    my $page_html  = shift ;

    my $html_miner = HTML::Miner->new ( 
	CURRENT_URL      => "http://www.amazon.co.uk/Kindle -Touch-Wi-Fi-Screen-Display/dp /B005890FUI/ref=amb_link_16348 9267_3?pf_rd_m=A3P5ROKL5A1OLE& pf_rd_s=center-1" , 
	CURRENT_URL_HTML => $page_html ,
	);

    my @links = @{ $html_miner->HTML::Miner::get_links() };

    run_subtests( \@links, 'OO Tests' ) ;

}



sub test_FU { 

    my $page_html   = shift ;

    my $current_url = "http://www.amazon.co.uk/Kindle -Touch-Wi-Fi-Screen-Display/dp /B005890FUI/ref=amb_link_16348 9267_3?pf_rd_m=A3P5ROKL5A1OLE& pf_rd_s=center-1" ;

    my @links = @{ HTML::Miner::get_links( $current_url, $page_html ) };

    run_subtests( \@links, 'Functional Tests' ) ;

}




sub run_subtests { 

    my $links = shift ;
    my $type  = shift ;

    my @links = @{ $links } ;

    subtest $type => sub {
	
	subtest 'HTTPS 1' => sub {

	    ok( $links[37]->{   ABS_EXISTS      } eq  1                                                                   ) ;
	    ok( $links[37]->{   ABS_URL         } eq  "https://s3.amazonaws.com/KindleTouch/Kindle_Touch_User_Guide.pdf", ) ;
	    ok( $links[37]->{   ANCHOR          } eq  "Kindle User's Guide"                                               ) ;
	    ok( $links[37]->{   DOMAIN          } eq  "s3.amazonaws.com"                                                  ) ;
	    ok( $links[37]->{   DOMAIN_IS_BASE  } eq  0                                                                   ) ;
	    ok( $links[37]->{   PROTOCOL        } eq  "https"                                                             ) ;
	    ok( $links[37]->{   TITLE           } eq  ""                                                                  ) ;
	    ok( $links[37]->{   URI             } eq  "/KindleTouch/Kindle_Touch_User_Guide.pdf"                          ) ;
	    ok( $links[37]->{   URL             } eq  "https://s3.amazonaws.com/KindleTouch/Kindle_Touch_User_Guide.pdf"  ) ;
	    
	    done_testing() ;
	    
	} ;
	
	
	subtest 'HTTPS 2' => sub {
	    
	    ok( $links[42]->{   ABS_EXISTS      } eq  1                                                                        ) ;
	    ok( $links[42]->{   ABS_URL         } eq  "https://s3.amazonaws.com/KindleTouch/Kindle_Touch_QuickStart_Guide.pdf" ) ;
	    ok( $links[42]->{   ANCHOR          } eq  "Quick Start Guide"                                                      ) ;
	    ok( $links[42]->{   DOMAIN          } eq  "s3.amazonaws.com"                                                       ) ;
	    ok( $links[42]->{   DOMAIN_IS_BASE  } eq  0                                                                        ) ;
	    ok( $links[42]->{   PROTOCOL        } eq  "https"                                                                  ) ;
	    ok( $links[42]->{   TITLE           } eq  ""                                                                       ) ;
	    ok( $links[42]->{   URI             } eq  "/KindleTouch/Kindle_Touch_QuickStart_Guide.pdf"                         ) ;
	    ok( $links[42]->{   URL             } eq  "https://s3.amazonaws.com/KindleTouch/Kindle_Touch_QuickStart_Guide.pdf" ) ;
	    
	    done_testing() ;
	    
	} ;
	
	subtest 'HTTPS 3' => sub {
	    
	    ok( $links[335]->{   ABS_EXISTS      } eq  1                                                                  ) ;
	    ok( $links[335]->{   ABS_URL         } eq  "https://www.amazon.co.uk/gp/css/order-history/ref=gno_yam_yrdrs/" ) ;
	    ok( $links[335]->{   ANCHOR          } eq  "Your Orders"                                                      ) ;
	    ok( $links[335]->{   DOMAIN          } eq  "www.amazon.co.uk"                                                 ) ;
	    ok( $links[335]->{   DOMAIN_IS_BASE  } eq  1                                                                  ) ;
	    ok( $links[335]->{   PROTOCOL        } eq  "https"                                                            ) ;
	    ok( $links[335]->{   TITLE           } eq  ""                                                                 ) ;
	    ok( $links[335]->{   URI             } eq  "/gp/css/order-history/ref=gno_yam_yrdrs/"                         ) ;
	    ok( $links[335]->{   URL             } eq  "https://www.amazon.co.uk/gp/css/order-history/ref=gno_yam_yrdrs"  ) ;
	    
	    done_testing() ;
	    
	} ;
	
	done_testing() ;
	
    } ;

}




__DATA__

<!-- saved from url=(0136)http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1 -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"><script async="" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/site-wide-11366246298._V1_.js"></script>
<script type="text/javascript">var ue_t0=ue_t0||+new Date();</script>
<script type="text/javascript">
var ue_csm = window;
ue_csm.ue_hob=ue_csm.ue_hob||+new Date();(function(a){a.ue_err={ec:0,pec:0,ts:0,erl:[],mxe:50,startTimer:function(){a.ue_err.ts++;setInterval(function(){a.ue&&(a.ue_err.pec<a.ue_err.ec)&&a.uex("at");a.ue_err.pec=a.ue_err.ec},10000)}};a.ueLogError=(function(){function b(c,e,d){if(a.ue_err.ec>a.ue_err.mxe){return}a.ue_err.ec++;a.ue.log({m:c,f:e,l:d,s:""},"jserr");return false}window.onerror=b;return function(c){if(a.ue_err.ec>a.ue_err.mxe){return}a.ue_err.ec++;a.ue_err.erl.push(c)}})()})(ue_csm);ue_csm.ue_hoe=+new Date();

var ue_id='0KGHD1WV7T4KNAQMVBGQ',
ue_sid='277-6643056-3126939',
ue_mid='A1F83G8C2ARO7P',
ue_sn='www.amazon.co.uk',
ue_url='/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3/uedata/unsticky/277-6643056-3126939/NoPageType/ntpoffrw',
ue_furl='fls-eu.amazon.co.uk',
ue_pr=0,
ue_navtiming=1,
ue_tofc=1,
ue_log_idx=0,
ue_tsinc=0,
ue_fcsn=0,
ue_pageviz=0;
if (!window.ue_csm) {var ue_csm = window;}
ue_csm.ue_hob=ue_csm.ue_hob||+new Date();(function(f,a){f.ueinit=(f.ueinit||0)+1;f.ue={t0:a.aPageStart||f.ue_t0,id:f.ue_id,url:f.ue_url,a:"",b:"",h:{},r:{ld:0,oe:0,ul:0},s:1,t:{},sc:{},iel:[],ielf:[],fc_idx:{},viz:[],v:26};f.ue.tagC=function(){var h=[];return function(i){if(i){h.push(i)}return h.slice(0)}};f.ue.tag=f.ue.tagC();f.ue.ifr=((a.top!==a.self)||(a.frameElement))?1:0;function c(j,m,o,l){var n=l||(new Date()).getTime();var h=!m&&typeof o!="undefined";if(h){return}if(j){var k=m?e("t",m)||e("t",m,{}):f.ue.t;k[j]=n;for(var i in o){e(i,m,o[i])}}return n}function e(i,j,k){var l,h;if(i){l=h=f.ue;if(j&&j!=l.id){h=l.sc[j];if(!h){h={};k?(l.sc[j]=h):h}}l=k?(h[i]=k):h[i]}return l}function d(l,m,k,i,h){var j="on"+k;var n=m[j];if(typeof(n)=="function"){if(l){f.ue.h[l]=n}}else{n=function(){}}m[j]=h?function(o){i(o);n(o)}:function(o){n(o);i(o)};m[j].isUeh=1}function g(o,k,n){function j(L,J){var H=[L],C=0,I={};if(J){H.push("m=1");I[J]=1}else{I=f.ue.sc}var A;for(var B in I){var D=e("wb",B),G=e("t",B)||{},F=e("t0",B)||f.ue.t0;if(J||D==2){var K=D?C++:"";H.push("sc"+K+"="+B);for(var E in G){if(E.length<=3&&G[E]){H.push(E+K+"="+(G[E]-F))}}H.push("t"+K+"="+G[o]);if(e("ctb",B)||e("wb",B)){A=1}}}if(!l&&A){H.push("ctb=1")}return H.join("&")}function r(C,B,E,A){if(C==""){return}var D=new Image();if(f.ue.b){D.onload=function(){if(f.ue.b==""){return}var G=f.ue.b;f.ue.b="";r(G,B,E,1)}}var F=!f.ue_tofc||(f.ue_tofc==1&&!A)||!f.ue.log||!window.amznJQ||(!A&&!E);if(F){f.ue.iel.push(D);D.src=C}if(f.ue_tofc&&f.ue.log&&(E||A)){f.ue.log(C,"uedata",{n:1});f.ue.ielf.push(C)}if(f.ue_err&&!f.ue_err.ts){f.ue_err.startTimer()}}function x(A){if(!ue.collected){var C=A.timing;if(C){f.ue.t.na_=C.navigationStart;f.ue.t.ul_=C.unloadEventStart;f.ue.t._ul=C.unloadEventEnd;f.ue.t.rd_=C.redirectStart;f.ue.t._rd=C.redirectEnd;f.ue.t.fe_=C.fetchStart;f.ue.t.lk_=C.domainLookupStart;f.ue.t._lk=C.domainLookupEnd;f.ue.t.co_=C.connectStart;f.ue.t._co=C.connectEnd;f.ue.t.sc_=C.secureConnectionStart;f.ue.t.rq_=C.requestStart;f.ue.t.rs_=C.responseStart;f.ue.t._rs=C.responseEnd;f.ue.t.dl_=C.domLoading;f.ue.t.di_=C.domInteractive;f.ue.t.de_=C.domContentLoadedEventStart;f.ue.t._de=C.domContentLoadedEventEnd;f.ue.t._dc=C.domComplete;f.ue.t.ld_=C.loadEventStart;f.ue.t._ld=C.loadEventEnd}var B=A.navigation;if(B){f.ue.t.ty=B.type+f.ue.t0;f.ue.t.rc=B.redirectCount+f.ue.t0;if(f.ue.tag){f.ue.tag(B.redirectCount?"redirect":"nonredirect")}}f.ue.collected=1}}var z=!k&&typeof n!="undefined";if(z){return}for(var h in n){e(h,k,n[h])}c("pc",k,n);var t=e("id",k)||f.ue.id;var m=f.ue.url+"?"+o+"&v="+f.ue.v+"&id="+t;var l=e("ctb",k)||e("wb",k);if(l){m+="&ctb="+l}if(f.ueinit>1){m+="&ic="+f.ueinit}var w=a.performance||a.webkitPerformance;var u=f.ue.bfini;if(u&&u>1){m+="&bft="+(u-1)}else{if(w&&w.navigation&&w.navigation.type==2){m+="&bft=1"}}if(f.ue._fi&&o=="at"&&(!k||k==t)){m+=f.ue._fi()}var i;if((o=="ld"||o=="ul")&&(!k||k==t)){if(o=="ld"){if(a.onbeforeunload&&a.onbeforeunload.isUeh){a.onbeforeunload=null}if(document.ue_backdetect&&document.ue_backdetect.ue_back){document.ue_backdetect.ue_back.value++}if(f._uess){i=f._uess()}if(f.ue_navtiming&&w&&w.timing){e("ctb",t,"1");if(f.ue_navtiming==1){f.ue.t.tc=w.timing.navigationStart}}}if(w){x(w)}if(f.ue_hob&&f.ue_hoe){f.ue.t.hob=f.ue_hob;f.ue.t.hoe=f.ue_hoe}if(f.ue.ifr){m+="&ifr=1"}}c(o,k,n);var s=(o=="ld"&&k&&e("wb",k));if(s){e("wb",k,2)}var v=1;for(var q in f.ue.sc){if(e("wb",q)==1){v=0;break}}if(s){if(f.ue.s!=0||!v){return}m=j(m,null)}else{if(v){var y=j(m,null);if(y!=m){f.ue.b=y}}if(i){m+=i}m=j(m,k||f.ue.id)}if(f.ue.b||s){for(var q in f.ue.sc){if(e("wb",q)==2){delete f.ue.sc[q]}}}var p=0;if(!s){f.ue.s=0;if(f.ue_err&&f.ue_err.ec>0){m+="&ec="+f.ue_err.ec}p=e("ctb",k);e("t",k,{})}if(f.ue_tofc&&f.ue.tag&&p){f.ue.tag("ue_tofc")}if(!window.amznJQ&&f.ue.tag){f.ue.tag("noAmznJQ")}if(m&&f.ue.tag&&f.ue.tag().length>0){m+="&csmtags="+f.ue.tag().join("|");f.ue.tag=f.ue.tagC()}if(m&&f.ue_pageviz&&f.ue.viz.length>0){m+="&viz="+f.ue.viz.join("|");f.ue.viz=[]}f.ue.a=m;r(m,o,p,s)}function b(){var j=f.ue.r;function i(l){return function(){if(!j[l]){j[l]=1;g(l)}}}f.onLd=i("ld");f.onLdEnd=i("ld");var h={beforeunload:i("ul"),stop:function(){g("os")}};for(var k in h){d(0,window,k,h[k])}if(f.ue_pageviz){ue_viz&&ue_viz()}if(a.addEventListener){a.addEventListener("load",f.onLd,false)}else{if(a.attachEvent){a.attachEvent("onload",f.onLd)}}f.ue._uep=function(){new Image().src=(f.ue_md?f.ue_md:"http://uedata.amazon.com/uedata/?tp=")+(+new Date)};if(f.ue_pr&&(f.ue_pr==2||f.ue_pr==4)){f.ue._uep()}if(f.queue){f.queue.replay=function(){while((nextArr=f.queue.remove("ue"))){nextArr[0].apply(this,nextArr.slice(1))}};f.queue.replay()}c("ue")}ue.reset=function(i,h){if(!i){return}f.ue_cel&&f.ue_cel.reset();f.ue.t0=+new Date();f.ue.rid=i;f.ue.id=i;f.ue.fc_idx={};f.ue.viz=[]};f.uei=b;f.ueh=d;f.ues=e;f.uet=c;f.uex=g;b()})(ue_csm,window);ue_csm.ue_hoe=+new Date();


ue_csm.ue_hob=ue_csm.ue_hob||+new Date();(function(b){var a=b.ue;a.rid=b.ue_id;a.sid=b.ue_sid;a.mid=b.ue_mid;a.furl=b.ue_furl;a.sn=b.ue_sn;a.lr=[];a.log=function(e,d,c){if(a.lr.length==500){return}a.lr.push(["l",e,d,c,a.d(),a.rid])};a.d=function(c){return +new Date-(c?0:a.t0)}})(ue_csm);ue_csm.ue_hoe=+new Date();
</script>


    
    
    
     





 

 
 


    
    
    
    
    






<script type="text/javascript">(function(){var i=new Image;i.src = "http://ecx.images-amazon.com/images/I/41JpsttW8CL._SL500_AA280_.jpg";})();</script>



    









<style type="text/css"><!--

* html body { margin-top: 0px; }
.serif { font-family: times,serif; font-size: medium; } 
.sans { font-family: verdana,arial,helvetica,sans-serif; font-size: medium; }

.small { font-family: verdana,arial,helvetica,sans-serif; font-size: small; }

h2.small {margin-bottom: 0em; }
h2.h1 { margin-bottom: 0em; }
h2.h3color { margin-bottom: 0em; }
.listprice { font-family: arial,verdana,helvetica,sans-serif; text-decoration: line-through; } 
.attention { background-color: #FFFFD5; } 
.price { font-family: verdana,arial,helvetica,sans-serif; color: #990000; } 
.alertgreen { color: #009900; font-weight: bold; } 
.active-nav { background-color: #000000; color: #FFFFFF; } 
.inactive-nav { background-color: #FFFFFF; color: #000000; } 
.tigerBox .head { border: 1px solid #CCCC99; border-bottom-width: 0px; background-color: #EEEECC; } 
.tigerBox .body { border: 1px solid #CCCC99; } 
.tigerBoxWithEyebrow .head { border-width: 0px; } 
.tigerBoxWithEyebrow .body { border: 1px solid #CCCC99; } 
.detailPageTigerBox .head { border-width: 0px; } 
.detailPageTigerBox .body { border: 1px solid #CCCC99; } 
.detailPageTigerBox .darkCell { background-color: #EEEECC; } 
.eyebrow { font-family: verdana,arial,helvetica,sans-serif; font-size: 10px; font-weight: bold; text-transform: uppercase; text-decoration: none; color: #FFFFFF; } 
div#page-wrap { min-width: 980px; }
div#leftcol, div#leftcolhidden { float: left; width: 180px; margin:5px 0px 0px 5px; display: inline; }

div#rightcol, div#rightcolhidden { float: right; width: 300px; margin-top:5px;}

div#leftcolhidden { clear:left;}
div#rightcolhidden { clear:right;}div#center1, div#centercol, div#centerrightspancol { overflow: hidden; }
* html div#center1 { width: 100%; }
* html div#centercol { width:100%; }
* html div#centerrightspancol { width: 100%; }
div#page-footer { clear: both; }
* html div#page-wrap { border-right: 980px solid #fff; width: 100%; margin-right: 25px;}
* html div#content { float: left; position:relative; margin-right: -980px; }
a:active { font-family: verdana,arial,helvetica,sans-serif; color: #FF9933; } 
a:visited { font-family: verdana,arial,helvetica,sans-serif; color: #996633; } 
a:link { font-family: verdana,arial,helvetica,sans-serif; color: #004B91; } 
a.noclick, a.noclick:visited { color: #000000; }
.noLinkDecoration a { text-decoration: none; border-bottom: none; }
.noLinkDecoration a:hover { text-decoration: underline; }
.noLinkDecoration a.dynamic:hover { text-decoration: none; border-bottom: 1px dashed; }
.noLinkDecoration a.noclick:hover { color: #000000; text-decoration: none; border-bottom: 1px dashed; }

.amabot_right .h1 { color: #E47911; font-size: .92em; } 
.amabot_right .amabot_widget .headline, .amabot_left .amabot_widget .headline { color: #E47911; font-size: .92em; display: block; font-weight: bold; } 
.amabot_widget .headline { color: #E47911; font-size: medium; display: block; font-weight: bold; } 
.amabot_right .amabot_widget { padding-top: 8px;  padding-bottom: 8px; padding-left: 8px;  padding-right: 8px; border-bottom: 1px solid #C9E1F4; border-left: 1px solid #C9E1F4; border-right: 1px solid #C9E1F4; border-top: 1px solid #C9E1F4; } 
.amabot_left .h1 { color: #E47911; font-size: .92em; } 
.amabot_left .amabot_widget { padding-top: 8px;  padding-bottom: 8px;  padding-left: 8px;  padding-right: 8px; border-bottom: 1px solid #C9E1F4; border-left: 1px solid #C9E1F4; border-right: 1px solid #C9E1F4;  border-top: 1px solid #C9E1F4; }
 
.amabot_center div.unified_widget, .amabot_center .amabot_widget { font-size: 12px; }
.amabot_right div.unified_widget, .amabot_right .amabot_widget { font-size: 12px; }
.amabot_left div.unified_widget, .amabot_left .amabot_widget { font-size: 12px; }

.nobullet { list-style-type: none; } 
.homepageTitle { font-size: 28pt; font-family: 'Arial Bold', Arial, sans-serif; font-weight: 800; font-variant: normal; color: #80B6CE; line-height:1em; } 
.tigerbox { padding-top: 8px;  padding-bottom: 8px;  padding-left: 8px;  padding-right: 8px;  border-bottom: 1px solid #C9E1F4; border-left: 1px solid #C9E1F4;  border-right: 1px solid #C9E1F4;  border-top: 1px solid #C9E1F4; } 
.hr-leftbrowse { border-top-width: 1px;	border-right-width: 1px;	border-bottom-width: 1px; border-left-width: 1px; border-top-style: dashed; border-right-style: none; border-bottom-style: none; border-left-style: none; border-top-color: #999999; border-right-color: #999999; border-bottom-color: #999999; border-left-color: #999999; margin-top: 10px; margin-right: 5px; margin-bottom: 0px; margin-left: 5px; } 
div.unified_widget p { margin:0 0 0.5em 0; line-height:1.4em; }

div.unified_widget h2 { color:#E47911; padding:0; }

.amabot_right div.unified_widget .headline, .amabot_left div.unified_widget .headline { color: #E47911; font-size: .92em; display: block; font-weight: bold; }
div.unified_widget .headline { color: #E47911; font-size: medium; display: block; font-weight: bold;}
div.unified_widget sup { font-weight:normal; font-size: 75%; } 
div.unified_widget h2 sup { font-size: 50%; }

td.amabot_left div.unified_widget h2, td.amabot_right div.unified_widget h2, div.amabot_left div.unified_widget h2, div.amabot_right div.unified_widget h2 { font-size:100%; margin:0 0 0.5em 0; } 
td.amabot_center div.unified_widget h2, div.amabot_Center div.unified_widget h2 { font-size:135%; font-weight:bold; margin:0 0 0.35em 0px; } 
td.amabot_center, div.amabot_center { padding:5px 15px 5px 10px; }
div.unified_widget ul { margin: 1em 0; padding: 0 0 0 15px; list-style-position:inside; }

div.unified_widget ol { margin:0; padding:0 0 0 2.5em; }

div.unified_widget a:link, div.unified_widget a:visited { text-decoration:underline; }
div.unified_widget a:hover { text-decoration:underline; }
div.unified_widget p.seeMore { clear:both; font-family:verdana,arial,helvetica,sans-serif; margin:0; padding-left:1.15em; text-indent: -1.15em; font-size:100%; font-weight:normal; } 
div.unified_widget p.seeMore a:link, div.unified_widget p.seeMore a:visited { text-decoration:underline; } 
div.unified_widget p.seeMore a:hover { text-decoration: underline; } 
div.unified_widget .carat, div.left_nav .carat { font-weight:bold; font-size:120%; font-family:verdana,arial,helvetica,sans-serif; color:#E47911; margin-right:0.20em; } 
div.unified_widget a img { border:0; }
 
div.h_rule { clear:both; } 
div#centerrightspancol div.h_rule { clear:right; }
div.unified_widget { margin-bottom:2em; clear:both; } 
div.unified_widget div.col1 { width: 100%; } 
div.unified_widget div.col2 { width: 49%; } 
div.unified_widget div.col3 { width: 32%; } 
div.unified_widget div.col4 { width: 24%; } 
div.unified_widget div.col5 { width: 19%; } 
div.unified_widget table { border:0; border-collapse:collapse; width:100%; } 
div.unified_widget td { padding:0 8px 8px 0; vertical-align:top; } 
div.unified_widget table.col1 td { width:100%; } 
div.unified_widget table.col2 td { width:49%; } 
div.unified_widget table.col3 td { width:32%; } 
div.unified_widget table.col4 td { width:24%; } 
div.unified_widget table.col5 td { width:19%; } 
div.unified_widget td.bottom { vertical-align:baseline; } 
div.unified_widget table h4, div.unified_widget h4 { color:#000; font-size:100%; font-weight:normal; margin:0; padding:0; } 
div.rcmBody div.prodImage, amabot_widget div.prodImage {float:left; margin:0px 0.5em 0.25em 0px;}

td.amabot_right div.unified_widget, td.amabot_left div.unified_widget, div.amabot_right div.unified_widget, div.amabot_left div.unified_widget { border:1px solid #C9E1F4; padding:8px; margin-bottom:20px; }

* html td.amabot_right div.unified_widget, * html div.amabot_right div.unified_widget { height:100%; }
* html td.amabot_left div.unified_widget, * html div.amabot_left div.unified_widget { height:100%; }

div.rcmBody, amabot_widget div.rcmBody { line-height:1.4em; }
div.rcmBody a:link, div.rcmBody a:visited { text-decoration: underline; }

div.rcmBody p.seeMore, amabot_widget div.rcmBody p.seeMore { margin-top:0.5em; }
div.rcmBody div.bannerImage { text-align:center; }
div.rcmBody h2 span.homepageTitle { display:block; margin-bottom:-0.3em; margin-top:-0.12em; line-height:1em; }
div.rcmBody h2 img { float:none; }
table.coopTable div.rcmBody .headline { font-size: 110%; }
table.coopTable div.rcmBody h2 { font-size: 110%; font-weight:bold; }
table.promo div.rcmBody h2 { font-size: 100%; font-weight:bold; }
div.blurb div.title { font-weight:bold; padding-top:5px; padding-bottom:2px; }

div.left_nav { font-family: Arial, sans-serif; font-size:100%; margin:0; line-height:1.05em; width:100%; border:1px solid #C9E1F4; padding-bottom:10px; } 
div.left_nav h2 { margin:0 0 0 0; color:#000000; font-weight:bold; line-height:1.25em; font-size:100%; font-family:verdana,arial,helvetica,sans-serif; padding: 3px 6px; background-color:#EAF3FE; } 
div.left_nav h3 { font-family:verdana,arial,helvetica,sans-serif; margin:0.5em 0 0.4em 0.5em; color:#E47911; font-weight:bold; line-height:1em; font-size:100%; padding-right:0.5em; } 
div.left_nav ul { margin:0; padding:0; } 
div.left_nav li, div.left_nav p { list-style:none; margin:0.5em 0.5em 0 1em; line-height:1.2em;}
 
div.left_nav hr { margin:1em 0.5em; border-top:0; border-left:0; border-right:0; border-bottom:1px dashed #cccccc; }

div.left_nav a:link, div.left_nav a:visited { color:#003399; text-decoration:none; font-family:Arial, sans-serif; } 
div.left_nav a:hover { color:#2a70fc; text-decoration:underline; } 
div.left_nav p.seeMore { padding-left:0.9em; text-indent:-0.9em; margin-top:0.35em; margin-bottom:1em; }
 
div.left_nav p.seeMore a:link, div.left_nav p.seeMore a:visited { text-decoration:none; } 
div.left_nav p.seeMore a:hover { text-decoration:underline; } 
div.asinItem { float:left; margin-bottom:1em; width:32%; } 
div.asinTextBlock { padding:0 8px 8px 0; } 
div.asinItem div.prodImage { height:121px; display:table-cell; vertical-align:bottom; } 
div.asinItem div.localImage { display:table-cell; vertical-align:bottom; }

div.asinItem span { margin: 0.5em 0 0.25em 0; } 
div.asinItem ul { margin:0; padding:0 0 0.5em 1.3em; text-indent:-1.3em; font-size:90%; }
 
div.asinTitle {padding-top:3px; padding-bottom:2px;}
div.row { clear:both; }
body.dp {}
body.dp div.h_rule { clear:none; }
body.dp div.unified_widget { clear:none; } 
div.asinCoop div.asinItem { float:none; width:100%;}
div.asinCoop_header {}
div.asinCoop_footer {}

div.newAndFuture div.asinItem ul { font-size:100%; }
div.newAndFuture div.asinItem li { list-style-position: outside; margin:0 0 0.35em 20px; padding:0; text-indent: 0; }
div.newAndFuture h3 { font-size:100%; margin:1em 0 ; }
div.newAndFuture a:link, div.newAndFuture a:visited { text-decoration:underline; }
div.newAndFuture a:hover { text-decoration:underline; }
div.newAndFuture p.seeMore { margin:-0.75em 0 0 35px; }

div.unified_widget ol.topList { margin: 0; padding: 0; list-style: none; }
div.unified_widget ol.topList li { list-style: none; clear: both; display: list-item; padding-top: 6px; }
div.unified_widget ol.topList .productImage { display: block; float: left;vertical-align: top;text-align: center;width:60px; }
div.unified_widget ol.topList .productText { display: block; float: left; padding-left:10px; vertical-align: top; }
:root div.unified_widget span.productImage { display: table-cell; float: none; }
:root div.unified_widget span.productText { display: table-cell; float: none; }
div.unified_widget dl.priceBlock {margin:0 0 0.45em 0;}
div.unified_widget dl.priceBlock dt {clear:left; font-weight:bold; float:left; margin:0 0.3em 0 0;}
div.unified_widget dl.priceBlock dd {margin:0 0 0.2em 0;}
div.unified_widget .bold {font-weight:bold;}
div.unified_widget .byline {font-size: 95%; font-weight: normal;}
table.thirdLvlNavContent div.blurb {margin:10px;}

div.pageBanner h1 { font-family:Arial, Helvetica, sans-serif; font-weight:normal; font-size:225%; color: #e47911; letter-spacing:-0.03em; margin:0; }
div.pageBanner p { font-size:90%; color:#888888; margin: 0; }

div.pageBanner h1.bkgnd { background-repeat:no-repeat; background-color:#FFFFFF; overflow:hidden; text-indent:-100em; }
INPUT { font-family: fixed; }

    BODY { background-color: #FFFFFF; font-family: verdana,arial,helvetica,sans-serif; font-size: small; }
    TD { font-family: verdana,arial,helvetica,sans-serif; font-size: small; }
    TH { font-family: verdana,arial,helvetica,sans-serif; font-size: small; }
    .h1 { font-family: verdana,arial,helvetica,sans-serif; color: #E47911; font-size: medium; }
    .h3color { font-family: verdana,arial,helvetica,sans-serif; color: #E47911; font-size: small; } 
    .tiny { font-family: verdana,arial,helvetica,sans-serif; font-size: x-small; } 
    .tinyprice { font-family: verdana,arial,helvetica,sans-serif; color: #990000; font-size: x-small; } 
    .highlight { font-family: verdana,arial,helvetica,sans-serif; color: #990000; font-size: small; } 
  --></style>





<!--[if IE]>

<script language="Javascript1.1" type="text/javascript">
    
  function dpCSSSetMinWidth() {
	var elem = document.getElementById("divsinglecolumnminwidth");
	if (elem) {
                dpCSSSetElemWidth(elem);
	}
  }
  
  function dpCSSSetElemWidth(elem) {
      if (elem) {
         var clientWidth = document.documentElement.clientWidth ? document.documentElement.clientWidth : document.body.clientWidth;
         elem.runtimeStyle.width = (clientWidth < 920 ? '920px' : '100%' );
      }
  }
  
  if ( -1 != navigator.userAgent.indexOf("MSIE") ) {
      window.onresize = dpCSSSetMinWidth;
  }
</script>

<![endif]-->





<script language="Javascript1.1" type="text/javascript">
<!--
function amz_js_PopWin(url,name,options){
  var ContextWindow = window.open(url,name,options);
  ContextWindow.focus();
  return false;
}
//-->
</script>



<script type="text/javascript">

// =============================================================================
// Function Class: Show/Hide product promotions & special offers link
// =============================================================================

function showElement(id) {
  var elm = document.getElementById(id);
  if (elm) {
    elm.style.visibility = 'visible';
    if (elm.getAttribute('name') == 'heroQuickPromoDiv') {
      elm.style.display = 'block';
    }
  }
}
function hideElement(id) {
  var elm = document.getElementById(id);
  if (elm) {
    elm.style.visibility = 'hidden';
    if (elm.getAttribute('name') == 'heroQuickPromoDiv') {
      elm.style.display = 'none';
    }
  }
}
function showHideElement(h_id, div_id) {
  var hiddenTag = document.getElementById(h_id);
  if (hiddenTag) {
    showElement(div_id);
  } else {
    hideElement(div_id);
  }
}

	window.isBowserFeatureCleanup = 0;
	
var touchDeviceDetected = false;
var CSMReqs={af:2,cf:2}
function setCSMReq(m){
      m=m.toLowerCase();
  	  if(--CSMReqs[m]<=0){
	    if(typeof uet == 'function'){uet(m);}
	  }
}
</script>


<script type="text/javascript">
var gbEnableTwisterJS  = 0;
var isTwisterPage = 0;
</script>




    
        
        

















<link rel="canonical" href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI">
<meta name="description" content="The new Kindle Touch e-reader for only has a new, easy-to-use touchscreen, the most advanced E Ink display and built-in Wi-Fi.  
">
<meta name="title" content="Kindle Touch: Touchscreen e-Reader with Wi-Fi, 6&quot; E Ink Display">

<meta name="keywords" content="Kindle Touch, Wi-Fi, 6&quot; E Ink Touch Screen Display,Amazon,D01200">
<title>Kindle Touch: Touchscreen e-Reader with Wi-Fi, 6" E Ink Display</title>









 



  
    












 
 


    









 





























    
















  









    





    




  




<link rel="stylesheet" type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/GB-combined-1155515822._V400694269_.css">








<link rel="stylesheet" type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/GB-combined-1374082263._V386866815_.css">




          <noscript>&lt;link type="text/css" rel="stylesheet" href="http://z-ecx.images-amazon.com/images/G/02/x-locale/communities/profile/customer-popover/style-no-js-3._V234365284_.css" /&gt;</noscript>

<link rel="stylesheet" type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/sd_style-ScheduledDeliveryJavascript-b1.0.3.93-min._V402627364_.css">

 
 
 
 
 
 

 
 
 

 









 	<link rel="stylesheet" type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/detailPageStatic._V391204233_.css">

<style type="text/css">


  



#importantInfoLightingSlotBucketContent hr {display: none;}
  h2 { color: #CC6600; font-size: medium; margin: 0px 0px 0.25em; }

  table.productImageGrid {
    float:left;
    margin: 0px 15px 15px 0px;
    background-color: #FFFFFF;
    text-align : center;
  }
  div.buying table { font-size: small; }

  div.buying table td.tiny { font-size: x-small; }

  #priceBlock, #priceBlock table td, #primaryUsedAndNew, #primaryClubPrice, #secondaryUsedAndNew, #secondaryClubPrice, #adultWarning, #violenceWarning { font-size: small; }
  .custImgLink { text-align : center; }
  #newAmazonShorts table { font-size: small; }

  #specialOffers table { font-size: small; }

  /* Used Buy Box */



  .amabot_endcap .amabot_widget .h1 {color: #000000; font-size: small; }
 
  .smallFontSize { font-size: small; }

  table.offersAndRebates th { font-size: small; font-weight: bold; text-align: right; padding-left: 8px; }

div.replacementTeaser {
  border: 1px solid #136eB4;
  background-color: #ffffdd;
  margin-left: 295px;
  margin-bottom: 5px;
  font-size:0.85em;
  padding: 3px 4px 4px 4px;
}

div.replacementWidget {
  margin-left:295px;
  margin-right:225px;
}




  /* Add to Wish List et al */




    .buyBottomBox { z-index: 1;}
    .cBoxInner .GFTButtonCondo {}

    .buyBoxDiv .subsDPTableCenter {
      padding: 0px 5px 5px;
    }
 
    .buyBoxDiv .subsDPTableTopRow
    {  height: 0px;
      line-height: 0px;
      font-size: 0px; 
    }

    * html .buttonCondoBox {
      z-index: 1;
    }
    
    .bc-disabled {
      cursor: not-allowed;
    }

    .bc-hidden {
      display: none;
    }

    .tinyGrey {
      font-family: verdana,arial,helvetica,sans-serif;
      font-size: xx-small;
      color:#808080;
    }
    .wl-pop-unsprited .wl-pop-body .wl-pop-left { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_left._V232086925_.png); }
    .wl-pop-unsprited .wl-pop-body .wl-pop-right { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_right._V232086925_.png); }
    .wl-pop-unsprited .wl-pop-header .wl-pop-left { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_topleft._V232086925_.png); }
    .wl-pop-unsprited .wl-pop-header .wl-pop-right { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_topright._V232086925_.png); }
    .wl-pop-unsprited .wl-pop-header .wl-pop-middle { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_top._V232086927_.png); }
    .wl-pop-unsprited .wl-pop-footer .wl-pop-left { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_bottomleft._V232086925_.png); }
    .wl-pop-unsprited .wl-pop-footer .wl-pop-right { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_bottomright._V232086924_.png); }
    .wl-pop-unsprited .wl-pop-footer .wl-pop-middle { background-image: url(http://g-ecx.images-amazon.com/images/G/02/gifts/registries/wishlist/eq/wladd_drop_bottom._V156433860_.png); }

    .wl-pop-sprited .wl-pop-body .wl-pop-left,
    .wl-pop-sprited .wl-pop-body .wl-pop-right {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_buybox_drop_sides._V234864356_.png);
    }

    .wl-pop-sprited .wl-pop-header .wl-pop-left,
    .wl-pop-sprited .wl-pop-header .wl-pop-right,
    .wl-pop-sprited .wl-pop-header .wl-pop-middle,
    .wl-pop-sprited .wl-pop-footer .wl-pop-left,
    .wl-pop-sprited .wl-pop-footer .wl-pop-right,
    .wl-pop-sprited .wl-pop-footer .wl-pop-middle {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_wladd_drop_corners._V156421607_.png);
    }

    .wl-pop-hide {
      display: none;
    }
    
    .wl-pop-body {
      height: 100%;
      position: relative;
    }

    .wl-pop-body .wl-pop-left {
      background-attachment: scroll;
      background-repeat: repeat-y;
      height: 100%;
      left: 0;
      position: absolute;
      top: 0;
      width: 5px;
    }

    .wl-pop-sprited .wl-pop-body .wl-pop-left {
      background-position: 0 top;
    }

    .wl-pop-sprited .wl-pop-body .wl-pop-right {
      background-position: -5px top;
    }

    .wl-pop-body .wl-pop-right {
      background-attachment: scroll;
      background-repeat: repeat-y;
      height: 100%;
      position: absolute;
      right: 0;
      top: 0;
      width: 5px;
    }

    .wl-pop-header, .wl-pop-footer {
      font-size: 0;
      line-height: 0;
      position: relative;
      width: 100%;
      overflow: hidden;
    }

    .wl-pop-footer * {
      height: 8px;
    }

    .wl-pop-header * {
      height: 4px;
    }

    .wl-pop-header .wl-pop-left {
      background-attachment: scroll;
      background-repeat: no-repeat;
      left: 0;
      position: absolute;
      top: 0;
      width: 8px;
    }

    .wl-pop-sprited .wl-pop-header .wl-pop-left { background-position: 0 -10px; }

    .wl-pop-header .wl-pop-right {
      background-attachment: scroll;
      background-repeat: no-repeat;
      position: absolute;
      right: 0;
      top: 0;
      width: 8px;
    }

    .wl-pop-sprited .wl-pop-header .wl-pop-right { background-position: -10px -10px; }

    .wl-pop-header .wl-pop-middle, .wl-pop-footer .wl-pop-middle {
      background-attachment: scroll;
      background-repeat: repeat-x;
      margin-right: 8px;
      margin-left: 8px;
    }

    .wl-pop-sprited .wl-pop-header .wl-pop-middle { background-position: 0 0; }

    .wl-pop-footer .wl-pop-left {
      background-attachment: scroll;
      background-repeat: no-repeat;
      left: 0;
      position: absolute;
      top: 0;
      width: 8px;
    }

    .wl-pop-sprited .wl-pop-footer .wl-pop-left { background-position: 0 -20px; }

    .wl-pop-footer .wl-pop-right {
      background-attachment: scroll;
      background-repeat: no-repeat;
      position: absolute;
      right: 0;
      top: 0;
      width: 8px;
    }

    .wl-pop-sprited .wl-pop-footer .wl-pop-right { background-position: -10px -20px; }

    .wl-pop-sprited .wl-pop-footer .wl-pop-middle { background-position: 0 -30px;}

    .wl-pop-wrapper {
      left: 5px;
      max-height: 191px;
      overflow-x: hidden;
      overflow-y: auto;
      position: relative;
      width: 160px;
    }

    * html .wl-pop-wrapper {
      height: expression( this.scrollHeight > 183 ? "184px" : "auto" );
      max-height: 184px;
    }

    .wl-pop-wrapper form {
      display: inline;
    }

    .wl-pop-wrapper a.wl-list-link, .wl-pop-wrapper a.wl-create-link {
      cursor: pointer;
      display: block;
      outline: none;
      text-decoration: none;
      width: 160px;
    }

    .wl-pop-wrapper a.wl-create-link {
      background-color: #e5e5c1;
    }

    .wl-pop-wrapper a.wl-list-link:hover, .wl-pop-wrapper a.wl-create-link:hover {
      background-color: #ffffff;
      background-image: none;
    }

    .wl-list-button, .wl-list-button-last, .wl-create-button, .wl-create-button-last {
      font-family: "arial";
      height: 23px;
      overflow: hidden;
      line-height: 23px;
      width: 160px;
    }

    .wl-create-button {
      border-color: #9d9d74;
      border-style: solid;
      border-width: 0 0 1px 0;
    }

    .wl-list-button {
      border-color: #9d9d74;
      border-style: solid;
      border-width: 0 0 1px 0;
    }

    .wl-list-button-last {
      border-color: #79784a;
      border-style: solid;
      border-width: 0 0 1px 0;
    }

    .wl-list-inner, .wl-create-inner {
      border-style: solid;
      border-width: 1px 0 0 1px;
    }

    .wl-list-inner {
      border-color: #ffffff;
    }

    .wl-create-inner {
      border-color: #f4f4e1;
    }

    .wl-list-type, .wl-list-type-break {
      color: #9d9d74;
      float: right;
      font-size: 9px;
      margin-right: 2px;
      max-height: 20px;
      overflow: hidden;
      text-align: right;
    }

    .wl-list-type-break {
      line-height: 9px;
      margin-top: 2px;
    }

    .wl-list-name-wrapper {
      height: 23px;
      margin-left: 2px;
      overflow: hidden;
      white-space: nowrap;
      width: 75px;
      display: inline;
    }

    .wl-list-name {
      color: #004b91;
      font-size: 10px;
      margin-left: 3px;
    }

    .wl-list-default {
      color: #004b91;
      font-size: 10px;
    }

    .wl-create-text {
      color: #004b91;
      font-size: 10px;
      margin-left: 3px;
    }

    .s_add2WishListRight, .s_add2WishListLeft {
      -webkit-appearance: none;
      -webkit-border-radius: 0;
    }



 


#obsims .content  { margin-left: 5px; }
#obsims .faceout     { padding: 0; }
#obsims .faceout img, #obsims img.faceout { margin-right: 10px; }
#obsims .asinDetails { padding: 0; font-size:10px; }
#obsims .asinList    { margin-top: 0; }
#obsims .vtp-clear   { height: 5px; line-height: 50%; }
#obsims .simFooter   { margin-left: 0; }

#ob-replacement_feature_div { zoom: 1 !important; }

div.nvff_radio       { margin-bottom: 10px; }
div.nvff_radio label { margin-bottom: 1em; }
div.nvff_highlight   { font-size:0.9em; margin-top:8px; margin-bottom:10px; padding:7px; border:1px solid #DDDAC0; background:#FFFFDD; }
div.nvff_help        { color:#000000; }
div.nvff_error       { color:#990000; }
div.nvffGrey         { margin-top:5px; font-size:.85em; color:#66666B; }
div.nvffGreen        { margin-top:5px; font-size:.85em; color:#090; }
div.nvffRed          { margin-top:5px; font-size:.85em; color:#990000; }
#nvFeedbackForm      { margin-bottom:0px; }
#nvOtherText         { border:1px solid #AED2EE; color:#999999; margin-top: 2px; }


  table.buyBox .eq td.bottomLeft table {
      padding-left: 22px;
      padding-right: 10px;
      padding-top: 4px;
      padding-bottom: 6px;
  }
  table.buyBox .eq td.bottomLeft {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprite/wl_bb_sprite_box._V152890262_.png);
      background-repeat: no-repeat;
      background-position: left bottom;
  }
  table.buyBox .eq td.bottomRight {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprite/wl_bb_sprite_box._V152890262_.png);
      background-repeat: no-repeat;
      background-position: right bottom;
  }
  table.buyBox .eq td.topLeft {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprite/wl_bb_sprite_box._V152890262_.png);
      background-repeat: no-repeat;
      background-position: left top;
  }
  table.buyBox .eq td.topRight {
      background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprite/wl_bb_sprite_box._V152890262_.png);
      background-repeat: no-repeat;
      background-position: right top;
  }
  table.buyBox div.eqspacer {
      padding-top: 8px;
  }
  table.buyBox td.topLeft {
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_box_bb._V156421490_.png);
    background-repeat: no-repeat;
    background-position: top left;
    padding-top: 12px;
    padding-left: 12px;
  }
  table.buyBox td.topRight {
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_box_bb._V156421490_.png);
    background-repeat: no-repeat;
    background-position: top right;
  }
  table.buyBox td.bottomLeft {
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_box_bb._V156421490_.png);
    background-repeat: no-repeat;
    background-position: bottom left;
    font-size: 4px;
  }
  table.buyBox td.bottomRight {
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite_box_bb._V156421490_.png);
    background-repeat: no-repeat;
    background-position: bottom right;
    font-size: 4px;
  }

.bb_exp_co_softlines {
        display:none !important;
}




  .extendedBuybox b.price { font-size: .86em; }
  .extendedBuybox { width: 100%; }
  div.extendedBuyBox { padding: 4px 0px; }  
  hr.EBBdivider { margin: 0px; }

.buyTopBox .cBoxTL, .buyTopBox .cBoxTR, .buyTopBox .cBoxBL, .buyTopBox .cBoxBR,
.buyBottomBox .cBoxTL, .buyBottomBox .cBoxTR, .buyBottomBox .cBoxBL, .buyBottomBox .cBoxBR,
.mbcBox .cBoxTL, .mbcBox .cBoxTR, .mbcBox .cBoxBL, .mbcBox .cBoxBR,
.addonBox .cBoxTL, .addonBox .cBoxTR { 
  background-image:url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite-cbox._V152889588_.png); 
  background-repeat:no-repeat; 
}

.addonBox .cBoxTL { background-position: 0px -180px; }
.addonBox .cBoxTR { background-position: -10px -180px; }

.mbcBox .cBoxTL { background-position: 0px -140px; }
.mbcBox .cBoxTR { background-position: -10px -140px; }
.mbcBox .cBoxBL { background-position: 0px -150px; }
.mbcBox .cBoxBR { background-position: -10px -150px; }
.mbcBox .cBoxR, .mbcBox .cBoxB { background-color: #6daee1; }
.mbcBox {
  border:1px solid #6daee1; 
  border-right: none; 
  border-bottom: none; 
  background-color: #fff;
  margin-bottom: 0;
  z-index: 0;
}
.buyTopBox .cBoxTL { background-position: 0px -20px; }
.buyTopBox .cBoxTR { background-position: -10px -20px; }
.buyTopBox .cBoxBL { background-position: 0px -30px; }
.buyTopBox .cBoxBR { background-position: -10px -30px; }
.buyTopBox .cBoxR, .buyTopBox .cBoxB { background-color: #6daee1; }
.buyTopBox { 
  margin-bottom: 0; 
  border:1px solid #6daee1; 
  border-right: none; 
  border-bottom: none; 
  background-color: #c0dbf2; 
}
.buyBottomBox .cBoxTL { background-position: 0px -120px; }
.buyBottomBox .cBoxTR { background-position: -10px -120px; }
.buyBottomBox .cBoxBL { background-position: 0px -130px; }
.buyBottomBox .cBoxBR { background-position: -10px -130px; }
.buyBottomBox .cBoxR, .buyBottomBox .cBoxB { background-color: #6daee1; }
.buyBottomBox .cBoxInner { padding-top: 4px; padding-bottom: 6px; }
.buyBottomBox { 
  margin-top: 0;
  margin-bottom: 0;
  border:1px solid #6daee1; 
  border-right: none; 
  border-top: none; 
  border-bottom: none; 
  background-color: #ebf3fe;
}
  .s_bbAdd2Cart {
     background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/btn_add-to-cart._V149608925_.png);
   }
div.mbcContainer { font-size:0.86em; }
div.mbcContainer div.mbcTitle, div.emwaTitle {
  background-color:#D6E7F8;
  font-size:11px;
  font-weight:bold;
  padding:4px 0 5px;
  text-align: center;
}
table.mbcOffers, table.mbcOfferRow {
  border:none;
  padding:0px; 
  width:100%;  
}
table.mbcOffers tr.mbcOfferRowSelect td, 
table.mbcOffers tr.mbcPopoverOfferRowSelect td {
  background-color: #FCFCC2;
  cursor: hand;
  cursor: pointer;
}
table.mbcOffers tr td.mbcOfferRowTD { padding:0px 10px; }
table.mbcOfferRow tr td.mbcPriceCell {
  color:#990000;
  border-bottom: 1px dotted #D6D6D6;
  padding-bottom:5px;
}
table.mbcOfferRow tr.mbcMerch td { 
  padding:5px 1px 0px 0px;
}
table.mbcOfferRow tr td {
  font-size:12px;
  font-family:Arial,Helvetica,Geneva,sans-serif;
}
*html div.mbcTradeIn{
  width:215px;
}
div.mbcOlp {
  padding: 5px 10px 0px 10px;
}
div.mbcOlpLink {
  font-size: 11px;
  border-bottom: 1px dotted #D6D6D6;
  padding-bottom: 5px;
}
.mbcPopoverContainer, 
.mbcPopoverContainer a, 
.mbcPopoverContainer a:visited, 
.mbcPopoverContainer a:active {
  font-family:Arial,Verdana,Helvetica,sans-serif;
  font-size:11px;
}
#mbcPPUText .pricePerUnit { white-space: normal; }
.nav-sprite {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png);
}
.nav_pop_h {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-h-v2._V147907311_.png);
}
.nav_pop_v {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-v-v2._V147907310_.png);
}
.nav_ie6 .nav_pop_h {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-8bit-h._V147907309_.png);
}
.nav_ie6 .nav_pop_v {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-8bit-v._V147907308_.png);
}
.nav-ajax-loading .nav-ajax-message {
  background: center center url(http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/snake._V192252891_.gif) no-repeat;
}
.iss-sprite {
  background-image: url(http://g-ecx.images-amazon.com/images/G/02/nav2/images/gui/beacon-sprite.png);
}

    

.vam{
  vertical-align: middle;
}  
    .tafShareText {
      padding: 0 5px;
    }
.tafSocialButton {
  cursor: pointer;
  display: inline-block;
  margin-left: 5px;
  background-image:url(http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/social/snwicons_v2._V402336182_.png);
}
.tafEmailIcon{
  cursor: pointer;
  display: inline-block;
  background-position: 0px 0px; height: 16px; width: 18px;
  background-image:url(http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/social/snwicons_v2._V402336182_.png);
}
.social_chevron {
  background-image:url(http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/social/social_chevron._V390310275_.png);
  display: -moz-inline-box;
  display: inline-block;
  background-position:0px,0px;
  height:11px;
  width:11px;
}


      .prime-xx-small
      {
        font-family: verdana,arial,helvetica,sans-serif;
        font-size: xx-small;
      }
      .membershipEnclosure
      {
        width: 100%;
        min-height: 58px;
        height: auto;
        padding: 0;
      }

      .nonmemberEnclosure {
        padding: 2px 0 5px 0;
        font-size: x-small;
        text-align: center;
        font-family: verdana,arial,helvetica,sans-serif;
      }

  .subsDPTableTop
{  
  background-color: #E5F4FB;
  border-top: 1px solid #5C9EBF;
}
.subsDPTableBottom
{ 
  background-color: #E5F4FB;
  border-bottom: 1px solid #5C9EBF;
}
.subsDPTableLeft
{ 
  background-color: #E5F4FB;
  border-left: 1px solid #5C9EBF;
}
.subsDPTableRight
{ 
  background-color: #E5F4FB;
  border-right: 1px solid #5C9EBF;
}
.subsDPTableCenter
{ 
  background-color:#E5F4FB;
  padding: 5px;
}
.PrimeBBOPtext
{ 
  font-size: 9px;
  color:#000;
  margin:5px 0 0 0;
  padding:0;
}
.PrimePopLine
{ 
  border-bottom: 1px dashed #ccc; 
  margin-top:10px; 
  margin-bottom: 
  10px;
}
ul.primeBuyBox
{
 padding-left: 25px;
 list-style-type:disc;
}



.prime-pBox { position:relative; width:100%; margin-bottom:15px;}
.prime-pBoxInner { font-size:10px; padding:0 9px 6px;}
.prime-pBoxBL, .prime-pBoxBR { position:absolute; width:10px; height:10px; z-index:1; bottom:-1px; background-image:url(http://g-ecx.images-amazon.com/images/G/02/x-locale/common/sprite-all-corners._V192561933_.gif); background-repeat:no-repeat; }
.prime-pBoxBL { left:-1px; background-position:0px -10px; }
.prime-pBoxBR { right:-1px; background-position:-10px -10px; }
.prime-pBoxB { position:absolute; width:100%; height:1px; bottom:-1px; background-color:#C9E1F4; }
.prime-secondary { border:1px solid #C9E1F4; border-top:none; border-bottom:none; }


  div.ensbox { padding: 0.25em 0em; font-size: .86em; }


div.sdBuyBox {
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/kitchen/scheduled-delivery/sd_bkgd_sprite2._V156428020_.png');
}
.sdCorner {
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/kitchen/scheduled-delivery/sd_bkgd_sprite2._V156428020_.png'); 
}

div.fionaPublish {
  background-image: url('http://g-ecx.images-amazon.com/images/G/02/kindle/merch/global/kindle-widget-photo._V388868132_.jpg');
  background-repeat: no-repeat;
  min-height: 8em;
  height: auto  !important;
  height: 8em;
}

div.fionaPublish div {
  margin: 0 5px 0 69px;
  font-size: 11px;
}

div.fionaRentalPublish {
  background-image: url('http://g-ecx.images-amazon.com/images/G/02/kindle/rentals/rent-book-promo-image._V152239283_.png');
  background-repeat: no-repeat;
  min-height: 6em;
  height: auto  !important;
  height: 6em;
}

div.fionaRentalPublish div {
  margin: 0 5px 0 110px;
  font-size: 11px;
}

div.fionaPublishBox {
  padding-top: 10px;
  text-align: left;
}

table.gftRdm .gftRdmTop td,
table.gftRdm .gftRdmBottom td {
  background-repeat:repeat-x;
  height:12px;
}

table.gftRdm .gftRdmLeft,
table.gftRdm .gftRdmRight {
  background-repeat:repeat-y;
  width:12px;
}

table.gftRdm .gftRdmTop .gftRdmLeft {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-top-left.jpg");
}

table.gftRdm .gftRdmTop .gftRdmCenter {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-top.jpg");
}

table.gftRdm .gftRdmTop .gftRdmRight {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-top-right.jpg");
}

table.gftRdm .gftRdmCenter .gftRdmLeft {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-left.jpg");
}

table.gftRdm .gftRdmCenter .gftRdmRight {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-right.jpg");
}

table.gftRdm .gftRdmBottom .gftRdmLeft {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-bottom-left.jpg");
}

table.gftRdm .gftRdmBottom .gftRdmCenter {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-bottom.jpg");
}

table.gftRdm .gftRdmBottom .gftRdmRight {
  background-image:url("http://g-ecx.images-amazon.com/images/G/02/kindle/gifting/box-bottom-right.jpg");
}

.giftRedemptionWrapper {
  padding:12px;
}
.buyBox.giftBox td {
  font-size:0.7em;
}

.suggest_link {
  background-color: #FFF;
  padding: 2px 6px 2px 6px;
}

.nav-beacon .suggest_link {
  padding: 1px 10px;
  line-height: 22px;
  margin: 0px;
}

.nav-beacon ul.promo_list {
  margin: 0;
  padding: 0;
  border-top: none;
  background-color: #FFF;
  list-style-type: none;
}

.nav-beacon ul.promo_list li {
  clear: both;
  overflow: hidden;
  padding: 7px 10px;
  white-space: normal;
  line-height: 20px;
  margin: 0;
}

.nav-beacon ul.promo_list li .promo_image {
  float: left;
  width: 40px;
  height: 40px;
  background-repeat: no-repeat;
  background-position: center center;
}

.nav-beacon ul.promo_list li .promo_cat {
  font-weight: bold;
  margin-left: 50px;
}
 
.nav-beacon ul.promo_list li .promo_title {
  line-height: 13px;
  margin-left: 50px;
}

.suggest_nm {
  display: block;
}

.nav-beacon .suggest_link_over {
  background-color: #EEE;
  color: #000;
}

.suggest_link_over {
  background-color: #146EB4;
  color: #FFF;
}

.suggest_link .suggest_category {
  color: #666;
} 

.nav-beacon .suggest_link_over .suggest_category {
  color: #666;
}

.suggest_link_over .suggest_category {
  color: #FFF;
}

#srch_sggst {
  background-color: #FFF;
  border: 1px solid #ddd;
  color: #000;
  position: absolute;
  text-align: left;
  z-index: 250;
}

.nav-beacon #srch_sggst {         
  -moz-box-shadow: 0 2px 5px 0 #AAAAAA;   
  -webkit-box-shadow: 0 2px 5px 0 #AAAAAA;   
  box-shadow: 0 2px 5px #AAAAAA;   
  border: none;  
  _border: 1px solid #ddd;   
}

.suggest_link, .promo_cat, .promo_title {
  font-family: arial, sans-serif;
}

#sugdivhdr, #sugdivhdr2 {
  color: #888;
  font-size: 10px;
  line-height: 12px;
  padding-right: 4px;
  text-align: right;
}




a.arrow-to-link span.arrow-to-link-span
{
    background-image: url('http://g-ecx.images-amazon.com/images/G/02/anywhere/chrome/arrow-right._V192241489_.gif');
    padding-left: 8;
    background-repeat: no-repeat;
    background-position: left;
    vertical-align: middle;
}
.Wid-technical-details-inbox
{
    -moz-background-inline-policy: continous;
    background: url('http://g-ecx.images-amazon.com/images/G/02/kindle/shasta/photos/grad_store_column3._V189714038_.jpg') repeat-y scroll left top transparent;
    width: 34%;
    height: 100%;
    vertical-align:top;
}
.stacked_tab_selected
{
    background: url('http://g-ecx.images-amazon.com/images/G/02/anywhere/chrome/arrow-right._V192241489_.gif') no-repeat;
}

.stacked_tab .minor_tab_selected
{
  background-position: 0 10px;
  background-image: url('http://g-ecx.images-amazon.com/images/G/02/anywhere/chrome/arrow-right._V192241489_.gif');
  background-repeat: no-repeat;
}

.stacked_tab .major_tab,
.stacked_tab .category_header
{
 
  background-position: 0 12px;
  background-image: url('http://g-ecx.images-amazon.com/images/G/02/kindle/shasta/gray-arrow.jpg');
  background-repeat: no-repeat;
}

.stacked_tab .major_tab_selected,
.stacked_tab .category_header_selected
{
  background:none;
}

.stacked_tab_selected .major_tab_container
{
  background: url('http://g-ecx.images-amazon.com/images/G/02/kindle/shasta/tab_background.jpg') repeat-x center bottom;
}

#buyBoxContent .cBox
{
  background-color:#E4F4FB;
  border: 1px solid #6DAEE1;
  margin: 10px 0 0 0;
}

.holiday-bow {
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/kindle/shasta/photos/bb_bow_02._V163521890_.png');
    padding-top: 14px;
    padding-bottom: 5px;
    height: 42px;
    background-repeat: no-repeat;
}



#buyBoxContent .cBox .cBoxTL,
#buyBoxContent .cBox .cBoxTR,
#buyBoxContent .cBox .cBoxBL,
#buyBoxContent .cBox .cBoxBR
{
  background-image:url(http://g-ecx.images-amazon.com/images/G/02/kindle/shasta/photos/bb-rounded-corner._V156952677_.png);
  background-color:#C0DBF2;
}
#buyBoxContent .cBox .cBoxTL { background-position:0 0; }
#buyBoxContent .cBox .cBoxTR { background-position:-10px 0; }
#buyBoxContent .cBox .cBoxBL { background-position:0 -10px; }
#buyBoxContent .cBox .cBoxBR { background-position:-10px -10px; }
#buyBoxContent .cBox .cBoxInner
{
  padding-left:0;
  text-align:left;
}

  .ap_popover_unsprited .ap_body .ap_left {  
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_left_17._V224624950_.png') !important;
  }
  .ap_popover_unsprited .ap_body .ap_right { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/KiSIT/arrow-popover-r_shadow_white._V135916158_.png') !important;
    width:45px;
  }
  .ap_popover_unsprited .ap_header .ap_left { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_top_left._V224624944_.png') !important;
  }
  .ap_popover_unsprited .ap_header .ap_right { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_top_right._V224624947_.png') !important;
  }
  .ap_popover_unsprited .ap_header .ap_middle { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_top._V224624945_.png') !important;
  }
  .ap_popover_unsprited .ap_header .ap_closebutton { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/btn_close._V192252893_.gif');
  }
  .ap_popover_unsprited .ap_footer .ap_left { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_bottom_left._V224624949_.png') !important;
  }
  .ap_popover_unsprited .ap_footer .ap_right { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_bottom_right._V224624948_.png') !important;
  }
  .ap_popover_unsprited .ap_footer .ap_middle { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_bottom._V224624949_.png') !important;
  }
  .ap_popover_unsprited .ap_footer .ap_middle { 
    background-image:url('http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/po_bottom._V224624949_.png') !important;
  }
  .bbHoverTextSimple b{
    color:#000000;
    text-decoration:none !important;
  }


#abbBox {
  padding: 10px 0;
}
#abbHeader {
  font-size: 11px;
  margin: 0;
  text-align: center;
}
#abbWrapper {
  padding: 0;
  text-align: left;
}
#abbWrapper ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
}
.abbListItem {
    font-size: 11px;
    margin-top: 5px;
}
.abbListItem input.abbListInput {
    float: left;
    display: inline;
    margin: 2px 0 10px 0;
    padding: 0;
    height: 16px;
}
.abbListItem a:link, .abbListItem a:visited,
a.ap_custom_close:link, a.ap_custom_close:visited {
    color: #039;
    text-decoration: none;
}
.abbListItem a:active, .abbListItem a:hover {
 color: #cc6600;
 text-decoration: underline;
}
.abbListItem a:hover {
    text-decoration: underline;
}
.abbListItem span.price {
    display:block;
}
div.abbItemText {
    display: block;
    margin-left: 20px;
    width: 170px;
}

.kfs-chart-close-image {
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/light/sprite-h._V218814404_.png);
}






.rhf-boxless-border {
    border-top: 1px solid #DDD;
    border-bottom: 1px solid #DDD;
    margin: 0px 10px;
}
.rhf-boxless-rhf-header {
    text-align:left;
    padding:10px 0px 0px;
}

.rhf_loading_outer {
    height: 248px; 
    overflow: hidden; 
    position: relative; 
    width: 100%;
}
.rhf_loading_outer[class] {
    display: table; 
    position: static;
}
.rhf_loading_middle {
    height: 100%;
    width: 100%;
}
.rhf_loading_inner {
    text-align: center;
    vertical-align: middle;
}





.rhfWrapper .shoveler .shoveler-heading {
    padding-right:14em;
}
.rhfWrapper .shoveler .shoveler-pagination {
    color: #666;
    padding: 0;
    position: absolute;
    right: 0;
    top: 0;
    width:14em;
    text-align:right;
}

#rhf a {
    text-decoration: none;
    color: #004B91;
}
#rhf a:hover {
    text-decoration: underline;
    color: #E47911;
}

.rhfWrapper .shoveler .start-over {
    font-size: 11px;
    font-family: Verdana;
    color: #666666;
}

.rhfWrapper .shoveler {
    position: relative;
    width: 100%;
}

.rhfWrapper .shoveler .shoveler-content {
    padding-top: 10px;
    margin: 0 35px 0 45px;
    clear:both;
}

* html .rhfWrapper .shoveler ul li {
    display: inline;
}

.rhfWrapper .shoveler li p {
    text-align: left;
}

.rhfWrapper .shoveler .reason-text {
    margin-top: 3px;
}

.rhfWrapper .shoveler ul li.shoveler-progress {
    background: no-repeat center 45px url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/loading-indicator._V192241665_.gif');
}

#rhf .rhfWrapper .product-link-wrapper a:hover,
#rhf .rhfWrapper .product-link-wrapper a:active {
    text-decoration: none;
    cursor: hand;
}
#rhf .rhfWrapper a:hover .title,
#rhf .rhfWrapper a:active .title {
    text-decoration: underline;
}

.rhfWrapper .title {
    font-family: arial, verdana, sans-serif;
    font-size: 13px;
    line-height: 18px;
    margin-top: 0;
}
.rhfWrapper .new-release {
    color: #009B01;
    font-weight: bold;
    font-family: verdana, arial, helvetica, sans-serif;
    font-size: 11px;
}

.rhfWrapper .byline {
    font-size: 11px;
}

.rhfHistoryWrapper {
    padding: 0 10px;
}

.rhfWrapper .rhfHistoryWrapper .byline {
    color: #666666;
}

.rhfWrapper #rviColumn {
    width: 240px;
    vertical-align: top;
    border-right: 1px solid #D3D3D3;

}

.rhfWrapper .shoveler .rating {
    margin-top: 3px;
}
.rhfWrapper .binding {
    color: #666666;
    font-size: 11px;
}
.rhfWrapper .shoveler .binding {
    margin-top: 2px;
}
.rhfWrapper .shoveler .price {
    margin-top: 2px;
    color: #900;
    font-size: 14px;
}
.rhfWrapper .shoveler .price .unit {
    color: #666;
    font-size: 12px;
}
.rhfWrapper .shoveler .priceText { font-size: 12px };
.rhfWrapper .shoveler .price-per-unit {
    font-size:10px;
    color:#990000;
    margin-left:.25em;
    white-space:nowrap;
}
#rhfMainHeading {
    font-family: Arial;
    font-weight: bold;
    font-size: 17px;
    color: #E47911;
}
.rhfWrapper #rhfNoRecsMessage {
    color: #666666;
    font-size: 13px;
    font-family: Arial;
}
.rhfWrapper .shoveler #rhfUpsellColumnTitle {
    color: #666666;
    font-size: 13px;
    font-family: Arial;
}
.rhfWrapper .rhfHistoryWrapper #rhfHistoryColumnTitle {
    color: #666666;
    font-size: 13px;
    font-family: Arial;
}
.rhfWrapper .popoverTrigger {
    margin-left:.35em;
    cursor:default;
}

* html .rhf {
    height:1%;
}
.rhfWrapper .shoveler-button-wrapper {
    position:relative;
    width:100%;
}
.rhfWrapper .shoveler div.back-button,
.rhfWrapper .shoveler div.next-button,
.rhfWrapper .shoveler div.disabled-button {
    position: absolute;
    height: 50px;
    width: 25px;
    top: 105px;
}
.rhfWrapper .shoveler div.next-button {
    right: 0;
    background: none;
}
.rhfWrapper .shoveler .back-button,
.rhfWrapper .shoveler div.disabled-button {
    left:1px;
}
.rhfWrapper .shoveler .next-button,
.rhfWrapper .shoveler div.disabled-button {
    right:1px;
}
.rhfWrapper .shoveler .back-button a,
.rhfWrapper .shoveler .next-button a {
    position: relative;
    font-size:70%;
    cursor: pointer;
}
.rhfWrapper .shoveler .back-button a .bg-text,
.rhfWrapper .shoveler .back-button a .bg-image,
.rhfWrapper .shoveler .next-button a .bg-text,
.rhfWrapper .shoveler .next-button a .bg-image {
    display: block;
    height: 50px;
    width: 25px;
    left: 0;
    overflow: hidden;
    position: absolute;
}
.rhfWrapper .shoveler .back-button a .bg-image,
.rhfWrapper .shoveler .next-button a .bg-image,
.rhfWrapper .shoveler div.disabled-button {
    background-image:  url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/left-right-arrow-semi-rd._V236573626_.gif');
}
.rhfWrapper .shoveler .back-button a .bg-image {
    background-position: 0 0;
}
.rhfWrapper .shoveler .back-button a.depressed .bg-image {
    background-position: 0 50px;
}
.rhfWrapper .shoveler .next-button a .bg-image {
    background-position: 25px 0;
}
.rhfWrapper .shoveler .next-button a.depressed .bg-image {
    background-position: 25px 50px;
}
.rhfWrapper .shoveler div.disabled-button {
    opacity: 0.2;
    -moz-opacity: 0.2;
    filter: alpha(opacity=20);
    cursor: default;
}
.rhfWrapper .shoveler .disclaim {
    margin-bottom: 15px;
}

#rhf_container {
    margin-top: 10px;
}

#rhf_container .carat {
    font-size: 11px;
    color: #E47911;
    line-height: 0;
    margin: 0 3px 0 0;
    font-weight: bold;
}

.rhfWrapper .shoveler ul {
    height: 286px !important;
    padding: 0;
    margin: 0;
    overflow:hidden;
    outline: none;
    font-size: 86%;
}

.rhfWrapper .shoveler ul li {
    float: left;
    margin: 0;
    padding: 0;
    width: 15em;
    height: 286px !important;
    overflow: hidden;
}

#rhf_tab_wrapper {
    position: relative;
    margin-bottom: 20px;
    width: 100%;
}
#rhf_tabs {
    padding-left: 10px;
    position: relative;
}
#rhf_container .tab {
    position: relative;
    display: inline-block;
    border: 1px solid #C9E1F4;
    padding: 3px 0px 3px 0px;
}
#rhf_tabs .active-rhf-tab {
    background-color: #FFFFFF;
    color: #E47911;
    border-bottom: 1px solid #FFFFFF;
    cursor: auto;
}
#rhf_tabs .inactive-rhf-tab {
    background-color: #EAF3FE;
    color: #003399;
    cursor: pointer;
}
#rhf_tabs .tabText {
    font-size: 13px;
    font-family: Arial;
    font-weight: bold;
    text-decoration: none;
}
#rhf_tabs .tabInner { padding: 0px 18px 0px 18px; }
#rhf_tabs .tabTL, #rhf_tabs .tabTR {
    position: absolute;
    display: block;
    width: 10px;
    height: 10px;
    z-index: 1;
    top: -1px;
    background-repeat: no-repeat;
}
#rhf_tabs .tabTL { left: -1px; }
#rhf_tabs .tabTR { right: -1px; }
#rhf_container .tabBarBottom {
    position: absolute;
    display: block;
    bottom: 3px;
    width: 100%;
    border-top: 1px solid #C9E1F4;
}
#rhf_tabs .tabTL, #rhf_tabs .tabTR { background-image: url(http://g-ecx.images-amazon.com/images/G/02/common/sprites/sprite-site-wide-2._V152889514_.png); }
#rhf_tabs .active-rhf-tab .tabTL { background-position: 0px 0px; }
#rhf_tabs .active-rhf-tab .tabTR { background-position: -10px 0px; }
#rhf_tabs .inactive-rhf-tab .tabTL { background-position: 0px -40px; }
#rhf_tabs .inactive-rhf-tab .tabTR { background-position: -10px -40px; }

.rhf_header {
    text-align:left;
    padding:10px 10px 0 10px;
}

#rhf_footer {
    padding: 10px;
    text-align: left;
    font-size: 13px;
}




.bxgy-priceblock .button-sprite, 
#bxgy_price_button_block .button-sprite,
#fbt_price_block .button-sprite {
        background-image: url( http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/bxgy/fbt-cart-preorder-sprite._V192237547_.gif);
}
#bxgy_price_button_block .wl-button-sprite,
#fbt_price_block .wl-button-sprite {
        background-image: url( http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/wishlist/add-to-wl-button-sprite._V247931754_.gif);
}
.bxgySellerLoading {
    background: url('http://g-ecx.images-amazon.com/images/G/02/x-locale/common/loading/loading-small._V192197121_.gif') no-repeat 50px 20px;
    height: 50px;
    margin: 0;
    padding: 0;
}





.shoveler li.shoveler-progress {
    background: no-repeat center 45px url('http://g-ecx.images-amazon.com/images/G/02/ui/loadIndicators/loading-small._V188036086_.gif');
}

.simsWrapper .shoveler ul {
    height: 217px;
}
.simsWrapper .shoveler li {
    width: 163px;
    margin: 0 10px;
    padding: 0;
    overflow: hidden;
}

.bdSprite {
    background: url('http://g-ecx.images-amazon.com/images/G/02/nav2/images/sprite-beard-buttons.jpg') no-repeat;
}


/* Mp3 Samples */
.simsMp3Enabled div.mp3AsinPlayImg { 
  background-image: url("http://g-ecx.images-amazon.com/images/G/02/s9-campaigns/music-player/playbutton.jpg");
}
 
.mp3AsinLoading div.mp3AsinPlayImg {
  background-image: url("http://g-ecx.images-amazon.com/images/G/02/s9-campaigns/music-player/spinner.jpg");
}

/* HMD Spinner */
.hmd-loading {
    background: no-repeat left 0 url('http://g-ecx.images-amazon.com/images/G/02/ui/loadIndicators/loading-small._V188036086_.gif');
}


#zgWrapper .shoveler .start-over {
    font-size:80%;    
}
#zgWrapper .shoveler .start-over a {
    text-decoration:none;    
}
#zgWrapper .shoveler .start-over a:visited {
    color:#004B91;   
}

#zgWrapper .shoveler {
    position:relative;
    width:100%;
}
#zgWrapper .shoveler .shoveler-content {
    margin:0 35px 0 45px;
    clear:both;
}
/*
#######################################################
# hackish for IE6's doubled float margin bug:see
# http://www.positioniseverything.net/explorer/doubled-margin.html
#######################################################
*/


* html #zgWrapper .shoveler ul li {
    display:inline;
}
#zgWrapper .shoveler .cBox {
    width:160px;
}
#zgWrapper .shoveler .noBox {
    padding:10px 0;
}
#zgWrapper .shoveler .product-image {
	margin-bottom:5px;
}
#zgWrapper .shoveler .pricetext {
        margin-top:5px;
}
#zgWrapper .shoveler .price {
	white-space:nowrap;
        margin-right:5px;
}
#zgWrapper .shoveler .pricelong {
        font-size:86%;
}

#zgWrapper .shoveler .whyPrice {
	white-space:nowrap;
        margin-top:2px;
        font-size:11px;
}

#zgWrapper .shoveler-button-wrapper {
    position:relative;
    width:100%;
}
#zgWrapper .shvl-byline {
    font-size:86%;
}
#zgWrapper .zg_rank {
    float:left;
    padding-right:6px;
}
#zgWrapper a.img-title {
  text-decoration:none;
}
#zgWrapper a.img-title:hover, 
#zgWrapper a.img-title:focus {
  text-decoration:underline;
}
/*
#########################################
# You should aim to align arrows with the 
# bottom of the product images and 
# the top of the titles.  
# Don't forget to also adjust the 
# loading icon position if you change this value
#########################################
*/
#zgWrapper .shoveler div.back-button, 
#zgWrapper .shoveler div.next-button,
#zgWrapper .shoveler div.disabled-button {
    position:absolute;
    height:50px; 
    width:25px;
    top:75px; 
}
#zgWrapper .shoveler div.next-button {
    background:none;
}
#zgWrapper .shoveler .back-button,
#zgWrapper .shoveler div.disabled-button {
	left:1px;
}
#zgWrapper .shoveler .next-button,
#zgWrapper .shoveler div.disabled-button {
	right:1px;
}
#zgWrapper .shoveler .back-button a, 
#zgWrapper .shoveler .next-button a {
    position:relative;
    font-size:70%;
    cursor:pointer;
}
#zgWrapper .shoveler .back-button a .bg-text, 
#zgWrapper .shoveler .back-button a .bg-image, 
#zgWrapper .shoveler .next-button a .bg-text, 
#zgWrapper .shoveler .next-button a .bg-image {
    display:block;
    height:50px;
    width:25px;
    left:0;
    overflow:hidden;
    position:absolute;
}

#zgWrapper .shoveler .back-button a .bg-image {
    background-position:0 0; 
}
#zgWrapper .shoveler .back-button a.depressed .bg-image {
    background-position:0 50px;
}
#zgWrapper .shoveler .next-button a .bg-image {
    background-position:25px 0; 
}
#zgWrapper .shoveler .next-button a.depressed .bg-image {
    background-position:25px 50px;
}

/*
##########################################
# DP-specific css
##########################################
*/
#zgWrapper {
	overflow:hidden;
}




#zgWrapper .shoveler .shoveler-heading {
	padding-right:175px;
	margin-bottom:15px;
	}
#zgWrapper .shoveler .shoveler-pagination {
    position:absolute;
    right:0;
    top:0;
    width:175px;
    text-align:right;
    padding:0;
}

#zgWrapper .shoveler ul li.shoveler-progress {
    background:no-repeat center 45px url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/loading-indicator._V192241665_.gif');
}
#zgWrapper .shoveler .back-button a .bg-image, 
#zgWrapper .shoveler .next-button a .bg-image,
#zgWrapper .shoveler div.disabled-button {
    background-image: url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/left-right-arrow-semi-rd._V236573626_.gif');
}
.shvlBack a .bg-image {
	background-image:url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/left-right-arrow-semi-rd._V236573626_.gif'); 
	background-position:0px 0px; 
	}
.shvlNext a .bg-image {
	background-image:url('http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/shoveler/left-right-arrow-semi-rd._V236573626_.gif'); 
	background-position:25px 0px; 
	}

#zgWrapper .shoveler ul {
    height:245px; 
    padding:0;
    overflow:hidden;
    outline:none;
}
#zgWrapper .shoveler ul li {
    float:left;
    margin:0 5px 0 5px;
    width:12.5em; #150px;
    height:245px; 
    overflow:hidden;
}




#productDescription h2.productDescriptionHeader {
    margin-bottom: 0em;	
}

#productDescription .emptyClear {
    clear:left;
    height:0px;
    font-size:0px;
}

#productDescription div.productDescriptionWrapper {
    margin: 0 0 1em 0;		
}

#productDescription h3.productDescriptionSource {
    font-weight:normal;
    color:#333333;
    font-size:1.23em;
    margin: .75em 0 .375em -15px;
    clear:left;
}

#productDescription .seeAll {
	margin-top: 1.25em; 
	margin-left: -15px; 
}

#productDescription ul, #technicalProductFeatures ul { 
  list-style-type: disc; 
  margin: 1.12em 0; 
  margin-left: 20px; 
}

#productDescription ul li { 
  margin: 0 0 0 20px; 
}

#productDescription ul li ul { 
  list-style-type: disc; 
  margin-left: 20px; 
}

#productDescription ul li ul li { 
  margin: 0 0 0 20px; 
}

#productDescription .aplus h4, #productDescription .aplus h5 {
    margin: 0 0 .75em 0;
    font-size: 1em;
}

#productDescription .aplus h4 {
    color: #CC6600;
}

#productDescription .aplus p {
    margin: 0 0 1em 0;
}

#productDescription .aplus .break {
    clear:both;
    height:0px;
    font-size:0px;
}

#productDescription .aplus .spacer {
    margin-bottom: 13px;
}

#productDescription .aplus img {
    border:none;
}

#productDescription .aplus .leftImage, #productDescription .aplus .rightImage, #productDescription .aplus .centerImage {
    margin-bottom: 1em;
    margin-top: 0;
    text-align:center;
    vertical-align:top;
}


#productDescription .aplus .leftImage {
    margin-right: 15px;
    float:left;
    clear:left;
}

#productDescription .aplus .rightImage {
    margin-left: 15px;
    float:right;
    clear:right;
}

#productDescription .aplus .imageCaption {
    clear:both;
    padding: .5em .5em 0 .5em;
    font-size: .846em;
    display: block;
}

#productDescription .aplus table.data { 
	border-collapse: collapse; 
	margin-bottom: 1.25em;
}

#productDescription .aplus table.data th { 
	font-weight: bold; 
	background: #F7F7F7; 
	border-style:solid; 
	border-color: #CCCCCC; 
	border-width:0 0 1px 1px; 
}

#productDescription .aplus table.data td { 
	border-left: 1px solid #CCC; 
	border-bottom: 1px dotted #CCC
}

#productDescription .aplus table.data th, #productDescription .aplus table.data td
{ 
	padding:3px 10px; 
	text-align:left
}

#productDescription .aplus table.data tfoot { 
	font-style: italic; 
}

#productDescription .aplus table.data caption {
	background: #eee; 
	font-size: .8125em;
}

#productDescription .aplus table.data tr td:first-child, #productDescription .aplus table.data tr th:first-child {
	border-left-width:0px;
}

#productDescription .aplus ul {
	margin:0 0 1em 0;
}


#productDescription .aplus .center {
	text-align: center;
}

#productDescription .aplus .right {
	text-align: right;
}

#productDescription .aplus  .sixth-col,
#productDescription .aplus .fourth-col,
#productDescription .aplus .third-col,
#productDescription .aplus .half-col,
#productDescription .aplus .two-third-col,
#productDescription .aplus .three-fourth-col,
#productDescription .aplus .one-col {
    float:left;
    margin-right: 1.6760%;
    overflow: hidden;
}

#productDescription .aplus .last {
    margin-right:0px;
}

#productDescription .aplus .sixth-col {
    width: 15.080%;
}
#productDescription .aplus .fourth-col {
    width: 23.4637%;
}

#productDescription .aplus .third-col {
    width: 31.8436%;
}

#productDescription .aplus .half-col {
    width: 48.6034%;
}

#productDescription .aplus .two-third-col {
    width: 65.3631%;
}

#productDescription .aplus .three-fourth-col {
    width: 73.7430%;
}

#productDescription .aplus .one-col {
    width: 98.8827%;
    margin-right:0;
}

#productDescription .aplus .last {
    margin-right:0;
}

#productDescription .aplus {
    width: 100%;
    min-width: 895px;
}

* html #productDescription .aplus {
    width: expression((document.body.clientWidth < 936) ? "895px" : "100%" );
}



  
    .tagEdit {
      padding-bottom:4px;
      padding-top:4px;
    }

    .edit-tag {
      width: 155px;
      margin-left: 10px;
    }

    .list-tags {
      white-space: nowrap;
      padding: 1px 0px 0px 0px;
    }

   #suggest-table {
      display: none;
      position: absolute;
      z-index: 2;
      background-color: #fff;
      border: 1px solid #9ac;
    }

    #suggest-table tr td{
      color: #333;
      font: 11px Verdana, sans-serif;
      padding: 2px;
    }

    #suggest-table tr.hovered {
      color: #efedd4;
      background-color: #9ac;
    }

  
  .see-popular {
    padding: 1.3em 0 0 0;
  }

  .tag-cols {
    border-collapse: collapse;
  }

  .tag-cols td {
    vertical-align: top;
    width: 250px;
    padding-right: 30px;
  }

  .tag-cols .tag-row {
    padding: 0 0 7px 0px;
  }

  .tag-cols .see-all {
    white-space: nowrap;
    padding-top: 5px;
  }

  .tags-piles-feedback {
    display: none;
    color: #000;
    font-size: 0.9em;
    font-weight: bold;
    margin: 0px 0 0 0;
   }

  .tag-cols i {
    display: none;
    cursor: pointer;
    cursor: hand;
    float: left;
    font-style: normal;
    font-size: 0px;
    vertical-align: bottom;
    width: 16px;
    height: 16px;
    margin-top: 1px;
    margin-right: 3px;
  }

  .tag-cols .snake {
    display: block;
    background: url('http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/tags/graysnake._V192196091_.gif');
  }

  #tagContentHolder .tip {
    display: none;
    color: #999;
    font-size: 10px;
    padding-top: 0.25em;
  }

  #tagContentHolder .tip a {
    color: #999 !important;
    text-decoration: none !important;
    border-bottom: solid 1px #CCC;
  }

  .nowrap {
    white-space: nowrap;
  }

  #tgEnableVoting {
    display: none;
  }

  #tagContentHolder .count {
    color: #666;
    font-size: 10px;
    margin-left: 3px;
    white-space: nowrap;
  }

  .count.tgVoting {
    cursor: pointer;
  }

  .tgVoting .tgCounter {
    margin-right: 3px;
    border-bottom: 1px dashed #003399;
    color: #003399;
  }



a.slateLink:link{ color: rgb(119,119,119); text-decoration:none;}
a.slateLink:active { color: rgb(119,119,119); text-decoration:none;}
a.slateLink:visited{ color: rgb(119,119,119); text-decoration:none;}
a.slateLink:hover{ color: rgb(119,119,119); text-decoration:none;}

.shuttleGradient {
    float:left;
    width:100%;
    text-align:left;
    line-height: normal;
    position:relative;
    height:43px; 
    background-color:#dddddd; 
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/customerimage/shuttle-gradient._V192198912_.gif); 
    background-position: bottom; 
    background-repeat : repeat-x;
}

.shuttleTextTop {
    font-size:18px;
    font-weight:bold;
    font-family:verdana,arial,helvetica,sans-serif;
    color: rgb(119,119,119);
    margin-left:10px;
}

.shuttleTextBottom {
    margin-top:-2px;
    font-size:15px;
    font-family:verdana,arial,helvetica,sans-serif;
    color: rgb(119,119,119);
    margin-left:10px;
}
.outercenterslate{
    cursor:pointer;
}
.innercenterslate{
    overflow: hidden;
}

.slateoverlay{
    position: absolute;
    top: 0px;
    border: 0px
}

.centerslate {
    display: table-cell;
    background-color:black; 
    text-align: center;
    vertical-align: middle;
}
.centerslate * {
    vertical-align: middle;
}
.centerslate { display/*\**/: block\9 } 
/*\*//*/
.centerslate {
    display: block;
}
.centerslate span {
    display: inline-block;
    height: 100%;
    width: 1px;
}
/**/
</style>
<!--[if lt IE 9]><style>
.centerslate span {
    display: inline-block;
    height: 100%;
}
</style><![endif]-->
<style>

.bucketDiv {
        padding:5px 0em;
        padding:15px 0px 15px 0px;
}

.bucketDivFloat {
        float:left;
        padding:5px 0em;
        padding:15px 0px 15px 0px;
}

.showFieldsTop {
        border-top:1px solid black;
        border-left:1px solid black;
}

.showFieldsBottom {
	font-family: verdana,arial,helvetica,sans-serif;
	font-size: x-small;
        border-bottom:1px solid black;
        border-right:1px solid black;
}









.jumpBar #amazon-like_feature_div,
#handleBuy #average-customer-reviews_feature_div,
#handleBuy #aamazon-like_feature_div,
.jumpBar #socialmedia-links_feature_div {
    display: inline-block;
}
.jumpBar #amazon-like_feature_div,
#handleBuy #average-customer-reviews_feature_div,
#handleBuy #amazon-like_feature_div,
.jumpBar #socialmedia-links_feature_div {
    display: inline;
}
.jumpBar>#amazon-like_feature_div,
#handleBuy>#average-customer-reviews_feature_div,
#handleBuy>#amazon-like_feature_div,
.jumpBar>#socialmedia-links_feature_div {
    display: inline-block;
}
#likeAndShareBar {
    top: 211px;
    text-align: right;
    font-size: 0.86em;
    margin-left: 4px;
    display: inline-block;
}

#amazonLikeKindle #likeAndShareBar {
    display: inline-block;
    position: relative;
    top: 4px;
    margin-left: 0px;
    margin-top: -.86em;
}
.jumpbar #likeAndShareBar {
    margin-top: -4px;
    margin-left: 0px;
}

.jumpBar #amazonLikeKindle #likeAndShareBar {
    margin-left: 0px;
}

#entityLike #likeAndShareBar {
    text-align: center;
    font-size: 0.86em;
    margin-top: -4px;
    display: inline-block;
}
.amazonLike .hideUntilJSReady {
    display: none;
}
.amazonLikeBeak {
    overflow: hidden;
    display: inline-block;
    background-repeat: repeat;
    background-attachment: scroll;
    background-position: -150px 0pt;
    background-color: transparent;
    position: absolute;
    top: -29px;
    right: 15px;
    width: 12px;
    height: 10px;
}
.amazonLikeBeak.entityPageLeft {
    left: 45px;
}
#amazonLikeKindle .amazonLike .amazonLikeButtonCountCombo {
    overflow: hidden;
}
.amazonLike .amazonLikeButtonCountCombo .amazonLikeCountContainer {
    display: inline-block;
    margin-top: 4px;
}
#entityLike .amazonLike .amazonLikeButtonCountCombo .amazonLikeCountContainer {
    vertical-align: middle;
}
.amazonLike .amazonLikeButtonCountCombo .amazonLikeButtonWrapper {
    float: left;
}
.amazonLike .amazonLikeButtonWrapper {
    margin: 0 4px 0 0;
}

#entityLike .amazonLike .amazonLikeButtonCountCombo .amazonLikeButtonWrapper {
    margin-top: -14px;
    margin: 0;
    float: none;
}
.amazonLike .amazonLikeButtonWrapper a {
    text-decoration: none;
    outline: none;
}
.amazonLike .amazonLikeButtonWrapper .amazonLikeButton {
    overflow: hidden;
    display: inline-block;
    position: relative;
    vertical-align: middle;
    background-repeat: no-repeat;
    background-color: #fff;
}
.amazonLike .amazonLikeButton.clickable {
    cursor: pointer;
}
.amazonLike .amazonLikeButton span.altText {
    position: absolute; top: -9999px;
}
.amazonLike .amazonLikeButton.down {
    height: 19px;
}
.amazonLike .amazonLikeButton.down.off {
    background-position: 0 0;
    width: 47px;
}
.amazonLike .amazonLikeButton.down.on {
    background-position: -100px 0;
    width: 47px;
}
.amazonLike .amazonLikeButton.down.pressed {
    background-position: -50px 0;
}
.amazonLikePopover {
    font-size: 11px;
    overflow: hidden;
}
.amazonLikePopover .amazonLikeShareCondo {
    margin-left: -5px;
}
.amazonLikePopover .tafContainerDiv {
    height: 18px;
}
.amazonLikeContext_entity .sharePageTeaser {
    margin: 0;
}
.amazonLikeContext_entity .sharepagebutton {
    padding: 0;
}
.amazonLikePopover .likePopoverError {
    margin-bottom: 10px;
}
.amazonLikePopover .spacer {
    margin-top: 10px;
}
.amazonLikePopover .bottomSpacer {
    margin-bottom: 10px;
}
.amazonLikePopover .likeCountText {
    font-weight: bold;
}
.amazonLikePopover .bottomRightLinks {
    text-align: right;
    color: #999;
}
.amazonLikePopover a.grayLink {
    color: #666;
    text-decoration: none;
    font-size: 10px;
}
.amazonLikePopover a.grayLink:link {
    color: #666;
    text-decoration: none;
    font-size: 10px;
}
.amazonLikePopover a.grayLink:visited {
    color: #666;
}
.amazonLikePopover a.grayLink:hover {
    color: #004B91;
    text-decoration: underline;
}





.c2c-inline-sprite {
    display: -moz-inline-box;
    display: inline-block;
    margin: 0;padding: 0; 
    position: relative;
    overflow: hidden;
    vertical-align: middle;
    background: url(http://g-ecx.images-amazon.com/images/G/02/electronics/click2call/click2call-sprite.png) no-repeat;
}
.c2c-inline-sprite span {
    position:absolute;
    top:-9999px;
}

.dp-call-me-button {
    width:52px;
    height:22px;
    background-position:0px -57px; 
}





.SponsoredLinkYellowBlock {
  margin-top       : 7px;
  position         : absolute;
  background-color : #db9234;
  width            : 4px;
  height           : 4px;
  margin-right     : 2px;
  margin-left      : 2px;
  left             : 0px;
  top              : 0px;
  line-height      : 1px;
}
  
#SponsoredLinksTagPage {
  margin-bottom:7px;
}
  
/* START: sponsored links third party ads css */
.SponsoredLinksDebug {
   background-color: yellow;
   font-size: 12px;
}
 
.SponsoredLinkSmall {
   font: 10px Verdana,Arial,Helvetica,sans-serif;
}
 
.SponsoredLinksGrayBox {
   height: auto;
   margin-bottom: -7px;
   padding-bottom: 5px;
   padding-right: 10px;
   padding-top: 8px;
}
 
.SponsoredLinksGrayBox a {
   text-decoration: underline;
}
 
.SponsoredLinksGrayBox a:hover {
   text-decoration: none;
   color:#CC6600;
}
.SponsoredLinkItemTD {
   padding-left: 25px;
   padding-top: 8px;
}
 
.SponsoredLinkItemTD a {
   font-weight: bold;
}

.SponsoredLinkColumnAds a:link {
   font-family: verdana,arial,helvetica,sans-serif;
}

.SponsoredLinkTitle a:link {
   color: #003399;
   font-size: 13px;
   text-decoration: underline;
}

.SponsoredLinkTitle a:hover {
  color: #CC6600;
  font-size: 13px;
  text-decoration: none;
}
 
.SponsoredLinkDescription {
   padding-left:10px;
   padding-top:1px;
   margin-left:1px;
   margin-right:4px;
}
 
.SponsoredLinkDescriptionText {
   font-family: verdana,arial,helvetica,sans-serif;
   font-size: 13px;
   color: black;
}
 
.SponsoredLinkItem{
   font-family: Verdana, Arial, Helvetica, sans-serif;
   font-size: 12px;
}
 
.SponsoredLinksDivider{
   border-top: 1px dashed #999999;
   height: 1px;
   color: #FFFFFF;
   margin: 3px 0px;
}
 
.SponsoredLinkYellowBlockEnclosure {
   position: relative;
}

 
.SponsoredLinkContentDeclaration {
   text-align: right;
   padding-right: 20px;
   color: #C2C2C2
}
 
.SponsoredLinksBottomBox {
   padding-top: 5px;
   padding-right: 20px;
}
 
#SponsoredLinksCustomerMediaPage h2 {
   display: inline;
   color: #CC6600;
   font-size: medium;
   font-family: verdana,arial,helvetica,sans-serif;
}
 
.SponsoredLinkDescriptionUrlLink a:hover {
   color:black;
}
 
.SponsoredLinksAdvertiseYourServices {
   font-size: 11px;
   float: right;
}
/* END: sponsored links third party ads css */

.SponsoredLinkDescriptionUrlLink:link, #A9AdsMiddleBoxTop .SponsoredLinkDescriptionUrlLink:link, #SponsoredLinksCustomerMediaPage .SponsoredLinkDescriptionUrlLink:link, #SponsoredLinksTagPage .SponsoredLinkDescriptionUrlLink:link {
   color:black;
   font-size:13px;
   font-weight:normal;
   text-decoration:none;
}
.SponsoredLinkDescriptionUrlLink:hover,  #A9AdsMiddleBoxTop .SponsoredLinkDescriptionUrlLink:hover, #SponsoredLinksCustomerMediaPage .SponsoredLinkDescriptionUrlLink:hover, #SponsoredLinksTagPage .SponsoredLinkDescriptionUrlLink:hover {
   color:black;
   font-size:13px;
   font-weight:normal;
   text-decoration:none;
}
.SponsoredLinkDescriptionUrlLink:visited, #A9AdsMiddleBoxTop .SponsoredLinkDescriptionUrlLink:visited, #SponsoredLinksCustomerMediaPage .SponsoredLinkDescritionUrlLink:visited, #SponsoredLinksTagPage .SponsoredLinkDescriptionUrlLink:visited {
   color:black;
   font-size:13px;
   font-weight:normal;
   text-decoration:none;
}
.SponsoredFeedbackDiv{
   display       : block;
   font-size     : 11px;
   padding-left  : 22px;
   padding-top   : 5px;
   margin-top    : 10px;
}


#SlDiv_0 .SponsoredLinkColumnAds{
  border-width: 0px;
  border-spacing: 0px;
  border-collapse: collapse;
}
#SlDiv_0 .SponsoredLinkDescriptionDIV {
  margin-top: 10px;
}
#SlDiv_0 .SponsoredLinkTitle, #SlDiv_0 .SponsoredLinkTitle a{
      margin-top: 10px;
      font-weight: bold;
}
#SlDiv_0 .SponsoredLinkYellowBlockEnclosureTop{
      color: #CC6600;
}

#SlDiv_1 .SponsoredLinkYellowBlockEnclosureTop{
  color: #CC6600;
}
#SlDiv_1 .SponsoredLinkDescription{
  padding-left: 0px;
}
      
#SlDiv_1 .SponsoredLinkColumnAds{
  border-width: 0px;
  border-spacing: 0px;
  border-collapse: collapse;
}

#SlDiv_1 .SponsoredLinkDescriptionUrlLinkEnclosure{
  padding-left: 26px;
  padding-right:40px;
}

#SlDiv_2 .SponsoredLinkYellowBlockEnclosureTop{
  color: #CC6600;
}
#SlDiv_2 .SponsoredLinkDescription{
  padding-left: 0px;
}
      
#SlDiv_2 .SponsoredLinkItemTD{
   margin-bottom:10px;
}


#SlDiv_0 .SponsoredLinkYellowBlock {
  margin-top: 10px;
}
#SlDiv_1 .SponsoredLinkYellowBlock {
  margin-top: 5px;
}

    
#SlDiv_1 {
  margin-top: 5px;
}



div.mp3Enabled { display: block; height: 20px; position: relative; }
div.mp3Enabled a.mp3Asin { display: -moz-inline-box; display: inline-block; height: 20px; width: 20px; cursor: pointer; margin: 0; vertical-align: middle; overflow: hidden;
		background: url('http://g-ecx.images-amazon.com/images/G/02/zeitgeist/mp3player/sprites._V192561915_.gif') repeat-x scroll 0 0; }
div.mp3Enabled a.mp3AsinActive { background-position: 0 0; }
div.mp3Enabled a.mp3AsinActiveHover { background-position: -25px 0; }
div.mp3Enabled a.mp3AsinActivePause { background-position: 0 -25px; }
div.mp3Enabled span.mp3Text { margin: 0; font-size: 0.8em; vertical-align: middle; }
* html div.mp3Enabled span.mp3Text { margin-left: 5px; }
div.mp3Enabled img.mp3Loading { height: 16px; width: 16px; vertical-align: middle; }   
div.mp3Enabled span.listenText { font-size: 0.9em; font-weight: bold; color: #CC6600 }   
.mp3DurationPopover { border: 1px solid black; background-color: #FFFFE1; font-size: 0.8em; padding: 1px 5px 1px 5px; text-align: center}
#mp3Player_noflash { border: 1px solid #A31919; color: #A31919; background-color: #FFFFDD; font-size: 0.8em; padding: 1px 5px 1px 5px; text-align: center }
.audioSamplesPlayer { margin: 12px 0px 3px 57px; text-align: left;  }

table.buyExternalShortFade td.topLeft {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/buyExternal/buyExternalShortFade_topLeft.jpg');
	background-repeat: no-repeat;
}
table.buyExternalShortFade td.topRight {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/buyExternal/buyExternalShortFade_topRight.jpg');
	background-repeat: no-repeat;
}
table.buyExternalShortFade td.bottomLeft {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/buyExternal/buyExternalShortFade_bottomLeft.jpg');
	background-repeat: no-repeat;
	line-height: 12px;
}
table.buyExternalShortFade td.bottomRight {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/buyExternal/buyExternalShortFade_bottomRight.jpg');
	background-repeat: no-repeat;
	line-height: 12px;
}

.pa_syndicationPrice {
	margin: 0px 0px 0px 8px;
	padding: 0px 0px 0px 12px;
	font-size: 10px;
	font-weight: bold;
	color: #990000;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/buyExternal/icon4-orangeSquare.jpg');
	background-position: 0 5;
	background-repeat: no-repeat;
}

.pa_offer .pa_merchant a.pa_merchantNamePopover {
	color: #565656;
	text-decoration: underline;
}

.pa_blueBorderTable .pa_borderTL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxTL.jpg');
	background-position: top right;
	background-repeat: no-repeat;
	width: 5px;
	height: 5px;
}
.pa_blueBorderTable .pa_borderTC {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxTC.jpg');
	background-repeat: repeat-x;
}
.pa_blueBorderTable .pa_borderTR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxTR.jpg');
	background-repeat: no-repeat;
	width: 5px;
}
.pa_blueBorderTable .pa_borderLeft {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxLeft.jpg');
	background-position: top left;
	background-repeat: repeat-y;
}
.pa_blueBorderTable .pa_borderRight {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxRight.jpg');
	background-position: top right;
	background-repeat: repeat-y;
}
.pa_blueBorderTable .pa_borderBL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxBL.jpg');
	background-repeat: no-repeat;
	height: 5px;
}
.pa_blueBorderTable .pa_borderBC {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxBC.jpg');
	background-repeat: repeat-x;
}
.pa_blueBorderTable .pa_borderBR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_blueBoxBR.jpg');
	background-repeat: no-repeat;
}

.pa_buyBoxWrap-TR {
	width: 99%;
	margin: auto;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_buyBoxWrapper-TR._V143784688_.gif') no-repeat right top;
}
.pa_buyBoxWrap-TL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_buyBoxWrapper-TL._V143784674_.gif') no-repeat left top;
}
.pa_buyBoxWrap-BR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_buyBoxWrapper-BR._V145602395_.gif') no-repeat right bottom;
}
.pa_buyBoxWrap-BL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_buyBoxWrapper-BL._V143784467_.gif') no-repeat left bottom;
}
.pa_firstOfferWrap-TR {
	width: 99%;
	margin: auto;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_primaryOfferWrap-TR._V143784618_.gif') no-repeat right top;
}
.pa_firstOfferWrap-TL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_primaryOfferWrap-TL._V143784660_.gif') no-repeat left top;
}
.pa_firstOfferWrap-BR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_primaryOfferWrap-BR._V143784640_.gif') no-repeat right bottom;
}
.pa_firstOfferWrap-BL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_primaryOfferWrap-BL._V143779215_.gif') no-repeat left bottom;
}
.pa_buyBoxOffer .pa_merchant a.pa_merchantNamePopover {
    white-space: nowrap;
	color: #565656;
	text-decoration: underline;
}
.pa_grayBorderTable .pa_borderTL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxTL.jpg');
	background-position: top right;
	background-repeat: no-repeat;
	width: 5px;
	height: 5px;
}
.pa_grayBorderTable .pa_borderTC {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxTC.jpg');
	background-repeat: repeat-x;
}
.pa_grayBorderTable .pa_borderTR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxTR.jpg');
	background-repeat: no-repeat;
	width: 5px;
}
.pa_grayBorderTable .pa_borderLeft {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxLeft.jpg');
	background-position: top left;
	background-repeat: repeat-y;
}
.pa_grayBorderTable .pa_borderRight {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxRight.jpg');
	background-position: top right;
	background-repeat: repeat-y;
}
.pa_grayBorderTable .pa_borderBL {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxBL.jpg');
	background-repeat: no-repeat;
	height: 5px;
}
.pa_grayBorderTable .pa_borderBC {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxBC.jpg');
	background-repeat: repeat-x;
}
.pa_grayBorderTable .pa_borderBR {
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_grayBoxBR.jpg');
	background-repeat: no-repeat;
}
.pa_bucketLoadingIndicator {
	padding: 0;
	margin: 15px 0px 15px 124px;
	height: 124px;
	background-image: url('http://g-ecx.images-amazon.com/images/G/02/ui/loadIndicators/loading-large_boxed._V192263005_.gif');
	background-repeat: no-repeat;
}
.pa_adID a
{
	text-decoration:none;
	display:block;
	background:url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_feedback_bubble._V147641588_.png') no-repeat;
	background-position: 130px 0px;
	line-height:12px;
}
.pa_adID a:hover
{
	background:url('http://g-ecx.images-amazon.com/images/G/02/productAds/pa_feedback_bubble._V147641588_.png') no-repeat;
	background-position: 130px -12px;
}
</style>











 
 




<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/site-wide-6146007985._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/GB-combined-3885691430._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/style-4._V195816946_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/dpMergedOverallCSS-13286489957._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleDeviceCSS-859337478._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleDeviceCSSExtended-2222428111._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleFamilyStripeCSS-2430517572._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/ciuCSS-ciuAnnotations-56849._V1_.css" rel="stylesheet">
<style type="text/css">

/* non-sprited */
.ap_popover_unsprited .ap_body   .ap_left   { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_left_17._V248144977_.png); }
.ap_popover_unsprited .ap_body   .ap_right  { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_right_17._V248144979_.png); }
.ap_popover_unsprited .ap_header .ap_left   { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_top_left._V265110087_.png); }
.ap_popover_unsprited .ap_header .ap_right  { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_top_right._V265110087_.png); }
.ap_popover_unsprited .ap_header .ap_middle { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_top._V265110086_.png); }
.ap_popover_unsprited .ap_footer .ap_left   { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_bottom_left._V265110084_.png); }
.ap_popover_unsprited .ap_footer .ap_right  { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_bottom_right._V265110087_.png); }
.ap_popover_unsprited .ap_footer .ap_middle { background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/po_bottom._V265110084_.png); }

/* Everything else -- sprited */
.ap_popover_sprited .ap_body .ap_left, 
.ap_popover_sprited .ap_body .ap_right {
    background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/light/sprite-v._V219326283_.png);
}


.ap_popover_sprited .ap_header .ap_left, 
.ap_popover_sprited .ap_header .ap_right,
.ap_popover_sprited .ap_header .ap_middle,
.ap_popover_sprited .ap_footer .ap_left, 
.ap_popover_sprited .ap_footer .ap_right,
.ap_popover_sprited .ap_footer .ap_middle,
.ap_popover_sprited .ap_closebutton {
    background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/light/sprite-h._V219326280_.png);
}

.ap_popover_sprited .ap_body .ap_right-arrow, .ap_popover_sprited .ap_body .ap_left-arrow {
    background-image: url(http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/light/sprite-arrow-v._V219326286_.png);
}

</style>


<script type="text/javascript">

var amznJQ,jQueryPatchIPadOffset=false;
(function() {
  function f(x) {return function(){x.push(arguments);}}
  function ch(y) {return String.fromCharCode(y);}
  var a=[],c=[],cs=[],d=[],l=[],o=[],s=[],p=[],t=[];
  amznJQ={
    _timesliceJS: false,
    _a:a,_c:c,_cs:cs,_d:d,_l:l,_o:o,_s:s,_pl:p,
    addLogical:f(l),
    addStyle:f(s),
    addPL:f(p),
    available:f(a),
    chars:{EOL:ch(10), SQUOTE:ch(39), DQUOTE:ch(34), BACKSLASH:ch(92), YEN:ch(165)},
    completedStage:f(cs),
    declareAvailable:f(d),
    onCompletion:f(c),
    onReady:f(o),
    strings:{}
  };
}());


</script>



<script type="text/javascript">
if (window.amznJQ) {
    amznJQ.addLogical('csm-base', [ "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/csm-base/csm-base-min-170757555._V1_.js" ]);
    amznJQ.available('csm-base', function() {});
}

</script>
<script type="text/javascript" src="chrome-extension://pmoflmbbcfgacopiikdcpmbiellfihdg/webkitnotif-wrapper-builder.js"></script><script type="text/javascript" src="chrome-extension://pmoflmbbcfgacopiikdcpmbiellfihdg/unity-api-page-proxy-builder-gen.js"></script><script type="text/javascript" src="chrome-extension://pmoflmbbcfgacopiikdcpmbiellfihdg/unity-api-page-proxy.js"></script></head>
<body class="dp"><div id="ap_container"><iframe frameborder="0" tabindex="-1" src="javascript:void(false)" style="display: none; position: absolute; z-index: 199; opacity: 0; top: 311px; left: 339.5px; width: 787px; height: 42px; visibility: visible;"></iframe><iframe frameborder="0" tabindex="-1" src="javascript:void(false)" style="display:none;position:absolute;z-index:0;filter:Alpha(Opacity=&#39;0&#39;);opacity:0;"></iframe><iframe frameborder="0" tabindex="-1" src="javascript:void(false)" style="display:none;position:absolute;z-index:0;filter:Alpha(Opacity=&#39;0&#39;);opacity:0;"></iframe></div>
<div class="singlecolumnminwidth" id="divsinglecolumnminwidth">
 





<script type="text/javascript">
amznJQ.onCompletion('amznJQ.criticalFeature', function() {
  amznJQ.available('navbarJS-jQuery', function(){});
  amznJQ.available('finderFitsJS', function(){});
  amznJQ.available('twister', function(){});
  amznJQ.available('swfjs', function(){});

});
</script>
<!-- BeginNav -->
  <!-- From remote config v3-->
  <script type="text/javascript"><!--
  window._navbarSpriteUrl = 'http://g-ecx.images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png';
  amznJQ.available('popover', function() {
    amznJQ.available('navbarBTF', function() {
      var ie6 = jQuery.browser.msie && parseInt(jQuery.browser.version) <= 6,
      h = new Image(), v = new Image(), c = 0, b, f, bi,
      fn = function(p){ switch(typeof p){ case'boolean':{b=p;bi=1;break} case'function':{f=p} default:{c++} } if(bi&&c>2)f(b) };
      
      h.src = (ie6 ? 'http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-8bit-h._V147907309_.png' : 'http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-h-v2._V147907311_.png');
      v.src = (ie6 ? 'http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-8bit-v._V147907308_.png' : 'http://g-ecx.images-amazon.com/images/G/02/gno/beacon/nav-pop-v-v2._V147907310_.png');
      window._navpreload = {'sprite_h':h, 'sprite_v':v, '_protectExposeSBD':fn};

      _navpreload._menuCallback = function() {
        _navpreload.spin = new Image();
        _navpreload.spin.src = 'http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/snake._V192252891_.gif';
      };
    });
  });
  --></script>
<img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/BeaconSprite-UK-02._V397961423_.png" style="display:none" alt="">
<img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/transparent-pixel._V167145160_.gif" style="display:none" alt="" id="nav_trans_pixel">






        

  

  



















<!--Pilu -->



<script type="text/javascript"><!--
    window.Navbar = function(options) {
      options = options || {};

      this._loadedCount = 0;
      this._hasUedata = (typeof uet == 'function');
      this._finishLoadQuota = options['finishLoadQuota'] || 2;
      this._startedLoading = false;

      this._btfFlyoutContents = [];
    
      this._saFlyoutHorizOffset = -20;
      this._saMaskHorizOffset = -21;
      
      this._sbd_config = {
        major_delay: 300,
        minor_delay: 100,
        target_slop: 25
      };
      
      this.addToBtfFlyoutContents = function(content, callback) {
        this._btfFlyoutContents.push({content: content, callback: callback});
      }

      this.getBtfFlyoutContents = function() {
        return this._btfFlyoutContents;
      }

      this.loading = function() {
        if (!this._startedLoading && this._isReportingEvents()) {
          uet('ns');
        }

        this._startedLoading = true;
      }

      this.componentLoaded = function() {
        this._loadedCount++;
        if (this._startedLoading && this._isReportingEvents() && (this._loadedCount == this._finishLoadQuota)) {
          uet('ne');
        }
      }

      this._isReportingEvents = function() {
        return this._hasUedata;
      }

      this.browsepromos = {};

      this.issPromos = [];

      this.le = {};

      this.logEv = function(d, o) {
      }

    }

    window._navbar = new Navbar({ finishLoadQuota: 1});
    _navbar.loading();


_navbar._ajaxProximity = [141,7,60,150];

--></script>

  <!-- navp-e6gfZirzpKFxuOdSjlEZrjv35/3zC3nk0WGFwN124MIXjwt/u5qgFycM5omtof4h1PuaxxeHpBQ= rid-0KGHD1WV7T4KNAQMVBGQ templated -->
  



  <style type="text/css"><!--
    .nav-searchfield-width {
      padding: 0 2px 0 89px;
    }

    #nav-search-in {
      width: 89px;
    }

  --></style>

<!--[if gt IE 6]--><noscript>&lt;![endif]&gt;
&lt;style type="text/css"&gt;&lt;!--
    select#searchDropdownBox {
      visibility: visible;
      display: block;
    }
    div.nav-searchfield-width {
      padding-left: 200px;
    }
    span#nav-search-in {
      width: 200px;
    }
    #nav-search-in span#nav-search-in-content {
      display: none;
    }
--&gt;&lt;/style&gt;
&lt;![if gt IE 6]&gt;</noscript><!--[endif]-->

<header>
  <div id="navbar" class="nav-beacon nav-subnav nav-prime-menu nav-logo-large">

    <div id="nav-cross-shop">

      <a href="http://www.amazon.co.uk/ref=gno_logo" id="nav-logo" class="nav_a nav-sprite" alt="Amazon">
        Amazon
        <span class="nav-prime-tag nav-sprite"></span>
      </a>


      <ul id="nav-cross-shop-links">
                      <li class="nav-xs-link first"><a href="http://www.amazon.co.uk/gp/yourstore/home/ref=topnav_ys" class="nav_a" id="nav-your-amazon">Your Amazon.co.uk</a></li>
                          <li class="nav-xs-link "><a href="http://www.amazon.co.uk/deals-offers-savings/b/ref=cs_top_nav_gb27?ie=UTF8&node=350613011" class="nav_a">Today's Deals</a></li>
                          <li class="nav-xs-link "><a href="http://www.amazon.co.uk/gp/gc/ref=topnav_giftcert" class="nav_a">Gift Cards</a></li>
                          <li class="nav-xs-link "><a href="http://www.amazon.co.uk/Help/b/ref=topnav_help?ie=UTF8&node=471044" class="nav_a">Help</a></li>
                    
      </ul>

      
        <div id="welcomeRowTable" style="height:50px">
        <!--[if IE ]><div class='nav-ie-min-width' style='width: 770px'></div><![endif]-->
        <div id="nav-ad-background-style" style="background-position: -800px 0px; background-image: url(http://g-ecx.images-amazon.com/images/G/02/Q4_2012/JanDeals/uk-x-site_17-12-12-jan-deals_swms._V398264144_.png);  height: 56px; margin-bottom: -6px; position: relative;background-repeat: no-repeat;">
          <div id="navSwmSlot">
            <div id="navSwmHoliday" style="background-image: url(http://g-ecx.images-amazon.com/images/G/02/Q4_2012/JanDeals/uk-x-site_17-12-12-jan-deals_swms._V398264144_.png); width: 300px; height: 50px; ">

 <img alt="January Deals" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/transparent-pixel._V167145160_.gif" border="0" width="300px" height="50px" usemap="#nav-swm-holiday-map"> </div>

<div style="display: none;">
<map id="nav-swm-holiday-map" name="nav-swm-holiday-map">
    <area shape="rect" coords="1,2,300,50" href="http://www.amazon.co.uk/deals-offers-savings/b/ref=swm_jandeals_grphc?ie=UTF8&node=350613011&pf_rd_p=361734427&pf_rd_s=nav-sitewide-msg&pf_rd_t=4201&pf_rd_i=navbar-4201&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" alt="January Deals">
</map>
</div>
          </div>
        </div>
      </div>

      <div style="clear: both;"></div>
    </div>

    <div id="nav-bar-outer">

      <div id="nav-logo-borderfade"><div class="nav-fade-mask"></div><div class="nav-fade nav-sprite"></div></div>

      <div id="nav-bar-inner" class="nav-sprite">

        <a id="nav-shop-all-button" href="http://www.amazon.co.uk/gp/site-directory/ref=topnav_sad" class="nav_a nav-button-outer nav-menu-active" alt="Shop By Department">
          <span class="nav-button-mid nav-sprite">
            <span class="nav-button-inner nav-sprite">
              <span class="nav-button-title nav-button-line1">Shop by</span>
              <span class="nav-button-title nav-button-line2">Department</span>
            </span>
          </span>
          <span class="nav-down-arrow nav-sprite"></span>
        </a>

                  <label id="nav-search-label" for="twotabsearchtextbox">
            Search
          </label>
        
        <div>
          <form action="http://www.amazon.co.uk/s/ref=nb_sb_noss" method="get" name="site-search" class="nav-searchbar-inner">
          

            <span id="nav-search-in" class="nav-sprite nav-facade-active" style="width: auto;">
              <span id="nav-search-in-content" data-value="search-alias=digital-text" style="width: auto; overflow: visible;">
                Kindle Store
              </span>
              <span class="nav-down-arrow nav-sprite"></span>
              <select name="url" id="searchDropdownBox" class="searchSelect" title="Search in" style="top: 0px;"><option value="search-alias=aps">All Departments</option><option value="search-alias=baby">Baby</option><option value="search-alias=beauty">Beauty</option><option value="search-alias=stripbooks">Books</option><option value="search-alias=automotive">Car &amp; Motorbike</option><option value="search-alias=classical">Classical</option><option value="search-alias=clothing">Clothing</option><option value="search-alias=computers">Computers &amp; Accessories</option><option value="search-alias=diy">DIY &amp; Tools</option><option value="search-alias=electronics">Electronics &amp; Photo</option><option value="search-alias=dvd">Film &amp; TV</option><option value="search-alias=outdoor">Garden &amp; Outdoors</option><option value="search-alias=grocery">Grocery</option><option value="search-alias=drugstore">Health &amp; Beauty</option><option value="search-alias=jewelry">Jewellery</option><option value="search-alias=digital-text" selected="selected">Kindle Store</option><option value="search-alias=kitchen">Kitchen &amp; Home</option><option value="search-alias=appliances">Large Appliances</option><option value="search-alias=lighting">Lighting</option><option value="search-alias=digital-music">MP3 Music</option><option value="search-alias=popular">Music</option><option value="search-alias=mi">Musical Instruments &amp; DJ</option><option value="search-alias=videogames">PC &amp; Video Games</option><option value="search-alias=pets">Pet Supplies</option><option value="search-alias=shoes">Shoes &amp; Accessories</option><option value="search-alias=software">Software</option><option value="search-alias=sports">Sports &amp; Outdoors</option><option value="search-alias=office-products">Stationery &amp; Office Supplies</option><option value="search-alias=toys">Toys &amp; Games</option><option value="search-alias=vhs">VHS</option><option value="search-alias=watches">Watches</option></select>
            </span>

            <div class="nav-searchfield-outer nav-sprite">
              <div class="nav-searchfield-inner nav-sprite">
                <div class="nav-searchfield-width" style="padding-left: 90px;">
                  <div id="nav-iss-attach">
                    <input type="text" id="twotabsearchtextbox" title="Search For" value="" name="field-keywords" autocomplete="off" style="padding-right: 0px;">
                  </div>
                </div>
                <!--[if IE ]><div class='nav-ie-min-width' style='width: 360px'></div><![endif]-->
              </div>
            </div>

            <div class="nav-submit-button nav-sprite">
              <input type="submit" value="Go" class="nav-submit-input" title="Go">
            </div>

          </form>
        </div>

        <a id="nav-your-account" href="https://www.amazon.co.uk/ap/signin?_encoding=UTF8&openid.assoc_handle=gbflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.uk%2Fgp%2Fcss%2Fhomepage.html%3Fie%3DUTF8%26ref_%3Dgno_yam_ya" class="nav_a nav-button-outer nav-menu-active" alt="Your Account">
          <span class="nav-button-mid nav-sprite">
            <span class="nav-button-inner nav-sprite">
              <span id="nav-signin-title" class="nav-button-title nav-button-line1">
                Hello.
                <span id="nav-signin-text" class="nav-button-em">Sign in</span>
              </span>
              <span class="nav-button-title nav-button-line2">Your Account</span>
            </span>
          </span>
          <span class="nav-down-arrow nav-sprite"></span>
        </a>

          <span class="nav-divider nav-divider-prime"></span>

          <a id="nav-your-prime" href="http://www.amazon.co.uk/gp/prime/ref=nav_menu" class="nav_a nav-button-outer nav-menu-active" alt="Join Prime">
            <span class="nav-button-mid nav-sprite">
              <span class="nav-button-inner nav-sprite">
                <span class="nav-button-title nav-button-line1">Join</span>
                <span class="nav-button-title nav-button-line2">Prime</span>
              </span>
            </span>
            <span class="nav-down-arrow nav-sprite"></span>
          </a>

          <span class="nav-divider nav-divider-account"></span>

          <a id="nav-cart" href="http://www.amazon.co.uk/gp/cart/view.html/ref=gno_cart" class="nav_a nav-button-outer nav-menu-active" alt="Basket">
            <span class="nav-button-mid nav-sprite">
              <span class="nav-button-inner nav-sprite">

                <span class="nav-button-title nav-button-line1"> </span>
                <span class="nav-button-title nav-button-line2">Basket</span>

                <span class="nav-cart-button nav-sprite"></span>
                <span id="nav-cart-count" class="nav-cart-0">0</span>

              </span>
            </span>
            <span class="nav-down-arrow nav-sprite"></span>
          </a>

          <span class="nav-divider nav-divider-cart"></span>

          <a id="nav-wishlist" href="http://www.amazon.co.uk/gp/registry/wishlist/ref=wish_list" class="nav_a nav-button-outer nav-menu-active" alt="Wish List">
            <span class="nav-button-mid nav-sprite">
              <span class="nav-button-inner nav-sprite">
                <span class="nav-button-title nav-button-line1">Wish</span>
                <span class="nav-button-title nav-button-line2">List</span>
              </span>
            </span>
            <span class="nav-down-arrow nav-sprite"></span>
          </a>

          <!-- nav-displayAggregator-category -->
          <!-- nav-displayAggregator-subnav -->
          <ul id="nav-subnav">
            <li class="nav-subnav-item nav-category-button">
              <a href="http://www.amazon.co.uk/kindle-store-ebooks-newspapers-blogs/b/ref=topnav_storetab_kinh?ie=UTF8&node=341677031" class="nav_a">
                Kindle Store
              </a>
            </li>

                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/gp/product/B007HCCOD0/ref=sv_kinh_0" class="nav_a">
                   Buy&nbsp;A Kindle
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/Kindle-eBooks/b/ref=sv_kinh_1?ie=UTF8&node=341689031" class="nav_a">
                   Kindle Books
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/b/ref=sv_kinh_2?ie=UTF8&node=2092391031" class="nav_a">
                   Newsstand
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/b/ref=sv_kinh_3?ie=UTF8&node=426479031" class="nav_a">
                   Accessories
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/tag/kindle/forum/ref=sv_kinh_4" class="nav_a">
                   Discussions
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/gp/digital/fiona/manage/ref=sv_kinh_5" class="nav_a">
                   Manage Your&nbsp;Kindle
                  </a>
                </li>
                <li class="nav-subnav-item ">
                  <a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=sv_kinh_6?ie=UTF8&nodeId=200487800" class="nav_a">
                   Kindle Support
                  </a>
                </li>

          </ul>

      </div>
    </div>

    
  </div>
</header>

<!-- nav promo cached -->


<map name="nav_imgmap_mp3" id="nav_imgmap_mp3">
<area shape="rect" coords="0,0,460,472" href="http://www.amazon.co.uk/what-is-cloud-player/b/ref=nav_sap_mp3?ie=UTF8&node=1954070031" alt="Learn more">
</map>



<map name="nav_imgmap_baby-kids-toys" id="nav_imgmap_baby-kids-toys">
<area shape="rect" coords="0,0,460,472" href="http://www.amazon.co.uk/gp/family/signup/welcome/ref=nav_sap_family" alt="Join now">
</map>



<map name="nav_imgmap_clothes-shoes-watches" id="nav_imgmap_clothes-shoes-watches">
<area shape="rect" coords="1,342,77,362" href="http://www.amazon.co.uk/b/ref=clo_fly_menwinteressentials_seemore?ie=UTF8&node=2468119031" alt="See more">
<area shape="rect" coords="1,363,108,384" href="http://www.amazon.co.uk/Clothing-Fashion-Women-Men-Kids/b/ref=clo_fly_menwinteressentials_shopall?ie=UTF8&node=83450031" alt="Shop All Clothing">
</map>



<map name="nav_imgmap_placeholder" id="nav_imgmap_placeholder">
</map>




<script type="text/javascript"><!--
_navbar.dynamicMenuUrl = '/gp/navigation/ajax/dynamicmenu.html';

_navbar.dismissNotificationUrl = '/gp/navigation/ajax/dismissnotification.html';

_navbar.dynamicMenus = false;

_navbar.yourAccountClickable = true;

_navbar.readyOnATF = false;

_navbar.abbrDropdown = true;











    if (typeof uet == 'function') {
      uet('bb', 'iss-init-pc', {wb: 1});
    }
    
    var iss
    // BEGIN Deprecated globals
      , issHost = "completion.amazon.co.uk/search/complete"
      , issMktid = "3"
      , issSearchAliases = ["aps", "stripbooks", "dvd", "electronics", "popular", "videogames", "toys", "kitchen", "shoes", "clothing", "sports", "drugstore", "baby", "classical", "software", "diy", "outdoor", "vhs", "software-videogames", "hd-dvd", "blu-ray", "garden", "tools", "jewelry", "watches", "music-song", "mp3-downloads", "digital-music", "digital-music-track", "digital-music-album", "digital-text", "lighting", "automotive", "beauty", "office-products", "outlet", "apparel-outlet", "shoes-outlet", "watches-outlet", "jewelry-outlet", "grocery", "computers", "pets", "mi", "videogames-tradein", "appliances", "mobile-apps"]
      , updateISSCompletion = function() { iss.updateAutoCompletion(); };
    // END deprecated globals
    amznJQ.available('search-js-autocomplete', function() {
      iss = new AutoComplete({
        src: issHost,
        mkt: issMktid,
        aliases: issSearchAliases,
        fb: 1,
        dupElim: 0,
        deptText: 'in {department}',
        sugText: 'Search suggestions',
        sc: 1,
        ime: 0,
        imeEnh: 0,
        isNavInline: 1,
        iac: 0,
        scs: 0
      });
      if (typeof uet == 'function' && typeof uex == 'function' ) {
        uet('be', 'iss-init-pc', {wb: 1});
        uex('ld', 'iss-init-pc', {wb: 1});
      }
    });



    amznJQ.declareAvailable('navbarInline');
    amznJQ.available('jQuery', function() {
        amznJQ.available('navbarJS-beacon', function(){});
    });




    _navbar._endSpriteImage = new Image();
    _navbar._endSpriteImage.onload = function() {_navbar.componentLoaded(); };
    _navbar._endSpriteImage.src = window._navbarSpriteUrl;






 _navbar.browsepromos['mp3'] = {"width":460,"promoType":"wide","vertOffset":"-10","horizOffset":"-15","height":472,"image":"http://g-ecx.images-amazon.com/images/G/02/uk-mp3/other/GNO_MP3_KindleUpdate_460x472_RS._V399786585_.png"}; 
 _navbar.browsepromos['baby-kids-toys'] = {"width":460,"promoType":"wide","vertOffset":"-10","horizOffset":"-15","height":418,"image":"http://g-ecx.images-amazon.com/images/G/02/uk-family/gno/uk_family_GNO_Flyout._V398577926_.png"}; 
 _navbar.browsepromos['clothes-shoes-watches'] = {"width":460,"promoType":"wide","vertOffset":"0","horizOffset":"0","height":426,"image":"http://g-ecx.images-amazon.com/images/G/02/uk_softlines/2012/clothing/gateway/flyout/uk-size/winter-essential_fo._V396543553_.png"}; 
 _navbar.browsepromos['placeholder'] = {"width":1,"promoType":"wide","vertOffset":0,"horizOffset":0,"height":1,"image":"http://g-ecx.images-amazon.com/images/G/02/x-locale/common/transparent-pixel._V167145160_.gif"}; 

 amznJQ.declareAvailable('navbarPromosContent');
--></script>

<!--Tilu -->


<!-- EndNav -->


 
 
 




<div class="site-stripe-margin-control">

</div>







<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleDeviceTequilaCSS-2784423526._V1_.css" rel="stylesheet">


<script type="text/javascript">

window.AmazonPopoverImages = {
  snake: 'http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/snake._V192571611_.gif',
  btnClose: 'http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/btn_close._V192188154_.gif',
  closeTan: 'http://g-ecx.images-amazon.com/images/G/02/nav2/images/close-tan-sm._V192198775_.gif',
  closeTanDown: 'http://g-ecx.images-amazon.com/images/G/02/nav2/images/close-tan-sm-dn._V192263238_.gif',
  loadingBar: 'http://g-ecx.images-amazon.com/images/G/01/javascripts/lib/popover/images/loading-bar-small._V192188123_.gif',
  pixel: 'http://g-ecx.images-amazon.com/images/G/01/icons/blank-pixel._V192192429_.gif'
};
var container = document.createElement("DIV");
container.id = "ap_container";
if (document.body.childNodes.length) {
    document.body.insertBefore(container, document.body.childNodes[0]);
} else {
    document.body.appendChild(container);
}

</script>

    <script type="text/javascript">
    (function() {
        var h = document.head || document.getElementsByTagName('head')[0] || document.documentElement;
        var s = document.createElement('script');
        s.async = 'async';
        s.src = 'http://z-ecx.images-amazon.com/images/G/01/browser-scripts/site-wide-js-1.2.6-beacon/site-wide-11366246298._V1_.js';
        h.insertBefore(s, h.firstChild);
     })();
    </script>
<script type="text/javascript">
    amznJQ.addLogical('popover', []);
    amznJQ.addLogical('navbarCSSUK-beacon', []);
    amznJQ.addLogical('search-js-autocomplete', []);
    amznJQ.addLogical('navbarJS-beacon', []);
    amznJQ.addLogical('dpProductImage', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/dpProductImage/dpProductImage-2900646310._V1_.js"]);
    amznJQ.addLogical('LBHUCCSS-GB', []);
    amznJQ.addLogical('CustomerPopover', ["http://z-ecx.images-amazon.com/images/G/02/x-locale/communities/profile/customer-popover/script-13-min._V234365288_.js"]);
    amznJQ.addLogical('amazonShoveler', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/amazonShoveler/amazonShoveler-1466453065._V1_.js"]);
    amznJQ.addLogical('dpCSS', []);
    amznJQ.addLogical('kindleDeviceCSS', []);
    amznJQ.addLogical('kindleDeviceCSSExtended', []);
    amznJQ.addLogical('kindleFamilyStripeCSS', []);
    amznJQ.addLogical('discussionsCSS', []);
    amznJQ.addLogical('bxgyCSS', []);
    amznJQ.addLogical('simCSS', []);
    amznJQ.addLogical('condProbCSS', []);
    amznJQ.addLogical('ciuAnnotations', []);
    amznJQ.addLogical('kindleDeviceJS', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/kindleDeviceJS/kindleDeviceJS-3148455776._V1_.js"]);
    amznJQ.addLogical('kindleDeviceTequilaCSS', []);
    amznJQ.addLogical('kindleDeviceTequilaJS', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/kindleDeviceTequilaJS/kindleDeviceTequilaJS-1151229296._V1_.js"]);
</script>







   
    

    
    







    
    
    
    


    
    
    


    
  
    
  
   

   


  
  
    
    
    




<div class="site-stripe-margin-control"><div style="background-image:url(https://images-na.ssl-images-amazon.com/images/G/01/kindle/merch/x-site/site-stripes/kindle-holiday-background.jpg);background-repeat:x-repeat;width:100%;text-align:center;font-weight:bold;font-size:12px;padding:5px 0">Live outside the UK?  Kindle Touch is available on Amazon.com for shipment outside the UK. <a href="http://www.amazon.co.uk/gp/redirect.html/ref=amb_link_163267747_1?location=http://www.amazon.com/dp/B005890FUI&token=3A0F170E7CEFE27BDC730D3D7344512BC1296B83&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ&pf_rd_t=201&pf_rd_p=286546887&pf_rd_i=B005890FUI">Click here</a> to shop on Amazon.com. 
     </div>
 
 
 
 


 
 

 




 

 



 
<div id="kfs-container" style="height: 185px;">
<!--[if IE]>
<div class="kfs-min-width-ie-fix"></div>
<![endif]-->
<div id="kfs-control-container">
    <div id="kfs-slide-control">


 
 
            <div class="kfs-bg-container" style="left: 0;background-image: url(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/stripe/kfs-background-stripe-1x185._V135515999_.jpg&#39;);"> 
  
<div class="kfs-inner-container kfs-front-title-container " style="width: 180px; ">
    <div class="kfs-title kfs-front-title" style="background-image: url(http://g-ecx.images-amazon.com/images/G/02/kindle/dp/2012/famStripe/e-ink-title-new._V402449382_.jpg);background-position: -11px center"></div>


</div>


  <!--[if IE]>
  <style type="text/css">
    #kfs-item-container0 {
        width: expression(this.offsetParent.clientWidth - 180 - 0 + "px");
    }
  </style>
  <![endif]-->
  
    <div class="kfs-item-container" id="kfs-item-container0" style="left:180px; right: 0px;">
  
<div id="kfs_family_0" class="kfs-inner-container " style="width: 18.9873417721519%; left: 0%; " onclick="javascript:(function(){ window.location=&#39;/gp/product/B008UAAE44/ref=famstripe_kt&#39;;})()">
    <a class="kfs-link" href="http://www.amazon.co.uk/gp/product/B008UAAE44/ref=famstripe_kt">
    <img class="kfs-img" style="margin-top: 11px;" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/FS-KT._V389389357_.gif">
    <br>
    Kindle Fire HD
    <br>
    <span class="kfs-price">
    from 
    </span>
    <br>
    </a>
     <div id="kfs_popover_content_0" class="kfs-popover-container" style="display:none;"><div style="white-space:nowrap;">Stunning HD, Dolby Audio, Ultra-fast Wi-Fi</div></div> 
</div>

    <div class="kfs-inner-container" style="width: 0%; left: 18.9873417721519%;">&nbsp;</div>
   
 
 

<div id="kfs_family_1" class="kfs-inner-container " style="width: 18.9873417721519%; left: 18.9873417721519%; " onclick="javascript:(function(){ window.location=&#39;/gp/product/B008GG0GBI/ref=famstripe_kO2&#39;;})()">
    <a class="kfs-link" href="http://www.amazon.co.uk/gp/product/B008GG0GBI/ref=famstripe_kO2">
    <img class="kfs-img" style="margin-top: 11px;" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/FS-KO2._V389389395_.gif">
    <br>
    Kindle Fire
    <br>
    <span class="kfs-price">
    from 
    </span>
    <br>
    </a>
     <div id="kfs_popover_content_1" class="kfs-popover-container" style="display:none;">Vibrant colour, movies, web, apps and more</div> 
</div>

    <div class="kfs-inner-container kfs-divider" style="width: 2.53164556962025%; left: 37.9746835443038%; background-image: url(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/stripe/kfs-vert-bar._V154237230_.png&#39;);">&nbsp;</div> 
   
 
 

<div id="kfs_family_2" class="kfs-inner-container " style="width: 18.9873417721519%; left: 40.5063291139241%; " onclick="javascript:(function(){ window.location=&#39;/gp/product/B007OZNWRC/ref=famstripe_clw&#39;;})()">
    <a class="kfs-link" href="http://www.amazon.co.uk/gp/product/B007OZNWRC/ref=famstripe_clw">
    <img class="kfs-img" style="margin-top: 11px;" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/FS-KCW-125._V385941796_.gif">
    <br>
    Kindle Paperwhite 3G
    <br>
    <span class="kfs-price">
       </span>
    <br>
    </a>
     <div id="kfs_popover_content_2" class="kfs-popover-container" style="display: none;">Higher resolution, higher contrast Paperwhite touchscreen with built-in light, Wi-Fi, and free 3G wireless</div> 
</div>

    <div class="kfs-inner-container" style="width: 0%; left: 59.493670886076%;">&nbsp;</div>
   
 
 

<div id="kfs_family_3" class="kfs-inner-container " style="width: 18.9873417721519%; left: 59.493670886076%; " onclick="javascript:(function(){ window.location=&#39;/gp/product/B007OZO03M/ref=famstripe_cl&#39;;})()">
    <a class="kfs-link" href="http://www.amazon.co.uk/gp/product/B007OZO03M/ref=famstripe_cl">
    <img class="kfs-img" style="margin-top: 11px;" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/FS-KC-125._V385941796_.gif">
    <br>
    Kindle Paperwhite
    <br>
    <span class="kfs-price">
    
    </span>
    <br>
    </a>
     <div id="kfs_popover_content_3" class="kfs-popover-container" style="display:none;">Higher resolution, higher contrast Paperwhite touchscreen display with built-in light and Wi-Fi</div> 
</div>

    <div class="kfs-inner-container" style="width: 0%; left: 78.4810126582279%;">&nbsp;</div>
   
 
 

<div id="kfs_family_4" class="kfs-inner-container " style="width: 18.9873417721519%; left: 78.4810126582279%; " onclick="javascript:(function(){ window.location=&#39;/gp/product/B007HCCOD0/ref=famstripe_ks&#39;;})()">
    <a class="kfs-link" href="http://www.amazon.co.uk/gp/product/B007HCCOD0/ref=famstripe_ks">
    <img class="kfs-img" style="margin-top: 11px;" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/FS-KS._V389397116_.gif">
    <br>
    Kindle
    <br>
    <span class="kfs-price">
    </span>
    <br>
    </a>
     <div id="kfs_popover_content_4" class="kfs-popover-container" style="display:none;">Light, small and fast, with built-in Wi-Fi</div> 
</div>
</div> 
</div>


    </div>
    </div>




<div id="kfs-chart0" class="kfs-chart" style="top: 183px; right: 0px;">
    <table class="kfs-chart-table">
    <colgroup>
    <col style="width:180px">
    <col style="width: 19.4805194805195%;">
    <col style="width: 20.7792207792208%;">
    <col style="width: 20.7792207792208%;">
    <col style="width: 19.4805194805195%;">
    <col style="width: 19.4805194805195%;">
    </colgroup>
    <tbody>
    
    <tr class="kfs-chart-table-row ">
        <th>Neque</th>
        <td colspan="4">At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis.</td>
        <td colspan="3" class="last">At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis.</td>
    </tr>
    <tr class="kfs-chart-table-row odd">
        <th>Porro Quisquam</th>
        <td>2"</td>
        <td>9"</td>
        <td class="last">1"</td>
    </tr>
    <tr class="kfs-chart-table-row ">
        <th>Est</th>
        <td>8-Nam Libero</td>
        <td>Deleniti-atque</td>
        <td class="last">Deleniti-atque</td>
    </tr>
    <tr class="kfs-chart-table-row odd">
        <th>Sed &amp; Quia</th>
        <td>Ab-Illo</td>
        <td>Ab-Illo</td>
        <td class="last">Dolorem 5Q + Ab-Illo</td>
    </tr>

    
    </tbody>

    </table>
    
    <div class="kfs-chart-bottom-container">
        <div class="kfs-chart-to-full-chart"><a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#kindle-compare">Full Comparison Chart</a></div>
        <div class="kfs-chart-close">
            Close
            <span class="kfs-chart-close-image">&nbsp;</span>
        </div>
    </div>
</div>
</div>

<script type="text/javascript">
    amznJQ.available('jQuery', function () {
        
    });
    amznJQ.available('kindleFamilyStripeJS', function(){
        KDS.common.FamilyStripe.setCurrentStripeIndex(0);        
    });
</script>
</div><br>
<div class="kitsune-atf">





<form method="post" id="handleBuy" name="handleBuy" action="http://www.amazon.co.uk/gp/digital/fiona/turing-handle-buy-box.html/ref=dp_start-bbf_1_glance" style="margin: 0pt;">

<input type="hidden" id="session-id" name="session-id" value="277-6643056-3126939">
<input type="hidden" id="ASIN" name="ASIN" value="B005890FUI">
<input type="hidden" id="isMerchantExclusive" name="isMerchantExclusive" value="0">
<input type="hidden" id="merchantID" name="merchantID" value="">
<input type="hidden" id="nodeID" name="nodeID" value="341687031">
<input type="hidden" id="offerListingID" name="offerListingID" value="">
<input type="hidden" id="sellingCustomerID" name="sellingCustomerID" value="">
<input type="hidden" id="sourceCustomerOrgListID" name="sourceCustomerOrgListID" value="">
<input type="hidden" id="sourceCustomerOrgListItemID" name="sourceCustomerOrgListItemID" value="">
<input type="hidden" id="qid" name="qid" value="">
<input type="hidden" id="sr" name="sr" value="">
<input type="hidden" id="storeID" name="storeID" value="fiona-hardware">
<input type="hidden" id="tagActionCode" name="tagActionCode" value="">
<input type="hidden" id="viewID" name="viewID" value="glance">




<table border="0" cellpadding="0" cellspacing="0" width="215" class="buyingDetailsGrid" align="right">

<tbody><tr><td valign="top" width="100%">
  


    





  





    
































    





  
    

  
  

    

    


    










    

    
  
    
  
    </td></tr><tr><td valign="top" width="100%">


    
    
    
    
    
    



    



    
    



    
    









<div class="cBox buyTopBox">
  <span class="cBoxTL"><!-- &nbsp; --></span>
  <span class="cBoxTR"><!-- &nbsp; --></span>
  <span class="cBoxR"><!-- &nbsp; --></span>
  <div class="mbcContainer cBoxInner">
    <div>




<div id="secondaryUsedAndNew" class="mbcOlp" style="text-align:center;">


<div class="mbcOlpLink"><a class="buyAction" href="http://www.amazon.co.uk/gp/offer-listing/B005890FUI/ref=dp_olp_refurbished_mbc?ie=UTF8&condition=refurbished">1&nbsp;refurbished</a>&nbsp;from&nbsp;<span class="price">64.99</span></div><div class="extendedBuyBox" style="text-align: center;"><a class="dpSprite s_seeAllBuying " href="http://www.amazon.co.uk/gp/offer-listing/B005890FUI/ref=dp_olp_refurbished_mbc?ie=UTF8&condition=refurbished" title="See All Buying Options"><span>See All Buying Options</span></a></div>

</div>

















    </div>
  </div>
</div>


    



<div class="cBox buyBottomBox">
  <span class="cBoxR"><!-- &nbsp; --></span>
  <span class="cBoxBL"><!-- &nbsp; --></span>
  <span class="cBoxBR"><!-- &nbsp; --></span>
  <span class="cBoxB"><!-- &nbsp; --></span>
  <div class="mbcContainer cBoxInner">





<div class="GFTButtonCondo" style="display: block;">
<input type="hidden" name="rsid" value="277-6643056-3126939">

       <div align="center" style="padding: 4px"><input border="0" type="image" title="Add to Wish List" alt="Add to Wish List" class="dpSprite s_add2WishList" id="" value="" name="submit.add-to-registry.wishlist" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/transparent-pixel._V167145160_.gif"></div>

</div>

  </div>
</div>  






</td></tr><tr><td valign="top" width="100%">

</td></tr><tr><td valign="top" width="100%">


    
    
      

    



  
  
  




<div style="text-align: center;padding:5px;">






<div id="tafContainerDiv"><a href="http://www.amazon.co.uk/gp/pdp/taf/ref=cm_sw_l_view_dp_1779qb0GDW74N?ie=UTF8&contentID=B005890FUI&contentName=item&contentType=asin&contentURI=%2Fdp%2FB005890FUI&emailCaptionStrID=&emailCustomMsgStrID=&emailDescStrID=&emailImageURL=&emailSubjectStrID=&emailTemplate=%2Fgp%2Fpdp%2Fcommon%2Femail%2Fshare-product&eventID=&imageURL=&isDynamicSWF=0&itemInfo=B005890FUI&learnMoreButton=&merchantID=&params=&parentASIN=B005890FUI&placementID=dp_1779qb0GDW74N&referer=http%253A%252F%252Fwww.amazon.co.uk%252Fgp%252Fproduct%252FB005890FUI%252Fref%253D&relatedAccounts=amazondeals%2Camazonmp3&suppressPurchaseReqLogin=&titleText=&type=SH&viaAccount=amazon" title="Share on E-Mail" id="swftext" class="vam"><span class="tafShareText">Share</span></a><a href="http://www.amazon.co.uk/gp/pdp/taf/ref=cm_sw_l_view_dp_1779qb0GDW74N?ie=UTF8&contentID=B005890FUI&contentName=item&contentType=asin&contentURI=%2Fdp%2FB005890FUI&emailCaptionStrID=&emailCustomMsgStrID=&emailDescStrID=&emailImageURL=&emailSubjectStrID=&emailTemplate=%2Fgp%2Fpdp%2Fcommon%2Femail%2Fshare-product&eventID=&imageURL=&isDynamicSWF=0&itemInfo=B005890FUI&learnMoreButton=&merchantID=&params=&parentASIN=B005890FUI&placementID=dp_1779qb0GDW74N&referer=http%253A%252F%252Fwww.amazon.co.uk%252Fgp%252Fproduct%252FB005890FUI%252Fref%253D&relatedAccounts=amazondeals%2Camazonmp3&suppressPurchaseReqLogin=&titleText=&type=SH&viaAccount=amazon" title="Share on E-Mail" class="linkImage" id="swftext_img"><span class="tafEmailIcon vam"></span></a><a href="http://www.amazon.co.uk/gp/redirect.html/ref=cm_sw_cl_fa_dp_1779qb0GDW74N?_encoding=UTF8&location=http%3A%2F%2Fwww.facebook.com%2Fshare.php%3Fu%3Dhttp%253A%252F%252Fwww.amazon.co.uk%252Fdp%252FB005890FUI%252Fref%253Dcm_sw_r_fa_dp_1779qb0GDW74N&token=6BD0FB927CC51E76FF446584B1040F70EA7E88E1" target="_blank" title="Share on Facebook" onclick="window.open(this.href, &#39;_blank&#39;, &#39;location=yes,width=700,height=400&#39;);return false;"><span class="tafSocialButton vam" style="background-position: -18px 0px; height: 16px; width: 16px;;"></span></a><a href="http://www.amazon.co.uk/gp/redirect.html/ref=cm_sw_cl_tw_dp_1779qb0GDW74N?_encoding=UTF8&location=http%3A%2F%2Ftwitter.com%2Fintent%2Ftweet%3Foriginal_referer%3Dhttp%25253A%25252F%25252Fwww.amazon.co.uk%25252Fgp%25252Fproduct%25252FB005890FUI%25252Fref%25253Dcm_sw_r_tw_dp_1779qb0GDW74N%26related%3Damazondeals%252Camazonmp3%26text%3DKindle%2520Touch%252C%2520Wi-Fi%252C%25206%2522%2520E%2520Ink%2520Touch%2520Screen%2520Display%2520by%2520Amazon%26url%3Dhttp%253A%252F%252Fwww.amazon.co.uk%252Fdp%252FB005890FUI%252Fref%253Dcm_sw_r_tw_dp_1779qb0GDW74N%26via%3Damazon&token=7A1A4AE8F6CE0BD277D8295E58702D283F329C0F" target="_blank" title="Share on Twitter" onclick="window.open(this.href, &#39;_blank&#39;, &#39;location=yes,width=700,height=400&#39;);return false;"><span class="tafSocialButton vam" style="background-position: -34px 0px; height: 16px; width: 16px;;"></span></a><a href="http://www.amazon.co.uk/gp/redirect.html/ref=cm_sw_cl_pi_dp_1779qb0GDW74N?_encoding=UTF8&location=http%3A%2F%2Fpinterest.com%2Fpin%2Fcreate%2Fbutton%2F%3Fdescription%3DKindle%2520Touch%252C%2520Wi-Fi%252C%25206%2522%2520E%2520Ink%2520Touch%2520Screen%2520Display%2520by%2520Amazon%252C%2520http%253A%252F%252Fwww.amazon.co.uk%252Fdp%252FB005890FUI%252Fref%253Dcm_sw_r_pi_dp_1779qb0GDW74N%26media%3Dhttp%253A%252F%252Fecx.images-amazon.com%252Fimages%252FI%252F41JpsttW8CL._SL500_.jpg%26title%3DKindle%2520Touch%252C%2520Wi-Fi%252C%25206%2522%2520E%2520Ink%2520Touch%2520Screen%2520Display%2520by%2520Amazon%26url%3Dhttp%253A%252F%252Fwww.amazon.co.uk%252Fdp%252FB005890FUI%252Fref%253Dcm_sw_r_pi_dp_1779qb0GDW74N&token=9F58B366258E1A8B5259E9BEF3482E02341F42D3" target="_blank" title="Share on Pinterest" onclick="window.open(this.href, &#39;_blank&#39;, &#39;location=yes,width=700,height=570&#39;);return false;"><span class="tafSocialButton vam" style="background-position: -50px 0px; height: 16px; width: 16px;;"></span></a></div>

<script language="JavaScript" type="text/JavaScript">
if (typeof window.amznJQ != 'undefined') {
  amznJQ.onCompletion('amznJQ.criticalFeature', function() {
    amznJQ.available("share-with-friends-js-new", function() {
      var popoverParams = { url: "/gp/pdp/taf/dpPop.html/ref=cm_sw_p_view_dp_1779qb0GDW74N?ie=UTF8&contentID=B005890FUI&contentName=item&contentType=asin&contentURI=%2Fdp%2FB005890FUI&emailCaptionStrID=&emailCustomMsgStrID=&emailDescStrID=&emailSubjectStrID=&emailTemplate=%2Fgp%2Fpdp%2Fcommon%2Femail%2Fshare-product&forceSprites=1&id=B005890FUI&imageURL=&isDynamicSWF=0&isEmail=0&learnMoreButton=&merchantID=&parentASIN=B005890FUI&placementID=dp_1779qb0GDW74N&ra=taf&referer=http%253A%252F%252Fwww.amazon.co.uk%252Fgp%252Fproduct%252FB005890FUI%252Fref%253D&relatedAccounts=amazondeals%2Camazonmp3&suppressPurchaseReqLogin=&titleText=&tt=sh&viaAccount=amazon", title: "Share this item via e-mail" , closeText: "Close", isCompact:  false};
      amz_taf_triggers.swftext = popoverParams;
      amz_taf_generatePopover("swftext", false);
    });
  });
}

</script>













 
 
</div>







</td></tr><tr><td valign="top" width="100%"></td></tr></tbody></table>



<table border="0" cellpadding="0" cellspacing="0" width="240" class="productImageGrid" align="left">

<tbody><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"> 
 
 

 
 
 




<script type="text/javascript">
    amznJQ.addLogical("swfobject-2.2", ["http://z-ecx.images-amazon.com/images/G/02/media/swf/amznjq-swfobject-2.2._V184869195_.js"]);
</script> 
</td></tr><tr><td valign="top" width="100%">
 




 
 



 
 

 




 

 




 



<div id="kib-container" style="width: 500px; text-align: center;">









<style>

a.slateLink:link{ color: rgb(119,119,119); text-decoration:none;}
a.slateLink:active { color: rgb(119,119,119); text-decoration:none;}
a.slateLink:visited{ color: rgb(119,119,119); text-decoration:none;}
a.slateLink:hover{ color: rgb(119,119,119); text-decoration:none;}

.shuttleGradient {
    float:left;
    width:100%;
    text-align:left;
    line-height: normal;
    position:relative;
    height:43px; 
    background-color:#dddddd; 
    background-image: url(http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/customerimage/shuttle-gradient._V192198912_.gif); 
    background-position: bottom; 
    background-repeat : repeat-x;
}

.shuttleTextTop {
    font-size:18px;
    font-weight:bold;
    font-family:verdana,arial,helvetica,sans-serif;
    color: rgb(119,119,119);
    margin-left:10px;
}

.shuttleTextBottom {
    margin-top:-2px;
    font-size:15px;
    font-family:verdana,arial,helvetica,sans-serif;
    color: rgb(119,119,119);
    margin-left:10px;
}
.outercenterslate{
    cursor:pointer;
}
.innercenterslate{
    overflow: hidden;
}

.slateoverlay{
    position: absolute;
    top: 0px;
    border: 0px
}

.centerslate {
    display: table-cell;
    background-color:black; 
    text-align: center;
    vertical-align: middle;
}
.centerslate * {
    vertical-align: middle;
}
.centerslate { display/*\**/: block\9 } 
/*\*//*/
.centerslate {
    display: block;
}
.centerslate span {
    display: inline-block;
    height: 100%;
    width: 1px;
}
/**/
</style>
<!--[if lt IE 9]><style>
.centerslate span {
    display: inline-block;
    height: 100%;
}
</style><![endif]-->
<style>
</style>

<script type="text/javascript">
amznJQ.addLogical("swfobject-2.2", ["http://z-ecx.images-amazon.com/images/G/02/media/swf/amznjq-swfobject-2.2._V184869195_.js"]);

window.AmznVideoPlayer=function(mediaObject,targetId,width,height){
  AmznVideoPlayer.players[mediaObject.mediaObjectId]=this;
  this.slateImageUrl=mediaObject.slateImageUrl;
  this.id=mediaObject.mediaObjectId;
  this.preplayWidth=width;
  this.preplayHeight=height;
  this.flashDivWidth=width;
  this.flashDivHeight=height;
  this.targetId=targetId;
  this.swfLoading=0;
  this.swfLoaded=0;
  this.preplayDivId='preplayDiv'+this.id;
  this.flashDivId='flashDiv'+this.id;
}

AmznVideoPlayer.players=[];
AmznVideoPlayer.session='277-6643056-3126939';
AmznVideoPlayer.root='http://www.amazon.co.uk';
AmznVideoPlayer.locale='en_GB';
AmznVideoPlayer.swf='http://g-ecx.images-amazon.com/images/G/01/am3/20120510035744301/AMPlayer._V148501545_.swf';
AmznVideoPlayer.preplayTemplate='<div style="width:0px;height:0px;" class="outercenterslate"><div style="width:0px;height:-43px;" class="centerslate" ><span></span><img border="0" alt="Click to watch this video" src="slateImageGoesHere"></div><div class="shuttleGradient"><div class="shuttleTextTop">Amazon</div><div class="shuttleTextBottom">Video</div><img id="mediaObjectIdpreplayImageId" style="height:74px;position:absolute;left:-31px;top:-31px;" src="http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/customerimage/play-shuttle-off._V192200344_.gif" border="0"/></div></div>';
AmznVideoPlayer.rollOn='http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/customerimage/play-shuttle-on._V192199034_.gif';
AmznVideoPlayer.rollOff='http://g-ecx.images-amazon.com/images/G/02/x-locale/communities/customerimage/play-shuttle-off._V192200344_.gif';
AmznVideoPlayer.flashVersion='9.0.115';
AmznVideoPlayer.noFlashMsg='To view this video download <a target="_blank" href="http://get.adobe.com/flashplayer/" target="_top">Flash Player</a> (version 9.0.115 or higher)';

AmznVideoPlayer.hideAll=function(){
  for(var i in AmznVideoPlayer.players){
    AmznVideoPlayer.players[i].hidePreplay();
    AmznVideoPlayer.players[i].hideFlash();
  }
}

AmznVideoPlayer.prototype.writePreplayHtml=function(){
  if(typeof this.preplayobject=='undefined'){
    this.preplayobject=jQuery(AmznVideoPlayer.preplayTemplate.replace("slateImageGoesHere",this.slateImageUrl)
        .replace("mediaObjectId",this.id).replace("-43px",(this.preplayHeight-43)+"px").replace("-31px",(Math.round(this.preplayWidth/2)-31)+"px"));
    this.preplayobject.width(this.preplayWidth+"px").height(this.preplayHeight+"px");
    this.preplayobject.find(".innercenterslate").width(this.preplayWidth+"px").height(this.preplayHeight+"px");
    this.preplayobject.find(".centerslate").width(this.preplayWidth+"px");
    var self=this;
    this.preparePlaceholder();
    jQuery("#"+this.preplayDivId).click(function(){self.preplayClick();});
    jQuery("#"+this.preplayDivId).hover(
        function(){jQuery("#"+self.id+'preplayImageId').attr('src',AmznVideoPlayer.rollOn);},
        function(){jQuery("#"+self.id+'preplayImageId').attr('src',AmznVideoPlayer.rollOff);});
    jQuery("#"+this.preplayDivId).html(this.preplayobject);
  }
}

AmznVideoPlayer.prototype.writeFlashHtml=function(){
  if(!this.swfLoaded&&!this.swfLoading){
    this.swfLoading=1;
    var params={'allowscriptaccess':'always','allowfullscreen':'true','wmode':'transparent','quality':'high'};
    var shiftJISRegExp = new RegExp("^https?:"+String.fromCharCode(0x5C)+"/"+String.fromCharCode(0x5C)+"/");
    var flashvars={'xmlUrl':AmznVideoPlayer.root+'/gp/mpd/getplaylist-v2/'+this.id+'/'+AmznVideoPlayer.session,
                   'mediaObjectId':this.id,'locale':AmznVideoPlayer.locale,'sessionId':AmznVideoPlayer.session,
                   'amazonServer':AmznVideoPlayer.root.replace(shiftJISRegExp,''),'swfEmbedTime':new Date().getTime(),
                   'allowFullScreen':'true','amazonPort':'80','preset':'detail','autoPlay':'1','permUrl':'gp/mpd/permalink','scale':'noscale'};
    var self=this;
    swfobject.embedSWF(AmznVideoPlayer.swf,'so_'+this.id,"100%","100%",AmznVideoPlayer.flashVersion,false,flashvars,params,params,
      function(e){
        self.swfLoading=0;
        if(e.success){AmznVideoPlayer.lastPlayedId=self.id;self.swfLoaded=1;return;}
        jQuery('#'+self.flashDivId).html('<br/><br/><br/><br/><br/><br/><br/>'+AmznVideoPlayer.noFlashMsg).css({'background':'#ffffff'});
      }
    );
  }
}

AmznVideoPlayer.prototype.showPreplay=function(){
  this.writePreplayHtml();
  this.preparePlaceholder();
  jQuery("#"+this.preplayDivId).show();
  return this;
}

AmznVideoPlayer.prototype.hidePreplay=function(){
  this.preparePlaceholder();
  jQuery("#"+this.preplayDivId).hide();
  return this;
}

AmznVideoPlayer.prototype.showFlash=function(){
  this.preparePlaceholder();
  if(!this.swfLoaded&&!this.swfLoading){
    var self=this;
    amznJQ.available("swfobject-2.2",function(){self.writeFlashHtml();});
  }
  jQuery("#"+this.flashDivId).width(this.flashDivWidth+'px').height(this.flashDivHeight+'px');
  AmznVideoPlayer.lastPlayedId=this.id;
  return this;
}

AmznVideoPlayer.prototype.hideFlash=function(){
  this.preparePlaceholder();
  jQuery("#"+this.flashDivId).width('0px').height('1px');
  return this;
}

AmznVideoPlayer.prototype.preparePlaceholder=function(){
  if(!(jQuery('#'+this.flashDivId).length)||!(jQuery('#'+this.preplayDivId))){
    var preplayDiv=jQuery("<div id='"+this.preplayDivId+"'></div>").css({'position':'relative'});
    var flashDiv=jQuery("<div id='"+this.flashDivId+"'><div id='so_"+this.id+"'/></div>").css({'overflow':'hidden',background:'#000000'});
    var wrapper=jQuery("<div/>").css({'position':'relative','float':'left'}).append(preplayDiv).append(flashDiv);
    jQuery('#'+this.targetId).html(wrapper);
  }
}

AmznVideoPlayer.prototype.resizeVideo=function(width,height){
  this.flashDivWidth=width;
  this.flashDivHeight=height;
  if (jQuery("#"+this.flashDivId)&&jQuery("#"+this.flashDivId).width()!=0){this.showFlash();}
}

AmznVideoPlayer.prototype.preplayClick=function(){ 
  if(this.swfLoaded){this.play();} 
  this.showFlash();
  this.hidePreplay();
}

AmznVideoPlayer.prototype.play=function(){
  var so=this.getSO();
  if(typeof so.playVideo=='function'){
    if(this.id!=AmznVideoPlayer.lastPlayedId){
      AmznVideoPlayer.players[AmznVideoPlayer.lastPlayedId].pause();
    }
    AmznVideoPlayer.lastPlayedId=this.id;so.playVideo();
  }
}

AmznVideoPlayer.prototype.pause=function(){if(this.swfLoading||this.swfLoaded){this.autoplayCancelled=true;}var so=this.getSO();if(so && typeof so.pauseVideo=='function'){so.pauseVideo();}}
AmznVideoPlayer.prototype.stop=function(){if(this.swfLoading||this.swfLoaded){this.autoplayCancelled=true;}var so=this.getSO();if(so && typeof so.stopVideo=='function'){so.stopVideo();}}
AmznVideoPlayer.prototype.getSO=function(){return jQuery("#so_"+this.id).get(0);}

function isAutoplayCancelled(showID) {
  return (AmznVideoPlayer.players[showID] && AmznVideoPlayer.players[showID].autoplayCancelled == true); 
}
</script>
 
<div id="kib-ma-container-0" class="kib-ma-container" style="display: block; margin-bottom: 1px;">
        <img class="kib-ma kib-image-ma" alt="Kindle e-reader" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-main-novid-lg._V134401297_.jpg" width="500" height="483" style="width: 500px; height: 483px;">
</div>
   
 
 
<div id="kib-ma-container-1" class="kib-ma-container" style="display: none; margin-bottom: 1px;">
        <img class="kib-ma kib-image-ma" alt="Kindle e-reader: device frontal view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-02-lg._V134401297_.jpg" width="500" height="483">
</div>
   
 
 
<div id="kib-ma-container-2" class="kib-ma-container" style="display: none; margin-bottom: 1px;">
        <img class="kib-ma kib-image-ma" alt="Kindle e-reader: device cover view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-03-lg._V134457777_.jpg" width="500" height="483">
</div>
   
 
 
<div id="kib-ma-container-3" class="kib-ma-container" style="display: none; margin-bottom: 1px;">
        <img class="kib-ma kib-image-ma" alt="Kindle e-reader: device back view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-04-lg._V134401297_.jpg" width="500" height="483">
</div>
   
 
 
<div id="kib-ma-container-4" class="kib-ma-container" style="display: none; margin-bottom: 1px;">
        <img class="kib-ma kib-image-ma" alt="Kindle e-reader: device in hand, reading at cafe" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-05-lg._V134401296_.jpg" width="500" height="483">
</div>
   
 

 
 
<div style="display: block; width: 500px;" id="kindle-video-footer">
<div id="kindle-video-footer-inner" style="width: 506px;">

<div id="kib-thumb-container-0" class="kib-thumb-container kib-thumb-container-selected" style="display: block; float: left;">
        <img id="kib-thumb-0" class="kib-thumb" alt="Kindle e-reader" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-01-novid-tn._V134401302_.jpg" width="93" height="70">
</div>
  
<div id="kib-thumb-container-1" class="kib-thumb-container" style="display: block; float: left;">
        <img id="kib-thumb-1" class="kib-thumb" alt="Kindle e-reader: device frontal view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-02-tn._V134401302_.jpg" width="93" height="70">
</div>
  
<div id="kib-thumb-container-2" class="kib-thumb-container" style="display: block; float: left;">
        <img id="kib-thumb-2" class="kib-thumb" alt="Kindle e-reader: device cover view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-03-tn._V134457777_.jpg" width="93" height="70">
</div>
  
<div id="kib-thumb-container-3" class="kib-thumb-container" style="display: block; float: left;">
        <img id="kib-thumb-3" class="kib-thumb" alt="Kindle e-reader: device back view" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-04-tn._V134401297_.jpg" width="93" height="70">
</div>
  
<div id="kib-thumb-container-4" class="kib-thumb-container" style="display: block; float: left;">
        <img id="kib-thumb-4" class="kib-thumb" alt="Kindle e-reader: device in hand, reading at cafe" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-slate-05-tn._V134401297_.jpg" width="93" height="70">
</div>
  
</div> 
</div>
<script type="text/javascript">
window.kibMAs = [
{
  "type" : "image",
  "imageUrls" : {
    "L" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-main-novid-lg._V134401297_.jpg",
    "S" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-01-novid-sm._V134401302_.jpg",
    "rich": {
        src: "http://g-ecx.images-amazon.com/images/G/02/misc/untranslatable-image-id.jpg",
        width: null,
        height: null
    }
  },
  "altText" : "Kindle e-reader",
  "thumbnailImageUrls" : {
    "default": "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-01-novid-tn._V134401302_.jpg"
  }
}
,
{
  "type" : "image",
  "imageUrls" : {
    "L" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-02-lg._V134401297_.jpg",
    "S" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-02-sm._V134401297_.jpg",
    "rich": {
        src: "http://g-ecx.images-amazon.com/images/G/02/misc/untranslatable-image-id.jpg",
        width: null,
        height: null
    }
  },
  "altText" : "Kindle e-reader: device frontal view",
  "thumbnailImageUrls" : {
    "default": "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-02-tn._V134401302_.jpg"
  }
}
,
{
  "type" : "image",
  "imageUrls" : {
    "L" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-03-lg._V134457777_.jpg",
    "S" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-03-sm._V134457777_.jpg",
    "rich": {
        src: "http://g-ecx.images-amazon.com/images/G/02/misc/untranslatable-image-id.jpg",
        width: null,
        height: null
    }
  },
  "altText" : "Kindle e-reader: device cover view",
  "thumbnailImageUrls" : {
    "default": "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-03-tn._V134457777_.jpg"
  }
}
,
{
  "type" : "image",
  "imageUrls" : {
    "L" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-04-lg._V134401297_.jpg",
    "S" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-04-sm._V134401297_.jpg",
    "rich": {
        src: "http://g-ecx.images-amazon.com/images/G/02/misc/untranslatable-image-id.jpg",
        width: null,
        height: null
    }
  },
  "altText" : "Kindle e-reader: device back view",
  "thumbnailImageUrls" : {
    "default": "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-04-tn._V134401297_.jpg"
  }
}
,
{
  "type" : "image",
  "imageUrls" : {
    "L" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-05-lg._V134401296_.jpg",
    "S" : "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-05-sm._V134401297_.jpg",
    "rich": {
        src: "http://g-ecx.images-amazon.com/images/G/02/misc/untranslatable-image-id.jpg",
        width: null,
        height: null
    }
  },
  "altText" : "Kindle e-reader: device in hand, reading at cafe",
  "thumbnailImageUrls" : {
    "default": "http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-slate-05-tn._V134401297_.jpg"
  }
}
];
window.kibConfig = 
{
  "L" : { 
      "minFooterWidth" : 506,
      "thumbsShow"     : [0,1,2,3,4],
      "mediaWidth"     : 500,
      "mediaHeight"    : 483 
  }, 
  "S" : {
      "minFooterWidth" : 304,
      "thumbsShow"     : [0,1,2],
      "mediaWidth"     : 320,
      "mediaHeight"    : 282
  },
  "playButtonUrl"      : "http://g-ecx.images-amazon.com/images/G/02/kindle/common-assets/play-btn-off._V151901884_.jpg",
  "playButtonHoverUrl" : "http://g-ecx.images-amazon.com/images/G/02/kindle/common-assets/play-btn-on._V151901884_.jpg",
  "autoplay"           : false,
  "useHTML5Video"      : 0,
  "mediaMarginBottom"  : 0,
  "preplayTemplate"    : '<div style="width:500px;height:0px;" class="outercenterslate"><div style="width:500px;height:0" class="centerslate" ><span></span><img border="0" src="slateImageGoesHere" /></div><div class="shuttleGradient" style="background: none;height:0px;"><img id="mediaObjectIdpreplayImageId" style="height:60px;position:absolute;left:0px;top:-60px;" src="http://g-ecx.images-amazon.com/images/G/02/kindle/common-assets/play-btn-off._V151901884_.jpg" border="0"/></div></div>',
  "cursorZoomInUrl"    : "http://g-ecx.images-amazon.com/images/G/02/detail-page/cursors/zoom-in._V184888380_.bmp"
}
;
</script> 

</div>

<script type="text/javascript">
// TODO: Add UX for handling user events when kindleImageBlockJS is not loaded
amznJQ.available("kindleImageBlockJS",function(event) {});
</script>
</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"> 





 

 
 







 
 

 
 



    
  




    


     <div id="kindle-img-links-pere-L"> 
                <table id="kindle-img-links-pere-L" align="center" cellspacing="0" cellpadding="0">
                  <tbody><tr>
                      <td> <div class="tiny" style="padding-top: 6px;"><a href="http://www.amazon.co.uk/gp/customer-media/product-gallery/B005890FUI/ref=cm_ciu_pdp_images_all">See all 19 customer images</a></div> </td>
                      <td> <div class="tiny" style="padding: 6px 12px 0px">|</div> </td>
                      <td>    <div class="tiny custImgLink" style="padding-top: 6px;">
  <a href="http://www.amazon.co.uk/gp/customer-media/upload/B005890FUI/ref=cm_ciu_pdp_add?ie=UTF8&rnd=1358413557">Share your own customer images</a>
</div></td>
                  </tr>
              </tbody></table>
         </div> 
              <div id="kindle-img-links-pere-S" style="display:none">
	          <div class="tiny" style="padding-top: 6px;"><a href="http://www.amazon.co.uk/gp/customer-media/product-gallery/B005890FUI/ref=cm_ciu_pdp_images_all">See all 19 customer images</a></div> 
                  <div class="tiny custImgLink" style="padding-top: 6px;">
  <a href="http://www.amazon.co.uk/gp/customer-media/upload/B005890FUI/ref=cm_ciu_pdp_add?ie=UTF8&rnd=1358413557">Share your own customer images</a>
</div>
              </div>         
  





</td></tr><tr><td valign="top" width="100%"></td></tr></tbody></table>

   
  





<div class="buying">
  <h1 class="parseasinTitle"><span id="btAsinTitle">Kindle Touch</span></h1>
  <span>Simple-to-use touchscreen, with audio and built-in Wi-Fi</span>
</div>




<div class="buying">
      


































  
  





























<span class="tiny">
      <script type="text/javascript">

    function reviewHistPingAjax() {
      jQuery.get("/gp/customer-reviews/common/du/recordHistoPopAjax.html", null);
    }

    var reviewHistPopoverConfig = {
      showOnHover:true,
      showCloseButton: false,
      width:null,
      location:'bottom',
      locationAlign:'left',
      locationOffset:[-20,0],
      group: 'reviewsPopover',
      clone:false,
      hoverHideDelay:300
    };
    
      </script>


      <script type="text/javascript">
     function constructTriggerPrefix(asin){
       return "reviewHistoPop" + '_' + asin;
     }

     function getContentDivId(triggerName){
       var nameArray = new Array();
       nameArray = triggerName.split('__');
       return nameArray[1];
     }
                                                                                                                                                             
     function jQueryInitHistoPopovers(asin, triggerDivPrefix) {
                                                                                                                                                             
       if(triggerDivPrefix == null){
         triggerDivPrefix = constructTriggerPrefix(asin);
       }
                                                                                                                                                             
       amznJQ.onReady('popover', function(){
         jQuery('a[name^=' + triggerDivPrefix + ']').each(function(){
                                                                                                                            
           jQuery(this).removeAmazonPopoverTrigger();
                                                                                                                                                            
           var contentDivId = getContentDivId(this.name);
                                                                                                                                                            
           var myConfig = jQuery.extend(true, {}, reviewHistPopoverConfig);
                                                                                                                                                             
           myConfig.localContent = '#' + contentDivId;
           myConfig.onShow = reviewHistPingAjax;                                                                                  
           jQuery(this).amazonPopoverTrigger(myConfig);
         });
       });
     }
      </script>

<span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005890FUI" ref="dp_top_cm_cr_acr_pop_">
               <a style="text-decoration:none" href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_img?ie=UTF8&showViewpoints=1" name="reviewHistoPop_B005890FUI_3193_star__contentDiv_reviewHistoPop_B005890FUI_3193"><span class="swSprite s_star_4_5 " title="4.3 out of 5 stars"><span>4.3 out of 5 stars</span></span>&nbsp;</a>&nbsp;<span class="histogramButton" style="margin-left:-3px"><a style="text-decoration:none" href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_img?ie=UTF8&showViewpoints=1" name="reviewHistoPop_B005890FUI_3193_button__contentDiv_reviewHistoPop_B005890FUI_3193"><span class="swSprite s_chevron "><span>See all reviews</span></span>&nbsp;</a></span></span>(<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">1,050 customer reviews</a>)</span>
                          <script type="text/javascript">
                            amznJQ.onReady('popover', function() {
                              jQueryInitHistoPopovers('B005890FUI','reviewHistoPop_B005890FUI_3193');
                            });
                          </script>
                         
                           <div id="contentDiv_reviewHistoPop_B005890FUI_3193" style="display:none;">
                           <table border="0" cellspacing="5" cellpadding="0" bgcolor="ffffff">
                           <tbody><tr><td>
                           <div>





















































































<div style="display:block; text-align:center; padding-bottom: 5px;" class="tiny">
  <b>1,050 Reviews</b>
</div>
<table border="0" cellspacing="1" cellpadding="0" align="center">
<tbody><tr>
<td align="left" style="padding-right:0.5em;padding-bottom:1px;white-space:nowrap;font-size:10px;">
  <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_5?ie=UTF8&filterBy=addFiveStar&showViewpoints=0" style="font-family:Verdana,Arial,Helvetica,Sans-serif;">5 star</a>:
</td>
<td style="min-width:60; background-color: #eeeecc" width="60" align="left" class="tiny" title="67%"><div style="background-color:#FFCC66; height:13px; width:67%;"></div></td>
<td align="right" style="font-family:Verdana,Arial,Helvetica,Sans-serif;;font-size:10px;">&nbsp;(712)</td>
</tr>
<tr>
<td align="left" style="padding-right:0.5em;padding-bottom:1px;white-space:nowrap;font-size:10px;">
  <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_4?ie=UTF8&filterBy=addFourStar&showViewpoints=0" style="font-family:Verdana,Arial,Helvetica,Sans-serif;">4 star</a>:
</td>
<td style="min-width:60; background-color: #eeeecc" width="60" align="left" class="tiny" title="15%"><div style="background-color:#FFCC66; height:13px; width:15%;"></div></td>
<td align="right" style="font-family:Verdana,Arial,Helvetica,Sans-serif;;font-size:10px;">&nbsp;(162)</td>
</tr>
<tr>
<td align="left" style="padding-right:0.5em;padding-bottom:1px;white-space:nowrap;font-size:10px;">
  <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_3?ie=UTF8&filterBy=addThreeStar&showViewpoints=0" style="font-family:Verdana,Arial,Helvetica,Sans-serif;">3 star</a>:
</td>
<td style="min-width:60; background-color: #eeeecc" width="60" align="left" class="tiny" title="5%"><div style="background-color:#FFCC66; height:13px; width:5%;"></div></td>
<td align="right" style="font-family:Verdana,Arial,Helvetica,Sans-serif;;font-size:10px;">&nbsp;(55)</td>
</tr>
<tr>
<td align="left" style="padding-right:0.5em;padding-bottom:1px;white-space:nowrap;font-size:10px;">
  <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_2?ie=UTF8&filterBy=addTwoStar&showViewpoints=0" style="font-family:Verdana,Arial,Helvetica,Sans-serif;">2 star</a>:
</td>
<td style="min-width:60; background-color: #eeeecc" width="60" align="left" class="tiny" title="3%"><div style="background-color:#FFCC66; height:13px; width:3%;"></div></td>
<td align="right" style="font-family:Verdana,Arial,Helvetica,Sans-serif;;font-size:10px;">&nbsp;(35)</td>
</tr>
<tr>
<td align="left" style="padding-right:0.5em;padding-bottom:1px;white-space:nowrap;font-size:10px;">
  <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_1?ie=UTF8&filterBy=addOneStar&showViewpoints=0" style="font-family:Verdana,Arial,Helvetica,Sans-serif;">1 star</a>:
</td>
<td style="min-width:60; background-color: #eeeecc" width="60" align="left" class="tiny" title="8%"><div style="background-color:#FFCC66; height:13px; width:8%;"></div></td>
<td align="right" style="font-family:Verdana,Arial,Helvetica,Sans-serif;;font-size:10px;">&nbsp;(86)</td>
</tr>
</tbody></table>
<br>
<span class="tiny"><span style="color:#E47911; font-weight:bold;"></span>&nbsp;<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=dp_top_cm_cr_acr_pop_hist_all?ie=UTF8&showViewpoints=1">See all 1,050 customer reviews...</a></span>
  <div class="tiny cdReviewsDiscussionLinkDiv_B005890FUI"></div>
</div>
                           </td></tr></tbody></table>
                           </div>
                          </span> <span class="byLinePipe">|</span> 








<span id="likeAndShareBar" style=""><span id="amznLike_B005890FUI" class="amazonLike hideUntilJSReady">
    <span class="amazonLikeButtonCountCombo">
        

<span class="amazonLikeButtonWrapper">
    <a href="http://www.amazon.co.uk/gp/like/sign-in/sign-in.html/ref=pd_like_unrec_signin_nojs_dp?ie=UTF8&isRedirect=1&location=%2Fgp%2Flike%2Fexternal%2Fsubmit.html%2Fref%3Dpd_like_submit_like_unrec_nojs_dp%3Fie%3DUTF8%26action%3Dlike%26context%3Ddp%26itemId%3DB005890FUI%26itemType%3Dasin%26redirect%3D1%26redirectPath%3D%252Fgp%252Fproduct%252FB005890FUI%253Fref%25255F%253Damb%25255Flink%25255F163489267%25255F3&useRedirectOnSuccess=1" style="text-decoration:none;" onclick="amznJQ.available(&#39;jQuery&#39;,function(){window.AMZN_LIKE_SUBMIT=true;});return false;">
        <span id="amazonLikeButton_B005890FUI" class="amazonLikeButton down unclickableIfNoJavascript off clickable" style="background-image: url(http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/amznlike/amznlike_sprite_02._V170008538_.gif);">
            <span class="altText">Like</span>
        </span>
    </a>
</span>

<span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_values" style="display:none;">
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_ts">1358413558</span>
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_isLiked">false</span>
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_customerWhitelistStatus">-1</span>
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_likeCount">1972</span>
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_commifiedLikeCount">1,972</span>
    <span id="amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_commifiedLikeCountMinusOne">1,971</span>
</span>


<span class="tiny amazonLikeCountContainer">(<span class="amazonLikeCount">1,972</span>)</span>

    </span>
</span></span>







</div>



<hr class="kitsune-solid-divider" noshade="noshade" size="1">



<table border="0" cellpadding="0" cellspacing="0">

<tbody><tr><td valign="top" width="100%">
  

    



</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">
</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">










<div class="buying"><br>









<span class="availGreen">Available from <a href="http://www.amazon.co.uk/gp/offer-listing/B005890FUI/ref=dp_olp_0?ie=UTF8&condition=all" class="buyAction">these sellers</a>.</span><br>




<br><br></div>






</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">

<div class="kitsune-fast-track"></div>




</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"><div style="color:#E47911;font-size:14px;font-weight:bold">
      Simple-to-use touchscreen, with audio and built-in Wi-Fi 
    </div></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">


























</td></tr><tr><td valign="top" width="100%">







<noscript>
&lt;style type="text/css"&gt;
.kindle-feature-bullets-toggle {
    display: none;
}

#kindle-feature-bullets-atf-more {
    display: block;
}

&lt;/style&gt;
</noscript>

<div id="kindle-feature-bullets-atf">
  <div>
    <ul>
        <li><span>Most-advanced E Ink display, now with multi-touch</span></li><li><span>Reads like real paper, even in bright sunlight</span></li><li><span>Built in Wi-Fi - get books in 60 seconds</span></li><li><span>Sleek design - Only 213 grams, holds up to 3,000 books</span></li><li><span>EasyReach touch technology lets you read easily with one hand</span></li><li><span>New X-Ray feature lets you look up characters, historical figures, and interesting phrases. <a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#xray">Learn More</a></span></li><li><span>Text-to-speech, audiobooks and mp3 support</span></li><li><span>Up to two month battery life</span></li>
    </ul>
  </div>
</div>

<script>
amznJQ.available('jQuery', function() {
(function ($) {
    $('.kindle-feature-bullets-toggle').click(function () {
        var toggleId = $(this).attr('id'),
            moreElement = $('#kindle-feature-bullets-atf-more'),
            moreToggleClass = 'kindle-feature-bullets-show-more';

        if (toggleId === moreToggleClass) {
            moreElement.show();
            $(this).hide();
        } else {
            moreElement.hide();
            $('#' + moreToggleClass).show();
        }
    });
}(jQuery));
});
</script>



</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">

</td></tr><tr><td valign="top" width="100%">


<div class="buying" id="promoGrid">
<div class="amabot_widget"></div><br></div>
</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%">
   
  




<div id="kindle-refurb-box">
    <div id="kindle-refurb-details">
     <div id="kindle-refurb-content">
    <p><span class="kindle-refurb-orange-bold">Looking for deals on Kindle?    

</span></p>
<p>Save now with a <a target="_blank" href="http://www.amazon.co.uk/gp/offer-listing/B005890FUI/ref=dp_olp_refurbished_mbc?ie=UTF8&condition=refurbished&m=A2OAJ7377F756P"><b>Certified Refurbished Kindle Touch</b></a> for just 64.99. A Certified Refurbished Kindle Touch is a pre-owned Kindle Touch that has been refurbished, tested, and certified to look and work like new.
     </p></div>
    </div>
</div>

<style>
.kindle-refurb-orange-bold {
   font-weight: bold;
   color: #000000;	
}
.kindle-refurb-link {
   text-decoration: underline !important;
}
#kindle-refurb-box {
    margin: 5px 0;	
}
#kindle-refurb-details {
	border: 1px solid #ccc;
	-webkit-border-radius: 5px;
	-moz-border-radius: 5px;
    border-radius: 5px;
    position: relative;
    z-index: 1;
    font-size: 12px;	
}
#kindle-refurb-content {
    margin: 8px;	
}
#kindle-refurb-content p {
	margin: 8px 0;	
}
</style>
</td></tr><tr><td valign="top" width="100%"></td></tr><tr><td valign="top" width="100%"></td></tr></tbody></table>




<input type="hidden" name="itemCount" value="6">
</form>



</div><div style="clear:both"></div>


<div style="clear:both;"></div>

<div class="bucket" id="kindle-at-a-glance">
  



  <table class="title-wrapper" style="margin-right:385px;"><tbody>
    <tr>
      <td><h2>At a Glance</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>




  <table class="at-a-glance-outer" width="95%">
    <tbody>
     <tr><td width="64%" valign="top">
      <table width="100%" style="margin-top:5px">
       <colgroup><col width="46%">
       <col width="8%">
       <col width="46%">
       </colgroup><tbody>
<tr><td valign="top"><span class="title">Most Advanced E Ink Display</span><br>
          <span>Kindle's high-contrast E Ink display delivers clear, crisp text and images.</span><br><br><span class="title">Read in Bright Sunlight</span><br>
          <span>Kindle's E Ink screen reads like real paper, with no glare. Read as easily in bright sunlight as in your living room.</span><br><br><span class="title">Simple To Use Touchscreen</span><br>
          <span>Kindle Touch features an easy-to-use touch interface. Turn pages, search, shop books and take notes quickly and easily.</span><br><br><span class="title">Holds Up To 3,000 Books</span><br>
          <span>Keep your library with you wherever you go.</span><br><br><span class="title">Light and Compact Design</span><br>
          <span>Only 213 grams, with the same 15cm screen size.  Lighter than a paperback and fits in your pocket.</span><br><br><span class="title">Books in 60 seconds</span><br>
          <span>Find a book and start reading in seconds with our fast, free wireless delivery.</span><br><br><span class="title">Built-In Wi-Fi</span><br>
          <span>Connect to Wi-Fi hotspots at home or on the road. </span><br><br><span class="title">Up to two Month Battery Life</span><br>
          <span>No battery anxiety - read half an hour per day for up to two months on a single charge with wireless off.</span><br><br><span class="title">NEW - EasyReach</span><br>
          <span>Tap to turn pages - no need to swipe, so you can hold Kindle in either hand. <a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#whispertap">Learn More</a></span><br><br><span class="title">Simple to Use</span><br>
          <span>Kindle is ready to use right out of the box - no setup, no software to install, no computer required to download content.</span><br><br><span class="title">Adjustable Fonts</span><br>
          <span>Read comfortably with eight different sizes and three font styles.</span><br><br><span class="title">Fast Page Turns</span><br>
          <span>Kindle Touch has a powerful processor tuned for fast, seamless page turns.</span><br><br><span class="title">PDF and Personal Documents</span><br>
          <span>Email personal documents and PDFs direct to your Kindle to read and annotate on-the-go.</span><br><br><span class="title">Choose Your Language</span><br>
          <span>You can set your language to French, English, German, Spanish, Italian, or Brazilian Portuguese - including home and menu displays and dictionary support. </span>
         </td>
         <td valign="top">&nbsp;</td>
         <td valign="top">
<span class="title">Large Selection</span><br>
             <span>Over one million books, newspapers, and magazines, including latest bestsellers, Kindle exclusives and more.</span><br><br><span class="title">Low Book Prices</span><br>
             <span>We check hundreds of prices every day to make sure our prices are the lowest of any ebook store in the UK. Compare our book prices--you'll like what you find.</span><br><br><span class="title">Free Books</span><br>
             <span>More than one million free books, such as <i>Pride and Prejudice</i> and <i>Treasure Island</i> are available. <a target="_blank" href="http://www.amazon.co.uk/b?ie=UTF8&node=434020031">Learn More</a></span><br><br><span class="title">Read a sample for free</span><br>
             <span>Sample a new author or book - download and read an extract of books for free.</span><br><br><span class="title">NEW - X-Ray</span><br>
             <span>Explore the "bones of a book".  With a single tap, see all the passages across a book that mention ideas, fictional characters, historical figures, places or topics of interest, as well as more detailed descriptions from Wikipedia and Shelfari. <a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#xray">Learn More</a> </span><br><br><span class="title">New - Instant Translations</span><br>
             <span>Tap any word or highlight a section to instantly translate into other languages, including Spanish, Japanese, and more. Translations by Bing Translator. </span><br><br><span class="title">Read-to-Me</span><br>
             <span>With Text-to-Speech, Kindle can read English-language content out loud to you, including summaries from your newspaper and magazine articles.</span><br><br><span class="title">Buy Once, Read Everywhere</span><br>
             <span>Kindle books can be read on your Kindle, iPhone, iPad, Android devices, Windows Phone 7, Mac, or PC with our <a target="_blank" href="http://www.amazon.co.uk/gp/feature.html?ie=UTF8&docId=1000425503">free Kindle Reading Apps</a>.</span><br><br><span class="title">Whispersync</span><br>
             <span>Our Whispersync technology synchronises your last page read, bookmarks and annotations across your devices so you can always pick up where you left off.</span><br><br><span class="title">Worry-Free Archive</span><br>
             <span>Books you purchase from the Kindle Store are automatically backed up online in your Kindle library on Amazon. Re-download books wirelessly for free, anytime. <a target="_blank" href="http://www.amazon.co.uk/gp/help/customer/display.html/?ie=UTF8&nodeId=200727580&qid=1331888285&sr=1-2">Learn More</a></span><br><br><span class="title">Built-in Dictionary with Instant Lookup</span><br>
             <span>Seamlessly look up definitions without interrupting your reading. Dictionaries are available in French, English, German, Spanish, Italian, or Brazilian Portuguese.</span>
         </td>
        </tr>
       </tbody>
      </table>
     </td>
     <td valign="top" width="4%">&nbsp;</td>
     <td valign="top" width="46%">
       <div style="text-align:center">

        <div class="shasta-image-gallery">
<img id="kindle-at-a-glance-image" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-aag-main-01._V134401297_.jpg" alt="">
          <table class="at-a-glance-thumbnails" cellpadding="0" cellspacing="0">
            <tbody>
              <tr>
<td><img alt="Kindle Touch e-reader: reads like real paper, even in bright sunlight, as shown by woman reading a Kindle at the beach" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-aag-tn-01._V134401302_.jpg" onclick="kindleAtAGlanceHandleClick(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-aag-main-01._V134401297_.jpg&#39;, &#39;&#39;)"></td><td><img alt="Kindle Touch e-reader: woman holding Kindle Touch while on commuter train" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-aag-tn-02._V134401297_.jpg" onclick="kindleAtAGlanceHandleClick(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-aag-main-02._V134401297_.jpg&#39;, &#39;&#39;)"></td><td><img alt="Kindle Touch e-reader: young girl reading, with Kindle Touch on her lap" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-aag-tn-03._V134401302_.jpg" onclick="kindleAtAGlanceHandleClick(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-aag-main-03._V134401297_.jpg&#39;, &#39;&#39;)"></td><td><img alt="Kindle Touch e-reader: woman reading in car with Kindle Touch on lap" src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-aag-tn-04._V134401302_.jpg" onclick="kindleAtAGlanceHandleClick(&#39;http://g-ecx.images-amazon.com/images/G/02/kindle/whitney/dp/uk-kw-aag-main-04._V134401296_.jpg&#39;, &#39;&#39;)"></td>
         </tr>
         </tbody>
         </table>
         </div>
         









        </div>
      </td>
    </tr></tbody>
  </table>
</div>

<script type="text/javascript">
    amznJQ.onReady('kindleDeviceJSExtended', function() {});
  
    amznJQ.onReady('kindleCountrySelect', function() {
      kindleDeviceCountrySelect.initialize();
    });
  </script>

<div class="hr-solid"></div>





<script type="text/javascript">
  amznJQ.onReady('kindleDeviceJSExtended', function() {});

  amznJQ.onReady('kindleCountrySelect', function() {
    kindleDeviceCountrySelect.initialize();
  });
</script>
















<div id="technical-details" style="margin: 40px 0 44px 0;">
         
              



  <table class="title-wrapper" style="margin-right:385px;"><tbody>
    <tr>
      <td><h2>Technical Details</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>



 

              <table cellspacing="0" cellpadding="0">
                <tbody>
                  <tr class="Teq-technical-details-inbox">
                    <td>
                      
<div class="Teq-technical-details-info">
<table id="technical-details-table" cellspacing="1" cellpadding="10" border="0" width="100%" style="margin-left:0;">
<colgroup>
<col style="width: 20%; background-color: #EAF3FE;">
<col>
</colgroup>
<tbody>
<tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Display</td><td style="font-size:12px;">Amazon's 6" diagonal electronic paper display, optimised with proprietary waveform and font technology, 600 x 800 pixel resolution at 167 ppi, 16-level grey scale.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Size</td><td style="font-size:12px;">172 mm x 120 mm x 10.1 mm</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Weight</td><td style="font-size:12px;">213 grams</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">System Requirements</td><td style="font-size:12px;">None, because it's wireless and doesn't require a computer to download content.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Storage</td><td style="font-size:12px;">Up to 3,000 books or 4 GB internal (approximately 3 GB available for user content).</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Cloud Storage</td><td style="font-size:12px;">Free cloud storage for all Amazon content.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Battery Life</td><td style="font-size:12px;">A single charge lasts up to two months with wireless off based upon a half-hour of daily reading time. Keep wireless always on and it lasts for up to 3 weeks. Battery life will vary based on wireless usage, such as shopping the Kindle Store, downloading content, and web browsing (browsing available only in Wi-Fi mode). </td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Charge Time</td><td style="font-size:12px;">Fully charges in approximately 4.5 hours via the included USB 2.0 cable connected to a computer. UK power adapter sold separately. </td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Wi-Fi Connectivity</td><td style="font-size:12px;">Supports public and private Wi-Fi networks or hotspots that use the 802.11b, 802.11g, or 802.11n standard with support for WEP, WPA and WPA2 security using password authentication or or Wi-Fi Protected Setup (WPS); Supports WPA and WPA2 secured networks using 802.1X authentication methods using password authentication; does not support connecting to ad-hoc (or peer-to-peer) Wi-Fi networks.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">USB Port</td><td style="font-size:12px;">USB 2.0 (micro-B connector)</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Content Formats Supported</td><td style="font-size:12px;">Kindle (AZW), Kindle Format 8 (AZW3), TXT, PDF, Audible (Audible Enhanced(AA,AAX)), MP3, unprotected MOBI, PRC natively; HTML, DOC, DOCX, JPEG, GIF, PNG, BMP through conversion.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Documentation</td><td style="font-size:12px;"><a href="https://s3.amazonaws.com/KindleTouch/Kindle_Touch_QuickStart_Guide.pdf" target="_blank">Quick Start Guide</a> (included in box) [PDF]; <a href="https://s3.amazonaws.com/KindleTouch/Kindle_Touch_User_Guide.pdf" target="_blank">Kindle User's Guide</a> (pre-installed on device) [PDF].</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Warranty and Service</td><td style="font-size:12px;">Kindle is sold with a worldwide <a href="http://www.amazon.co.uk/gp/help/customer/display.html?nodeId=200838740" target="_blank">limited warranty of one year</a> provided by the manufacturer. If you are a consumer, the limited warranty is in addition to your consumer rights, and does not jeopardise these rights in any way. This means you may still have additional rights at law even after the limited warranty has expired (for further information on your consumer rights, <a href="http://www.amazon.co.uk/gp/help/customer/display.html?nodeId=200900540" target="_blank">click here</a>). Optional <a href="http://www.amazon.co.uk/gp/product/B006X5F0NS/ref=kinw3wf_ddp" target="_blank">3-year Extended Warranty</a> available for UK customers sold separately. Use of Kindle is subject to the <a href="http://www.amazon.co.uk/gp/help/customer/display.html?nodeId=200501450" target="_blank">Kindle License Agreement and Terms of Use</a>.</td></tr><tr><td align="right" style="font-weight: bold;text-align:left; font-size: 12px;">Included in the Box</td><td style="font-size:12px;">Kindle wireless reader, USB 2.0 cable, and <a href="https://s3.amazonaws.com/KindleTouch/Kindle_Touch_QuickStart_Guide.pdf" target="_blank">Quick Start Guide</a>.</td></tr>
</tbody>
</table>
</div>
    
                    </td>
                    <td valign="top">
                      <div class="Teq-technical-details-inbox-image"> <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-tech-01._V134401296_.jpg" width="318" alt="Technical Details" height="371" border="0"> </div>
                    </td>
                  </tr>
                </tbody>
              </table>
              </div>
















<div class="kmd-title-container" style="margin-bottom:30px;">
    <div class="kmd-title-underline"></div>
    <a name="kindle-compare"></a>
    <h3 class="kmd-title">Compare Kindles</h3> 
</div>


 
 
 




<div class="kmd-comp-container" style="margin-left: 10px;">
<table class="kmd-comp-table">
<colgroup>
    <col class="kmd-comp-attr-col" style="width: 30.3030303030303%; ">
    
    <col class="" style="width: 12.1212121212121%;">

    
    <col class="" style="width: 12.1212121212121%;">

    
    <col class="" style="width: 15.1515151515152%;">

    
    <col class="" style="width: 15.1515151515152%;">

    
    <col class="" style="width: 15.1515151515152%;">

    
</colgroup>

<thead>


<tr class="kmd-comp-group-row">
    <th class="kmd-comp-borderless-cell"></th>
    
    <th colspan="3" class="kmd-comp-family-name kmd-comp-borderless-cell">Kindle e-Reader family</th>
    
    <th colspan="2" class="kmd-comp-family-name  kmd-comp-family-border">Kindle Fire Family</th>
    
</tr>

<tr class="kmd-comp-notch-row">
    <th class="kmd-comp-borderless-cell"></th>
     <th colspan="2" class="kmd-comp-borderless-cell"></th><th class=""></th><th class=" kmd-comp-family-border"></th><th class=""></th></tr>

<tr class="kmd-comp-device-img-row">
    <th class="kmd-comp-borderless-cell"></th>
    <th colspan="2" class="kmd-comp-borderless-cell"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-KC._V385941562_.gif" width="109" height="135" border="0"></th><th class=""><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-KS._V389397403_.gif" width="109" height="135" border="0"></th><th class=" kmd-comp-family-border"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-KT._V389389329_.gif" width="109" height="135" border="0"></th><th class=""><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-O2._V389389328_.gif" width="109" height="135" border="0"></th></tr>

<tr>
    <th class="kmd-comp-borderless-cell"></th>
    <th class="kmd-comp-device-name kmd-comp-borderless-cell">
                    <a href="http://www.amazon.co.uk/gp/product/B007OZNWRC/ref=k_md_12">Kindle Paperwhite 3G</a>
                </th><th class="kmd-comp-device-name kmd-comp-in-group">
                    <a href="http://www.amazon.co.uk/gp/product/B007OZO03M/ref=k_md_12">Kindle Paperwhite</a>
                </th><th class="kmd-comp-device-name">
                    <a href="http://www.amazon.co.uk/gp/product/B007HCCOD0/ref=k_md_12">Kindle</a>
                </th><th class="kmd-comp-device-name kmd-comp-family-border">
                    <a href="http://www.amazon.co.uk/gp/product/B008UAAE44/ref=k_md_12">Kindle Fire HD</a>
                </th><th class="kmd-comp-device-name">
                    <a href="http://www.amazon.co.uk/gp/product/B008GG0GBI/ref=k_md_12">Kindle Fire</a>
                </th></tr>
<tr class="kmd-comp-price-row">
    <th class="kmd-comp-borderless-cell"></th>
    
                <th class="kmd-comp-price kmd-comp-borderless-cell">169</th>         
            
                <th class="kmd-comp-price kmd-comp-in-group">109</th>         
            
                <th class="kmd-comp-price">69</th>         
            
                <th class="kmd-comp-price kmd-comp-family-border">from159</th>         
            
                <th class="kmd-comp-price">from 129</th>         
            </tr>
</thead>

<tbody>
<tr class="kmd-comp-attr-row kmd-comp-first-attr-row">
    <th class="kmd-comp-attr-name">Screen size</th>

            <td class="kmd-comp-attr-value" colspan="2">6"</td>
        
            <td class="kmd-comp-attr-value">6"</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">7"</td>
        
            <td class="kmd-comp-attr-value">7"</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Display Technology</th>

            <td class="kmd-comp-attr-value" colspan="2">Paperwhite Built-in light</td>
        
            <td class="kmd-comp-attr-value">E Ink Pearl</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">HD LCD</td>
        
            <td class="kmd-comp-attr-value">LCD</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Resolution/ Pixel density</th>

            <td class="kmd-comp-attr-value" colspan="2">212 PPI</td>
        
            <td class="kmd-comp-attr-value">167 PPI</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">1280x800, <br>up to 720p HD</td>
        
            <td class="kmd-comp-attr-value">1024x600</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Audio</th>

            <td class="kmd-comp-attr-value" colspan="2">-</td>
        
            <td class="kmd-comp-attr-value">-</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">Dolby Audio<br>dual-driver stereo speakers</td>
        
            <td class="kmd-comp-attr-value">Stereo speakers</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Connectivity</th>

            <td class="kmd-comp-attr-value">Free 3G + Wi-Fi</td>
        
            <td class="kmd-comp-attr-value kmd-comp-in-group">Wi-Fi</td>
        
            <td class="kmd-comp-attr-value">Wi-Fi</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">Dual-band, dual antenna Wi-Fi</td>
        
            <td class="kmd-comp-attr-value">Wi-Fi</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Storage</th>

            <td class="kmd-comp-attr-value" colspan="2">2 GB on device<br><br>Plus free cloud storage for all Amazon content</td>
        
            <td class="kmd-comp-attr-value">2 GB on device<br><br>Plus free cloud storage for all Amazon content</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">16 GB or 32 GB on device<br><br>Plus free cloud storage for all Amazon content</td>
        
            <td class="kmd-comp-attr-value">8 GB on device<br><br>Plus free cloud storage for all Amazon content</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Dimensions</th>

            <td class="kmd-comp-attr-value" colspan="2">16.9 cm x 11.7 cm<br>x 0.91 cm</td>
        
            <td class="kmd-comp-attr-value">16.5 cm x 11.4 cm<br>x 0.87 cm</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">19.3 cm x 13.7 cm<br>x 1.03 cm</td>
        
            <td class="kmd-comp-attr-value">18.9 cm x 12 cm<br>x 1.15 cm</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Weight</th>

            <td class="kmd-comp-attr-value">222 g</td>
        
            <td class="kmd-comp-attr-value kmd-comp-in-group">213 g</td>
        
            <td class="kmd-comp-attr-value">170 g</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">395 g</td>
        
            <td class="kmd-comp-attr-value">400 g</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Processor</th>

            <td class="kmd-comp-attr-value" colspan="2">-</td>
        
            <td class="kmd-comp-attr-value">-</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">Dual-core,<br>1.2GHz OMAP 4460</td>
        
            <td class="kmd-comp-attr-value">Dual-core,<br>1.2GHz OMAP 4430</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Battery life (wireless off)</th>

            <td class="kmd-comp-attr-value" colspan="2">8 weeks</td>
        
            <td class="kmd-comp-attr-value">Up to 1 month</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">Over 11 hours <br>continuous use</td>
        
            <td class="kmd-comp-attr-value">Almost 9 hours<br>continuous use</td>
        
</tr>

<tr class="kmd-comp-attr-row ">
    <th class="kmd-comp-attr-name">Web</th>

            <td class="kmd-comp-attr-value" colspan="2">Experimental<br>browser</td>
        
            <td class="kmd-comp-attr-value">Experimental<br>browser</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border">Cloud-accelerated browsing<br>using Amazon Silk</td>
        
            <td class="kmd-comp-attr-value">Cloud-accelerated browsing<br>using Amazon Silk</td>
        
</tr>

<tr class="kmd-comp-attr-row " style="height:200px;">
    <th class="kmd-comp-attr-name">Interface</th>

            <td class="kmd-comp-attr-value" colspan="2"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-IF-touch._V389029186_.gif"><br><br>2-point <br>multi-touch</td>
        
            <td class="kmd-comp-attr-value"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-IF_rocker._V389029184_.gif"><br><br>5-way controller</td>
        
            <td class="kmd-comp-attr-value kmd-comp-family-border"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-IF-multi._V389029187_.gif"><br><br>10-point <br>multi-touch</td>
        
            <td class="kmd-comp-attr-value"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/comp-IF-multi._V389029187_.gif"><br><br>2-point <br>multi-touch</td>
        
</tr>



</tbody>

</table>
</div>


<div id="e-ink-101">
    



  <table class="title-wrapper" style="margin-right:385px;"><tbody>
    <tr>
      <td><h2>E Ink 101</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>




</div>




<table cellpadding="0" cellspacing="0" border="0">  <tbody><tr>
    <td width="" valign="top" align="left">
      <div class="kindle-feature"><div class="sub-headline"><a name="eink-101"></a>
If you're purchasing a device primarily for reading, an important consideration is the screen technology.  Unlike devices with LCD screens, Kindle e-readers use the latest generation of Electronic Ink ("E Ink") technology  E Ink Pearl  designed specifically to deliver clearer, sharper text that makes reading for extended periods of time more comfortable.  Here are some of the advantages to reading on an E Ink device:<br clear="all"><br clear="all"><b>Reads Like Real Paper, Even in Bright Sunlight</b><br clear="all">
E Ink screens look and read just like real paper. Kindle e-readers' matte screens reflect light like ordinary paper and use no backlighting, so you can read as easily in bright sunlight as in your living room.  Unlike LCD screens, E Ink screens have no glare.<br clear="all"><br clear="all"><b>Easy on the Eyes</b><br clear="all">
E Ink uses actual ink particles to create crisp, print-like text similar to what you see in a physical book. And Kindle e-readers also use proprietary, hand-built fonts to take advantage of the special characteristics of the ink to make letters appear clear and sharp.<br clear="all"></div><div style="padding-left:20px;" class="sub-headline">
	<b>Less eye fatigue:</b> Every time your eye switches from a bright screen to a dimmer, ambient room, your eyes have to adjust, which may result in fatigue. With E Ink, the page is the same brightness as everything else in the room so there's no adjustment needed.<br clear="all"><br clear="all">
	<b>Reduced glare:</b> All E Ink surfaces are treated to be matte like a printed page, reducing glare and increasing legibility.<br clear="all"><br clear="all">
	<b>Read in any position:</b> E Ink screens have a uniform contrast ratio that does not change with your viewing angle, so you can read in any position.<br clear="all"><br clear="all">
	<b>Sharp, clear text:</b> E Ink screens have 100% aperture ratio, so there are no gaps between pixels. The blacks and whites on an E Ink screen are uniform, improving image quality.<br clear="all"></div><div class="sub-headline"><b>Read with One Hand</b><br clear="all">
Ranging from 170 grams to 247 grams, Kindle e-readers are lighter than most paperback books, and weigh half as much as many LCD tablet devices, making it easy and comfortable to hold in one hand for extended periods of time. <br clear="all"><br clear="all"><b>Longer Battery Life</b><br clear="all">
Electronic ink screens also have the advantage of significantly lower power consumption than LCD screens.  E Ink screens do not require power to maintain a page of text, allowing you to read for up to two months on a single charge.<br clear="all"></div></div>
      
      
      
      
      
<div id="detailed-features">
    



  <table class="title-wrapper" style="width:100%;"><tbody>
    <tr>
      <td><h2>Detailed Features</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>




</div>



      <div class="kindle-feature"><div class="headline">
Elegant, Easy-to-Use Design
</div><div class="sub-headline"><b>Lose Yourself in Your Reading</b><br clear="all">
The most elegant feature of a physical book is that it disappears while you're reading. Immersed in the author's world and ideas, you don't notice a book's glue, the stitching, or ink. Our top design objective is to make Kindle Touch disappear  just like a physical book  so you can get lost in your reading, not the technology.
<br clear="all"><br clear="all"><b>Ergonomic Design</b><br clear="all">
Kindle Touch is easy to hold and read. We designed it with long-form reading in mind. When reading for long periods of time, people naturally shift positions and often like to read with one hand. Kindle Touch has a new ergonomic design so it can be held comfortably however you choose to read. 
<br clear="all"><br clear="all"><b>Touch Controls and Virtual Keyboard</b><br clear="all">
Kindle Touch features a full touchscreen display that puts page turns, navigation and note-taking at your fingertips. Tap unknown words to call up definitions in the dictionary, highlight sections of text to send to a friend, or search, shop and type with a virtual keyboard that appears on screen just when you need it and provides suggestions as you type. 
<br clear="all"><br clear="all"><a name="whispertap"></a><b>New Touch Experience - EasyReach</b><br clear="all">
Amazon invented a new type of touch experience that eliminates the fatigue caused by continuously swiping to turn the page, and that allows readers to hold Kindle with either hand while still turning pages comfortably. With EasyReach, Kindle Touch users can effortlessly page forward in a book or a newspaper while holding the device with either hand. Tapping on most of the screen area will turn the page forward, the most common action done when reading; tapping in a narrow area near the left edge of the device turns to the previous page; and tapping on the top part of the screen brings up the toolbars for further options. This is another way that Kindle helps readers get lost in the author's world.
<br clear="all"><br clear="all"><b>Never Gets Hot</b><br clear="all">
Unlike a laptop, Kindle Touch never gets hot so you can read comfortably as long as you like.
<br clear="all"><br clear="all"></div><div class="headline">
Wireless Capability
</div><div class="sub-headline"><b>Built-in Wi-Fi</b><br clear="all">
Kindle Touch automatically detects nearby Wi-Fi networks at school, home, or your favorite caf. At a hotel or caf that requires a password? Simply enter the password and connect to the network. Once you have added a Wi-Fi network, Kindle Touch will automatically connect to that network the next time youre near the hotspot.
<br clear="all"><br clear="all"></div><div class="headline"><a name="Reading on Kindle"></a>
Reading on Kindle
</div><div class="sub-headline"><b>Adjustable Text Size</b><br clear="all">Kindle Touch has eight adjustable font sizes to suit your reading preference. You can increase the text size of your favourite book, newspaper or magazine with the push of a button. If your eyes tire, simply increase the font size and continue reading comfortably. Kindle Touch also has three font styles to choose from  all optimised and hand-tuned to provide the best reading experience.  
<br clear="all"><br clear="all"><b>Custom Fonts</b><br clear="all">
Kindle Touch uses hand-built, custom fonts and font-hinting to make words and letters more crisp, clear, and natural-looking. Font hints are instructions, written as code, that control points on a font character's line, improving legibility at small font sizes where few pixels are available. Hinting is a mix of aesthetic judgments and complicated technical strategies. We've designed our proprietary font-hinting to optimise specifically for the special characteristics of electronic ink. 
<br clear="all"><br clear="all"><b>Fast Page Turns </b><br clear="all">
Kindle Touch has fast page turns. Weve done this by fine-tuning Kindle Touchs proprietary waveform, the series of electronic pulses that move black and white electronic ink particles to achieve an optimal display of images and text. 
<br clear="all"><br clear="all"><b>Rotate Between Portrait and Landscape Mode </b><br clear="all">
Switch between portrait and landscape orientation to read maps, graphs and tables more easily. 
<br clear="all"><br clear="all"><b>Support for Non-Latin Characters</b><br clear="all">
Kindle Touch supports the display of non-Latin characters, so you can read books and documents in the translation thats right for you.  Kindle displays Cyrillic (such as Russian), Japanese, Chinese (Traditional and Simplified), and Korean characters, in addition to Latin and Greek scripts.  <br clear="all"><br clear="all"><b>Full Image Zoom</b><br clear="all">
Images and photos display crisply on Kindle Touch and can be zoomed to the full size of the screen. 
<br clear="all"><br clear="all"><b>Real Page Numbers </b><br clear="all">
Easily reference and cite passages or read alongside others in a book club or class with real page numbers.  Using the computing fabric of Amazon Web Services, we've created algorithms that match specific text in a Kindle book to the corresponding text in a print book, to identify the correct, "real" page number to display.   Available on tens of thousands of our most popular Kindle books, including the top 100 bestselling books in the Kindle Store that have matching print editions.  Page numbers are displayed when you push the menu button.
<br clear="all"><br clear="all"><b>Carry and Read Your Personal Documents</b><br clear="all">
Kindle Touch makes it easy to take your personal documents with you, eliminating the need to print. You and your approved contacts can e-mail documents  including Word, PDF and more - directly to your Kindle and read them in Kindle format. Your personal documents will be stored in your Kindle library on Amazon and ready to download conveniently anywhere at any time. You can add notes, highlights and bookmarks, which are automatically synchronized across devices along with the last page you read using our Whispersync technology. 
<br clear="all"><br clear="all">
You can read your PDFs in their native format and convert them to the Kindle format so that it reflows like a regular Kindle book. <a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=amb_link_163211287_1?ie=UTF8&nodeId=200767360&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-21-0&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ&pf_rd_t=201&pf_rd_p=321882607&pf_rd_i=B005890FUI#pdocfees" target="_blank">Learn More</a><br clear="all"><br clear="all"></div><div class="headline">
Dictionary and Search
</div><div class="sub-headline"><b>Built-In Dictionary with Instant Lookup</b><br clear="all">
Come across a word you don't know? Kindle Touch includes The New Oxford English Dictionary with over 250,000 entries and definitions for free. Kindle Touch lets you instantly look up the definition without ever leaving the book  simply touch and hold the word you want to check and the definition will automatically display at the bottom of the screen.
<br clear="all"><br clear="all"><b>Search Wikipedia and the Web</b><br clear="all">
Kindle Touch makes it easy to find what you're looking for. Just enter a word or phrase and Kindle will search every instance across your Kindle library, in the Kindle Store, on Wikipedia, or the Web using Google search. 

<br clear="all"><br clear="all"><a name="xray"></a><b>X-Ray</b><br clear="all">
For Kindle Touch, Amazon invented X-Ray - a new feature that lets customers explore the bones of the book. With a single tap, readers can see all the passages across a book that mention ideas, fictional characters, historical figures, places or topics that interest them, as well as more detailed descriptions from Wikipedia and Shelfari, Amazons community-powered encyclopedia for book lovers.   
<br clear="all"><br clear="all">
Amazon built X-Ray using its expertise in language processing and machine learning, access to significant storage and computing resources with Amazon S3 and EC2, and a deep library of book and character information.  The vision is to have every important phrase in every book. 

<br clear="all"><br clear="all"></div><div class="headline">
Notes and Sharing
</div><div class="sub-headline"><b>Bookmarks and Annotations
</b><br clear="all">
Add annotations to text, just like you might write in the margins of a book, with a virtual keyboard that appears just when you need it. And because it is digital, you can edit, delete, and export your notes. You can highlight and clip key passages and bookmark pages for future use. You'll never need to bookmark your last place in the book, because Kindle remembers for you and always opens to the last page you read.
<br clear="all"><br clear="all"><b>Popular Highlights</b><br clear="all">
See what millions of Kindle readers think are the most interesting passages in your books. If several other readers have highlighted a particular passage, then that passage will be highlighted in your book along with the total number of people who have highlighted it.  <a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=amb_link_163211287_2?ie=UTF8&nodeId=200838580&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-21-0&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ&pf_rd_t=201&pf_rd_p=321882607&pf_rd_i=B005890FUI#pop" target="_blank">View Details</a><br clear="all"><br clear="all"><b>Share Meaningful Passages</b><br clear="all">
Share your passion for books and reading with friends, family, and other readers around the world by posting meaningful passages to social networks like Facebook and Twitter directly from Kindle, without leaving the page. Want to post or tweet about a great new novel or newspaper article? When you highlight or create a note in your book or periodical, you can easily share it with your social network. Help your network of family and friends discover new authors and books. 
<br clear="all"><br clear="all"><b>Public Notes</b><br clear="all">
Share your notes and see what others are saying about Kindle books. Any Kindle user  including authors, book reviewers, professors and passionate readers everywhere  can opt-in to share their thoughts on book passages and ideas with friends, family members, colleagues, and the greater Kindle community. <a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=amb_link_163211287_3?ie=UTF8&nodeId=200838580&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-21-0&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ&pf_rd_t=201&pf_rd_p=321882607&pf_rd_i=B005890FUI#public" target="_blank">Learn More</a><br clear="all"><br clear="all"></div><div class="headline">
Customise Your Kindle
</div><div class="sub-headline"><b>Choose Your Language</b><br clear="all">
You can customise your Kindle with the language you prefer.  You can set your default language on Kindle to English (U.S. and U.K.), German, French, Spanish, Italian, or Brazilian Portuguese.  
<br clear="all"><br clear="all"><b>Organise Your Library</b><br clear="all">
Organise your Kindle library into customised collections, or categories, to easily access any book you are looking for. You can add an item to multiple collections to make organising and finding titles even easier. For example, you can add the same book to your "History" and "My Favourite Authors" collections. 
<br clear="all"><br clear="all"><b>Password Protection</b><br clear="all">
With password protection functionality, you can choose to lock your Kindle automatically when not in use.

</div><div class="headline">
The Kindle Store
</div><div class="sub-headline">
Access the Kindle Store wirelessly right from your Kindle Touch  search and shop the worlds largest selection of books that people want to read, plus magazines, newspapers and blogs. We auto-deliver all your purchases in seconds  simply search, buy, and youre ready to read.
<br clear="all"><br clear="all"><b>Personalised Recommendations</b><br clear="all">
Kindle Touch makes it easy to discover new titles with recommendations personalised just for you.  Kindle uses the same personalised customer experience you're used to across Amazon.co.uk, matching our best recommendations to your personal reading habits.
<br clear="all"><br clear="all"><b>Huge Selection, Low Prices</b><br clear="all">
With the biggest selection of any ebook store in the UK, you can shop more than 1 million books, including bestsellers and new releases, UK and international newspapers, magazines, and blogs. Over 1 million free books, such as <i>Pride and Prejudice</i> and <i>Treasure Island</i>, are also available.

<br clear="all"><br clear="all">
Our vision for Kindle is to have every book ever written, in every language, available in 60 seconds from anywhere on earth. 

<br clear="all"><br clear="all"><b>Newspapers &amp; Magazines</b><br clear="all">
Shop and subscribe to your favourite magazines and newspapers such as <i>The Times</i>, <i>The Guardian</i>, and <i>The Economist</i>. New editions are auto-delivered wirelessly direct to your device the second they go on sale.
<br clear="all"><br clear="all"></div><div class="headline">
Experimental Features 
</div><div class="sub-headline"><b>WebKit-Based Browser</b><br clear="all">Kindle's experimental web browser is based on WebKit. It's easy to find the information you're looking for right from your Kindle Touch. Experimental web browsing is free. <br clear="all"><br clear="all"><b>Read-to-Me</b><br clear="all">With the Text-to-Speech feature turned on, Kindle Touch can read English newspapers, magazines, blogs and books out loud to you, unless the book's rights holder made the feature unavailable. You can switch back and forth between reading and listening, and your spot is automatically saved. Pages automatically turn while the content is being read, so you can listen hands-free. You can choose from both male and female voices which can be sped up or slowed down to suit your preference. In the middle of a great story or article but have to jump in the car? Simply turn on Text-to-Speech and listen on the go. <br clear="all"><br clear="all"><b>Listen to Music and Podcasts</b><br clear="all">Transfer MP3 files to Kindle Touch to play as background music while you read. You can quickly and easily transfer MP3 files via USB by connecting Kindle Touch to your computer.
<br clear="all"><br clear="all"></div></div>
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
    </td>
    <td valign="top" align="left" width="385">
      
      
      <div class="right-column-images"><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/eink-text._V138789301_.jpg" width="350" align="left" alt="E Ink fonts are sharp and clear like real paper." height="220" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
E Ink fonts are sharp and clear like real paper
</div></td></tr><tr><td valign="top"><br><br><br><br><br></td></tr><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-features-01._V134401302_.jpg" width="350" align="left" alt="Shop the Kindle Store, direct from your device" height="350" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
Shop the Kindle Store, direct from your device
</div></td></tr><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-features-02._V134401297_.jpg" width="350" align="left" alt="Choose from eight adjustable text sizes and three font styles" height="350" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
Choose from eight adjustable text sizes and three font styles
</div></td></tr><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-features-03._V134401296_.jpg" width="350" align="left" alt="Look up words with built-in dictionary " height="350" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
Look up words with built-in dictionary 
</div></td></tr><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-features-04._V134401297_.jpg" width="350" align="left" alt="Touchscreen keyboard" height="350" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
Touchscreen keyboard
</div></td></tr><tr><td valign="top"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/uk-kw-features-06._V134401296_.jpg" width="350" align="left" alt="Kit out your Kindle from our broad selection of accessories" height="350" border="0"></td></tr><tr><td valign="top"><div class="rightColumnCaption">
Kit out your Kindle from our broad selection of accessories
</div></td></tr></tbody></table></div>
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
    </td>
  </tr>
</tbody></table>


<div id="kindle-store">
    



  <table class="title-wrapper" style="margin-right:385px;"><tbody>
    <tr>
      <td><h2>Kindle Store</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>




</div>



    






    














<div id="kindle-shoveler-731">
<noscript>
.kindle-shoveler-nojs-hidden {
    visibility: hidden;   
}
</noscript>










<link rel="stylesheet" type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/GB-combined-1155515822._V400694269_.css">




<noscript>
&lt;style type="text/css"&gt;
.kindleTab-noJS-hidden {
    visibility: hidden;
}
&lt;/style&gt;
</noscript>

<div class="kindleTab-tabs kindleTab-noJS-hidden">
<table cellpadding="0" cellspacing="0">
<tbody><tr>
<td class="kindleTab-tab-spacer kindleTab-left-spacer">&nbsp;</td>
<td id="W731_tab1" content-id="W731_1" class="kindleTab-tab kindleTab-active-tab" width="200">
    <div class="cBox secondary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Bestsellers 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W731_tab2" content-id="W731_2" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Free Classics 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W731_tab3" content-id="W731_3" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Newspapers 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W731_tab4" content-id="W731_4" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Magazines 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>


<script type="text/javascript">
amznJQ.onReady('kindleTabsJS', function () {
    new KDS.common.Shoveler({
        containerId: 'kindle-shoveler-731', 
        leftSpacerMargin: 860,
        tabChangeCallback: 
                function(tabId, contentId) {
                    kindleShovelers[contentId].updateUI(false,false);
                }
    });
});
</script>

<td class="kindleTab-right-spacer" style="width: 410px;">&nbsp;</td>
</tr>
</tbody></table>
</div>
<div style="margin:0 15px 0 40px;">
<div id="W731_1" class="shoveler kindleTab-active-content">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Bestsellers&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">5 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        




















  
  





























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Girl-Dragon-Tattoo-ebook/dp/B002RI9ZQ8/ref=_1_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51aiFJHCJnL._SY110_.jpg" width="72" alt="The Girl with the Dragon Tattoo" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Girl with the Dragon Tattoo" href="http://www.amazon.co.uk/The-Girl-Dragon-Tattoo-ebook/dp/B002RI9ZQ8/ref=_1_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Girl with the Dragon Tattoo</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B002RI9ZQ8" ref="1_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B002RI9ZQ8/ref=1_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.0 out of 5 stars"><span>4.0 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B002RI9ZQ8/ref=1_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">1,398</a>)</span>
        
        <span class="price">2.70</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B002RI9ZQ8&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B002RI9ZQ8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B002RI9ZQ8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B002RI9ZQ8">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B002RI9ZQ8&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Hanging-Shed-Douglas-ebook/dp/B004G5YVT6/ref=_1_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51GNvqCVMWL._SY110_.jpg" width="71" alt="The Hanging Shed: Douglas Brodie Series, Book 1" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Hanging Shed: Douglas Brodie Series, Book 1" href="http://www.amazon.co.uk/The-Hanging-Shed-Douglas-ebook/dp/B004G5YVT6/ref=_1_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Hanging Shed: Douglas Brodie Series, Book 1</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004G5YVT6" ref="1_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004G5YVT6/ref=1_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004G5YVT6/ref=1_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">285</a>)</span>
        
        <span class="price">2.56</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004G5YVT6&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004G5YVT6">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004G5YVT6">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004G5YVT6">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004G5YVT6&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Room-ebook/dp/B003X27L9U/ref=_1_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51FHAmfv-7L._SY110_.jpg" width="72" alt="Room" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Room" href="http://www.amazon.co.uk/Room-ebook/dp/B003X27L9U/ref=_1_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Room</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003X27L9U" ref="1_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003X27L9U/ref=1_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003X27L9U/ref=1_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">944</a>)</span>
        
        <span class="price">1.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B003X27L9U&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B003X27L9U">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B003X27L9U">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B003X27L9U">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B003X27L9U&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Into-the-Darkest-Corner-ebook/dp/B004OVDVBQ/ref=_1_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41b7QxYxcML._SY110_.jpg" width="72" alt="Into the Darkest Corner" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Into the Darkest Corner" href="http://www.amazon.co.uk/Into-the-Darkest-Corner-ebook/dp/B004OVDVBQ/ref=_1_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Into the Darkest Corner</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004OVDVBQ" ref="1_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004OVDVBQ/ref=1_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.7 out of 5 stars"><span>4.7 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004OVDVBQ/ref=1_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">889</a>)</span>
        
      </div>
    </div></li>      <li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><div style="height:110px">
      <a href="http://www.amazon.co.uk/Game-Thrones-Song-Fire-ebook/dp/B004GJXQ20/ref=_1_5">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51ihcXeXX9L._SY110_.jpg" width="72" height="110" border="0">
      </a>
    </div>
    <div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="A Game of Thrones (A Song of Ice and Fire, Book 1)" href="http://www.amazon.co.uk/Game-Thrones-Song-Fire-ebook/dp/B004GJXQ20/ref=_1_5">A Game of Thrones (A Song of Ice and Fire, Book 1)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004GJXQ20" ref="1_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004GJXQ20/ref=1_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/stars-4-5._V192196957_.gif" width="55" alt="4.5 out of 5 stars" align="absbottom" title="4.5 out of 5 stars" height="12" border="0"></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004GJXQ20/ref=1_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">959</a>)</span>
        
        <span class="price">2.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004GJXQ20&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004GJXQ20">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004GJXQ20">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004GJXQ20">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004GJXQ20&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li></ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/bestsellers/digital-text/341689031/ref=_1_lnk1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Bestsellers

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW731_1 = function(cellStart, numCells) {
    var asins = ['B002RI9ZQ8','B004G5YVT6','B003X27L9U','B004OVDVBQ','B004GJXQ20','B004VSTP08','B004FV4XBC','B002RI9UGI','B003VWBMI8','B002RI9ZX6','B0040GJJOS','B0051GSSRU','B003NX6Y2O','B00457X7O0','B004M8RYZA','B0042JTAIS','B004GKMV3Y','B004VT0WJ0','B0058O84G0','B004I6DDG0','B004WDZZP6','B003XRDBMQ','B00500YCEA','B005EGXTEE'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_1_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW731_1 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; visibility:hidden;\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW731_1 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W731_1'] = jQuery("#W731_1").shoveler(getEndpointW731_1, 24, {
        cellTransformer: getCellContentW731_1,
        onPageChangeCompleteHandler: function() { 
              if (loadedW731_1) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W731_1").addClass('kindleTab-active-content');
  });

  jQuery(document).ready(function() {
      loadedW731_1 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W731_2" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Free Classics&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">2 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Adventures-Sherlock-Holmes-ebook/dp/B000JQU1VS/ref=_2_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/516Hw8yrN2L._SY110_.jpg" width="72" alt="The Adventures of Sherlock Holmes" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Adventures of Sherlock Holmes" href="http://www.amazon.co.uk/The-Adventures-Sherlock-Holmes-ebook/dp/B000JQU1VS/ref=_2_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Adventures of Sherlock Holmes</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000JQU1VS" ref="2_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000JQU1VS/ref=2_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.5 out of 5 stars"><span>4.5 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000JQU1VS/ref=2_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">215</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Dracula-A-Mystery-Story-ebook/dp/B000JQUBRM/ref=_2_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31JqhOSbZ9L._SY110_.jpg" width="73" alt="Dracula: A Mystery Story" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Dracula: A Mystery Story" href="http://www.amazon.co.uk/Dracula-A-Mystery-Story-ebook/dp/B000JQUBRM/ref=_2_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Dracula: A Mystery Story</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000JQUBRM" ref="2_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000JQUBRM/ref=2_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.3 out of 5 stars"><span>4.3 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000JQUBRM/ref=2_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">361</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Pride-and-Prejudice-ebook/dp/B000JMLFLW/ref=_2_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/517sDg5aiCL._SY110_.jpg" width="73" alt="Pride and Prejudice" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Pride and Prejudice" href="http://www.amazon.co.uk/Pride-and-Prejudice-ebook/dp/B000JMLFLW/ref=_2_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Pride and Prejudice</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000JMLFLW" ref="2_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000JMLFLW/ref=2_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.6 out of 5 stars"><span>4.6 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000JMLFLW/ref=2_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">352</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/A-Tale-Two-Cities-ebook/dp/B004EHZXVQ/ref=_2_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51pLBQZ2yLL._SY110_.jpg" width="72" alt="A Tale of Two Cities" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="A Tale of Two Cities" href="http://www.amazon.co.uk/A-Tale-Two-Cities-ebook/dp/B004EHZXVQ/ref=_2_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">A Tale of Two Cities</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004EHZXVQ" ref="2_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004EHZXVQ/ref=2_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.5 out of 5 stars"><span>4.5 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004EHZXVQ/ref=2_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">130</a>)</span>
        
        <span class="price">0.00</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004EHZXVQ&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004EHZXVQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004EHZXVQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004EHZXVQ">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004EHZXVQ&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>      <li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Iliad-ebook/dp/B000JQUHX0/ref=_2_5">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41a4XpAPe4L._SY110_.jpg" width="72" height="110" border="0">
      </a>
    </div>
    <div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Iliad" href="http://www.amazon.co.uk/The-Iliad-ebook/dp/B000JQUHX0/ref=_2_5">The Iliad</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000JQUHX0" ref="2_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000JQUHX0/ref=2_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/stars-4-0._V192198291_.gif" width="55" alt="3.9 out of 5 stars" align="absbottom" title="3.9 out of 5 stars" height="12" border="0"></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000JQUHX0/ref=2_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">25</a>)</span>
        
        <span class="price"></span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B000JQUHX0&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B000JQUHX0">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B000JQUHX0">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B000JQUHX0">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B000JQUHX0&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li></ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_2_lnk1?ie=UTF8&node=434020031&pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Free Classics

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW731_2 = function(cellStart, numCells) {
    var asins = ['B000JQU1VS','B000JQUBRM','B000JMLFLW','B004EHZXVQ','B000JQUHX0','B000JQUT8S','B000JQUA64','B000JMLMXI'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_2_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW731_2 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; visibility:hidden;\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW731_2 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W731_2'] = jQuery("#W731_2").shoveler(getEndpointW731_2, 8, {
        cellTransformer: getCellContentW731_2,
        onPageChangeCompleteHandler: function() { 
              if (loadedW731_2) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W731_2").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW731_2 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W731_3" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Newspapers&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">3 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Times-and-Sunday/dp/B000J0ZPGU/ref=_3_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31IgdZjG7hL._SY110_.jpg" width="82" alt="The Times and Sunday Times" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Times and Sunday Times" href="http://www.amazon.co.uk/The-Times-and-Sunday/dp/B000J0ZPGU/ref=_3_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Times and Sunday Times</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000J0ZPGU" ref="3_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000J0ZPGU/ref=3_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_2_5 " title="2.7 out of 5 stars"><span>2.7 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000J0ZPGU/ref=3_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">179</a>)</span>
        
        <span class="price">14.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B000J0ZPGU&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B000J0ZPGU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B000J0ZPGU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B000J0ZPGU">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B000J0ZPGU&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Guardian-and-the-Observer/dp/B004MME3M8/ref=_3_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31u9v3jHGYL._SY110_.jpg" width="82" alt="The Guardian and the Observer" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Guardian and the Observer" href="http://www.amazon.co.uk/The-Guardian-and-the-Observer/dp/B004MME3M8/ref=_3_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Guardian and the Observer</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004MME3M8" ref="3_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004MME3M8/ref=3_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.0 out of 5 stars"><span>4.0 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004MME3M8/ref=3_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">128</a>)</span>
        
        <span class="price">9.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004MME3M8&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004MME3M8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004MME3M8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004MME3M8">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004MME3M8&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Telegraph/dp/B0028K2YZO/ref=_3_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31Az3dyV3BL._SY110_.jpg" width="82" alt="The Telegraph" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Telegraph" href="http://www.amazon.co.uk/The-Telegraph/dp/B0028K2YZO/ref=_3_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Telegraph</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B0028K2YZO" ref="3_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B0028K2YZO/ref=3_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_3_0 " title="3.2 out of 5 stars"><span>3.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B0028K2YZO/ref=3_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">151</a>)</span>
        
        <span class="price">9.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B0028K2YZO&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B0028K2YZO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B0028K2YZO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B0028K2YZO">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B0028K2YZO&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Daily-Mail-Sunday/dp/B001S2PQY4/ref=_3_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/314-K0knd9L._SY110_.jpg" width="82" alt="The Daily Mail and The Mail on Sunday" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Daily Mail and The Mail on Sunday" href="http://www.amazon.co.uk/The-Daily-Mail-Sunday/dp/B001S2PQY4/ref=_3_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Daily Mail and The Mail on Sunday</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B001S2PQY4" ref="3_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B001S2PQY4/ref=3_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_3_0 " title="2.8 out of 5 stars"><span>2.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B001S2PQY4/ref=3_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">125</a>)</span>
        
        <span class="price">8.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B001S2PQY4&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B001S2PQY4">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B001S2PQY4">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B001S2PQY4">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B001S2PQY4&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>      <li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><div style="height:110px">
      <a href="http://www.amazon.co.uk/Financial-Times-UK-Edition/dp/B002LVV0S2/ref=_3_5">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31ePbEBjmkL._SY110_.jpg" width="82" height="110" border="0">
      </a>
    </div>
    <div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Financial Times - UK Edition" href="http://www.amazon.co.uk/Financial-Times-UK-Edition/dp/B002LVV0S2/ref=_3_5">Financial Times - UK Edition</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B002LVV0S2" ref="3_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B002LVV0S2/ref=3_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/stars-3-5._V192198298_.gif" width="55" alt="3.3 out of 5 stars" align="absbottom" title="3.3 out of 5 stars" height="12" border="0"></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B002LVV0S2/ref=3_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">21</a>)</span>
        
        <span class="price">17.98</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B002LVV0S2&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B002LVV0S2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B002LVV0S2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B002LVV0S2">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B002LVV0S2&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li></ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_3_lnk1?ie=UTF8&node=341691031&pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Newspapers

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW731_3 = function(cellStart, numCells) {
    var asins = ['B000J0ZPGU','B004MME3M8','B0028K2YZO','B001S2PQY4','B002LVV0S2','B000JMJVK4','B002VPE6VQ','B000N8V468','B000GFK7L6','B002KT1ZF8','B000HA4CYS','B000JJ4A9E','B002HMCRJQ','B002EEP3RU'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_3_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW731_3 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; visibility:hidden;\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW731_3 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W731_3'] = jQuery("#W731_3").shoveler(getEndpointW731_3, 14, {
        cellTransformer: getCellContentW731_3,
        onPageChangeCompleteHandler: function() { 
              if (loadedW731_3) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W731_3").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW731_3 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W731_4" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Magazines&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">3 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Economist-UK-Edition/dp/B003VS0BIE/ref=_4_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51Wi8W2MIbL._SY110_.jpg" width="82" alt="The Economist - UK Edition" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Economist - UK Edition" href="http://www.amazon.co.uk/The-Economist-UK-Edition/dp/B003VS0BIE/ref=_4_1?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Economist - UK Edition</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003VS0BIE" ref="4_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003VS0BIE/ref=4_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_2_5 " title="2.3 out of 5 stars"><span>2.3 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003VS0BIE/ref=4_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">42</a>)</span>
        
        <span class="price">9.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B003VS0BIE&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B003VS0BIE">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B003VS0BIE">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B003VS0BIE">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B003VS0BIE&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/The-Spectator/dp/B002CVUQ2M/ref=_4_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51eppdLMeCL._SY110_.jpg" width="84" alt="The Spectator" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="The Spectator" href="http://www.amazon.co.uk/The-Spectator/dp/B002CVUQ2M/ref=_4_2?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">The Spectator</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B002CVUQ2M" ref="4_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B002CVUQ2M/ref=4_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B002CVUQ2M/ref=4_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">24</a>)</span>
        
        <span class="price">2.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B002CVUQ2M&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B002CVUQ2M">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B002CVUQ2M">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B002CVUQ2M">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B002CVUQ2M&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Foreign-Affairs/dp/B00284BH62/ref=_4_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51CFTw+rg4L._SY110_.jpg" width="78" alt="Foreign Affairs" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Foreign Affairs" href="http://www.amazon.co.uk/Foreign-Affairs/dp/B00284BH62/ref=_4_3?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Foreign Affairs</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B00284BH62" ref="4_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B00284BH62/ref=4_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B00284BH62/ref=4_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">8</a>)</span>
        
        <span class="price">1.49</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B00284BH62&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B00284BH62">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B00284BH62">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B00284BH62">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B00284BH62&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Asimovs-Science-Fiction/dp/B000N8V3F0/ref=_4_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51DS6MqpXUL._SY110_.jpg" width="75" alt="Asimov&#39;s Science Fiction" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Asimov&#39;s Science Fiction" href="http://www.amazon.co.uk/Asimovs-Science-Fiction/dp/B000N8V3F0/ref=_4_4?pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Asimov's Science Fiction</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B000N8V3F0" ref="4_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B000N8V3F0/ref=4_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B000N8V3F0/ref=4_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">19</a>)</span>
        
        <span class="price">1.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B000N8V3F0&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B000N8V3F0">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B000N8V3F0">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B000N8V3F0">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B000N8V3F0&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>      <li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><div style="height:110px">
      <a href="http://www.amazon.co.uk/New-Statesman/dp/B0026RHKC6/ref=_4_5">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51ROFoJu56L._SY110_.jpg" width="83" height="110" border="0">
      </a>
    </div>
    <div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="New Statesman" href="http://www.amazon.co.uk/New-Statesman/dp/B0026RHKC6/ref=_4_5">New Statesman</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B0026RHKC6" ref="4_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B0026RHKC6/ref=4_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/stars-3-5._V192198298_.gif" width="55" alt="3.6 out of 5 stars" align="absbottom" title="3.6 out of 5 stars" height="12" border="0"></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B0026RHKC6/ref=4_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">12</a>)</span>
        
        <span class="price">4.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; visibility:hidden;">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B0026RHKC6&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B0026RHKC6">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B0026RHKC6">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B0026RHKC6">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B0026RHKC6&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li></ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_4_lnk1?ie=UTF8&node=341690031&pf_rd_p=285652787&pf_rd_s=center-41&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Magazines

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW731_4 = function(cellStart, numCells) {
    var asins = ['B003VS0BIE','B002CVUQ2M','B00284BH62','B000N8V3F0','B0026RHKC6','B004GUSDVI','B004ZFZ4O8','B001AHPAX4','B002A9JXY8','B001RTSGRM','B001P80M1S','B003GAN58K','B000HA4FKO'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_4_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW731_4 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; visibility:hidden;\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW731_4 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W731_4'] = jQuery("#W731_4").shoveler(getEndpointW731_4, 13, {
        cellTransformer: getCellContentW731_4,
        onPageChangeCompleteHandler: function() { 
              if (loadedW731_4) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W731_4").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW731_4 = true;
  });
});

</script>

</div>
<div style="clear:both"></div>


                                                                                                      
                                                                                                      

<div id="kindle-accessories">
    



  <table class="title-wrapper" style="margin-right:385px;"><tbody>
    <tr>
      <td><h2>Kindle Accessories</h2></td>
      <td class="title-underline"><div>&nbsp;</div></td>
    </tr>
  </tbody></table>




</div>



    




    














<div id="kindle-shoveler-733">
<noscript>
.kindle-shoveler-nojs-hidden {
    visibility: hidden;   
}
</noscript>






<noscript>
&lt;style type="text/css"&gt;
.kindleTab-noJS-hidden {
    visibility: hidden;
}
&lt;/style&gt;
</noscript>

<div class="kindleTab-tabs kindleTab-noJS-hidden">
<table cellpadding="0" cellspacing="0">
<tbody><tr>
<td class="kindleTab-tab-spacer kindleTab-left-spacer">&nbsp;</td>
<td id="W733_tab1" content-id="W733_1" class="kindleTab-tab kindleTab-active-tab" width="200">
    <div class="cBox secondary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Recommended 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W733_tab2" content-id="W733_2" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Covers 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W733_tab3" content-id="W733_3" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Sleeves 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W733_tab4" content-id="W733_4" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Skins 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W733_tab5" content-id="W733_5" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Reading lights 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>

<td id="W733_tab6" content-id="W733_6" class="kindleTab-tab kindleTab-inactive-tab" width="200">
    <div class="cBox primary">
        <span class="cBoxTL"></span>
        <span class="cBoxTR"></span>
        <span class="cBoxR"></span>
        <div class="cBoxInner" tabindex="0">
            Power adapters 
        </div>
    </div>
</td>
<td class="kindleTab-tab-spacer">&nbsp;</td>


<script type="text/javascript">
amznJQ.onReady('kindleTabsJS', function () {
    new KDS.common.Shoveler({
        containerId: 'kindle-shoveler-733', 
        leftSpacerMargin: 1280,
        tabChangeCallback: 
                function(tabId, contentId) {
                    kindleShovelers[contentId].updateUI(false,false);
                }
    });
});
</script>

<td class="kindleTab-right-spacer">&nbsp;</td>
</tr>
</tbody></table>
</div>
<div style="margin:0 15px 0 40px;">
<div id="W733_1" class="shoveler kindleTab-active-content">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Recommended&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">5 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Leather-Cover/dp/B004SD22PQ/ref=_1_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/311lfBUM3pL._SY110_.jpg" width="78" alt="Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Leather-Cover/dp/B004SD22PQ/ref=_1_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD22PQ" ref="1_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD22PQ/ref=1_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.4 out of 5 stars"><span>4.4 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD22PQ/ref=1_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">147</a>)</span>
        
        <span class="price">30.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004SD22PQ&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004SD22PQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004SD22PQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004SD22PQ">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004SD22PQ&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Lighted-Leather-Paperwhite/dp/B004SD262U/ref=_1_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41IrsrP3ATL._SY110_.jpg" width="66" alt="Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)" href="http://www.amazon.co.uk/Amazon-Kindle-Lighted-Leather-Paperwhite/dp/B004SD262U/ref=_1_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD262U" ref="1_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD262U/ref=1_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD262U/ref=1_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">188</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Paperwhite-Touch/dp/B004SD27DI/ref=_1_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/513bXuIJZIL._SY110_.jpg" width="90" alt="Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Paperwhite-Touch/dp/B004SD27DI/ref=_1_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD27DI" ref="1_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD27DI/ref=1_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.9 out of 5 stars"><span>3.9 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD27DI/ref=1_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">167</a>)</span>
        
        <span class="price">20.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004SD27DI&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004SD27DI">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004SD27DI">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004SD27DI">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004SD27DI&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Reader-Adapter-charger-Paperwhite-Keyboard/dp/B005DOKDQO/ref=_1_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31yViAv-MjL._SY110_.jpg" width="122" alt="e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" href="http://www.amazon.co.uk/Reader-Adapter-charger-Paperwhite-Keyboard/dp/B005DOKDQO/ref=_1_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005DOKDQO" ref="1_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005DOKDQO/ref=1_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005DOKDQO/ref=1_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">609</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005DOKDQO&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005DOKDQO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005DOKDQO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005DOKDQO">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005DOKDQO&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Kindle-Touch-e-Reader-Touch-Screen-Wi-Fi/dp/B006X5F0NS/ref=_1_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31SE2FZiKIL._SY110_.jpg" width="110" alt="3-Year SquareTrade Warranty + Accident Protection &amp; Theft Cover for Kindle Touch, UK customers only" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="3-Year SquareTrade Warranty + Accident Protection &amp; Theft Cover for Kindle Touch, UK customers only" href="http://www.amazon.co.uk/Kindle-Touch-e-Reader-Touch-Screen-Wi-Fi/dp/B006X5F0NS/ref=_1_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">3-Year SquareTrade Warranty + Accident Protection &amp; Theft Cover for Kindle Touch, UK customers only</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B006X5F0NS" ref="1_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B006X5F0NS/ref=1_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_5_0 " title="4.8 out of 5 stars"><span>4.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B006X5F0NS/ref=1_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">75</a>)</span>
        
        <span class="price">29.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B006X5F0NS&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B006X5F0NS">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B006X5F0NS">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B006X5F0NS">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B006X5F0NS&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























      </ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_1_lnk1?ie=UTF8&node=1501220031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Touch Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_1 = function(cellStart, numCells) {
    var asins = ['B004SD22PQ','B004SD262U','B004SD27DI','B005DOKDQO','B006X5F0NS','B005HSG3L0','B003FZA1MY','B005Z44NW2','B004SD26Z2','B005HSG446','B004SD26E8','B004SD23G4','B005KELQEU','B004SD27OC','B004D39RMW','B005HSG482','B004SD25SK','B005HSG3JC','B005Z44MSC','B004SD2562','B004SD23SW','B004SD283M','B004SD249A','B003FZA1OW'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_1_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_1 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_1 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_1'] = jQuery("#W733_1").shoveler(getEndpointW733_1, 24, {
        cellTransformer: getCellContentW733_1,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_1) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_1").addClass('kindleTab-active-content');
  });

  jQuery(document).ready(function() {
      loadedW733_1 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W733_2" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Covers&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">5 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Leather-Cover/dp/B004SD22PQ/ref=_2_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/311lfBUM3pL._SY110_.jpg" width="78" alt="Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Leather-Cover/dp/B004SD22PQ/ref=_2_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Touch Leather Cover, Black (only fits Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD22PQ" ref="2_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD22PQ/ref=2_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.4 out of 5 stars"><span>4.4 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD22PQ/ref=2_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">147</a>)</span>
        
        <span class="price">30.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004SD22PQ&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004SD22PQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004SD22PQ">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004SD22PQ">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004SD22PQ&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Lighted-Leather/dp/B004SD26E8/ref=_2_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/419Xp4YXg2L._SY110_.jpg" width="66" alt="Amazon Kindle Touch Lighted Leather Cover, Olive Green (only fits Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Touch Lighted Leather Cover, Olive Green (only fits Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Touch-Lighted-Leather/dp/B004SD26E8/ref=_2_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Touch Lighted Leather Cover, Olive Green (only fits Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD26E8" ref="2_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD26E8/ref=2_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD26E8/ref=2_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">188</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Marware-Eco-Vue-Kindle-Cover-Paperwhite/dp/B005HSG482/ref=_2_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41XCwvdCcVL._SY110_.jpg" width="110" alt="Marware Eco-Vue Kindle Cover, Pink (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Marware Eco-Vue Kindle Cover, Pink (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Marware-Eco-Vue-Kindle-Cover-Paperwhite/dp/B005HSG482/ref=_2_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Marware Eco-Vue Kindle Cover, Pink (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005HSG482" ref="2_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005HSG482/ref=2_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.6 out of 5 stars"><span>4.6 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005HSG482/ref=2_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">181</a>)</span>
        
        <span class="price">29.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005HSG482&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005HSG482">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005HSG482">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005HSG482">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005HSG482&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Marware-Atlas-Kindle-Cover-Paperwhite/dp/B005HSG3JC/ref=_2_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41qqA02sYcL._SY110_.jpg" width="110" alt="Marware Atlas Kindle Cover, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Marware Atlas Kindle Cover, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Marware-Atlas-Kindle-Cover-Paperwhite/dp/B005HSG3JC/ref=_2_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Marware Atlas Kindle Cover, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005HSG3JC" ref="2_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005HSG3JC/ref=2_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.4 out of 5 stars"><span>4.4 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005HSG3JC/ref=2_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">160</a>)</span>
        
        <span class="price">26.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005HSG3JC&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005HSG3JC">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005HSG3JC">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005HSG3JC">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005HSG3JC&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Lighted-Leather-Paperwhite/dp/B004SD262U/ref=_2_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41IrsrP3ATL._SY110_.jpg" width="66" alt="Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)" href="http://www.amazon.co.uk/Amazon-Kindle-Lighted-Leather-Paperwhite/dp/B004SD262U/ref=_2_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Touch Lighted Leather Cover, Saddle Tan (does not fit Kindle Paperwhite)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD262U" ref="2_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD262U/ref=2_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD262U/ref=2_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">188</a>)</span>
        
      </div>
    </div></li>





  
  




























      </ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_2_lnk1?ie=UTF8&node=1501073031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all covers for Kindle Touch

    </span>
</a>
</span><span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_2_lnk2?ie=UTF8&node=341687031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_2 = function(cellStart, numCells) {
    var asins = ['B004SD22PQ','B004SD26E8','B005HSG482','B005HSG3JC','B004SD262U','B004SD25SK','B006ZBWV0K','B004SD23SW','B005HSG338','B004SD249A','B004SD23G4','B005KDY8NM','B006ZBWVIC','B005KDY756','B005HSG31K','B005HSG3LK','B005HSG446','B005HSG35Q','B006ZBWV0K','B00609PBRW','B005KDY8AU','B005K2YEOG'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_2_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_2 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_2 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_2'] = jQuery("#W733_2").shoveler(getEndpointW733_2, 22, {
        cellTransformer: getCellContentW733_2,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_2) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_2").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW733_2 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W733_3" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Sleeves&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">4 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Graphite-Paperwhite/dp/B004SD26Z2/ref=_3_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41+mnwarTLL._SY110_.jpg" width="96" alt="Amazon Kindle Zip Sleeve, Graphite (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Zip Sleeve, Graphite (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Graphite-Paperwhite/dp/B004SD26Z2/ref=_3_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Zip Sleeve, Graphite (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD26Z2" ref="3_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD26Z2/ref=3_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.9 out of 5 stars"><span>3.9 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD26Z2/ref=3_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">167</a>)</span>
        
        <span class="price">20.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004SD26Z2&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004SD26Z2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004SD26Z2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004SD26Z2">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004SD26Z2&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Belkin-Neoprene-Portfolio-Kindle-Paperwhite/dp/B005KELQEU/ref=_3_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41Gce+5JHDL._SY110_.jpg" width="121" alt="Belkin Neoprene Portfolio Case for Kindle, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Belkin Neoprene Portfolio Case for Kindle, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Belkin-Neoprene-Portfolio-Kindle-Paperwhite/dp/B005KELQEU/ref=_3_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Belkin Neoprene Portfolio Case for Kindle, Black (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005KELQEU" ref="3_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005KELQEU/ref=3_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.4 out of 5 stars"><span>4.4 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005KELQEU/ref=3_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">14</a>)</span>
        
        <span class="price">19.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005KELQEU&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005KELQEU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005KELQEU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005KELQEU">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005KELQEU&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/BUILT-Neoprene-Kindle-Sleeve-Paperwhite/dp/B005I6DIPU/ref=_3_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/517s-BMGhmL._SY110_.jpg" width="110" alt="BUILT Slim Neoprene Kindle Sleeve, Vine (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="BUILT Slim Neoprene Kindle Sleeve, Vine (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/BUILT-Neoprene-Kindle-Sleeve-Paperwhite/dp/B005I6DIPU/ref=_3_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">BUILT Slim Neoprene Kindle Sleeve, Vine (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005I6DIPU" ref="3_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005I6DIPU/ref=3_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005I6DIPU/ref=3_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">70</a>)</span>
        
        <span class="price">24.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005I6DIPU&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005I6DIPU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005I6DIPU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005I6DIPU">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005I6DIPU&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Paperwhite-Touch/dp/B004SD27DI/ref=_3_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/513bXuIJZIL._SY110_.jpg" width="90" alt="Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Amazon-Kindle-Sleeve-Paperwhite-Touch/dp/B004SD27DI/ref=_3_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Amazon Kindle Zip Sleeve, Blue (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004SD27DI" ref="3_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004SD27DI/ref=3_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.9 out of 5 stars"><span>3.9 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004SD27DI/ref=3_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">167</a>)</span>
        
        <span class="price">20.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B004SD27DI&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B004SD27DI">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B004SD27DI">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B004SD27DI">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B004SD27DI&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Neoprene-Kindle-Sleeve-Scatter-Paperwhite/dp/B005I6DIKU/ref=_3_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/518qiaFV2tL._SY110_.jpg" width="110" alt="BUILT Slim Neoprene Kindle Sleeve, Scatter Dot (fits Kindle Paperwhite, Kindle and Kindle Touch)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="BUILT Slim Neoprene Kindle Sleeve, Scatter Dot (fits Kindle Paperwhite, Kindle and Kindle Touch)" href="http://www.amazon.co.uk/Neoprene-Kindle-Sleeve-Scatter-Paperwhite/dp/B005I6DIKU/ref=_3_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">BUILT Slim Neoprene Kindle Sleeve, Scatter Dot (fits Kindle Paperwhite, Kindle and Kindle Touch)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005I6DIKU" ref="3_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005I6DIKU/ref=3_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005I6DIKU/ref=3_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">70</a>)</span>
        
        <span class="price">24.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005I6DIKU&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005I6DIKU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005I6DIKU">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005I6DIKU">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005I6DIKU&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























      </ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_3_lnk1?ie=UTF8&node=1501216031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all sleeves for Kindle Touch

    </span>
</a>
</span><span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_3_lnk2?ie=UTF8&node=341687031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_3 = function(cellStart, numCells) {
    var asins = ['B004SD26Z2','B005KELQEU','B005I6DIPU','B004SD27DI','B005I6DIKU','B004SD27OC','B005KELS6Q','B004SD27WE','B005K2Z2O2','B004SD283M','B005KELSLQ','B005I6DI1O','B005I6DI7I','B005KELR3A','B005I6DIFU','B005K2Z99U'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_3_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_3 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_3 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_3'] = jQuery("#W733_3").shoveler(getEndpointW733_3, 16, {
        cellTransformer: getCellContentW733_3,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_3) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_3").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW733_3 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W733_4" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Skins&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">4 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Doodle/dp/B005Z44NW2/ref=_4_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/61tIqAN4QfL._SY110_.jpg" width="110" alt="Decalgirl Kindle Touch Skin - Doodle Color" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Decalgirl Kindle Touch Skin - Doodle Color" href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Doodle/dp/B005Z44NW2/ref=_4_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Decalgirl Kindle Touch Skin - Doodle Color</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005Z44NW2" ref="4_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005Z44NW2/ref=4_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_3_0 " title="3.0 out of 5 stars"><span>3.0 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005Z44NW2/ref=4_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">9</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005Z44NW2&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005Z44NW2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005Z44NW2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005Z44NW2">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005Z44NW2&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Moon/dp/B005Z44NIG/ref=_4_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51b2Ubf4HBL._SY110_.jpg" width="110" alt="Decalgirl Kindle Touch Skin - Moon Tree" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Decalgirl Kindle Touch Skin - Moon Tree" href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Moon/dp/B005Z44NIG/ref=_4_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Decalgirl Kindle Touch Skin - Moon Tree</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005Z44NIG" ref="4_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005Z44NIG/ref=4_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005Z44NIG/ref=4_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">2</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005Z44NIG&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005Z44NIG">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005Z44NIG">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005Z44NIG">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005Z44NIG&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Paris/dp/B005Z44RVY/ref=_4_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/5190q3Zu27L._SY110_.jpg" width="110" alt="Decalgirl Kindle Touch Skin - Paris Makes me Happy" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Decalgirl Kindle Touch Skin - Paris Makes me Happy" href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Paris/dp/B005Z44RVY/ref=_4_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Decalgirl Kindle Touch Skin - Paris Makes me Happy</a>
      </div>
      <div style="padding-top: 3px">
        
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005Z44RVY&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005Z44RVY">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005Z44RVY">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005Z44RVY">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005Z44RVY&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Abstraction/dp/B005Z44ZF2/ref=_4_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/516OJkM05ZL._SY110_.jpg" width="110" alt="Decalgirl Kindle Touch Skin - Her Abstraction" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Decalgirl Kindle Touch Skin - Her Abstraction" href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Abstraction/dp/B005Z44ZF2/ref=_4_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Decalgirl Kindle Touch Skin - Her Abstraction</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005Z44ZF2" ref="4_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005Z44ZF2/ref=4_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_1_0 " title="1.0 out of 5 stars"><span>1.0 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005Z44ZF2/ref=4_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">2</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005Z44ZF2&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005Z44ZF2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005Z44ZF2">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005Z44ZF2">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005Z44ZF2&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Blossoming/dp/B005Z44MZA/ref=_4_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/51Lo8SdGtbL._SY110_.jpg" width="110" alt="Decalgirl Kindle Touch Skin - Blossoming Almond Tree" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Decalgirl Kindle Touch Skin - Blossoming Almond Tree" href="http://www.amazon.co.uk/Decalgirl-Kindle-Touch-Skin-Blossoming/dp/B005Z44MZA/ref=_4_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Decalgirl Kindle Touch Skin - Blossoming Almond Tree</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005Z44MZA" ref="4_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005Z44MZA/ref=4_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="4.2 out of 5 stars"><span>4.2 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005Z44MZA/ref=4_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">4</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005Z44MZA&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005Z44MZA">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005Z44MZA">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005Z44MZA">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005Z44MZA&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























      </ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_4_lnk1?ie=UTF8&node=1501207031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all skins for Kindle Touch

    </span>
</a>
</span><span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_4_lnk2?ie=UTF8&node=341687031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_4 = function(cellStart, numCells) {
    var asins = ['B005Z44NW2','B005Z44NIG','B005Z44RVY','B005Z44ZF2','B005Z44MZA','B005Z44MSC','B005Z44UN4','B005Z44XZY','B005Z44ZKC','B005Z44NPE','B005Z44ODU','B005Z44SQI','B005Z44PI4','B005Z44VZ6','B005Z44U8E','B005Z44UZW','B005Z44U1G','B005Z44SKE','B005Z44WPU','B005Z44WHI'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_4_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_4 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_4 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_4'] = jQuery("#W733_4").shoveler(getEndpointW733_4, 20, {
        cellTransformer: getCellContentW733_4,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_4) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_4").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW733_4 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W733_5" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Reading lights&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">2 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Mighty-Bright-MiniFlex-Clip-On-Reading/dp/B003FZA1MY/ref=_5_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/316dtcPBHsL._SY110_.jpg" width="110" alt="Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Black)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Black)" href="http://www.amazon.co.uk/Mighty-Bright-MiniFlex-Clip-On-Reading/dp/B003FZA1MY/ref=_5_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Black)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003FZA1MY" ref="5_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003FZA1MY/ref=5_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.3 out of 5 stars"><span>4.3 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003FZA1MY/ref=5_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">464</a>)</span>
        
        <span class="price">15.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B003FZA1MY&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B003FZA1MY">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B003FZA1MY">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B003FZA1MY">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B003FZA1MY&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Verso-Clip-On-Reading-Kindle-Graphite/dp/B003FZA1OW/ref=_5_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/412umXUG-LL._SY110_.jpg" width="110" alt="Verso Clip-On Reading Light for Kindle (Graphite)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Verso Clip-On Reading Light for Kindle (Graphite)" href="http://www.amazon.co.uk/Verso-Clip-On-Reading-Kindle-Graphite/dp/B003FZA1OW/ref=_5_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Verso Clip-On Reading Light for Kindle (Graphite)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003FZA1OW" ref="5_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003FZA1OW/ref=5_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.7 out of 5 stars"><span>4.7 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003FZA1OW/ref=5_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">29</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Verso-Rechargeable-Wrap-Light-E-Readers/dp/B004D39RMW/ref=_5_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31TFRW+sckL._SY110_.jpg" width="166" alt="Verso Rechargeable Wrap Light for E-Readers - Graphite" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Verso Rechargeable Wrap Light for E-Readers - Graphite" href="http://www.amazon.co.uk/Verso-Rechargeable-Wrap-Light-E-Readers/dp/B004D39RMW/ref=_5_3?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Verso Rechargeable Wrap Light for E-Readers - Graphite</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B004D39RMW" ref="5_3_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B004D39RMW/ref=5_3_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.6 out of 5 stars"><span>4.6 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B004D39RMW/ref=5_3_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">14</a>)</span>
        
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Mighty-Bright-MiniFlex-Clip-On-Reading/dp/B003FZA1N8/ref=_5_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31QekGsZsHL._SY110_.jpg" width="110" alt="Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Silver)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Silver)" href="http://www.amazon.co.uk/Mighty-Bright-MiniFlex-Clip-On-Reading/dp/B003FZA1N8/ref=_5_4?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Mighty Bright MiniFlex Clip-On Reading Light for Kindle (Silver)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003FZA1N8" ref="5_4_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003FZA1N8/ref=5_4_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.3 out of 5 stars"><span>4.3 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003FZA1N8/ref=5_4_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">464</a>)</span>
        
        <span class="price">13.50</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B003FZA1N8&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B003FZA1N8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B003FZA1N8">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B003FZA1N8">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B003FZA1N8&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Verso-Clip-On-Reading-Light-Kindle/dp/B003FZA1O2/ref=_5_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31MFHoLBtGL._SY110_.jpg" width="97" alt="Verso Clip-On Reading Light for Kindle (White)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="Verso Clip-On Reading Light for Kindle (White)" href="http://www.amazon.co.uk/Verso-Clip-On-Reading-Light-Kindle/dp/B003FZA1O2/ref=_5_5?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">Verso Clip-On Reading Light for Kindle (White)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B003FZA1O2" ref="5_5_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B003FZA1O2/ref=5_5_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.7 out of 5 stars"><span>4.7 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B003FZA1O2/ref=5_5_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">29</a>)</span>
        
      </div>
    </div></li>





  
  




























      </ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_5_lnk1?ie=UTF8&node=1501189031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all reading lights for Kindle Touch

    </span>
</a>
</span><span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_5_lnk2?ie=UTF8&node=341687031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_5 = function(cellStart, numCells) {
    var asins = ['B003FZA1MY','B003FZA1OW','B004D39RMW','B003FZA1N8','B003FZA1O2','B004D39RJU','B004D39RMM','B003FZA1NI'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_5_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_5 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_5 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_5'] = jQuery("#W733_5").shoveler(getEndpointW733_5, 8, {
        cellTransformer: getCellContentW733_5,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_5) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_5").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW733_5 = true;
  });
});

</script>
<div style="margin:0 15px 0 40px;">
<div id="W733_6" class="shoveler kindleTab-inactive">
  <div class="shoveler-header">
  <noscript>
    &lt;p&gt;&lt;b&gt;Power adapters&lt;/b&gt;&lt;/p&gt;
  </noscript>


<div class="shoveler-pagination" style="display:none">

<span>&nbsp;</span>
<span>
Page <span class="page-number">1 </span>  of  <span class="num-pages">1 </span> 
<span class="start-over" style="display: none;"> (<a href="http://www.amazon.co.uk/Kindle-Touch-Wi-Fi-Screen-Display/dp/B005890FUI/ref=amb_link_163489267_3?pf_rd_m=A3P5ROKL5A1OLE&pf_rd_s=center-1#" onclick="return false;" class="start-over-link">Start over</a>) </span>
</span>
</div>
  </div>
  <div class="shoveler-main tabbedShoveler-body">
   <div class="prev-button button kindle-shoveler-nojs-hidden" style="display: none;"></div>

    <div class="shoveler-content">
    <ul style="height: 222px;">
        





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/Reader-Adapter-charger-Paperwhite-Keyboard/dp/B005DOKDQO/ref=_6_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/31yViAv-MjL._SY110_.jpg" width="122" alt="e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" href="http://www.amazon.co.uk/Reader-Adapter-charger-Paperwhite-Keyboard/dp/B005DOKDQO/ref=_6_1?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">e-Reader Power Adapter, Kindle UK (Type G) USB charger (for Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B005DOKDQO" ref="6_1_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B005DOKDQO/ref=6_1_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_0 " title="3.8 out of 5 stars"><span>3.8 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B005DOKDQO/ref=6_1_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">609</a>)</span>
        
        <span class="price">17.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B005DOKDQO&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B005DOKDQO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B005DOKDQO">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B005DOKDQO">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B005DOKDQO&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>





  
  




























<li style="width: 180px; margin-left: 22px; margin-right: 22px;" class="shoveler-cell">
      
    
    
<div style="height:110px">
      <a href="http://www.amazon.co.uk/eReader-Replacement-Kindle-Paperwhite-Keyboard/dp/B006BGZJJ4/ref=_6_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">
        <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/41PYOT1ZF-L._SY110_.jpg" width="110" alt="eReader Replacement USB Cable, Kindle, White (works with Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" height="110" border="0">
      </a>
    </div><div>
      <div style="height: 2.5em; overflow: hidden">
        <a title="eReader Replacement USB Cable, Kindle, White (works with Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)" href="http://www.amazon.co.uk/eReader-Replacement-Kindle-Paperwhite-Keyboard/dp/B006BGZJJ4/ref=_6_2?pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ">eReader Replacement USB Cable, Kindle, White (works with Kindle Paperwhite, Kindle, Kindle Touch, and Kindle Keyboard)</a>
      </div>
      <div style="padding-top: 3px">
        <span class="crAvgStars" style="white-space:no-wrap;"><span class="asinReviewsSummary" name="B006BGZJJ4" ref="6_2_cm_cr_acr_pop_">
               <a href="http://www.amazon.co.uk/product-reviews/B006BGZJJ4/ref=6_2_cm_cr_acr_img?ie=UTF8&showViewpoints=1"><span class="swSprite s_star_4_5 " title="4.6 out of 5 stars"><span>4.6 out of 5 stars</span></span></a>&nbsp;</span>(<a href="http://www.amazon.co.uk/product-reviews/B006BGZJJ4/ref=6_2_cm_cr_acr_txt?ie=UTF8&showViewpoints=1">18</a>)</span>
        
        <span class="price">8.99</span>
      </div>
          <div class="kindle-shoveler-nojs-hidden" style="padding-top: 10px; hide-if-no-price">
        <a href="javascript:void(0)" onclick="TSAjaxCartAdd(&#39;B006BGZJJ4&#39;, &#39;277-6643056-3126939&#39;);" class="AjaxCartAdd_B006BGZJJ4">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-add-to-cart-md-pri._V210611548_.gif" width="106" alt="Add to basket" height="22" border="0">
        </a>
        <div style="display: none" class="AjaxCartProcessing_B006BGZJJ4">
          <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/btn-processing-md-st._V210611498_.gif" width="100" alt="Processing" height="22" border="0">
        </div>
        <div style="white-space: nowrap; display: none" class="AjaxCartRemove_B006BGZJJ4">
          <b>In Basket</b> (<a onclick="TSAjaxCartRemove(&#39;B006BGZJJ4&#39;, &#39;277-6643056-3126939&#39;)" href="javascript:void(0)">undo</a>)
        </div>
      </div>
    </div></li>      <li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><span class="empty"></span></li><li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><span class="empty"></span></li><li class="shoveler-cell" style="margin-left: 22px; margin-right: 22px;"><span class="empty"></span></li></ul>
    </div>
    <div class="next-button button kindle-shoveler-nojs-hidden" style="display: none;"></div>
  </div>
  <div class="tabbedShoveler-links">
<span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_6_lnk1?ie=UTF8&node=1501180031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all power adapters for Kindle Touch

    </span>
</a>
</span><span class="tabbedShoveler-link">




<a href="http://www.amazon.co.uk/gp/browse/ref=_6_lnk2?ie=UTF8&node=341687031&pf_rd_p=315313307&pf_rd_s=center-42&pf_rd_t=201&pf_rd_i=B005890FUI&pf_rd_m=A3P5ROKL5A1OLE&pf_rd_r=0KGHD1WV7T4KNAQMVBGQ" class="arrow-to-link">
    <span class="arrow-to-link-span">

        Browse all Kindle Accessories

    </span>
</a>
</span>  </div>
</div>
</div>


<script type="text/javascript">

if (!window.kindleShovelers) {
    kindleShovelers = [];
}

  var getEndpointW733_6 = function(cellStart, numCells) {
    var asins = ['B005DOKDQO','B006BGZJJ4'];
    var url = '/gp/digital/fiona/ajax/asin-info?sId=277-6643056-3126939&asinList=';
    var delim = '';
    for (var i = cellStart; i < cellStart + numCells && i < asins.length; i++) { 
      url += delim + asins[i];
      delim = ',';
    }
    url += '&firstRef=_6_' + (cellStart + 1);
    url += '&imageHeight=110';
    return url;
  }

  var getCellContentW733_6 = function(data) {
    if (data == null) { return ''; }


    var html = "\n      \n    <div style=\"height:110px\">\n      <a href=\"%productUrl\">\n        %image\n      </a>\n    </div>\n    <div>\n      <div style=\"height: 2.5em; overflow: hidden\">\n        <a title=\"%title\" href=\"%productUrl\">%title</a>\n      </div>\n      <div style=\"padding-top: 3px\">\n        %review\n        \n        <span class=\"price\">%price</span>\n      </div>\n          <div class=\"kindle-shoveler-nojs-hidden\" style=\"padding-top: 10px; hide-if-no-price\">\n        <a href=\"javascript:void(0)\" onclick=\"TSAjaxCartAdd('%asin', '277-6643056-3126939');\" class=\"AjaxCartAdd_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-add-to-cart-md-pri._V210611548_.gif\" width=\"106\" alt=\"Add to basket\" height=\"22\" border=\"0\" />\n        </a>\n        <div style=\"display: none\" class=\"AjaxCartProcessing_%asin\">\n          <img src=\"http://g-ecx.images-amazon.com/images/G/02/kindle/turing/btn-processing-md-st._V210611498_.gif\" width=\"100\" alt=\"Processing\" height=\"22\" border=\"0\" />\n        </div>\n        <div style=\"white-space: nowrap; display: none\" class=\"AjaxCartRemove_%asin\">\n          <b>In Basket</b> (<a onclick=\"TSAjaxCartRemove('%asin', '277-6643056-3126939')\" href=\"javascript:void(0)\">undo</a>)\n        </div>\n      </div>\n    </div>\n";
    
    var asin = '', title = '', price = '', review = '', image = '', productUrl = '';
    
    if (data.asin) { asin = data.asin; }
    html = html.replace(/%asin/g, asin);
    
    if (data.productUrl) { productUrl = data.productUrl; }
    html = html.replace(/%productUrl/g, productUrl);
    
    if (data.title) { title = data.title.replace(/"/g, '&quot;'); }                                     
    html = html.replace(/%title/g, title);
    
    if (data.price && data.price.formatted) { 
      price = data.price.formatted; 
    } 
    html = html.replace(/%price/g, price);

    if(price == ''){
    html = html.replace(/hide-if-no-price/g, ';visibility:hidden;');
    }

    if (data.review) { review = data.review; }
    html = html.replace(/%review/g, review);
    
    if (data.image && data.image.tag) { 
        image = data.image.tag; 
    }
    html = html.replace(/%image/g, image);
    
    return html;
  };

  var loadedW733_6 = false;
amznJQ.onReady('jQuery', function(){
  amznJQ.onReady('amazonShoveler', function() {
    kindleShovelers['W733_6'] = jQuery("#W733_6").shoveler(getEndpointW733_6, 2, {
        cellTransformer: getCellContentW733_6,
        onPageChangeCompleteHandler: function() { 
              if (loadedW733_6) {
                setTimeout(TSAjaxCartUpdateStatus, 0);
              }
	  },
        horizPadding: 10
    });

        jQuery("#W733_6").addClass("kindleTab-inactive");
  });

  jQuery(document).ready(function() {
      loadedW733_6 = true;
  });
});

</script>

</div>
<div style="clear:both"></div>


                                                                                                      
                                                                                                      



    



    

  
    <div id="likeAndShareBarLazyLoad" style="display:none;">
        



<span id="amazonLikeKindleDevice">





<script language="Javascript" type="text/javascript">
amznJQ.onCompletion("amznJQ.criticalFeature", function() {
    amznJQ.available('amazonLike', function () {
        
        var stateCache = new AmazonLikeStateCache("amznLikeStateCache_27766430563126939_dp_asin_B005890FUI");
        stateCache.init();
        stateCache.ready(function(){
            if (stateCache.getTimestamp() < 1358413558) {
                stateCache.set('isLiked', jQuery("#amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_isLiked").text()  == "true");
                stateCache.set('customerWhitelistStatus',  parseInt(jQuery("#amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_customerWhitelistStatus").text()));
                stateCache.set('likeCount', parseInt(jQuery("#amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_likeCount").text()));
                stateCache.set('commifiedLikeCount', jQuery("#amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_commifiedLikeCount").text());
                stateCache.set('commifiedLikeCountMinusOne', jQuery("#amznLikeStateCache_27766430563126939_dp_asin_B005890FUI_commifiedLikeCountMinusOne").text());
                stateCache.set('ts', "1358413558");
            }
        if (!window.amznLikeStateCache) {
            window.amznLikeStateCache = {};
        }
        window.amznLikeStateCache["amznLikeStateCache_27766430563126939_dp_asin_B005890FUI"] = stateCache;
        });


        var amznLikeDiv = jQuery("#amznLike_B005890FUI");
        var stateCache = window.amznLikeStateCache["amznLikeStateCache_27766430563126939_dp_asin_B005890FUI"];
        amznLikeDiv.remove();

        var amznLike;
        amznLike = amznLikeDiv.amazonLike({
            context             : "dp",
            itemId              : "B005890FUI",
            itemType            : "asin",
            isLiked             : stateCache.get("isLiked"),
            customerWhitelistStatus : stateCache.get("customerWhitelistStatus"),
            isCustomerSignedIn  : false,
            isOnHover           : false,
            isPressed           : false,
            popoverWidth        : 335,
            popoverAlign        : "right",
            popoverOffset       : 0,
            sessionId           : "277-6643056-3126939",
            likeCount           : stateCache.get("likeCount"),
            commifiedLikeCount  : stateCache.get("commifiedLikeCount"),
            commifiedLikeCountMinusOne : stateCache.get("commifiedLikeCountMinusOne"),
            isSignInRedirect    : false,
            shareText 		    : "Share this item",
            onBeforeAttachPopoverCallback : function () {
                jQuery("#likeAndShareBar").append(amznLikeDiv).show();
            },
            spriteURL           : "http://g-ecx.images-amazon.com/images/G/02/x-locale/personalization/amznlike/amznlike_sprite_02._V170008538_.gif",
            buttonOnClass       : 'on',
            buttonOffClass      : 'off',
            buttonPressedClass  : 'pressed',
            popoverHTML         : "<div id="+'"'+"amazonLikePopoverWrapper_B005890FUI"+'"'+" class="+'"'+"amazonLikePopoverWrapper amazonLikeContext_dp"+'"'+" >"+String.fromCharCode(0x000D)+"<div class="+'"'+"amazonLikeBeak "+'"'+">&nbsp;</div>    <div class="+'"'+"amazonLikePopover"+'"'+">"+String.fromCharCode(0x000D)+"<div class="+'"'+"likePopoverError"+'"'+" style="+'"'+"display: none;"+'"'+">"+String.fromCharCode(0x000D)+"<span class="+'"'+"error"+'"'+" style="+'"'+"color: #900;"+'"'+"><strong>An error has occurred. Please try your request again.</strong></span>"+String.fromCharCode(0x000D)+"</div>"+String.fromCharCode(0x000D)+"<div class="+'"'+"likeOffPopoverContent"+'"'+" >"+String.fromCharCode(0x000D)+"<div>"+String.fromCharCode(0x000D)+"<div class="+'"'+"likeCountText likeCountLoadingIndicator"+'"'+" style="+'"'+"display: none;"+'"'+"><img src="+'"'+"http://g-ecx.images-amazon.com/images/G/02/javascripts/lib/popover/images/snake._V192252891_.gif"+'"'+" width="+'"'+"16"+'"'+" alt="+'"'+"Loading"+'"'+" height="+'"'+"16"+'"'+" border="+'"'+"0"+'"'+" /></div>"+String.fromCharCode(0x000D)+"<span style="+'"'+"font-weight: bold;"+'"'+"><a class="+'"'+"likeSignInLink"+'"'+" href="+'"'+"/gp/like/sign-in/sign-in.html/ref=pd_like_unrec_signin_nojs_dp?ie=UTF8&isRedirect=1&location=%2Fgp%2Flike%2Fexternal%2Fsubmit.html%2Fref%3Dpd_like_submit_like_unrec_nojs_dp%3Fie%3DUTF8%26action%3Dlike%26context%3Ddp%26itemId%3DB005890FUI%26itemType%3Dasin%26redirect%3D1%26redirectPath%3D%252Fgp%252Fproduct%252FB005890FUI%253Fref%25255F%253Damb%25255Flink%25255F163489267%25255F3&useRedirectOnSuccess=1"+'"'+">Sign in to like this</a>.</span>"+String.fromCharCode(0x000D)+"</div>"+String.fromCharCode(0x000D)+"<div class="+'"'+"spacer"+'"'+">Telling us what you like can improve your shopping experience. <a class="+'"'+"grayLink"+'"'+" href="+'"'+"/gp/help/customer/display.html/ref=pd_like_help_dp?ie=UTF8&nodeId=200627470#like"+'"'+">Learn more</a></div>"+String.fromCharCode(0x000D)+"</div>"+String.fromCharCode(0x000D)+"</div>"+String.fromCharCode(0x000D)+"</div>",
            stateCache          : stateCache
        });
        if (window.AMZN_LIKE_SUBMIT) {
            amznLike.onLike();
        }
        });
    });
</script>

</span>

    </div>


















    
    
    
    
    


































































    


  
  
  
  

  
















<hr class="bucketDivider" style="height:1px">
<a id="customerReviews"></a>

<div class="reviews">
<!--[if IE]> 
  <div class="pcr7 mt15 reviews" style="width:100%;" > 
<![endif]-->
<!--[if !IE]> -->
  <div class="pcr7 mt15 reviews"> 
<!-- <![endif]-->
    <div class="pc">
      <h2 style="font-size: 18px;" class="orange">Customer Reviews</h2>
      <div style="margin: 20px 0 40px 25px;">
        <div id="revSum">





  <div id="revH" class="fl">







































<div id="revHist-dpReviewsSummary-B005890FUI" style="font-size: 11px; white-space:no-wrap; line-height:19px;" class="txtsmaller">
  <div class="fl histoRowfive clearboth" title="68% of reviews have 5 stars">
      <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_hist_five?ie=UTF8&filterBy=addFiveStar&showViewpoints=0">
      <div class="histoRating fl gr10 txtnormal">5 star</div>
    <div class="histoFullBar fl tiny mr1" style="width:96px; background-color:#f4f4cf; overflow: hidden;">
      <div class="histoRatingBar" style="background-color:#ffcc66; height:19px; width:65px; border: 0;"></div>
    </div>
      <div class="histoCount fl gl10 ltgry txtnormal" style="text-decoration: none;">712</div>
      </a>
  </div>
  <div class="fl histoRowfour clearboth" title="15% of reviews have 4 stars">
      <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_hist_four?ie=UTF8&filterBy=addFourStar&showViewpoints=0">
      <div class="histoRating fl gr10 txtnormal">4 star</div>
    <div class="histoFullBar fl tiny mr1" style="width:96px; background-color:#f4f4cf; overflow: hidden;">
      <div class="histoRatingBar" style="background-color:#ffcc66; height:19px; width:15px; border: 0;"></div>
    </div>
      <div class="histoCount fl gl10 ltgry txtnormal" style="text-decoration: none;">162</div>
      </a>
  </div>
  <div class="fl histoRowthree clearboth" title="5% of reviews have 3 stars">
      <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_hist_three?ie=UTF8&filterBy=addThreeStar&showViewpoints=0">
      <div class="histoRating fl gr10 txtnormal">3 star</div>
    <div class="histoFullBar fl tiny mr1" style="width:96px; background-color:#f4f4cf; overflow: hidden;">
      <div class="histoRatingBar" style="background-color:#ffcc66; height:19px; width:5px; border: 0;"></div>
    </div>
      <div class="histoCount fl gl10 ltgry txtnormal" style="text-decoration: none;">55</div>
      </a>
  </div>
  <div class="fl histoRowtwo clearboth" title="3% of reviews have 2 stars">
      <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_hist_two?ie=UTF8&filterBy=addTwoStar&showViewpoints=0">
      <div class="histoRating fl gr10 txtnormal">2 star</div>
    <div class="histoFullBar fl tiny mr1" style="width:96px; background-color:#f4f4cf; overflow: hidden;">
      <div class="histoRatingBar" style="background-color:#ffcc66; height:19px; width:3px; border: 0;"></div>
    </div>
      <div class="histoCount fl gl10 ltgry txtnormal" style="text-decoration: none;">35</div>
      </a>
  </div>
  <div class="fl histoRowone clearboth" title="8% of reviews have 1 stars">
      <a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_hist_one?ie=UTF8&filterBy=addOneStar&showViewpoints=0">
      <div class="histoRating fl gr10 txtnormal">1 star</div>
    <div class="histoFullBar fl tiny mr1" style="width:96px; background-color:#f4f4cf; overflow: hidden;">
      <div class="histoRatingBar" style="background-color:#ffcc66; height:19px; width:8px; border: 0;"></div>
    </div>
      <div class="histoCount fl gl10 ltgry txtnormal" style="text-decoration: none;">86</div>
      </a>
  </div>
</div>








</div>
  <div id="acr" style="margin: 0 0 0 40px;" class="fl">
    








<div id="acr-dpReviewsSummary-B005890FUI" class="txtsmall inlineblock">
  <div class="fl acrStars"><span class="swSprite s_starBig_4_5 " title="4.3 out of 5 stars"><span>4.3 out of 5 stars</span></span>


</div>
  <div class="fl gl5 mt3 txtnormal acrCount"><a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_see_all_top?ie=UTF8&showViewpoints=1" class="noTextDecoration">1,050 reviews</a></div>
  <div class="clearboth"></div>
  <div class="gry txtnormal acrRating">4.3 out of 5 stars</div>
</div>









    <div id="revWR" class="mt20">
      

<a href="http://www.amazon.co.uk/review/create-review/ref=cm_cr_dp_wrt_top?ie=UTF8&asin=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware" class="cr-btn btn-sec border-one rounded-standard" title="Write a customer review">
  <span class="btn-medium txtsmall">
    <strong>Write a customer review</strong>
  </span>
</a>

    </div>
  </div>
<div class="clearboth"></div>

</div>
      </div>
      <div style="margin: 0 30px 0 25px;">
        <div id="revMH">




<div id="revMHT" class="mb15 txtlarger drkgry"><strong>Most Helpful Customer Reviews</strong></div>
<div id="revMHRL" class="mb30">



























<div id="rev-dpReviewsMostHelpful-RSY06QYWIMLE5" class="reviews">  <div class="gry txtsmall hlp">2,231 of 2,261 people found the following review helpful</div>  <div class="clearboth"></div>  <div class="mt4 ttl"><span class="swSprite s_star_4_0 " title="4.0 out of 5 stars"><span>4.0 out of 5 stars</span></span>


<a href="http://www.amazon.co.uk/review/RSY06QYWIMLE5/ref=cm_cr_dp_title?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware" class="txtlarge gl3 gr4 reviewTitle valignMiddle"><strong>An Honest Review of the Kindle Touch</strong></a><span class="gry valignMiddle">








<span class="inlineblock txtsmall">23 April 2012</span>
</span></div>  <div class="mt4 ath"><span class="gr10">
    







<span class="txtsmall"><span class="gry">By</span> <a href="http://www.amazon.co.uk/gp/pdp/profile/AEM532AMHVT6Q/ref=cm_cr_dp_pdp" class="noTextDecoration">Crafty Marie</a></span>
</span><span class="gr8"> <span class="c7yBadge TR-3">TOP 50 REVIEWER</span></span>


</div>  <div class="txtsmall mt4 fvavp"><span class="inlineblock avpOrVine"><span class="orange strong avp">Amazon Verified Purchase</span></span></div>  <div class="mt9 reviewText">




<div class="drkgry">
  I've been a Kindle owner since the very old and chunky Kindle 2 device. Here's my personal pros and cons on the new Kindle Touch:<br><br>PROS ON THE KINDLE TOUCH:<br><br>1) Smaller and lighter than my previous Kindle Keyboard model. Dispensing with the physical keyboard and using an on-screen keyboard has saved a lot of space. This makes it nice and light to hold and also it's now small enough to fit into most of my handbags too.<br><br>2) The touch aspect is very responsive which is both good and bad. It's ever so easy to turn pages with a very light press on the right side for moving on a page or left for moving back. You can also swipe to turn pages too which again is very easy. I love the fact that Amazon have added up and down swiping while reading which means you can move to the next or previous chapter very quickly - if chapter markers have been added by the publishers in the book.<br><br>3) Using a touch screen is probably more intuitive for most people who are used to tablets and touch screen gadgets. It's great to be able to simply touch a word and you get your dictionary definition rather than having to navigate down to a word using buttons and then select it which is tedious.<br><br>4) I was very concerned about fingerprints over the reading screen but I've been pleasantly suprised with that. You do get fingerprints but they are admittedly very difficult to see on the matt finished screen unless you look closely. So hopefully that shouldn't put you off if fingerprints are a worry.<br><br>5) The text is clear and easy to read with lots of options of changing the size of the text and a few options on the font - just the same as with the Kindle Keyboard model. I compared both screens on my old and new device and noticed no difference with clarity of text between the two models.<br><br>6) Great new X-Ray feature (only works with some books where the publisher has provided it) which means you can see more info about characters, events and places with your book. This has been brilliant with reading the Harry Potter books where sometimes I want more detail. No having to go online to look it up - the extra info is there for you.<br><br>7) Some operations are made a lot easier with the Touch model like selecting words to get a dictionary definition, highlighting your favourite passages and quotes, adding a bookmark by just pressing the top right corner etc.<br><br>CONS ON THE KINDLE TOUCH:<br><br>1) I can't type as quickly on a touch screen keyboard as I can on the physical one on my Kindle Keyboard model. This may not be an issue for most people but I use my Kindle as a research tool as well as to read books so sometimes I can make extensive notes. This will be a pain for me with the touch model - plus sometimes my fingers press the wrong key on the Touch model because they're not very big.<br><br>2) The touch screen is very responsive which has its good points as I mentioned in the pros. But it also causes some issues too because if I don't press the power button when I'm done reading to activate the screensaver right away then any accidental movement on top of the screen causes something to happen which has ended up with me losing my place while reading a few times. Also my clumsy fingers have pressed on screen items by mistake on a number of occasions causing me confusion as to where I was.<br><br>3) I definitely seem to get more screen ghosting with this model than with my Kindle Keyboard so I'm a little disappointed in that. First thing you might want to do when you get your Touch is to go to settings and make sure you get the device to refresh the e-ink on every page turn. If you don't then I kid you not, you will see parts of the previous screen 'ink' on the current page that you're reading and this is known as screen ghosting. It's very annoying. Even having the page refresh on every turn, I still get a little of this ghosting so that's a slight con for me.<br><br>4) My BIGGEST CON with this new Kindle is the lack of physical page turn buttons. Yes, I know it's a Touch model but personally I'd prefer the option of being able to use page turn buttons while reading OR to use the screen to navigate. Problem with using the screen is that your thumb (which you'll use to move forward and back whether tapping or swiping) ends up obstructing some of what you're reading. If you're a fast reader and turning pages quickly, this can be pretty annoying. I love the physical page turn buttons on my Kindle Keyboard and I just wish that Amazon had provided them as well with this model. Personally I don't want to have to touch the screen to do every single thing.<br><br>So while I think this new model is great and has many advantages over the Kindle Keyboard, I'm not giving it a full-out 5 star rating because the device isn't quite perfect for me. I don't see any improvement with the sharpness or clarity of text over the previous model, I do get a little of the annoying screen ghosting and I just wish Amazon had provided those physical page turn buttons as well so you're not forced into having to read by touching (and covering) the screen.<br><br>And that's my very honest take on it. Great model but just missed the mark of being the perfect Kindle model for me.
</div>

</div>  <div class="clearboth txtsmall gt9 vtStripe">    <div class="fl cmt">









<a href="http://www.amazon.co.uk/review/RSY06QYWIMLE5/ref=cm_cr_dp_cmt?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware#wasThisHelpful" class="noTextDecoration">38 Comments</a>
 <span class="gry gr4 gl4">|</span>&nbsp;</div>    <div class="vt">










<a id="RSY06QYWIMLE5.2115.Helpful.Reviews"></a>
  <div>
   <div class="votingPrompt drkgry fl mr6"><strong>Was this review helpful to you?</strong></div>
   <div class="fl mr6 mtNegative3 votingButtonReviews yesButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/RSY06QYWIMLE5/Helpful/1/ref=cm_cr_dp_voteyn_yes?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=7922FEAC60FA23FC840E82C7CA87DBB58BB66689&voteAnchorName=RSY06QYWIMLE5.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="Yes">
  <span class="btn-small txtsmall">Yes</span>
</a>
</div>
   <div class="fl mtNegative3 votingButtonReviews noButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/RSY06QYWIMLE5/Helpful/-1/ref=cm_cr_dp_voteyn_no?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=CBF798B53A74CDCD79474CFBC1A2B298755084EF&voteAnchorName=RSY06QYWIMLE5.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="No">
  <span class="btn-small txtsmall">No</span>
</a>
</div>
  </div>
  <div class="votingMessage fl mr2"></div>
  <div class="clearboth"></div>



</div>  </div></div>











<div id="rev-dpReviewsMostHelpful-R1PT0QQFQZ16J6" class="reviews" style="margin-top:30px;">  <div class="gry txtsmall hlp">250 of 254 people found the following review helpful</div>  <div class="clearboth"></div>  <div class="mt4 ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<a href="http://www.amazon.co.uk/review/R1PT0QQFQZ16J6/ref=cm_cr_dp_title?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware" class="txtlarge gl3 gr4 reviewTitle valignMiddle"><strong>Superb! Absolutely delighted.</strong></a><span class="gry valignMiddle">







<span class="inlineblock txtsmall">12 Jun 2012</span>
</span></div>  <div class="mt4 ath"><span class="gr10">







<span class="txtsmall"><span class="gry">By</span> <a href="http://www.amazon.co.uk/gp/pdp/profile/A1NNF2A84E1H7M/ref=cm_cr_dp_pdp" class="noTextDecoration">Sarah</a></span>
</span>


</div>  <div class="txtsmall mt4 fvavp"><span class="inlineblock avpOrVine"><span class="orange strong avp">Amazon Verified Purchase</span></span></div>  <div class="mt9 reviewText">




<div class="drkgry">
  I wasn't immediately keen on the idea of the Amazon Kindle as I thought I would lose some of the enjoyment of the reading experience - I suppose I thought it would be like reading from a standard computer screen. That was until I had a look at my mum's Kindle and from the moment I started reading I knew I had to have one!<br><br>I ordered the Touch, as for 20 more you get a more slimline product, and I am delighted with it.<br><br>It is light, attractive and comfortable to hold;<br><br>The screen is responsive, but not excessively so;<br><br>It is nicer to read than paper. I activated the 'refresh e-ink after every page turn' feature to avoid the ghost writing that people have warned of and have not found it to be a problem whatsoever;<br><br>It is simple to shop for books using the Touch screen, and downloads take less than a minute to appear on your Kindle;<br><br>It has superb features such as the 'x-ray' which, if the book you're reading is enabled, allows you to 'dig deeper' into the story. Such a good feature! I also love the automatic bookmark, the option to highlight text and save quotes in a 'cuttings' file;<br><br>When you touch a word with which you are unfamiliar or do not understand the meaning of, the Oxford definition comes up. This has enhanced my reading experience immeasurably;<br><br>The screensavers are very nice and enhance the product and my enjoyment of it - they have an artsy feel, which I love;<br><br>The thing I love most is this: when you're lying down and reading it is so comfortable. I used to like the idea of relaxing with a good book, but trying to read the words which had been printed too close to the binding, folding back pages and then losing my place, bulkiness, heaviness... all these things and more used to make reading difficult. The Kindle has actually enabled me to love reading again, and I really can relax with a good book now (or 3000 - which is what it holds) while lying down or even in bright sunlight.<br><br>I love it, and could probably go on and on about how good I think it is.<br><br>I would love to own a Kindle Touch cover by Amazon but they are too expensive, which is a shame, as that would be the 'icing on the cake'. I will have to buy a generic one from eBay instead!<br><br>I would wholeheartedly recommend this product - I will never go back to ordinary books after reading from a Kindle. In fact I sold most of them!<br><br>5 big, flashing, bold, bright and beautiful stars from me :-DD
</div>

</div>  <div class="clearboth txtsmall gt9 vtStripe">    <div class="fl cmt">




<a href="http://www.amazon.co.uk/review/R1PT0QQFQZ16J6/ref=cm_cr_dp_cmt?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware#wasThisHelpful" class="noTextDecoration">Comment</a>
 <span class="gry gr4 gl4">|</span>&nbsp;</div>    <div class="vt">









<a id="R1PT0QQFQZ16J6.2115.Helpful.Reviews"></a>
  <div>
   <div class="votingPrompt drkgry fl mr6"><strong>Was this review helpful to you?</strong></div>
   <div class="fl mr6 mtNegative3 votingButtonReviews yesButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/R1PT0QQFQZ16J6/Helpful/1/ref=cm_cr_dp_voteyn_yes?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=739AA0789A5FFB4C0FEC707F2ADBD6BFDAE83C31&voteAnchorName=R1PT0QQFQZ16J6.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="Yes">
  <span class="btn-small txtsmall">Yes</span>
</a>
</div>
   <div class="fl mtNegative3 votingButtonReviews noButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/R1PT0QQFQZ16J6/Helpful/-1/ref=cm_cr_dp_voteyn_no?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=674BC545E139989F246E4730FFBF249AC6ED1719&voteAnchorName=R1PT0QQFQZ16J6.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="No">
  <span class="btn-small txtsmall">No</span>
</a>
</div>
  </div>
  <div class="votingMessage fl mr2"></div>
  <div class="clearboth"></div>



</div>  </div></div>











<div id="rev-dpReviewsMostHelpful-R32NVYOS22SMEN" class="reviews" style="margin-top:30px;">  <div class="gry txtsmall hlp">716 of 732 people found the following review helpful</div>  <div class="clearboth"></div>  <div class="mt4 ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<a href="http://www.amazon.co.uk/review/R32NVYOS22SMEN/ref=cm_cr_dp_title?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware" class="txtlarge gl3 gr4 reviewTitle valignMiddle"><strong>Are you new to Kindle?</strong></a><span class="gry valignMiddle">







<span class="inlineblock txtsmall">21 May 2012</span>
</span></div>  <div class="mt4 ath"><span class="gr10">







<span class="txtsmall"><span class="gry">By</span> <a href="http://www.amazon.co.uk/gp/pdp/profile/A3D26EBP3P0QMT/ref=cm_cr_dp_pdp" class="noTextDecoration">N. J. H.</a></span>
</span><span class="gr8"> <span class="c7yBadge TR-4">TOP 100 REVIEWER</span></span>


</div>  <div class="txtsmall mt4 fvavp"><span class="inlineblock avpOrVine"><span class="orange strong avp">Amazon Verified Purchase</span></span></div>  <div class="mt9 reviewText">




<div class="drkgry">
  Up to this point I was completely against Kindle's for a number of reasons of which I'll discuss in the hopes to reassure people like me that the Kindle is the way forward. First of all let me tell you why I chose the Kindle Touch. For me, Kindle Touch seemed the most inviting because I was used to Touch screen but I was still a little worried about it's features. So here's what I was worried about and what I found out:<br><br>1. I was worried about the sensitivity of the touch screen: The Touch IS sensitive but in a great way - it takes only a very light tap or brush of the finger to turn the page. Additionally there are features which mean that if you press a certain area of the "page" or screen you can go forward, backwards or bring up some further options (like adding annotations or going to a specific page). In comparison to other touch screens, like the iphone let's say, it's less sensitive in my opinion. In particular, if you wanted to scroll down the page of a website (because yes, you can use the internet too) this is bit less sensitive and also, it can take a second or two to refresh the page that you're scrolling down to because of the E-ink mechanism.<br><br>2. What would this E-Ink mechanism actually mean for my reading experience?: Well E-ink to be honest just looks like any other reading format, the difference you'll notice is that when you change the page the screen refreshes almost instantly OR it will flash. Now this flashing can happen after every page if you set your Kindle to refresh it's E-ink after each page. Why would you want to do that? Well some people have noticed some sort of "ghosting" which essentially means you can still very faintly see the words from the previous page. I have never noticed this myself (probably because these people are experiencing a fault of some sort rather than a drawback of the Kindle). But anyway, you can select this option to refresh your ink and get a shiny new page. For me, E-ink is great. It takes a bit longer if you use the internet for the Kindle to refresh but overall you'd never know it wasn't just as always.<br><br>3. Would I be able to download books straight to my Kindle or is there a "middle man" if you don't have 3G?: At first I thought that maybe you'd need to hook up your Kindle to your computer in order to download books - like any other USB stick - but that's not the case at all. The Wi-Fi options for the standard Kindle Touch means that as long as you have an internet connection and a wireless connection to join you can download books onto your Kindle at any time. For example, if you're in a "hotspot" and you join the wireless network (which is simply one button push on the kindle) you can download straight away. The drawback maybe if you don't have 3G is that you can't do this ANYWHERE you can only do it where there's a wi-fi connection to join. With the 3G you can do this absolutely anywhere you like and amazon funds it. Personally, I chose the standard Touch because I don't travel a great deal but also if I knew I was going to be travelling I would just stock up on e-books before I left - therefore I wouldn't need 3G. But of course, if you're away for a great deal of time this may not be appropriate but for any week or two week holiday stocking up should be fine.<br><br>4.Can I keep my books forever? Well that seems to be the case because you have an "Archive" within amazon. Much like when you purchase a book normally, you have a previous history of purchases in your account which shows what you've bought and how much it cost you. Well now with Kindle you have a log of all of the e-books you download which is great because if you were to lose your Kindle, bought a new one or yours became damaged and was replaced you can go straight into this archive and re-download everything you already had. This is a tiny bit different for newspaper subscriptions in that after 7 years they delete because the Kindle deems them as out-of-date. BUT if you're not happy about this you simply archive certain articles or an entire paper so that you can keep it until you choose to delete it.<br><br>5.Would I miss books?: It's tricky because my favourite authors or books I know I'll love I still buy in paperback because sometimes a good book on a shelf is nice to look at. But no I don't really miss books because I still have them just I don't have to hold a heavy book in my hand anymore. And actually, I was getting tired of having book dents in my hands from where heavy books had been digging in whilst I'd been reading. I don't think the Kindle should be looked at as a book replacer unless you're looking for that. It has everything you could possibly want out of a book so it could be used in that way but for me, and I think for a lot of us, the Kindle is a way of reducing luggage whilst travelling, book dents in our hands and it's just something different and new for reading. For children, this thing makes reading seem fun but for adults it's an add-on to the reading experience. So what I'm saying is, don't look at the Kindle as the end to books, just as a different way to read if you wanted to - you can still read books too and have them age on your shelf.<br><br>6.Would it be too difficult to use?: Not in the slightest! This is something I was really concerned about because for some people reading is a relaxing way to spend our time and adding technology to it would inevitably confuse us right? Wrong. This is such a simple but brilliant device that has everything so easily laid out and structured that it's obvious how to use it. There's also a free e-book which comes on your Kindle that you can read straight away which is a step-by-step of how to use your Kindle. After reading maybe half of this I was well on my way. The buttons are not ambigious, they are very well labelled and categorised so that it's easy to see what you're looking for. The "Menu" button is your best friend because it brings up all these options for you.<br><br>7.Will it remember my page?: If you want it to, yes. There are bookmarking options but also the standby option. What this means is that, if you leave your Kindle for a short while it will put itself into standby whilst remembering what you were last looking at. Additionally you can tell it go into standby by very briefly touching the on-off button. Also, this button is well out of reach of being pushed by accident because it's right down the button and on the edge of the Kindle.<br><br>8.Are Kindle books more expensive?: That again was something I wondered about because to me, whats the point in buying a kindle if the books cost just as much. Well Kindle books range in price as you'd expect but a lot of them are FREE. Some other books are the same price as paperback, some are more expensive but these prices fluctuate. I've found the Kindle most useful for books which aren't published in paperback but are published as e-books. Some of my favourite authors write smaller novellas to go between their main novels which are only available in e-book format so that's a fantastic addition for me. I've found that a lot of the books I read, predominately young adult, are much cheaper in Kindle format so it's worked out well for me. I have noticed though that new books are often very close to the same price as a paperback so if you only read newly published books this might be something to take into consideration if you're just looking to save money.<br><br>But is there anything I don't like? At the moment, after having used it religiously, I just can't find anything worth mentioning. You can have free books, cheaper books sometimes too, it's easy to use and it looks quite nice too. If I had to pick something I'd pick the web browser feature.<br><br>Web browser feature: This feature had a couple of issues for me because initially my Kindle decided that even though all my settings were for UK that my primary source for the Kindle Store should be Amazon US. Now as I live in the UK I didn't really understand this but after using the browser to search for amazon UK it re-set itself and figured out that I'd be buying my books from the UK site. Additionally, something that annoyed me a little bit is the e-ink capabilities for web browsers. If you were to scroll down the page it's jumpy and quite slow because the ink has to reset and reprint new information - this is very different to turning a page in your book so don't think this will be the case whilst reading, it's just the web browser. Now the Kindle has labelled this feature as "experimental" so I suppose you have to expect some room for development. Still, it does the job and I'm able to buy e-books which is all I really wanted the feature for anyway.<br><br>So overall, if you're like I was and you're worrying that the Kindle just isn't for you then hopefully I've addressed some of the worries you might have. If there's anything I've missed out please comment below and I'll try my best to answer your question. The Kindle Touch is a great device. I can't compare it to previous Kindle's because I haven't owned one but I can more than recommend this - it's completely changed my mind about e-readers. Hope this helps.
</div>

</div>  <div class="clearboth txtsmall gt9 vtStripe">    <div class="fl cmt">









<a href="http://www.amazon.co.uk/review/R32NVYOS22SMEN/ref=cm_cr_dp_cmt?ie=UTF8&ASIN=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware#wasThisHelpful" class="noTextDecoration">57 Comments</a>
 <span class="gry gr4 gl4">|</span>&nbsp;</div>    <div class="vt">









<a id="R32NVYOS22SMEN.2115.Helpful.Reviews"></a>
  <div>
   <div class="votingPrompt drkgry fl mr6"><strong>Was this review helpful to you?</strong></div>
   <div class="fl mr6 mtNegative3 votingButtonReviews yesButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/R32NVYOS22SMEN/Helpful/1/ref=cm_cr_dp_voteyn_yes?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=0E9CC1FEE8AC132C687E7B9F99FC4A0F08228CF7&voteAnchorName=R32NVYOS22SMEN.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="Yes">
  <span class="btn-small txtsmall">Yes</span>
</a>
</div>
   <div class="fl mtNegative3 votingButtonReviews noButton">


<a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/R32NVYOS22SMEN/Helpful/-1/ref=cm_cr_dp_voteyn_no?ie=UTF8&target=aHR0cDovL3d3dy5hbWF6b24uY28udWsvZ3AvcHJvZHVjdC9CMDA1ODkwRlVJL3JlZj1jbV9jcl9kcHZvdGVyZHI&token=71CA1CF2B95F6728789F00F71873B476BEC9A0EB&voteAnchorName=R32NVYOS22SMEN.2115.Helpful.Reviews&voteSessionID=277-6643056-3126939" class="cr-btn btn-sec border-one rounded-standard" title="No">
  <span class="btn-small txtsmall">No</span>
</a>
</div>
  </div>
  <div class="votingMessage fl mr2"></div>
  <div class="clearboth"></div>



</div>  </div></div>










</div>

</div>
      </div>
      <div id="revF" style="margin: 0 0 30px 25px;">
         





<div>
  <b class="h3color txtsmall"></b>
  <a id="seeAllReviewsUrl" href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_see_all_btm?ie=UTF8&showViewpoints=1&sortBy=bySubmissionDateDescending" class="txtlarge noTextDecoration">
    <strong>
      See all 1,050 customer reviews (newest first)
    </strong>
  </a>
</div>
<div id="ftWR" class="mt20">
  

<a href="http://www.amazon.co.uk/review/create-review/ref=cm_cr_dp_wrt_btm?ie=UTF8&asin=B005890FUI&channel=detail-glance&nodeID=341687031&store=fiona-hardware" class="cr-btn btn-sec border-one rounded-standard" title="Write a customer review">
  <span class="btn-medium txtsmall">
    <strong>Write a customer review</strong>
  </span>
</a>

</div>

      </div>
    </div>
    <div class="pr7 mb30" style="width: 305px;">
      <div style="padding-bottom: 20px"><script type="text/javascript">var paCusRevAllURL = "http://product-ads-portal.amazon.com/gp/synd/?asin=B005890FUI&pAsin=&gl=349&sq=&sa=&se=&noo=&pt=Detail&spt=Glance&sn=customer-reviews-top&pRID=0KGHD1WV7T4KNAQMVBGQ&ts=1358413557&h=EE30EF95B80DA3DCB033FEC4D4B438CE7195059D";</script></div>
      <div>




<div id="revMRT" class="txtlarger drkgry"><strong>Most Recent Customer Reviews</strong></div>
<div id="revMRRL">



<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R3Q642Q2AH6TO" class="reviewTitle inlineblock mt14" title="Read the full review by Les">  <div id="rev-dpReviewsMostRecent-R3Q642Q2AH6TO" class="block">    <div class="ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Cant be with out it.</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  Love it love it love it.  Cant say any more other than.... thought this was fab and still do but was bought a Kindle Fire HD for xmas<br>Wow even better. Well done Kindle.
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 1 day ago by Les</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R1TDFQ8FTWQHV9" class="reviewTitle inlineblock mt17" title="Read the full review by J">  <div id="rev-dpReviewsMostRecent-R1TDFQ8FTWQHV9" class="block">    <div class="ttl"><span class="swSprite s_star_2_0 " title="2.0 out of 5 stars"><span>2.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Awkward</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  Well it works, but if you have an iPad or iPhone, use the Kindle app instead - this is so clunky and annoying in comparison
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 1 day ago by J</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#RNMV9UR36SHLL" class="reviewTitle inlineblock mt17" title="Read the full review by Agnieszka Jurgielewicz">  <div id="rev-dpReviewsMostRecent-RNMV9UR36SHLL" class="block">    <div class="ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Nice product</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  I can't write much about this product because I bought it as a gift for a friend, but she was happy :)
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 2 days ago by Agnieszka Jurgielewicz</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#RF2UE3DJ5QF6T" class="reviewTitle inlineblock mt17" title="Read the full review by Ian Cassidy">  <div id="rev-dpReviewsMostRecent-RF2UE3DJ5QF6T" class="block">    <div class="ttl"><span class="swSprite s_star_4_0 " title="4.0 out of 5 stars"><span>4.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Kindle Touch</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  My only issue is that if you lose your page, it's difficult to find again and if you fall asleep reading you tend to jump foward as your finger hits the screen!
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 2 days ago by Ian Cassidy</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R2CKODI6U5XYDV" class="reviewTitle inlineblock mt17" title="Read the full review by Mrs Alison Beaven">  <div id="rev-dpReviewsMostRecent-R2CKODI6U5XYDV" class="block">    <div class="ttl"><span class="swSprite s_star_1_0 " title="1.0 out of 5 stars"><span>1.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Good for 2 weeks</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  The Kindle Touch was good for about 2 weeks. Then, it would only switch if the charger was plugged in (although the battery was fully charged). <span class="readMoreLink">Read more</span>
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 3 days ago by Mrs Alison Beaven</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R3UJQR9Q6UAQZK" class="reviewTitle inlineblock mt17" title="Read the full review by PJB.COM">  <div id="rev-dpReviewsMostRecent-R3UJQR9Q6UAQZK" class="block">    <div class="ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>kindle love</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  what a machine very well made easy to use cant find ant faults with it as yet downloading books is as easy as 123 rec to all in fact just also got the kindle fire hd
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 3 days ago by PJB.COM</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R17HL4E3K7K46O" class="reviewTitle inlineblock mt17" title="Read the full review by Paulius Anciukevicius">  <div id="rev-dpReviewsMostRecent-R17HL4E3K7K46O" class="block">    <div class="ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Good</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  Good product good price. Arrived on time. No problems while using it. Secure packaging. Used it for a couple of months now and it works fine
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 4 days ago by Paulius Anciukevicius</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R30SQRSFUP6BA6" class="reviewTitle inlineblock mt17" title="Read the full review by SheilaX">  <div id="rev-dpReviewsMostRecent-R30SQRSFUP6BA6" class="block">    <div class="ttl"><span class="swSprite s_star_1_0 " title="1.0 out of 5 stars"><span>1.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Kindle touch</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  I have always been a reader since childhood, and normally get through 6-7 books per week. I was so glad I was able to afford a Kindle<br> as kindle books are cheaper than paper... <span class="readMoreLink">Read more</span>
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 6 days ago by SheilaX</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R16SS2O6T42GPL" class="reviewTitle inlineblock mt17" title="Read the full review by Mr M  Banks">  <div id="rev-dpReviewsMostRecent-R16SS2O6T42GPL" class="block">    <div class="ttl"><span class="swSprite s_star_4_0 " title="4.0 out of 5 stars"><span>4.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Impressed</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  I liked the new Kindle because of it`s touch screen,it is easier to use than the old version.Very pleased with it.
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 6 days ago by Mr M  Banks</span>
</div>  </div></a>
<a href="http://www.amazon.co.uk/product-reviews/B005890FUI/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending#R1ESIHLZWDFKPI" class="reviewTitle inlineblock mt17" title="Read the full review by Emily Allan">  <div id="rev-dpReviewsMostRecent-R1ESIHLZWDFKPI" class="block">    <div class="ttl"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars"><span>5.0 out of 5 stars</span></span>


<span class="txtlarge gl3 valignMiddle"><strong>Brilliant!</strong></span></div>    <div class="reviewText">




<div class="drkgry">
  This kindle has helped my daughter (who is slightly dyslexic) read.  She now reads a book every 10 days or so. <span class="readMoreLink">Read more</span>
</div>


</div>    <div class="clearboth mt3 pbl">







<span class="gry txtsmall">Published 7 days ago by Emily Allan</span>
</div>  </div></a>










</div>

</div>
      <div id="revS" style="margin-top: 30px;">





<form method="GET" action="http://www.amazon.co.uk/gp/community-content-search/results/ref=cm_cr_dp_srch" style="padding:0; margin:0;"> 

  <div class="txtlarge mb5">
    <strong>
      Search Customer Reviews
    </strong>
  </div>
  <div>
    <div class="fl">
      <input id="searchCustomerReviewsInput" class="small mr5" style="width: 225px; margin-top: 0px;" type="text" name="query" value="">
    </div>
    <div id="searchCustomerReviewsButton" class="fl" unselectable="on">
      

<span class="cr-btn btn-input btn-sec rounded-standard">
  <input type="submit" class="btn-small" value="Go" title="Go">
</span>

    </div>
  </div>
  <div class="clearboth">
    <input type="checkbox" name="idx.asin" value="B005890FUI" checked=""> 
    <input type="hidden" name="search-alias" value="community-reviews">
    
    <span class="tiny"> 
      Only search this product's reviews 
    </span>
  </div>

</form>



</div>
    </div>
  </div>
  <div class="clearboth"></div>
</div>






<script>
  if (typeof uet == 'function') { uet('cf'); } 
  if(typeof window.amznJQ != 'undefined') {amznJQ.completedStage('amznJQ.criticalFeature');}
</script>



 





<script type="text/javascript">
amznJQ.onCompletion('amznJQ.criticalFeature', function() {
  amznJQ.available('search-js-jq', function(){});
  amznJQ.available('amazonShoveler', function(){});
  amznJQ.available('simsJS', function(){});
  amznJQ.available('cmuAnnotations', function(){});
  amznJQ.available('externalJS.tagging', function(){});
  amznJQ.available('amzn-ratings-bar', function(){});
  amznJQ.available('accessoriesJS', function(){});
  amznJQ.available('priceformatterJS', function(){});
  amznJQ.available('CustomerPopover', function(){});

});
</script>








<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleCompChartCSS-926985093._V1_.css" rel="stylesheet">
<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/kindleImageBlockCSS-2190593842._V1_.css" rel="stylesheet">
<script type="text/javascript">
    amznJQ.addLogical('kindleCompChartCSS', []);
    amznJQ.addLogical('cmuAnnotations', ["http://z-ecx.images-amazon.com/images/G/01/nav2/gamma/cmuAnnotations/cmuAnnotations-cmuAnnotations-55262._V1_.js"]);
    amznJQ.addLogical('share-with-friends-js-new', ["http://z-ecx.images-amazon.com/images/G/01/nav2/gamma/share-with-friends-js-new/share-with-friends-js-new-share-12795._V1_.js"]);
    amznJQ.addLogical('AmazonCountdown', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/AmazonCountdownMerged/AmazonCountdownMerged-27059._V1_.js"]);
    amznJQ.addLogical('kindleFamilyStripeJS', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/kindleFamilyStripeJS/kindleFamilyStripeJS-1662756._V1_.js"]);
    amznJQ.addLogical('kindleImageBlockJS', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/kindleImageBlockJS/kindleImageBlockJS-4255176538._V1_.js"]);
    amznJQ.addLogical('kindleImageBlockCSS', []);
    amznJQ.addLogical('amazonLike', ["http://z-ecx.images-amazon.com/images/G/01/browser-scripts/amazonLike/amazonLike-682075628._V1_.js"]);
    amznJQ.addLogical('gridReviewCSS-US', []);
    amznJQ.addLogical('reviewsCSS-US', []);
</script>


<hr size="1" noshade=""><div class="bucket"><div class="kindle-feature headline">
      Customer Discussions
    </div></div>

<div class="kindle-forum">











  
  

























































<div class="unified_widget">

  <div class="cmPage">
    



















<script language="Javascript1.1" type="text/javascript">
<!--
function PopWin(url,name,options){
        var ContextWindow = window.open(url,name,options);
        ContextWindow.opener = this;
        ContextWindow.focus();
}
function RefreshOriginalWindow(url) {
        if ((window.opener == null) || (window.opener.closed))
        {
                var OriginalWindow = window.open(url);
                OriginalWindow.opener = this;
        }
        else{
                window.opener.location=url;
        }
}
//-->
</script>









<script><!--

  function cdBindThreadPopover() { 
    jQuery('.CDTPop').each(function() {
      jQuery(this).removeAmazonPopoverTrigger();
      jQuery(this).amazonPopoverTrigger({
        ajaxTimeout: 4000,

        ajaxErrorContent: 'Unable to load. Please try again soon.',

        width: 550,
        locationMargin: 18,
        location: ["right", "left"],
        closeEventInclude: "MOUSE_LEAVE",
        showOnHover: true,
        showCloseButton: false,
        destination: '/gp/forum/cd/du/forum/thread/popover.html?' + jQuery(this).attr('name')
      });
    });
  }

  amznJQ.onReady('popover', cdBindThreadPopover);


--></script>






  

<script type="text/javascript">

var cdLocalizedStrings;
if ( ! cdLocalizedStrings ) {
  cdLocalizedStrings = new Array();
}

function cdGetLocalizedString(key, replacements) {
  var str = cdLocalizedStrings[key];

  if ( !str ) {
      return key;
  }

  if ( replacements ) {
    for ( var replace in replacements ) {
      var replacementKey = "${"+replace+"}";
      str = str.split(replacementKey).join(replacements[replace]);
    }
  }

  return str;
}
</script>


  


<script><!--
var ASINInjectorTextareaID = null;

if (typeof(goWysiASINPop) != 'undefined' && goWysiASINPop.isVisible()) {
  goWysiASINPop.hide();
}

function ASINInjectorSwitchTextarea(textareaID) {
  if (typeof(goWysiASINPop) != 'undefined' && goWysiASINPop.isVisible()) {
    goWysiASINPop.hide();
  }

  ASINInjectorTextareaID = textareaID;
}

function ASINInjectorHandleSelection(asin, title) {
  // Hide popover
  if (typeof(goWysiASINPop) != 'undefined' && goWysiASINPop.isVisible()) {
    goWysiASINPop.hide();
  }

  ASINInjectorInsertText('[[ASIN:' + asin + ' ' + title + ']]', ASINInjectorTextareaID);
}

function ASINInjectorSaveCursorPos(ta) {
  if (ta.createTextRange)
  {
    ta.cursorPos = document.selection.createRange().duplicate();
  }
}

function ASINInjectorInsertText(text, textareaID) {
  var ta = document.getElementById(textareaID);
  if (!ta) return;

  ta.focus();

  // Replace HTML entities to literal characters
  text = text.replace(/&amp;/gi, "&");
  text = text.replace(/&lt;/gi, "<");
  text = text.replace(/&gt;/gi, ">");

  // IE
  if (ta.createTextRange && ta.cursorPos) {
    var range = ta.cursorPos;
    range.text = text;
    range.select();
  }
  // Mozilla et. al
  else if (ta.selectionStart || ta.selectionStart == '0') {
    // Store scroll position to set it back after
    var scrollPos = ta.scrollTop;
    var startPos = ta.selectionStart;
    var endPos = ta.selectionEnd;
    ta.value = ta.value.substring(0, startPos)
      + text 
      + ta.value.substring(endPos, ta.value.length);
  
    ta.selectionStart = endPos + text.length;
    ta.selectionEnd = endPos + text.length;
    ta.scrollTop = scrollPos;
    ta.focus();
  } else {
    ta.value += text;
  }
}

function ASINInjectorInit(elementID) {
    jQuery('.ASINInjectorEnabled').css('display', 'inline');
    jQuery('.ASINInjectorDisabled').css('display', 'none');

    if (!elementID) {
        elementID = '';
    } else {
        elementID = '_' + elementID;
    }

    jQuery('.ASINInjectorTextArea' + elementID).each(function() {
        jQuery('#'+this.id).click(function() { ASINInjectorSaveCursorPos(this); });
        jQuery('#'+this.id).keyup(function() { ASINInjectorSaveCursorPos(this); });
    });

        jQuery("a[name='ASINInjectorTrigger" + elementID + "']").removeAmazonPopoverTrigger();
        jQuery("a[name='ASINInjectorTrigger" + elementID + "']").wysiAsinPopoverTrigger();
}

amznJQ.onReady('asinPopover', function() {
  ASINInjectorInit();
});
//-->
</script>


<script>
cdLocalizedStrings['err_thread_post_body_n_too_long'] = 'The post is ${length} characters longer than the maximum post length. Please edit it.';
cdLocalizedStrings['err_thread_post_topic_n_too_long'] = 'The discussion topic is ${length} characters longer than the maximum topic length. Please edit it.';
  var CDPostValidator = function(postBoxTitleInputId, postBoxExpanderId, startDiscussionBtnId, postBoxFormId) {
    var cdDisablePostForm = 0;
    var postBoxTitleInputId = postBoxTitleInputId || 'cdPostBoxTitleInput';
    var postBoxExpanderId = postBoxExpanderId || 'cdPostBoxExpander';
    var startDiscussionBtnId = startDiscussionBtnId || 'startDiscussionBtn';
    var postBoxFormId = postBoxFormId || 'cdPostBoxForm';
    
    this.cdCheckThreadPost = function(form) {
      var sub = '' + form.subjectText.value;
      if ( (sub == '') || (sub.match(/^\s*$/)) ) {
        alert("The discussion topic is empty. Please add text to it.");
        return false;
      }
      if ( sub.length > 255 ) {
        alert( cdGetLocalizedString('err_thread_post_topic_n_too_long', {'length':(sub.length - 255)}) );
        return false;
      }

      var body = '' + form.bodyText.value;
      if ( (body == '') || (body.match(/^\s*$/)) ) {
        alert("The discussion body is empty. Please add text to it.");
        return false;
      }

      var maxLen = 16000;
      if ( body.length > maxLen  ) {
        alert( cdGetLocalizedString('err_thread_post_body_n_too_long', {'length':(body.length - maxLen)}) );
        return false;
      }

      if ( cdDisablePostForm++ ) {
        return false;
      }

      return true;
    }

    this.cdEnablePostBox = function() {
      cdDisablePostForm = 0;
    }
  
    this.cdFocusPostTitle = function() {
      jQuery('#'+postBoxTitleInputId).focus();
      return false;
    }

    this.cdPostCancelKey = function(e) {
      var code = e.keyCode || e.which;
      if (code == 32) {
        cdClosePostBox();
        return false;
      }
    }

    this.cdOpenPostBox = function() {
      jQuery('#'+postBoxExpanderId).show();
      jQuery('#'+startDiscussionBtnId).hide();
      return false;
    }

    this.cdClosePostBox = function() {
      jQuery('#'+postBoxExpanderId).hide();
      jQuery('#'+startDiscussionBtnId).show();
      jQuery('#'+postBoxFormId)[0].reset();
      cdDisablePostForm = 0;

      if (typeof(goWysiASINPop) != 'undefined' && goWysiASINPop.isVisible()) {
        goWysiASINPop.hide();
      }

      return false;
    }    
  }
  
</script>


<script>
  var threadValidator = new CDPostValidator('cdPostBoxTitleInput', 'cdPostBoxExpander', 'startDiscussionBtn', 'cdPostBoxForm');
</script>





<div style="padding: 4px 0"><b class="h1">Kindle forum</b></div>

























<noscript>
&lt;style&gt;
.jsOffDisplayBlock      { display: block; }
.jsOffDisplayInline     { display: inline; }
.jsOffVisibility        { visibility: visible; }
.jsOnDisplayBlock       { display: none; }
.jsOnDisplayNoneBlock   { display: block; }
.jsOnDisplayNoneInline  { display: inline; }
.jsOnDisplayInline      { display: none; }
.jsOnVisibility         { visibility: hidden; }
.jqOnDisplayBlock       { display: none; }
.jqOnDisplayInline      { display: none; }
.jqOnVisibility         { visibility: hidden; }
.jqOnDisplayNoneBlock   { display: block; }
.jqOnDisplayNoneInline  { display: inline; }
&lt;/style&gt;
</noscript>



    <div style="margin: 4px;">
      <table class="dataGrid" cellspacing="0" style="width: 100%">
        <tbody><tr>
          <th width="1%">
            &nbsp;
          </th>
          <th width="70%">
            Discussion
          </th>
          <th width="3%" class="num">
            Replies
          </th>
          <th width="25%">
            Latest Post
          </th>
        </tr>





        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=Tx2YVANXDL73ZCI" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-Tx2YVANXDL73ZCI" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">



  <div style="color: rgb(204, 102, 0); font-size: 0.86em;">Announcement</div>

  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=Tx2YVANXDL73ZCI">New software update for Kindle Touch</a>
</span>


          </td>

          <td class="num" style="text-align:right">147
          </td>

          <td style="white-space: nowrap;" class="newness">

1 hour ago




</td>
        </tr>




        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=Tx2PI34B41LI557" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-Tx2PI34B41LI557" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">



  <div style="color: rgb(204, 102, 0); font-size: 0.86em;">Announcement</div>

  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=Tx2PI34B41LI557">New software update for Kindle Paperwhite</a>
</span>


          </td>

          <td class="num" style="text-align:right">371
          </td>

          <td style="white-space: nowrap;" class="newness">
10 hours ago




</td>
        </tr>




        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=TxEF0FEJEUZU1V" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-TxEF0FEJEUZU1V" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">



  <div style="color: rgb(204, 102, 0); font-size: 0.86em;">Announcement</div>

  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=TxEF0FEJEUZU1V">Kindle Paperwhite joins the Kindle Family!</a>
</span>


          </td>

          <td class="num" style="text-align:right">1192
          </td>

          <td style="white-space: nowrap;" class="newness">
16 hours ago




</td>
        </tr>




        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=Tx131XRBFXMQGBU" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-Tx131XRBFXMQGBU" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">



  <div style="color: rgb(204, 102, 0); font-size: 0.86em;">Announcement</div>

  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=Tx131XRBFXMQGBU">New additions to the Kindle Family!</a>
</span>


          </td>

          <td class="num" style="text-align:right">1796
          </td>

          <td style="white-space: nowrap;">
2 days ago




</td>
        </tr>




        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=Tx2SPDL6HROWTCB" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-Tx2SPDL6HROWTCB" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">



  <div style="color: rgb(204, 102, 0); font-size: 0.86em;">Announcement</div>

  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=Tx2SPDL6HROWTCB">Important Announcement from Amazon</a>
</span>


          </td>

          <td class="num" style="text-align:right">613
          </td>

          <td style="white-space: nowrap;">
2 days ago




</td>
        </tr>




        <tr>
          <td class="icon"><div class="CDTPop" name="threadID=Tx2452G6MIX4QO9" style="cursor: pointer; overflow: hidden;"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/drop-down-icon-small-arrow._V167145196_.gif" width="11" alt="" id="cdDataGridPopoverImg-Tx2452G6MIX4QO9" class="iconImg jsOnVisibility" height="11" border="0"></div></td>
          <td class="title">
            


<span style="display:inline-block; vertical-align:top">




  <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_tft_tp?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdThread=Tx2452G6MIX4QO9">Freebies ~ Thursday 17th of January</a>
</span>


          </td>

          <td class="num" style="text-align:right">4
          </td>

          <td style="white-space: nowrap;" class="newness">
2 minutes ago




</td>
        </tr>


      </tbody></table>
    </div>



      <div class="bucketFooter">
        <b class="h3Color"> <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_sap?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W">See all discussions...</a></b>  &nbsp;
        <b class="h3Color"> <a href="http://www.amazon.co.uk/forum/kindle/ref=cm_cd_ecf_sd?_encoding=UTF8&cdForum=Fx3IRFCNF3E5K2W&cdOpenPostbox=1#CustomerDiscussionsPost">Start a new discussion</a></b>
      </div>



























  </div>
</div>








</div>

<div id="bb_extra_B004SD2562_title" style="display:none;">Add an Amazon Kindle Lighted Leather Cover</div><div id="bb_extra_B004SD2562" class="bb_extra" style="display:none" width="760" modal="true"><div class="popoverLoading">
  <table border="0"><tbody>
    <tr>
      <td style="border:0;padding:0;width:16px"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/icon_spinner._V192252841_.gif" width="16" height="16" border="0"></td>
      <td style="border:0;padding:0">Loading, please wait</td>
    </tr>
  </tbody></table>
</div>
<div class="popoverLoaded" style="display:none">
  <table>
   <tbody>
    <tr>
      <td style="text-align:center;vertical-align:center;">
        <div id="bb_extra_feature_B005PB2T3U_productImage" style="height:280px"></div>
        <br>
        <div id="bb_extra_feature_B005PB2T3U_altImages"></div>
      </td>
      <td style="height:140px;vertical-align:center;padding-left:10px">
        <div id="bb_extra_feature_B005PB2T3U_title" class="popoverTitle"></div>
        
        <div id="bb_extra_feature_B005PB2T3U_price" class="popoverPrice"></div>
        <div id="bb_extra_feature_B005PB2T3U_variations"></div><div class="para">
<ul>

<li>Built-in LED reading light provides even lighting across Kindle's entire screen</li>
<li>Light draws power from Kindle device. No batteries required</li>
<li>Premium leather exterior looks and feels great</li>
<li>Sleek, lightweight design protects Kindle without adding bulk</li>
<li>Cover folds back for easy one-handed reading</li>
</ul>
</div><div id="bb_extra_feature_B005PB2T3U_addToOrder" class="bbButton">
           <a href="javascript:BBPopover.addToOrder("B005PB2T3U");">
            <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/add-to-kindle-order._V156427493_.png" width="143" alt="Add to Kindle Order" title="Add to Kindle Order" height="28" border="0">
          </a>
        </div>
        <div id="bb_noThanks" class="bbButtonHidden noThanksButton">
              <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/nothanks.gif" alt="No thanks" class="ap_custom_close" title="No thanks" border="0">
        </div>
     
      </td>
    </tr>
  </tbody></table>
</div>
</div>
<script type="text/javascript">
amznJQ.onReady('kindleDeviceJS', function() {
  BBPopover.sessionId = '277-6643056-3126939';
  var refTag = 'kinW_ddp_pop3';
  var learnMoreLink = jQuery("#bb_lm_B004SD2562").attr("href");
  if ( learnMoreLink ) {
    var refTagPattern = /ref=\w*/;
    refTag = refTagPattern.exec( learnMoreLink );
    refTag = new String(refTag).substr( 4 ); 
  }

  BBPopover.refTag['B004SD2562'] = refTag;
  BBPopover.registerDynamicPopover( 'B004SD2562', function() {
    BBPopover.selectedAsin['B005PB2T3U'] = 'B004SD2562';
    BBPopover.displayedAsin['B005PB2T3U'] = 'B004SD2562';
    BBPopover.originalAsin['B005PB2T3U'] = 'B004SD2562';
    jQuery.ajax({
      cache: false,
      data: {
        "asin": "B004SD2562",
        "asinCSVList" : "",
        "sId" : BBPopover.sessionId,
        "baseRef" : BBPopover.refTag['B004SD2562'],
        "isFirstLoad" : 1,
        "bundlePriceOverride" : ""
      },
      dataType: "json",
      success: function(data, status) {
        if ( data && data.error == 0 ) {
          for ( var key in data ) {
            if ( key == "error" ) {
              continue;
            }
            BBPopover.asinCache[key] = data[key];
            jQuery('#bb_extra_B004SD2562').children('.popoverLoading').css('display','none');
            BBPopover.doUpdate( 'B005PB2T3U', key, 1 );
            /* Pull in the image size from its parent object setting */
            var imgParam = jQuery('#bb_extra_feature_B005PB2T3U_productImage').css('height');
            jQuery('#bb_extra_feature_B005PB2T3U_productImage img').css('height',imgParam);
            /* Display all product info after aloading*/
            jQuery('#bb_extra_B004SD2562').children('.popoverLoaded').css('display','block');
          }
        }
      },
      type: "GET",
      url: "/gp/digital/fiona/ajax/buyBoxTwister/ref=" + BBPopover.refTag['B004SD2562'] + "_bbpfl"
    });
  });
});
</script>












<div id="bb_extra_B004SD22PQ_title" style="display:none;">Add an Amazon Kindle Touch Leather Cover</div><div id="bb_extra_B004SD22PQ" class="bb_extra" style="display:none" width="760" modal="true"><div class="popoverLoading">
  <table border="0"><tbody>
    <tr>
      <td style="border:0;padding:0;width:16px"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/icon_spinner._V192252841_.gif" width="16" height="16" border="0"></td>
      <td style="border:0;padding:0">Loading, please wait</td>
    </tr>
  </tbody></table>
</div>
<div class="popoverLoaded" style="display:none">
  <table>
   <tbody>
    <tr>
      <td style="text-align:center;vertical-align:center;">
        <div id="bb_extra_feature_B005PB2T2Q_productImage" style="height:280px"></div>
        <br>
        <div id="bb_extra_feature_B005PB2T2Q_altImages"></div>
      </td>
      <td style="height:140px;vertical-align:center;padding-left:10px">
        <div id="bb_extra_feature_B005PB2T2Q_title" class="popoverTitle"></div>
        
        <div id="bb_extra_feature_B005PB2T2Q_price" class="popoverPrice"></div>
        <div id="bb_extra_feature_B005PB2T2Q_variations"></div><div class="para">
<ul>

<li>Sleek, lightweight design protects Kindle without adding bulk</li>
<li>Premium leather exterior looks and feels great</li>
<li>Cover folds back for easy one-handed reading</li>

</ul>
</div><div id="bb_extra_feature_B005PB2T2Q_addToOrder" class="bbButton">
           <a href="javascript:BBPopover.addToOrder("B005PB2T2Q");">
            <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/add-to-kindle-order._V156427493_.png" width="143" alt="Add to Kindle Order" title="Add to Kindle Order" height="28" border="0">
          </a>
        </div>
        <div id="bb_noThanks" class="bbButtonHidden noThanksButton">
              <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/nothanks.gif" alt="No thanks" class="ap_custom_close" title="No thanks" border="0">
        </div>
     
      </td>
    </tr>
  </tbody></table>
</div>
</div>
<script type="text/javascript">
amznJQ.onReady('kindleDeviceJS', function() {
  BBPopover.sessionId = '277-6643056-3126939';
  var refTag = 'kinW_ddp_pop2';
  var learnMoreLink = jQuery("#bb_lm_B004SD22PQ").attr("href");
  if ( learnMoreLink ) {
    var refTagPattern = /ref=\w*/;
    refTag = refTagPattern.exec( learnMoreLink );
    refTag = new String(refTag).substr( 4 ); 
  }

  BBPopover.refTag['B004SD22PQ'] = refTag;
  BBPopover.registerDynamicPopover( 'B004SD22PQ', function() {
    BBPopover.selectedAsin['B005PB2T2Q'] = 'B004SD22PQ';
    BBPopover.displayedAsin['B005PB2T2Q'] = 'B004SD22PQ';
    BBPopover.originalAsin['B005PB2T2Q'] = 'B004SD22PQ';
    jQuery.ajax({
      cache: false,
      data: {
        "asin": "B004SD22PQ",
        "asinCSVList" : "",
        "sId" : BBPopover.sessionId,
        "baseRef" : BBPopover.refTag['B004SD22PQ'],
        "isFirstLoad" : 1,
        "bundlePriceOverride" : ""
      },
      dataType: "json",
      success: function(data, status) {
        if ( data && data.error == 0 ) {
          for ( var key in data ) {
            if ( key == "error" ) {
              continue;
            }
            BBPopover.asinCache[key] = data[key];
            jQuery('#bb_extra_B004SD22PQ').children('.popoverLoading').css('display','none');
            BBPopover.doUpdate( 'B005PB2T2Q', key, 1 );
            /* Pull in the image size from its parent object setting */
            var imgParam = jQuery('#bb_extra_feature_B005PB2T2Q_productImage').css('height');
            jQuery('#bb_extra_feature_B005PB2T2Q_productImage img').css('height',imgParam);
            /* Display all product info after aloading*/
            jQuery('#bb_extra_B004SD22PQ').children('.popoverLoaded').css('display','block');
          }
        }
      },
      type: "GET",
      url: "/gp/digital/fiona/ajax/buyBoxTwister/ref=" + BBPopover.refTag['B004SD22PQ'] + "_bbpfl"
    });
  });
});
</script>












<div id="bb_extra_B005DOKDQO_title" style="display:none;">Amazon Kindle UK Power Adapter</div><div id="bb_extra_B005DOKDQO" class="bb_extra" style="display:none" width="760" modal="true"><div class="popoverLoading">
  <table border="0"><tbody>
    <tr>
      <td style="border:0;padding:0;width:16px"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/icon_spinner._V192252841_.gif" width="16" height="16" border="0"></td>
      <td style="border:0;padding:0">Loading, please wait</td>
    </tr>
  </tbody></table>
</div>
<div class="popoverLoaded" style="display:none">
  <table>
   <tbody>
    <tr>
      <td style="text-align:center;vertical-align:center;">
        <div id="bb_extra_feature_B005DOKDQO_productImage" style="height:280px"></div>
        <br>
        <div id="bb_extra_feature_B005DOKDQO_altImages"></div>
      </td>
      <td style="height:140px;vertical-align:center;padding-left:10px">
        <div id="bb_extra_feature_B005DOKDQO_title" class="popoverTitle"></div>
        
        <div id="bb_extra_feature_B005DOKDQO_price" class="popoverPrice"></div>
        <div id="bb_extra_feature_B005DOKDQO_variations"></div><div class="para">

<ul>
<li>UK (type G, United Kingdom) charger approved for use with Kindle, Kindle Touch, Kindle Touch 3G and Kindle Keyboard (not compatible with 1st Generation Kindle)</li>
<li>Supports 100VAC-240VAC. UK plug only. Not compatible with non-UK outlets</li>
<li>See Kindle User's Guide for instructions and important safety information</li>
</ul>
</div><div id="bb_extra_feature_B005DOKDQO_addToOrder" class="bbButton">
           <a href="javascript:BBPopover.addToOrder("B005DOKDQO");">
            <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/add-to-kindle-order._V156427493_.png" width="143" alt="Add to Kindle Order" title="Add to Kindle Order" height="28" border="0">
          </a>
        </div>
        <div id="bb_noThanks" class="bbButtonHidden noThanksButton">
              <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/nothanks.gif" alt="No thanks" class="ap_custom_close" title="No thanks" border="0">
        </div>
     
      </td>
    </tr>
  </tbody></table>
</div>
</div>
<script type="text/javascript">
amznJQ.onReady('kindleDeviceJS', function() {
  BBPopover.sessionId = '277-6643056-3126939';
  var refTag = 'kinW_ddp_pop1';
  var learnMoreLink = jQuery("#bb_lm_B005DOKDQO").attr("href");
  if ( learnMoreLink ) {
    var refTagPattern = /ref=\w*/;
    refTag = refTagPattern.exec( learnMoreLink );
    refTag = new String(refTag).substr( 4 ); 
  }

  BBPopover.refTag['B005DOKDQO'] = refTag;
  BBPopover.registerDynamicPopover( 'B005DOKDQO', function() {
    BBPopover.selectedAsin['B005DOKDQO'] = 'B005DOKDQO';
    BBPopover.displayedAsin['B005DOKDQO'] = 'B005DOKDQO';
    BBPopover.originalAsin['B005DOKDQO'] = 'B005DOKDQO';
    jQuery.ajax({
      cache: false,
      data: {
        "asin": "B005DOKDQO",
        "asinCSVList" : "",
        "sId" : BBPopover.sessionId,
        "baseRef" : BBPopover.refTag['B005DOKDQO'],
        "isFirstLoad" : 1,
        "bundlePriceOverride" : ""
      },
      dataType: "json",
      success: function(data, status) {
        if ( data && data.error == 0 ) {
          for ( var key in data ) {
            if ( key == "error" ) {
              continue;
            }
            BBPopover.asinCache[key] = data[key];
            jQuery('#bb_extra_B005DOKDQO').children('.popoverLoading').css('display','none');
            BBPopover.doUpdate( 'B005DOKDQO', key, 1 );
            /* Pull in the image size from its parent object setting */
            var imgParam = jQuery('#bb_extra_feature_B005DOKDQO_productImage').css('height');
            jQuery('#bb_extra_feature_B005DOKDQO_productImage img').css('height',imgParam);
            /* Display all product info after aloading*/
            jQuery('#bb_extra_B005DOKDQO').children('.popoverLoaded').css('display','block');
          }
        }
      },
      type: "GET",
      url: "/gp/digital/fiona/ajax/buyBoxTwister/ref=" + BBPopover.refTag['B005DOKDQO'] + "_bbpfl"
    });
  });
});
</script>












<div id="bb_extra_B006X5F0NS_title" style="display:none;">3-Year SquareTrade Warranty + Accident &amp; Theft Cover for Kindle Touch</div><div id="bb_extra_B006X5F0NS" class="bb_extra" style="display:none" width="760" modal="true"><div class="popoverLoading">
  <table border="0"><tbody>
    <tr>
      <td style="border:0;padding:0;width:16px"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/icon_spinner._V192252841_.gif" width="16" height="16" border="0"></td>
      <td style="border:0;padding:0">Loading, please wait</td>
    </tr>
  </tbody></table>
</div>
<div class="popoverLoaded" style="display:none">
  <table>
   <tbody>
    <tr>
      <td style="text-align:center;vertical-align:center;">
        <div id="bb_extra_feature_B006X5F0NS_productImage" style="height:280px"></div>
        <br>
        <div id="bb_extra_feature_B006X5F0NS_altImages"></div>
      </td>
      <td style="height:140px;vertical-align:center;padding-left:10px">
        <div id="bb_extra_feature_B006X5F0NS_title" class="popoverTitle"></div>
        
        <div id="bb_extra_feature_B006X5F0NS_price" class="popoverPrice"></div>
        <div id="bb_extra_feature_B006X5F0NS_variations"></div><div class="para">
<ul>
<li>Accidental damage cover starts on day 1 and lasts for 3 years from your Kindle purchase date</li>
<li>Extended mechanical and electrical breakdown cover for your 2nd and 3rd years of Kindle ownership</li>
<li>No excess or fees for any claims made on you</li>
<li>Make up to 3 claims over 3 years</li>
<li>Available for Kindles purchased on Amazon.co.uk or from offline retailers within the last 30 days</li>
<li>The vast majority of Kindle failures occur because of accidents.  With the 3-Year Warranty + Accident &amp; Theft Protection for Kindle, you are protected starting from day one.</li>
</ul>
Your Kindle comes with a one-year manufacturer's warranty. If you are a consumer, you will also have consumer rights and this 3-year warranty is provided to you in addition to these rights, and does not prejudice your consumer rights in any way. However, your consumer rights will not include protection for accidental damage and theft cover. For more information on your consumer rights for faulty goods, <a href="http://www.amazon.co.uk/gp/help/customer/display.html?nodeId=200900540" target="_blank">click here</a>.



</div><div id="bb_extra_feature_B006X5F0NS_addToOrder" class="bbButton">
           <a href="javascript:BBPopover.addToOrder("B006X5F0NS");">
            <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/add-to-kindle-order._V156427493_.png" width="143" alt="Add to Kindle Order" title="Add to Kindle Order" height="28" border="0">
          </a>
        </div>
        <div id="bb_noThanks" class="bbButtonHidden noThanksButton">
              <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/nothanks.gif" alt="No thanks" class="ap_custom_close" title="No thanks" border="0">
        </div>
     
      </td>
    </tr>
  </tbody></table>
</div>
</div>
<script type="text/javascript">
amznJQ.onReady('kindleDeviceJS', function() {
  BBPopover.sessionId = '277-6643056-3126939';
  var refTag = 'kinW_ddp_pop4';
  var learnMoreLink = jQuery("#bb_lm_B006X5F0NS").attr("href");
  if ( learnMoreLink ) {
    var refTagPattern = /ref=\w*/;
    refTag = refTagPattern.exec( learnMoreLink );
    refTag = new String(refTag).substr( 4 ); 
  }

  BBPopover.refTag['B006X5F0NS'] = refTag;
  BBPopover.registerDynamicPopover( 'B006X5F0NS', function() {
    BBPopover.selectedAsin['B006X5F0NS'] = 'B006X5F0NS';
    BBPopover.displayedAsin['B006X5F0NS'] = 'B006X5F0NS';
    BBPopover.originalAsin['B006X5F0NS'] = 'B006X5F0NS';
    jQuery.ajax({
      cache: false,
      data: {
        "asin": "B006X5F0NS",
        "asinCSVList" : "",
        "sId" : BBPopover.sessionId,
        "baseRef" : BBPopover.refTag['B006X5F0NS'],
        "isFirstLoad" : 1,
        "bundlePriceOverride" : ""
      },
      dataType: "json",
      success: function(data, status) {
        if ( data && data.error == 0 ) {
          for ( var key in data ) {
            if ( key == "error" ) {
              continue;
            }
            BBPopover.asinCache[key] = data[key];
            jQuery('#bb_extra_B006X5F0NS').children('.popoverLoading').css('display','none');
            BBPopover.doUpdate( 'B006X5F0NS', key, 1 );
            /* Pull in the image size from its parent object setting */
            var imgParam = jQuery('#bb_extra_feature_B006X5F0NS_productImage').css('height');
            jQuery('#bb_extra_feature_B006X5F0NS_productImage img').css('height',imgParam);
            /* Display all product info after aloading*/
            jQuery('#bb_extra_B006X5F0NS').children('.popoverLoaded').css('display','block');
          }
        }
      },
      type: "GET",
      url: "/gp/digital/fiona/ajax/buyBoxTwister/ref=" + BBPopover.refTag['B006X5F0NS'] + "_bbpfl"
    });
  });
});
</script>












<div id="bb_extra_B004SD26Z2_title" style="display:none;">Amazon Kindle Zip Sleeve, Graphite</div><div id="bb_extra_B004SD26Z2" class="bb_extra" style="display:none" width="760" modal="true"><div class="popoverLoading">
  <table border="0"><tbody>
    <tr>
      <td style="border:0;padding:0;width:16px"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/icon_spinner._V192252841_.gif" width="16" height="16" border="0"></td>
      <td style="border:0;padding:0">Loading, please wait</td>
    </tr>
  </tbody></table>
</div>
<div class="popoverLoaded" style="display:none">
  <table>
   <tbody>
    <tr>
      <td style="text-align:center;vertical-align:center;">
        <div id="bb_extra_feature_B005PB2T6C_productImage" style="height:280px"></div>
        <br>
        <div id="bb_extra_feature_B005PB2T6C_altImages"></div>
      </td>
      <td style="height:140px;vertical-align:center;padding-left:10px">
        <div id="bb_extra_feature_B005PB2T6C_title" class="popoverTitle"></div>
        
        <div id="bb_extra_feature_B005PB2T6C_price" class="popoverPrice"></div>
        <div id="bb_extra_feature_B005PB2T6C_variations"></div><div class="para">
<ul>
<li>Simple, stylish, lightweight sleeve protects Kindle from scuffs and scratches</li>
<li>Convenient zipper closure keeps your device secure when you're on the go.</li>
<li>Available in 5 colours</li>

</ul>
</div><div id="bb_extra_feature_B005PB2T6C_addToOrder" class="bbButton">
           <a href="javascript:BBPopover.addToOrder("B005PB2T6C");">
            <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/add-to-kindle-order._V156427493_.png" width="143" alt="Add to Kindle Order" title="Add to Kindle Order" height="28" border="0">
          </a>
        </div>
        <div id="bb_noThanks" class="bbButtonHidden noThanksButton">
              <img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/nothanks.gif" alt="No thanks" class="ap_custom_close" title="No thanks" border="0">
        </div>
     
      </td>
    </tr>
  </tbody></table>
</div>
</div>
<script type="text/javascript">
amznJQ.onReady('kindleDeviceJS', function() {
  BBPopover.sessionId = '277-6643056-3126939';
  var refTag = 'kin3w_ddp_bbe3';
  var learnMoreLink = jQuery("#bb_lm_B004SD26Z2").attr("href");
  if ( learnMoreLink ) {
    var refTagPattern = /ref=\w*/;
    refTag = refTagPattern.exec( learnMoreLink );
    refTag = new String(refTag).substr( 4 ); 
  }

  BBPopover.refTag['B004SD26Z2'] = refTag;
  BBPopover.registerDynamicPopover( 'B004SD26Z2', function() {
    BBPopover.selectedAsin['B005PB2T6C'] = 'B004SD26Z2';
    BBPopover.displayedAsin['B005PB2T6C'] = 'B004SD26Z2';
    BBPopover.originalAsin['B005PB2T6C'] = 'B004SD26Z2';
    jQuery.ajax({
      cache: false,
      data: {
        "asin": "B004SD26Z2",
        "asinCSVList" : "",
        "sId" : BBPopover.sessionId,
        "baseRef" : BBPopover.refTag['B004SD26Z2'],
        "isFirstLoad" : 1,
        "bundlePriceOverride" : ""
      },
      dataType: "json",
      success: function(data, status) {
        if ( data && data.error == 0 ) {
          for ( var key in data ) {
            if ( key == "error" ) {
              continue;
            }
            BBPopover.asinCache[key] = data[key];
            jQuery('#bb_extra_B004SD26Z2').children('.popoverLoading').css('display','none');
            BBPopover.doUpdate( 'B005PB2T6C', key, 1 );
            /* Pull in the image size from its parent object setting */
            var imgParam = jQuery('#bb_extra_feature_B005PB2T6C_productImage').css('height');
            jQuery('#bb_extra_feature_B005PB2T6C_productImage img').css('height',imgParam);
            /* Display all product info after aloading*/
            jQuery('#bb_extra_B004SD26Z2').children('.popoverLoaded').css('display','block');
          }
        }
      },
      type: "GET",
      url: "/gp/digital/fiona/ajax/buyBoxTwister/ref=" + BBPopover.refTag['B004SD26Z2'] + "_bbpfl"
    });
  });
});
</script>












  



  
    
    
    
    
    
    
    
    

    
    
		
  

                                                                                                                                                               
  
    
    
    
		

                                                                                                                                                               
                                                                                                                                                               

  	
  

    
                                                                                                                                                               
                                                                                                                                                               

  
      
  
    
    
    
		
  
  
  
  
  

  





<br>





















<style type="text/css">
  .nav-npm-sprite-place-holder{
    background: url(http://g-ecx.images-amazon.com/images/G/02/marketing/prime/ev/Sprite_Nav._V399807289_.png);
  }

  #nav-prime-menu{
    font-family: arial,sans-serif;
    width: 310px;
    background-color: white;
  }

  #nav-npm-header{
    padding-bottom: 11px;
    font-family: arial,sans-serif;
    font-size: 13px;
    font-weight: bold;
    color: #333333;
  }

  .nav-npm-content{
    height: 98px;
  }

  .nav-npm-content-text{
    width: 212px;
    float: left;
    margin-top: 18px;
  }
  .nav-npm-text-title, a.nav-npm-text-title-a, a.nav-npm-text-title-a:link, a.nav-npm-text-title-a:visited, a.nav-npm-text-title-a:hover, a.nav-npm-text-title-a:active{
    font-family: arial,sans-serif;
    font-size: 13px;
    font-weight: bold;
    color: #E47923;
    text-decoration: none;
  }
  .nav-npm-text-title{
    margin-top: 1px;
    margin-bottom: 4px;
  }
  .nav-npm-text-detail, a.nav-npm-text-detail-a, a.nav-npm-text-detail-a:link, a.nav-npm-text-detail-a:visited, a.nav-npm-text-detail-a:hover, a.nav-npm-text-detail-a:active{
    font-family: arial,sans-serif;
    font-size: 12px;
    color: #333333;
  }
  .nav-npm-text-detail{
    margin: 0px;
  }
  .nav-npm-text-underline{
    text-decoration: underline;
  }

  .nav-npm-content-image{
    height: 80px;
    width: 86px;
    margin-top: 10px;
    margin-left: 10px;
    float: left;
  }
  a.nav-npm-content-image-a{
    height: 80px;
    width: 86px;
    display: block;
  }
  #nav-npm-prime-logo{
    height: 21px;
    width: 94px;
    margin-top: 16px;
    background-position: 0px 0px;
    background-repeat: no-repeat;
    float: left;
  }

  #nav-npm-footer{
    height: 40px;
  }

  .nav-npm-content, #nav-npm-footer{
    border-top: 1px solid #E0E0E0;
  }
</style>

<div style="display: none">
  <div id="nav-prime-menu">

    <div id="nav-npm-header">
      Join millions of Amazon Prime members who enjoy:

    </div>





    <div class="nav-npm-content">
      <div class="nav-npm-content-text">
        <p class="nav-npm-text-title">
          <a class="nav-npm-text-title-a" href="http://www.amazon.co.uk/gp/prime/ref=nav_menu_shipping_redirect">Unlimited One-Day Delivery</a>
        </p>
        <p class="nav-npm-text-detail"> Get fast delivery on millions of eligible items </p>
      </div>
      <div class="nav-npm-content-image nav-npm-sprite-place-holder" style="background-position: -4px -24px;">
        <a class="nav-npm-content-image-a" href="http://www.amazon.co.uk/gp/prime/ref=nav_menu_shipping_pic_redirect"></a>
      </div>
    </div>



    <div class="nav-npm-content">
      <div class="nav-npm-content-text">
        <p class="nav-npm-text-title">
          <a class="nav-npm-text-title-a" href="http://www.amazon.co.uk/gp/prime/ref=nav_menu_books_redirect">Kindle Owners' Lending Library</a>
        </p>
        <p class="nav-npm-text-detail"> Borrow from over 200,000 titles at no extra cost </p>
      </div>
      <div class="nav-npm-content-image nav-npm-sprite-place-holder" style="background-position: -4px -108px;">
        <a class="nav-npm-content-image-a" href="http://www.amazon.co.uk/gp/prime/ref=nav_menu_books_pic_redirect"></a>
      </div>
    </div>



    <div id="nav-npm-footer">
      <div class="nav-npm-content-text">
        <p class="nav-npm-text-detail">
          &gt;
          <a class="nav-npm-text-detail-a nav-npm-text-underline" href="https://www.amazon.co.uk/gp/subs/primeclub/signup/handler.html/ref=nav_menu_redirect">Get Started</a>
        </p>
      </div>
      <div class="nav-npm-sprite-place-holder" id="nav-npm-prime-logo"></div>
    </div>

  </div>
</div>




      
      

<div style="display: none;">







<div id="nav_browse_flyout">
  <div id="nav_subcats_wrap" class="nav_browse_wrap">
    <div id="nav_subcats">
      <div id="nav_subcats_0" class="nav_browse_subcat" data-nav-promo-id="mp3">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">MP3s &amp; Cloud Player</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/MP3-Music-Download/b/ref=sa_menu_mp3_str0?ie=UTF8&node=77197031" class="nav_a">MP3 Music Store</a><div class="nav_tag">Shop 20 million songs</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/dmusic/mp3/player/ref=sa_menu_mp3_acp10" class="nav_a">Cloud Player for Web</a><div class="nav_tag">Play from any browser</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/cloud-player-android/b/ref=sa_menu_mp3_and0?ie=UTF8&node=1947547031" class="nav_a">Cloud Player for Android</a><div class="nav_tag">For Android phones, and tablets</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/cloud-player-iphone-ipod-touch/b/ref=sa_menu_mp3_ios0?ie=UTF8&node=1947549031" class="nav_a">Cloud Player for iOS</a><div class="nav_tag">For iPhone and iPod touch</div></li>

  </ul>
</div><div id="nav_subcats_1" class="nav_browse_subcat" data-nav-promo-id="cloud-drive">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Amazon Cloud Drive</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/clouddrive/ref=sa_menu_acd_urc1" target="_blank" class="nav_a">Your Cloud Drive</a><div class="nav_tag">5 GB of free storage</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/feature.html/ref=sa_menu_acd_dsktopapp1?ie=UTF8&docId=1000655873" class="nav_a">Get the Desktop App</a><div class="nav_tag">For Windows and Mac</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/feature.html/ref=sa_menu_acd_lrn1?ie=UTF8&docId=1000655803" class="nav_a">Learn More About Cloud Drive</a></li>

  </ul>
</div><div id="nav_subcats_2" class="nav_browse_subcat" data-nav-promo-id="android">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Appstore for Android</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/feature.html/ref=sa_menu_adr_app2?ie=UTF8&docId=1000644603" class="nav_a">Appstore</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/feature.html/ref=sa_menu_adr_amz2?ie=UTF8&docId=1000501923" class="nav_a">Amazon Apps</a><div class="nav_tag">Kindle, mobile shopping, MP3, and more</div></li>

  </ul>
</div><div id="nav_subcats_3" class="nav_browse_subcat" data-nav-promo-id="books">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Books</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/books-used-books-textbooks/b/ref=sa_menu_bo3?ie=UTF8&node=266239" class="nav_a">Books</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Kindle-eBooks/b/ref=sa_menu_kbo3?ie=UTF8&node=341689031" class="nav_a">Kindle Books</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/New-Used-Textbooks-Books/b/ref=sa_menu_tb3?ie=UTF8&node=13384091" class="nav_a">Books For Study</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Audio-CDs-Books/b/ref=sa_menu_ab3?ie=UTF8&node=267859" class="nav_a">Audiobooks</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Audible-Audiobook-Downloads/b/ref=sa_menu_aab3?ie=UTF8&node=192376031" class="nav_a">Audible Audiobooks</a><div class="nav_tag">60,000 audiobook downloads</div></li>

  </ul>
</div><div id="nav_subcats_4" class="nav_browse_subcat" data-nav-promo-id="music-games-film-tv">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Music, Games, Film &amp; TV</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/music-rock-classical-pop-jazz/b/ref=sa_menu_mu4?ie=UTF8&node=229816" class="nav_a">Music</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/MP3-Music-Download/b/ref=sa_menu_dm4?ie=UTF8&node=77197031" class="nav_a">MP3 Downloads</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/musical-instruments-DJ/b/ref=sa_menu_mi4?ie=UTF8&node=340837031" class="nav_a">Musical Instruments &amp; DJ</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/DVDs-Blu-ray-box-sets/b/ref=sa_menu_dvd4?ie=UTF8&node=283926" class="nav_a">Film &amp; TV</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Blu-ray-Movies-TV/b/ref=sa_menu_blu4?ie=UTF8&node=293962011" class="nav_a">Blu-ray</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/PC-Video-Games-Consoles-Accessories/b/ref=sa_menu_cvg4?ie=UTF8&node=300703" class="nav_a">PC &amp; Video Games</a></li>

  </ul>
</div><div id="nav_subcats_5" class="nav_browse_subcat nav_super_cat" data-nav-promo-id="kindle">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Kindle</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B0083Q04M2/ref=sa_menu_kdpo2n5" class="nav_a">Kindle Fire</a><div class="nav_tag">Vibrant colour, movies, webs, apps and more</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B0083PWAWU/ref=sa_menu_kdptan5" class="nav_a">Kindle Fire HD</a><div class="nav_tag">Stunning HD, Dolby Audio, Ultra-fast Wi-Fi</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B007HCCOD0/ref=sa_menu_kdpsz5" class="nav_a">Kindle</a><div class="nav_tag">Small, light, perfect for reading</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B007OZO03M/ref=sa_menu_kdpcwi5" class="nav_a">Kindle Paperwhite</a><div class="nav_tag">Our most advanced e-reader</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B007OZNWRC/ref=sa_menu_kdpcwa5" class="nav_a">Kindle Paperwhite 3G</a><div class="nav_tag">With free 3G wireless</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/dp/B002LVUWFE/ref=sa_menu_kdpshan5" class="nav_a">Kindle Keyboard 3G</a><div class="nav_tag">Physical keyboard with Wi-Fi and free 3G</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/kindle/kcp/ref=sa_menu_krdg5" class="nav_a">Free Kindle Reading Apps</a><div class="nav_tag">For PC, iPad, iPhone, Android, and more</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_kacces5?ie=UTF8&node=426479031" class="nav_a">Kindle Accessories</a></li>

  </ul>
  <ul class="nav_browse_ul nav_browse_cat2_ul">
<li class="nav_pop_li nav_browse_cat_head">&nbsp;</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/feature.html/ref=sa_menu_kds5?ie=UTF8&docId=1000659983" class="nav_a">Kindle Owners' Lending Library</a><div class="nav_tag">With Prime, Kindle device owners read for free</div></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Kindle-eBooks/b/ref=sa_menu_kbo5?ie=UTF8&node=341689031" class="nav_a">Kindle Books</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_knwstnd35?ie=UTF8&node=2092391031" class="nav_a">Newsstand</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/kindle-store-ebooks-newspapers-blogs/b/ref=sa_menu_ks5?ie=UTF8&node=341677031" class="nav_a">Kindle Store</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/gp/digital/fiona/manage/ref=sa_menu_myk5" class="nav_a">Manage Your Kindle</a><div class="nav_tag">Your content, devices, settings, and more</div></li>

  </ul>
</div><div id="nav_subcats_6" class="nav_browse_subcat" data-nav-promo-id="electronics">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Electronics</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/digitalcamera-dslr-camcorders-lenses/b/ref=sa_menu_p6?ie=UTF8&node=560834" class="nav_a">Camera &amp; Photo</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/tv-bluray-dvd-home-cinema/b/ref=sa_menu_tv6?ie=UTF8&node=560858" class="nav_a">TV</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_hom_cin6?ie=UTF8&node=443721031" class="nav_a">Home Cinema</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/mp3-ipod-headphones-DAB-radio/b/ref=sa_menu_pa6?ie=UTF8&node=560884" class="nav_a">Audio, MP3 &amp; Accessories</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/sat-nav-car-GPS/b/ref=sa_menu_stnv6?ie=UTF8&node=509908031" class="nav_a">Sat Nav &amp; Car Electronics</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/mobile-phones-smartphones/b/ref=sa_menu_phsacc6?ie=UTF8&node=560820" class="nav_a">Phones &amp; Accessories</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/PC-Video-Games-Consoles-Accessories/b/ref=sa_menu_cvg6?ie=UTF8&node=300703" class="nav_a">PC &amp; Video Games</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/electronics-camera-mp3-ipod-tv/b/ref=sa_menu_el6?ie=UTF8&node=560798" class="nav_a">All Electronics</a></li>

  </ul>
</div><div id="nav_subcats_7" class="nav_browse_subcat" data-nav-promo-id="computers-office">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Computers &amp; Office</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_pc7?ie=UTF8&node=514938031" class="nav_a">PCs &amp; Laptops</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_ca7?ie=UTF8&node=428654031" class="nav_a">Computer Accessories</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_cc7?ie=UTF8&node=428655031" class="nav_a">Computer Components</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/software-business-finance-virus-protection/b/ref=sa_menu_sw7?ie=UTF8&node=300435" class="nav_a">Software</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/PC-Video-Games-Consoles-Accessories/b/ref=sa_menu_cvg7?ie=UTF8&node=300703" class="nav_a">PC &amp; Video Games</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/b/ref=sa_menu_pi7?ie=UTF8&node=428653031" class="nav_a">Printers &amp; Ink</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/office-products-pens-paper/b/ref=sa_menu_ops7?ie=UTF8&node=192413031" class="nav_a">Stationery &amp; Office Supplies</a></li>

  </ul>
</div><div id="nav_subcats_8" class="nav_browse_subcat" data-nav-promo-id="home-garden-pets">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Home, Garden &amp; Pets</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Garden-Outdoors-Home/b/ref=sa_menu_lg8?ie=UTF8&node=11052671" class="nav_a">Garden &amp; Outdoors</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Furniture-beds-bedding-clocks-furnishings/b/ref=sa_menu_fd8?ie=UTF8&node=10709121" class="nav_a">Homeware &amp; Furniture</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Kitchen-cookware-glassware-cutlery-pans/b/ref=sa_menu_ki8?ie=UTF8&node=11052681" class="nav_a">Kitchen &amp; Dining</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/kitchen-appliances-vacuums-heaters-fans/b/ref=sa_menu_app8?ie=UTF8&node=391784011" class="nav_a">Small Appliances 
</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Washing-Machines-Fridges-Freezers-Ovens-Tumble-Dryers/b/ref=sa_menu_la8?ie=UTF8&node=908798031" class="nav_a">Large Appliances
</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Pet-Supplies-Food-Animals/b/ref=sa_menu_ps8?ie=UTF8&node=340840031" class="nav_a">Pet Supplies</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Lighting-LED-bulbs-lamps-energy-saving/b/ref=sa_menu_light8?ie=UTF8&node=213077031" class="nav_a">Lighting</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/home-garden-kitchen-appliances-lighting/b/ref=sa_menu_hg8?ie=UTF8&node=11052591" class="nav_a">All Home &amp; Garden</a></li>

  </ul>
</div><div id="nav_subcats_9" class="nav_browse_subcat" data-nav-promo-id="baby-kids-toys">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Toys, Children &amp; Baby</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/toys-games-dolls-puzzles-arts-and-crafts/b/ref=sa_menu_tg9?ie=UTF8&node=468292" class="nav_a">Toys &amp; Games</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Baby-Car-Seats-Prams-Nursery/b/ref=sa_menu_ba9?ie=UTF8&node=59624031" class="nav_a">Baby</a></li>

  </ul>
</div><div id="nav_subcats_10" class="nav_browse_subcat" data-nav-promo-id="clothes-shoes-watches">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Clothes, Shoes &amp; Watches</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Clothing-Fashion-Women-Men-Kids/b/ref=sa_menu_ap10?ie=UTF8&node=83450031" class="nav_a">Clothing</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Shoes-Smart-Casual-Trainers-Bags/b/ref=sa_menu_shoeh10?ie=UTF8&node=355005011" class="nav_a">Shoes</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Jewellery-Charms-Rings-Earrings-Pendants/b/ref=sa_menu_jewelry10?ie=UTF8&node=193716031" class="nav_a">Jewellery</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Watches-Chronograph-Analogue-Digital-Automatic/b/ref=sa_menu_watches10?ie=UTF8&node=328228011" class="nav_a">Watches</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Shoes-Bags-Accessories-Satchels-Handbags/b/ref=sa_menu_hbags10?ie=UTF8&node=362353011" class="nav_a">Bags &amp; Accessories</a></li>

  </ul>
</div><div id="nav_subcats_11" class="nav_browse_subcat" data-nav-promo-id="sports-outdoors">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Sports &amp; Outdoors</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Exercise-Fitness-Toning-Strength-Equipment/b/ref=sa_menu_exf11?ie=UTF8&node=319535011" class="nav_a">Exercise &amp; Fitness</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Camping-Hiking-Tents-Sleeping-Bags/b/ref=sa_menu_cphk11?ie=UTF8&node=319545011" class="nav_a">Camping &amp; Hiking</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Cycling-Bikes-Helmets-Lights-Accessories/b/ref=sa_menu_bksc11?ie=UTF8&node=324144011" class="nav_a">Bikes &amp; Scooters</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Golf-Balls-Clubs-Bags-Clothing/b/ref=sa_menu_glf11?ie=UTF8&node=324115011" class="nav_a">Golf</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Sportswear-Outdoor-Shirts-Jackets-Shorts/b/ref=sa_menu_spwr11?ie=UTF8&node=116189031" class="nav_a">Athletic &amp; Outdoor Clothing</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Sports-Exercise-Fitness-Bikes-Camping/b/ref=sa_menu_allsp11?ie=UTF8&node=318949011" class="nav_a">All Sports &amp; Outdoors</a></li>

  </ul>
</div><div id="nav_subcats_12" class="nav_browse_subcat" data-nav-promo-id="grocery-health-beauty">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">Grocery, Health &amp; Beauty</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Coffee-Snacks-International-Speciality-Food/b/ref=sa_menu_gs12?ie=UTF8&node=340834031" class="nav_a">Grocery</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/health-beauty-haircare-wellbeing-dentalcare-shaving-hairremoval/b/ref=sa_menu_da12?ie=UTF8&node=65801031" class="nav_a">Health &amp; Beauty</a></li>

  </ul>
</div><div id="nav_subcats_13" class="nav_browse_subcat" data-nav-promo-id="diy-tools-car">
  <ul class="nav_browse_ul nav_browse_cat_ul">
<li class="nav_pop_li nav_browse_cat_head">DIY, Tools &amp; Car</li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/DIY-Power-Garden-Tools-Accessories/b/ref=sa_menu_diyhi13?ie=UTF8&node=79903031" class="nav_a">DIY &amp; Tools</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/Car-Motorbike-Accessories-Parts/b/ref=sa_menu_car13?ie=UTF8&node=248877031" class="nav_a">Car &amp; Motorbike</a></li>
<li class="nav_pop_li "><a href="http://www.amazon.co.uk/sat-nav-car-GPS/b/ref=sa_menu_stnvdiy13?ie=UTF8&node=509908031" class="nav_a">Sat Nav &amp; Car Electronics</a></li>

  </ul>
</div>
    </div>
    <div class="nav_subcats_div"></div>
    <div class="nav_subcats_div nav_subcats_div2"></div>
  </div>
  <div id="nav_cats_wrap" class="nav_browse_wrap">
    <ul id="nav_cats" class="nav_browse_ul">
      <li id="nav_cat_0" class="nav_pop_li nav_cat">MP3s &amp; Cloud Player<div class="nav_tag">20 million songs, play anywhere</div></li>
<li id="nav_cat_1" class="nav_pop_li nav_cat">Amazon Cloud Drive<div class="nav_tag">5 GB of free storage</div></li>
<li id="nav_cat_2" class="nav_pop_li nav_cat">Appstore for Android<div class="nav_tag">Get a paid app for free every day</div></li>
<li id="nav_cat_3" class="nav_pop_li nav_cat">Books</li>
<li id="nav_cat_4" class="nav_pop_li nav_cat">Music, Games, Film &amp; TV</li>
<li id="nav_cat_5" class="nav_pop_li nav_cat">Kindle</li>
<li id="nav_cat_6" class="nav_pop_li nav_cat">Electronics</li>
<li id="nav_cat_7" class="nav_pop_li nav_cat">Computers &amp; Office</li>
<li id="nav_cat_8" class="nav_pop_li nav_cat">Home, Garden &amp; Pets</li>
<li id="nav_cat_9" class="nav_pop_li nav_cat">Toys, Children &amp; Baby</li>
<li id="nav_cat_10" class="nav_pop_li nav_cat">Clothes, Shoes &amp; Watches</li>
<li id="nav_cat_11" class="nav_pop_li nav_cat">Sports &amp; Outdoors</li>
<li id="nav_cat_12" class="nav_pop_li nav_cat">Grocery, Health &amp; Beauty</li>
<li id="nav_cat_13" class="nav_pop_li nav_cat">DIY, Tools &amp; Car</li>
<li id="nav_fullstore" class="nav_pop_li nav_divider_before nav_last_li nav_a_carat">
           <span class="nav_a_carat"></span><a href="http://www.amazon.co.uk/gp/site-directory/ref=sa_menu_fullstore" class="nav_a">Full Shop Directory</a></li>

    </ul>
    <div id="nav_cat_indicator" class="nav-sprite"></div>
  </div>
</div>








<!-- Updated -->
<div id="nav_your_account_flyout">  <ul class="nav_pop_ul">
<li class="nav_pop_li nav_divider_after">
  <div><a href="https://www.amazon.co.uk/ap/signin?_encoding=UTF8&openid.assoc_handle=gbflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.uk%2Fgp%2Fyourstore%2Fhome%3Fie%3DUTF8%26ref_%3Dgno_signin" class="nav-action-button nav-sprite" rel="nofollow">
      <span class="nav-action-inner nav-sprite">Sign in</span>
    </a></div>
  <div class="nav_pop_new_cust">New customer? <a href="https://www.amazon.co.uk/ap/register?_encoding=UTF8&openid.assoc_handle=gbflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.uk%2Fgp%2Fyourstore%2Fhome%3Fie%3DUTF8%26ref_%3Dgno_newcust" rel="nofollow" class="nav_a">Start here.</a></div>
</li>
 <li class="nav_pop_li"><a href="https://www.amazon.co.uk/gp/css/homepage.html/ref=topnav_ya" class="nav_a">Your Account</a></li>
 <li class="nav_pop_li"><a href="https://www.amazon.co.uk/gp/css/order-history/ref=gno_yam_yrdrs" class="nav_a" id="nav_prefetch_yourorders">Your Orders</a></li>
 <li class="nav_pop_li"><a href="http://www.amazon.co.uk/gp/registry/wishlist/ref=gno_listpop_wi" class="nav_a">Your Wish List</a></li>
 <li class="nav_pop_li"><a href="http://www.amazon.co.uk/gp/yourstore/ref=gno_recs" class="nav_a">Your Recommendations</a></li>
 <li class="nav_pop_li"><a href="https://www.amazon.co.uk/gp/subscribe-and-save/manager/viewsubscriptions/ref=gno_yam_mysns" class="nav_a">Manage Your Subscribe &amp; Save Items</a></li>
 <li class="nav_pop_li nav_divider_before"><a href="http://www.amazon.co.uk/gp/digital/fiona/manage/ref=gno_yam_myk" class="nav_a">Manage Your Kindle</a></li>
 <li class="nav_pop_li"><a href="http://www.amazon.co.uk/gp/dmusic/mp3/player/ref=gno_yam_cldplyr" class="nav_a">Your Cloud Player</a><div class="nav_tag">Play from any browser</div></li>
 <li class="nav_pop_li nav_last_li"><a href="http://www.amazon.co.uk/clouddrive/ref=gno_yam_clddrv" class="nav_a">Your Cloud Drive</a><div class="nav_tag">5 GB of free storage</div></li>
   </ul>   <!--[if IE ]>      <div class='nav-ie-min-width' style='width: 160px'></div>    <![endif]-->  </div>








<div id="nav_cart_flyout" class="nav-empty">
  <ul class="nav_dynamic"></ul>
  <div class="nav-ajax-message"></div>
  <div class="nav-dynamic-empty">
    <p class="nav_p nav-bold nav-cart-empty"> Your Shopping Basket is empty.</p>
    <p class="nav_p "> Give it purpose -- fill it with books, DVDs, clothes, electronics and more.</p>
    <p class="nav_p "> If you already have an account, <a href="https://www.amazon.co.uk/ap/signin?_encoding=UTF8&openid.assoc_handle=gbflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.uk%2Fgp%2Fyourstore%2Fhome%3Fie%3DUTF8%26ref_%3Dgno_signin_cart" class="nav_a">sign in</a>.</p>
  </div>
  <div class="nav-ajax-error-msg">
    <p class="nav_p nav-bold"> There's a problem previewing your shopping basket at the moment.</p>
    <p class="nav_p "> Check your Internet connection and <a href="http://www.amazon.co.uk/gp/cart/view.html/ref=gno_flyout_viewcart?ie=UTF8&hasWorkingJavascript=1" class="nav_a">go to your cart</a>, or <a href="javascript:void(0);" class="nav_a nav-try-again">try again</a>.</p>
  </div>

      <a href="http://www.amazon.co.uk/gp/cart/view.html/ref=gno_flyout_viewcart?ie=UTF8&hasWorkingJavascript=1" id="nav-cart-menu-button" class="nav-action-button nav-sprite"><span class="nav-action-inner nav-sprite">
      View Shopping Basket
      <span class="nav-ajax-success">
        <span id="nav-cart-zero">(<span class="nav-cart-count">0</span> items)</span>
        <span id="nav-cart-one" style="display: none;">(<span class="nav-cart-count">0</span> item)</span>
        <span id="nav-cart-many" style="display: none;">(<span class="nav-cart-count">0</span> items)</span>
      </span>
    </span></a>
  
  
</div>







<!-- Updated -->
<div id="nav_wishlist_flyout" class="nav-empty">
  <div class="nav-ajax-message"></div>
  <ul class="nav_dynamic nav_pop_ul nav_divider_after"></ul>
  <ul class="nav_pop_ul">
     <li class="nav_pop_li nav-dynamic-empty"><a href="http://www.amazon.co.uk/gp/wishlist/ref=gno_createwl" class="nav_a">Create a Wish List</a></li>
 <li class="nav_pop_li"><a href="http://www.amazon.co.uk/gp/registry/search.html/ref=gno_listpop_find?ie=UTF8&type=wishlist" class="nav_a">Find a Wish List</a></li>
 <li class="nav_pop_li"><a href="http://www.amazon.co.uk/wishlist/universal/ref=gno_listpop_uwl" class="nav_a">Wish from Any Website</a><div class="nav_tag">Add items to your List from anywhere</div></li>
 <li class="nav_pop_li nav_last_li"><a href="http://www.amazon.co.uk/gp/wedding/homepage/ref=gno_listpop_wr" class="nav_a">Wedding List</a></li>

  </ul>
</div>




<script type="text/html" id="nav-tpl-wishlist">
  <# jQuery.each(wishlist, function (i, item) { #>
    <li class='nav_pop_li'>
      <a href='<#=item.url #>' class='nav_a'>
        <#=item.name #>
      </a>
      <div class='nav_tag'>
        <# if(typeof item.count !='undefined') { #>
          <#=
            (item.count == 1 ? "{count} item" : "{count} items")
              .replace("{count}", item.count)
          #>
        <# } #>
      </div>
    </li>
  <# }); #>
</script>
<script type="text/html" id="nav-tpl-cart">
  <# jQuery.each(cart, function (i, item) { #>
    <li class='nav_cart_item'>
      <a href='<#=item.url #>' class='nav_a'>
        <img class='nav_cart_img' src='<#=item.img #>'/>
        <span class='nav-cart-title'><#=item.name #></span>
        <span class='nav-cart-quantity'>
          <# if(typeof item.wireless !== 'undefined') { #>
            <#= "".replace("{count}", item.qty) #>
          <# } else { #>
            <#= "Quantity: {count}".replace("{count}", item.qty) #>
          <# } #>
        </span>
      </a>
    </li>
  <# }); #>
</script>
<script type="text/html" id="nav-tpl-asin-promo">
  <a href='<#=destination #>' class='nav_asin_promo'>
    <img src='<#=image #>' class='nav_asin_promo_img'/>
    <span class='nav_asin_promo_headline'><#=headline #></span>
    <span class='nav_asin_promo_info'>
      <span class='nav_asin_promo_title'><#=productTitle #></span>
      <span class='nav_asin_promo_title2'><#=productTitle2 #></span>
      <span class='nav_asin_promo_price'><#=price #></span>
    </span>
    <span class='nav_asin_promo_button nav-sprite'><#=button #></span>
  </a>
</script>
</div>
<script type="text/javascript">














_navbar.prefetch = function() {
amznJQ.addPL(['http://z-ecx.images-amazon.com/images/G/01/browser-scripts/registriesCSS/GB-combined-2130994517._V387395653_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/site-wide-js-1.2.6-beacon/site-wide-11366246298._V1_.js',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/uk-site-wide-css-beacon/site-wide-6146007985._V1_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/wcs-ya-homepage-beaconized/wcs-ya-homepage-beaconized-322195074._V1_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/wcs-ya-homepage/wcs-ya-homepage-1020977892._V1_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/wcs-ya-order-history-beaconized/wcs-ya-order-history-beaconized-2950527408._V1_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/wcs-ya-order-history/wcs-ya-order-history-1992112531._V1_.css',
'https://images-na.ssl-images-amazon.com/images/G/01/x-locale/cs/css/images/amznbtn-sprite03._V387356454_.png',
'https://images-na.ssl-images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png',
'https://images-na.ssl-images-amazon.com/images/G/02/gno/images/general/navAmazonLogoFooter._V152929188_.gif',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/transparent-pixel._V167145160_.gif',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/help/images/spotlight/kindle-family-02b._V160654766_.jpg',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/orders/images/acorn._V192195382_.gif',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/orders/images/btn-close._V192195353_.gif',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/ya/images/new-link._V192238985_.gif',
'https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/ya/images/shipment_large_lt._V192238984_.gif']);
}
    amznJQ.declareAvailable('navbarBTFLite');
    amznJQ.declareAvailable('navbarBTF');
</script>









<table width="100%" align="center">





</table>

























<div id="rhf">

<div class="cBox secondary">
  <span class="cBoxTL"><!-- &nbsp; --></span>
  <span class="cBoxTR"><!-- &nbsp; --></span>
  <span class="cBoxR"><!-- &nbsp; --></span>
  <span class="cBoxBL"><!-- &nbsp; --></span>
  <span class="cBoxBR"><!-- &nbsp; --></span>
  <span class="cBoxB"><!-- &nbsp; --></span>
  
  <div class="cBoxInner"><div class="rhf_header"><span id="rhfMainHeading">Your Recent History</span>&nbsp;<span class="tiny" id="rhfLearnMore">(<a href="http://www.amazon.co.uk/gp/yourstore/cc/ref=pd_rhf_lm">What's this?</a>)</span></div><div id="rhf_container" style="">





<div class="rhf_loading_outer"><table class="rhf_loading_middle"><tbody><tr><td class="rhf_loading_inner"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/loadIndicator-large._V192262978_.gif"></td></tr></tbody></table></div>


<script type="text/JavaScript">

amznJQ.onReady('JQuery', function() { (function($) {

    window.RECS_rhfShvlLoading = false;
    window.RECS_rhfShvlLoaded = false;
    window.RECS_rhfInView = false;
    window.RECS_rhfMetrics = {};
    $("#rhf_container").show();
    var rhfShvlEventHandler = function () {
        if (   ! window.RECS_rhfShvlLoaded
            && ! window.RECS_rhfShvlLoading
            && $('#rhf_container').size() > 0 ) {
            var yPosition = $(window).scrollTop() + $(window).height();
            var rhfElementFound = $('#rhfMainHeading').size();
            var rhfPosition = $('#rhfMainHeading').offset().top;

            if (/webkit.*mobile/i.test(navigator.userAgent)) {
                rhfPosition -= $(window).scrollTop();
            }

            if (rhfElementFound && ( rhfPosition - yPosition < 400 )) {
                window.RECS_rhfMetrics["start"] = (new Date()).getTime();
                window.RECS_rhfShvlLoading = true;
                var handleSuccess = function (html) {
                    $("#rhf_container").html(html);
                    $("#rhf0Shvl").trigger("render-shoveler");
                    window.RECS_rhfShvlLoaded = true;
                    window.RECS_rhfMetrics["loaded"] = (new Date()).getTime();
                };
                var handleError = function () {
                    $("#rhf_container").hide();
                    $("#rhf_error").show();
                    window.RECS_rhfMetrics["loaded"] = "error";
                };
                $.ajax({
                    url: '/gp/history/external/full-rhf-rec-handler.html',
                    type: "POST",
                    timeout: 10000,
                    data: {
                        shovelerName    : 'rhf0',
                        key             : 'rhf',
                        numToPreload    : '8',
                        isGateway       : 0,
                        refTag          : 'pd_rhf_dp',
                        parentSession   : '277-6643056-3126939',
                        excludeASIN     : 'B005890FUI',
                        renderPopover   : 0,
                        forceSprites    : 1,
                        currentPageType : 'Detail',
                        currentSubPageType : 'Kindle_HW',
                        searchAlias     : "",
                        keywords        : "",
                        node            : ''
                    },
                    dataType: "html",
                    success: function (data, status) {
                        handleSuccess(data);
                    },
                    error: function (xhr, status) {
                        handleError();
                    }
                });
            }
        }
    };
    var rhfInView = function() {
        if (!window.RECS_rhfInView && $('#rhf_container').size() > 0) {
            var yPosition = $(window).scrollTop() + $(window).height();
            var rhfElementFound = ($('#rhfMainHeading').size() > 0);
            var rhfPosition = $('#rhfMainHeading').offset().top;
            if (/webkit.*mobile/i.test(navigator.userAgent)) {
                rhfPosition -= $(window).scrollTop();
            }
            if (rhfElementFound && ( rhfPosition - yPosition < 0 )) {
                window.RECS_rhfInView = true;
                window.RECS_rhfMetrics["inView"] = (new Date()).getTime();
            }
        }
    };
    $(document).ready(rhfShvlEventHandler);
    $(window).scroll(rhfShvlEventHandler);
    $(document).ready(rhfInView);
    $(window).scroll(rhfInView);
})(jQuery); });
</script>


</div><noscript>






&lt;table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-top: 10px"&gt;
    &lt;tr valign="top"&gt;
        &lt;td valign="top"&gt;
            &lt;div class="rhfHistoryWrapper"&gt;
                &lt;p&gt;After viewing product detail pages or search results, look here to find an easy way to navigate back to pages you are interested in.&lt;/p&gt;
            &lt;/div&gt;
        &lt;/td&gt;
    &lt;/tr&gt;
    &lt;tr&gt;&lt;td&gt;
    &lt;div style="padding:10px 10px 0 10px; text-align:left;"&gt;
        &lt;b&gt;&lt;span style="color: rgb(204, 153, 0); font-weight: bold; font-size: 13px;"&gt; &amp;#8250; &lt;/span&gt;
        &lt;a href="/gp/yourstore/pym/ref=pd_pyml_rhf"&gt;Visit the Page You Made&lt;/a&gt;
        &lt;/b&gt;&lt;/div&gt;
    &lt;/td&gt;&lt;/tr&gt;
&lt;/table&gt;
</noscript><div id="rhf_error" style="display:none;">






<table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-top: 10px">
    <tbody><tr valign="top">
        <td valign="top">
            <div class="rhfHistoryWrapper">
                <p>After viewing product detail pages or search results, look here to find an easy way to navigate back to pages you are interested in.</p>
            </div>
        </td>
    </tr>
    <tr><td>
    <div style="padding:10px 10px 0 10px; text-align:left;">
        <b><span style="color: rgb(204, 153, 0); font-weight: bold; font-size: 13px;">  </span>
        <a href="http://www.amazon.co.uk/gp/yourstore/pym/ref=pd_pyml_rhf">Visit the Page You Made</a>
        </b></div>
    </td></tr>
</tbody></table>
</div></div>
</div>  


</div>    <br>


























<div id="navFooter">
  <table cellspacing="0">
    <tbody><tr>
      <td>
        <table class="navFooterThreeColumn" cellspacing="0">
          <tbody><tr>
            <td class="navFooterColSpacerOuter"></td>
            <td class="navFooterLinkCol">
<div class="navFooterColHead">Get to Know Us</div>
<ul>
<li><a href="http://www.amazon.co.uk/b/ref=gw_m_b_careers?ie=UTF8&node=202594011">Careers</a></li>
<li><a href="http://www.amazon.co.uk/gp/redirect.html/ref=footer_ir?_encoding=UTF8&location=http%3A%2F%2Fphx.corporate-ir.net%2Fphoenix.zhtml%3Fc%3D97664%26p%3Dirol-irhome&token=F9CAD8A11D4336B5E0B3C3B089FA066D0A467C1C">Investor Relations</a></li>
<li><a href="http://www.amazon.co.uk/gp/redirect.html/ref=footer_press?_encoding=UTF8&location=http%3A%2F%2Fphx.corporate-ir.net%2Fphoenix.zhtml%3Fc%3D251199%26p%3Dirol-mediaHome&token=F9CAD8A11D4336B5E0B3C3B089FA066D0A467C1C">Press Releases</a></li>
<li><a href="http://www.amazon.co.uk/Amazon-and-our-Planet/b/ref=footer_planet?ie=UTF8&node=299737031">Amazon and Our Planet</a></li>
</ul>
</td>
<td class="navFooterColSpacerInner"></td>
<td class="navFooterLinkCol">
<div class="navFooterColHead">Make Money with Us</div>
<ul>
<li><a href="http://services.amazon.co.uk/services/sell-on-amazon/how-it-works/?ld=AZUKSOAFooter">Sell on Amazon</a></li>
<li><a href="https://affiliate-program.amazon.co.uk/">Associates Programme</a></li>
<li><a href="http://services.amazon.co.uk/services/fulfilment-by-amazon/features-benefits/?ld=AZUKFBAFooter">Fulfilment by Amazon</a></li>
<li><a href="http://kdp.amazon.co.uk/">Self-publish with Us</a></li>
<li><span class="navFooterRightArrowBullet"></span> <a href="http://services.amazon.co.uk/services/?ld=AZUKALLFooter">See all</a></li>
</ul>
</td>
<td class="navFooterColSpacerInner"></td>
<td class="navFooterLinkCol">
<div class="navFooterColHead">Let Us Help You</div>
<ul>
<li><a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=footer_shiprates?ie=UTF8&nodeId=492868">Delivery Rates &amp; Policies</a></li>
<li><a href="http://www.amazon.co.uk/gp/subs/primeclub/signup/main.html/ref=footer_prime">Amazon Prime</a></li>
<li><a href="http://www.amazon.co.uk/gp/css/returns/homepage.html/ref=hy_f_4">Returns Are Easy</a></li>
<li><a href="http://www.amazon.co.uk/gp/digital/fiona/manage/ref=footer_myk">Manage Your Kindle</a></li>
<li><a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=gw_m_b_he?ie=UTF8&nodeId=471044">Help</a></li>
</ul>
</td>

            <td class="navFooterColSpacerOuter"></td>
          </tr>
        </tbody></table>
      </td>
    </tr>
    <tr>
      <td>
        <div class="navFooterLine navFooterLogoLine">
          <a href="http://www.amazon.co.uk/ref=footer_logo"><img src="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/navAmazonLogoFooter._V152929188_.gif" width="133" alt="amazon.co.uk" height="28" border="0"></a>
        </div>
        <div class="navFooterLine navFooterLinkLine navFooterPadItemLine">
          <a href="http://www.amazon.com.br/">Brazil</a>
<a href="http://www.amazon.ca/">Canada</a>
<a href="http://www.amazon.cn/">China</a>
<a href="http://www.amazon.fr/">France</a>
<a href="http://www.amazon.de/">Germany</a>
<a href="http://www.amazon.it/">Italy</a>
<a href="http://www.amazon.co.jp/">Japan</a>
<a href="http://www.amazon.es/">Spain</a>
<a href="http://www.amazon.com/">United States</a>

        </div>
        <div class="navFooterLine navFooterLinkLine navFooterDescLine">
          <table cellspacing="0">
            <tbody><tr>
<td class="navFooterDescSpacer" style="width: 38.0%"></td>
<td class="navFooterDescItem"><a href="http://www.abebooks.co.uk/">AbeBooks<br> <span class="navFooterDescText">Rare &amp; Collectible<br> Books</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.audible.co.uk/">Audible<br> <span class="navFooterDescText">Download<br> Audio Books</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://local.amazon.co.uk/">AmazonLocal<br> <span class="navFooterDescText">Great Local Deals<br> In Your City</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.bookdepository.co.uk/">Book Depository<br> <span class="navFooterDescText">Books With Free<br> Delivery Worldwide</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.dpreview.co.uk/">DPReview<br> <span class="navFooterDescText">Digital<br> Photography</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://uk.imdb.com/">IMDb<br> <span class="navFooterDescText">Movies, TV<br> &amp; Celebrities</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.javari.co.uk/f/welcome">Javari UK<br> <span class="navFooterDescText">Shoes<br> &amp; Handbags</span></a></td>
<td class="navFooterDescSpacer" style="width: 38.0%"></td>
</tr>
<tr><td>&nbsp;</td></tr>
<tr>
<td class="navFooterDescSpacer" style="width: 38.0%"></td>
<td class="navFooterDescItem"><a href="http://www.javari.fr/">Javari France<br> <span class="navFooterDescText">Shoes<br> &amp; Handbags</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.javari.jp/">Javari Japan<br> <span class="navFooterDescText">Shoes<br> &amp; Handbags</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.javari.de/f/willkommen">Javari Germany<br> <span class="navFooterDescText">Shoes<br> &amp; Handbags</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.junglee.com/">Junglee.com<br> <span class="navFooterDescText">Shop Online<br> in India</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.lovefilm.com/">LOVEFiLM<br> <span class="navFooterDescText">Watch Movies<br> Online</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.myhabit.com/">MYHABIT<br> <span class="navFooterDescText">Designer &amp; Fashion<br> Private Sale Site</span></a></td>
<td class="navFooterDescSpacer" style="width: 4%"></td>
<td class="navFooterDescItem"><a href="http://www.shopbop.com/uk/welcome">Shopbop<br> <span class="navFooterDescText">Designer<br> Fashion Brands</span></a></td>
<td class="navFooterDescSpacer" style="width: 38.0%"></td>
</tr>

          </tbody></table>
        </div>
        <div class="navFooterLine navFooterLinkLine navFooterPadItemLine">
          <a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=footer_cou?ie=UTF8&nodeId=1040616">Conditions of Use &amp; Sale</a>
<a href="http://www.amazon.co.uk/gp/help/customer/display.html/ref=footer_privacy?ie=UTF8&nodeId=502584">Privacy Notice</a>
<a href="http://www.amazon.co.uk/cookiesandinternetadvertising">Cookies &amp; Internet Advertising</a>
<span>
 1996-2013, Amazon.com, Inc. or its affiliates
</span>

        </div>
      </td>
    </tr>
    

  </tbody></table>
</div>
<!-- whfh-i6bY6p8zpDTHNmnX9e2914S43yZsFr4HIYsxnDNgINGsh570dSrWSTlD5Ht+g26i rid-0KGHD1WV7T4KNAQMVBGQ -->








<link type="text/css" href="./Kindle Touch  Touchscreen e-Reader with Wi-Fi, 6  E Ink Display_files/asinPopoverCSS-asinPopoverCSS-28226._V1_.css" rel="stylesheet">
<script type="text/javascript">
    amznJQ.addLogical('wysiwygUtilsJQ', ["http://z-ecx.images-amazon.com/images/G/01/nav2/gamma/wysiwygUtilsJQ/wysiwygUtilsJQ-wysiwygUtils-21812._V1_.js"]);
    amznJQ.addLogical('wysiwygWidgetsJQ', ["http://z-ecx.images-amazon.com/images/G/01/nav2/gamma/wysiwygWidgetsJQ/wysiwygWidgetsJQ-combined-core-5363._V1_.js"]);
    amznJQ.addLogical('asinPopoverCSS', []);
</script>
<script type="text/javascript"><!--
/* customer-reviews */

amznJQ.onReady('jQuery', function() {
  var voteAjaxDefaultBeforeSendReviews = function(buttonAnchor, buttonContainer, messageContainer) {
    messageContainer.html('Sending feedback...'); 
    buttonContainer.hide(); 
    messageContainer.show();
  };
  var voteAjaxDefaultSuccessReviews = function(aData, aStatus, buttonAnchor, buttonContainer, messageContainer, isNoButton) { 
    if (aData.redirect == 1) {
      return window.location.href=buttonAnchor.children[0].href;
    }
    if (aData.error == 1) {
      jQuery(buttonContainer.children()[0]).html('Sorry, we failed to record your vote. Please try again');
      messageContainer.hide();
      buttonContainer.show();
    } else {
      messageContainer.html('Thank you for your feedback.');
      if (isNoButton == 1) {
        messageContainer.append('<span class="black gl5">If this review is inappropriate, <a href="http://www.amazon.co.uk/gp/voting/cast/Reviews/2115/RSY06QYWIMLE5/Inappropriate/1/ref=cm_cr_dp_abuse_voteyn?ie=UTF8&target=&token=708A24DC42F87C05882616EEA0687414BB78E368&voteAnchorName=RSY06QYWIMLE5.2115.Inappropriate.Reviews&voteSessionID=277-6643056-3126939" class="noTextDecoration" style="color: #039;" >please let us know.</a></span>');
      }
      messageContainer.addClass('green');
    }
  };
  var voteAjaxDefaultErrorReviews = function(aStatus, aError, buttonAnchor, buttonContainer, messageContainer) { 
    jQuery(buttonContainer.children()[0]).html('Sorry, we failed to record your vote. Please try again');
    messageContainer.hide();
    buttonContainer.show();
  };

  jQuery('.votingButtonReviews').each(function(){
    jQuery(this).unbind('click.vote.Reviews');
    jQuery(this).bind('click.vote.Reviews', function(){
      var buttonAnchor = this;
      var buttonContainer = jQuery(this).parent();
      var messageContainer = jQuery(buttonContainer).next('.votingMessage');
      var isNoButton = jQuery(this).hasClass('noButton');
      jQuery.ajax({
        type: 'GET',
        dataType: 'json',
        ajaxTimeout: 10000,
        cache: false,
        beforeSend: function(){ 
          voteAjaxDefaultBeforeSendReviews(buttonAnchor, buttonContainer, messageContainer); 
        },
        success: function(data, textStatus){ 
          voteAjaxDefaultSuccessReviews(data, textStatus, buttonAnchor, buttonContainer, messageContainer, isNoButton); 
        },
        error: function(XMLHttpRequest, textStatus, errorThrown){
          voteAjaxDefaultErrorReviews(textStatus, errorThrown, buttonAnchor, buttonContainer, messageContainer);
        },
        url: buttonAnchor.children[0].href+'&type=json'
      });
      return false;
    });
  });
});


//--></script>











<script type="text/javascript">
!function() {
  if (amznJQ && amznJQ.addPL) {
    amznJQ.addPL([
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/clickWithinSearchPageStatic/clickWithinSearchPageStatic-1828160054._V1_.css",
      "http://g-ecx.images-amazon.com/images/G/02/x-locale/common/transparent-pixel._V167145160_.gif",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/jserrors/jserrors-1966534302._V1_.js",
      "http://g-ecx.images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/site-wide-js-1.2.6-beacon/site-wide-11366246298._V1_.js",
      "http://g-ecx.images-amazon.com/images/G/02/nav2/images/gui/searchSprite._V396211504_.gif",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/csmCELLS/csmCELLS-2674349615._V1_.js",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/search-css/search-css-4142872413._V1_.css",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/search-js-general/search-js-general-1775547764._V1_.js",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/search-js-mobile/search-js-mobile-2477532308._V1_.js",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/forester-client/forester-client-1562341213._V1_.js",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/uk-site-wide-css-beacon/site-wide-6146007985._V1_.css",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/page-ajax/page-ajax-50348029._V1_.js",
      "http://z-ecx.images-amazon.com/images/G/01/browser-scripts/search-ajax/search-ajax-2728037230._V1_.js"
    ]);
  }
}();
</script>











 
<script type="text/javascript">
if ( window.amznJQ && amznJQ.addPL ) {
	amznJQ.addPL(["https://images-na.ssl-images-amazon.com/images/G/02/gno/images/general/navAmazonLogoFooter._V152929188_.gif","https://images-na.ssl-images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png","https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/transparent-pixel._V167145160_.gif","https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/ya/images/shipment_large_lt._V192238984_.gif","https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/ya/images/new-link._V192238985_.gif","https://images-na.ssl-images-amazon.com/images/G/02/x-locale/cs/help/images/spotlight/kindle-family-02b._V160654766_.jpg","https://images-na.ssl-images-amazon.com/images/G/01/x-locale/cs/css/images/amznbtn-sprite03._V387356454_.png","https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/site-wide-js-1.2.6-beacon/site-wide-11366246298._V1_.js","https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/uk-site-wide-css-beacon/site-wide-6146007985._V1_.css","https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/wcs-ya-homepage-beaconized/wcs-ya-homepage-beaconized-322195074._V1_.css"]);
}
</script>

    

        



<script type="text/javascript">
amznJQ.available("jQuery", function() {
  jQuery(window).load(function() { setTimeout(function() {
    var imageAssets = new Array();
    var jsCssAssets = new Array();
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/buy-buttons/review-1-click-order._V192198599_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/buttons/continue-shopping._V192188120_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/buy-buttons/thank-you-elbow._V192198531_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/x-locale/communities/social/snwicons_v2._V402336182_.png");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/checkout/assets/carrot._V192253931_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/checkout/thank-you-page/assets/yellow-rounded-corner-sprite._V192253922_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/checkout/thank-you-page/assets/white-rounded-corner-sprite._V212531240_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/gno/beacon/BeaconSprite-UK-02._V397961423_.png");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/G/02/x-locale/common/transparent-pixel._V167145160_.gif");
      imageAssets.push("https://images-na.ssl-images-amazon.com/images/I/41JpsttW8CL._SX35_.jpg");
      jsCssAssets.push("https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/site-wide-js-1.2.6-beacon/site-wide-11366246298._V1_.js");
      jsCssAssets.push("https://images-na.ssl-images-amazon.com/images/G/01/browser-scripts/uk-site-wide-css-beacon/site-wide-6146007985._V1_.css");

    // pre-fetching image assets
    for (var i=0; i<imageAssets.length; i++) {
       new Image().src = imageAssets[i];
    }
    // pre-fetching css and js assets based on different browser types
    var isIE = /*@cc_on!@*/0;
    var isFireFox = /Firefox/.test(navigator.userAgent);
    if (isIE) {
      for (var i=0; i<jsCssAssets.length; i++) {
        new Image().src = jsCssAssets[i];
      }
    }
    else if (isFireFox) {
      for (var i=0; i<jsCssAssets.length; i++) {
        var o =  document.createElement("object");
        o.data = jsCssAssets[i];
        o.width = o.height = 0;
        document.body.appendChild(o);
      }
    }
  }, 2000); });
});
</script>

<input type="hidden" name="1click-tsdelta" id="1click-tsdelta">
<script type="text/javascript">
var ocInitTimestamp = 1358413558;
amznJQ.onCompletion("amznJQ.criticalFeature", function() {
  amznJQ.available("jQuery", function() {
    jQuery.ajax({
      url: 'http://z-ecx.images-amazon.com/images/G/02/orderApplication/javascript/pipeline/201201041713-ocd._V394759231_.js',
      dataType: 'script',
      cache: true
    }); 
  });
});
</script>








</div>
<div id="be" style="display:none;visibility:hidden;"><form name="ue_backdetect"><input name="ue_back" value="2" type="hidden"></form><script type="text/javascript">
(function(a){if(document.ue_backdetect&&document.ue_backdetect.ue_back){a.ue.bfini=document.ue_backdetect.ue_back.value}if(a.uet){a.uet("be")}if(a.onLdEnd){if(window.addEventListener){window.addEventListener("load",a.onLdEnd,false)}else{if(window.attachEvent){window.attachEvent("onload",a.onLdEnd)}}}if(a.ueh){a.ueh(0,window,"load",a.onLd,1)}if(a.ue_pr&&(a.ue_pr==3||a.ue_pr==4)){a.ue._uep()}})(ue_csm);
</script>


<noscript>&lt;img src='/gp/uedata/277-6643056-3126939?noscript&amp;amp;id=0KGHD1WV7T4KNAQMVBGQ' /&gt;</noscript></div>
<script type="text/javascript">
(function(a){a._uec=function(d){var h=window,b=h.performance,f=b?b.navigation.type:0;if(f==0){var e="; expires="+new Date(+new Date+604800000).toGMTString(),c=+new Date-ue_t0;if(c>0){var g=a.ue_tsinc?"|"+ +new Date:"|";document.cookie="csm-hit="+(d/c).toFixed(2)+g+e+"; path=/"}}}})(ue_csm);
_uec(517023);
</script>



            
      













<embed type="application/x-unity-webapps-npapi" id="unityChromiumExtensionId" height="0" width="0" style="display: block !important;"></body></html>
