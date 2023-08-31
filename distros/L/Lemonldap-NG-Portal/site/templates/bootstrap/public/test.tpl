<TMPL_INCLUDE NAME="header.tpl">

<div class="container">

  <div class="alert alert-success">Public page example</div>

  <div class="card">
    <p>You can have some public pages using LLNG framework. To enable this:</p>
    <ul>
      <li>Add "<tt>customPlugins = ::Plugins::PublicPages</tt>" in your
       "lemonldap-ng.ini" file to enable this plugin;</li>
      <li>Create a "public" subdir in your template directory;</li>
      <li>Create your .tpl files inside;</li>
      <li>To access them, use "http://auth.your.domain/public/name" where "name"
       is the template name <i>(without .tpl).</i>
    </ul>
    <div class="buttons">
    <TMPL_IF NAME="MSG"><TMPL_VAR NAME="MSG"></TMPL_IF>
      <a href="<TMPL_VAR NAME="PORTAL_URL">?cancel=1" class="btn btn-primary" role="button">
        <span class="fa fa-home"></span>
        <span trspan="goToPortal">Go to portal</span>
      </a>
    </div>
  </div>
</div>

<TMPL_INCLUDE NAME="footer.tpl">
