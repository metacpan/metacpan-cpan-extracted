<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <TMPL_IF NAME="AUTH_ERROR">
      <div class="title">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <TMPL_VAR NAME="AUTH_ERROR">
      </div>
      <hr class="solid" />
      </TMPL_IF>
      <p>
        <span class="text-error"><lang en="Connected as" fr="Connect&eacute; en tant que " />: <u><TMPL_VAR NAME="AUTH_USER"></u></span>
      </p>

      <div id="menu">

      <TMPL_IF DISPLAY_MODULES>
        <ul>
        <TMPL_LOOP NAME="DISPLAY_MODULES">
          <TMPL_IF NAME="Appslist">
          <li><a href="#appslist"><span><img src="<TMPL_VAR NAME="SKIN_PATH">/common/application_cascade.png" width="16" height="16" alt="appslist" /> <lang en="Your applications" fr="Vos applications" /></span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="ChangePassword">
          <li><a href="#password"><span><img src="<TMPL_VAR NAME="SKIN_PATH">/common/vcard_edit.png" width="16" height="16" alt="password" /> <lang en="Password" fr="Mot de passe" /></span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="LoginHistory">
          <li><a href="#loginHistory"><span><img src="<TMPL_VAR NAME="SKIN_PATH">/common/calendar.png" width="16" height="16" alt="login history" /> <lang en="Login history" fr="Historique des connexions" /></span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="Logout">
          <li><a href="#logout"><span><img src="<TMPL_VAR NAME="SKIN_PATH">/common/door_out.png" width="16" height="16" alt="logout" /> <lang en="Logout" fr="Se d&eacute;connecter" /></span></a></li>
          </TMPL_IF>
        </TMPL_LOOP>
        </ul>
      </TMPL_IF>

      <div id="content-all-info2">

      <TMPL_IF DISPLAY_MODULES>

        <TMPL_LOOP NAME="DISPLAY_MODULES">

        <TMPL_IF NAME="Appslist">
        <div id="appslist">
          <p class="text-label">
            <lang en="Choose an application your are allowed to access to" fr="Choisissez une application &agrave; laquelle vous &ecirc;tes autoris&eacute; &agrave; acc&eacute;der" /> :
          </p>
                <TMPL_LOOP NAME="APPSLIST_LOOP">
                <!-- Template loops -->

                <TMPL_IF NAME="category">
                <!-- Category -->

                <div class="category cat-level-<TMPL_VAR NAME="catlevel"> <TMPL_VAR NAME="catid">" id="sort_<TMPL_VAR NAME="__counter__">">
                <h3 class="catname"><TMPL_VAR NAME="catname"></h3>

                <TMPL_IF applications>
                <!-- Applications -->

                <TMPL_LOOP NAME=applications>

                <!-- Application -->

                <div class="application <TMPL_VAR NAME="appid">">

                <!-- Logo (optional) -->
                <TMPL_IF NAME="applogo">
                <img    src="<TMPL_VAR NAME="SKIN_PATH">/common/apps/<TMPL_VAR NAME="applogo">"
                        class="applogo <TMPL_VAR NAME="appid">"
                        alt="<TMPL_VAR NAME="appname">" />
                </TMPL_IF>

                <!-- Name and link (mandatory) -->
                <h4 class="appname <TMPL_VAR NAME="appid">">
                <a href="<TMPL_VAR NAME="appuri">" alt="<TMPL_VAR NAME="appname">">
                <TMPL_VAR NAME="appname">
                </a>
                </h4>

                <!-- Logo (optional) -->
                <TMPL_IF NAME="appdesc">
                <p class="appdesc <TMPL_VAR NAME="appid">">
                <TMPL_VAR NAME="appdesc">
                </p>
                </TMPL_IF>

                <div class="clearfix"></div>
                </div>

                <!-- End of applications loop -->
                </TMPL_LOOP>
                </TMPL_IF>

                <TMPL_IF categories>
                <!-- Sub categories -->

                <TMPL_LOOP NAME=categories>
                <div class="category cat-level-<TMPL_VAR NAME="catlevel">">
                <h3 class="catname"><TMPL_VAR NAME="catname"></h3>

                <TMPL_IF applications>
                <!-- Applications in sub category -->

                <TMPL_LOOP NAME=applications>

                <!-- Application in sub category-->

                <div class="application <TMPL_VAR NAME="appid">">

                <!-- Logo (optional) -->
                <TMPL_IF NAME="applogo">
                <img    src="<TMPL_VAR NAME="SKIN_PATH">/common/apps/<TMPL_VAR NAME="applogo">"
                        class="applogo <TMPL_VAR NAME="appid">"
                        alt="<TMPL_VAR NAME="appname">" />
                </TMPL_IF>

                <!-- Name and link (mandatory) -->
                <h4 class="appname <TMPL_VAR NAME="appid">">
                <a href="<TMPL_VAR NAME="appuri">" alt="<TMPL_VAR NAME="appname">">
                <TMPL_VAR NAME="appname">
                </a>
                </h4>

                <!-- Logo (optional) -->
                <TMPL_IF NAME="appdesc">
                <p class="appdesc <TMPL_VAR NAME="appid">">
                <TMPL_VAR NAME="appdesc">
                </p>
                </TMPL_IF>

                <div class="clearfix"></div>
                </div>

                <!-- End of applications loop -->
                </TMPL_LOOP>
                </TMPL_IF>

                <div class="clearfix"></div>
                </div>

                <!-- End of sub categories loop -->
                </TMPL_LOOP>
                </TMPL_IF>

                <div class="clearfix"></div>
                </div>

                <!-- End of categories loop -->
                </TMPL_IF>
                </TMPL_LOOP>

        </div>
        </TMPL_IF>

	<TMPL_IF NAME="ChangePassword">
        <TMPL_INCLUDE NAME="password.tpl">
        </TMPL_IF>

        <TMPL_IF NAME="LoginHistory">
          <div id="loginHistory">
            <div class="form">
              <TMPL_IF NAME="SUCCESS_LOGIN">
              <h3><lang en="Last logins" fr="Derni&egrave;res connexions" /></h3>
              <TMPL_VAR NAME="SUCCESS_LOGIN">
              </TMPL_IF>
              <TMPL_IF NAME="FAILED_LOGIN">
              <h3><lang en="Last failed logins" fr="Derni&egrave;res connexions refusées" /></h3>
              <TMPL_VAR NAME="FAILED_LOGIN">
              </TMPL_IF>
            </div>
          </div>
        </TMPL_IF>


        <TMPL_IF NAME="Logout">
        <div id="logout">
          <p class="text-label">
            <lang en="Are you sure?" fr="&Ecirc;tes vous s&ucirc;r ?" />
          </p>
          <button type="submit" class="positive" onclick="location.href='<TMPL_VAR NAME="LOGOUT_URL">';return false;">
            <lang en="I'm sure" fr="Je suis s&ucirc;r" />
          </button>
        </div>
        </TMPL_IF>

	</TMPL_LOOP>

      </TMPL_IF>

        </div>
      </div>
    </div>
  </div>

<TMPL_IF NAME="PING">
<!-- Keep session alive -->
<script type="text/javascript">
  setTimeout('ping();',pingInterval);
</script>
</TMPL_IF>

<TMPL_INCLUDE NAME="footer.tpl">

