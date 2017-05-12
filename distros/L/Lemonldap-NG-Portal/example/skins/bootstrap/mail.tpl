<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><TMPL_VAR NAME="AUTH_ERROR"></div>
  </TMPL_IF>

  <div class="panel panel-default">

  <TMPL_IF NAME="DISPLAY_FORM">

    <form action="#" method="post" class="login" role="form">
    <div class="form">

    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>

    <h3><lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/></h3>

    <div class="form-group input-group">
      <span class="input-group-addon"><i class="glyphicon glyphicon-envelope"></i> </span>
      <input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" class="form-control" placeholder="<lang en="Mail" fr="Adresse mail"/>" required />
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

    <button type="submit" class="btn btn-success" >
      <span class="glyphicon glyphicon-send"></span>
      <lang en="Send me a new password" fr="Envoyez-moi un nouveau mot de passe" />
    </button>
    
    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_RESEND_FORM">

    <form action="#" method="post" class="login" role="form">
    <div class="form">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <TMPL_IF NAME="MAIL">
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      </TMPL_IF>

      <h3><lang en="Resend confirmation mail?" fr="Renvoyer le mail de confirmation ?"/></h3>

      <p class="alert alert-info">
        <lang en="A password reset request was already issued on " fr="Une demande de réinitialisation de mot de passe a déjà été faite le " />
        <TMPL_VAR NAME="STARTMAILDATE">.
        <lang en="Do you want the confirmation mail to be resent?" fr="Voulez-vous que le message de confirmation soit renvoyé ?" />
      </p>


      <div class="checkbox">
        <label for="resendconfirmation">
          <input id="resendconfirmation" type="checkbox" name="resendconfirmation">
          <lang en="Yes, resend the mail" fr="Oui, renvoyer le mail"/>
        </label>
      </div>

      <div class="form-group">
        <button type="submit" class="btn btn-success">
          <lang en="Submit" fr="Valider" />
        </button>
      </div>

    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_PASSWORD_FORM">
    <div id="password">
      <form action="#" method="post" class="password" role="form">
      <div class="form">

        <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
        <TMPL_IF NAME="CHOICE_VALUE">
          <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        </TMPL_IF>

        <TMPL_IF NAME="MAIL_TOKEN">
          <input type="hidden" id="mail_token" name="mail_token" value="<TMPL_VAR NAME="MAIL_TOKEN">" />
        </TMPL_IF>

        <h3><lang en="Change your password" fr="Changez votre mot de passe" /></h3>

        <div class="form-group input-group">
          <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
          <input name="newpassword" type="password" class="form-control" placeholder="<lang en="New password" fr="Nouveau mot de passe" />" />
        </div>

        <div class="form-group input-group">
          <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
          <input name="confirmpassword" type="password" class="form-control" placeholder="<lang en="Confirm password" fr="Confirmez le mot de passe" />" />
        </div>

        <div class="checkbox">
          <label for="reset">
            <input id="reset" type="checkbox" name="reset" />
            <lang en="Generate the password automatically" fr="Générer le mot de passe automatiquement" />
          </label>
        </div>

        <div class="form-group">
          <button type="submit" class="btn btn-success">
            <lang en="Submit" fr="Soumettre" />
          </button>
        </div>

      </div>
      </form>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3>
        <lang en="A message has been sent to your mail address." fr="Un message a été envoyé à votre adresse mail." />
      </h3>
      <p class="alert alert-info">
        <lang en="This message contains a link to reset your password, this link is valid until " fr="Ce message contient un lien pour réinitialiser votre mot de passe, ce lien est valide jusqu'au " />
        <TMPL_VAR NAME="EXPMAILDATE">.
      </p>
    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3>
        <lang en="A confirmation has been sent to your mail address." fr="Une confirmation a &eacute;t&eacute; envoy&eacute;e &agrave; votre adresse mail." />
      </h3>
    </div>
    </form>
  </TMPL_IF>

  </div>

  <div class="buttons">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN">" class="btn btn-primary" role="button">
      <span class="glyphicon glyphicon-home"></span>
      <lang en="Go back to portal" fr="Retourner au portail" />
    </a>
  </div>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
