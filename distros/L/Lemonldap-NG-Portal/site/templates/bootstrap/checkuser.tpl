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
        <input id="userfield" name="user" type="text" class="form-control" value="<TMPL_VAR NAME="LOGIN" ESCAPE=HTML>" trplaceholder="user" aria-required="true"/>
      </div>
      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <span class="input-group-text"><label for="urlfield" class="mb-0"><i class="fa fa-link"></i></label></span>
        </div>
        <input id="urlfield" name="url" type="text" class="form-control" value="<TMPL_VAR NAME="URL">" trplaceholder="URL / DNS" aria-required="true" autocomplete="url" />
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
      <div class ="col-12 col-sm-12 col-md-12 pb-3">
        <div class="card h-100 border-secondary">
          <div class="card-title text-center bg-light text-dark"><b><span trspan="headers">HEADERS</span></b></div>
          <div class="card-text font-weight-bold m-2">
            <TMPL_LOOP NAME="HEADERS">
              <TMPL_VAR NAME="key">: <TMPL_VAR NAME="value"><br/>
            </TMPL_LOOP>
          </div>
        </div>
      </div>
    </div>
    </TMPL_IF>

    <div class= "row ">
    <TMPL_IF NAME="DISPLAY">
      <!-- Groups Card 1 -->
      <div class ="col-6 col-sm-12 col-md-6 p-0">
        <div class="card h-100">
          <TMPL_IF NAME="GROUPS">
            <div class="card-title text-center bg-light text-dark"><b><span trspan="groups_sso">SSO GROUPS</span></b></div>
            <TMPL_LOOP NAME="GROUPS">
            <div class="card-text text-left ml-2"><TMPL_VAR NAME="value"></div>
            </TMPL_LOOP>
          </TMPL_IF>
        </div>
      </div>

      <!-- Macros Card 2 -->
      <div class ="col-6 col-sm-12 col-md-6 p-0">
        <div class="card h-100">
          <TMPL_IF NAME="MACROS">
          <div class="card-title text-center bg-light text-dark"><b><span trspan="macros">MACROS</span></b></div>
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
          </TMPL_IF>
        </div>
      </div>

      <!-- History Card 3 -->
      <div class ="col-6 col-sm-12 col-md-6 p-0">
        <div class="card h-100">
          <TMPL_IF NAME="HISTORY">
            <div class="card-title text-center bg-light text-dark"><b><span trspan="loginHistory">HISTORY</span></b></div>
            <TMPL_IF NAME="SUCCESS">
            <table class="table table-sm table-hover">
              <thead>
                <div class="card-text text-center bg-light text-dark"><span trspan="lastLogins">Success</span></div>
                <tr>
                  <th scope="col"><span trspan="date">Date</span></th>
                  <th scope="col"><span trspan="value">Value</span></th>
                </tr>
              </thead>
              <tbody>
                <TMPL_LOOP NAME="SUCCESS">
                <tr>
                  <td class="localeDate" scope="row" val="<TMPL_VAR NAME="utime">"></td>
                  <td scope="row"><TMPL_VAR NAME="values"></td>
                </tr>
                </TMPL_LOOP>
              </tbody>
            </table>
            </TMPL_IF>
            <TMPL_IF NAME="FAILED">
            <table class="table table-sm table-hover">
              <thead>
                <div class="card-text text-center bg-light text-dark"><span trspan="lastFailedLogins">Failed</span></div>
                <tr>
                  <th scope="col"><span trspan="date">Date</span></th>
                  <th scope="col"><span trspan="value">Value</span></th>
                </tr>
              </thead>
              <tbody>
                <TMPL_LOOP NAME="FAILED">
                <tr>
                  <td class="localeDate" scope="row" val="<TMPL_VAR NAME="utime">"></td>
                  <td scope="row"><TMPL_VAR NAME="values"></td>
                </tr>
                </TMPL_LOOP>
              </tbody>
            </table>
            </TMPL_IF>
          </TMPL_IF>
        </div>
      </div>

      <!-- Attribute Card 4 -->
      <div class ="col-6 col-sm-12 col-md-6 p-0">
        <div class="card h-100">
          <TMPL_IF NAME="ATTRIBUTES">
            <div class="card-title text-center bg-light text-dark"><b><span trspan="attributes">ATTRIBUTES</span></b></div>
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
          </TMPL_IF>
        </div>
      </div>
    </TMPL_IF>
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
