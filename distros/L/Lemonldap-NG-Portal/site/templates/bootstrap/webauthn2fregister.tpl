<TMPL_INCLUDE NAME="header.tpl">

  <main id="menucontent" class="container">

    <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert"><span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span></div>

    <div class="card">
     <div class="card-body">
       <div id="u2fPermission" trspan="u2fPermission" class="alert alert-info">You may be prompted to allow the site permission to access your security keys. After granting permission, the device will start to blink.</div>

       <div class="row">
         <div class="col-md-6 text-center">
           <img src="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="SKIN">/webauthn.png" alt="WebAuthn" title="WebAuthn" />
         </div>

         <div class="col-md-6">
         <div class="form-group">
            <label for="keyName"><span trspan="name">Name</span></label>
            <input type="text" class="form-control" id="keyName" name="keyName" value="MyFidoKey" trplaceholder="name" />
         </div>
         </div>

       </div>

       <div class="buttons">
         <div class="btn btn-primary" role="button" id="retrybutton">
           <span class="fa fa-repeat"></span>
           <span trspan="retry">Retry</span>
         </div>
       </div>
     </div>
    </div>
  </main>

<div class="buttons">
  <a href="<TMPL_VAR NAME="PORTAL_URL">2fregisters?skin=<TMPL_VAR NAME="SKIN">" class="btn btn-info" role="button">
    <span class="fa fa-shield"></span>
    <span trspan="sfaManager">sfaManager</span>
  </a>

  <a id="goback" href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1&skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="goToPortal">Go to portal</span>
  </a>
</div>
<TMPL_INCLUDE NAME="footer.tpl">
