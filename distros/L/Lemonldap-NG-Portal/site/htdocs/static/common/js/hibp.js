(function () {
  'use strict';

  $(document).on('checkpassword', function (event, context) {
    var evType, newpasswordVal, setResult;
    context.password;
    evType = context.evType;
    setResult = context.setResult;
    // if checkHIBP is enabled
    if ($('#ppolicy-checkhibp-feedback').length > 0) {
      newpasswordVal = $("#newpassword").val();
      if (newpasswordVal.length >= 5) {
        // don't check HIBP at each keyup, but only when input focuses out
        if (evType === "focusout") {
          setResult('ppolicy-checkhibp-feedback', "waiting");
          return $.ajax({
            dataType: "json",
            url: "".concat(scriptname, "checkhibp"),
            method: "POST",
            data: {
              "password": btoa(newpasswordVal)
            },
            context: document.body,
            success: function success(data) {
              var code, msg;
              code = data.code;
              msg = data.message;
              if (code !== void 0) {
                if (parseInt(code) === 0) {
                  // password ok
                  return setResult('ppolicy-checkhibp-feedback', "good");
                } else if (parseInt(code) === 2) {
                  // password compromised
                  return setResult('ppolicy-checkhibp-feedback', "bad");
                } else {
                  // unexpected error
                  console.error('checkhibp: backend error: ', msg);
                  return setResult('ppolicy-checkhibp-feedback', "unknown");
                }
              }
            },
            error: function error(j, status, err) {
              var res;
              if (err) {
                console.error('checkhibp: frontend error: ', err);
              }
              if (j) {
                res = JSON.parse(j.responseText);
              }
              if (res && res.error) {
                console.error('checkhibp: returned error: ', res);
              }
            }
          });
        }
      } else {
        // Check not performed yet
        return setResult('ppolicy-checkhibp-feedback', "unknown");
      }
    }
  });

})();
