<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <form id="form" action="#" method="<TMPL_VAR NAME="FORM_METHOD">" class="confirm" role="form">

    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="AUTH_URL">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    </TMPL_IF>
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>
    <TMPL_IF NAME="CONFIRMKEY">
      <input type="hidden" id="confirm" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">" />
    </TMPL_IF>

    <div class="panel panel-info">
      <div class="panel-heading">
        <h3 class="panel-title"><lang en="Confirmation" fr="Confirmation"/></h3>
      </div>
      <div class="panel-body form">

      <TMPL_VAR NAME="MSG">

      <TMPL_IF NAME="LIST">

      <h3><lang en="Select your Identity Provider" fr="Choisissez votre fournisseur d'identité"/></h3>
      <input type="hidden" id="idp" name="idp"/>

      <TMPL_LOOP NAME="LIST">
          <button type="submit" class="positive btn btn-info" onclick="$('#idp').val('<TMPL_VAR NAME="VAL">')">
            <span class="glyphicon glyphicon-chevron-right"></span>
            <TMPL_VAR NAME="NAME">
          </button>
      </TMPL_LOOP>

      <div class="checkbox">
        <label for="remember">
          <input type="checkbox" id="remember" name="cookie_type" value="1">
          <lang en="Remember my choice" fr="Se souvenir de mon choix"/>
        </label>
      </div>

      <TMPL_ELSE>

      <TMPL_IF NAME="ACTIVE_TIMER">

        <div class="alert alert-info">
          <p id="timer"><lang en="Automatically accept in 5 seconds" fr="Acceptation automatique dans 5 secondes"/></p>
        </div>

        <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/confirm.js"></script>
      </TMPL_IF>

      <div class="buttons">
        <button type="submit" class="positive btn btn-success">
          <span class="glyphicon glyphicon-ok"></span>
          <lang en="Accept" fr="Accepter" />
        </button>
        <button type="submit" class="negative btn btn-danger" onclick="$('#confirm').attr('value','-<TMPL_VAR NAME="CONFIRMKEY">');">
          <span class="glyphicon glyphicon-stop"></span>
          <lang en="Refuse" fr="Refuser" />
        </button>
      </div>

      </TMPL_IF>

      <TMPL_INCLUDE NAME="checklogins.tpl">

      </div>
    </div>

  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
