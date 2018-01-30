<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>
  </TMPL_IF>

  <div class="loginlogo"></div>

  <TMPL_IF NAME="DISPLAY_FORM">

    <form action="#" method="post" class="login">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>

      <h3><lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/></h3>

      <table>
        <tr>
          <th><lang en="Mail" fr="Adresse mail"/></th>
          <td><input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">"/></td>
        </tr>

        <TMPL_IF NAME=CAPTCHA_IMG>
          <tr><td></td><td>
            <img src="<TMPL_VAR NAME=CAPTCHA_IMG>" />
          </td></tr>
          <tr><th><lang en="Captcha" fr="Captcha" /></th>
            <td><input type="text" name="captcha_user_code" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" />
            <input type="hidden" name="captcha_code" value="<TMPL_VAR NAME=CAPTCHA_CODE>" /></td>
          </tr>
        </TMPL_IF>

        <tr><td colspan="2">
          <div class="buttons">
            <button type="submit" class="positive">
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
              <lang en="Send me a new password" fr="Envoyez-moi un nouveau mot de passe" />
            </button>
          </div>
        </td></tr>
      </table>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_RESEND_FORM">

    <form action="#" method="post" class="login">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <TMPL_IF NAME="MAIL">
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      </TMPL_IF>

      <h3><lang en="Resend confirmation mail?" fr="Renvoyer le mail de confirmation ?"/></h3>

      <p>
        <lang en="A password reset request was already issued on " fr="Une demande de r&eacute;initialisation de mot de passe a d&eacute;j&agrave; &eacute;t&eacute; faite le " />
        <TMPL_VAR NAME="STARTMAILDATE">.
        <lang en="Do you want the confirmation mail to be resent?" fr="Voulez-vous que le message de confirmation soit renvoy&eacute; ?" />
      </p>

      <table>
        <tr><th><input id="resendconfirmation" type="checkbox" name="resendconfirmation"></th>
          <td><lang en="Yes, resend the mail" fr="Oui, renvoyer le mail"/></td>
        </tr>
        <tr><td colspan="2">
          <div class="buttons">
            <button type="submit" class="positive">
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
              <lang en="Submit" fr="Valider" />
            </button>
          </div>
        </td></tr>
      </table>

    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_PASSWORD_FORM">
    <div id="password">
      <form action="#" method="post" class="password">
        <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
        <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
        <TMPL_IF NAME="CHOICE_VALUE">
          <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        </TMPL_IF>
        <TMPL_IF NAME="MAIL_TOKEN">
          <input type="hidden" id="mail_token" name="mail_token" value="<TMPL_VAR NAME="MAIL_TOKEN">" />
        </TMPL_IF>
        <h3><lang en="Change your password" fr="Changez votre mot de passe" /></h3>
        <table>
          <tr><th><lang en="New password" fr="Nouveau mot de passe" /></th>
            <td><input name="newpassword" type="password" tabindex="3" /></td></tr>
          <tr><th><lang en="Confirm password" fr="Confirmez le mot de passe" /></th>
            <td><input name="confirmpassword" type="password" tabindex="4" /></td></tr>
          <tr><td colspan="2">
            <input id="reset" type="checkbox" name="reset" />
            <lang en="Generate the password automatically" fr="G&eacute;n&eacute;rer le mot de passe automatiquement" />
          </td></tr>
          <tr><td colspan="2">
            <div class="buttons">
              <button type="reset" class="negative" tabindex="6">
                <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
                <lang en="Cancel" fr="Annuler" />
              </button>
              <button type="submit" class="positive" tabindex="5">
                <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
                <lang en="Submit" fr="Soumettre" />
              </button>
            </div>
          </td></tr>
        </table>
      </form>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <form action="#" method="post" class="login">
      <h3>
        <lang en="A message has been sent to your mail address." fr="Un message a &eacute;t&eacute; envoy&eacute; &agrave; votre adresse mail." />
      </h3>
      <p>
        <lang en="This message contains a link to reset your password, this link is valid until " fr="Ce message contient un lien pour r&eacute;initialiser votre mot de passe, ce lien est valide jusqu'au " />
        <TMPL_VAR NAME="EXPMAILDATE">.
      </p>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <form action="#" method="post" class="login">
      <h3>
        <lang en="A confirmation has been sent to your mail address." fr="Une confirmation a &eacute;t&eacute; envoy&eacute;e &agrave; votre adresse mail." />
      </h3>
    </form>
  </TMPL_IF>

  <div class="link">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="CHOICE_VALUE">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="CHOICE_VALUE"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
      <lang en="Go back to portal" fr="Retourner au portail" />
    </a>
  </div>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
