<div class="form">

  <div class="webauthnclick">
    <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/modules/webauthn.png" alt="<TMPL_VAR NAME="module">" class="img-thumbnail mb-3" />
  </div>

    <input type="hidden" id="credential" name="credential" value="" />
    <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <div class="btn btn-success webauthnclick" role="button" id="webauthnbutton">
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </div>
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-secondary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>

</div>

<TMPL_IF NAME="DISPLAY_FINDUSER">
  <div class="actions">
  <button type="button" class="btn btn-secondary" data-toggle="modal" data-target="#finduserModal">
    <span class="fa fa-search"></span>
    <span trspan="searchAccount">Search for an account</span>
  </button>
  </div>
</TMPL_IF>
