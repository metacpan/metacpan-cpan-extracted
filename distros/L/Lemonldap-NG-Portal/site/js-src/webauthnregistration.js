/*
LemonLDAP::NG WebAuthn registration script
*/
var displayError, register, setMsg, verify;

setMsg = function(msg, level) {
  $('#msg').attr('trspan', msg);
  $('#msg').html(window.translate(msg));
  $('#color').removeClass('message-positive message-warning message-danger alert-success alert-warning alert-danger');
  $('#color').addClass(`message-${level}`);
  if (level === 'positive') {
    level = 'success';
  }
  return $('#color').addClass(`alert-${level}`);
};

displayError = function(j, status, err) {
  var res;
  console.error('Error', err);
  res = JSON.parse(j.responseText);
  if (res && res.error) {
    res = res.error.replace(/.* /, '');
    console.error('Returned error', res);
    return setMsg(res, 'danger');
  }
};

// Registration function (launched by "register" button)
register = function() {
  if (!webauthnJSON.supported()) {
    setMsg('webAuthnUnsupported', 'warning');
    return;
  }
  // 1 get registration token
  return $.ajax({
    type: "POST",
    url: `${scriptname}2fregisters/webauthn/registrationchallenge`,
    data: {},
    dataType: 'json',
    headers: {
      "X-CSRF-Check": "1"
    },
    error: displayError,
    success: function(ch) {
      var e, request;
      // 2 build response
      request = {
        publicKey: ch.request
      };
      e = jQuery.Event("webauthnRegistrationAttempt");
      $(document).trigger(e);
      if (!e.isDefaultPrevented()) {
        setMsg('webAuthnRegisterInProgress', 'warning');
        $('#u2fPermission').show();
        return webauthnJSON.create(request).then(function(response) {
          e = jQuery.Event("webauthnRegistrationSuccess");
          $(document).trigger(e, [response]);
          if (!e.isDefaultPrevented()) {
            return $.ajax({
              type: "POST",
              url: `${scriptname}2fregisters/webauthn/registration`,
              data: {
                state_id: ch.state_id,
                credential: JSON.stringify(response),
                keyName: $('#keyName').val()
              },
              headers: {
                "X-CSRF-Check": "1"
              },
              dataType: 'json',
              success: function(resp) {
                if (resp.error) {
                  if (resp.error.match(/badName/)) {
                    return setMsg(resp.error, 'danger');
                  } else {
                    return setMsg('webAuthnRegisterFailed', 'danger');
                  }
                } else if (resp.result) {
                  e = jQuery.Event("mfaAdded");
                  $(document).trigger(e, [{
                    "type": "webauthn"
                  }]);
                  if (!e.isDefaultPrevented()) {
                    return window.location.href = window.portal + "2fregisters?continue=1";
                  }
                }
              },
              error: displayError
            });
          }
        }, function(error) {
          e = jQuery.Event("webauthnRegistrationFailure");
          $(document).trigger(e, [error]);
          if (!e.isDefaultPrevented()) {
            return setMsg('webAuthnBrowserFailed', 'danger');
          }
        });
      }
    }
  });
};

// Verification function (launched by "verify" button)
verify = function() {
  if (!webauthnJSON.supported()) {
    setMsg('webAuthnUnsupported', 'warning');
    return;
  }
  // 1 get challenge
  return $.ajax({
    type: "POST",
    url: `${scriptname}2fregisters/webauthn/verificationchallenge`,
    data: {},
    headers: {
      "X-CSRF-Check": "1"
    },
    dataType: 'json',
    error: displayError,
    success: function(ch) {
      var request;
      // 2 build response
      request = {
        publicKey: ch.request
      };
      setMsg('webAuthnBrowserInProgress', 'warning');
      return webauthnJSON.get(request).then(function(response) {
        return $.ajax({
          type: "POST",
          url: `${scriptname}2fregisters/webauthn/verification`,
          data: {
            state_id: ch.state_id,
            credential: JSON.stringify(response)
          },
          headers: {
            "X-CSRF-Check": "1"
          },
          dataType: 'json',
          success: function(resp) {
            if (resp.error) {
              return setMsg('webAuthnFailed', 'danger');
            } else if (resp.result) {
              return setMsg('yourKeyIsVerified', 'positive');
            }
          },
          error: displayError
        });
      }).catch(function(error) {
        return setMsg('webAuthnBrowserFailed', 'danger');
      });
    }
  });
};

// Register "click" events
$(document).ready(function() {
  $('#u2fPermission').hide();
  $('#register').on('click', register);
  $('#verify').on('click', verify);
  setTimeout(register, 1000);
  $('#retrybutton').on('click', register);
  return $('#goback').attr('href', portal);
});