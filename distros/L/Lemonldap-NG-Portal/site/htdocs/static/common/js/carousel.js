(function () {
  'use strict';

  function _toConsumableArray(arr) {
    return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
  }
  function _arrayWithoutHoles(arr) {
    if (Array.isArray(arr)) return _arrayLikeToArray(arr);
  }
  function _iterableToArray(iter) {
    if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
  }
  function _unsupportedIterableToArray(o, minLen) {
    if (!o) return;
    if (typeof o === "string") return _arrayLikeToArray(o, minLen);
    var n = Object.prototype.toString.call(o).slice(8, -1);
    if (n === "Object" && o.constructor) n = o.constructor.name;
    if (n === "Map" || n === "Set") return Array.from(o);
    if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
  }
  function _arrayLikeToArray(arr, len) {
    if (len == null || len > arr.length) len = arr.length;
    for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i];
    return arr2;
  }
  function _nonIterableSpread() {
    throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
  }

  $(window).on("load", function () {
    // Adapt some class to fit Bootstrap theme
    $("div.carousel").addClass("slide");
    var today = new Date().toISOString().split("T")[0];
    var publicNotifications = window.datas["publicNotifications"] ? window.datas["publicNotifications"] : {};
    var public_errors = publicNotifications["public_errors"].filter(function (notif) {
      return notif.date <= today;
    }).sort(function (a, b) {
      return a.date < b.date;
    });
    var public_warns = publicNotifications["public_warns"].filter(function (notif) {
      return notif.date <= today;
    }).sort(function (a, b) {
      return a.date < b.date;
    });
    var public_infos = publicNotifications["public_infos"].filter(function (notif) {
      return notif.date <= today;
    }).sort(function (a, b) {
      return a.date < b.date;
    });
    var ordonned_notifications = [].concat(_toConsumableArray(public_errors), _toConsumableArray(public_warns), _toConsumableArray(public_infos));
    var carouselInner = $("<div class='carousel-inner rounded'></div>");
    var carouselIndicators = $("<ol class=\"carousel-indicators\"></ol>");
    ordonned_notifications.forEach(function (element, index) {
      var bslevel = "";
      var level = element.uid.split("-").pop();
      switch (level) {
        case "info":
          bslevel = "info";
          break;
        case "warn":
          bslevel = "warning";
          break;
        case "error":
          bslevel = "danger";
          break;
        default:
          bslevel = "primary";
      }
      var notificationElement = $("<div class='carousel-item notif-container alert alert-".concat(bslevel, "'></div>"));
      var notificationIndicator = $("<li data-target=\"#carousel\" data-slide-to=\"".concat(index, "\"></li>"));
      if (index === 0) {
        notificationElement.addClass("active");
        notificationIndicator.addClass("active");
      }
      var notificationTitle = $("<h4 class='text-center'></h4>");
      notificationTitle.append(element === null || element === void 0 ? void 0 : element.title);
      notificationElement.append(notificationTitle);
      var notificationSubtitle = $("<i class='d-flex justify-content-center align-items-center'></i>");
      notificationSubtitle.append(element === null || element === void 0 ? void 0 : element.subtitle);
      notificationElement.append(notificationSubtitle);
      var notificationContent = $("<p class='d-flex justify-content-center align-items-center'></p>");
      notificationContent.text(element === null || element === void 0 ? void 0 : element.text);
      notificationElement.append(notificationContent);
      carouselInner.append(notificationElement);
      carouselIndicators.append(notificationIndicator);
    });
    // Append the carousel inner to the carousel container
    var previousButton = $("<a class=\"carousel-control-prev\" href=\"#carousel\" role=\"button\" data-slide=\"prev\">\n        <span class=\"carousel-control-prev-icon\" aria-hidden=\"true\"></span>\n        <span class=\"sr-only\">Previous</span>\n      </a>");
    var nextButton = $("<a class=\"carousel-control-next\" href=\"#carousel\" role=\"button\" data-slide=\"next\">\n    <span class=\"carousel-control-next-icon\" aria-hidden=\"true\"></span>\n    <span class=\"sr-only\">Next</span>\n  </a>");
    $("div.carousel").append(carouselIndicators, carouselInner, previousButton, nextButton);
  });

})();
