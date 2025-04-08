// Launch SSL request
var sendUrl, tryssl;

tryssl = function(myevent) {
  var e, form, path;
  form = $(myevent.currentTarget).closest('form');
  path = window.location.pathname;
  console.log('path -> ', path);
  console.log('Call URL -> ', window.datas.sslHost);
  e = jQuery.Event("sslAttempt");
  $(document).trigger(e);
  if (!e.isDefaultPrevented()) {
    $.ajax(window.datas.sslHost, {
      dataType: 'json',
      xhrFields: {
        withCredentials: true
      },
      // If request succeed, posting form to get redirection
      // or menu
      success: function(data) {
        console.log('Success -> ', data);
        e = jQuery.Event("sslSuccess");
        $(document).trigger(e, [data]);
        if (!e.isDefaultPrevented()) {
          // If we contain a ajax_auth_token, add it to form
          if (data.ajax_auth_token) {
            form.find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token);
          }
          return sendUrl(form, path);
        }
      },
      // Case else, will display PE_BADCREDENTIALS or fallback to next auth
      // backend
      error: function(result) {
        console.log('Error during AJAX SSL authentication', result);
        e = jQuery.Event("sslFailure");
        $(document).trigger(e, [result]);
        if (!e.isDefaultPrevented()) {
          // If the AJAX query didn't fire at all, it's probably
          // a bad certificate
          if (result.status === 0) {
            // We couldn't send the request.
            // if client verification is optional, this means
            // the certificate was rejected (or some network error)
            sendUrl(form, path);
          }
          // For compatibility with earlier configs, handle PE9 by posting form
          if (result.responseJSON && 'error' in result.responseJSON && result.responseJSON.error === "9") {
            sendUrl(form, path);
          }
          // If the server sent a html error description, display it
          if (result.responseJSON && 'html' in result.responseJSON) {
            $('#errormsg').html(result.responseJSON.html);
            return $(window).trigger('load');
          }
        }
      }
    });
  }
  return false;
};

// This function is exported so that custom JS code can call it
// Do not remove without a deprecation notice
window.ssl_start = tryssl;

sendUrl = function(form, path) {
  var form_url;
  form_url = form.attr('action');
  if (form_url.match(/^#$/)) {
    form_url = path;
  } else {
    form_url = form_url + path;
  }
  console.log('form action URL -> ', form_url);
  form.attr('action', form_url);
  return form.submit();
};

$(document).ready(function() {
  if (!window._ssl_js_done) {
    window._ssl_js_done = true;
    return $('.sslclick').on('click', tryssl);
  }
});
