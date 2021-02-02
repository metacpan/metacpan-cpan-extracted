<TMPL_IF NAME="FINDUSER">
  <br>
  <div class="card">
  <br>
  <form action="/finduser" id="searchAccount" method="post" role="form" class="login">
  <div class="form">
    <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
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
            <span class="input-group-text"><label for="<TMPL_VAR NAME="key">" class="mb-0"><i class="fa fa-user"></i></label></span>
          </div>
          <input id="findUser_<TMPL_VAR NAME="key">" name="<TMPL_VAR NAME="key">" type="text" autocomplete="off" class="form-control" placeholder="<TMPL_VAR NAME="value">" />
        </div>
      </TMPL_IF>
    </TMPL_LOOP>
    <button type="submit" class="btn btn-info" >
      <span class="fa fa-eye"></span>
      <span trspan="searchAccount">Search for an account</span>
    </button>
  </div>
  </form>
  <br>
  </div>
</TMPL_IF>
