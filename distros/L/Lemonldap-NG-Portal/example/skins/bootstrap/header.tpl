<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title><lang en="Authentication portal" fr="Portail d'authentification"/></title>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 <meta http-equiv="Content-Script-Type" content="text/javascript" />
 <meta http-equiv="cache-control" content="no-cache" />
 <meta name="viewport" content="width=device-width, initial-scale=1.0">
 <TMPL_IF NAME="browserIdEnabled">
  <meta http-equiv="X-UA-Compatible" content="IE=Edge">
 </TMPL_IF>
 <link href="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/css/bootstrap.css" rel="stylesheet">
 <link href="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/css/bootstrap-theme.css" rel="stylesheet">
 <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/css/styles.css" />
 <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
 <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
 <!--[if lt IE 9]>
   <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
   <script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
 <![endif]-->
 <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="icon" type="image/x-icon" />
 <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="shortcut icon" />
 <TMPL_IF NAME="PROVIDERURI">
  <link rel="openid.server" href="<TMPL_VAR NAME="PROVIDERURI">" />
  <link rel="openid2.provider" href="<TMPL_VAR NAME="PROVIDERURI">" />
 </TMPL_IF>
 <TMPL_INCLUDE NAME="../common/script.tpl">
 <script src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/js/skin.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/portal.js"></script>
 <script src="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/js/bootstrap.js"></script>
 <TMPL_INCLUDE NAME="customhead.tpl">
</head>
<body>

  <div id="wrap">

    <div id="header"><TMPL_INCLUDE NAME="customheader.tpl"></div>

