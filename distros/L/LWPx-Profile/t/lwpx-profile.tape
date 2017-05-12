use HTTP::Response;
use HTTP::Request;
$VAR1 = [
          {
            'response' => bless( {
                                   '_msg' => 'OK',
                                   '_headers' => bless( {
                                                          'accept-ranges' => 'none',
                                                          'client-peer' => '74.125.225.16:80',
                                                          'alternate-protocol' => '80:quic,p=0.08',
                                                          'vary' => 'Accept-Encoding',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'content-type' => 'text/html; charset=ISO-8859-1',
                                                          'client-response-num' => 1,
                                                          'expires' => '-1',
                                                          'x-meta-description' => 'Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for.',
                                                          'title' => 'Google',
                                                          '::std_case' => {
                                                                            'x-meta-robots' => 'X-Meta-Robots',
                                                                            'alternate-protocol' => 'Alternate-Protocol',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'x-frame-options' => 'X-Frame-Options',
                                                                            'x-xss-protection' => 'X-XSS-Protection',
                                                                            'title' => 'Title',
                                                                            'set-cookie' => 'Set-Cookie',
                                                                            'p3p' => 'P3P',
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date'
                                                                          },
                                                          'x-xss-protection' => '1; mode=block',
                                                          'x-frame-options' => 'SAMEORIGIN',
                                                          'server' => 'gws',
                                                          'cache-control' => 'private, max-age=0',
                                                          'x-meta-robots' => 'noodp',
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'connection' => 'close',
                                                          'set-cookie' => [
                                                                            'PREF=ID=5253d9fe7190ed45:FF=0:TM=1424358595:LM=1424358595:S=wcoGj7FLBp2xF6Fw; expires=Sat, 18-Feb-2017 15:09:55 GMT; path=/; domain=.google.com',
                                                                            'NID=67=HNrJEEownufs9hmON7a6Wh3V0VzmXB1I5iKQohRLwBpYvcgCj-ulcZjc-qA28C3M4tM0Ox-_unnRXz-uhYPU7CCWIz2UojFo-Ne8Rmf711C4ZgosAaYciIZn7yD2QdMb; expires=Fri, 21-Aug-2015 15:09:55 GMT; path=/; domain=.google.com; HttpOnly'
                                                                          ],
                                                          'p3p' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."'
                                                        }, 'HTTP::Headers' ),
                                   '_request' => bless( {
                                                          '_uri' => bless( do{\(my $o = 'http://www.google.com/')}, 'URI::http' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_method' => 'GET'
                                                        }, 'HTTP::Request' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_rc' => '200',
                                   '_content' => '<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for." name="description"><meta content="noodp" name="robots"><meta content="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" itemprop="image"><title>Google</title><script>(function(){window.google={kEI:\'w_zlVNHyFoWbyASt_YKoDQ\',kEXPI:\'4011559,4020347,4020562,4020726,4021598,4023678,4024600,4026109,4026240,4026473,4028366,4028650,4028717,4029141,4029155,4029373,4029515,4029737,8500394,8500851,10200083,10200909,10200958\',authuser:0,kSID:\'w_zlVNHyFoWbyASt_YKoDQ\'};google.kHL=\'en\';})();(function(){google.lc=[];google.li=0;google.getEI=function(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||google.kEI};google.getLEI=function(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b};google.https=function(){return"https:"==window.location.protocol};google.ml=function(){};google.time=function(){return(new Date).getTime()};google.log=function(a,b,e,f,l){var d=new Image,h=google.lc,g=google.li,c="",m=google.ls||"";d.onerror=d.onload=d.onabort=function(){delete h[g]};h[g]=d;if(!e&&-1==b.search("&ei=")){var k=google.getEI(f),c="&ei="+k;-1==b.search("&lei=")&&((f=google.getLEI(f))?c+="&lei="+f:k!=google.kEI&&(c+="&lei="+google.kEI))}a=e||"/"+(l||"gen_204")+"?atyp=i&ct="+a+"&cad="+b+c+m+"&zx="+google.time();/^http:/i.test(a)&&google.https()?(google.ml(Error("a"),!1,{src:a,glmm:1}),delete h[g]):(d.src=a,google.li=g+1)};google.y={};google.x=function(a,b){google.y[a.id]=[a,b];return!1};google.load=function(a,b,e){google.x({id:a+n++},function(){google.load(a,b,e)})};var n=0;})();google.kCSI={};var _gjwl=location;function _gjuc(){var a=_gjwl.href.indexOf("#");if(0<=a&&(a=_gjwl.href.substring(a),0<a.indexOf("&q=")||0<=a.indexOf("#q="))&&(a=a.substring(1),-1==a.indexOf("#"))){for(var d=0;d<a.length;){var b=d;"&"==a.charAt(b)&&++b;var c=a.indexOf("&",b);-1==c&&(c=a.length);b=a.substring(b,c);if(0==b.indexOf("fp="))a=a.substring(0,d)+a.substring(c,a.length),c=d;else if("cad=h"==b)return 0;d=c}_gjwl.href="/search?"+a+"&cad=h";return 1}return 0}
function _gjh(){!_gjuc()&&window.google&&google.x&&google.x({id:"GJH"},function(){google.nav&&google.nav.gjh&&google.nav.gjh()})};window._gjh&&_gjh();</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}</style><style>body,td,a,p,.h{font-family:arial,sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#36c}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px arial,sans-serif}.gsfs{font:17px arial,sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:black}a{color:#11c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#36c}a:visited{color:#551a8b}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff !important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#eee;border:solid 1px;border-color:#ccc #999 #999 #ccc;height:30px}.lsbb{display:block}.ftl,#fll a{display:inline-block;margin:0 12px}.lsb{background:url(/images/srpr/nav_logo80.png) 0 -258px repeat-x;border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lsb:active{background:#ccc}.lst:focus{outline:none}</style><script></script></head><body bgcolor="#fff"><script>(function(){var src=\'/images/nav_logo176.png\';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
}
})();</script><div id="mngb">   <div id=gbar><nobr><b class=gb1>Search</b> <a class=gb1 href="http://www.google.com/imghp?hl=en&tab=wi">Images</a> <a class=gb1 href="http://maps.google.com/maps?hl=en&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=en&tab=w8">Play</a> <a class=gb1 href="http://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="http://news.google.com/nwshp?hl=en&tab=wn">News</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="http://www.google.com/intl/en/options/"><u>More</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com/history/optout?hl=en" class=gb4>Web History</a> | <a  href="/preferences?hl=en" class=gb4>Settings</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=en&continue=http://www.google.com/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div>  </div><center><span id="prt" style="display:block"> <div><style>.pmoabs{background-color:#fff;border:1px solid #E5E5E5;color:#666;font-size:13px;padding-bottom:20px;position:absolute;right:2px;top:3px;z-index:986}#pmolnk{border-radius:2px;-moz-border-radius:2px;-webkit-border-radius:2px}.kd-button-submit{border:1px solid #3079ed;background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#4787ed\')}.kd-button-submit:hover{border:1px solid #2f5bb7;background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#357ae8\')}.kd-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}#pmolnk a{color:#fff;display:inline-block;font-weight:bold;padding:5px 20px;text-decoration:none;white-space:nowrap}.xbtn{color:#999;cursor:pointer;font-size:23px;line-height:5px;padding-top:5px}.padi{padding:0 8px 0 10px}.padt{padding:5px 20px 0 0;color:#444}.pads{text-align:left;max-width:200px}</style> <div class="pmoabs" id="pmocntr2" style="behavior:url(#default#userdata);display:none"> <table border="0"> <tr> <td colspan="2"> <div class="xbtn" onclick="google.promos&&google.promos.toast&& google.promos.toast.cpc()" style="float:right">&times;</div> </td> </tr> <tr> <td class="padi" rowspan="2"> <img src="/images/icons/product/chrome-48.png"> </td> <td class="pads">A faster way to browse the web</td> </tr> <tr> <td class="padt"> <div class="kd-button-submit" id="pmolnk"> <a href="/chrome/index.html?hl=en&amp;brand=CHNG&amp;utm_source=en-hpp&amp;utm_medium=hpp&amp;utm_campaign=en" onclick="google.promos&&google.promos.toast&& google.promos.toast.cl()">Install Google Chrome</a> </div> </td> </tr> </table> </div> <script type="text/javascript">(function(){var a={o:{}};a.o.qa=50;a.o.oa=10;a.o.Y="body";a.o.Oa=!0;a.o.Ra=function(b,c){var d=a.o.Ea();a.o.Ga(d,b,c);a.o.Sa(d);a.o.Oa&&a.o.Pa(d)};a.o.Sa=function(b){(b=a.o.$(b))&&0<b.forms.length&&b.forms[0].submit()};a.o.Ea=function(){var b=document.createElement("iframe");b.height=0;b.width=0;b.style.overflow="hidden";b.style.top=b.style.left="-100px";b.style.position="absolute";document.body.appendChild(b);return b};a.o.$=function(b){return b.contentDocument||b.contentWindow.document};a.o.Ga=function(b,c,d){b=a.o.$(b);b.open();d=["<",a.o.Y,\'><form method=POST action="\',d,\'">\'];for(var e in c)c.hasOwnProperty(e)&&d.push(\'<textarea name="\',e,\'">\',c[e],"</textarea>");d.push("</form></",a.o.Y,">");b.write(d.join(""));b.close()};a.o.ba=function(b,c){c>a.o.oa?google&&google.ml&&google.ml(Error("ogcdr"),!1,{cause:"timeout"}):b.contentWindow?a.o.Qa(b):window.setTimeout(function(){a.o.ba(b,c+1)},a.o.qa)};a.o.Qa=function(b){document.body.removeChild(b)};a.o.Pa=function(b){a.o.Ca(b,"load",function(){a.o.ba(b,0)})};a.o.Ca=function(b,c,d){b.addEventListener?b.addEventListener(c,d,!1):b.attachEvent&&b.attachEvent("on"+c,d)};var m={Va:0,D:1,F:2,K:5};a.k={};a.k.M={ka:"i",J:"d",ma:"l"};a.k.A={N:"0",G:"1"};a.k.O={L:1,J:2,I:3};a.k.v={ea:"a",ia:"g",C:"c",ya:"u",xa:"t",N:"p",pa:"pid",ga:"eid",za:"at"};a.k.la=window.location.protocol+"//www.google.com/_/og/promos/";a.k.ha="g";a.k.Aa="z";a.k.S=function(b,c,d,e){var f=null;switch(c){case m.D:f=window.gbar.up.gpd(b,d,!0);break;case m.K:f=window.gbar.up.gcc(e)}return null==f?0:parseInt(f,10)};a.k.Ka=function(b,c,d){return c==m.D?null!=window.gbar.up.gpd(b,d,!0):!1};a.k.P=function(b,c,d,e,f,h,k,l){var g={};g[a.k.v.N]=b;g[a.k.v.ia]=c;g[a.k.v.ea]=d;g[a.k.v.za]=e;g[a.k.v.ga]=f;g[a.k.v.pa]=1;k&&(g[a.k.v.C]=k);l&&(g[a.k.v.ya]=l);if(h)g[a.k.v.xa]=h;else return google.ml(Error("knu"),!1,{cause:"Token is not found"}),null;return g};a.k.V=function(b,c,d){if(b){var e=c?a.k.ha:a.k.Aa;c&&d&&(e+="?authuser="+d);a.o.Ra(b,a.k.la+e)}};a.k.Fa=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.J,a.k.O.J,d,f,null,e);a.k.V(b,h,k)};a.k.Ia=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.ka,a.k.O.L,d,f,e,null);a.k.V(b,h,k)};a.k.Na=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.dpc(e,f);break;case m.D:window.gbar.up.spd(b,d,1,!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.G,n=n||0,a.k.Fa(e,h,k,f,l,g,n)}};a.k.La=function(b,c,d,e,f){return c==m.D?0<d&&a.k.S(b,c,e,f)>=d:!1};a.k.Ha=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.iic(e,f);break;case m.D:c=a.k.S(b,c,d,e)+1;window.gbar.up.spd(b,d,c.toString(),!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.N,n=n||0,a.k.Ia(e,h,k,1,l,g,n)}};a.k.Ma=function(b,c,d,e,f,h){b=a.k.P(c,b,a.k.M.ma,a.k.O.I,d,e,null,null);a.k.V(b,f,h)};var p={Ta:"a",Wa:"l",Ua:"c",fa:"d",I:"h",L:"i",gb:"n",G:"x",cb:"ma",eb:"mc",fb:"mi",Xa:"pa",Ya:"pc",$a:"pi",bb:"pn",ab:"px",Za:"pd",hb:"gpa",jb:"gpi",kb:"gpn",lb:"gpx",ib:"gpd"};a.i={};a.i.s={na:"hplogo",wa:"pmocntr2"};a.i.A={va:"0",G:"1",da:"2"};a.i.p=document.getElementById(a.i.s.wa);a.i.ja=16;a.i.ra=2;a.i.ta=20;google.promos=google.promos||{};google.promos.toast=google.promos.toast||{};a.i.H=function(b){a.i.p&&(a.i.p.style.display=b?"":"none",a.i.p.parentNode&&(a.i.p.parentNode.style.position=b?"relative":""))};a.i.ca=function(b){try{if(a.i.p&&b&&b.es&&b.es.m){var c=window.gbar.rtl(document.body)?"left":"right";a.i.p.style[c]=b.es.m-a.i.ja+a.i.ra+"px";a.i.p.style.top=a.i.ta+"px"}}catch(d){google.ml(d,!1,{cause:a.i.w+"_PT"})}};google.promos.toast.cl=function(){try{a.i.Q==m.F&&a.k.Ma(a.i.T,a.i.B,a.i.A.da,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.I,a.i.R(),1)}catch(b){google.ml(b,!1,{cause:a.i.w+"_CL"})}};google.promos.toast.cpc=function(){try{a.i.p&&(a.i.H(!1),a.k.Na(a.i.p,a.i.Q,a.i.s.Z,a.i.T,a.i.Da,a.i.B,a.i.A.G,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.fa,a.i.R(),1))}catch(b){google.ml(b,!1,{cause:a.i.w+"_CPC"})}};a.i.aa=function(){try{if(a.i.p){var b=276,c=document.getElementById(a.i.s.na);c&&(b=Math.max(b,c.offsetWidth));var d=parseInt(a.i.p.style.right,10)||0;a.i.p.style.visibility=2*(a.i.p.offsetWidth+d)+b>document.body.clientWidth?"hidden":""}}catch(e){google.ml(e,!1,{cause:a.i.w+"_HOSW"})}};a.i.Ba=function(){var b=["gpd","spd","aeh","sl"];if(!window.gbar||!window.gbar.up)return!1;for(var c=0,d;d=b[c];c++)if(!(d in window.gbar.up))return!1;return!0};a.i.Ja=function(){return a.i.p.currentStyle&&"absolute"!=a.i.p.currentStyle.position};google.promos.toast.init=function(b,c,d,e,f,h,k,l,g,n,q,r){try{a.i.Ba()?a.i.p&&(e==m.F&&!l==!g?(google.ml(Error("tku"),!1,{cause:"zwieback: "+g+", gaia: "+l}),a.i.H(!1)):(a.i.s.C="toast_count_"+c+(q?"_"+q:""),a.i.s.Z="toast_dp_"+c+(r?"_"+r:""),a.i.w=d,a.i.B=b,a.i.Q=e,a.i.T=c,a.i.Da=f,a.i.X=l?l:g,a.i.U=!!l,a.i.W=k,a.k.Ka(a.i.p,e,a.i.s.Z,c)||a.k.La(a.i.p,e,h,a.i.s.C,c)||a.i.Ja()?a.i.H(!1):(a.k.Ha(a.i.p,e,a.i.s.C,c,f,a.i.B,a.i.A.va,a.i.X,a.i.U,a.i.W),n||(window.gbar.up.aeh(window,"resize",a.i.aa),window.lol=
a.i.aa,window.gbar.elr&&a.i.ca(window.gbar.elr()),window.gbar.elc&&window.gbar.elc(a.i.ca),a.i.H(!0)),window.gbar.up.sl(a.i.B,a.i.w,p.L,a.i.R())))):google.ml(Error("apa"),!1,{cause:a.i.w+"_INIT"})}catch(t){google.ml(t,!1,{cause:a.i.w+"_INIT"})}};a.i.R=function(){var b=a.k.S(a.i.p,a.i.Q,a.i.s.C,a.i.T);return"ic="+b};})();</script> <script type="text/javascript">(function(){var sourceWebappPromoID=144002;var sourceWebappGroupID=5;var payloadType=5;var cookieMaxAgeSec=2592000;var dismissalType=5;var impressionCap=25;var gaiaXsrfToken=\'\';var zwbkXsrfToken=\'\';var kansasDismissalEnabled=false;var sessionIndex=0;var invisible=false;window.gbar&&gbar.up&&gbar.up.r&&gbar.up.r(payloadType,function(show){if (show){google.promos.toast.init(sourceWebappPromoID,sourceWebappGroupID,payloadType,dismissalType,cookieMaxAgeSec,impressionCap,sessionIndex,gaiaXsrfToken,zwbkXsrfToken,invisible,\'0612\');}
});})();</script> </div> </span><br clear="all" id="lgpd"><div id="lga"><a href="/search?site=&amp;ie=UTF-8&amp;q=Lunar+New+Year&amp;oi=ddle&amp;ct=lunar-new-year-2015-5753824463552512-hp&amp;hl=en&amp;sa=X&amp;ei=w_zlVNHyFoWbyASt_YKoDQ&amp;ved=0CAMQNg"><img alt="Lunar New Year 2015" border="0" height="200" src="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" title="Lunar New Year 2015" width="500" id="hplogo" onload="window.lol&&lol()"><br></a><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="en" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><div class="ds" style="height:32px;margin:4px 0"><input style="color:#000;margin:0;padding:5px 8px 0 6px;vertical-align:top" autocomplete="off" class="lst" value="" title="Google Search" maxlength="2048" name="q" size="57"></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" value="I\'m Feeling Lucky" name="btnI" onclick="if(this.form.q.value)this.checked=1; else top.location=\'/doodles/\'" type="submit"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=en&amp;authuser=0">Advanced search</a><a href="/language_tools?hl=en&amp;authuser=0">Language tools</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"></form><div id="gac_scont"></div><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="fll"><a href="/intl/en/ads/">Advertising&nbsp;Programs</a><a href="/services/">Business Solutions</a><a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google</a><a href="/intl/en/about.html">About Google</a></div></div><p style="color:#767676;font-size:8pt">&copy; 2015 - <a href="/intl/en/policies/privacy/">Privacy</a> - <a href="/intl/en/policies/terms/">Terms</a></p></span></center><div id="xjsd"></div><div id="xjsi" data-jiis="bp"><script>(function(){function c(b){window.setTimeout(function(){var a=document.createElement("script");a.src=b;document.getElementById("xjsd").appendChild(a)},0)}google.dljp=function(b,a){google.xjsu=b;c(a)};google.dlj=c;})();(function(){window.google.xjsrm=[];})();if(google.y)google.y.first=[];if(!google.xjs){window._=window._||{};window._._DumpException=function(e){throw e};if(google.timers&&google.timers.load.t){google.timers.load.t.xjsls=new Date().getTime();}google.dljp(\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\',\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\');google.xjs=1;}google.pmc={"sb_he":{"agen":true,"cgen":true,"client":"heirloom-hp","dh":true,"ds":"","exp":"msedr","fl":true,"host":"google.com","jam":0,"jsonp":true,"msgs":{"cibl":"Clear Search","dym":"Did you mean:","lcky":"I\\u0026#39;m Feeling Lucky","lml":"Learn more","oskt":"Input tools","psrc":"This search was removed from your \\u003Ca href=\\"/history\\"\\u003EWeb History\\u003C/a\\u003E","psrl":"Remove","sbit":"Search by image","srch":"Google Search"},"ovr":{},"pq":"","refoq":true,"scd":10,"sce":5,"stok":"KQyI_EZbgtzI5GTIJDD0ZSNgC_Y"},"d":{}};google.y.first.push(function(){if(google.med){google.med(\'init\');google.initHistory();google.med(\'history\');}});if(google.j&&google.j.en&&google.j.xi){window.setTimeout(google.j.xi,0);}
</script></div></body></html>'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_request' => bless( {
                                                          '_uri_canonical' => bless( do{\(my $o = 'http://www.google.com/')}, 'URI::http' ),
                                                          '_method' => 'GET',
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for." name="description"><meta content="noodp" name="robots"><meta content="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" itemprop="image"><title>Google</title><script>(function(){window.google={kEI:\'w_zlVLWaHpejyASqsoKgDQ\',kEXPI:\'2032608,4011009,4014789,4017578,4020560,4020726,4021587,4021598,4025827,4027919,4028649,4028716,4029135,4029141,4029155,4029466,4029737,8500393,8500572,8500852,8500973,8501082,10200083,10200909\',authuser:0,kSID:\'w_zlVLWaHpejyASqsoKgDQ\'};google.kHL=\'en\';})();(function(){google.lc=[];google.li=0;google.getEI=function(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||google.kEI};google.getLEI=function(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b};google.https=function(){return"https:"==window.location.protocol};google.ml=function(){};google.time=function(){return(new Date).getTime()};google.log=function(a,b,e,f,l){var d=new Image,h=google.lc,g=google.li,c="",m=google.ls||"";d.onerror=d.onload=d.onabort=function(){delete h[g]};h[g]=d;if(!e&&-1==b.search("&ei=")){var k=google.getEI(f),c="&ei="+k;-1==b.search("&lei=")&&((f=google.getLEI(f))?c+="&lei="+f:k!=google.kEI&&(c+="&lei="+google.kEI))}a=e||"/"+(l||"gen_204")+"?atyp=i&ct="+a+"&cad="+b+c+m+"&zx="+google.time();/^http:/i.test(a)&&google.https()?(google.ml(Error("a"),!1,{src:a,glmm:1}),delete h[g]):(d.src=a,google.li=g+1)};google.y={};google.x=function(a,b){google.y[a.id]=[a,b];return!1};google.load=function(a,b,e){google.x({id:a+n++},function(){google.load(a,b,e)})};var n=0;})();google.kCSI={};var _gjwl=location;function _gjuc(){var a=_gjwl.href.indexOf("#");if(0<=a&&(a=_gjwl.href.substring(a),0<a.indexOf("&q=")||0<=a.indexOf("#q="))&&(a=a.substring(1),-1==a.indexOf("#"))){for(var d=0;d<a.length;){var b=d;"&"==a.charAt(b)&&++b;var c=a.indexOf("&",b);-1==c&&(c=a.length);b=a.substring(b,c);if(0==b.indexOf("fp="))a=a.substring(0,d)+a.substring(c,a.length),c=d;else if("cad=h"==b)return 0;d=c}_gjwl.href="/search?"+a+"&cad=h";return 1}return 0}
function _gjh(){!_gjuc()&&window.google&&google.x&&google.x({id:"GJH"},function(){google.nav&&google.nav.gjh&&google.nav.gjh()})};window._gjh&&_gjh();</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}</style><style>body,td,a,p,.h{font-family:arial,sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#36c}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px arial,sans-serif}.gsfs{font:17px arial,sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:black}a{color:#11c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#36c}a:visited{color:#551a8b}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff !important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#eee;border:solid 1px;border-color:#ccc #999 #999 #ccc;height:30px}.lsbb{display:block}.ftl,#fll a{display:inline-block;margin:0 12px}.lsb{background:url(/images/srpr/nav_logo80.png) 0 -258px repeat-x;border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lsb:active{background:#ccc}.lst:focus{outline:none}</style><script></script></head><body bgcolor="#fff"><script>(function(){var src=\'/images/nav_logo176.png\';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
}
})();</script><div id="mngb">   <div id=gbar><nobr><b class=gb1>Search</b> <a class=gb1 href="http://www.google.com/imghp?hl=en&tab=wi">Images</a> <a class=gb1 href="http://maps.google.com/maps?hl=en&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=en&tab=w8">Play</a> <a class=gb1 href="http://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="http://news.google.com/nwshp?hl=en&tab=wn">News</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="http://www.google.com/intl/en/options/"><u>More</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com/history/optout?hl=en" class=gb4>Web History</a> | <a  href="/preferences?hl=en" class=gb4>Settings</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=en&continue=http://www.google.com/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div>  </div><center><span id="prt" style="display:block"> <div><style>.pmoabs{background-color:#fff;border:1px solid #E5E5E5;color:#666;font-size:13px;padding-bottom:20px;position:absolute;right:2px;top:3px;z-index:986}#pmolnk{border-radius:2px;-moz-border-radius:2px;-webkit-border-radius:2px}.kd-button-submit{border:1px solid #3079ed;background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#4787ed\')}.kd-button-submit:hover{border:1px solid #2f5bb7;background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#357ae8\')}.kd-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}#pmolnk a{color:#fff;display:inline-block;font-weight:bold;padding:5px 20px;text-decoration:none;white-space:nowrap}.xbtn{color:#999;cursor:pointer;font-size:23px;line-height:5px;padding-top:5px}.padi{padding:0 8px 0 10px}.padt{padding:5px 20px 0 0;color:#444}.pads{text-align:left;max-width:200px}</style> <div class="pmoabs" id="pmocntr2" style="behavior:url(#default#userdata);display:none"> <table border="0"> <tr> <td colspan="2"> <div class="xbtn" onclick="google.promos&&google.promos.toast&& google.promos.toast.cpc()" style="float:right">&times;</div> </td> </tr> <tr> <td class="padi" rowspan="2"> <img src="/images/icons/product/chrome-48.png"> </td> <td class="pads">A faster way to browse the web</td> </tr> <tr> <td class="padt"> <div class="kd-button-submit" id="pmolnk"> <a href="/chrome/index.html?hl=en&amp;brand=CHNG&amp;utm_source=en-hpp&amp;utm_medium=hpp&amp;utm_campaign=en" onclick="google.promos&&google.promos.toast&& google.promos.toast.cl()">Install Google Chrome</a> </div> </td> </tr> </table> </div> <script type="text/javascript">(function(){var a={o:{}};a.o.qa=50;a.o.oa=10;a.o.Y="body";a.o.Oa=!0;a.o.Ra=function(b,c){var d=a.o.Ea();a.o.Ga(d,b,c);a.o.Sa(d);a.o.Oa&&a.o.Pa(d)};a.o.Sa=function(b){(b=a.o.$(b))&&0<b.forms.length&&b.forms[0].submit()};a.o.Ea=function(){var b=document.createElement("iframe");b.height=0;b.width=0;b.style.overflow="hidden";b.style.top=b.style.left="-100px";b.style.position="absolute";document.body.appendChild(b);return b};a.o.$=function(b){return b.contentDocument||b.contentWindow.document};a.o.Ga=function(b,c,d){b=a.o.$(b);b.open();d=["<",a.o.Y,\'><form method=POST action="\',d,\'">\'];for(var e in c)c.hasOwnProperty(e)&&d.push(\'<textarea name="\',e,\'">\',c[e],"</textarea>");d.push("</form></",a.o.Y,">");b.write(d.join(""));b.close()};a.o.ba=function(b,c){c>a.o.oa?google&&google.ml&&google.ml(Error("ogcdr"),!1,{cause:"timeout"}):b.contentWindow?a.o.Qa(b):window.setTimeout(function(){a.o.ba(b,c+1)},a.o.qa)};a.o.Qa=function(b){document.body.removeChild(b)};a.o.Pa=function(b){a.o.Ca(b,"load",function(){a.o.ba(b,0)})};a.o.Ca=function(b,c,d){b.addEventListener?b.addEventListener(c,d,!1):b.attachEvent&&b.attachEvent("on"+c,d)};var m={Va:0,D:1,F:2,K:5};a.k={};a.k.M={ka:"i",J:"d",ma:"l"};a.k.A={N:"0",G:"1"};a.k.O={L:1,J:2,I:3};a.k.v={ea:"a",ia:"g",C:"c",ya:"u",xa:"t",N:"p",pa:"pid",ga:"eid",za:"at"};a.k.la=window.location.protocol+"//www.google.com/_/og/promos/";a.k.ha="g";a.k.Aa="z";a.k.S=function(b,c,d,e){var f=null;switch(c){case m.D:f=window.gbar.up.gpd(b,d,!0);break;case m.K:f=window.gbar.up.gcc(e)}return null==f?0:parseInt(f,10)};a.k.Ka=function(b,c,d){return c==m.D?null!=window.gbar.up.gpd(b,d,!0):!1};a.k.P=function(b,c,d,e,f,h,k,l){var g={};g[a.k.v.N]=b;g[a.k.v.ia]=c;g[a.k.v.ea]=d;g[a.k.v.za]=e;g[a.k.v.ga]=f;g[a.k.v.pa]=1;k&&(g[a.k.v.C]=k);l&&(g[a.k.v.ya]=l);if(h)g[a.k.v.xa]=h;else return google.ml(Error("knu"),!1,{cause:"Token is not found"}),null;return g};a.k.V=function(b,c,d){if(b){var e=c?a.k.ha:a.k.Aa;c&&d&&(e+="?authuser="+d);a.o.Ra(b,a.k.la+e)}};a.k.Fa=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.J,a.k.O.J,d,f,null,e);a.k.V(b,h,k)};a.k.Ia=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.ka,a.k.O.L,d,f,e,null);a.k.V(b,h,k)};a.k.Na=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.dpc(e,f);break;case m.D:window.gbar.up.spd(b,d,1,!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.G,n=n||0,a.k.Fa(e,h,k,f,l,g,n)}};a.k.La=function(b,c,d,e,f){return c==m.D?0<d&&a.k.S(b,c,e,f)>=d:!1};a.k.Ha=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.iic(e,f);break;case m.D:c=a.k.S(b,c,d,e)+1;window.gbar.up.spd(b,d,c.toString(),!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.N,n=n||0,a.k.Ia(e,h,k,1,l,g,n)}};a.k.Ma=function(b,c,d,e,f,h){b=a.k.P(c,b,a.k.M.ma,a.k.O.I,d,e,null,null);a.k.V(b,f,h)};var p={Ta:"a",Wa:"l",Ua:"c",fa:"d",I:"h",L:"i",gb:"n",G:"x",cb:"ma",eb:"mc",fb:"mi",Xa:"pa",Ya:"pc",$a:"pi",bb:"pn",ab:"px",Za:"pd",hb:"gpa",jb:"gpi",kb:"gpn",lb:"gpx",ib:"gpd"};a.i={};a.i.s={na:"hplogo",wa:"pmocntr2"};a.i.A={va:"0",G:"1",da:"2"};a.i.p=document.getElementById(a.i.s.wa);a.i.ja=16;a.i.ra=2;a.i.ta=20;google.promos=google.promos||{};google.promos.toast=google.promos.toast||{};a.i.H=function(b){a.i.p&&(a.i.p.style.display=b?"":"none",a.i.p.parentNode&&(a.i.p.parentNode.style.position=b?"relative":""))};a.i.ca=function(b){try{if(a.i.p&&b&&b.es&&b.es.m){var c=window.gbar.rtl(document.body)?"left":"right";a.i.p.style[c]=b.es.m-a.i.ja+a.i.ra+"px";a.i.p.style.top=a.i.ta+"px"}}catch(d){google.ml(d,!1,{cause:a.i.w+"_PT"})}};google.promos.toast.cl=function(){try{a.i.Q==m.F&&a.k.Ma(a.i.T,a.i.B,a.i.A.da,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.I,a.i.R(),1)}catch(b){google.ml(b,!1,{cause:a.i.w+"_CL"})}};google.promos.toast.cpc=function(){try{a.i.p&&(a.i.H(!1),a.k.Na(a.i.p,a.i.Q,a.i.s.Z,a.i.T,a.i.Da,a.i.B,a.i.A.G,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.fa,a.i.R(),1))}catch(b){google.ml(b,!1,{cause:a.i.w+"_CPC"})}};a.i.aa=function(){try{if(a.i.p){var b=276,c=document.getElementById(a.i.s.na);c&&(b=Math.max(b,c.offsetWidth));var d=parseInt(a.i.p.style.right,10)||0;a.i.p.style.visibility=2*(a.i.p.offsetWidth+d)+b>document.body.clientWidth?"hidden":""}}catch(e){google.ml(e,!1,{cause:a.i.w+"_HOSW"})}};a.i.Ba=function(){var b=["gpd","spd","aeh","sl"];if(!window.gbar||!window.gbar.up)return!1;for(var c=0,d;d=b[c];c++)if(!(d in window.gbar.up))return!1;return!0};a.i.Ja=function(){return a.i.p.currentStyle&&"absolute"!=a.i.p.currentStyle.position};google.promos.toast.init=function(b,c,d,e,f,h,k,l,g,n,q,r){try{a.i.Ba()?a.i.p&&(e==m.F&&!l==!g?(google.ml(Error("tku"),!1,{cause:"zwieback: "+g+", gaia: "+l}),a.i.H(!1)):(a.i.s.C="toast_count_"+c+(q?"_"+q:""),a.i.s.Z="toast_dp_"+c+(r?"_"+r:""),a.i.w=d,a.i.B=b,a.i.Q=e,a.i.T=c,a.i.Da=f,a.i.X=l?l:g,a.i.U=!!l,a.i.W=k,a.k.Ka(a.i.p,e,a.i.s.Z,c)||a.k.La(a.i.p,e,h,a.i.s.C,c)||a.i.Ja()?a.i.H(!1):(a.k.Ha(a.i.p,e,a.i.s.C,c,f,a.i.B,a.i.A.va,a.i.X,a.i.U,a.i.W),n||(window.gbar.up.aeh(window,"resize",a.i.aa),window.lol=
a.i.aa,window.gbar.elr&&a.i.ca(window.gbar.elr()),window.gbar.elc&&window.gbar.elc(a.i.ca),a.i.H(!0)),window.gbar.up.sl(a.i.B,a.i.w,p.L,a.i.R())))):google.ml(Error("apa"),!1,{cause:a.i.w+"_INIT"})}catch(t){google.ml(t,!1,{cause:a.i.w+"_INIT"})}};a.i.R=function(){var b=a.k.S(a.i.p,a.i.Q,a.i.s.C,a.i.T);return"ic="+b};})();</script> <script type="text/javascript">(function(){var sourceWebappPromoID=144002;var sourceWebappGroupID=5;var payloadType=5;var cookieMaxAgeSec=2592000;var dismissalType=5;var impressionCap=25;var gaiaXsrfToken=\'\';var zwbkXsrfToken=\'\';var kansasDismissalEnabled=false;var sessionIndex=0;var invisible=false;window.gbar&&gbar.up&&gbar.up.r&&gbar.up.r(payloadType,function(show){if (show){google.promos.toast.init(sourceWebappPromoID,sourceWebappGroupID,payloadType,dismissalType,cookieMaxAgeSec,impressionCap,sessionIndex,gaiaXsrfToken,zwbkXsrfToken,invisible,\'0612\');}
});})();</script> </div> </span><br clear="all" id="lgpd"><div id="lga"><a href="/search?site=&amp;ie=UTF-8&amp;q=Lunar+New+Year&amp;oi=ddle&amp;ct=lunar-new-year-2015-5753824463552512-hp&amp;hl=en&amp;sa=X&amp;ei=w_zlVLWaHpejyASqsoKgDQ&amp;ved=0CAMQNg"><img alt="Lunar New Year 2015" border="0" height="200" src="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" title="Lunar New Year 2015" width="500" id="hplogo" onload="window.lol&&lol()"><br></a><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="en" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><div class="ds" style="height:32px;margin:4px 0"><input style="color:#000;margin:0;padding:5px 8px 0 6px;vertical-align:top" autocomplete="off" class="lst" value="" title="Google Search" maxlength="2048" name="q" size="57"></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" value="I\'m Feeling Lucky" name="btnI" onclick="if(this.form.q.value)this.checked=1; else top.location=\'/doodles/\'" type="submit"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=en&amp;authuser=0">Advanced search</a><a href="/language_tools?hl=en&amp;authuser=0">Language tools</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"></form><div id="gac_scont"></div><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="fll"><a href="/intl/en/ads/">Advertising&nbsp;Programs</a><a href="/services/">Business Solutions</a><a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google</a><a href="/intl/en/about.html">About Google</a></div></div><p style="color:#767676;font-size:8pt">&copy; 2015 - <a href="/intl/en/policies/privacy/">Privacy</a> - <a href="/intl/en/policies/terms/">Terms</a></p></span></center><div id="xjsd"></div><div id="xjsi" data-jiis="bp"><script>(function(){function c(b){window.setTimeout(function(){var a=document.createElement("script");a.src=b;document.getElementById("xjsd").appendChild(a)},0)}google.dljp=function(b,a){google.xjsu=b;c(a)};google.dlj=c;})();(function(){window.google.xjsrm=[];})();if(google.y)google.y.first=[];if(!google.xjs){window._=window._||{};window._._DumpException=function(e){throw e};if(google.timers&&google.timers.load.t){google.timers.load.t.xjsls=new Date().getTime();}google.dljp(\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\',\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\');google.xjs=1;}google.pmc={"sb_he":{"agen":true,"cgen":true,"client":"heirloom-hp","dh":true,"ds":"","exp":"msedr","fl":true,"host":"google.com","jam":0,"jsonp":true,"msgs":{"cibl":"Clear Search","dym":"Did you mean:","lcky":"I\\u0026#39;m Feeling Lucky","lml":"Learn more","oskt":"Input tools","psrc":"This search was removed from your \\u003Ca href=\\"/history\\"\\u003EWeb History\\u003C/a\\u003E","psrl":"Remove","sbit":"Search by image","srch":"Google Search"},"ovr":{},"pq":"","refoq":true,"scd":10,"sce":5,"stok":"KQyI_EZbgtzI5GTIJDD0ZSNgC_Y"},"d":{}};google.y.first.push(function(){if(google.med){google.med(\'init\');google.initHistory();google.med(\'history\');}});if(google.j&&google.j.en&&google.j.xi){window.setTimeout(google.j.xi,0);}
</script></div></body></html>',
                                   '_rc' => '200',
                                   '_headers' => bless( {
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'connection' => 'close',
                                                          'set-cookie' => [
                                                                            'PREF=ID=ca50e86810ebe65d:FF=0:TM=1424358595:LM=1424358595:S=ACPWtKI_Wm8GWoaG; expires=Sat, 18-Feb-2017 15:09:55 GMT; path=/; domain=.google.com',
                                                                            'NID=67=WaDqmhZxgDHWx5i7fg8HMS8S0V2j2xmd8vhpVeMw1OjaHvr0muf1hy6jR8GCVQpl0zH05NyIEQTyma0cdItO2-eMvmoN2adLsLEp3mKn5P3G-qhcjO2waTnHctlbXF5z; expires=Fri, 21-Aug-2015 15:09:55 GMT; path=/; domain=.google.com; HttpOnly'
                                                                          ],
                                                          'p3p' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."',
                                                          'title' => 'Google',
                                                          '::std_case' => {
                                                                            'x-xss-protection' => 'X-XSS-Protection',
                                                                            'x-frame-options' => 'X-Frame-Options',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'alternate-protocol' => 'Alternate-Protocol',
                                                                            'x-meta-robots' => 'X-Meta-Robots',
                                                                            'title' => 'Title',
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'set-cookie' => 'Set-Cookie',
                                                                            'p3p' => 'P3P',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'cache-control' => 'private, max-age=0',
                                                          'server' => 'gws',
                                                          'x-meta-robots' => 'noodp',
                                                          'x-xss-protection' => '1; mode=block',
                                                          'x-frame-options' => 'SAMEORIGIN',
                                                          'content-type' => 'text/html; charset=ISO-8859-1',
                                                          'client-response-num' => 1,
                                                          'vary' => 'Accept-Encoding',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'expires' => '-1',
                                                          'x-meta-description' => 'Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for.',
                                                          'accept-ranges' => 'none',
                                                          'client-peer' => '74.125.225.16:80',
                                                          'alternate-protocol' => '80:quic,p=0.08'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'OK'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'http://www.google.com/')}, 'URI::http' ),
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' ),
                                  '_method' => 'GET',
                                  '_uri' => do{my $o},
                                  '_content' => ''
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'x-meta-description' => 'Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for.',
                                                          'expires' => '-1',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'vary' => 'Accept-Encoding',
                                                          'client-response-num' => 1,
                                                          'content-type' => 'text/html; charset=ISO-8859-1',
                                                          'client-peer' => '74.125.225.16:80',
                                                          'alternate-protocol' => '80:quic,p=0.08',
                                                          'accept-ranges' => 'none',
                                                          'set-cookie' => [
                                                                            'PREF=ID=421e54fc3a1220ec:FF=0:TM=1424358595:LM=1424358595:S=vkkKNRlblQn2dpxq; expires=Sat, 18-Feb-2017 15:09:55 GMT; path=/; domain=.google.com',
                                                                            'NID=67=TRbSTrjT8Vc1G9RwM2uc4QIGEzG3n95yJ9v1Vw3gT6vOqg5xfJQzXE2k-uwCAbFjQw3r720IXpLFBUV67AErIVJ74c8mi8-TpNBFWZ8_TKg8itsNqG7mZGosljk_Sstz; expires=Fri, 21-Aug-2015 15:09:55 GMT; path=/; domain=.google.com; HttpOnly'
                                                                          ],
                                                          'p3p' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."',
                                                          'connection' => 'close',
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'x-xss-protection' => '1; mode=block',
                                                          'x-frame-options' => 'SAMEORIGIN',
                                                          'x-meta-robots' => 'noodp',
                                                          'cache-control' => 'private, max-age=0',
                                                          'server' => 'gws',
                                                          '::std_case' => {
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'set-cookie' => 'Set-Cookie',
                                                                            'p3p' => 'P3P',
                                                                            'title' => 'Title',
                                                                            'x-frame-options' => 'X-Frame-Options',
                                                                            'x-xss-protection' => 'X-XSS-Protection',
                                                                            'alternate-protocol' => 'Alternate-Protocol',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'x-meta-robots' => 'X-Meta-Robots'
                                                                          },
                                                          'title' => 'Google'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'OK',
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for." name="description"><meta content="noodp" name="robots"><meta content="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" itemprop="image"><title>Google</title><script>(function(){window.google={kEI:\'w_zlVL68JceiyAS15YDQCQ\',kEXPI:\'2032608,4011559,4017578,4020347,4020560,4021587,4021598,4023678,4026109,4028366,4028541,4028650,4028717,4029045,4029053,4029141,4029155,4029370,4029471,4029515,4029737,8500393,8501080,8501084,8501183,10200083,10200908\',authuser:0,kSID:\'w_zlVL68JceiyAS15YDQCQ\'};google.kHL=\'en\';})();(function(){google.lc=[];google.li=0;google.getEI=function(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||google.kEI};google.getLEI=function(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b};google.https=function(){return"https:"==window.location.protocol};google.ml=function(){};google.time=function(){return(new Date).getTime()};google.log=function(a,b,e,f,l){var d=new Image,h=google.lc,g=google.li,c="",m=google.ls||"";d.onerror=d.onload=d.onabort=function(){delete h[g]};h[g]=d;if(!e&&-1==b.search("&ei=")){var k=google.getEI(f),c="&ei="+k;-1==b.search("&lei=")&&((f=google.getLEI(f))?c+="&lei="+f:k!=google.kEI&&(c+="&lei="+google.kEI))}a=e||"/"+(l||"gen_204")+"?atyp=i&ct="+a+"&cad="+b+c+m+"&zx="+google.time();/^http:/i.test(a)&&google.https()?(google.ml(Error("a"),!1,{src:a,glmm:1}),delete h[g]):(d.src=a,google.li=g+1)};google.y={};google.x=function(a,b){google.y[a.id]=[a,b];return!1};google.load=function(a,b,e){google.x({id:a+n++},function(){google.load(a,b,e)})};var n=0;})();google.kCSI={};var _gjwl=location;function _gjuc(){var a=_gjwl.href.indexOf("#");if(0<=a&&(a=_gjwl.href.substring(a),0<a.indexOf("&q=")||0<=a.indexOf("#q="))&&(a=a.substring(1),-1==a.indexOf("#"))){for(var d=0;d<a.length;){var b=d;"&"==a.charAt(b)&&++b;var c=a.indexOf("&",b);-1==c&&(c=a.length);b=a.substring(b,c);if(0==b.indexOf("fp="))a=a.substring(0,d)+a.substring(c,a.length),c=d;else if("cad=h"==b)return 0;d=c}_gjwl.href="/search?"+a+"&cad=h";return 1}return 0}
function _gjh(){!_gjuc()&&window.google&&google.x&&google.x({id:"GJH"},function(){google.nav&&google.nav.gjh&&google.nav.gjh()})};window._gjh&&_gjh();</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}</style><style>body,td,a,p,.h{font-family:arial,sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#36c}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px arial,sans-serif}.gsfs{font:17px arial,sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:black}a{color:#11c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#36c}a:visited{color:#551a8b}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff !important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#eee;border:solid 1px;border-color:#ccc #999 #999 #ccc;height:30px}.lsbb{display:block}.ftl,#fll a{display:inline-block;margin:0 12px}.lsb{background:url(/images/srpr/nav_logo80.png) 0 -258px repeat-x;border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lsb:active{background:#ccc}.lst:focus{outline:none}</style><script></script></head><body bgcolor="#fff"><script>(function(){var src=\'/images/nav_logo176.png\';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
}
})();</script><div id="mngb">    <div id=gbar><nobr><b class=gb1>Search</b> <a class=gb1 href="http://www.google.com/imghp?hl=en&tab=wi">Images</a> <a class=gb1 href="http://maps.google.com/maps?hl=en&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=en&tab=w8">Play</a> <a class=gb1 href="http://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="http://news.google.com/nwshp?hl=en&tab=wn">News</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="http://www.google.com/intl/en/options/"><u>More</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com/history/optout?hl=en" class=gb4>Web History</a> | <a  href="/preferences?hl=en" class=gb4>Settings</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=en&continue=http://www.google.com/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div>    </div><center><span id="prt" style="display:block"> <div><style>.pmoabs{background-color:#fff;border:1px solid #E5E5E5;color:#666;font-size:13px;padding-bottom:20px;position:absolute;right:2px;top:3px;z-index:986}#pmolnk{border-radius:2px;-moz-border-radius:2px;-webkit-border-radius:2px}.kd-button-submit{border:1px solid #3079ed;background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#4787ed\')}.kd-button-submit:hover{border:1px solid #2f5bb7;background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#357ae8\')}.kd-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}#pmolnk a{color:#fff;display:inline-block;font-weight:bold;padding:5px 20px;text-decoration:none;white-space:nowrap}.xbtn{color:#999;cursor:pointer;font-size:23px;line-height:5px;padding-top:5px}.padi{padding:0 8px 0 10px}.padt{padding:5px 20px 0 0;color:#444}.pads{text-align:left;max-width:200px}</style> <div class="pmoabs" id="pmocntr2" style="behavior:url(#default#userdata);display:none"> <table border="0"> <tr> <td colspan="2"> <div class="xbtn" onclick="google.promos&&google.promos.toast&& google.promos.toast.cpc()" style="float:right">&times;</div> </td> </tr> <tr> <td class="padi" rowspan="2"> <img src="/images/icons/product/chrome-48.png"> </td> <td class="pads">A faster way to browse the web</td> </tr> <tr> <td class="padt"> <div class="kd-button-submit" id="pmolnk"> <a href="/chrome/index.html?hl=en&amp;brand=CHNG&amp;utm_source=en-hpp&amp;utm_medium=hpp&amp;utm_campaign=en" onclick="google.promos&&google.promos.toast&& google.promos.toast.cl()">Install Google Chrome</a> </div> </td> </tr> </table> </div> <script type="text/javascript">(function(){var a={o:{}};a.o.qa=50;a.o.oa=10;a.o.Y="body";a.o.Oa=!0;a.o.Ra=function(b,c){var d=a.o.Ea();a.o.Ga(d,b,c);a.o.Sa(d);a.o.Oa&&a.o.Pa(d)};a.o.Sa=function(b){(b=a.o.$(b))&&0<b.forms.length&&b.forms[0].submit()};a.o.Ea=function(){var b=document.createElement("iframe");b.height=0;b.width=0;b.style.overflow="hidden";b.style.top=b.style.left="-100px";b.style.position="absolute";document.body.appendChild(b);return b};a.o.$=function(b){return b.contentDocument||b.contentWindow.document};a.o.Ga=function(b,c,d){b=a.o.$(b);b.open();d=["<",a.o.Y,\'><form method=POST action="\',d,\'">\'];for(var e in c)c.hasOwnProperty(e)&&d.push(\'<textarea name="\',e,\'">\',c[e],"</textarea>");d.push("</form></",a.o.Y,">");b.write(d.join(""));b.close()};a.o.ba=function(b,c){c>a.o.oa?google&&google.ml&&google.ml(Error("ogcdr"),!1,{cause:"timeout"}):b.contentWindow?a.o.Qa(b):window.setTimeout(function(){a.o.ba(b,c+1)},a.o.qa)};a.o.Qa=function(b){document.body.removeChild(b)};a.o.Pa=function(b){a.o.Ca(b,"load",function(){a.o.ba(b,0)})};a.o.Ca=function(b,c,d){b.addEventListener?b.addEventListener(c,d,!1):b.attachEvent&&b.attachEvent("on"+c,d)};var m={Va:0,D:1,F:2,K:5};a.k={};a.k.M={ka:"i",J:"d",ma:"l"};a.k.A={N:"0",G:"1"};a.k.O={L:1,J:2,I:3};a.k.v={ea:"a",ia:"g",C:"c",ya:"u",xa:"t",N:"p",pa:"pid",ga:"eid",za:"at"};a.k.la=window.location.protocol+"//www.google.com/_/og/promos/";a.k.ha="g";a.k.Aa="z";a.k.S=function(b,c,d,e){var f=null;switch(c){case m.D:f=window.gbar.up.gpd(b,d,!0);break;case m.K:f=window.gbar.up.gcc(e)}return null==f?0:parseInt(f,10)};a.k.Ka=function(b,c,d){return c==m.D?null!=window.gbar.up.gpd(b,d,!0):!1};a.k.P=function(b,c,d,e,f,h,k,l){var g={};g[a.k.v.N]=b;g[a.k.v.ia]=c;g[a.k.v.ea]=d;g[a.k.v.za]=e;g[a.k.v.ga]=f;g[a.k.v.pa]=1;k&&(g[a.k.v.C]=k);l&&(g[a.k.v.ya]=l);if(h)g[a.k.v.xa]=h;else return google.ml(Error("knu"),!1,{cause:"Token is not found"}),null;return g};a.k.V=function(b,c,d){if(b){var e=c?a.k.ha:a.k.Aa;c&&d&&(e+="?authuser="+d);a.o.Ra(b,a.k.la+e)}};a.k.Fa=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.J,a.k.O.J,d,f,null,e);a.k.V(b,h,k)};a.k.Ia=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.ka,a.k.O.L,d,f,e,null);a.k.V(b,h,k)};a.k.Na=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.dpc(e,f);break;case m.D:window.gbar.up.spd(b,d,1,!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.G,n=n||0,a.k.Fa(e,h,k,f,l,g,n)}};a.k.La=function(b,c,d,e,f){return c==m.D?0<d&&a.k.S(b,c,e,f)>=d:!1};a.k.Ha=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.iic(e,f);break;case m.D:c=a.k.S(b,c,d,e)+1;window.gbar.up.spd(b,d,c.toString(),!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.N,n=n||0,a.k.Ia(e,h,k,1,l,g,n)}};a.k.Ma=function(b,c,d,e,f,h){b=a.k.P(c,b,a.k.M.ma,a.k.O.I,d,e,null,null);a.k.V(b,f,h)};var p={Ta:"a",Wa:"l",Ua:"c",fa:"d",I:"h",L:"i",gb:"n",G:"x",cb:"ma",eb:"mc",fb:"mi",Xa:"pa",Ya:"pc",$a:"pi",bb:"pn",ab:"px",Za:"pd",hb:"gpa",jb:"gpi",kb:"gpn",lb:"gpx",ib:"gpd"};a.i={};a.i.s={na:"hplogo",wa:"pmocntr2"};a.i.A={va:"0",G:"1",da:"2"};a.i.p=document.getElementById(a.i.s.wa);a.i.ja=16;a.i.ra=2;a.i.ta=20;google.promos=google.promos||{};google.promos.toast=google.promos.toast||{};a.i.H=function(b){a.i.p&&(a.i.p.style.display=b?"":"none",a.i.p.parentNode&&(a.i.p.parentNode.style.position=b?"relative":""))};a.i.ca=function(b){try{if(a.i.p&&b&&b.es&&b.es.m){var c=window.gbar.rtl(document.body)?"left":"right";a.i.p.style[c]=b.es.m-a.i.ja+a.i.ra+"px";a.i.p.style.top=a.i.ta+"px"}}catch(d){google.ml(d,!1,{cause:a.i.w+"_PT"})}};google.promos.toast.cl=function(){try{a.i.Q==m.F&&a.k.Ma(a.i.T,a.i.B,a.i.A.da,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.I,a.i.R(),1)}catch(b){google.ml(b,!1,{cause:a.i.w+"_CL"})}};google.promos.toast.cpc=function(){try{a.i.p&&(a.i.H(!1),a.k.Na(a.i.p,a.i.Q,a.i.s.Z,a.i.T,a.i.Da,a.i.B,a.i.A.G,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.fa,a.i.R(),1))}catch(b){google.ml(b,!1,{cause:a.i.w+"_CPC"})}};a.i.aa=function(){try{if(a.i.p){var b=276,c=document.getElementById(a.i.s.na);c&&(b=Math.max(b,c.offsetWidth));var d=parseInt(a.i.p.style.right,10)||0;a.i.p.style.visibility=2*(a.i.p.offsetWidth+d)+b>document.body.clientWidth?"hidden":""}}catch(e){google.ml(e,!1,{cause:a.i.w+"_HOSW"})}};a.i.Ba=function(){var b=["gpd","spd","aeh","sl"];if(!window.gbar||!window.gbar.up)return!1;for(var c=0,d;d=b[c];c++)if(!(d in window.gbar.up))return!1;return!0};a.i.Ja=function(){return a.i.p.currentStyle&&"absolute"!=a.i.p.currentStyle.position};google.promos.toast.init=function(b,c,d,e,f,h,k,l,g,n,q,r){try{a.i.Ba()?a.i.p&&(e==m.F&&!l==!g?(google.ml(Error("tku"),!1,{cause:"zwieback: "+g+", gaia: "+l}),a.i.H(!1)):(a.i.s.C="toast_count_"+c+(q?"_"+q:""),a.i.s.Z="toast_dp_"+c+(r?"_"+r:""),a.i.w=d,a.i.B=b,a.i.Q=e,a.i.T=c,a.i.Da=f,a.i.X=l?l:g,a.i.U=!!l,a.i.W=k,a.k.Ka(a.i.p,e,a.i.s.Z,c)||a.k.La(a.i.p,e,h,a.i.s.C,c)||a.i.Ja()?a.i.H(!1):(a.k.Ha(a.i.p,e,a.i.s.C,c,f,a.i.B,a.i.A.va,a.i.X,a.i.U,a.i.W),n||(window.gbar.up.aeh(window,"resize",a.i.aa),window.lol=
a.i.aa,window.gbar.elr&&a.i.ca(window.gbar.elr()),window.gbar.elc&&window.gbar.elc(a.i.ca),a.i.H(!0)),window.gbar.up.sl(a.i.B,a.i.w,p.L,a.i.R())))):google.ml(Error("apa"),!1,{cause:a.i.w+"_INIT"})}catch(t){google.ml(t,!1,{cause:a.i.w+"_INIT"})}};a.i.R=function(){var b=a.k.S(a.i.p,a.i.Q,a.i.s.C,a.i.T);return"ic="+b};})();</script> <script type="text/javascript">(function(){var sourceWebappPromoID=144002;var sourceWebappGroupID=5;var payloadType=5;var cookieMaxAgeSec=2592000;var dismissalType=5;var impressionCap=25;var gaiaXsrfToken=\'\';var zwbkXsrfToken=\'\';var kansasDismissalEnabled=false;var sessionIndex=0;var invisible=false;window.gbar&&gbar.up&&gbar.up.r&&gbar.up.r(payloadType,function(show){if (show){google.promos.toast.init(sourceWebappPromoID,sourceWebappGroupID,payloadType,dismissalType,cookieMaxAgeSec,impressionCap,sessionIndex,gaiaXsrfToken,zwbkXsrfToken,invisible,\'0612\');}
});})();</script> </div> </span><br clear="all" id="lgpd"><div id="lga"><a href="/search?site=&amp;ie=UTF-8&amp;q=Lunar+New+Year&amp;oi=ddle&amp;ct=lunar-new-year-2015-5753824463552512-hp&amp;hl=en&amp;sa=X&amp;ei=w_zlVL68JceiyAS15YDQCQ&amp;ved=0CAMQNg"><img alt="Lunar New Year 2015" border="0" height="200" src="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" title="Lunar New Year 2015" width="500" id="hplogo" onload="window.lol&&lol()"><br></a><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="en" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><div class="ds" style="height:32px;margin:4px 0"><input style="color:#000;margin:0;padding:5px 8px 0 6px;vertical-align:top" autocomplete="off" class="lst" value="" title="Google Search" maxlength="2048" name="q" size="57"></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" value="I\'m Feeling Lucky" name="btnI" onclick="if(this.form.q.value)this.checked=1; else top.location=\'/doodles/\'" type="submit"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=en&amp;authuser=0">Advanced search</a><a href="/language_tools?hl=en&amp;authuser=0">Language tools</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"></form><div id="gac_scont"></div><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="fll"><a href="/intl/en/ads/">Advertising&nbsp;Programs</a><a href="/services/">Business Solutions</a><a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google</a><a href="/intl/en/about.html">About Google</a></div></div><p style="color:#767676;font-size:8pt">&copy; 2015 - <a href="/intl/en/policies/privacy/">Privacy</a> - <a href="/intl/en/policies/terms/">Terms</a></p></span></center><div id="xjsd"></div><div id="xjsi" data-jiis="bp"><script>(function(){function c(b){window.setTimeout(function(){var a=document.createElement("script");a.src=b;document.getElementById("xjsd").appendChild(a)},0)}google.dljp=function(b,a){google.xjsu=b;c(a)};google.dlj=c;})();(function(){window.google.xjsrm=[];})();if(google.y)google.y.first=[];if(!google.xjs){window._=window._||{};window._._DumpException=function(e){throw e};if(google.timers&&google.timers.load.t){google.timers.load.t.xjsls=new Date().getTime();}google.dljp(\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\',\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\');google.xjs=1;}google.pmc={"sb_he":{"agen":true,"cgen":true,"client":"heirloom-hp","dh":true,"ds":"","exp":"msedr","fl":true,"host":"google.com","jam":0,"jsonp":true,"msgs":{"cibl":"Clear Search","dym":"Did you mean:","lcky":"I\\u0026#39;m Feeling Lucky","lml":"Learn more","oskt":"Input tools","psrc":"This search was removed from your \\u003Ca href=\\"/history\\"\\u003EWeb History\\u003C/a\\u003E","psrl":"Remove","sbit":"Search by image","srch":"Google Search"},"ovr":{},"pq":"","refoq":true,"scd":10,"sce":5,"stok":"KQyI_EZbgtzI5GTIJDD0ZSNgC_Y"},"d":{}};google.y.first.push(function(){if(google.med){google.med(\'init\');google.initHistory();google.med(\'history\');}});if(google.j&&google.j.en&&google.j.xi){window.setTimeout(google.j.xi,0);}
</script></div></body></html>',
                                   '_rc' => '200',
                                   '_request' => {}
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'http://www.google.com/')}, 'URI::http' ),
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' ),
                                  '_method' => 'GET',
                                  '_uri' => do{my $o},
                                  '_content' => ''
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'connection' => 'close',
                                                          'set-cookie' => [
                                                                            'PREF=ID=c92a1546582eeeec:FF=0:TM=1424358595:LM=1424358595:S=FxvNQIDc0qfmzzVk; expires=Sat, 18-Feb-2017 15:09:55 GMT; path=/; domain=.google.com',
                                                                            'NID=67=mkZND-mJNZeTXp8TJCP8vAT-I7_erXP-KSS-Wo14mm1mXE1vZzyh17k4lffoGNt9VNGWbuYu4VauFQNeCIl5BHfVOtL4UjxFXK2dshYBb3c2Yu-RvycexmGUHrPEwSx1; expires=Fri, 21-Aug-2015 15:09:55 GMT; path=/; domain=.google.com; HttpOnly'
                                                                          ],
                                                          'p3p' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."',
                                                          'title' => 'Google',
                                                          '::std_case' => {
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'set-cookie' => 'Set-Cookie',
                                                                            'p3p' => 'P3P',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'x-frame-options' => 'X-Frame-Options',
                                                                            'x-xss-protection' => 'X-XSS-Protection',
                                                                            'alternate-protocol' => 'Alternate-Protocol',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'x-meta-robots' => 'X-Meta-Robots',
                                                                            'title' => 'Title'
                                                                          },
                                                          'cache-control' => 'private, max-age=0',
                                                          'server' => 'gws',
                                                          'x-meta-robots' => 'noodp',
                                                          'x-xss-protection' => '1; mode=block',
                                                          'x-frame-options' => 'SAMEORIGIN',
                                                          'content-type' => 'text/html; charset=ISO-8859-1',
                                                          'client-response-num' => 1,
                                                          'vary' => 'Accept-Encoding',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'expires' => '-1',
                                                          'x-meta-description' => 'Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for.',
                                                          'accept-ranges' => 'none',
                                                          'client-peer' => '74.125.225.16:80',
                                                          'alternate-protocol' => '80:quic,p=0.08'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for." name="description"><meta content="noodp" name="robots"><meta content="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" itemprop="image"><title>Google</title><script>(function(){window.google={kEI:\'w_zlVJDsLMONyASIyIK4DA\',kEXPI:\'2032608,4010073,4011559,4017578,4020562,4021587,4021598,4026108,4027916,4028649,4028717,4029136,4029141,4029155,4029514,8300096,8500394,8500852,8501082,8501183,10200083,10200793,10200902,10200909,10200959\',authuser:0,kSID:\'w_zlVJDsLMONyASIyIK4DA\'};google.kHL=\'en\';})();(function(){google.lc=[];google.li=0;google.getEI=function(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||google.kEI};google.getLEI=function(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b};google.https=function(){return"https:"==window.location.protocol};google.ml=function(){};google.time=function(){return(new Date).getTime()};google.log=function(a,b,e,f,l){var d=new Image,h=google.lc,g=google.li,c="",m=google.ls||"";d.onerror=d.onload=d.onabort=function(){delete h[g]};h[g]=d;if(!e&&-1==b.search("&ei=")){var k=google.getEI(f),c="&ei="+k;-1==b.search("&lei=")&&((f=google.getLEI(f))?c+="&lei="+f:k!=google.kEI&&(c+="&lei="+google.kEI))}a=e||"/"+(l||"gen_204")+"?atyp=i&ct="+a+"&cad="+b+c+m+"&zx="+google.time();/^http:/i.test(a)&&google.https()?(google.ml(Error("a"),!1,{src:a,glmm:1}),delete h[g]):(d.src=a,google.li=g+1)};google.y={};google.x=function(a,b){google.y[a.id]=[a,b];return!1};google.load=function(a,b,e){google.x({id:a+n++},function(){google.load(a,b,e)})};var n=0;})();google.kCSI={};var _gjwl=location;function _gjuc(){var a=_gjwl.href.indexOf("#");if(0<=a&&(a=_gjwl.href.substring(a),0<a.indexOf("&q=")||0<=a.indexOf("#q="))&&(a=a.substring(1),-1==a.indexOf("#"))){for(var d=0;d<a.length;){var b=d;"&"==a.charAt(b)&&++b;var c=a.indexOf("&",b);-1==c&&(c=a.length);b=a.substring(b,c);if(0==b.indexOf("fp="))a=a.substring(0,d)+a.substring(c,a.length),c=d;else if("cad=h"==b)return 0;d=c}_gjwl.href="/search?"+a+"&cad=h";return 1}return 0}
