(function () {
  'use strict';

  var barWidth, bootstrapClasses, displayEntropyBar, displayEntropyBarMsg;
  bootstrapClasses = new Map([["Err", "bg-danger"], ["0", "bg-danger"], ["1", "bg-warning"], ["2", "bg-info"], ["3", "bg-primary"], ["4", "bg-success"]]);
  barWidth = new Map([["Err", "0"], ["0", "20"], ["1", "40"], ["2", "60"], ["3", "80"], ["4", "100"]]);

  // display entropy bar with correct level
  displayEntropyBar = function displayEntropyBar(level) {
    // Remove all classes from progressbar and restore default progress-bar class
    $("#entropybar div").removeClass();
    $("#entropybar div").addClass('progress-bar');
    // set width
    $("#entropybar div").width(barWidth.get(level) + '%');
    // set color
    $("#entropybar div").addClass(bootstrapClasses.get(level));
    // display percentage width inside the bar
    return $("#entropybar div").html(barWidth.get(level) + '%');
  };

  // display custom message if any, else remove hide div block
  displayEntropyBarMsg = function displayEntropyBarMsg(msg) {
    $("#entropybar-msg").html(msg);
    if (msg.length === 0) {
      return $("#entropybar-msg").addClass("entropyHidden");
    } else {
      return $("#entropybar-msg").removeClass("entropyHidden");
    }
  };
  $(document).on('checkpassword', function (event, context) {
    var entropyrequired, entropyrequiredlevel, newpasswordVal, setResult;
    context.password;
    context.evType;
    setResult = context.setResult;
    // if checkEntropy is enabled
    if ($('#ppolicy-checkentropy-feedback').length > 0) {
      newpasswordVal = $("#newpassword").val();
      entropyrequired = $("span[trspan='checkentropyLabel']").attr("data-checkentropy_required");
      entropyrequiredlevel = $("span[trspan='checkentropyLabel']").attr("data-checkentropy_required_level");
      if (newpasswordVal.length === 0) {
        // restore default empty bar
        displayEntropyBar("Err");
        displayEntropyBarMsg("");
        setResult('ppolicy-checkentropy-feedback', "unknown");
      }
      if (newpasswordVal.length > 0) {
        // send a request to checkentropy endpoint
        return $.ajax({
          dataType: "json",
          url: "".concat(scriptname, "checkentropy"),
          method: "POST",
          data: {
            "password": btoa(newpasswordVal)
          },
          context: document.body,
          success: function success(data) {
            var level, msg;
            level = data.level;
            msg = data.message;
            if (level !== void 0) {
              if (parseInt(level) >= 0 && parseInt(level) <= 4) {
                // display entropy bar with correct level
                displayEntropyBar(level);
                displayEntropyBarMsg(msg);
                // set a warning if level < required level and prevent form validation
                if (entropyrequired === "1" && entropyrequiredlevel.length > 0) {
                  if (parseInt(level) >= parseInt(entropyrequiredlevel)) {
                    setResult('ppolicy-checkentropy-feedback', "good");
                  } else {
                    setResult('ppolicy-checkentropy-feedback', "bad");
                  }
                }
                // entropy criteria is set to ok if entropy check is not required
                if (entropyrequired !== "1") {
                  return setResult('ppolicy-checkentropy-feedback', "good");
                }
              } else if (parseInt(level) === -1) {
                // error when computing entropy: display entropy bar with error level
                displayEntropyBar(level);
                displayEntropyBarMsg(msg);
                return setResult('ppolicy-checkentropy-feedback', "bad");
              } else {
                // unexpected error: display entropy bar with error level
                displayEntropyBar(level);
                displayEntropyBarMsg(msg);
                return setResult('ppolicy-checkentropy-feedback', "unknown");
              }
            }
          },
          error: function error(j, status, err) {
            var res;
            if (err) {
              console.log('checkentropy: frontend error: ', err);
            }
            if (j) {
              res = JSON.parse(j.responseText);
            }
            if (res && res.error) {
              return console.log('checkentropy: returned error: ', res);
            }
          }
        });
      }
    }
  });

})();
