<TMPL_INCLUDE NAME="header.tpl">

<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">/common/js/redirect.min.js"></script>
<script id="redirect" type="custom">
<TMPL_IF NAME="HIDDEN_INPUTS">
form
<TMPL_ELSE>
<TMPL_VAR NAME="URL">
</TMPL_IF>
</script>

<main id="redirectcontent" class="container">
  <div class="card border-secondary">
    <div class="card-header text-white bg-secondary">
      <h4 class="text-center card-title"><span trspan="redirectionInProgress">Redirection in progress...</span></h4>
    </div>
    <div class="card-body">
      <div class="progress">
        <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div>
      </div>
  <noscript>
    <div class="message message-warning alert">It appears that your browser does not support Javascript.</div>
  </noscript>
  <TMPL_IF NAME="HIDDEN_INPUTS">
    <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <noscript>
        <input type="submit" />
      </noscript>
    </form>
  <TMPL_ELSE>
    <noscript>
      <p><a href="<TMPL_VAR NAME="URL">">Please click here</a></p>
    </noscript>
  </TMPL_IF>
    </div>
  </div>
</main>

<TMPL_INCLUDE NAME="footer.tpl">
