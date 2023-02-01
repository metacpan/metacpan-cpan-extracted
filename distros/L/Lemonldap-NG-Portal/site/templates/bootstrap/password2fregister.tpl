<TMPL_INCLUDE NAME="header.tpl">

  <main id="menucontent" class="container">

    <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert"><span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span></div>

    <div id="divToHide" class="card">
      <div class="card-body">

        <div class="form-group">
          <label for="password"><span trspan="password">Password</span></label>
          <input type="password" id="password2f" class="form-control" name="password" autocomplete="new-password" />
        </div>
        <div class="form-group">
          <label for="passwordverify"><span trspan="passwordverify">Verify Password</span></label>
          <input type="password"  id="password2fverify" class="form-control" name="passwordverify" autocomplete="new-password" />
        </div>

        <div class="buttons">
          <span id="register" class="btn btn-success" role="button">
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
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/password2fregistration.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/password2fregistration.js"></script>
<!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
