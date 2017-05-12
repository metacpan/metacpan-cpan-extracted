<div class="form">
  <div class="form-group input-group">
    <span class="input-group-addon"><i class="glyphicon glyphicon-chevron-right"></i> </span>
    <input name="yubikeyOTP" type="text" class="form-control" placeholder="<lang en="Please use your Yubikey" fr="Utilisez votre Yubikey"/>" />
  </div>

  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="glyphicon glyphicon-log-in"></span>
    <lang en="Connect" fr="Se connecter" />
  </button>
</div>
