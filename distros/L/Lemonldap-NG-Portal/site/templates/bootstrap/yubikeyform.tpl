<div class="form">
  <div class="input-group mb-3">
    <div class="input-group-prepend">
      <span class="input-group-text"><label for="yubikeyOTPfield" class="mb-0"><i class="fa fa-chevron-right"></i></label></span>
    </div>
    <input id="yubikeyOTPfield"  name="yubikeyOTP" type="text" class="form-control" trplaceholder="enterYubikey" aria-required="true" autocomplete="off" />
  </div>

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success" >
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </button>
</div>
