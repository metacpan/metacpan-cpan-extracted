  <form id="formpass" action="#" method="post" class="password" role="form">
  <div class="form">
    <TMPL_VAR NAME="HIDDEN_INPUTS">

    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>

    <TMPL_IF NAME="AUTH_URL">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    </TMPL_IF>
    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />

    <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    </TMPL_IF>

    <TMPL_IF NAME="LOGIN">
    <div class="input-group mb-3">
      <input name="user" type="hidden" value="<TMPL_VAR NAME=LOGIN ESCAPE=HTML>" />
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="staticUser" class="mb-0"><i class="fa fa-user"></i></label></span>
      </div>
      <input id="staticUser" type="text" readonly class="form-control" value="<TMPL_VAR NAME=LOGIN ESCAPE=HTML>" />
    </div>
    </TMPL_IF>

    <TMPL_IF NAME="REQUIRE_OLDPASSWORD">
      <TMPL_IF NAME="HIDE_OLDPASSWORD">
        <input id="oldpassword" name="oldpassword" type="hidden" value="<TMPL_VAR NAME=OLDPASSWORD>" aria-required="true">
      <TMPL_ELSE>
        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><label for="oldpassword" class="mb-0"><i class="fa fa-lock"></i></label></span>
          </div>
          <TMPL_IF NAME="DONT_STORE_PASSWORD">
            <input id="oldpassword" name="oldpassword" type="text" value="<TMPL_VAR NAME=OLDPASSWORD>" class="form-control" trplaceholder="currentPwd" autocomplete="off" required aria-required="true">
            <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
              <div class="input-group-append">
                <span class="input-group-text"><i id="toggle_oldpassword" class="fa fa-eye-slash toggle-password"></i></span>
              </div>
            </TMPL_IF>
          <TMPL_ELSE>
            <input id="oldpassword" name="oldpassword" type="password" value="<TMPL_VAR NAME=OLDPASSWORD>" class="form-control" trplaceholder="currentPwd" required aria-required="true">
            <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
              <div class="input-group-append">
                <span class="input-group-text"><i id="toggle_oldpassword" class="fa fa-eye-slash toggle-password"></i></span>
              </div>
            </TMPL_IF>
          </TMPL_IF>
        </div>
      </TMPL_IF>
    </TMPL_IF>

    <TMPL_IF NAME="DISPLAY_PPOLICY"><TMPL_INCLUDE NAME="passwordpolicy.tpl"></TMPL_IF>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="newpassword" class="mb-0"><i class="fa fa-lock"></i></label></span>
      </div>
      <TMPL_IF NAME="DONT_STORE_PASSWORD">
        <input id="newpassword" name="newpassword" type="text" class="form-control" trplaceholder="newPassword" autocomplete="off" required aria-required="true"/>
        <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
          <div class="input-group-append">
            <span class="input-group-text"><i id="toggle_newpassword" class="fa fa-eye-slash toggle-password"></i></span>
          </div>
        </TMPL_IF>
      <TMPL_ELSE>
        <input id="newpassword" name="newpassword" type="password" class="form-control" trplaceholder="newPassword" required aria-required="true"/>
        <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
          <div class="input-group-append">
            <span class="input-group-text"><i id="toggle_newpassword" class="fa fa-eye-slash toggle-password"></i></span>
          </div>
        </TMPL_IF>
      </TMPL_IF>
    </div>
    <div class="form-group input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="confirmpassword" class="mb-0"><i class="fa fa-lock"></i></label></span>
      </div>
      <TMPL_IF NAME="DONT_STORE_PASSWORD">
        <input id="confirmpassword" name="confirmpassword" type="text" class="form-control" trplaceholder="confirmPwd" autocomplete="off" required aria-required="true"/>
        <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
          <div class="input-group-append">
            <span class="input-group-text"><i id="toggle_confirmpassword" class="fa fa-eye-slash toggle-password"></i></span>
          </div>
        </TMPL_IF>
      <TMPL_ELSE>
        <input id="confirmpassword" name="confirmpassword" type="password" class="form-control" trplaceholder="confirmPwd" required aria-required="true"/>
        <TMPL_IF NAME="ENABLE_PASSWORD_DISPLAY">
          <div class="input-group-append">
            <span class="input-group-text"><i id="toggle_confirmpassword" class="fa fa-eye-slash toggle-password"></i></span>
          </div>
        </TMPL_IF>
      </TMPL_IF>
    </div>
  <TMPL_IF NAME=CAPTCHA_HTML>
    <TMPL_VAR NAME=CAPTCHA_HTML>
  </TMPL_IF>
    <div class="buttons">
      <button type="submit" class="btn btn-success">
        <span class="fa fa-check-circle"></span>
        <span trspan="submit">Submit</span>
      </button>
    </div>
  </div>
  </form>
