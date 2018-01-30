<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <lang en="Create an account" fr="Cr&eacute;er un compte"/>
      </div>
      <hr class="solid" />
      <TMPL_IF NAME="AUTH_ERROR">
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_FORM">
      <form action="#" method="post" class="login">
      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <div id="content-all-info">
        <table>
          <tr>
            <th><lang en="First name" fr="Pr&eacute;nom"/></th>
            <td><input name="firstname" type="text" value="<TMPL_VAR NAME="FIRSTNAME">"/></td>
          </tr>
          <tr>
            <th><lang en="Last name" fr="Nom"/></th>
            <td><input name="lastname" type="text" value="<TMPL_VAR NAME="LASTNAME">"/></td>
          </tr>
          <tr>
            <th><lang en="Mail" fr="Adresse mail"/></th>
            <td><input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" /></td>
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
          <tr>
            <td colspan="2">
              <div class="buttons">
                <button type="submit" class="positive">
                  <lang en="Submit" fr="Envoyer" />
                </button>
              </div>
            </td>
          </tr>
        </table>
      </div>
      </form>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_RESEND_FORM">
      <form action="#" method="post" class="login">
      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
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
      <div id="content-all-info">
        <p>
        <lang en="A register request for this account was already issued on " fr="Une demande de cr&eacute;ation pour ce compte a d&eacute;j&agrave; &eacute;t&eacute; faite le " />
        <TMPL_VAR NAME="STARTMAILDATE">.
        <lang en="Do you want the confirmation mail to be resent?" fr="Voulez-vous que le message de confirmation soit renvoy&eacute; ?" />
        </p>
        <table>
          <tr>
            <th><input id="resendconfirmation" type="checkbox" name="resendconfirmation"></th>
            <td><lang en="Yes, resend the mail" fr="Oui, renvoyer le mail"/></td>
          </tr>
          <tr>
            <td colspan="2">
              <div class="buttons">
                <button type="submit" class="positive">
                  <lang en="Submit" fr="Valider" />
                </button>
              </div>
            </td>
          </tr>
        </table>
      </div>
      </form>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
      <div id="content-all-info">
      <lang en="A message has been sent to your mail address." fr="Un message a &eacute;t&eacute; envoy&eacute; &agrave; votre adresse mail." />
      <lang en="A confirmation link has been sent, this link is valid until " fr="Un lien de confirmation a &eacute;t&eacute; envoy&eacute;, ce lien est valide jusqu'au " />
      <TMPL_VAR NAME="EXPMAILDATE">.
      </div>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_MAILSENT">
      <div id="content-all-info">
      <lang en="Your account has been created, your temporary password has been sent to your mail address." fr="Votre compte a &eacute;t&eacute; cr&eacute;&eacute;, un mot de passe temporaire a &eacute;t&eacute; envoy&eacute; &agrave; votre adresse mail." />
      </div>
      </TMPL_IF>

      <div class="panel-buttons">
        <button type="button" class="positive" tabindex="1" onclick="location.href='<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="CHOICE_VALUE">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="CHOICE_VALUE"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>';return false;">
          <lang en="Go to portal" fr="Aller au portail" />
        </button>
      </div>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">
