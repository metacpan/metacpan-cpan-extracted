<h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>

<table>
  <tr><th><lang en="Login" fr="Identifiant"/></th>
    <td><input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">" tabindex="1" /></td>
  </tr>
  <tr><th><lang en="Password" fr="Mot de passe"/></th>
    <td><input name="password" type="password" tabindex="2" /></td>
  </tr>

  <TMPL_IF NAME=CAPTCHA_IMG>
    <tr><td></td><td>
      <img src="<TMPL_VAR NAME=CAPTCHA_IMG>" />
    </td></tr>
    <tr><th><lang en="Captcha" fr="Captcha" /></th>
      <td><input type="text" name="captcha_user_code" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" tabindex="3" />
      <input type="hidden" name="captcha_code" value="<TMPL_VAR NAME=CAPTCHA_CODE>" /></td>
    </tr>
  </TMPL_IF>

  <TMPL_IF NAME="CHECK_LOGINS">
    <tr><td colspan="2"><div class="buttons">
      <label for="checkLogins">
        <input type="checkbox" id="checkLogins" name="checkLogins" <TMPL_IF NAME="ASK_LOGINS">checked</TMPL_IF> tabindex="4" />
        <lang en="Check my last logins" fr="Voir mes derni&egrave;res connexions"/>
      </label>
    </div></td></tr>
  </TMPL_IF>

  <tr><td colspan="2">
    <div class="buttons">
      <button type="reset" class="negative" tabindex="10">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
        <lang en="Cancel" fr="Annuler" />
      </button>
      <button type="submit" class="positive" tabindex="8">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
        <lang en="Connect" fr="Se connecter" />
      </button>
    </div>
  </td></tr>

  <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
    <tr><td colspan="2">
      <div class="buttons">
        <a class="positive" tabindex="5" href="<TMPL_VAR NAME="MAIL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF>">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/email.png" alt="" />
          <lang en="Reset my password" fr="R&eacute;initialiser mon mot de passe"/>
        </a>
      </div>
    </td></tr>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_REGISTER">
    <tr><td colspan="2">
      <div class="buttons">
        <a class="positive" tabindex="6" href="<TMPL_VAR NAME="REGISTER_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF>">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/vcard_edit.png" alt="" />
          <lang en="Create an account" fr="Cr&eacute;er un compte"/>
        </a>
      </div>
    </td></tr>
  </TMPL_IF>


</table>
