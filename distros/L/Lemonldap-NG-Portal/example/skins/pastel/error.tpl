<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent">

  <TMPL_IF ERROR403>
    <div class="message negative"><ul><li><lang en="You have no access authorization for this application" fr="Vous n'avez pas les droits d'acc&egrave;s &agrave; cette application" /></li></ul></div>
  </TMPL_IF>

  <TMPL_IF ERROR500>
    <div class="message negative"><ul><li><lang en="Error occurs on the server" fr="Une erreur est survenue sur le serveur" /></li></ul></div>
  </TMPL_IF>

  <TMPL_IF ERROR503>
    <div class="message warning"><ul><li><lang en="This application is in maintenance, please try to connect later" fr="Cette application est en maintenance, merci de réessayer plus tard" /></li></ul></div>
  </TMPL_IF>

  <div class="loginlogo"></div>

  <div id="error">

    <TMPL_IF URL>
      <h3>
        <lang en="You were redirect from " fr="Vous avez été redirigé depuis " />
        <a href="<TMPL_VAR NAME="URL">"><TMPL_VAR NAME="URL"></a>
      </h3>
    </TMPL_IF>

    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
        <lang en="Go to portal" fr="Aller au portail" />
      </a>
      <TMPL_IF NAME="LOGOUT_URL">
        <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
          <lang en="Logout" fr="Se d&eacute;connecter" />
        </a>
      </TMPL_IF>
    </div>
  </div>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
