        <p>
          <span class="text-label"><lang en="Login" fr="Identifiant"/></span><br/>
          <input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">" tabindex="1" /><br/>
        </p>
        <p>
          <span class="text-label"><lang en="Password" fr="Mot de passe"/></span><br/>
          <input name="password" type="password" tabindex="2" /><br/>
        </p>

        <TMPL_IF NAME=CAPTCHA_IMG>
	<p>
          <img src="<TMPL_VAR NAME=CAPTCHA_IMG>" />
        </p>
        <p>
          <span class="text-label"><lang en="Captcha" fr="Captcha" /></span><br />
          <input type="text" name="captcha_user_code" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" tabindex="3" /><br />
          <input type="hidden" name="captcha_code" value="<TMPL_VAR NAME=CAPTCHA_CODE>" />
        </p>
        </TMPL_IF>

        <TMPL_IF NAME="CHECK_LOGINS">
        <p>
        <label for="checkLogins">
            <input type="checkbox" id="checkLogins" name="checkLogins" <TMPL_IF NAME="ASK_LOGINS">checked</TMPL_IF> tabindex="4" />
            <lang en="Check my last logins" fr="Voir mes derni&egrave;res connexions"/>
        </label>
        </p>
        </TMPL_IF>

        <hr class="solid" />
        <div class="panel-buttons">
          <button type="reset" class="negative" tabindex="10">
            <lang en="Cancel" fr="Annuler" />
          </button>
          <button type="submit" class="positive" tabindex="8">
            <lang en="Connect" fr="Se connecter" />
          </button>
        </div>

      <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
      <p>
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="MAIL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>"><lang en="Reset my password" fr="R&eacute;initialiser mon mot de passe"/></a>
      </p>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_REGISTER">
      <p>
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="REGISTER_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="key">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="key"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>"><lang en="Create an account" fr="Cr&eacute;er un compte"/></a>
      </p>
      </TMPL_IF>

