<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="info" role="form">
    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="SEND_PARAMS">
      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
    </TMPL_IF>
    <div class="card border-info">
      <div class="card-header text-white bg-info">
        <h3 class="card-title" trspan="info">Information</h3>
      </div>
      <div class="card-body">
        <TMPL_VAR NAME="MSG">
      </div>
      <TMPL_IF NAME="ACTIVE_TIMER">
      <div id="divToHide" class="card-footer text-white bg-info">
        <p id="timer" trspan="redirectedIn">You'll be redirected in 30 seconds</p>
      </div>
      </TMPL_IF>
    </div>
    <div class="buttons">
      <button type="submit" class="positive btn btn-success">
        <span class="fa fa-check-circle"></span>
        <span trspan="continue">Continue</span>
      </button>
      <TMPL_IF NAME="ACTIVE_TIMER">
      <button id="wait" type="reset" class="negative btn btn-danger">
        <span class="fa fa-stop"></span>
        <span trspan="wait">Wait</span>
      </button>
      </TMPL_IF>
    </div>
  </form>
  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/info.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/info.js"></script>
  <!-- //endif -->

</div>

<TMPL_INCLUDE NAME="footer.tpl">
