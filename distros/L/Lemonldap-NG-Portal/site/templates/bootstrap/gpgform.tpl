<span trspan="Please sign the following text with your GPG key"></span>
<pre>echo -n "<TMPL_VAR NAME="TOKEN">"| gpg --clear-sign</pre>
<div class="form">
  <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><label for="userfield" class="mb-0"><i class="fa fa-user"></i></label></span>
    </div>
    <input id="userfield" name="user" type="text" class="form-control" value="<TMPL_VAR NAME="LOGIN" ESCAPE=HTML>" trplaceholder="mail" required aria-required="true" />
  </div>

  <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><label for="passwordfield" class="mb-0"><i class="fa fa-lock"></i></label></span>
    </div>
    <textarea id="passwordfield" name="password" class="form-control" trplaceholder="Signed text" required aria-required="true"></textarea>
  </div>

  <TMPL_IF NAME=CAPTCHA_HTML>
    <TMPL_VAR NAME=CAPTCHA_HTML>
  </TMPL_IF>
  <input id="token" type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </button>
</div>

<div class="actions">
  <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
  <a class="btn btn-secondary" href="<TMPL_VAR NAME="MAIL_URL"><TMPL_UNLESS NAME="MAIL_URL_EXTERNAL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF></TMPL_UNLESS>">
    <span class="fa fa-info-circle"></span>
    <span trspan="resetPwd">Reset my password</span>
  </a>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_UPDATECERTIF">
     <a class="btn btn-secondary" href="<TMPL_VAR NAME="MAILCERTIF_URL"><TMPL_UNLESS NAME="MAILCERTIF_URL_EXTERNAL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF></TMPL_UNLESS>">
        <span class="fa fa-refresh"></span>
        <span trspan="certificateReset">Reset my certificate</span>
     </a>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_FINDUSER">
    <button type="button" class="btn btn-secondary" data-toggle="modal" data-target="#finduserModal">
      <span class="fa fa-search"></span>
      <span trspan="searchAccount">Search for an account</span>
    </button>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_REGISTER">
    <a class="btn btn-secondary" href="<TMPL_VAR NAME="REGISTER_URL"><TMPL_UNLESS NAME="REGISTER_URL_EXTERNAL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF></TMPL_UNLESS>">
      <span class="fa fa-plus-circle"></span>
      <span trspan="createAccount">Create an account</span>
    </a>
  </TMPL_IF>
</div>
