<TMPL_INCLUDE NAME="header.tpl">

<main id="logincontent" class="container">

<div class="message message-positive alert"><span trspan="<TMPL_IF "LEGEND"><TMPL_VAR "LEGEND"><TMPL_ELSE>enterExt2fCode</TMPL_IF>"></span></div>

<div class="card">

<form action="<TMPL_IF "TARGET"><TMPL_VAR "TARGET"><TMPL_ELSE>/ext2fcheck</TMPL_IF>" method="post" class="password" role="form">
  <div class="form">
    <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    <input type="hidden" id="checkLogins" name="checkLogins" value="<TMPL_VAR NAME="CHECKLOGINS">" />
    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-lock"></i> </span>
        <input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />
      </div>
    </div>
  </div>
  <div class="buttons">
    <button type="submit" class="btn btn-success">
      <span class="fa fa-sign-in"></span>
      <span trspan="connect">Connect</span>
    </button>
  </div>
  <br/>
  <div class="buttons">
  <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
    <span class="fa fa-home"></span>
    <span trspan="cancel">Cancel</span>
  </a>
  </div>
</div>
</main>

<TMPL_INCLUDE NAME="footer.tpl">
