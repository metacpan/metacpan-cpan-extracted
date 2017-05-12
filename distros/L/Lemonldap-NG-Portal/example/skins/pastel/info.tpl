<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent">

  <div class="message warning"><ul><li><lang en="Information" fr="Information"/></li></ul></div>

  <div class="loginlogo"></div>

  <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>
    <TMPL_VAR NAME="MSG">
    <p id="timer"><lang en="You'll be redirected in 10 seconds" fr="Vous allez &ecirc;tre redirig&eacute;(e) automatiquement dans 10 secondes"/></p>
    <table><tbody><tr><td>
      <div class="buttons">
        <button type="submit" class="positive">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
          <lang en="Continue" fr="Continuer" />
        </button>
        <button type="reset" class="negative" onclick="stop();">
          <img src="<TMPL_VAR NAME="SKIN_PATH">/common/cancel.png" alt="" />
          <lang en="Wait" fr="Attendre" />
        </button>
      </div>
    </td></tr></tbody></table>
  </form>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/info.js"></script>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
