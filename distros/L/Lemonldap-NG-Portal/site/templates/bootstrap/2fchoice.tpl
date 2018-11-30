<TMPL_INCLUDE NAME="header.tpl">

<div class="container">
  <div class="message message-positive alert" trspan="choose2f"></div>
  <div class="buttons">
    <form action="/2fchoice" method="POST">
      <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">">
      <TMPL_LOOP NAME="MODULES">
        <button type="submit" name="sf" value="<TMPL_VAR NAME="CODE">" class="mx-3">
          <img src="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="SKIN">/<TMPL_VAR NAME="LOGO">" alt="<TMPL_VAR NAME="CODE">2F" title="<TMPL_VAR NAME="CODE">2F" />
        </button>
      </TMPL_LOOP>
    </form>
  </div>
</div>
<div class="buttons mt-3">
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>
</div>

<TMPL_INCLUDE NAME="footer.tpl">

