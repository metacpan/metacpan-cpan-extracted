<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Information" fr="Information" />
      </div>
      <hr class="solid" />
      <p id="timer" class="text-error"><lang en="You'll be redirected in 10 seconds" fr="Vous allez &ecirc;tre redirig&eacute;(e) automatiquement dans 10 secondes"/></p>
      <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <div id="content-all-info">
        <TMPL_VAR NAME="MSG">
      </div>
        <div class="panel-buttons">
          <button type="reset" class="negative" tabindex="4" onclick="stop();">
            <lang en="Wait" fr="Attendre" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Continue" fr="Continuer" />
          </button>
        </div>
      </form>
    </div>
  </div>
 
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/info.js"></script>

<TMPL_INCLUDE NAME="footer.tpl">

