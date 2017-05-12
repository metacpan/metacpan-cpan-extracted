<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="info" role="form">
    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>
    <div class="panel panel-info">
      <div class="panel-heading">
        <h3 class="panel-title"><lang en="Information" fr="Information"/></h3>
      </div>
      <div class="panel-body">
        <TMPL_VAR NAME="MSG">
      </div>
    </div>
    <div class="alert alert-info">
      <p id="timer"><lang en="You'll be redirected in 10 seconds" fr="Vous allez &ecirc;tre redirig&eacute;(e) automatiquement dans 10 secondes"/></p>
    </div>
      <div class="buttons">
        <button type="submit" class="positive btn btn-success">
          <span class="glyphicon glyphicon-ok"></span>
          <lang en="Continue" fr="Continuer" />
        </button>
        <button type="reset" class="negative btn btn-danger" onclick="stop();">
          <span class="glyphicon glyphicon-stop"></span>
          <lang en="Wait" fr="Attendre" />
        </button>
      </div>
  </form>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/info.js"></script>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
