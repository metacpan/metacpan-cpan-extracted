<TMPL_INCLUDE NAME="header.tpl">

<div id="mailcontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
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

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="firstnamefield" class="mb-0"><i class="fa fa-user"></i></label></span>
      </div>
      <input id="firstnamefield" name="firstname" type="text" value="<TMPL_VAR NAME="FIRSTNAME">" class="form-control" trplaceholder="firstName" required aria-required="true" autocomplete="given-name" />
    </div>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="lastnamefield" class="mb-0"><i class="fa fa-user"></i></label></span>
      </div>
      <input id="lastnamefield" name="lastname" type="text" value="<TMPL_VAR NAME="LASTNAME">" class="form-control" autocomplete="family-name" trplaceholder="lastName" required aria-required="true"/>
    </div>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><label for="mailfield" class="mb-0"><i class="fa fa-envelope"></i></label></span>
      </div>
      <input id="mailfield" name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" class="form-control" trplaceholder="mail" required aria-required="true" autocomplete="email" />
    </div>

    <TMPL_IF NAME=CAPTCHA_HTML>
      <TMPL_VAR NAME=CAPTCHA_HTML>
    </TMPL_IF>
    <TMPL_IF NAME="TOKEN">
      <input id="token" type="hidden" name="token" value="<TMPL_VAR NAME="TOKEN">" />
    </TMPL_IF>

    <button type="submit" class="btn btn-success" >
      <span class="fa fa-envelope-open"></span>
      <span trspan="submit">Submit</span>
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
            <input class="form-check-input" id="resendconfirmation" type="checkbox" name="resendconfirmation" ariadescribedby="resendconfirmationlabel">
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
  </div>
  </TMPL_IF>

  <TMPL_IF NAME="DISPLAY_CONFIRMMAILSENT">
  <div class="card">
    <form action="#" method="post" class="login" role="form">
    <div class="form">
      <h3 trspan="mailSent2">A message has been sent to your mail address.</h3>
      <p class="alert alert-info">
        <span trspan="confirmLinkSent">A confirmation link has been sent, this link is valid until </span>
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
      <h3 trspan="accountCreated">Your account has been created, your temporary password has been sent to your mail address.</h3>
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