function _gjh(){!_gjuc()&&window.google&&google.x&&google.x({id:"GJH"},function(){google.nav&&google.nav.gjh&&google.nav.gjh()})};window._gjh&&_gjh();</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}</style><style>body,td,a,p,.h{font-family:arial,sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#36c}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px arial,sans-serif}.gsfs{font:17px arial,sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:black}a{color:#11c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#36c}a:visited{color:#551a8b}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff !important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#eee;border:solid 1px;border-color:#ccc #999 #999 #ccc;height:30px}.lsbb{display:block}.ftl,#fll a{display:inline-block;margin:0 12px}.lsb{background:url(/images/srpr/nav_logo80.png) 0 -258px repeat-x;border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lsb:active{background:#ccc}.lst:focus{outline:none}</style><script></script></head><body bgcolor="#fff"><script>(function(){var src=\'/images/nav_logo176.png\';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
}
})();</script><div id="mngb">   <div id=gbar><nobr><b class=gb1>Search</b> <a class=gb1 href="http://www.google.com/imghp?hl=en&tab=wi">Images</a> <a class=gb1 href="http://maps.google.com/maps?hl=en&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=en&tab=w8">Play</a> <a class=gb1 href="http://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="http://news.google.com/nwshp?hl=en&tab=wn">News</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="http://www.google.com/intl/en/options/"><u>More</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com/history/optout?hl=en" class=gb4>Web History</a> | <a  href="/preferences?hl=en" class=gb4>Settings</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=en&continue=http://www.google.com/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div>  </div><center><span id="prt" style="display:block"> <div><style>.pmoabs{background-color:#fff;border:1px solid #E5E5E5;color:#666;font-size:13px;padding-bottom:20px;position:absolute;right:2px;top:3px;z-index:986}#pmolnk{border-radius:2px;-moz-border-radius:2px;-webkit-border-radius:2px}.kd-button-submit{border:1px solid #3079ed;background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#4787ed\')}.kd-button-submit:hover{border:1px solid #2f5bb7;background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#357ae8\')}.kd-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}#pmolnk a{color:#fff;display:inline-block;font-weight:bold;padding:5px 20px;text-decoration:none;white-space:nowrap}.xbtn{color:#999;cursor:pointer;font-size:23px;line-height:5px;padding-top:5px}.padi{padding:0 8px 0 10px}.padt{padding:5px 20px 0 0;color:#444}.pads{text-align:left;max-width:200px}</style> <div class="pmoabs" id="pmocntr2" style="behavior:url(#default#userdata);display:none"> <table border="0"> <tr> <td colspan="2"> <div class="xbtn" onclick="google.promos&&google.promos.toast&& google.promos.toast.cpc()" style="float:right">&times;</div> </td> </tr> <tr> <td class="padi" rowspan="2"> <img src="/images/icons/product/chrome-48.png"> </td> <td class="pads">A faster way to browse the web</td> </tr> <tr> <td class="padt"> <div class="kd-button-submit" id="pmolnk"> <a href="/chrome/index.html?hl=en&amp;brand=CHNG&amp;utm_source=en-hpp&amp;utm_medium=hpp&amp;utm_campaign=en" onclick="google.promos&&google.promos.toast&& google.promos.toast.cl()">Install Google Chrome</a> </div> </td> </tr> </table> </div> <script type="text/javascript">(function(){var a={o:{}};a.o.qa=50;a.o.oa=10;a.o.Y="body";a.o.Oa=!0;a.o.Ra=function(b,c){var d=a.o.Ea();a.o.Ga(d,b,c);a.o.Sa(d);a.o.Oa&&a.o.Pa(d)};a.o.Sa=function(b){(b=a.o.$(b))&&0<b.forms.length&&b.forms[0].submit()};a.o.Ea=function(){var b=document.createElement("iframe");b.height=0;b.width=0;b.style.overflow="hidden";b.style.top=b.style.left="-100px";b.style.position="absolute";document.body.appendChild(b);return b};a.o.$=function(b){return b.contentDocument||b.contentWindow.document};a.o.Ga=function(b,c,d){b=a.o.$(b);b.open();d=["<",a.o.Y,\'><form method=POST action="\',d,\'">\'];for(var e in c)c.hasOwnProperty(e)&&d.push(\'<textarea name="\',e,\'">\',c[e],"</textarea>");d.push("</form></",a.o.Y,">");b.write(d.join(""));b.close()};a.o.ba=function(b,c){c>a.o.oa?google&&google.ml&&google.ml(Error("ogcdr"),!1,{cause:"timeout"}):b.contentWindow?a.o.Qa(b):window.setTimeout(function(){a.o.ba(b,c+1)},a.o.qa)};a.o.Qa=function(b){document.body.removeChild(b)};a.o.Pa=function(b){a.o.Ca(b,"load",function(){a.o.ba(b,0)})};a.o.Ca=function(b,c,d){b.addEventListener?b.addEventListener(c,d,!1):b.attachEvent&&b.attachEvent("on"+c,d)};var m={Va:0,D:1,F:2,K:5};a.k={};a.k.M={ka:"i",J:"d",ma:"l"};a.k.A={N:"0",G:"1"};a.k.O={L:1,J:2,I:3};a.k.v={ea:"a",ia:"g",C:"c",ya:"u",xa:"t",N:"p",pa:"pid",ga:"eid",za:"at"};a.k.la=window.location.protocol+"//www.google.com/_/og/promos/";a.k.ha="g";a.k.Aa="z";a.k.S=function(b,c,d,e){var f=null;switch(c){case m.D:f=window.gbar.up.gpd(b,d,!0);break;case m.K:f=window.gbar.up.gcc(e)}return null==f?0:parseInt(f,10)};a.k.Ka=function(b,c,d){return c==m.D?null!=window.gbar.up.gpd(b,d,!0):!1};a.k.P=function(b,c,d,e,f,h,k,l){var g={};g[a.k.v.N]=b;g[a.k.v.ia]=c;g[a.k.v.ea]=d;g[a.k.v.za]=e;g[a.k.v.ga]=f;g[a.k.v.pa]=1;k&&(g[a.k.v.C]=k);l&&(g[a.k.v.ya]=l);if(h)g[a.k.v.xa]=h;else return google.ml(Error("knu"),!1,{cause:"Token is not found"}),null;return g};a.k.V=function(b,c,d){if(b){var e=c?a.k.ha:a.k.Aa;c&&d&&(e+="?authuser="+d);a.o.Ra(b,a.k.la+e)}};a.k.Fa=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.J,a.k.O.J,d,f,null,e);a.k.V(b,h,k)};a.k.Ia=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.ka,a.k.O.L,d,f,e,null);a.k.V(b,h,k)};a.k.Na=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.dpc(e,f);break;case m.D:window.gbar.up.spd(b,d,1,!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.G,n=n||0,a.k.Fa(e,h,k,f,l,g,n)}};a.k.La=function(b,c,d,e,f){return c==m.D?0<d&&a.k.S(b,c,e,f)>=d:!1};a.k.Ha=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.iic(e,f);break;case m.D:c=a.k.S(b,c,d,e)+1;window.gbar.up.spd(b,d,c.toString(),!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.N,n=n||0,a.k.Ia(e,h,k,1,l,g,n)}};a.k.Ma=function(b,c,d,e,f,h){b=a.k.P(c,b,a.k.M.ma,a.k.O.I,d,e,null,null);a.k.V(b,f,h)};var p={Ta:"a",Wa:"l",Ua:"c",fa:"d",I:"h",L:"i",gb:"n",G:"x",cb:"ma",eb:"mc",fb:"mi",Xa:"pa",Ya:"pc",$a:"pi",bb:"pn",ab:"px",Za:"pd",hb:"gpa",jb:"gpi",kb:"gpn",lb:"gpx",ib:"gpd"};a.i={};a.i.s={na:"hplogo",wa:"pmocntr2"};a.i.A={va:"0",G:"1",da:"2"};a.i.p=document.getElementById(a.i.s.wa);a.i.ja=16;a.i.ra=2;a.i.ta=20;google.promos=google.promos||{};google.promos.toast=google.promos.toast||{};a.i.H=function(b){a.i.p&&(a.i.p.style.display=b?"":"none",a.i.p.parentNode&&(a.i.p.parentNode.style.position=b?"relative":""))};a.i.ca=function(b){try{if(a.i.p&&b&&b.es&&b.es.m){var c=window.gbar.rtl(document.body)?"left":"right";a.i.p.style[c]=b.es.m-a.i.ja+a.i.ra+"px";a.i.p.style.top=a.i.ta+"px"}}catch(d){google.ml(d,!1,{cause:a.i.w+"_PT"})}};google.promos.toast.cl=function(){try{a.i.Q==m.F&&a.k.Ma(a.i.T,a.i.B,a.i.A.da,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.I,a.i.R(),1)}catch(b){google.ml(b,!1,{cause:a.i.w+"_CL"})}};google.promos.toast.cpc=function(){try{a.i.p&&(a.i.H(!1),a.k.Na(a.i.p,a.i.Q,a.i.s.Z,a.i.T,a.i.Da,a.i.B,a.i.A.G,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.fa,a.i.R(),1))}catch(b){google.ml(b,!1,{cause:a.i.w+"_CPC"})}};a.i.aa=function(){try{if(a.i.p){var b=276,c=document.getElementById(a.i.s.na);c&&(b=Math.max(b,c.offsetWidth));var d=parseInt(a.i.p.style.right,10)||0;a.i.p.style.visibility=2*(a.i.p.offsetWidth+d)+b>document.body.clientWidth?"hidden":""}}catch(e){google.ml(e,!1,{cause:a.i.w+"_HOSW"})}};a.i.Ba=function(){var b=["gpd","spd","aeh","sl"];if(!window.gbar||!window.gbar.up)return!1;for(var c=0,d;d=b[c];c++)if(!(d in window.gbar.up))return!1;return!0};a.i.Ja=function(){return a.i.p.currentStyle&&"absolute"!=a.i.p.currentStyle.position};google.promos.toast.init=function(b,c,d,e,f,h,k,l,g,n,q,r){try{a.i.Ba()?a.i.p&&(e==m.F&&!l==!g?(google.ml(Error("tku"),!1,{cause:"zwieback: "+g+", gaia: "+l}),a.i.H(!1)):(a.i.s.C="toast_count_"+c+(q?"_"+q:""),a.i.s.Z="toast_dp_"+c+(r?"_"+r:""),a.i.w=d,a.i.B=b,a.i.Q=e,a.i.T=c,a.i.Da=f,a.i.X=l?l:g,a.i.U=!!l,a.i.W=k,a.k.Ka(a.i.p,e,a.i.s.Z,c)||a.k.La(a.i.p,e,h,a.i.s.C,c)||a.i.Ja()?a.i.H(!1):(a.k.Ha(a.i.p,e,a.i.s.C,c,f,a.i.B,a.i.A.va,a.i.X,a.i.U,a.i.W),n||(window.gbar.up.aeh(window,"resize",a.i.aa),window.lol=
a.i.aa,window.gbar.elr&&a.i.ca(window.gbar.elr()),window.gbar.elc&&window.gbar.elc(a.i.ca),a.i.H(!0)),window.gbar.up.sl(a.i.B,a.i.w,p.L,a.i.R())))):google.ml(Error("apa"),!1,{cause:a.i.w+"_INIT"})}catch(t){google.ml(t,!1,{cause:a.i.w+"_INIT"})}};a.i.R=function(){var b=a.k.S(a.i.p,a.i.Q,a.i.s.C,a.i.T);return"ic="+b};})();</script> <script type="text/javascript">(function(){var sourceWebappPromoID=144002;var sourceWebappGroupID=5;var payloadType=5;var cookieMaxAgeSec=2592000;var dismissalType=5;var impressionCap=25;var gaiaXsrfToken=\'\';var zwbkXsrfToken=\'\';var kansasDismissalEnabled=false;var sessionIndex=0;var invisible=false;window.gbar&&gbar.up&&gbar.up.r&&gbar.up.r(payloadType,function(show){if (show){google.promos.toast.init(sourceWebappPromoID,sourceWebappGroupID,payloadType,dismissalType,cookieMaxAgeSec,impressionCap,sessionIndex,gaiaXsrfToken,zwbkXsrfToken,invisible,\'0612\');}
});})();</script> </div> </span><br clear="all" id="lgpd"><div id="lga"><a href="/search?site=&amp;ie=UTF-8&amp;q=Lunar+New+Year&amp;oi=ddle&amp;ct=lunar-new-year-2015-5753824463552512-hp&amp;hl=en&amp;sa=X&amp;ei=w_zlVJDsLMONyASIyIK4DA&amp;ved=0CAMQNg"><img alt="Lunar New Year 2015" border="0" height="200" src="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" title="Lunar New Year 2015" width="500" id="hplogo" onload="window.lol&&lol()"><br></a><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="en" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><div class="ds" style="height:32px;margin:4px 0"><input style="color:#000;margin:0;padding:5px 8px 0 6px;vertical-align:top" autocomplete="off" class="lst" value="" title="Google Search" maxlength="2048" name="q" size="57"></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" value="I\'m Feeling Lucky" name="btnI" onclick="if(this.form.q.value)this.checked=1; else top.location=\'/doodles/\'" type="submit"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=en&amp;authuser=0">Advanced search</a><a href="/language_tools?hl=en&amp;authuser=0">Language tools</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"></form><div id="gac_scont"></div><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="fll"><a href="/intl/en/ads/">Advertising&nbsp;Programs</a><a href="/services/">Business Solutions</a><a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google</a><a href="/intl/en/about.html">About Google</a></div></div><p style="color:#767676;font-size:8pt">&copy; 2015 - <a href="/intl/en/policies/privacy/">Privacy</a> - <a href="/intl/en/policies/terms/">Terms</a></p></span></center><div id="xjsd"></div><div id="xjsi" data-jiis="bp"><script>(function(){function c(b){window.setTimeout(function(){var a=document.createElement("script");a.src=b;document.getElementById("xjsd").appendChild(a)},0)}google.dljp=function(b,a){google.xjsu=b;c(a)};google.dlj=c;})();(function(){window.google.xjsrm=[];})();if(google.y)google.y.first=[];if(!google.xjs){window._=window._||{};window._._DumpException=function(e){throw e};if(google.timers&&google.timers.load.t){google.timers.load.t.xjsls=new Date().getTime();}google.dljp(\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\',\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\');google.xjs=1;}google.pmc={"sb_he":{"agen":true,"cgen":true,"client":"heirloom-hp","dh":true,"ds":"","exp":"msedr","fl":true,"host":"google.com","jam":0,"jsonp":true,"msgs":{"cibl":"Clear Search","dym":"Did you mean:","lcky":"I\\u0026#39;m Feeling Lucky","lml":"Learn more","oskt":"Input tools","psrc":"This search was removed from your \\u003Ca href=\\"/history\\"\\u003EWeb History\\u003C/a\\u003E","psrl":"Remove","sbit":"Search by image","srch":"Google Search"},"ovr":{},"pq":"","refoq":true,"scd":10,"sce":5,"stok":"KQyI_EZbgtzI5GTIJDD0ZSNgC_Y"},"d":{}};google.y.first.push(function(){if(google.med){google.med(\'init\');google.initHistory();google.med(\'history\');}});if(google.j&&google.j.en&&google.j.xi){window.setTimeout(google.j.xi,0);}
</script></div></body></html>',
                                   '_rc' => '200'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'connection' => 'close',
                                                          'p3p' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."',
                                                          'set-cookie' => [
                                                                            'PREF=ID=6bd393659dac07e2:FF=0:TM=1424358595:LM=1424358595:S=CKa418_lXla6a4UW; expires=Sat, 18-Feb-2017 15:09:55 GMT; path=/; domain=.google.com',
                                                                            'NID=67=fu8k061vAaAyWCrA1sDOd7hjzoDbfLmHSe8-U4viwHlOhTgerTN_d0vum80PVA0iZfTfzLFIhhlz37mm0zVzIh2zo-BVDbZ-IMding8P4NJzu3XbEP7QBhqOTskpwtuF; expires=Fri, 21-Aug-2015 15:09:55 GMT; path=/; domain=.google.com; HttpOnly'
                                                                          ],
                                                          'title' => 'Google',
                                                          '::std_case' => {
                                                                            'set-cookie' => 'Set-Cookie',
                                                                            'p3p' => 'P3P',
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'x-meta-robots' => 'X-Meta-Robots',
                                                                            'alternate-protocol' => 'Alternate-Protocol',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'x-frame-options' => 'X-Frame-Options',
                                                                            'x-xss-protection' => 'X-XSS-Protection',
                                                                            'title' => 'Title'
                                                                          },
                                                          'x-xss-protection' => '1; mode=block',
                                                          'x-frame-options' => 'SAMEORIGIN',
                                                          'cache-control' => 'private, max-age=0',
                                                          'server' => 'gws',
                                                          'x-meta-robots' => 'noodp',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:55 GMT',
                                                          'vary' => 'Accept-Encoding',
                                                          'content-type' => 'text/html; charset=ISO-8859-1',
                                                          'client-response-num' => 1,
                                                          'expires' => '-1',
                                                          'x-meta-description' => 'Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for.',
                                                          'accept-ranges' => 'none',
                                                          'client-peer' => '74.125.225.16:80',
                                                          'alternate-protocol' => '80:quic,p=0.08'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_method' => 'GET',
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'http://www.google.com/')}, 'URI::http' ),
                                                          '_uri' => do{my $o},
                                                          '_content' => ''
                                                        }, 'HTTP::Request' ),
                                   '_content' => '<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world\'s information, including webpages, images, videos and more. Google has many special features to help you find exactly what you\'re looking for." name="description"><meta content="noodp" name="robots"><meta content="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" itemprop="image"><title>Google</title><script>(function(){window.google={kEI:\'w_zlVPWVNIupyQTKuIHICg\',kEXPI:\'2032608,4011009,4017578,4020347,4020562,4020726,4021587,4021598,4024681,4025827,4028650,4028716,4029048,4029056,4029140,4029155,4029471,8500394,8500851,8500972,8501082,8501183,10200083,10200793,10200909\',authuser:0,kSID:\'w_zlVPWVNIupyQTKuIHICg\'};google.kHL=\'en\';})();(function(){google.lc=[];google.li=0;google.getEI=function(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||google.kEI};google.getLEI=function(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b};google.https=function(){return"https:"==window.location.protocol};google.ml=function(){};google.time=function(){return(new Date).getTime()};google.log=function(a,b,e,f,l){var d=new Image,h=google.lc,g=google.li,c="",m=google.ls||"";d.onerror=d.onload=d.onabort=function(){delete h[g]};h[g]=d;if(!e&&-1==b.search("&ei=")){var k=google.getEI(f),c="&ei="+k;-1==b.search("&lei=")&&((f=google.getLEI(f))?c+="&lei="+f:k!=google.kEI&&(c+="&lei="+google.kEI))}a=e||"/"+(l||"gen_204")+"?atyp=i&ct="+a+"&cad="+b+c+m+"&zx="+google.time();/^http:/i.test(a)&&google.https()?(google.ml(Error("a"),!1,{src:a,glmm:1}),delete h[g]):(d.src=a,google.li=g+1)};google.y={};google.x=function(a,b){google.y[a.id]=[a,b];return!1};google.load=function(a,b,e){google.x({id:a+n++},function(){google.load(a,b,e)})};var n=0;})();google.kCSI={};var _gjwl=location;function _gjuc(){var a=_gjwl.href.indexOf("#");if(0<=a&&(a=_gjwl.href.substring(a),0<a.indexOf("&q=")||0<=a.indexOf("#q="))&&(a=a.substring(1),-1==a.indexOf("#"))){for(var d=0;d<a.length;){var b=d;"&"==a.charAt(b)&&++b;var c=a.indexOf("&",b);-1==c&&(c=a.length);b=a.substring(b,c);if(0==b.indexOf("fp="))a=a.substring(0,d)+a.substring(c,a.length),c=d;else if("cad=h"==b)return 0;d=c}_gjwl.href="/search?"+a+"&cad=h";return 1}return 0}
