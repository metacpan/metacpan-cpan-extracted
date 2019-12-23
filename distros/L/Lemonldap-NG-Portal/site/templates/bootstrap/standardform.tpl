<TMPL_IF NAME="TOKEN">
<input id="token" type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
</TMPL_IF>

<TMPL_IF NAME="WAITING_MESSAGE">
<div class="alert alert-info"><span trspan="waitingmessage" /></div>
<TMPL_ELSE>
<div class="form">
  <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><i class="fa fa-user"></i> </span>
    </div>
    <input name="user" type="text" class="form-control" value="<TMPL_VAR NAME="LOGIN">" trplaceholder="login" required aria-required="true"/>
  </div>

  <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><i class="fa fa-lock"></i> </span>
    </div>
    <TMPL_IF NAME="DONT_STORE_PASSWORD">
      <input name="password" type="text" class="form-control key" autocomplete="off" required aria-required="true" aria-hidden="true"/>
    <TMPL_ELSE>
      <input name="password" type="password" class="form-control" trplaceholder="password" required aria-required="true"/>
    </TMPL_IF>
  </div>

  <TMPL_IF NAME=CAPTCHA_SRC>
    <TMPL_INCLUDE NAME="captcha.tpl">
  </TMPL_IF>

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </button>
</div>
</TMPL_IF>

<div class="actions">
  <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
  <a class="btn btn-secondary" href="<TMPL_VAR NAME="MAIL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
    <span class="fa fa-info-circle"></span>
    <span trspan="resetPwd">Reset my password</span>
  </a>
  </TMPL_IF>
 
  <TMPL_IF NAME="DISPLAY_UPDATECERTIF">
     <a class="btn btn-primary" href="<TMPL_VAR NAME="MAILCERTIF_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
        <span class="fa fa-refresh"></span>
        <span trspan="certificateReset">Reset my certificate</span>
     </a>
   </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_REGISTER">
  <a class="btn btn-secondary" href="<TMPL_VAR NAME="REGISTER_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
    <span class="fa fa-plus-circle"></span>
    <span trspan="createAccount">Create an account</span>
  </a>
  </TMPL_IF>
</div>
