<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">

<div class="message message-positive alert"><span trspan="<TMPL_VAR NAME="MSG">"></span></div>

<form id="upgrd" action="<TMPL_VAR NAME="FORMACTION">" method="post" class="password" role="form">
  <input type="hidden" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">">
  <input type="hidden" id="forceUpgrade" name="forceUpgrade" value="<TMPL_VAR NAME="FORCEUPGRADE">" />
  <input type="hidden" name="url" value="<TMPL_VAR NAME="URL">">
  <div class="buttons">
    <button type="submit" class="btn btn-success">
      <span class="fa fa-sign-in"></span>
      <span trspan="<TMPL_VAR NAME="BUTTON">">Upgrade session</span>
    </button>
    <TMPL_IF NAME="PORTALBUTTON">
    <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
      <span class="fa fa-home"></span>
      <span trspan="goToPortal">Go to portal</span>
    </a>
    </TMPL_IF>
  </div>
</form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
