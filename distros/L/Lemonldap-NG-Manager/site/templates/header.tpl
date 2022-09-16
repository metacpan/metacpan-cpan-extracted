<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <link rel="shortcut icon" type="image/vnd.microsoft.icon" sizes="16x16 32x32 48x48 64x64 128x128" href="<TMPL_VAR NAME="STATIC_PREFIX">logos/favicon.ico" />
  <link rel="icon" type="image/vnd.microsoft.icon" sizes="16x16 32x32 48x48 64x64 128x128" href="<TMPL_VAR NAME="STATIC_PREFIX">logos/favicon.ico" />
<!-- //if:usedebianlibs
  <link rel="stylesheet" type="text/css" href="/javascript/angular.js/angular-csp.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.min.css" />
  <link rel="stylesheet" type="text/css" href="/javascript/bootstrap/css/bootstrap.min.css" />
  <link rel="stylesheet" type="text/css" href="/javascript/bootstrap/css/bootstrap-theme.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-csp.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">css/manager.min.css" />
//elsif:useexternallibs
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular/angular-csp.min.css" />
  <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/angular-ui-tree/2.13.0/angular-ui-tree.min.css" />
  <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"></script>
  <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css"></script>
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-csp.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">css/manager.min.css" />
//elsif:cssminified
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular/angular-csp.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/bootstrap/dist/css/bootstrap.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/bootstrap/dist/css/bootstrap-theme.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-csp.min.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">css/manager.min.css" />
//else -->
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular/angular-csp.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/bootstrap/dist/css/bootstrap.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/bootstrap/dist/css/bootstrap-theme.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-csp.css" />
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX">css/manager.css" />
  <TMPL_IF NAME="CUSTOM_CSS">
  <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="STATIC_PREFIX"><TMPL_VAR NAME="CUSTOM_CSS">" />
  </TMPL_IF>
<!-- //endif -->
