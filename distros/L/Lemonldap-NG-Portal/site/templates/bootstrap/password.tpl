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

    <TMPL_IF NAME="LOGIN">
    <div class="input-group mb-3">
      <input name="user" type="hidden" value="<TMPL_VAR NAME=LOGIN>" />
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-user"></i></span>
      </div>
      <p class="form-control-static"><TMPL_VAR NAME=LOGIN></p>
    </div>
    </TMPL_IF>

    <TMPL_IF NAME="REQUIRE_OLDPASSWORD">

      <TMPL_IF NAME="HIDE_OLDPASSWORD">
        <input id="oldpassword" name="oldpassword" type="hidden" value="<TMPL_VAR NAME=OLDPASSWORD>" aria-required="true">
      <TMPL_ELSE>
        <div class="input-group mb-3">
          <div class="input-group-prepend">
            <span class="input-group-text"><i class="fa fa-lock"></i></span>
          </div>
          <input id="oldpassword" name="oldpassword" type="password" value="<TMPL_VAR NAME=OLDPASSWORD>" class="form-control" trplaceholder="currentPwd" required/ aria-required="true">
        </div>
      </TMPL_IF>

    </TMPL_IF>

    <div class="input-group mb-3">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-lock"></i></span>
      </div>
      <input id="newpassword" name="newpassword" type="password" class="form-control" trplaceholder="newPassword" required aria-required="true"/>
    </div>
    <div class="form-group input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fa fa-lock"></i></span>
      </div>
      <input id="confirmpassword" name="confirmpassword" type="password" class="form-control" trplaceholder="confirmPwd" required aria-required="true"/>
    </div>

    <button type="submit" class="btn btn-success">
      <span class="fa fa-check-circle"></span>
      <span trspan="submit">Submit</span>
    </button>
  </div>
  </form>
