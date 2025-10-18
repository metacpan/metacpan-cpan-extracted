/*
LemonLDAP::NG TOTP registration script
*/
var displayError, getKey, setMsg, token, verify;

setMsg = function(msg, level) {
  $('#msg').attr('trspan', msg);
  $('#msg').html(window.translate(msg));
  $('#color').removeClass('message-positive message-warning message-danger alert-success alert-warning alert-danger');
  $('#color').addClass(`message-${level}`);
  if (level === 'positive') {
    level = 'success';
  }
  $('#color').addClass(`alert-${level}`);
  return $('#msg').attr('role', (level === 'danger' ? 'alert' : 'status'));
};

displayError = function(j, status, err) {
  var res;
  console.error('Error', err);
  res = JSON.parse(j.responseText);
  if (res && res.error) {
    res = res.error.replace(/.* /, '');
    console.error('Returned error', res);
    return setMsg(res, 'warning');
  }
};

token = '';

getKey = function() {
  setMsg('yourTotpKey', 'warning');
  return $.ajax({
    type: "POST",
    url: `${scriptname}2fregisters/totp/getkey`,
    dataType: 'json',
    headers: {
      "X-CSRF-Check": "1"
    },
    error: displayError,
    // Display key and QR code
    success: function(data) {
      var s, secret;
      if (data.error) {
        return setMsg(data.error, 'warning');
      }
      if (!(data.portal && data.user && data.secret)) {
        return setMsg('PE24', 'danger');
      }
      // Generate OTP url
      $("#divToHide").show();
      s = `otpauth://totp/${escape(data.portal)}:${escape(data.user)}?secret=${data.secret}&issuer=${escape(data.portal)}`;
      if (data.digits !== 6) {
        s += `&digits=${data.digits}`;
      }
      if (data.interval !== 30) {
        s += `&period=${data.interval}`;
      }
      // Generate QR code
      new QRious({
        element: document.getElementById('qr'),
        value: s,
        size: 150
      });
      // Display serialized key
      secret = data.secret || "";
      // If an element on the page has class="otpauth-url", set the URL to it
      $('.otpauth-url').attr("href", s);
      // If an element on the page has id="secret", set a human-readable secret to it
      $('#secret').text(secret.toUpperCase().replace(/(.{4})/g, '$1 ').trim());
      // Show message (warning level if key is new)
      if (data.newkey) {
        setMsg('yourNewTotpKey', 'warning');
      } else {
        setMsg('yourTotpKey', 'success');
      }
      return token = data.token;
    }
  });
};

verify = function() {
  var val;
  val = $('#code').val();
  if (!val) {
    setMsg('totpMissingCode', 'warning');
    return $("#code").focus();
  } else {
    return $.ajax({
      type: "POST",
      url: `${scriptname}2fregisters/totp/verify`,
      dataType: 'json',
      data: {
        token: token,
        code: val,
        TOTPName: $('#TOTPName').val()
      },
      headers: {
        "X-CSRF-Check": "1"
      },
      error: displayError,
      success: function(data) {
        var e;
        if (data.error) {
          if (data.error.match(/bad(Code|Name)/)) {
            return setMsg(data.error, 'warning');
          } else {
            return setMsg(data.error, 'danger');
          }
        } else {
          e = jQuery.Event("mfaAdded");
          $(document).trigger(e, [{
            "type": "totp"
          }]);
          if (!e.isDefaultPrevented()) {
            return window.location.href = window.portal + "2fregisters?continue=1";
          }
        }
      }
    });
  }
};

$(document).ready(function() {
  getKey();
  return $('#verify').on('click', function() {
    return verify();
  });
});