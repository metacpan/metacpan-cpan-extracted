<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">

<div class="message message-positive alert"><span trspan="<TMPL_VAR NAME="MSG">"></span></div>

<form id="upgrd" action="/upgradesession" method="post" class="password" role="form">
  <input type="hidden" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">">
  <input type="hidden" name="url" value="<TMPL_VAR NAME="URL">">
  <div class="buttons">
    <button type="submit" class="btn btn-success">
      <span class="fa fa-sign-in"></span>
      <span trspan="upgradeSession">Upgrade session</span>
    </button>
  </div>
</form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
