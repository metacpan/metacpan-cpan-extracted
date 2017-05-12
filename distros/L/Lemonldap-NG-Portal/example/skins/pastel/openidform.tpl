<h3><lang en="Please enter your OpenID login" fr="Entrez votre identifiant OpenID"/></h3>

<table>
  <tr>
    <td><input name="openid_identifier" type="text" /></td>
  </tr>

  <TMPL_IF NAME="CHECK_LOGINS">
    <tr><td colspan="2"><div class="buttons">
      <label for="checkLogins">
        <input type="checkbox" id="checkLogins" name="checkLogins" <TMPL_IF NAME="ASK_LOGINS">checked</TMPL_IF>/>
        <lang en="Check my last logins" fr="Voir mes dernières connexions"/>
      </label>
    </div></td></tr>
  </TMPL_IF>

  <tr><td>
    <div class="buttons">
      <button type="reset" class="negative" tabindex="4">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
        <lang en="Cancel" fr="Annuler" />
      </button>
      <button type="submit" class="positive" tabindex="3">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
        <lang en="Connect" fr="Se connecter" />
      </button>
    </div>
  </td></tr>
</table>

