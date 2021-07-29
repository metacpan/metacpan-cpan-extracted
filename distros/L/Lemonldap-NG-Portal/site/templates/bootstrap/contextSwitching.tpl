<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <div class="alert <TMPL_VAR NAME="ALERTE"> alert"><div class="text-center"><span trspan="<TMPL_VAR NAME="MSG">"></span></div></div>
    <form id="contextSwitching" action="/switchcontext" method="post" class="password" role="form">
      <TMPL_IF NAME="TOKEN">
        <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      </TMPL_IF>
      <TMPL_INCLUDE NAME="impersonation.tpl">
      <div class="buttons">
        <button type="submit" class="btn btn-success">
          <span class="fa fa-random"></span>
          <span trspan="switchContext">switchContext</span>
        </button>
      </div>
    </form>
    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
    </div>
  </div>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
