<TMPL_INCLUDE NAME="header.tpl">

<main id="logincontent" class="container">

<TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
<TMPL_ELSE>
<div class="message message-positive alert"><span trspan="enterPassword">Enter your password</span></div>
</TMPL_IF>

<div class="card">

<form action="/password2fcheck" method="post" class="password" role="form">
  <div class="form">
    <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
    <input type="hidden" id="stayconnected" name="stayconnected" value="<TMPL_VAR NAME="STAYCONNECTED">" />
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="password" class="mb-0"><i class="fa fa-lock"></i></label></span>
      </div>
      <input name="password" value="" type="password" class="form-control" id="password2f" trplaceholder="password" />
    </div>
  </div>
  <div class="buttons mb-3">
    <button type="submit" class="btn btn-success">
      <span class="fa fa-sign-in"></span>
      <span trspan="connect">Connect</span>
    </button>
  </div>
  <div class="buttons">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-primary" role="button">
      <span class="fa fa-home"></span>
      <span trspan="cancel">Cancel</span>
    </a>
  </div>
</form>
</div>
</main>

<TMPL_INCLUDE NAME="footer.tpl">
