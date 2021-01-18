<TMPL_INCLUDE NAME="header.tpl">

  <main id="menucontent" class="container">

    <div id="color" class="message message-<TMPL_VAR NAME="ALERT"> alert"><span id="msg" trspan="<TMPL_VAR NAME="MSG">"></span></div>

    <div class="card">
      <div class="card-body">
      <form action="/2fregisters/yubikey/register" method="post">

      <div class="row">

        <div class="col-md-6 text-center">
          <img src="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="SKIN">/yubikey.png" alt="Yubikey" title="Yubikey" />
        </div>
        <div class="col-md-6">
          <div class="form-group">
            <label for="UBKName"><span trspan="name">Name</span></label>
            <input type="text" class="form-control" id="UBKName" name="UBKName" value="MyYubikey" trplaceholder="name" />
          </div>
          <div class="form-group">
            <label for="otp"><span trspan="id">Id</span></label>
            <input type="text" class="form-control" id="otp" name="otp" trplaceholder="Id" autocomplete="off" autofocus/>
          </div>
          <input class="custom-control-input" type="submit" value="Submit" />
        </div>

      </div>

      </form>
      </div>
    </div>

  </main>

<div class="buttons">
  <a href="<TMPL_VAR NAME="PORTAL_URL">2fregisters" class="btn btn-info" role="button">
    <span class="fa fa-shield"></span>
    <span trspan="sfaManager">sfaManager</span>
  </a>

  <a id="goback" href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1<TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="goToPortal">Go to portal</span>
  </a>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
