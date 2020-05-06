<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <form id="form" action="<TMPL_VAR NAME="FORM_ACTION">" method="<TMPL_VAR NAME="FORM_METHOD">" class="confirm" role="form">

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

    <div class="card border-info">
      <div class="card-header text-white bg-info">
        <h3 class="card-title">
          <span trspan="confirmation">Confirmation</span>
        </h3>
      </div>
      <div class="card-body">

      <TMPL_VAR NAME="MSG">

      <div class="buttons">
        <button type="submit" class="positive btn btn-success">
          <span class="fa fa-check-circle"></span>
          <span trspan="accept">Accept</span>
        </button>
        <button id="refuse" type="submit" class="negative btn btn-danger" val="-<TMPL_VAR NAME="CONFIRMKEY">">
          <span class="fa fa-times-circle"></span>
          <span trspan="refuse">Refuse</span>
        </button>
      </div>

      </div>

      <TMPL_IF NAME="ACTIVE_TIMER">
        <div class="card-footer bg-info">
          <p id="timer" trspan="autoAccept">Automatically accept in 30 seconds</p>
        </div>
      </TMPL_IF>

    </div>

      <!-- //if:jsminified
        <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/confirm.min.js"></script>
      //else -->
        <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/confirm.js"></script>
      <!-- //endif -->

	  <TMPL_IF NAME="PORTAL_URL">
	    <div id="logout">
	      <div class="buttons">
	        <a href="<TMPL_VAR NAME="PORTAL_URL">/?cancel=1<TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
	          <span class="fa fa-home"></span>
	          <span trspan="cancel">Cancel</span>
	        </a>
	      </div>
	    </div>
	  </TMPL_IF>

  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
