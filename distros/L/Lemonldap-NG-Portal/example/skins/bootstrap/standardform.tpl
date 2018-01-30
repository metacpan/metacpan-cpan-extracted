<div class="form">
  <div class="form-group input-group">
    <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i> </span>
    <input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">" class="form-control" placeholder="<lang en="Login" fr="Identifiant"/>" required />
  </div>

  <div class="form-group input-group">
    <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
    <input name="password" type="password" class="form-control" placeholder="<lang en="Password" fr="Mot de passe"/>" required />
  </div>

  <TMPL_IF NAME=CAPTCHA_IMG>
  <div class="form-group">
    <img src="<TMPL_VAR NAME=CAPTCHA_IMG>" class="img-thumbnail" />
  </div>
  <div class="form-group input-group">
    <span class="input-group-addon"><i class="glyphicon glyphicon-eye-open"></i> </span>
    <input type="text" name="captcha_user_code" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" class="form-control" placeholder="Captcha" required />
  </div>
  <input type="hidden" name="captcha_code" value="<TMPL_VAR NAME=CAPTCHA_CODE>" />
  </TMPL_IF>

  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="glyphicon glyphicon-log-in"></span>
    <lang en="Connect" fr="Se connecter" />
  </button>
</div>

<div class="actions">
  <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
  <a class="btn btn-info" href="<TMPL_VAR NAME="MAIL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
    <span class="glyphicon glyphicon-info-sign"></span>
    <lang en="Reset my password" fr="R&eacute;initialiser mon mot de passe"/>
  </a>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_REGISTER">
  <a class="btn btn-warning" href="<TMPL_VAR NAME="REGISTER_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
    <span class="glyphicon glyphicon-plus-sign"></span>
    <lang en="Create an account" fr="Cr&eacute;er un compte"/>
  </a>
  </TMPL_IF>
</div>
