<!-- //if:jsminified
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/captcha.min.js"></script>
//else -->
  <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/captcha.js"></script>
<!-- //endif -->

<div class="form-group">
  <img class="renewcaptchaclick" src="<TMPL_VAR NAME="STATIC_PREFIX">common/icons/arrow_refresh.png" alt="Renew Captcha" title="Renew Captcha" class="img-thumbnail mb-3" />
  <img id="captcha" src="<TMPL_VAR NAME=CAPTCHA_SRC>" class="img-thumbnail" />
</div>
<div class="input-group mb-3">
  <div class="input-group-prepend">
    <span class="input-group-text"><label for="captchafield" class="mb-0"><i class="fa fa-eye"></i></label></span>
  </div>
  <input id="captchafield" type="text" name="captcha" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" class="form-control" trplaceholder="captcha" required aria-required="true" autocomplete="off" />
</div>
