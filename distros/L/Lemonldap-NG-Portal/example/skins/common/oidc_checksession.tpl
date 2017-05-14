<html>
  <head>
    <title>Check Session</title>
<!-- //if:usedebianlibs
    <script type="text/javascript" src="/javascript/cryptojs/components/sha256-min.js"></script>
    <script type="text/javascript" src="/javascript/cryptojs/components/enc-base64-min.js"></script>
 //elsif:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/sha256.min.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/enc-base64.min.js"></script>
 //else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/sha256.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/enc-base64.js"></script>
 <!-- //endif -->
    <script type="text/javascript">//<![CDATA[
    <TMPL_VAR NAME="JS_CODE">
    //]]></script>
  </head>
  <body>
  </body>
</html>
