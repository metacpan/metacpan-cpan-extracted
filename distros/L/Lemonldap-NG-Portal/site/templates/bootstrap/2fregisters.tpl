<TMPL_INCLUDE NAME="header.tpl">

<div class="container">
  <div id="color" class="message message-positive alert">
   <TMPL_IF NAME="REG_REQUIRED">
    <span trspan="2fRegRequired"></span>
   <TMPL_ELSE>
    <span id="msg" trspan="choose2f"></span>
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
            <td class="align-middle"><TMPL_VAR NAME="type"></td>
            <td class="align-middle"><TMPL_VAR NAME="name"></td>
            <td class="data-epoch"><TMPL_VAR NAME="epoch"></td>
            <td>
              <TMPL_IF NAME="delAllowed">
                <span device='<TMPL_VAR NAME="type">' epoch='<TMPL_VAR NAME="epoch">' class="btn btn-danger" role="button">
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

  <div class="text-center mb-3 row"> 
    <TMPL_LOOP NAME="MODULES">
    <div class="col">
    <div class="card border-secondary">
      <div class="card-body py-3">
      <a href="<TMPL_VAR NAME="URL">" class="nodecor">
        <img src="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="SKIN">/<TMPL_VAR NAME="LOGO">" alt="<TMPL_VAR NAME="CODE">2F" title="<TMPL_VAR NAME="CODE">2F" />
      </a>
      </div>
      <div class="card-footer text-white text-uppercase bg-secondary"><TMPL_VAR NAME="CODE">2F</div>
    </div>
    </div>
    </TMPL_LOOP>
  </div>

</div>

<div class="buttons">
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
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

