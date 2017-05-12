<TMPL_INCLUDE NAME="header.tpl">

<div id="menucontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><TMPL_VAR NAME="AUTH_ERROR"></div>
  </TMPL_IF>

  <div id="menu">

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
      <span class="glyphicon glyphicon-home"></span>
    </a>

    </div>

    <TMPL_IF DISPLAY_MODULES>

    <div class="navbar-collapse collapse">
    <!-- Tabs list -->
      <ul class="nav navbar-nav">
        <TMPL_LOOP NAME="DISPLAY_MODULES">

          <TMPL_IF NAME="Appslist">
            <li><a href="#appslist"><span>
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/application_cascade.png" width="16" height="16" alt="appslist" />
              <lang en="Your applications" fr="Vos applications" />
            </span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="ChangePassword">
            <li><a href="#password"><span>
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/vcard_edit.png" width="16" height="16" alt="password" />
              <lang en="Password" fr="Mot de passe" />
            </span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="LoginHistory">
            <li><a href="#loginHistory"><span>
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/calendar.png" width="16" height="16" alt="login history" />
              <lang en="Login history" fr="Historique des connexions" />
            </span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="Logout">
            <li><a href="#logout"><span>
              <img src="<TMPL_VAR NAME="SKIN_PATH">/common/door_out.png" width="16" height="16" alt="logout" />
              <lang en="Logout" fr="D&eacute;connexion" />
            </span></a></li>
          </TMPL_IF>
        </TMPL_LOOP>
      </ul>

      <div class="user navbar-right">
        <p class="navbar-text"><lang en="Connected as" fr="Connect&eacute; en tant que" /> <TMPL_VAR NAME="AUTH_USER"></p>
      </div>

    </div>
    </TMPL_IF>

    </div>

    <!-- Tabs content -->
    <TMPL_LOOP NAME="DISPLAY_MODULES">

      <TMPL_IF NAME="Appslist">
        <div id="appslist">

          <TMPL_LOOP NAME="APPSLIST_LOOP">
          <!-- Template loops -->

            <TMPL_IF NAME="category">
            <!-- Category -->

              <div class="category cat-level-<TMPL_VAR NAME="catlevel"> <TMPL_VAR NAME="catid"> panel panel-info" id="sort_<TMPL_VAR NAME="__counter__">">

                <div class="panel-heading">
                <h3 class="catname panel-title"><TMPL_VAR NAME="catname"></h3>
                </div>

                  <TMPL_IF applications>
                  <div class="panel-body">
                    <!-- Applications -->

                    <div class="row">
                    <TMPL_LOOP NAME=applications>

                      <!-- Application -->
                      <div class="col-md-4">
                      <div class="application <TMPL_VAR NAME="appid"> panel panel-default">
                        <a class="btn btn-link" href="<TMPL_VAR NAME="appuri">" title="<TMPL_VAR NAME="appname">" role="button">

                        <div class="row">
                        <!-- Logo (optional) -->
                        <TMPL_IF NAME="applogo">
                          <div class="col-xs-3">
                          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/apps/<TMPL_VAR NAME="applogo">"
                            class="applogo <TMPL_VAR NAME="appid">"
                            alt="<TMPL_VAR NAME="appname">" />
                          </div>
                          <div class="col-xs-9">
                        <TMPL_ELSE>
                          <div class="col-xs-12">
                        </TMPL_IF>

                        <!-- Name and link (mandatory) -->
                        <h4 class="appname <TMPL_VAR NAME="appid"> text-center">
                          <TMPL_VAR NAME="appname">
                        </h4>

                        <!-- Description (optional) -->
                        <TMPL_IF NAME="appdesc">
                          <p class="appdesc <TMPL_VAR NAME="appid"> hidden-xs">
                            <TMPL_VAR NAME="appdesc">
                          </p>
                        </TMPL_IF>

                          </div>
                        </div>
                        </a>

                      </div>
                      </div>

                    <!-- End of applications loop -->
                    </TMPL_LOOP>
                    </div>

                  </div>
                  </TMPL_IF>

                </div>

              <!-- End of categories loop -->
            </TMPL_IF>
          </TMPL_LOOP>

        </div>
      </TMPL_IF>

      <TMPL_IF NAME="ChangePassword">
        <div id="password">
            <div class="panel panel-info">
              <div class="panel-heading">
              <h3 class="panel-title"><lang en="Change your password" fr="Changez votre mot de passe" /></h3>
              </div>
              <div class="panel-body">
              <TMPL_INCLUDE NAME="password.tpl">
              </div>
            </div>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="LoginHistory">
        <div id="loginHistory">
            <TMPL_IF NAME="SUCCESS_LOGIN">
            <div class="panel panel-info">
              <div class="panel-heading">
              <h3 class="panel-title"><lang en="Last logins" fr="Derni&egrave;res connexions" /></h3>
              </div>
              <div class="panel-body">
              <TMPL_VAR NAME="SUCCESS_LOGIN">
              </div>
            </div>
            </TMPL_IF>
            <TMPL_IF NAME="FAILED_LOGIN">
            <div class="panel panel-info">
              <div class="panel-heading">
              <h3 class="panel-title"><lang en="Last failed logins" fr="Derni&egrave;res connexions refus&eacute;es" /></h3>
              </div>
              <div class="panel-body">
              <TMPL_VAR NAME="FAILED_LOGIN">
              </div>
            </div>
            </TMPL_IF>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="Logout">
        <div id="logout">
          <div class="panel panel-info">
            <div class="panel-heading">
              <h3 class="panel-title"><lang en="Are you sure ?" fr="&Ecirc;tes vous s&ucirc;r ?" /></h3>
            </div>
            <div class="panel-body buttons">
            <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="btn btn-success" role="button">
              <span class="glyphicon glyphicon-ok"></span>
              <lang en="I'm sure" fr="Je suis s&ucirc;r" />
            </a>
            </div>
          </div>
        </div>
      </TMPL_IF>

    </TMPL_LOOP>

  </div>

</div>

<TMPL_IF NAME="PING">
<!-- Keep session alive -->
<script type="text/javascript">
  setTimeout('ping();',pingInterval);
</script>
</TMPL_IF>

<TMPL_INCLUDE NAME="footer.tpl">
