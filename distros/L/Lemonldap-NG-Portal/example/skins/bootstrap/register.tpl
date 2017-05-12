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

    <div class="form-group input-group">
      <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i> </span>
      <input name="firstname" type="text" value="<TMPL_VAR NAME="FIRSTNAME">" class="form-control" placeholder="<lang en="First name" fr="Prénom"/>" required />
    </div>

    <div class="form-group input-group">
      <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i> </span>
      <input name="lastname" type="text" value="<TMPL_VAR NAME="LASTNAME">" class="form-control" placeholder="<lang en="Last name" fr="Nom"/>" required />
    </div>

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
      <span class="glyphicon glyphicon-ok"></span>
      <lang en="Submit" fr="Envoyer" />
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
      <TMPL_IF NAME="FIRSTNAME">
        <input type="hidden" value="<TMPL_VAR NAME="FIRSTNAME">" name="firstname">
      </TMPL_IF>
      <TMPL_IF NAME="LASTNAME">
        <input type="hidden" value="<TMPL_VAR NAME="LASTNAME">" name="lastname">
      </TMPL_IF>
      <TMPL_IF NAME="MAIL">
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      </TMPL_IF>

      <h3><lang en="Resend confirmation mail?" fr="Renvoyer le mail de confirmation ?"/></h3>

      <p class="alert alert-info">
        <lang en="A register request for this account was already issued on " fr="Une demande de création pour ce compte a déjà été faite le " />
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

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3>
        <lang en="A message has been sent to your mail address." fr="Un message a été envoyé à votre adresse mail." />
      </h3>
      <p class="alert alert-info">
        <lang en="A confirmation link has been sent, this link is valid until " fr="Un lien de confirmation a été envoyé, ce lien est valide jusqu'au " />
        <TMPL_VAR NAME="EXPMAILDATE">.
      </p>
    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3>
        <lang en="Your account has been created, your temporary password has been sent to your mail address." fr="Votre compte a été créé, un mot de passe temporaire a été envoyé à votre adresse mail." />
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
