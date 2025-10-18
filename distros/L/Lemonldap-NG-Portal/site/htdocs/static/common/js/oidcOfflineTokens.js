(function () {
  'use strict';

  (function () {
    $(window).on("load", function () {
      var offlineSessions = window.datas["sessions"] ? window.datas["sessions"] : {};
      offlineSessions.forEach(function (session) {
        var epoch = new Date(session.epoch * 1000).toLocaleString();
        var removeButton = "<a title=\"delete\" class=\"removeOidcOfflineTokens\" partner=".concat(session.sessionid, ">\n        <span class=\"btn btn-danger\" role=\"button\">\n          <span class=\"fa fa-minus-circle\"></span>\n          <span trspan=\"unregister\">Unregister</span>\n        </span>\n      </a>");
        $("tbody.oidcOfflineTokens").append($("<tr partner=\"".concat(session.sessionid, "\"><td>").concat(session.id, "</td><td>").concat(epoch, "</td><td>").concat(removeButton, "</td></tr>")));
      });
      $(".removeOidcOfflineTokens").on("click", function () {
        return removeOfflineSession($(this).attr("partner"));
      });
    });
    // Delete
    var delKey = function delKey(key, success, error) {
      return $.ajax({
        type: "DELETE",
        url: "".concat(scriptname, "myoffline/").concat(key),
        dataType: "json",
        success: success,
        error: error
      });
    };
    var removeOfflineSession = function removeOfflineSession(partner) {
      var e;
      e = function e(j, s, _e) {
        return alert("".concat(s, " ").concat(_e));
      };
      // Success
      return delKey(partner, function () {
        return $("[partner='".concat(partner, "']")).hide();
        // Error
      }, e);
    };
  })();

})();
