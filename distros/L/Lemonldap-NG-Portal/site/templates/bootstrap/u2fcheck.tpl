<TMPL_INCLUDE NAME="header.tpl">

<div class="container">

<TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
</TMPL_IF>
<TMPL_IF NAME="DATA">
  <div class="message message-positive alert"><span trspan="touchU2fDevice"></span></div>
  <form id="verify-form" action="/u2fcheck" method="post">
    <input type="hidden" id="verify-data" name="signature" value="" />
    <input type="hidden" id="verify-challenge" name="challenge" value="" />
    <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
    <input type="hidden" id="stayconnected" name="stayconnected" value="<TMPL_VAR NAME="STAYCONNECTED">" />
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
  </form>
  <script type="application/init">
  <TMPL_VAR NAME="DATA">
  </script>
<!-- //if:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/u2f-api.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/u2fcheck.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/u2f-api.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/u2fcheck.js"></script>
<!-- //endif -->
</TMPL_IF>

</div>

<div class="buttons">
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>
</div>

<TMPL_INCLUDE NAME="footer.tpl">

