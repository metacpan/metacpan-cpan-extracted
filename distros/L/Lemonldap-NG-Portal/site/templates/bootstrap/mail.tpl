<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
    <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert">
    <span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_FORM">
  <div class="card">
    <form action="#" method="post" class="login" role="form">
    <div class="form">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>

      <h3 trspan="forgotPwd">Forgot your password?</h3>

      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <span class="input-group-text"><i class="fa fa-envelope"></i> </span>
        </div>
        <input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" class="form-control" trplaceholder="mail" required />
      </div>

      <TMPL_IF NAME=CAPTCHA_SRC>
        <div class="form-group">
          <img src="<TMPL_VAR NAME=CAPTCHA_SRC>" class="img-thumbnail" />
        </div>
        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><i class="fa fa-eye"></i> </span>
          </div>
          <input type="text" name="captcha" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" class="form-control" trplaceholder="captcha" required autocomplete="off" />
        </div>
      </TMPL_IF>
      <TMPL_IF NAME="TOKEN">
        <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      </TMPL_IF>

      <button type="submit" class="btn btn-success">
        <span class="fa fa-envelope-open"></span>
        <span trspan="sendPwd">Send me a link</span>
      </button>

    </div>
    </form>
  </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_RESEND_FORM">
  <div class="card">
    <form action="#" method="post" class="login" role="form">
    <div class="form">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <TMPL_IF NAME="MAIL">
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      </TMPL_IF>

      <TMPL_IF NAME="TOKEN">
        <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
      </TMPL_IF>

      <h3 trspan="resendConfirmMail">Resend confirmation mail?</h3>

      <p class="alert alert-info">
        <span trspan="pwdResetAlreadyIssued">A password reset request was already issued on</span>
        <TMPL_VAR NAME="STARTMAILDATE">.
        <span trspan="resentConfirm">Do you want the confirmation mail to be resent?</span>
      </p>

      <TMPL_IF NAME=CAPTCHA_SRC>
        <div class="form-group">
          <img src="<TMPL_VAR NAME=CAPTCHA_SRC>" class="img-thumbnail" />
        </div>
        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><i class="fa fa-eye"></i> </span>
          </div>
          <input type="text" name="captcha" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" class="form-control" trplaceholder="captcha" required autocomplete="off"/>
        </div>
      </TMPL_IF>

      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <div class="input-group-text">
            <input id="resendconfirmation" type="checkbox" name="resendconfirmation" aria-describedby="resendconfirmationlabel" />
          </div>
        </div>
        <p class="form-control">
          <label for="resendconfirmation" id="resendconfirmationlabel" trspan="confirmPwd">Yes, resend the mail</label>
        </p>
      </div>

      <button type="submit" class="btn btn-success">
        <span class="fa fa-envelope-open"></span>
        <span trspan="submit">Submit</span>
      </button>

    </div>
    </form>
  </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_PASSWORD_FORM">
    <div class="card" id="password">
      <form action="#" method="post" class="password" role="form">
      <div class="form">

        <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
        <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
        <TMPL_IF NAME="CHOICE_VALUE">
          <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        </TMPL_IF>

        <TMPL_IF NAME="TOKEN">
          <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
        </TMPL_IF>

        <h3 trspan="changePwd">Change your password</h3>

        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><i class="fa fa-lock"></i> </span>
          </div>
          <input name="newpassword" type="password" class="form-control" trplaceholder="newPassword" />
        </div>

        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><i class="fa fa-lock"></i> </span>
          </div>
          <input name="confirmpassword" type="password" class="form-control" trplaceholder="confirmPwd" />
        </div>

        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <div class="input-group-text">
              <input id="reset" type="checkbox" name="reset" aria-describedby="resetlabel" />
            </div>
          </div>
          <p class="form-control">
            <label for="reset" id="resetlabel" trspan="generatePwd">Generate the password automatically</label>
          </p>
        </div>

        <button type="submit" class="btn btn-success">
          <span class="fa fa-envelope-open"></span>
          <span trspan="submit">Submit</span>
        </button>

      </div>
      </form>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <div class="card">
    <form action="#" method="post" class="login" role="form">
      <div class="form">
        <h3 trspan="mailSent2">A message has been sent to your mail address.</h3>
        <p class="alert alert-info">
          <span trspan="linkValidUntil">This message contains a link to reset your password. This link is valid until </span>
          <TMPL_VAR NAME="EXPMAILDATE">.
        </p>
      </div>
    </form>
    </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <div class="card">
    <form action="#" method="post" class="login" role="form">
      <div class="form">
        <h3 trspan="newPwdSentTo">A confirmation has been sent to your mail address.</h3>
      </div>
    </form>
    </div>
  </TMPL_IF>

  <div class="buttons">
    <a href="<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="CHOICE_VALUE">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="CHOICE_VALUE"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
      <span class="fa fa-home"></span>
      <span trspan="back2Portal">Go back to portal</span>
    </a>
  </div>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
