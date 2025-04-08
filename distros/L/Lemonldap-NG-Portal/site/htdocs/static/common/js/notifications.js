(function () {
  'use strict';

  /*
  LemonLDAP::NG Notifications script
  */
  var displayError, msg, setMsg, toggle, toggle_explorer, toggle_eye, viewNotif;
  msg = $('#msg').attr('trspan');
  setMsg = function setMsg(msg, level) {
    $('#msg').html(window.translate(msg));
    $('#color').removeClass('message-positive message-warning alert-success alert-warning');
    $('#color').addClass("message-".concat(level));
    if (level === 'positive') {
      level = 'success';
    }
    $('#color').addClass("alert-".concat(level));
    return $('#color').attr("role", "status");
  };
  displayError = function displayError(j, status, err) {
    setMsg('notificationRetrieveFailed', 'warning');
    return console.log('Error:', err, 'Status:', status);
  };
  toggle_eye = function toggle_eye(slash) {
    if (slash) {
      $("#icon-explorer-button").removeClass('fa-eye');
      return $("#icon-explorer-button").addClass('fa-eye-slash');
    } else {
      $("#icon-explorer-button").removeClass('fa-eye-slash');
      return $("#icon-explorer-button").addClass('fa-eye');
    }
  };
  toggle_explorer = function toggle_explorer(visible) {
    if (visible) {
      $('#explorer').hide();
      $('#color').hide();
      return toggle_eye(0);
    } else {
      $('#explorer').show();
      $('#color').show();
      return toggle_eye(1);
    }
  };
  toggle = function toggle(button, notif, epoch) {
    setMsg(msg, 'positive');
    $(".btn-danger").each(function () {
      $(this).removeClass('btn-danger');
      return $(this).addClass('btn-success');
    });
    $(".fa-eye-slash").each(function () {
      $(this).removeClass('fa-eye-slash');
      return $(this).addClass('fa-eye');
    });
    $(".verify").each(function () {
      $(this).text(window.translate('verify'));
      return $(this).attr('trspan', 'verify');
    });
    if (notif && epoch) {
      button.removeClass('btn-success');
      button.addClass('btn-danger');
      $("#icon-".concat(notif, "-").concat(epoch)).removeClass('fa-eye');
      $("#icon-".concat(notif, "-").concat(epoch)).addClass('fa-eye-slash');
      $("#text-".concat(notif, "-").concat(epoch)).text(window.translate('hide'));
      $("#text-".concat(notif, "-").concat(epoch)).attr('trspan', 'hide');
      $("#myNotification").removeAttr('hidden');
      return toggle_eye(1);
    } else {
      $("#myNotification").attr('hidden', 'true');
      return $("#explorer-button").attr('hidden', 'true');
    }
  };

  // viewNotif function (launched by "verify" button)
  viewNotif = function viewNotif(notif, epoch, button) {
    console.log('Ref:', notif, 'epoch:', epoch);
    if (notif && epoch) {
      console.log('Send AJAX request');
      return $.ajax({
        type: "GET",
        url: "".concat(scriptname, "mynotifications/").concat(notif),
        data: {
          epoch: epoch
        },
        dataType: 'json',
        error: displayError,
        success: function success(resp) {
          var myDate;
          if (resp.result) {
            console.log('Notification:', resp.notification);
            toggle(button, notif, epoch);
            $('#displayNotif').html(resp.notification);
            $('#notifRef').text(notif);
            myDate = new Date(epoch * 1000);
            $('#notifEpoch').text(myDate.toLocaleString());
            return $("#explorer-button").removeAttr('hidden');
          } else {
            return setMsg('notificationNotFound', 'warning');
          }
        }
      });
    } else {
      return setMsg('notificationRetrieveFailed', 'warning');
    }
  };

  // Register "click" events
  $(document).ready(function () {
    $(".data-epoch").each(function () {
      var myDate;
      myDate = new Date($(this).text() * 1000);
      return $(this).text(myDate.toLocaleString());
    });
    $('#goback').attr('href', portal);
    $('body').on('click', '.btn-success', function () {
      return viewNotif($(this).attr('notif'), $(this).attr('epoch'), $(this));
    });
    $('body').on('click', '.btn-danger', function () {
      return toggle($(this));
    });
    return $('body').on('click', '.btn-info', function () {
      return toggle_explorer($('#explorer').is(':visible'));
    });
  });

})();