function _gjh(){!_gjuc()&&window.google&&google.x&&google.x({id:"GJH"},function(){google.nav&&google.nav.gjh&&google.nav.gjh()})};window._gjh&&_gjh();</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}</style><style>body,td,a,p,.h{font-family:arial,sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#36c}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px arial,sans-serif}.gsfs{font:17px arial,sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:black}a{color:#11c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#36c}a:visited{color:#551a8b}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff !important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#eee;border:solid 1px;border-color:#ccc #999 #999 #ccc;height:30px}.lsbb{display:block}.ftl,#fll a{display:inline-block;margin:0 12px}.lsb{background:url(/images/srpr/nav_logo80.png) 0 -258px repeat-x;border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lsb:active{background:#ccc}.lst:focus{outline:none}</style><script></script></head><body bgcolor="#fff"><script>(function(){var src=\'/images/nav_logo176.png\';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
}
})();</script><div id="mngb">   <div id=gbar><nobr><b class=gb1>Search</b> <a class=gb1 href="http://www.google.com/imghp?hl=en&tab=wi">Images</a> <a class=gb1 href="http://maps.google.com/maps?hl=en&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=en&tab=w8">Play</a> <a class=gb1 href="http://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="http://news.google.com/nwshp?hl=en&tab=wn">News</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="http://www.google.com/intl/en/options/"><u>More</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com/history/optout?hl=en" class=gb4>Web History</a> | <a  href="/preferences?hl=en" class=gb4>Settings</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=en&continue=http://www.google.com/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div>  </div><center><span id="prt" style="display:block"> <div><style>.pmoabs{background-color:#fff;border:1px solid #E5E5E5;color:#666;font-size:13px;padding-bottom:20px;position:absolute;right:2px;top:3px;z-index:986}#pmolnk{border-radius:2px;-moz-border-radius:2px;-webkit-border-radius:2px}.kd-button-submit{border:1px solid #3079ed;background-color:#4d90fe;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#4787ed));background-image:-webkit-linear-gradient(top,#4d90fe,#4787ed);background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-image:-ms-linear-gradient(top,#4d90fe,#4787ed);background-image:-o-linear-gradient(top,#4d90fe,#4787ed);background-image:linear-gradient(top,#4d90fe,#4787ed);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#4787ed\')}.kd-button-submit:hover{border:1px solid #2f5bb7;background-color:#357ae8;background-image:-webkit-gradient(linear,left top,left bottom,from(#4d90fe),to(#357ae8));background-image:-webkit-linear-gradient(top,#4d90fe,#357ae8);background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-image:-ms-linear-gradient(top,#4d90fe,#357ae8);background-image:-o-linear-gradient(top,#4d90fe,#357ae8);background-image:linear-gradient(top,#4d90fe,#357ae8);filter:progid:DXImageTransform.Microsoft.gradient(startColorStr=\'#4d90fe\',EndColorStr=\'#357ae8\')}.kd-button-submit:active{-webkit-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}#pmolnk a{color:#fff;display:inline-block;font-weight:bold;padding:5px 20px;text-decoration:none;white-space:nowrap}.xbtn{color:#999;cursor:pointer;font-size:23px;line-height:5px;padding-top:5px}.padi{padding:0 8px 0 10px}.padt{padding:5px 20px 0 0;color:#444}.pads{text-align:left;max-width:200px}</style> <div class="pmoabs" id="pmocntr2" style="behavior:url(#default#userdata);display:none"> <table border="0"> <tr> <td colspan="2"> <div class="xbtn" onclick="google.promos&&google.promos.toast&& google.promos.toast.cpc()" style="float:right">&times;</div> </td> </tr> <tr> <td class="padi" rowspan="2"> <img src="/images/icons/product/chrome-48.png"> </td> <td class="pads">A faster way to browse the web</td> </tr> <tr> <td class="padt"> <div class="kd-button-submit" id="pmolnk"> <a href="/chrome/index.html?hl=en&amp;brand=CHNG&amp;utm_source=en-hpp&amp;utm_medium=hpp&amp;utm_campaign=en" onclick="google.promos&&google.promos.toast&& google.promos.toast.cl()">Install Google Chrome</a> </div> </td> </tr> </table> </div> <script type="text/javascript">(function(){var a={o:{}};a.o.qa=50;a.o.oa=10;a.o.Y="body";a.o.Oa=!0;a.o.Ra=function(b,c){var d=a.o.Ea();a.o.Ga(d,b,c);a.o.Sa(d);a.o.Oa&&a.o.Pa(d)};a.o.Sa=function(b){(b=a.o.$(b))&&0<b.forms.length&&b.forms[0].submit()};a.o.Ea=function(){var b=document.createElement("iframe");b.height=0;b.width=0;b.style.overflow="hidden";b.style.top=b.style.left="-100px";b.style.position="absolute";document.body.appendChild(b);return b};a.o.$=function(b){return b.contentDocument||b.contentWindow.document};a.o.Ga=function(b,c,d){b=a.o.$(b);b.open();d=["<",a.o.Y,\'><form method=POST action="\',d,\'">\'];for(var e in c)c.hasOwnProperty(e)&&d.push(\'<textarea name="\',e,\'">\',c[e],"</textarea>");d.push("</form></",a.o.Y,">");b.write(d.join(""));b.close()};a.o.ba=function(b,c){c>a.o.oa?google&&google.ml&&google.ml(Error("ogcdr"),!1,{cause:"timeout"}):b.contentWindow?a.o.Qa(b):window.setTimeout(function(){a.o.ba(b,c+1)},a.o.qa)};a.o.Qa=function(b){document.body.removeChild(b)};a.o.Pa=function(b){a.o.Ca(b,"load",function(){a.o.ba(b,0)})};a.o.Ca=function(b,c,d){b.addEventListener?b.addEventListener(c,d,!1):b.attachEvent&&b.attachEvent("on"+c,d)};var m={Va:0,D:1,F:2,K:5};a.k={};a.k.M={ka:"i",J:"d",ma:"l"};a.k.A={N:"0",G:"1"};a.k.O={L:1,J:2,I:3};a.k.v={ea:"a",ia:"g",C:"c",ya:"u",xa:"t",N:"p",pa:"pid",ga:"eid",za:"at"};a.k.la=window.location.protocol+"//www.google.com/_/og/promos/";a.k.ha="g";a.k.Aa="z";a.k.S=function(b,c,d,e){var f=null;switch(c){case m.D:f=window.gbar.up.gpd(b,d,!0);break;case m.K:f=window.gbar.up.gcc(e)}return null==f?0:parseInt(f,10)};a.k.Ka=function(b,c,d){return c==m.D?null!=window.gbar.up.gpd(b,d,!0):!1};a.k.P=function(b,c,d,e,f,h,k,l){var g={};g[a.k.v.N]=b;g[a.k.v.ia]=c;g[a.k.v.ea]=d;g[a.k.v.za]=e;g[a.k.v.ga]=f;g[a.k.v.pa]=1;k&&(g[a.k.v.C]=k);l&&(g[a.k.v.ya]=l);if(h)g[a.k.v.xa]=h;else return google.ml(Error("knu"),!1,{cause:"Token is not found"}),null;return g};a.k.V=function(b,c,d){if(b){var e=c?a.k.ha:a.k.Aa;c&&d&&(e+="?authuser="+d);a.o.Ra(b,a.k.la+e)}};a.k.Fa=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.J,a.k.O.J,d,f,null,e);a.k.V(b,h,k)};a.k.Ia=function(b,c,d,e,f,h,k){b=a.k.P(c,b,a.k.M.ka,a.k.O.L,d,f,e,null);a.k.V(b,h,k)};a.k.Na=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.dpc(e,f);break;case m.D:window.gbar.up.spd(b,d,1,!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.G,n=n||0,a.k.Fa(e,h,k,f,l,g,n)}};a.k.La=function(b,c,d,e,f){return c==m.D?0<d&&a.k.S(b,c,e,f)>=d:!1};a.k.Ha=function(b,c,d,e,f,h,k,l,g,n){switch(c){case m.K:window.gbar.up.iic(e,f);break;case m.D:c=a.k.S(b,c,d,e)+1;window.gbar.up.spd(b,d,c.toString(),!0);break;case m.F:g=g||!1,l=l||"",h=h||0,k=k||a.k.A.N,n=n||0,a.k.Ia(e,h,k,1,l,g,n)}};a.k.Ma=function(b,c,d,e,f,h){b=a.k.P(c,b,a.k.M.ma,a.k.O.I,d,e,null,null);a.k.V(b,f,h)};var p={Ta:"a",Wa:"l",Ua:"c",fa:"d",I:"h",L:"i",gb:"n",G:"x",cb:"ma",eb:"mc",fb:"mi",Xa:"pa",Ya:"pc",$a:"pi",bb:"pn",ab:"px",Za:"pd",hb:"gpa",jb:"gpi",kb:"gpn",lb:"gpx",ib:"gpd"};a.i={};a.i.s={na:"hplogo",wa:"pmocntr2"};a.i.A={va:"0",G:"1",da:"2"};a.i.p=document.getElementById(a.i.s.wa);a.i.ja=16;a.i.ra=2;a.i.ta=20;google.promos=google.promos||{};google.promos.toast=google.promos.toast||{};a.i.H=function(b){a.i.p&&(a.i.p.style.display=b?"":"none",a.i.p.parentNode&&(a.i.p.parentNode.style.position=b?"relative":""))};a.i.ca=function(b){try{if(a.i.p&&b&&b.es&&b.es.m){var c=window.gbar.rtl(document.body)?"left":"right";a.i.p.style[c]=b.es.m-a.i.ja+a.i.ra+"px";a.i.p.style.top=a.i.ta+"px"}}catch(d){google.ml(d,!1,{cause:a.i.w+"_PT"})}};google.promos.toast.cl=function(){try{a.i.Q==m.F&&a.k.Ma(a.i.T,a.i.B,a.i.A.da,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.I,a.i.R(),1)}catch(b){google.ml(b,!1,{cause:a.i.w+"_CL"})}};google.promos.toast.cpc=function(){try{a.i.p&&(a.i.H(!1),a.k.Na(a.i.p,a.i.Q,a.i.s.Z,a.i.T,a.i.Da,a.i.B,a.i.A.G,a.i.X,a.i.U,a.i.W),window.gbar.up.sl(a.i.B,a.i.w,p.fa,a.i.R(),1))}catch(b){google.ml(b,!1,{cause:a.i.w+"_CPC"})}};a.i.aa=function(){try{if(a.i.p){var b=276,c=document.getElementById(a.i.s.na);c&&(b=Math.max(b,c.offsetWidth));var d=parseInt(a.i.p.style.right,10)||0;a.i.p.style.visibility=2*(a.i.p.offsetWidth+d)+b>document.body.clientWidth?"hidden":""}}catch(e){google.ml(e,!1,{cause:a.i.w+"_HOSW"})}};a.i.Ba=function(){var b=["gpd","spd","aeh","sl"];if(!window.gbar||!window.gbar.up)return!1;for(var c=0,d;d=b[c];c++)if(!(d in window.gbar.up))return!1;return!0};a.i.Ja=function(){return a.i.p.currentStyle&&"absolute"!=a.i.p.currentStyle.position};google.promos.toast.init=function(b,c,d,e,f,h,k,l,g,n,q,r){try{a.i.Ba()?a.i.p&&(e==m.F&&!l==!g?(google.ml(Error("tku"),!1,{cause:"zwieback: "+g+", gaia: "+l}),a.i.H(!1)):(a.i.s.C="toast_count_"+c+(q?"_"+q:""),a.i.s.Z="toast_dp_"+c+(r?"_"+r:""),a.i.w=d,a.i.B=b,a.i.Q=e,a.i.T=c,a.i.Da=f,a.i.X=l?l:g,a.i.U=!!l,a.i.W=k,a.k.Ka(a.i.p,e,a.i.s.Z,c)||a.k.La(a.i.p,e,h,a.i.s.C,c)||a.i.Ja()?a.i.H(!1):(a.k.Ha(a.i.p,e,a.i.s.C,c,f,a.i.B,a.i.A.va,a.i.X,a.i.U,a.i.W),n||(window.gbar.up.aeh(window,"resize",a.i.aa),window.lol=
a.i.aa,window.gbar.elr&&a.i.ca(window.gbar.elr()),window.gbar.elc&&window.gbar.elc(a.i.ca),a.i.H(!0)),window.gbar.up.sl(a.i.B,a.i.w,p.L,a.i.R())))):google.ml(Error("apa"),!1,{cause:a.i.w+"_INIT"})}catch(t){google.ml(t,!1,{cause:a.i.w+"_INIT"})}};a.i.R=function(){var b=a.k.S(a.i.p,a.i.Q,a.i.s.C,a.i.T);return"ic="+b};})();</script> <script type="text/javascript">(function(){var sourceWebappPromoID=144002;var sourceWebappGroupID=5;var payloadType=5;var cookieMaxAgeSec=2592000;var dismissalType=5;var impressionCap=25;var gaiaXsrfToken=\'\';var zwbkXsrfToken=\'\';var kansasDismissalEnabled=false;var sessionIndex=0;var invisible=false;window.gbar&&gbar.up&&gbar.up.r&&gbar.up.r(payloadType,function(show){if (show){google.promos.toast.init(sourceWebappPromoID,sourceWebappGroupID,payloadType,dismissalType,cookieMaxAgeSec,impressionCap,sessionIndex,gaiaXsrfToken,zwbkXsrfToken,invisible,\'0612\');}
});})();</script> </div> </span><br clear="all" id="lgpd"><div id="lga"><a href="/search?site=&amp;ie=UTF-8&amp;q=Lunar+New+Year&amp;oi=ddle&amp;ct=lunar-new-year-2015-5753824463552512-hp&amp;hl=en&amp;sa=X&amp;ei=w_zlVPWVNIupyQTKuIHICg&amp;ved=0CAMQNg"><img alt="Lunar New Year 2015" border="0" height="200" src="/logos/doodles/2015/lunar-new-year-2015-5753824463552512-hp.gif" title="Lunar New Year 2015" width="500" id="hplogo" onload="window.lol&&lol()"><br></a><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="en" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><div class="ds" style="height:32px;margin:4px 0"><input style="color:#000;margin:0;padding:5px 8px 0 6px;vertical-align:top" autocomplete="off" class="lst" value="" title="Google Search" maxlength="2048" name="q" size="57"></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" value="I\'m Feeling Lucky" name="btnI" onclick="if(this.form.q.value)this.checked=1; else top.location=\'/doodles/\'" type="submit"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=en&amp;authuser=0">Advanced search</a><a href="/language_tools?hl=en&amp;authuser=0">Language tools</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"></form><div id="gac_scont"></div><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="fll"><a href="/intl/en/ads/">Advertising&nbsp;Programs</a><a href="/services/">Business Solutions</a><a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google</a><a href="/intl/en/about.html">About Google</a></div></div><p style="color:#767676;font-size:8pt">&copy; 2015 - <a href="/intl/en/policies/privacy/">Privacy</a> - <a href="/intl/en/policies/terms/">Terms</a></p></span></center><div id="xjsd"></div><div id="xjsi" data-jiis="bp"><script>(function(){function c(b){window.setTimeout(function(){var a=document.createElement("script");a.src=b;document.getElementById("xjsd").appendChild(a)},0)}google.dljp=function(b,a){google.xjsu=b;c(a)};google.dlj=c;})();(function(){window.google.xjsrm=[];})();if(google.y)google.y.first=[];if(!google.xjs){window._=window._||{};window._._DumpException=function(e){throw e};if(google.timers&&google.timers.load.t){google.timers.load.t.xjsls=new Date().getTime();}google.dljp(\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\',\'/xjs/_/js/k\\x3dxjs.hp.en_US._y8mmB9OTno.O/m\\x3dsb_he,d/rt\\x3dj/d\\x3d1/t\\x3dzcms/rs\\x3dACT90oEQYapbhQOEh6Jd5y29jydvuygGJA\');google.xjs=1;}google.pmc={"sb_he":{"agen":true,"cgen":true,"client":"heirloom-hp","dh":true,"ds":"","exp":"msedr","fl":true,"host":"google.com","jam":0,"jsonp":true,"msgs":{"cibl":"Clear Search","dym":"Did you mean:","lcky":"I\\u0026#39;m Feeling Lucky","lml":"Learn more","oskt":"Input tools","psrc":"This search was removed from your \\u003Ca href=\\"/history\\"\\u003EWeb History\\u003C/a\\u003E","psrl":"Remove","sbit":"Search by image","srch":"Google Search"},"ovr":{},"pq":"","refoq":true,"scd":10,"sce":5,"stok":"KQyI_EZbgtzI5GTIJDD0ZSNgC_Y"},"d":{}};google.y.first.push(function(){if(google.med){google.med(\'init\');google.initHistory();google.med(\'history\');}});if(google.j&&google.j.en&&google.j.xi){window.setTimeout(google.j.xi,0);}
</script></div></body></html>',
                                   '_rc' => '200',
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_request' => bless( {
                                                          '_uri_canonical' => bless( do{\(my $o = 'http://www.perl.org/')}, 'URI::http' ),
                                                          '_method' => 'GET',
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_content' => '
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>The Perl Programming Language - www.perl.org</title>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />

    <link rel="shortcut icon" href="//st.pimg.net/perlweb/favicon.v249dfa7.ico" />



      <link rel="stylesheet" type="text/css" href="//st.pimg.net/perlweb/css/leostyle.v8cd7532.css" /> 
      <link rel="stylesheet" type="text/css" href="//st.pimg.net/perlweb/css/www.v1c370c5.css" /> 


    <meta name="description" content="The Perl Programming Language at Perl.org. Links and other helpful resources for new and experienced Perl programmers." />
    

    

    
    <link rel="canonical" href="https://www.perl.org/" />
    




