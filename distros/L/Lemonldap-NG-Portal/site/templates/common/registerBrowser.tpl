<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title>Register browser</title>
</head>
<body>
 <p>Please wait...</p>
 <form id="form" action="<TMPL_VAR NAME="ACTION">" method="post">
  <input type="hidden" id="usetotp" name="usetotp" value="<TMPL_VAR NAME="USETOTP">" />
  <input type="hidden" id="totpsecret" name="totpsecret" value="<TMPL_VAR NAME="TOTPSEC">" />
  <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
  <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">">
  <input type="hidden" name="url" value="<TMPL_VAR NAME="URL">" />
  <input type="hidden" name="fg" id="fg" value="" />
 </form>
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
</body>
</html>
