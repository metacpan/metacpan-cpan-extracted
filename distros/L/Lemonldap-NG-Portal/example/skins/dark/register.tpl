<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>
  </TMPL_IF>

  <div class="loginlogo"></div>

  <TMPL_IF NAME="DISPLAY_FORM">

    <form action="#" method="post" class="login">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>

      <h3><lang en="Create an account" fr="Créer un compte"/></h3>

      <table>
        <tr>
          <th><lang en="First name" fr="Prénom"/></th>
          <td><input name="firstname" type="text" value="<TMPL_VAR NAME="FIRSTNAME">"/></td>
        </tr>

        <tr>
          <th><lang en="Last name" fr="Nom"/></th>
          <td><input name="lastname" type="text" value="<TMPL_VAR NAME="LASTNAME">"/></td>
        </tr>

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
              <lang en="Submit" fr="Envoyer" />
            </button>
          </div>
        </td></tr>
      </table>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_RESEND_FORM">

    <form action="#" method="post" class="login">

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

      <p>
        <lang en="A register request for this account was already issued on " fr="Une demande de création pour ce compte a déjà été faite le " />
        <TMPL_VAR NAME="STARTMAILDATE">.
        <lang en="Do you want the confirmation mail to be resent?" fr="Voulez-vous que le message de confirmation soit renvoyé ?" />
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

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <form action="#" method="post" class="login">
      <h3>
        <lang en="A message has been sent to your mail address." fr="Un message a été envoyé à votre adresse mail." />
      </h3>
      <p>
        <lang en="A confirmation link has been sent, this link is valid until " fr="Un lien de confirmation a été envoyé, ce lien est valide jusqu'au " />
        <TMPL_VAR NAME="EXPMAILDATE">.
      </p>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <form action="#" method="post" class="login">
      <h3>
        <lang en="Your account has been created, your temporary password has been sent to your mail address." fr="Votre compte a été créé, un mot de passe temporaire a été envoyé à votre adresse mail." />
      </h3>
    </form>
  </TMPL_IF>

  <div class="link">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN">">
      <lang en="Go back to portal" fr="Retourner au portail" />
    </a>
  </div>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
