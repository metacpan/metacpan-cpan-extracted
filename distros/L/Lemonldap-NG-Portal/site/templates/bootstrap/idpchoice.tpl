<TMPL_INCLUDE NAME="header.tpl">

<div id="logincontent" class="container">

  <form id="form" action="#" method="<TMPL_VAR NAME="FORM_METHOD">" class="confirm" role="form">

    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <input type="hidden" name="cancel" value="0" />
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
      <div class="card-header text-white bg-info text-center">
        <h3 class="card-title">
          <span trspan="selectIdP">Select your Identity Provider</span>
        </h3>
      </div>
      <div class="card-body">

      <input type="hidden" id="idp" name="idp"/>

      <div class="row text-center">
      <TMPL_LOOP NAME="LIST">
        <div class="col-sm-6 <TMPL_VAR NAME="class"> mb-3">
          <button type="submit" class="btn btn-secondary idploop py-3" val="<TMPL_VAR NAME="VAL">">
          <TMPL_IF NAME="icon">
            <img src="<TMPL_VAR NAME="icon">" class="mr-2" alt="<TMPL_VAR NAME="NAME">" title="<TMPL_VAR NAME="NAME">" />
          <TMPL_ELSE>
            <i class="fa fa-globe mr-2"></i>
            <TMPL_VAR NAME="NAME">
          </TMPL_IF>
          </button>
        </div>
      </TMPL_LOOP>
      </div>

      <!-- //if:jsminified
        <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/idpchoice.min.js"></script>
      //else -->
        <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/idpchoice.js"></script>
      <!-- //endif -->

      </div>
    </div>
    <TMPL_IF NAME="CHOICE_PARAM">
  	  <TMPL_IF NAME="PORTAL_URL">
  	    <div id="logout">
  	      <div class="buttons">
  	        <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1<TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
  	          <span class="fa fa-home"></span>
  	          <span trspan="cancel">Cancel</span>
  	        </a>
  	      </div>
  	    </div>
  	  </TMPL_IF>
    </TMPL_IF>
  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
