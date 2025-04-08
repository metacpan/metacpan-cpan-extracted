(function () {
  'use strict';

  /*
  LemonLDAP::NG Generic registration script
  */
  var displayError, register, setMsg, verify;
  setMsg = function setMsg(msg, level) {
    $('#msg').attr('trspan', msg);
    $('#msg').html(window.translate(msg));
    $('#color').removeClass('message-positive message-warning message-danger alert-success alert-warning alert-danger');
    $('#color').addClass("message-".concat(level));
    if (level === 'positive') {
      level = 'success';
    }
    $('#color').addClass("alert-".concat(level));
    return $('#msg').attr('role', level === 'danger' ? 'alert' : 'status');
  };
  displayError = function displayError(j, status, err) {
    var res;
    console.log('Error', err);
    res = JSON.parse(j.responseText);
    if (res && res.error) {
      res = res.error.replace(/.* /, '');
      console.log('Returned error', res);
      return setMsg(res, 'warning');
    }
  };
  verify = function verify() {
    var generic, prefix;
    generic = $('#generic').val();
    prefix = window.datas.prefix;
    if (!generic) {
      setMsg('PE79', 'warning');
      return $('#generic').focus();
    } else {
      return $.ajax({
        type: 'POST',
        url: "".concat(scriptname, "2fregisters/").concat(prefix, "/sendcode"),
        dataType: 'json',
        data: {
          generic: generic
        },
        headers: {
          "X-CSRF-Check": "1"
        },
        error: displayError,
        success: function success(data) {
          if (data.error) {
            if (data.error.match(/PE79/)) {
              return setMsg(data.error, 'warning');
            } else {
              return setMsg(data.error, 'danger');
            }
          } else {
            $('#token').val(data.token);
            return setMsg('genericCheckCode', 'success');
          }
        }
      });
    }
  };
  register = function register() {
    var generic, genericcode, genericname, prefix, token;
    generic = $('#generic').val();
    genericname = $('#genericname').val();
    genericcode = $('#code').val();
    prefix = window.datas.prefix;
    token = $('#token').val();
    if (!generic) {
      setMsg('PE79', 'warning');
      return $('#generic').focus();
    } else {
      return $.ajax({
        type: 'POST',
        url: "".concat(scriptname, "2fregisters/").concat(prefix, "/verify"),
        dataType: 'json',
        data: {
          generic: generic,
          genericname: genericname,
          genericcode: genericcode,
          token: token
        },
        headers: {
          "X-CSRF-Check": "1"
        },
        error: displayError,
        success: function success(data) {
          var e;
          if (data.error) {
            if (data.error.match(/mailNotSent/)) {
              return setMsg(data.error, 'warning');
            } else {
              return setMsg(data.error, 'danger');
            }
          } else {
            e = jQuery.Event("mfaAdded");
            $(document).trigger(e, [{
              "type": prefix
            }]);
            if (!e.isDefaultPrevented()) {
              return window.location.href = window.portal + "2fregisters?continue=1";
            }
          }
        }
      });
    }
  };

  // Register "click" events
  $(document).ready(function () {
    $('#verify').on('click', verify);
    return $('#register').on('click', register);
  });

})();
