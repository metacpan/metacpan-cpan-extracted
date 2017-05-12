<div class="form">
  <div class="form-group input-group">
    <span class="input-group-addon"><i class="glyphicon glyphicon-link"></i> </span>
    <input name="openid_identifier" type="text" class="form-control" placeholder="<lang en="Please enter your OpenID login" fr="Entrez votre identifiant OpenID"/>" />
  </div>

  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="glyphicon glyphicon-log-in"></span>
    <lang en="Connect" fr="Se connecter" />
  </button>
</div>
