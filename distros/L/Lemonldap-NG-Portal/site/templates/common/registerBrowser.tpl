<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title>Register browser</title>
</head>
<body>
 <p>Please wait...</p>
 <form id="form" action="<TMPL_VAR NAME="ACTION">" method="post">
  <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
  <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">">
  <input type="hidden" name="url" value="<TMPL_VAR NAME="URL">" />
  <input type="hidden" name="fg" id="fg" value="" />
 </form>
 <!-- //if:usedebianlibs
  <script type="text/javascript" src="/javascript/jquery/jquery.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/fingerprintjs2/fingerprint2.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js"></script>
//elsif:useexternallibs
  <script type="text/javascript" src="http://code.jquery.com/jquery-2.2.0.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/fingerprintjs2/fingerprint2.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js"></script>
 //elsif:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/fingerprintjs2/fingerprint2.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.min.js"></script>
 //else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/jquery/dist/jquery.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/fingerprintjs2/fingerprint2.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/registerbrowser.js"></script>
 <!-- //endif -->
</body>
</html>
