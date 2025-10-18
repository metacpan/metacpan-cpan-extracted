// TOTP part inspired from https://github.com/bellstrand/totp-generator
// Copyright: 2016 Magnus Bellstrand, license MIT
var base32tohex, dec2hex, getToken, go, hex2dec, leftpad, tryFingerprint;

$(document).ready(function() {
  if (window.requestIdleCallback) {
    return requestIdleCallback(function() {
      return go();
    });
  } else {
    return setTimeout(go, 500);
  }
});

go = function() {
  var e, script, secret, usetotp;
  usetotp = Boolean(parseInt($('#usetotp').attr("value")));
  if (window.localStorage && usetotp) {
    secret = $('#totpsecret').attr("value");
    if (secret) {
      try {
        localStorage.setItem("stayconnectedkey", secret);
      } catch (error) {
        e = error;
        console.error("Unable to register key in storage", e);
      }
    } else {
      secret = localStorage.getItem("stayconnectedkey");
    }
    if (secret) {
      try {
        $('#fg').attr("value", `TOTP_${getToken(secret)}`);
        $('#form').submit();
        return;
      } catch (error) {
        e = error;
        console.error("Unable to register key in storage", e);
      }
    }
  }
  // Load fingerprint2
  script = document.createElement('script');
  script.src = window.staticPrefix + "bwr/fingerprintjs2/fingerprint2.js";
  script.async = false;
  document.body.append(script);
  script.onload = tryFingerprint;
  // If script not loaded after 1s, skip its load
  return setTimeout(tryFingerprint, 1000);
};

tryFingerprint = function() {
  console.debug("Trying fingerprint");
  if (window.Fingerprint2) {
    return Fingerprint2.get(function(components) {
      var result, values;
      values = components.map((component) => {
        return component.value;
      });
      result = Fingerprint2.x64hash128(values.join(''), 31);
      $('#fg').attr("value", result);
      return $('#form').submit();
    });
  } else {
    console.error('No way to register this device');
    return $('#form').submit();
  }
};

getToken = function(key) {
  var hmac, offset, otp, shaObj, time;
  key = base32tohex(key);
  time = leftpad(dec2hex(Math.floor(Date.now() / 30000)), 16, "0");
  shaObj = new jsSHA("SHA-1", "HEX");
  shaObj.setHMACKey(key, "HEX");
  shaObj.update(time);
  hmac = shaObj.getHMAC("HEX");
  offset = hex2dec(hmac.substring(hmac.length - 1));
  otp = (hex2dec(hmac.substr(offset * 2, 8)) & hex2dec("7fffffff")) + "";
  return otp.substr(Math.max(otp.length - 6, 0), 6);
};

hex2dec = function(s) {
  return parseInt(s, 16);
};

dec2hex = function(s) {
  return (s < 15.5 ? "0" : "") + Math.round(s).toString(16);
};

base32tohex = function(base32) {
  var base32chars, bits, chunk, hex, i, j, k, ref, ref1, val;
  base32chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  bits = "";
  hex = "";
  base32 = base32.replace(/=+$/, "");
  for (i = j = 0, ref = base32.length - 1;
    (0 <= ref ? j <= ref : j >= ref); i = 0 <= ref ? ++j : --j) {
    val = base32chars.indexOf(base32.charAt(i).toUpperCase());
    if (val === -1) {
      throw new Error("Invalid base32 character in key");
    }
    bits += leftpad(val.toString(2), 5, "0");
  }
  for (i = k = 0, ref1 = bits.length - 8; k <= ref1; i = k += 8) {
    chunk = bits.substr(i, 8);
    hex = hex + leftpad(parseInt(chunk, 2).toString(16), 2, "0");
  }
  return hex;
};

leftpad = function(str, len, pad) {
  if (len + 1 >= str.length) {
    str = Array(len + 1 - str.length).join(pad) + str;
  }
  return str;
};
