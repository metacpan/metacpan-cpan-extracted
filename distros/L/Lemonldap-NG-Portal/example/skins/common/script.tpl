 <!-- Load javascript common to all skins -->
 <!-- //if:usedebianlibs
  <script type="text/javascript" src="/javascript/jquery/jquery.min.js"></script>
  <script type="text/javascript" src="/javascript/jquery-ui/jquery-ui.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.base64.min.js"></script>
  <script type="text/javascript" src="/javascript/jquery-cookie/jquery.cookie.min.js"></script>
//elsif:useexternallibs
  <script type="text/javascript" src="http://code.jquery.com/jquery-2.2.0.min.js"></script>
  <script type="text/javascript" src="http://code.jquery.com/ui/1.10.4/jquery-ui.min.js"></script>
  <script type="text/javascript" src="https://javascriptbase64.googlecode.com/files/base64.js"></script>
  <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.4.1/jquery.cookie.min.js"></script>
 //elsif:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-1.10.2.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-ui-1.10.3.custom.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.base64.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.cookie.min.js"></script>
 //else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-1.10.2.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-ui-1.10.3.custom.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.base64.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.cookie.js"></script>
 <!-- //endif -->
 <TMPL_IF NAME="browserIdEnabled">
   <script src="https://login.persona.org/include.js"></script>
  <!-- //endif -->
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLoginScript">
  <script type="text/javascript">//<![CDATA[
     var browserIdSiteName="<TMPL_VAR NAME="browserIdSiteName">";
     var browserIdSiteLogo="<TMPL_VAR NAME="browserIdSiteLogo">";
     var browserIdBackgroundColor="<TMPL_VAR NAME="browserIdBackgroundColor">";
     var browserIdAutoLogin="<TMPL_VAR NAME="browserIdAutoLogin">";
  //]]></script>
  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.min.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogin.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogin.js"></script>
  <!-- //endif -->
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLogoutScript">
  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.min.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogout.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogout.js"></script>
  <!-- //endif -->
 </TMPL_IF>
 <script type="text/javascript">//<![CDATA[
    var displaytab="<TMPL_VAR NAME="DISPLAY_TAB">";
    var choicetab="<TMPL_VAR NAME="CHOICE_VALUE">";
    var login="<TMPL_VAR NAME="LOGIN">";
    var newwindow="<TMPL_VAR NAME="NEWWINDOW">";
    var antiframe="<TMPL_VAR NAME="ANTIFRAME">";
    var appslistorder="<TMPL_VAR NAME="APPSLIST_ORDER">";
    var scriptname="<TMPL_VAR NAME="SCRIPT_NAME">";
    var activeTimer="<TMPL_VAR NAME="ACTIVE_TIMER">";
    var pingInterval=parseInt("<TMPL_VAR NAME="PING">");
 //]]></script>

