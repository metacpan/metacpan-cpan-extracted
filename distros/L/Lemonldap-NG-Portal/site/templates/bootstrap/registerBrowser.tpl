<TMPL_INCLUDE NAME="header.tpl">

<main id="redirectcontent" class="container">
  <div class="card border-secondary">
    <div class="card-header text-white bg-secondary">
      <h4 class="text-center card-title"><span trspan="waitingmessage">Please wait...</span></h4>
    </div>
    <div class="card-body">
      <div class="progress">
        <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div>
      </div>
      <noscript>
        <div class="message message-warning alert">It appears that your browser does not support Javascript.</div>
      </noscript>
      <form id="form" action="<TMPL_VAR NAME="ACTION">" method="post">
        <input type="hidden" id="usetotp" name="usetotp" value="<TMPL_VAR NAME="USETOTP">" />
        <input type="hidden" id="totpsecret" name="totpsecret" value="<TMPL_VAR NAME="TOTPSEC">" />
        <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
        <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">">
        <input type="hidden" name="url" value="<TMPL_VAR NAME="URL">" />
        <input type="hidden" name="fg" id="fg" value="" />
        <noscript>
          <input type="submit" />
        </noscript>
      </form>
</main>

<script type="text/JavaScript" src="<TMPL_VAR NAME="SCRIPTNAME">psgi.js"></script>
<!-- //if:usedebianlibs
  <script type="text/javascript" src="/javascript/jquery/jquery.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jssha/dist/sha1.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//elsif:useexternallibs
  <script type="text/javascript" src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jssha/dist/sha1.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//elsif:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jssha/dist/sha1.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jssha/dist/sha1.js?v=<TMPL_VAR CACHE_TAG>"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.js?v=<TMPL_VAR CACHE_TAG>"></script>
<!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
