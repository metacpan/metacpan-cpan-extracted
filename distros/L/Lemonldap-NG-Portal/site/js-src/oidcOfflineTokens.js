var removeOfflineSession;
(function() {
  $(window).on("load", function() {
    var offlineSessions = window.datas["sessions"] ? window.datas["sessions"] : {};
    offlineSessions.forEach((session) => {
      const epoch = new Date(session.epoch * 1000).toLocaleString();

      const removeButton = `<a title="delete" class="removeOidcOfflineTokens" partner=${session.sessionid}>
        <span class="btn btn-danger" role="button">
          <span class="fa fa-minus-circle"></span>
          <span trspan="unregister">Unregister</span>
        </span>
      </a>`;

      $("tbody.oidcOfflineTokens").append(
        $(`<tr partner="${session.sessionid}"><td>${session.id}</td><td>${epoch}</td><td>${removeButton}</td></tr>`)
      );
    });
    $(".removeOidcOfflineTokens").on("click", function() {
      return removeOfflineSession($(this).attr("partner"));
    });
  });
  // Delete
  const delKey = function(key, success, error) {
    return $.ajax({
      type: "DELETE",
      url: `${scriptname}myoffline/${key}`,
      dataType: "json",
      success: success,
      error: error,
    });
  };
  const removeOfflineSession = function(partner) {
    var e;
    e = function(j, s, e) {
      return alert(`${s} ${e}`);
    };
    // Success
    return delKey(
      partner,
      function() {
        return $(`[partner='${partner}']`).hide();
        // Error
      },
      e
    );
  };


})();