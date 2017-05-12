  <form action="#" method="post" class="password" role="form">
  <div class="form">
    <TMPL_VAR NAME="HIDDEN_INPUTS">

    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>

    <TMPL_IF NAME="AUTH_URL">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    </TMPL_IF>

    <TMPL_IF NAME="LOGIN">
    <div class="form-group input-group">
      <input name="user" type="hidden" value="<TMPL_VAR NAME=LOGIN>" />
      <span class="input-group-addon"><i class="glyphicon glyphicon-user"></i> </span>
      <p class="form-control-static"><TMPL_VAR NAME=LOGIN></p>
    </div>
    </TMPL_IF>

    <TMPL_IF NAME="REQUIRE_OLDPASSWORD">

      <TMPL_IF NAME="HIDE_OLDPASSWORD">
        <input name="oldpassword" type="hidden" value="<TMPL_VAR NAME=OLDPASSWORD>">
      <TMPL_ELSE>
        <div class="form-group input-group">
          <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
          <input name="oldpassword" type="password" value="<TMPL_VAR NAME=OLDPASSWORD>" class="form-control" placeholder="<lang en="Current password" fr="Mot de passe actuel" />" required/>
        </div>
      </TMPL_IF>

    </TMPL_IF>

    <div class="form-group input-group">
      <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
      <input name="newpassword" type="password" class="form-control" placeholder="<lang en="New password" fr="Nouveau mot de passe" />" required />
    </div>
    <div class="form-group input-group">
      <span class="input-group-addon"><i class="glyphicon glyphicon-lock"></i> </span>
      <input name="confirmpassword" type="password" class="form-control" placeholder="<lang en="Confirm password" fr="Confirmez le mot de passe" />" required/>
    </div>

    <button type="submit" class="btn btn-success" >
      <span class="glyphicon glyphicon-ok"></span>
      <lang en="Submit" fr="Soumettre" />
    </button>
  </div>
  </form>
