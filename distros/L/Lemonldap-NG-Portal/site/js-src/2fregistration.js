/*
LemonLDAP::NG 2F registration script
*/
var delete2F, displayError, update2F, setMsg;

setMsg = function(msg, level) {
  $('#msg').attr('trspan', msg);
  $('#msg').html(window.translate(msg));
  $('#color').removeClass('message-positive message-warning alert-success alert-warning alert-danger');
  $('#color').addClass(`message-${level}`);
  if (level === 'positive') {
    level = 'success';
  }
  $('#color').addClass(`alert-${level}`);
  return $('#color').attr("role", "status");
};

displayError = function(j, status, err) {
  var refresh, res;
  console.error('Error', err);
  res = JSON.parse(j.responseText);
  if (res && res.error) {
    res = res.error.replace(/.* /, '');
    console.error('Returned error', res);
    if (res.match(/module/)) {
      return setMsg('notAuthorized', 'warning');
    } else if (res === 'csrfToken') {
      setMsg(res, 'danger');
      refresh = function() {
        return window.location = window.location.href.split("?")[0];
      };
      return setTimeout(refresh, 2000);
    } else {
      return setMsg(res, 'warning');
    }
  }
};

// Delete function (launched by "delete" button)
delete2F = function(device, epoch, prefix) {
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
  return $.ajax({
    type: "POST",
    url: `${scriptname}2fregisters/${prefix}/delete`,
    data: {
      epoch: epoch
    },
    headers: {
      "X-CSRF-Check": "1"
    },
    dataType: 'json',
    error: displayError,
    success: function(resp) {
      var e, refresh;
      if (resp.error) {
        if (resp.error.match(/notAuthorized/)) {
          return setMsg('notAuthorized', 'warning');
        } else {
          return setMsg('unknownAction', 'warning');
        }
      } else if (resp.result) {
        $(`#delete-${epoch}`).hide();
        e = jQuery.Event("mfaDeleted");
        $(document).trigger(e, [{
          "type": device,
          "epoch": epoch
        }]);
        if (!e.isDefaultPrevented()) {
          setMsg('yourKeyIsUnregistered', 'positive');
        }
        refresh = function() {
          return window.location = window.location.href.split("?")[0];
        };
        return setTimeout(refresh, 2000);
      }
    },
    error: displayError
  });
};

// Update function (launched by "save" button)
update2F = function update2F(device, epoch, prefix, label, oldlabel) {
  if (label == oldlabel) {
    setMsg('yourKeyIsUnchanged', 'warning');
  } else {
    return $.ajax({
      type: "POST",
      url: `${scriptname}2fregisters/${prefix}/modify`,
      data: {
        epoch: epoch,
        label: label
      },
      headers: {
        "X-CSRF-Check": "1"
      },
      dataType: 'json',
      error: displayError,
      success: function success(data) {
        var e, refresh;
        if (data.error) {
          if (data.error.match(/bad(Code|Name)/)) {
            return setMsg(data.error, 'warning');
          } else {
            return setMsg(data.error, 'danger');
          }
        } else {
          $(`span.update2f[device=${device}][epoch=${epoch}]`).attr('oldlabel',label);
          e = jQuery.Event("mfaUpdated");
          $(document).trigger(e, [{
            "type": device,
            "epoch": epoch,
            "label": label
          }]);
          if (!e.isDefaultPrevented()) {
            setMsg('yourKeyIsUpdated', 'positive');
          }
        }
      }
    });
  }
};

// Register "click" events
$(document).ready(function() {
  $('body').on('click', '.remove2f', function() {
    return delete2F($(this).attr('device'), $(this).attr('epoch'), $(this).attr('prefix'));
  });
  $('body').on('click', '.update2f', function() {
    return update2F($(this).attr('device'), $(this).attr('epoch'), $(this).attr('prefix'), $(`#input-${$(this).attr('epoch')}`).val(), $(this).attr('oldlabel'));
  });
  $('#goback').attr('href', portal);
  return $(".data-epoch").each(function() {
    var myDate;
    myDate = new Date($(this).text() * 1000);
    return $(this).text(myDate.toLocaleString());
  });
});
