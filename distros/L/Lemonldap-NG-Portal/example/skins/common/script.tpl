 <!-- Load javascript common to all skins -->
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-1.10.2.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery-ui-1.10.3.custom.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.base64.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/jquery.cookie.js"></script>
 <TMPL_IF NAME="browserIdEnabled">
  <script src="https://login.persona.org/include.js"></script>
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLoginScript">
  <script type="text/javascript">//<![CDATA[
     var browserIdSiteName="<TMPL_VAR NAME="browserIdSiteName">";
     var browserIdSiteLogo="<TMPL_VAR NAME="browserIdSiteLogo">";
     var browserIdBackgroundColor="<TMPL_VAR NAME="browserIdBackgroundColor">";
     var browserIdAutoLogin="<TMPL_VAR NAME="browserIdAutoLogin">";
  //]]></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogin.js"></script>
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLogoutScript">
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browserid.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/browseridlogout.js"></script>
 </TMPL_IF>
 <script type="text/javascript">//<![CDATA[
    var displaytab="<TMPL_VAR NAME="DISPLAY_TAB">";
    var choicetab="<TMPL_VAR NAME="CHOICE_VALUE">";
    var autocomplete="<TMPL_VAR NAME="AUTOCOMPLETE">";
    var login="<TMPL_VAR NAME="LOGIN">";
    var newwindow="<TMPL_VAR NAME="NEWWINDOW">";
    var antiframe="<TMPL_VAR NAME="ANTIFRAME">";
    var appslistorder="<TMPL_VAR NAME="APPSLIST_ORDER">";
    var scriptname="<TMPL_VAR NAME="SCRIPT_NAME">";
    var activeTimer="<TMPL_VAR NAME="ACTIVE_TIMER">";
    var pingInterval=parseInt("<TMPL_VAR NAME="PING">");
 //]]></script>

