 <!-- Load javascript common to all skins -->
 <!-- //if:usedebianlibs
  <script type="text/javascript" src="/javascript/jquery/jquery.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="/javascript/jquery-ui/jquery-ui.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="/javascript/jquery-cookie/jquery.cookie.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//elsif:useexternallibs
  <script type="text/javascript" src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
  <script type="text/javascript" src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>
  <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.4.1/jquery.cookie.min.js"></script>
 //elsif:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery-ui/jquery-ui.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery.cookie/jquery.cookie.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
 //else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery-ui/jquery-ui.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery.cookie/jquery.cookie.js?v=<TMPL_VAR CACHE_TAG>"></script>
 <!-- //endif -->

 <TMPL_IF NAME="DISPLAY_PPOLICY">
 <!-- //if:jsminified
 <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/ppolicy.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
 //else -->
 <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/ppolicy.js?v=<TMPL_VAR CACHE_TAG>"></script>
 <!-- //endif -->
 </TMPL_IF>

 <script type="application/init">
 {
 "choicetab":"<TMPL_VAR NAME="CHOICE_VALUE">",
 "language": "<TMPL_VAR NAME="LANGUAGE">",
 "newwindow":<TMPL_VAR NAME="NEWWINDOW" DEFAULT="0">,
 "appslistorder":"<TMPL_VAR NAME="APPSLIST_ORDER">",
 "activeTimer":<TMPL_VAR NAME="ACTIVE_TIMER" DEFAULT="0">,
 "pingInterval":<TMPL_VAR NAME="PING" DEFAULT="0">,
 "trOver":<TMPL_VAR NAME="TROVER" DEFAULT="[]">,<TMPL_IF NAME="DISPLAY_PPOLICY">
 "ppolicy": {
            "display": "<TMPL_VAR NAME="DISPLAY_PPOLICY" DEFAULT="0">",
            "minsize": "<TMPL_VAR NAME="PPOLICY_MINSIZE" DEFAULT="0">",
            "maxsize": "<TMPL_VAR NAME="PPOLICY_MAXSIZE" DEFAULT="0">",
            "minlower": "<TMPL_VAR NAME="PPOLICY_MINLOWER" DEFAULT="0">",
            "minupper": "<TMPL_VAR NAME="PPOLICY_MINUPPER" DEFAULT="0">",
            "mindigit": "<TMPL_VAR NAME="PPOLICY_MINDIGIT" DEFAULT="0">",
            "nopolicy": "<TMPL_VAR NAME="PPOLICY_NOPOLICY" DEFAULT="0">",
            "allowedspechar": <TMPL_VAR NAME="PPOLICY_ALLOWEDSPECHAR_JSON" DEFAULT='""'>,
            "minspechar": "<TMPL_VAR NAME="PPOLICY_MINSPECHAR" DEFAULT="0">"
            },</TMPL_IF>
 "enablePasswordDisplay":<TMPL_VAR NAME="ENABLE_PASSWORD_DISPLAY" DEFAULT="0">,
 "dontStorePassword":<TMPL_VAR NAME="DONT_STORE_PASSWORD" DEFAULT="0">,
 "scrollTop":<TMPL_VAR NAME="SCROLL_TOP" DEFAULT="0">,
 "floatingCategory":"<TMPL_VAR NAME="FLOATING_CAT">",
 "sameSite":"<TMPL_VAR NAME="SAMESITE">",
 "cookieSecure":<TMPL_VAR NAME="COOKIESECURE">
 }
 </script>

