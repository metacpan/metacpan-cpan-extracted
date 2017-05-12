<TMPL_INCLUDE NAME="header.tpl">

    <div id="content">

    <div id="content-left">
      <p><img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-lock.png" /></p>
    </div>

    <div id="content-right">
      <TMPL_IF NAME="AUTH_ERROR">
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      </TMPL_IF>
      <TMPL_IF NAME="ID">
        <p><lang en="Your identity is" fr="Votre identit&eacute; est&nbsp;"/>:</p>
        <p><TMPL_VAR NAME="ID"></p>
      </TMPL_IF>

      <TMPL_IF NAME="MSG">
        <TMPL_VAR NAME="MSG">
      </TMPL_IF>

      <TMPL_IF NAME="PORTAL_URL">
        <p>
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive"><lang en="Go to portal" fr="Aller au portail" /></a>
        </p>
		</TMPL_IF>

    </div>

<TMPL_INCLUDE NAME="footer.tpl">
