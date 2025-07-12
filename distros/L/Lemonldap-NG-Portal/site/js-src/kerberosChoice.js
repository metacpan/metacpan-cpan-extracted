// Launch Kerberos request
$(document).ready(function() {
  var e;
  e = jQuery.Event("kerberosAttempt");
  $(document).trigger(e);
  if (!e.isDefaultPrevented()) {
    return $.ajax(`${portal}authkrb`, {
      dataType: 'json',
      // Get auth token from success response and post it
      success: function(data) {
        e = jQuery.Event("kerberosSuccess");
        $(document).trigger(e, [data]);
        if (!e.isDefaultPrevented()) {
          if (data.ajax_auth_token) {
            $('#lformKerberos').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token);
          }
          return $('#lformKerberos').submit();
        }
      },
      // Case else, will display PE_BADCREDENTIALS or fallback to next auth
      // backend
      error: function(xhr, status, error) {
        e = jQuery.Event("kerberosFailure");
        $(document).trigger(e, [xhr, status, error]);

        // Check if we are in a choice menu
        var authMenu = $('#authMenu');

        // If this is a choice menu, don't submit form
        if(authMenu.length) {
          var msgBox = $('#errormsg');
          var msgBoxContent = '<div class="message message-negative' +
                              ' alert alert-danger" role="alert">';
          // If this is a regular Kerberos authentication error,
          // display the appropriate error message
          if(error.match(/Unauthorized/i)) {
            msgBoxContent += '<span trmsg="5">' + translate('PE5') + '</span>';
          }
          // Display generic error message
          else {
            msgBoxContent += '<span trmsg="24">' + translate('PE24') + '</span>';
            // If this is an unexpected Kerberos error,
            // display the error in console
            console.error("Error while trying Kerberos authentication: " + error);
          }
            msgBoxContent += '</div>';
            msgBox.html(msgBoxContent);
        }
        // If this is NOT a choice menu, submit form
        else {
          if (!e.isDefaultPrevented()) {
            return $('#lformKerberos').submit();
          }
        }
      }
    });
  }
});