</head>
<body class="section_home">

<div id="header_holder">
    <div class="sub_holder">
        <div id="page_image"></div>
        <h1>
           <a href="/">The Perl Programming Language</a>
        </h1>
        <div id="logo_holder">
           
            

            <a href="/"><img src="//st.pimg.net/perlweb/images/camel_head.v25e738a.png" id="logo" alt="Perl, modern programming" height="65" align="right" /></a>
            

			 <span>www.perl.org</span>

        </div>
    </div>
</div>

<div id="nav">
    <div class="sub_holder">
        <ul>
    <li class="selected">
        <a href="/">Home</a>
    </li>
    <li>
        <a href="/learn.html">Learn</a>
    </li>
    <li>
        <a href="/docs.html">Documentation</a>
    </li>
    <li>
        <a href="/cpan.html">CPAN</a>
    </li>
    <li>
        <a href="/community.html">Community</a>
    </li>
    <li>
        <a href="/contribute.html">Get Involved</a>
    </li>
    <li class="sub">
        <a href="/about.html">About Perl</a>
    </li>
    <li class="sub">
        <a href="/get.html">Download</a>
    </li>
</ul>

    </div>
</div>

<div id="crum_holder">
    <div id="crum" class="sub_holder">
        &nbsp;
    </div>
</div>

