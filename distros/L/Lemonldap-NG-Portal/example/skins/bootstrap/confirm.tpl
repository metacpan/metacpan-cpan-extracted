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
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />

    <div class="panel panel-info">
      <div class="panel-heading">
        <h3 class="panel-title">
        <TMPL_IF NAME="LIST">
          <lang en="Select your Identity Provider" fr="Choisissez votre fournisseur d'identit&eacute;"/>
        <TMPL_ELSE>
          <lang en="Confirmation" fr="Confirmation"/>
        </TMPL_IF>
        </h3>
      </div>
      <div class="panel-body form">

      <TMPL_VAR NAME="MSG">

      <TMPL_IF NAME="LIST">

      <input type="hidden" id="idp" name="idp"/>

      <div class="row">
      <TMPL_LOOP NAME="LIST">
        <div class="col-sm-6 <TMPL_VAR NAME="class">">
          <button type="submit" class="btn btn-info" onclick="$('#idp').val('<TMPL_VAR NAME="VAL">')">
          <TMPL_IF NAME="icon">
            <img src="<TMPL_VAR NAME="icon">" class="glyphicon" />
          <TMPL_ELSE>
            <i class="glyphicon glyphicon-chevron-right"></i>
          </TMPL_IF>
            <TMPL_VAR NAME="NAME">
          </button>
        </div>
      </TMPL_LOOP>
      </div>

      <TMPL_IF NAME="REMEMBER">
      <div class="checkbox">
        <label for="remember">
          <input type="checkbox" id="remember" name="cookie_type" value="1">
          <lang en="Remember my choice" fr="Se souvenir de mon choix"/>
        </label>
      </div>
      </TMPL_IF>

      <TMPL_ELSE>

      <TMPL_IF NAME="ACTIVE_TIMER">

        <div class="alert alert-info">
          <p id="timer"><lang en="Automatically accept in 5 seconds" fr="Acceptation automatique dans 5 secondes"/></p>
        </div>

        <!-- //if:jsminified
          <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/confirm.min.js"></script>
        //else -->
          <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/confirm.js"></script>
        <!-- //endif -->
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

      <hr />

      <TMPL_INCLUDE NAME="checklogins.tpl">

      </div>
    </div>

  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
