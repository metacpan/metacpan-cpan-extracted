<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
    <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert">
      <TMPL_VAR NAME="AUTH_ERROR">
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="ID">
    <div class="alert alert-info">
      <h3><lang en="Your identity is" fr="Votre identit&eacute; est&nbsp;"/>: <TMPL_VAR NAME="ID"></h3>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="PORTAL_URL">

    <TMPL_IF NAME="MSG">
      <div class="alert alert-info">
        <TMPL_VAR NAME="MSG">
      </div>
    </TMPL_IF>

    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive btn btn-success">
        <span class="glyphicon glyphicon-ok"></span>
        <lang en="Go to portal" fr="Aller au portail" />
      </a>
    </div>

  </TMPL_IF>

</div>

<TMPL_INCLUDE NAME="footer.tpl">

