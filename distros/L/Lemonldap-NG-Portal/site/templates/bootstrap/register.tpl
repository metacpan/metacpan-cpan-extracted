<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
  </TMPL_IF>

  <div class="card">

  <TMPL_IF NAME="DISPLAY_FORM">

    <form action="#" method="post" class="login" role="form">
    <div class="form">

    <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
    <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-user"></i> </span>
      </div>
      <input name="firstname" type="text" value="<TMPL_VAR NAME="FIRSTNAME">" class="form-control" trplaceholder="firstName" required aria-required="true"/>
    </div>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-user"></i> </span>
      </div>
      <input name="lastname" type="text" value="<TMPL_VAR NAME="LASTNAME">" class="form-control" trplaceholder="lastName" required aria-required="true"/>
    </div>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-envelope"></i> </span>
      </div>
      <input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" class="form-control" trplaceholder="mail" required aria-required="true"/>
    </div>

    <TMPL_IF NAME=CAPTCHA_SRC>
    <div class="form-group">
      <img src="<TMPL_VAR NAME=CAPTCHA_SRC>" class="img-thumbnail" />
    </div>
    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-eye"></i> </span>
      </div>
      <input type="text" name="captcha" size="<TMPL_VAR NAME=CAPTCHA_SIZE>" class="form-control" placeholder="Captcha" required aria-required="true"/>
    </div>
    </TMPL_IF>
    <TMPL_IF NAME="TOKEN">
      <input type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    </TMPL_IF>

    <button type="submit" class="btn btn-success" >
      <span class="fa fa-envelope-open"></span>
      <span trspan="submit">Submit</span>
    </button>

    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_RESEND_FORM">

    <form action="#" method="post" class="login" role="form">
    <div class="form">

      <input type="hidden" name="skin" value="<TMPL_VAR NAME="SKIN">" />
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <TMPL_IF NAME="CHOICE_VALUE">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      </TMPL_IF>
      <TMPL_IF NAME="FIRSTNAME">
        <input type="hidden" value="<TMPL_VAR NAME="FIRSTNAME">" name="firstname">
      </TMPL_IF>
      <TMPL_IF NAME="LASTNAME">
        <input type="hidden" value="<TMPL_VAR NAME="LASTNAME">" name="lastname">
      </TMPL_IF>
      <TMPL_IF NAME="MAIL">
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      </TMPL_IF>

      <h3 trspan="resendConfirmMail">Resend confirmation mail?</h3>

      <p class="alert alert-info">
        <span trspan="registerRequestAlreadyIssued">A register request for this account was already issued on </span>
        <TMPL_VAR NAME="STARTMAILDATE">.
        <span trspan="resentConfirm">Do you want the confirmation mail to be resent?</span>
      </p>


      <div class="input-group mb-3">
        <div class="input-group-prepend">
          <div class="input-group-text">
            <input id="resendconfirmation" type="checkbox" name="resendconfirmation" ariadescribedby="resendconfirmationlabel">
          </div>
        </div>
        <p class="form-control">
          <label class="form-check-label" id="resendconfirmationlabel" for="resendconfirmation" trspan="yesResendMail">Yes, resend the mail</label>
        </p>
      </div>

      <button type="submit" class="btn btn-success">
        <span class="fa fa-envelope-open"></span>
        <span trspan="submit">Submit</span>
      </button>

    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3 trspan="mailSent2">A message has been sent to your mail address.</h3>
      <p class="alert alert-info">
        <span trspan="confirmLinkSent">A confirmation link has been sent, this link is valid until </span>
        <TMPL_VAR NAME="EXPMAILDATE">.
      </p>
    </div>
    </form>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_MAILSENT">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3 trspan="accountCreated">Your account has been created, your temporary password has been sent to your mail address.</h3>
    </div>
    </form>
  </TMPL_IF>

  </div>

	<div class="buttons">
	  <a href="<TMPL_VAR NAME="PORTAL_URL">?skin=<TMPL_VAR NAME="SKIN"><TMPL_IF NAME="CHOICE_VALUE">&<TMPL_VAR NAME="CHOICE_PARAM">=<TMPL_VAR NAME="CHOICE_VALUE"></TMPL_IF><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>" class="btn btn-primary" role="button">
	    <span class="fa fa-home"></span>
	    <span trspan="back2Portal">Go back to portal</span>
	  </a>
	</div>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