<div id="content_holder">
    <div id="content" class="sub_holder">
        <div id="main">
            



<div class="masthead">
	<p class="headline">Flexible &amp; Powerful</p>
	
	<p class="strap">That\'s why we love Perl 5</p>
	
	
	<p class="button"><a href="/get.html" class="download">Download Perl</a></p>
	
	
	<p class="cta"><a href="/get.html">Get started</a></p>

</div>

<p class="intro">Perl 5 is a highly capable, feature-rich programming language with over 27 years of development. <a href="/about.html">More about why we love Perl...</a></p>

<table class="content_table">

    <tr>
        <td>
            <div class="module">
                <a href="/learn.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/learn.v0e1f83c.png" width="45" height="45" /></a>
                <h4>
                    <a href="/learn.html">Learning Perl 5</a>
                </h4>
                <p>
                    With free online books, over 25,000 extension modules, and a large developer community, there are many ways to learn Perl 5.
                </p>
            </div>
        </td>
        <td>
            <div class="module">
                <a href="/community.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/community.v03bf8ce.png" width="45" height="45" /></a>
                <h4>
                    <a href="/community.html">The Perl Community</a>
                </h4>
                <p>
                    Perl has an active world wide community with over 300 local groups, mailing lists and support/discussion websites.
                </p>
            </div>
        </td>
    </tr>
    <tr>
        <td>
            <div class="module">
                <a href="/docs.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/docs.v2622a01.png" width="45" height="45" /></a>
                <h4>
                    <a href="/docs.html">Documentation</a>
                </h4>
                <p>
                    Core documentation, FAQs and translations.
                </p>
            </div>
        </td>
        <td>
            <div class="module">
                <a href="/contribute.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/cog.v08b9acc.png" width="45" height="45" /></a>
                <h4>
                    <a href="/contribute.html">Contribute to Perl</a>
                </h4>
                <p>
                    Perl is being <a href="/dev.html">actively developed</a>. There are many ways to <a href="/contribute.html">get involved</a>.
                </p>
            </div>
        </td>
    </tr>
    <tr>
        <td>
            <div class="module">
                <a href="/cpan.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/cpan.vdc5be93.png" width="45" height="45" /></a>
                <h4>
                    <a href="/cpan.html">CPAN</a>
                </h4>
                <p>
                    The Comprehensive Perl Archive Network (CPAN) has over 25,000 open source distributions available for download.
                </p>
            </div>
        </td>
        <td>
            <div class="module">
                <a href="/events.html"><img alt="" src="//st.pimg.net/perlweb/images/icons/cal.v705acef.png" width="45" height="45" /></a>
                <h4>
                    <a href="/events.html">Events and Conferences</a>
                </h4>
                <p>
                    Conferences, social and technical events around the world offer lots of networking and learning opportunities.
                </p>
            </div>
        </td>
    </tr>
    <tr>
        <td>
            <div class="module">
                <a href="http://www.perl6.org/"><img alt="" src="//st.pimg.net/perlweb/images/icons/perl6.v8ff6c63.png" width="45" height="45" /></a>
                <h4>
                    <a href="http://www.perl6.org/">Perl 6</a>
                </h4>
                <p>
                    Perl 6 is a sister language, part of the Perl family. Perl 6 is not production ready yet, you can get involved with its <a href="/dev.html">development</a> though.
                </p>
            </div>
        </td>
        <td>
            <div class="module">
                <a href="http://www.perlfoundation.org/"><img alt="" src="//st.pimg.net/perlweb/images/icons/onion.vee5cb98.png" width="45" height="45" /></a>
                <h4>
                    <a href="http://www.perlfoundation.org/">The Perl Foundation</a>
                </h4>
                <p>
                    The Perl Foundation is dedicated to the advancement of the Perl programming language through open discussion, collaboration, design, and code.
                </p>
            </div>
        </td>
    </tr>
