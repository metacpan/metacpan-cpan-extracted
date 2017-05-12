<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-warn.png" />
        <lang en="Warning" fr="Attention" />
      </div>
      <p></p>
      <div id="content-all-info">
        <TMPL_IF ERROR403>
          <h3><lang en="You have no access authorization for this application" fr="Vous n'avez pas les droits d'acc&egrave;s &agrave; cette application" /></h3>
        </TMPL_IF>
        <TMPL_IF ERROR500>
          <h3><lang en="Error occurs on the server" fr="Une erreur est survenue sur le serveur" /></h3>
        </TMPL_IF>
        <TMPL_IF ERROR503>
          <h3><lang en="This application is in maintenance, please try to connect later" fr="Cette application est en maintenance, merci de réessayer plus tard" /></h3>
        </TMPL_IF>
        <TMPL_IF URL>
          <h3>
            <lang en="You were redirect from " fr="Vous avez été redirigé depuis " />
            <a href="<TMPL_VAR NAME="URL">"><TMPL_VAR NAME="URL"></a>
          </h3>
        </TMPL_IF>
      </div>
      <div class="panel-buttons">
        <button type="button" class="positive" tabindex="1" onclick="location.href='<TMPL_VAR NAME="PORTAL_URL">';return false;">
          <lang en="Go to portal" fr="Aller au portail" />
        </button>
        <button type="button" class="negative" tabindex="2" onclick="location.href='<TMPL_VAR NAME="LOGOUT_URL">';return false;">
          <lang en="Logout" fr="Se d&eacute;connecter" />
        </button>
      </div>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">

