<TMPL_INCLUDE NAME="header.tpl">

<div class="container">

<TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
</TMPL_IF>
<TMPL_IF NAME="DATA">
  <div id="color" class="message message-positive alert"><span id="msg" trspan="webAuthnRequired"></span></div>
  <form id="verify-form" action="/webauthn2fcheck" method="post">
    <input type="hidden" id="credential" name="credential" value="" />
    <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
    <input type="hidden" id="stayconnected" name="stayconnected" value="<TMPL_VAR NAME="STAYCONNECTED">" />
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
  </form>
  <script type="application/init">
  <TMPL_VAR NAME="DATA">
  </script>
</TMPL_IF>

</div>

<div class="buttons">
  <div class="btn btn-primary" role="button" id="retrybutton">
    <span class="fa fa-repeat"></span>
    <span trspan="retry">Retry</span>
  </div>
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-secondary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>
</div>

<TMPL_INCLUDE NAME="footer.tpl">