</table>

<div class="bar">&nbsp; &nbsp; &nbsp; &nbsp;</div>

<table class="content_table">
  <tr>
    <td>
        
        <ul>
        
            <li class="rss round">Latest Uploads to <a href="http://www.cpan.org/">CPAN</a></li>
        
            
                <li class="rss_content"><a href="http://metacpan.org/release/SKIM/Map-Tube-Moscow-0.03">Map-Tube-Moscow-0.03</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/GOMOR/Net-Routing-0.42">Net-Routing-0.42</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/RDRAKE/Net-ISC-DHCPd-0.1707">Net-ISC-DHCPd-0.1707</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/TECHMAN/WebService-Strava-0.04">WebService-Strava-0.04</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/DAPINK/DateTime-TimeZone-Local-Win32-1.81">DateTime-TimeZone-Local-Win32-1.81</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/SADAMS/Mojolicious-Plugin-MimeTypes-0.02">Mojolicious-Plugin-MimeTypes-0.02</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/PLICEASE/Yars-1.07">Yars-1.07</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/MOZNION/Perl-PrereqScanner-Lite-0.22">Perl-PrereqScanner-Lite-0.22</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/IRONCAMEL/WebService-Snapcard-0.0001">WebService-Snapcard-0.0001</a></li>
                
                
            
                <li class="rss_content"><a href="http://metacpan.org/release/PERLANCAR/Perinci-Access-0.40">Perinci-Access-0.40</a></li>
                
                
        </ul>
    </td>
    <td>
        
        <ul>
        
            <li class="rss round"><a href="http://perlnews.org/">Perl News</a></li>
        
            
                <li class="rss_content"><a href="http://feedproxy.google.com/~r/PerlNews/~3/IjSwneLRJ_g/">Perl QA Hackathon 2015</a></li>
                
                
            
                <li class="rss_content"><a href="http://feedproxy.google.com/~r/PerlNews/~3/yc6fvyDg1Eo/">Perl Track at FOSDEM 2015</a></li>
                
                
            
                <li class="rss_content"><a href="http://feedproxy.google.com/~r/PerlNews/~3/oedgSvhHLb8/">Test module updates – test your code now…</a></li>
                
                
            
                <li class="rss_content"><a href="http://feedproxy.google.com/~r/PerlNews/~3/Nih5amljrtY/">Advent Calendars</a></li>
                
                
            
                <li class="rss_content"><a href="http://feedproxy.google.com/~r/PerlNews/~3/AiYrH0GY8fs/">Perl and Shellshock</a></li>
                
                
        </ul>
    </td>
  </tr>
