<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <div class="alert <TMPL_VAR NAME="ALERTE"> alert"><div class="text-center"><span trspan="<TMPL_VAR NAME="MSG">"></span></div></div>
  <form id="checkuser" action="/checkuser" method="post" class="password" role="form">
    <div class="buttons">
      <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      </TMPL_IF>
      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <span class="input-group-text"><label for="userfield" class="mb-0"><i class="fa fa-user"></i></label></span>
        </div>
        <input id="userfield" name="user" type="text" class="form-control" value="<TMPL_VAR NAME="LOGIN">" trplaceholder="user" aria-required="true"/>
      </div>
      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <span class="input-group-text"><label for="urlfield" class="mb-0"><i class="fa fa-link"></i></label></span>
        </div>
        <input id="urlfield" name="url" type="text" class="form-control" value="<TMPL_VAR NAME="URL">" trplaceholder="URL / DNS" aria-required="true"/>
      </div>
      <button type="submit" class="btn btn-success">
        <span class="fa fa-search"></span>
        <span trspan="search">Search</span>
      </button>
    </div>
  </form>
  <div>
    <TMPL_IF NAME="ALLOWED">
    <div class="alert <TMPL_VAR NAME="ALERTE_AUTH">"><div class="text-center"><b><span trspan="<TMPL_VAR NAME="ALLOWED">"></span></b></div></div>
    </TMPL_IF>

    <TMPL_IF NAME="HEADERS">
    <div class="row">
      <div class="card col border-secondary">
        <div class="text-center bg-light text-dark"><b><span trspan="headers">HEADERS</span></b></div>
        <div class="font-weight-bold">
          <TMPL_LOOP NAME="HEADERS">
            <TMPL_VAR NAME="key">: <TMPL_VAR NAME="value"><br/>
          </TMPL_LOOP>
        </div>
      </div>
    </div>
    </TMPL_IF>
    <div class="row">
      <TMPL_IF NAME="GROUPS">
      <div class="card col border-secondary">
        <div class="text-center bg-light text-dark"><b><span trspan="groups_sso">SSO GROUPS</span></b></div>
        <div class="row">
          <TMPL_LOOP NAME="GROUPS">
          <div class="w-100"></div>
          <div class="col"><TMPL_VAR NAME="value"></div>
          </TMPL_LOOP>
        </div>
      </div>
      </TMPL_IF>
      <div class="col">
        <div class="row">
          <TMPL_IF NAME="ATTRIBUTES">
          <div class="card col border-secondary">
            <div class="text-center bg-light text-dark"><b><span trspan="attributes">ATTRIBUTES</span></b></div>
            <table class="table table-sm table-hover">
              <thead>
                <tr>
                  <th scope="col"><span trspan="key">Key</span></th>
                  <th scope="col"><span trspan="value">Value</span></th>
                </tr>
              </thead>
              <tbody>
                <TMPL_LOOP NAME="ATTRIBUTES">
                <tr>
                  <td scope="row"><TMPL_VAR NAME="key"></td>
                  <td scope="row"><TMPL_VAR NAME="value"></td>
                </tr>
                </TMPL_LOOP>
              </tbody>
            </table>
          </div>
          </TMPL_IF>
          <TMPL_IF NAME="GROUPS"><div class="w-100"></div></TMPL_IF>
          <TMPL_IF NAME="MACROS">
          <div class="card col border-secondary">
            <div class="text-center bg-light text-dark"><b><span trspan="macros">MACROS</span></b></div>
            <table class="table table-sm table-hover">
              <thead>
                <tr>
                  <th scope="col"><span trspan="key">Key</span></th>
                  <th scope="col"><span trspan="value">Value</span></th>
                </tr>
              </thead>
              <tbody>
                  <TMPL_LOOP NAME="MACROS">
                  <tr>
                    <td scope="row"><TMPL_VAR NAME="key"></td>
                    <td scope="row"><TMPL_VAR NAME="value"></td>
                  </tr>
                 </TMPL_LOOP>
              </tbody>
            </table>
          </div> 
          </TMPL_IF>
        </div>
      </div>
    </div>

    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
    </div>
  </div>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
