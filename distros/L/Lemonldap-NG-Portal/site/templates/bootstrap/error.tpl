<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <TMPL_IF AUTH_ERROR>
    <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span>
      <TMPL_IF LOCKTIME>
        <TMPL_VAR NAME="LOCKTIME"> <span trspan="seconds">seconds</span>.
      </TMPL_IF>
    </div>
  </TMPL_IF>
  <TMPL_IF RAW_ERROR>
    <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trspan="<TMPL_VAR NAME="RAW_ERROR">"></span></div>
  </TMPL_IF>
  <TMPL_IF ERROR403>
    <div class="message message-negative alert">
      <span trspan="accessDenied">You have no access authorization for this application</span>
    </div>
  </TMPL_IF>

  <TMPL_IF ERROR404>
    <div class="message message-negative alert">
      <span trspan="notFound">File not found</span>
    </div>
  </TMPL_IF>

  <TMPL_IF ERROR500>
    <div class="message message-negative alert">
      <span trspan="serverError">Error occurs on the server</span>
    </div>
  </TMPL_IF>

  <TMPL_IF ERROR502>
    <div class="message message-negative alert">
      <span trspan="proxyError">Proxy error</span>
    </div>
  </TMPL_IF>

  <TMPL_IF ERROR503>
    <div class="message message-warning alert">
      <span trspan="maintenanceMode">This application is in maintenance, please try to connect later</span>
    </div>
  </TMPL_IF>

  <div id="error">
    <TMPL_IF URL>
      <div class="message message-warning alert">
        <span trspan="redirectedFrom">You were redirect from </span>
        <a href="<TMPL_VAR NAME="URL">"><TMPL_VAR NAME="URL"></a>
      </div>
    </TMPL_IF>

    <div class="buttons">
      <TMPL_IF RAW_ERROR>
        <a href="<TMPL_VAR NAME="PORTAL_URL">2fregisters?skin=<TMPL_VAR NAME="SKIN">" class="btn btn-info" role="button">
          <span class="fa fa-shield"></span>
          <span trspan="sfaManager">sfaManager</span>
        </a>
      </TMPL_IF>
      <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
      <TMPL_IF NAME="LOGOUT_URL">
        <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="btn btn-danger" role="button">
          <span class="fa fa-sign-out"></span>
          <span trspan="logout">Logout</span>
        </a>
      </TMPL_IF>
    </div>
  </div>
</div>
<TMPL_INCLUDE NAME="footer.tpl">
