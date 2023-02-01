<TMPL_INCLUDE NAME="header.tpl">

<div class="container">
  <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert">
   <TMPL_IF NAME="REG_REQUIRED">
    <span trspan="2fRegRequired"></span>
   <TMPL_ELSE>
    <span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span>
   </TMPL_IF>
  </div>
  <TMPL_IF NAME="SFDEVICES">
    <div class="card mb-3 border-secondary">
    <div class="card-body table-responsive">
    <table class="table table-hover">
      <thead>
        <tr>
          <th><span trspan="type">Type</span></th>
          <th><span trspan="name">Name</span></th>
          <th><span trspan="date">Date</span></th>
          <th>
            <TMPL_IF NAME="ACTION">
              <span trspan="action">Action</span>
            </TMPL_IF>
          </th>
        </tr>
      </thead>
      <tbody>
        <TMPL_LOOP NAME="SFDEVICES">
          <tr id='delete-<TMPL_VAR NAME="epoch">'>
            <td class="align-middle">
            <TMPL_IF name="label">
                <TMPL_VAR NAME="label">
            <TMPL_ELSE>
                <TMPL_VAR NAME="type">
            </TMPL_IF>
            </td>
            <td class="align-middle"><TMPL_VAR NAME="name"></td>
            <td class="data-epoch"><TMPL_VAR NAME="epoch"></td>
            <td>
              <TMPL_IF NAME="delAllowed">
                <span
                    device='<TMPL_VAR NAME="type">'
                    epoch='<TMPL_VAR NAME="epoch">'
                    prefix='<TMPL_VAR NAME="prefix">'
                    class="btn btn-danger"
                    role="button"
                    data-toggle="modal"
                    data-target="#remove2fModal">
                  <span class="fa fa-minus-circle"></span>
                  <span trspan="unregister">Unregister</span>
  	            </span>
              </TMPL_IF>
	          </td>
          </tr>
        </TMPL_LOOP>
      </tbody>
    </table>
    </div>
    </div>
  </TMPL_IF>

  <div class="modal fade" id="remove2fModal" tabindex="-1" role="dialog" aria-labelledby="remove2fModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="remove2fModalLabel"><span trspan="areYouSure">Are you sure ?</span></h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <span trspan="remove2fWarning">This operation cannot be undone</span>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">
                  <span trspan="cancel">Cancel</span>
          </button>
          <button type="button" class="btn btn-danger remove2f" data-dismiss="modal">
            <span class="fa fa-minus-circle"></span>
            <span trspan="unregister">Unregister</span>
          </button>
        </div>
      </div>
    </div>
  </div>

  <div class="text-center mb-3 row">
    <TMPL_LOOP NAME="MODULES">
    <div class="col">
    <div class="card border-secondary">
      <div class="card-body py-3">
      <a href="<TMPL_VAR NAME="URL">" class="nodecor">
        <img src="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="SKIN">/<TMPL_VAR NAME="LOGO">" alt="<TMPL_VAR NAME="CODE">2f" title="<TMPL_VAR NAME="LABEL">" />
      </a>
      </div>
      <div class="card-footer text-white text-uppercase bg-secondary">
      <TMPL_IF LABEL>
        <p><TMPL_VAR NAME="LABEL"></p>
      <TMPL_ELSE>
        <p trspan="<TMPL_VAR NAME="CODE">2f"></p>
      </TMPL_IF>
      </div>
    </div>
    </div>
    </TMPL_LOOP>
  </div>

</div>

<div class="buttons">
  <TMPL_IF NAME="DISPLAY_UPG">
    <a href="<TMPL_VAR NAME="PORTAL_URL">upgradesession?forceUpgrade=1&url=<TMPL_VAR NAME="SFREGISTERS_URL">" class="btn btn-success" role="button">
      <span class="fa fa-sign-in"></span>
      <span trspan="upgradeSession">Upgrade session</span>
    </a>
  </TMPL_IF>
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN">" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="goToPortal">Go to portal</span>
  </a>
</div>

<!-- //if:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/2fregistration.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/2fregistration.js"></script>
<!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">

