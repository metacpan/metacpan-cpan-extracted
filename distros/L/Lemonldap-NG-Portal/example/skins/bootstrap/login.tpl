<TMPL_INCLUDE NAME="header.tpl">


  <div id="logincontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><TMPL_VAR NAME="AUTH_ERROR"></div>
  </TMPL_IF>

  <TMPL_IF AUTH_LOOP>

    <div id="authMenu">

    <!-- Authentication loop -->
    <div class="nav navbar-default">

    <div class="navbar-header">

    <button class="navbar-toggle" data-target=".navbar-collapse" data-toggle="collapse" type="button">
        <span class="sr-only">
            Toggle navigation
        </span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
    </button>
    <a class="navbar-brand" href="#">
      <span class="glyphicon glyphicon-user"></span>
    </a>

    </div>

    <!-- Choice tabs -->
    <div class="navbar-collapse collapse">

      <ul class="nav navbar-nav">
        <TMPL_LOOP NAME="AUTH_LOOP">
          <li title="<TMPL_VAR NAME="key">"><a href="#<TMPL_VAR NAME="key">"><TMPL_VAR NAME="name"></a></li>
        </TMPL_LOOP>
      </ul>

    </div>
 
      <!-- Forms -->
      <TMPL_LOOP NAME="AUTH_LOOP">

        <div id="<TMPL_VAR NAME="key">">

          <form action="<TMPL_VAR NAME="url">" method="post" class="login <TMPL_VAR NAME="module">">

            <!-- Hidden fields -->
            <TMPL_VAR NAME="HIDDEN_INPUTS">
            <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
            <input type="hidden" name="timezone" />
            <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="key">" />

            <TMPL_IF NAME="standardform">
              <TMPL_INCLUDE NAME="standardform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="openidform">
              <TMPL_INCLUDE NAME="openidform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="yubikeyform">
              <TMPL_INCLUDE NAME="yubikeyform.tpl">
            </TMPL_IF>

            <TMPL_IF NAME="logo">

              <div class="form">

                <TMPL_IF NAME="module">
                  <img src="<TMPL_VAR NAME="SKIN_PATH">/common/<TMPL_VAR NAME="module">.png" alt="<TMPL_VAR NAME="module">" class="img-thumbnail" />
                </TMPL_IF>

                <TMPL_INCLUDE NAME="checklogins.tpl">

                  <button type="submit" class="btn btn-success">
                    <span class="glyphicon glyphicon-log-in"></span>
                    <lang en="Connect" fr="Se connecter" />
                  </button>

              </div>

            </TMPL_IF>

          </form>

        </div>

      </TMPL_LOOP>

    </div>

    </div> <!-- end authMenu -->

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_FORM">

    <div class="panel panel-default">
    <form action="#" method="post" class="login" role="form">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="standardform.tpl">
    </form>

    </div>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_OPENID_FORM">

    <div class="panel panel-default">
    <form action="#" method="post" class="login" role="form">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="openidform.tpl">
    </form>
    </div>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_YUBIKEY_FORM">

    <div class="panel panel-default">
    <form action="#" method="post" class="login" role="form">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />
      <TMPL_INCLUDE NAME="yubikeyform.tpl">
    </form>
    </div>

  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_LOGO_FORM">

    <div class="panel panel-default">
    <form action="#" method="post" class="login <TMPL_VAR NAME="module">" role="form">
      <!-- Hidden fields -->
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <input type="hidden" name="timezone" />

      <div class="form">
      <TMPL_IF NAME="module">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/common/<TMPL_VAR NAME="module">.png" alt="<TMPL_VAR NAME="module">" class="img-thumbnail" />
      </TMPL_IF>

      <TMPL_INCLUDE NAME="checklogins.tpl">

      <button type="submit" class="btn btn-success">
        <span class="glyphicon glyphicon-log-in"></span>&nbsp;
        <lang en="Connect" fr="Se connecter" />
      </button>
      </div>

    </form>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_PASSWORD">
    <div id="password" class="panel panel-default">
    <TMPL_INCLUDE NAME="password.tpl">
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="LOGIN_INFO">
    <div class="alert alert-info">
      <TMPL_VAR NAME="LOGIN_INFO">
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="PORTAL_URL">
    <div id="logout">
      <div class="buttons">
      <TMPL_IF NAME="MSG"><TMPL_VAR NAME="MSG"></TMPL_IF>
        <a href="<TMPL_VAR NAME="PORTAL_URL">" class="btn btn-primary" role="button">
          <span class="glyphicon glyphicon-home"></span>&nbsp;
          <lang en="Go to portal" fr="Aller au portail" />
        </a>
      </div>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="LOGOUT_URL">
    <div id="logout">
      <div class="buttons">
        <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="btn btn-danger" role="button">
          <span class="glyphicon glyphicon-log-out"></span>&nbps;
          <lang en="Logout" fr="Se d&eacute;connecter"/>
        </a>
      </div>
    </div>
  </TMPL_IF>

  </div>

<TMPL_INCLUDE NAME="footer.tpl">
