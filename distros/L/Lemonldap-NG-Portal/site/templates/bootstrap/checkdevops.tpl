<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <div class="alert <TMPL_VAR NAME="ALERTE"> alert"><div class="text-center"><span trspan="<TMPL_VAR NAME="MSG">"></span></div></div>
  <TMPL_IF NAME="UNKNOWN">
    <div class="card col border-secondary">
        <div class="text-center bg-light text-dark"><b><span trspan="unknownAttributes">UNKNOWN ATTRIBUTES</span></b></div>
        <div class="text-center bg-light text-dark"><TMPL_VAR NAME="UNKNOWN"></div>
    </div>
  </TMPL_IF>
  <TMPL_IF NAME="RULES">
      <div class="card col border-secondary">
        <div class="text-center bg-light text-dark"><b><span trspan="rules">RULES</span></b></div>
        <div class="font-weight-bold">
          <TMPL_LOOP NAME="RULES">
            <TMPL_VAR NAME="uri">: <span trspan="<TMPL_VAR NAME="access">"><TMPL_VAR NAME="access"></span><br/>
          </TMPL_LOOP>
        </div>
      </div>
  </TMPL_IF>
  <TMPL_IF NAME="HEADERS">
      <div class="card col border-secondary">
        <div class="text-center bg-light text-dark"><b><span trspan="headers">HEADERS</span></b></div>
        <div class="font-weight-bold">
          <TMPL_LOOP NAME="HEADERS">
            <TMPL_VAR NAME="key">: <TMPL_VAR NAME="value"><br/>
          </TMPL_LOOP>
        </div>
      </div>
  </TMPL_IF>
  <form id="checkDevOps" action="/checkdevops" method="post" class="password" role="form">
    <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    </TMPL_IF>
    <TMPL_IF NAME="DOWNLOAD">
      <input id="urlfield" name="url" type="text" class="form-control" value="<TMPL_VAR NAME="URL">" trplaceholder="URL / DNS" aria-required="true" autocomplete="url" />
      <pre><textarea id="checkDevOpsFile" name="checkDevOpsFile" class="form-control rounded-1" rows="10" trplaceholder="pasteHere"><TMPL_VAR NAME="FILE"></textarea></pre>
    <TMPL_ELSE>
      <pre><textarea id="checkDevOpsFile" name="checkDevOpsFile" class="form-control rounded-1" rows="10" trplaceholder="pasteHere" required><TMPL_VAR NAME="FILE"></textarea></pre>
    </TMPL_IF>

    <div class="buttons">
      <button type="submit" class="btn btn-success">
        <span class="fa fa-check-circle"></span>
        <span trspan="verify">Verify</span>
      </button>
    </div>
  </form>
    <div class="buttons">
      <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
    </div>
  </div>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
