<TMPL_INCLUDE NAME="header.tpl">

  <main id="menucontent" class="container">

    <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert"><span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span></div>

    <div id="divToHide" class="card">
      <div class="card-body">

      <div class="row">
        <div class="col-md-6 text-center">
          <div >
            <p>&#x2460; <span trspan="totpQrCode"></span></p>
            <canvas id="qr"></canvas>

            <p><span trspan="totpSecretKey"></span></p>
            <tt id="secret"></tt>
          </div>
        </div>

        <div class="col-md-6">
          <div class="form-group">
            <label for="TOTPName">&#x2461; <span trspan="totpRegisterName">Name</span></label>
            <input type="text" class="form-control" id="TOTPName" name="TOTPName" value="MyTOTP" trplaceholder="name" />
          </div>
          <div class="form-group">
            <label for="code">&#x2462; <span trspan="totpRegisterCode">Code</span></label>
            <input id="code" class="form-control" name="code" autocomplete="off" />
          </div>
        </div>
      </div>

      <div class="buttons">
        <span id="verify" class="btn btn-success" role="button">
          <span class="fa fa-floppy-o"></span>
          <span trspan="register">Register</span>
        </span>
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

<!-- //if:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/qrious/dist/qrious.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/totpregistration.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/qrious/dist/qrious.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/totpregistration.js"></script>
<!-- //endif -->
<TMPL_INCLUDE NAME="footer.tpl">
