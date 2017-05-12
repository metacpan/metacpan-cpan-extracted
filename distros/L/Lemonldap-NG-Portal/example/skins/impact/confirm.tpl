<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Confirmation" fr="Confirmation" />
      </div>
      <hr class="solid" />

      <TMPL_UNLESS NAME="LIST"><TMPL_IF NAME="ACTIVE_TIMER">
      <p id="timer" class="text-error"><lang en="Automaticaly accept in 5 seconds" fr="Acceptation automatique dans 5 secondes"/></p>
      <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/info.js"></script>
      </TMPL_IF></TMPL_UNLESS>

      <form id="form" action="#" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
        <TMPL_VAR NAME="HIDDEN_INPUTS">
        <TMPL_IF NAME="AUTH_URL">
        <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
        </TMPL_IF>
        <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        </TMPL_IF>
        <TMPL_IF NAME="CONFIRMKEY">
        <input type="hidden" id="confirm" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">" />
        </TMPL_IF>

        <TMPL_IF NAME="MSG">
        <div id="content-all-info">
          <TMPL_VAR NAME="MSG">
        </div>
        </TMPL_IF>

        <TMPL_IF NAME="LIST">

        <h3><lang en="Select your Identity Provider" fr="Choisissez votre fournisseur d'identité"/></h3>
        <input type="hidden" id="idp" name="idp"/>
        <table style="margin: 0px auto">
        <TMPL_LOOP NAME="LIST">
          <tr><td><div class="buttons">
            <button type="submit" class="positive" style="width: 100%" onclick="$('#idp').val('<TMPL_VAR NAME="VAL">')">
              <TMPL_VAR NAME="NAME">
            </button>
          </div></td></tr>
    
        </TMPL_LOOP>

          <tr><td>
            <input type="checkbox" id="remember" name="cookie_type" value="1">
            <label for="remember"><lang en="Remember my choice" fr="Se souvenir de mon choix"/></label>
          </td></tr>

        <TMPL_ELSE>

        <table style="margin: 0px auto">
          <tr><td><div class="panel-buttons">
          <button type="submit" class="negative" tabindex="4" onclick="$('#confirm').attr('value','-<TMPL_VAR NAME="CONFIRMKEY">');">
            <lang en="Refuse" fr="Refuser" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Accept" fr="Accepter" />
          </button>
          </div></td></tr>

        </TMPL_IF>

        <TMPL_IF NAME="CHECK_LOGINS">
        <tr><td>
          <input type="checkbox" id="checkLogins" name="checkLogins" <TMPL_IF NAME="ASK_LOGINS">checked</TMPL_IF>/>
          <label for="checkLogins">
            <lang en="Check my last logins" fr="Voir mes dernières connexions"/>
          </label>
        </td></tr>
        </TMPL_IF>

        </table>
      </form>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">

