(function () {
  'use strict';

  function _defineProperty(obj, key, value) {
    key = _toPropertyKey(key);
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }
    return obj;
  }
  function _toPrimitive(input, hint) {
    if (typeof input !== "object" || input === null) return input;
    var prim = input[Symbol.toPrimitive];
    if (prim !== undefined) {
      var res = prim.call(input, hint || "default");
      if (typeof res !== "object") return res;
      throw new TypeError("@@toPrimitive must return a primitive value.");
    }
    return (hint === "string" ? String : Number)(input);
  }
  function _toPropertyKey(arg) {
    var key = _toPrimitive(arg, "string");
    return typeof key === "symbol" ? key : String(key);
  }

  /*
  LemonLDAP::NG 2F registration script
  */
  var delete2F, displayError, setMsg;
  setMsg = function setMsg(msg, level) {
    $('#msg').attr('trspan', msg);
    $('#msg').html(window.translate(msg));
    $('#color').removeClass('message-positive message-warning alert-success alert-warning alert-danger');
    $('#color').addClass("message-".concat(level));
    if (level === 'positive') {
      level = 'success';
    }
    $('#color').addClass("alert-".concat(level));
    return $('#color').attr("role", "status");
  };
  displayError = function displayError(j, status, err) {
    var refresh, res;
    console.log('Error', err);
    res = JSON.parse(j.responseText);
    if (res && res.error) {
      res = res.error.replace(/.* /, '');
      console.log('Returned error', res);
      if (res.match(/module/)) {
        return setMsg('notAuthorized', 'warning');
      } else if (res === 'csrfToken') {
        setMsg(res, 'danger');
        refresh = function refresh() {
          return window.location = window.location.href.split("?")[0];
        };
        return setTimeout(refresh, 2000);
      } else {
        return setMsg(res, 'warning');
      }
    }
  };

  // Delete function (launched by "delete" button)
  delete2F = function delete2F(device, epoch, prefix) {
    if (!prefix) {
      if (device === 'UBK') {
        prefix = 'yubikey';
      } else if (device === 'TOTP') {
        prefix = 'totp';
      } else if (device === 'WebAuthn') {
        prefix = 'webauthn';
      } else {
        // Falling back is not likely to be very successful...
        prefix = device.toLowerCase();
      }
    }
    return $.ajax(_defineProperty({
      type: "POST",
      url: "".concat(scriptname, "2fregisters/").concat(prefix, "/delete"),
      data: {
        epoch: epoch
      },
      headers: {
        "X-CSRF-Check": "1"
      },
      dataType: 'json',
      error: displayError,
      success: function success(resp) {
        var e, refresh;
        if (resp.error) {
          if (resp.error.match(/notAuthorized/)) {
            return setMsg('notAuthorized', 'warning');
          } else {
            return setMsg('unknownAction', 'warning');
          }
        } else if (resp.result) {
          $("#delete-".concat(epoch)).hide();
          e = jQuery.Event("mfaDeleted");
          $(document).trigger(e, [{
            "type": device,
            "epoch": epoch
          }]);
          if (!e.isDefaultPrevented()) {
            setMsg('yourKeyIsUnregistered', 'positive');
          }
          refresh = function refresh() {
            return window.location = window.location.href.split("?")[0];
          };
          return setTimeout(refresh, 2000);
        }
      }
    }, "error", displayError));
  };

  // Register "click" events
  $(document).ready(function () {
    $('body').on('click', '.remove2f', function () {
      return delete2F($(this).attr('device'), $(this).attr('epoch'), $(this).attr('prefix'));
    });
    $('#goback').attr('href', portal);
    return $(".data-epoch").each(function () {
      var myDate;
      myDate = new Date($(this).text() * 1000);
      return $(this).text(myDate.toLocaleString());
    });
  });

})();
