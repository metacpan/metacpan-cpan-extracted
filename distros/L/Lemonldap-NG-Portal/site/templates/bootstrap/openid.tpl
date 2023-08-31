<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
    <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">">
      <span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="ID">
    <div class="alert alert-info">
      <h3><span trspan="yourIdentityIs">Your identity is</span>: <TMPL_VAR NAME="ID"></h3>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="PORTAL_URL">

    <TMPL_IF NAME="MSG">
      <div class="alert alert-info">
        <TMPL_VAR NAME="MSG">
      </div>
    </TMPL_IF>

    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="positive btn btn-primary">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
    </div>

  </TMPL_IF>

</div>

<TMPL_INCLUDE NAME="footer.tpl">

