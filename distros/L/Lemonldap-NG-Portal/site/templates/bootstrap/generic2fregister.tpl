<TMPL_INCLUDE NAME="header.tpl">

  <main id="menucontent" class="container">

    <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert"><span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span></div>

    <div id="divToHide" class="card">
      <div class="card-body">

      <div class="row">

        <div class="col-md-6 text-center">
          <input type="hidden" id="token" name="token" />

          <div class="form-group">
            <label for="generic">&#x2460; <span trspan="genericRegisterPrompt">Enter your contact information</span></label>
            <input type="email" id="generic" class="form-control" name="generic" autocomplete="off" />
          </div>

          <label for="verify">&#x2461; <span trspan="genericRegisterVerify">Enter your contact information</span></label>
          <div class="buttons">
            <span id="verify" class="btn btn-success" role="button">
              <span class="fa fa-check"></span>
              <span trspan="verify">Verify</span>
            </span>
          </div>
        </div>

        <div class="col-md-6 text-center">
          <div class="form-group">
            <label for="genericname">&#x2462; <span trspan="genericRegisterName">Name</span></label>
            <input type="text" class="form-control" id="genericname" name="genericname" value="MyContact" trplaceholder="name" />
          </div>
          <div class="form-group">
            <label for="code">&#x2463; <span trspan="genericRegisterCode">Code</span></label>
            <input id="code" class="form-control" name="code" autocomplete="off" />
          </div>
          <label for="register">&#x2464; <span trspan="genericRegisterRegister">Code</span></label>
          <div class="buttons">
            <span id="register" class="btn btn-success" role="button">
              <span class="fa fa-floppy-o"></span>
              <span trspan="register">Register</span>
            </span>
          </div>
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

<!-- //if:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/generic2fregistration.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/generic2fregistration.js"></script>
<!-- //endif -->
<script type="application/init">
{
 "prefix":"<TMPL_VAR NAME="PREFIX">"
}
</script>
<TMPL_INCLUDE NAME="footer.tpl">
