<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title><lang en="Authentication portal" fr="Portail d'authentification"/></title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Content-Script-Type" content="text/javascript" />
  <meta http-equiv="cache-control" content="no-cache" />
  <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="icon" type="image/x-icon" />
  <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="shortcut icon" />
  <style type="text/css">
body, a {
  background: #ddd;
  color: #fff;
}
h1 {
  size: 10pt;
  letter-spacing: 5px;
  margin: 100px auto 100px;
}
p, h1 {
  text-align: center;
}
form {
  display: none;
}
  </style>
</head>

<TMPL_IF NAME="HIDDEN_INPUTS">
<body onload="document.getElementById('form').submit()">
<TMPL_ELSE>
<body onload="document.location.href='<TMPL_VAR NAME="URL">'">
</TMPL_IF>

  <h1><lang en="Redirection in progress..." fr="Redirection en cours..."/></h1>
  <noscript>
    <p><lang en="It appears that your browser<br/>does not support Javascript." fr="Il semble que votre navigateur<br/>ne prend pas en charge Javascript."/></p>
  </noscript>
  <TMPL_IF NAME="HIDDEN_INPUTS">
    <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <noscript>
        <input type="submit" value="<lang en="Please click here" fr="Cliquez ici"/>"/>
      </noscript>
    </form>
  <TMPL_ELSE>
    <noscript>
      <p><a href="<TMPL_VAR NAME="URL">"><lang en="Please click here" fr="Cliquez ici"/></a></p>
    </noscript>
  </TMPL_IF>
</body>
</html>

