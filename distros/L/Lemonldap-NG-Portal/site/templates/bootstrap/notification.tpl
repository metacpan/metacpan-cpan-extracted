<TMPL_INCLUDE NAME="header.tpl">

<div id="notifcontent" class="container">

  <form action="/notifback" method="post" class="notif" role="form">
    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>
    <TMPL_IF NAME="AUTH_URL">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    </TMPL_IF>
    <div class="card border-info">
      <div class="card-header text-white bg-info">
        <h3 class="card-title" trspan="gotNewMessages">You have some new messages</h3>
      </div>
      <div class="card-body">
        <div class="form">
        <TMPL_VAR NAME="NOTIFICATION">
        </div>
      </div>
    </div>

    <div class="buttons">
      <a id="goback" href="<TMPL_VAR NAME="PORTAL_URL">notifback?cancel=1" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="cancel">Cancel</span>
      </a>
      <button type="submit" class="positive btn btn-success">
        <span class="fa fa-check-circle"></span>
        <span trspan="accept">Accept</span>
      </button>
    </div>

  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
