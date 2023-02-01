<html>
<head>
  <TMPL_IF NAME="INSTANCE_NAME">
    <title><TMPL_VAR NAME="INSTANCE_NAME"> Manager API</title>
  <TMPL_ELSE>
    <title>LemonLDAP::NG Manager API</title>
  </TMPL_IF>
    <link rel="stylesheet" type="text/css" href="/static/bwr/bootstrap/dist/css/bootstrap.min.css"/>
</head>
<body>
    <div class="container text-center">
        <h1>LemonLDAP::NG Manager API</h1>
        <hr />
        <a href="<TMPL_VAR NAME="DOC_PREFIX">/pages/manager-api/index.html" class="btn btn-lg btn-primary">API Reference</a>
    </div>
</body>
</html>

