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
            $('#lform').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token);
          }
          return $('#lform').submit();
        }
      },
      // Case else, will display PE_BADCREDENTIALS or fallback to next auth
      // backend
      error: function(xhr, status, error) {
        e = jQuery.Event("kerberosFailure");
        $(document).trigger(e, [xhr, status, error]);
        if (!e.isDefaultPrevented()) {
          return $('#lform').submit();
        }
      }
    });
  }
});