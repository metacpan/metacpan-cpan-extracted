<TMPL_IF NAME="DISPLAY_FINDUSER">

<div id="finduserModal" class="modal fade" tabindex="-1" role="dialog">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><span trspan="searchingForm">Searching form</span></h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
      <form action="/finduser" method="POST" id="finduserForm" role="form" class="login">
        <div class="form">
          <TMPL_IF NAME="TOKEN">
            <input id="finduserToken" type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
          </TMPL_IF>
          <TMPL_LOOP NAME="FIELDS">
            <TMPL_IF NAME="select">
              <div class="form-group">
              <label for="<TMPL_VAR NAME="key">"><TMPL_VAR NAME="value"></label>
              <select class="form-control" id="findUser_<TMPL_VAR NAME="key">" name="<TMPL_VAR NAME="key">">
                <TMPL_IF NAME="null">
                  <option value=""></option>
                </TMPL_IF>
                <TMPL_LOOP NAME="choices">
                  <option value="<TMPL_VAR NAME="key">"><TMPL_VAR NAME="value"></option>
                </TMPL_LOOP>
              </select>
              </div>
            <TMPL_ELSE>
              <div class="input-group mb-3">
                <div class="input-group-prepend">
                  <span class="input-group-text"><label for="<TMPL_VAR NAME="key">" class="mb-0"><i class="fa fa-binoculars"></i></label></span>
                </div>
                <input id="findUser_<TMPL_VAR NAME="key">" name="<TMPL_VAR NAME="key">" type="text" autocomplete="off" class="form-control" placeholder="<TMPL_VAR NAME="value">" />
              </div>
            </TMPL_IF>
          </TMPL_LOOP>
        </div>
        <div class="modal-footer">
          <button id="closefinduserform" type="button" class="btn btn-secondary" data-dismiss="modal"><span trspan="close">Close</span></button>
          <button id="finduserbutton" type="submit" class="btn btn-info" data-dismiss="modal">
            <span class="fa fa-search"></span>
            <span trspan="searchAccount">Search for an account</span>
          </button>
          <button id="resetfinduserform" type="button" class="btn btn-primary"><span trspan="cancel">Cancel</span></button>
        </div>
      </form>
      </div>
    </div>
  </div>
</div>

</TMPL_IF>
