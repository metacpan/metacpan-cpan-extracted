<TMPL_INCLUDE NAME="header.tpl">

<div id="notifcontent">
  
  <div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li>
    <lang en="You have some new messages" fr="Vous avez de nouveaux messages"/>
  </li></ul></div>

  <div class="loginlogo"></div>

  <form action="#" method="post" class="login">
    <TMPL_VAR NAME="HIDDEN_INPUTS">
    <TMPL_IF NAME="CHOICE_VALUE">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
    </TMPL_IF>
    <TMPL_IF NAME="AUTH_URL">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
    </TMPL_IF>
    <h3><lang en="New message(s)" fr="Nouveaux messages"/>&nbsp;:</h3>
    <table>
      <tr><td>
        <TMPL_VAR NAME="NOTIFICATION">
        <div class="buttons">
          <button type="submit" class="positive">
            <img src="<TMPL_VAR NAME="SKIN_PATH">/common/accept.png" alt="" />
            <lang en="Accept" fr="Accepter" />
          </button>
        </div>
      </td></tr>
    </table>
  </form>

</div>

<TMPL_INCLUDE NAME="footer.tpl">
