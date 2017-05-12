<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>
  </TMPL_IF>
  <div class="loginlogo"></div>

  <TMPL_IF AUTH_LOOP>

    <!-- Authentication loop -->

    <!-- Choice tabs -->
    <div id="authMenu">
      <ul>
        <TMPL_LOOP NAME="AUTH_LOOP">
          <li title="<TMPL_VAR NAME="key">"><a href="#<TMPL_VAR NAME="key">"><TMPL_VAR NAME="name"></a></li>
        </TMPL_LOOP>
      </ul>

      <!-- Forms -->
      <TMPL_LOOP NAME="AUTH_LOOP">

        <div id="<TMPL_VAR NAME="key">">

          <form action="<TMPL_VAR NAME="url">" method="post" class="login <TMPL_VAR NAME="module">">

            <!-- Hidden fields -->
            <TMPL_VAR NAME="HIDDEN_INPUTS">
            <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
            <input type="hidden" name="timezone" />
            <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="key">" />

            <TMPL_IF NAME="standardform">
              <TMPL_INCLUDE NAME="standardform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="openidform">
              <TMPL_INCLUDE NAME="openidform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="yubikeyform">
              <TMPL_INCLUDE NAME="yubikeyform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="logo">

              <h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>

              <table>
                <TMPL_IF NAME="module">
                  <tr class="authLogo"><td>
                  <img src="<TMPL_VAR NAME="SKIN_PATH">/common/<TMPL_VAR NAME="module">.png" alt="" />
                  </td></tr>
                </TMPL_IF>

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

            </TMPL_IF>

          </form>
        </div>
      </TMPL_LOOP>
    </div> <!-- end authMenu -->
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_FORM">

    <form action="#" method="post" class="login">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="standardform.tpl">
    </form>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_OPENID_FORM">

    <form action="#" method="post" class="login">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="openidform.tpl">
    </form>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_YUBIKEY_FORM">

    <form action="#" method="post" class="login">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="yubikeyform.tpl">
    </form>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_LOGO_FORM">

    <form action="#" method="post" class="login <TMPL_VAR NAME="module">">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />

      <h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>

      <table>
        <TMPL_IF NAME="module">
          <tr class="authLogo"><td>
            <img src="<TMPL_VAR NAME="SKIN_PATH">/common/<TMPL_VAR NAME="module">.png" alt="" />
          </td></tr>
        </TMPL_IF>

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
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_PASSWORD">
    <TMPL_INCLUDE NAME="password.tpl">
  </TMPL_IF>

  <TMPL_IF NAME="LOGIN_INFO">
    <div class="login_info">
      <TMPL_VAR NAME="LOGIN_INFO">
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="PORTAL_URL">
    <div id="logout">
      <TMPL_IF NAME="MSG"><TMPL_VAR NAME="MSG"></TMPL_IF>
      <div class="buttons">
        <a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
          <lang en="Go to portal" fr="Aller au portail" />
        </a>
      </div>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="LOGOUT_URL">
    <div id="logout">
      <div class="buttons">
        <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
          <lang en="Logout" fr="Se d&eacute;connecter"/>
        </a>
      </div>
    </div>
  </TMPL_IF>

  </div>

<TMPL_INCLUDE NAME="footer.tpl">