</table>


        </div>
        <div id="short_lists" class="short_lists">
            

            <div class="quick_links">
        <h4 class="round">
            Current Perl version
        </h4>
        <div class="list">
        
        <p><a href="/get.html">5.20.1 - download now</a></p>        
        
        </div>
</div>


            <div class="quick_links">
        <h4 class="round">
            Find out more
        </h4>
        <div class="list">
        
        <p><a href="/learn.html">Learn</a></p>        
        
        <p><a href="/docs.html">Documentation</a></p>        
        
        <p><a href="/community.html">Community</a></p>        
        
        <p><a href="/events.html">Events</a></p>        
        
        </div>
</div>

            

            
<div class="quick_links">
        <h4 class="round">
            Tip
        </h4>
        <div class="list">
        <p>
            <strong>Need a Job?</strong>
            <a href="http://jobs.perl.org/">jobs.perl.org</a> has the job for you!
        </p>
    </div>
</div>


            <div id="sponsor">
        <h4>
            <a href="/siteinfo.html#sponsors">Sponsor</a>
        </h4>
        <p>
          


<a href="http://www.yellowbot.com">
  <img class="border" border="0" src="//st.pimg.net/perlweb/images/friends/yellowbot.vcc29f5b.gif"
       width="150" height="40" alt="YellowBot" />Local Search
  </a>


        </p>
