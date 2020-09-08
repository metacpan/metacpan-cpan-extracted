<TMPL_INCLUDE NAME="header.tpl">

<div id="errorcontent" class="container">
  <div class="alert <TMPL_VAR NAME="ALERTE"> alert"><div class="text-center"><span trspan="<TMPL_VAR NAME="MSG">"></span></div></div>

  <TMPL_IF NAME="DECRYPTED">
  <div class="alert <TMPL_VAR NAME="DALERTE"> alert"><div class="text-center"><span trspan="<TMPL_VAR NAME="DECRYPTED">"></span></div></div>
  </TMPL_IF>

  <form id="findUser" action="/decryptvalue" method="post" class="password" role="form">
    <div class="buttons">
      <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      </TMPL_IF>

      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <span class="input-group-text"><label for="cipheredValuefield" class="mb-0"><i class="fa fa-random icon-blue"></i></label></span>
        </div>
        <input id="cipheredValuefield" name="cipheredValue" type="text" class="form-control" trplaceholder="cipheredValue" autocomplete="off" aria-required="false"/>
      </div>

      <button type="submit" class="btn btn-success">
        <span class="fa fa-search"></span>
        <span trspan="search">Search</span>
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
