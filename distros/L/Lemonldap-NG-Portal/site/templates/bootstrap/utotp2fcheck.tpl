<TMPL_INCLUDE NAME="header.tpl">

<main id="logincontent" class="container">

<TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
</TMPL_IF>

<div class="card">

<TMPL_IF NAME="FAILED">
  <p trspan="u2fFailed"></p>
</TMPL_IF>

<TMPL_IF NAME="AUTH_ERROR">
  <div class="buttons">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
      <span class="fa fa-home"></span>
      <span trspan="goToPortal">Go to portal</span>
    </a>
  </div>
<TMPL_ELSE>
 <form id="verify-form" action="/utotp2fcheck" method="post">
  <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
  <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
  <input type="hidden" id="stayconnected" name="stayconnected" value="<TMPL_VAR NAME="STAYCONNECTED">" />
  <TMPL_IF NAME="DATA">
   <div class="message message-positive alert">
    <span trspan="touchU2fDeviceOrEnterTotp"></span>
   </div>
    <input type="hidden" id="verify-data" name="signature" value="" />
    <input type="hidden" id="verify-challenge" name="challenge" value="" />
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
  <TMPL_ELSE>
   <div class="message message-positive alert">
       <span trspan="enterTotpCode"></span>
   </div>
  </TMPL_IF>
  <div class="form">
   <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><label for="extcode" class="mb-0"><i class="fa fa-lock"></i></label></span>
    </div>
    <input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />
   </div>
  </div>
  <div class="buttons mb-3">
   <button type="submit" class="btn btn-success">
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
   </button>
  </div>
  <div class="buttons">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
      <span class="fa fa-home"></span>
      <span trspan="cancel">Cancel</span>
    </a>
  </div>
  <br>
 </form>
</TMPL_IF>

</div>
</main>

<TMPL_INCLUDE NAME="footer.tpl">