</div>


            <div id="spacer_for_google"></div>
            
        </div>
    </div>
</div>
<div style="clear:both"></div>

<div id="footer">
    <div class="sub_holder">
        

        <p class="sites">
            &nbsp;When you need <em>Perl</em> think <strong>Perl.org</strong>: <a href="http://www.perl.org/">www</a> | <a href="http://blogs.perl.org/">blogs</a> | <a href="http://jobs.perl.org/">jobs</a> | <a href="http://learn.perl.org/">learn</a> <!-- | <a href="http://lists.perl.org/">lists</a> --> | <a href="http://dev.perl.org/">dev</a>   
        </p>
        <p class="copyright">
            <a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/us/"><img alt="Creative Commons License" style="border-width:0" src="//st.pimg.net/perlweb/images/icons/creativecommons-by-nc-nd-3.0-us-80x15.v072f8cd.png" /></a> © 2002-2015 Perl.org | <a href="/siteinfo.html">Site Info</a>
        </p>


        <div style="clear:both"></div>
        <div id="google_translate_element"></div>
    </div>
</div>


<script type="text/javascript">
  (function(i,s,o,g,r,a,m){i[\'GoogleAnalyticsObject\']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,\'script\',\'//www.google-analytics.com/analytics.js\',\'ga\');

  ga(\'create\', \'UA-50555-1\', \'auto\');
  ga(\'require\', \'linkid\', \'linkid.js\');
  ga(\'set\', \'dimension1\', window.location.protocol);
  ga(\'send\', \'pageview\');
</script>
<script type="text/javascript" src="//st.pimg.net/cdn/libs/jquery/1.7.1/jquery.min.js" charset="UTF-8"></script>
<script type="text/javascript" src="//st.pimg.net/perlweb/js/jquery.corner.v84b7681.js" charset="UTF-8"></script>
<script type="text/javascript" src="//st.pimg.net/perlweb/js/leo.v6d3826a.js" charset="UTF-8"></script>



<script type="text/javascript">
function googleTranslateElementInit() {
          new google.translate.TranslateElement({
            pageLanguage: \'en\',
            autoDisplay: false
            ,
            gaTrack: true,
            gaId: \'UA-50555-1\'
                  }, \'google_translate_element\');
        }
</script>

<script src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit" type="text/javascript"></script>



</body>
</html>


',
                                   '_rc' => '200',
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'p3p' => 'CP="There\'s no P3P policy. Learn why here: http://www.w3.org/P3P/"',
                                                          'link' => [
                                                                      '<//st.pimg.net/perlweb/favicon.v249dfa7.ico>; rel="shortcut icon"',
                                                                      '<//st.pimg.net/perlweb/css/leostyle.v8cd7532.css>; rel="stylesheet"; type="text/css"',
                                                                      '<//st.pimg.net/perlweb/css/www.v1c370c5.css>; rel="stylesheet"; type="text/css"',
                                                                      '<https://www.perl.org/>; rel="canonical"'
                                                                    ],
                                                          'connection' => 'close',
                                                          'client-date' => 'Thu, 19 Feb 2015 15:09:56 GMT',
                                                          'x-served-by' => 'varnish2',
                                                          'x-varnish' => '1577799867',
                                                          'x-cache-hits' => '0',
                                                          'server' => 'NetDNA-cache/2.2',
                                                          'cache-control' => 'public, maxage=86400',
                                                          'x-cache' => [
                                                                         'MISS',
                                                                         'HIT'
                                                                       ],
                                                          '::std_case' => {
                                                                            'title' => 'Title',
                                                                            'x-cache' => 'X-Cache',
                                                                            'x-varnish' => 'X-Varnish',
                                                                            'x-cache-hits' => 'X-Cache-Hits',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'x-served-by' => 'X-Served-By',
                                                                            'link' => 'Link',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'p3p' => 'P3P',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'x-meta-description' => 'X-Meta-Description',
                                                                            'x-proxy' => 'X-Proxy'
                                                                          },
                                                          'title' => 'The Perl Programming Language - www.perl.org',
                                                          'last-modified' => 'Thu, 19 Feb 2015 08:57:13 GMT',
                                                          'x-meta-description' => 'The Perl Programming Language at Perl.org. Links and other helpful resources for new and experienced Perl programmers.',
                                                          'x-proxy' => 'proxy2',
                                                          'vary' => 'Accept-Encoding',
                                                          'date' => 'Thu, 19 Feb 2015 15:09:56 GMT',
                                                          'client-response-num' => 1,
                                                          'content-type' => 'text/html; charset=utf-8',
                                                          'age' => '0',
                                                          'client-peer' => '108.161.188.196:80',
                                                          'via' => '1.1 varnish'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'OK'
                                 }, 'HTTP::Response' ),
            'request' => {}
          }
        ];
$VAR1->[0]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[0]{'response'}{'_request'}{'_uri'};
$VAR1->[0]{'request'} = $VAR1->[0]{'response'}{'_request'};
$VAR1->[1]{'response'}{'_request'}{'_uri'} = $VAR1->[1]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[1]{'request'} = $VAR1->[1]{'response'}{'_request'};
$VAR1->[2]{'request'}{'_uri'} = $VAR1->[2]{'request'}{'_uri_canonical'};
$VAR1->[2]{'response'}{'_request'} = $VAR1->[2]{'request'};
$VAR1->[3]{'request'}{'_uri'} = $VAR1->[3]{'request'}{'_uri_canonical'};
$VAR1->[3]{'response'}{'_request'} = $VAR1->[3]{'request'};
$VAR1->[4]{'response'}{'_request'}{'_uri'} = $VAR1->[4]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[4]{'request'} = $VAR1->[4]{'response'}{'_request'};
$VAR1->[5]{'response'}{'_request'}{'_uri'} = $VAR1->[5]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[5]{'request'} = $VAR1->[5]{'response'}{'_request'};

