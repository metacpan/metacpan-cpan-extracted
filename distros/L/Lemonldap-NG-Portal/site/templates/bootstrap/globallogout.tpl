<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <div class="alert alert-warning alert"><div class="text-center"><span trspan="globalLogout">globalLogout</span></div></div>

  <div class="row">
    <TMPL_IF NAME="SESSIONS">
    <div class="card col border-secondary">
      <div class="text-center bg-light text-dark"><b><span trspan="activeSessions">ACTIVE SSO SESSIONS</span>: <u><TMPL_VAR NAME="LOGIN"></u></b></div>
      <table class="table table-sm table-hover text-center">
        <thead>
          <tr>
            <th scope="col"><span trspan="startTime">startTime</span></th>
            <th scope="col"><span trspan="updateTime">updateTime</span></th>
            <th scope="col"><span trspan="ipAddr">ipAddr</span></th>
            <th scope="col"><span trspan="authLevel">authLevel</span></th>
            <TMPL_IF NAME="CUSTOMPRM">
              <th scope="col"><TMPL_VAR NAME="CUSTOMPRM"></th>
            </TMPL_IF>
          </tr>
        </thead>
        <tbody>
          <TMPL_LOOP NAME="SESSIONS">
          <tr>
            <td scope="row" class="data-epoch"><TMPL_VAR NAME="startTime"></td>
            <td scope="row" class="data-epoch"><TMPL_VAR NAME="updateTime"></td>
            <td scope="row"><TMPL_VAR NAME="ipAddr"></td>
            <td scope="row"><TMPL_VAR NAME="authLevel"></td>
            <TMPL_IF NAME="CUSTOMPRM">
              <td scope="row"><TMPL_VAR NAME="customParam"></td>
            </TMPL_IF>
          </tr>
          </TMPL_LOOP>
        </tbody>
      </table>
    </div>
    </TMPL_IF>
  </div>
  <p>
    <div class="card-footer bg-info">
      <p id="timer" trspan="autoGlobalLogout">Automatically global logout in 30 seconds</p>
    </div>
  </p>
  <form id="globallogout" action="/globallogout?all=1" method="post" class="password" role="form">
    <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <div class="buttons">
      <button type="submit" class="btn btn-danger">
        <span class="fa fa-sign-out"></span>
        <span trspan="all">All</span>
      </button>
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
      <a href="<TMPL_VAR NAME="PORTAL_URL">globallogout" class="btn btn-success" role="button">
        <span class="fa fa-sign-out"></span>
        <span trspan="current">Current</span>
      </a>
    </div>
  </form>

  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/globalLogout.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/globalLogout.js"></script>
  <!-- //endif -->

</div>

<TMPL_INCLUDE NAME="footer.tpl">
