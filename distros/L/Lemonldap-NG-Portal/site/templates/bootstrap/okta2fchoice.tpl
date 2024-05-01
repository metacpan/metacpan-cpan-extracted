<TMPL_INCLUDE NAME="header.tpl">

<div class="container">
  <div class="message message-<TMPL_VAR NAME="ALERT"> alert" trspan="<TMPL_VAR NAME="MSG">"></div>
  <div class="buttons">
    <form action="/okta2fchoice" method="POST">
      <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
      <input type="hidden" id="stayconnected" name="stayconnected" value="<TMPL_VAR NAME="STAYCONNECTED">" />
      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <TMPL_LOOP NAME="MODULES">
        <button type="submit" name="sf" value="<TMPL_VAR NAME="CODE">" class="mx-3 btn btn-light" role="button">
        <div>
          <h4 trspan="okta2f<TMPL_VAR NAME="LABEL">"></h4>
        </div>
          <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/2F/okta-<TMPL_VAR NAME="LABEL">.png" alt="<TMPL_VAR NAME="LABEL">" title="OKTA <TMPL_VAR NAME="LABEL">" />
        </button>
      </TMPL_LOOP>
    </form>
  </div>
</div>
<div class="buttons mt-3">
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>
</div>

<TMPL_INCLUDE NAME="footer.tpl">

