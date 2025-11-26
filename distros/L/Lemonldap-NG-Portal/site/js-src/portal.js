/*
  LemonLDAP::NG Portal jQuery scripts
  */
var datas, delKey, displayIcon, getQueryParam, getValues, ping, ppolicyResults, removeOidcConsent, restoreOrder, setCookie, setKey, setOrder, setResult, setSelector, translate, translatePage, translationFields, updateBorder,
  indexOf = [].indexOf;

// Translation mechanism
translationFields = {};

// Launched at startup: download language JSON and translate all HTML tags that
// contains one of the following attributes using translate() function:
//  - trspan       : set result in tag content
//  - trmsg        : get error number and set result of PE<number> result in tag
//                   content
//  - trplaceholder: set result in "placeholder" attribute
//  - localtime    : transform time (in ms)ing translate()
ppolicyResults = {};

setResult = function(field, result) {
  var ref, ref1;
  ppolicyResults[field] = result;
  displayIcon(field, result);
  // Compute form validity from all previous results
  if (Object.values(ppolicyResults).every((value) => {
      return value === "good" || value === "info";
    })) {
    if ((ref = $('#newpassword').get(0)) != null) {
      ref.setCustomValidity('');
    }
  } else {
    if ((ref1 = $('#newpassword').get(0)) != null) {
      ref1.setCustomValidity(translate('PE28'));
    }
  }
  return updateBorder();
};

displayIcon = function(field, result) {
  // Clear icon
  $("#" + field).removeClass('fa-times fa-check fa-spinner fa-pulse fa-info-circle fa-question-circle text-danger text-success text-info text-secondary');
  $("#" + field).attr('role', 'status');
  // Display correct icon
  switch (result) {
    case "good":
      return $("#" + field).addClass('fa-check text-success');
    case "bad":
      $("#" + field).addClass('fa-times text-danger');
      return $("#" + field).attr('role', 'alert');
    case "unknown":
      return $("#" + field).addClass('fa-question-circle text-secondary');
    case "waiting":
      return $("#" + field).addClass('fa-spinner fa-pulse text-secondary');
    case "info":
      return $("#" + field).addClass('fa-info-circle text-info');
  }
};

updateBorder = function() {
  var ref, ref1;
  if (((ref = $('#newpassword').get(0)) != null ? ref.checkValidity() : void 0) && ((ref1 = $('#confirmpassword').get(0)) != null ? ref1.checkValidity() : void 0)) {
    return $('.ppolicy').removeClass('border-danger').addClass('border-success');
  } else {
    return $('.ppolicy').removeClass('border-success').addClass('border-danger');
  }
};

translatePage = function(lang) {

  if (lang) {
    window.currentLanguage = lang
  } else {
    lang = window.currentLanguage
  }

  return $.getJSON(`${window.staticPrefix}languages/${lang}.json`, function(data) {
    var k, ref, ref1, v;
    translationFields = data;
    ref = window.datas.trOver.all;
    for (k in ref) {
      v = ref[k];
      translationFields[k] = v;
    }
    if (window.datas.trOver[lang]) {
      ref1 = window.datas.trOver[lang];
      for (k in ref1) {
        v = ref1[k];
        translationFields[k] = v;
      }
    }
    $("[trspan]").each(function() {
      var args, i, len, txt;
      args = $(this).attr('trspan').split(',');
      txt = translate(args.shift());
      for (i = 0, len = args.length; i < len; i++) {
        v = args[i];
        txt = txt.replace(/%[sd]/, v);
      }
      return $(this).html(txt);
    });
    $("[trmsg]").each(function() {
      var msg;
      $(this).html(translate(`PE${$(this).attr('trmsg')}`));
      msg = translate(`PE${$(this).attr('trmsg')}`);
      if (msg.match(/_hide_/)) {
        return $(this).parent().hide();
      }
    });
    $("[trattribute]").each(function() {
      var attribute, i, len, trattribute, trattributes, value;
      trattributes = $(this).attr('trattribute').trim().split(/\s+/);
      for (i = 0, len = trattributes.length; i < len; i++) {
        trattribute = trattributes[i];
        [attribute, value] = trattribute.split(':');
        if (attribute && value) {
          $(this).attr(attribute, translate(value));
        }
      }
      return true;
    });
    $("[trplaceholder]").each(function() {
      var tmp;
      tmp = translate($(this).attr('trplaceholder'));
      $(this).attr('placeholder', tmp);
      return $(this).attr('aria-label', tmp);
    });
    return $("[localtime]").each(function() {
      var d;
      d = new Date($(this).attr('localtime') * 1000);
      return $(this).text(d.toLocaleString());
    });
  });
};

// Translate a string
translate = function(str) {
  if (translationFields[str]) {
    return translationFields[str];
  } else {
    return str;
  }
};


// These functions are exported so that custom JS code can call them
// Do not remove without a deprecation notice
window.translate = translate;
window.translatePage = translatePage;

// Initialization variables: read all <script type="application/init"> tags and
// return JSON parsing result. This is set in window.data variable
getValues = function() {
  var values;
  values = {};
  $("script[type='application/init']").each(function() {
    var e, k, results, tmp;
    try {
      tmp = JSON.parse($(this).text());
      results = [];
      for (k in tmp) {
        results.push(values[k] = tmp[k]);
      }
      return results;
    } catch (error1) {
      e = error1;
      console.error('Parsing error', e);
      console.debug('JSON', $(this).text());
    }
  });
  return values;
};

// Gets a query string parametrer
// We cannot use URLSearchParam because of IE (#2230)
getQueryParam = function(name) {
  var match;
  match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
  if (match) {
    return decodeURIComponent(match[1].replace(/\+/g, ' '));
  } else {
    return null;
  }
};

// Code from http://snipplr.com/view/29434/
// ----------------------------------------
setSelector = "#appslist";

// Function to write the sorted apps list to session (network errors ignored)
setOrder = function() {
  return setKey('_appsListOrder', $(setSelector).sortable("toArray").join());
};

// Function used to remove an OIDC consent
removeOidcConsent = function(partner) {
  var e;
  e = function(j, s, e) {
    return alert(`${s} ${e}`);
  };
  // Success
  return delKey("_oidcConsents", partner, function() {
    return $(`[partner='${partner}']`).hide();
    // Error
  }, e);
};

// Function used by setOrder() and removeOidcConsent() to push new values
// For security reason, modification is rejected unless a valid token is given
setKey = function(key, val, success, error) {
  // First request to get token
  return $.ajax({
    type: "GET",
    url: `${scriptname}mysession/?gettoken`,
    dataType: 'json',
    error: error,
    // On success, value is set
    success: function(data) {
      var d;
      d = {
        token: data.token
      };
      d[key] = val;
      return $.ajax({
        type: "PUT",
        url: `${scriptname}mysession/persistent`,
        dataType: 'json',
        data: d,
        success: success,
        error: error
      });
    }
  });
};

delKey = function(key, sub, success, error) {
  return $.ajax({
    type: "GET",
    url: `${scriptname}mysession/?gettoken`,
    dataType: 'json',
    error: error,
    // On success, value is set
    success: function(data) {
      return $.ajax({
        type: "DELETE",
        url: `${scriptname}mysession/persistent/${key}?sub=${sub}&token=${data.token}`,
        dataType: 'json',
        success: success,
        error: error
      });
    }
  });
};

// function that restores the list order from session
restoreOrder = function() {
  var IDs, child, i, item, itemID, items, l, len, len1, list, rebuild, savedOrd, v;
  list = $(setSelector);
  if (!((list != null) && datas['appslistorder'])) {
    return null;
  }
  // make array from saved order
  IDs = datas['appslistorder'].split(',');
  // fetch current order
  items = list.sortable("toArray");
  // make array from current order
  rebuild = [];
  for (i = 0, len = items.length; i < len; i++) {
    v = items[i];
    rebuild[v] = v;
  }
  for (l = 0, len1 = IDs.length; l < len1; l++) {
    itemID = IDs[l];
    if (rebuild[itemID]) {
      // select item id from current order
      item = rebuild[itemID];
      // select the item according to current order
      child = $(setSelector + ".ui-sortable").children("#" + item);
      // select the item according to the saved order
      savedOrd = $(setSelector + ".ui-sortable").children("#" + itemID);
      // remove all the items
      child.remove();
      // add the items in turn according to saved order
      // we need to filter here since the "ui-sortable"
      // class is applied to all ul elements and we
      // only want the very first! You can modify this
      // to support multiple lists - not tested!
      $(setSelector + ".ui-sortable").filter(":first").append(savedOrd);
    }
  }
  return 1;
};

// function void ping()
// Check if session is alive on server side
// @return nothing
ping = function() {
  return $.ajax({
    type: "POST",
    url: scriptname,
    data: {
      ping: 1
    },
    dataType: 'json',
    success: function(data) {
      if ((data.result != null) && data.result === 1) {
        return setTimeout(ping, datas['pingInterval']);
      } else {
        return location.reload(true);
      }
    },
    error: function(j, t, e) {
      return location.reload(true);
    }
  });
};

window.ping = ping;

setCookie = function(name, value, exdays) {
  var cookiestring, d, samesite, secure;
  samesite = datas['sameSite'];
  secure = datas['cookieSecure'];
  cookiestring = `${name}=${value}; path=/; SameSite=${samesite}`;
  if (exdays) {
    d = new Date();
    d.setTime(d.getTime() + exdays * 86400000);
    cookiestring += `; expires=${d.toUTCString()}`;
  }
  if (secure) {
    cookiestring += "; Secure";
  }
  return document.cookie = cookiestring;
};

// Initialization
datas = {};

$(window).on('load', function() {
  var action, al, authMenuIndex, authMenuTabs, back_url, checkpassword, checksamepass, field, hiddenParams, i, lang, langdiv, len, link, menuIndex, menuTabs, method, queryLang, ref, setCookieLang, togglecheckpassword, displaytab;
  // Get application/init variables
  datas = getValues();
  // Keep the currently selected tab
  if ("datas" in window && "choicetab" in window.datas) {
    datas.choicetab = window.datas.choicetab;
  }
  // Export datas for other scripts
  window.datas = datas;
  $("#appslist").sortable({
    axis: "y",
    cursor: "move",
    opacity: 0.5,
    revert: true,
    items: "> div.category",
    update: function() {
      return setOrder();
    }
  });
  restoreOrder();
  $("div.message").fadeIn('slow');
  // Set timezone
  $("input[name=timezone]").val(-(new Date().getTimezoneOffset() / 60));
  // Menu tabs
  menuTabs = $("#menu").tabs({
    active: 0
  });
  displaytab = getQueryParam('tab');
  menuIndex = $('#menu a[href="#' + displaytab + '"]').parent().index();
  if (menuIndex < 0) {
    menuIndex = 0;
  }
  menuTabs.tabs("option", "active", menuIndex);
  // Authentication choice tabs
  authMenuTabs = $("#authMenu").tabs({
    active: 0
  });
  authMenuIndex = $('#authMenu a[href="#' + displaytab + '"]').parent().index();
  if (authMenuIndex < 0) {
    authMenuIndex = 0;
  }
  authMenuTabs.tabs("option", "active", authMenuIndex);
  // TODO: cookie
  // $("#authMenu").tabs
  // 	cookie:
  // 		name: 'lemonldapauthchoice'
  if (datas['choicetab']) {
    authMenuTabs.tabs("option", "active", $('#authMenu a[href="#' + datas['choicetab'] + '"]').parent().index());
  }
  // If there are no auto-focused fields, focus on first visible input
  if ($("input[autofocus]").length === 0) {
    $("input[type=text], input[type=password]").first().focus();
  }
  // Open links in new windows if required
  if (datas['newwindow']) {
    $('#appslist a').attr("target", "_blank");
  }
  // Complete removeOther link
  if ($("p.removeOther").length) {
    action = $("#form").attr("action");
    method = $("#form").attr("method");
    console.debug('method=', method);
    hiddenParams = "";
    if ($("#form input[type=hidden]")) {
      console.debug('Parse hidden values');
      $("#form input[type=hidden]").each(function(index) {
        console.debug(' ->', $(this).attr("name"), $(this).val());
        return hiddenParams += "&" + $(this).attr("name") + "=" + $(this).val();
      });
    }
    back_url = "";
    if (action) {
      console.debug('action=', action);
      if (action.indexOf("?") !== -1) {
        action.substring(0, action.indexOf("?")) + "?";
      } else {
        back_url = action + "?";
      }
      back_url += hiddenParams;
      hiddenParams = "";
    }
    link = $("p.removeOther a").attr("href") + "&method=" + method + hiddenParams;
    if (back_url) {
      link += "&url=" + btoa(back_url);
    }
    $("p.removeOther a").attr("href", link);
  }
  // Language detection. Priority order:
  //  0 - llnglanguage parameter
  //  1 - datas['language'] value (server-set from Cookie+Accept-Language)
  if (window.location.search) {
    queryLang = getQueryParam('llnglanguage');
    if (queryLang) {
      console.debug('Get lang from parameter');
    }
    setCookieLang = getQueryParam('setCookieLang');
    if (setCookieLang === 1) {
      console.debug('Set lang cookie');
    }
  }
  if (!lang) {
    lang = window.datas['language'];
    if (lang && !queryLang) {
      console.debug('Get lang from server');
    }
  } else if (indexOf.call(window.availableLanguages, lang) < 0) {
    lang = window.datas['language'];
    if (!queryLang) {
      console.debug('Lang not available -> Get lang from server');
    }
  }
  if (queryLang) {
    if (indexOf.call(window.availableLanguages, queryLang) < 0) {
      console.debug('Lang not available -> Get lang from server');
      queryLang = window.language;
    }
    console.debug('Selected lang ->', queryLang);
    if (setCookieLang) {
      console.debug('Set cookie lang ->', queryLang);
      setCookie('llnglanguage', queryLang, 3650);
    }
    translatePage(queryLang);
  } else {
    console.debug('Selected lang ->', lang);
    translatePage(lang);
  }
  // Build language icons
  langdiv = '';
  ref = window.availableLanguages;
  for (i = 0, len = ref.length; i < len; i++) {
    al = ref[i];
    langdiv += `<img class=\"langicon\" src=\"${window.staticPrefix}common/${al}.png\" title=\"${al}\" alt=\"[${al}]\"> `;
  }
  $('#languages').html(langdiv);
  $('.langicon').on('click', function() {
    lang = $(this).attr('title');
    setCookie('llnglanguage', lang, 3650);
    return translatePage(lang);
  });
  // Password policy
  checkpassword = function(password, evType) {
    var e, info;
    e = jQuery.Event("checkpassword");
    info = {
      password: password,
      evType: evType,
      setResult: setResult
    };
    return $(document).trigger(e, info);
  };
  checksamepass = function() {
    var ref1, ref2, ref3, ref4, ref5;
    if (((ref1 = $('#confirmpassword').get(0)) != null ? ref1.value : void 0) && ((ref2 = $('#confirmpassword').get(0)) != null ? ref2.value : void 0) === ((ref3 = $('#newpassword').get(0)) != null ? ref3.value : void 0)) {
      if ((ref4 = $('#confirmpassword').get(0)) != null) {
        ref4.setCustomValidity('');
      }
      displayIcon("samepassword-feedback", "good");
      updateBorder();
      return true;
    } else {
      if ((ref5 = $('#confirmpassword').get(0)) != null) {
        ref5.setCustomValidity(translate('PE34'));
      }
      displayIcon("samepassword-feedback", "bad");
      updateBorder();
      return false;
    }
  };
  if ((window.datas.ppolicy != null) && $('#newpassword').length) {
    // Initialize display
    checkpassword('');
    checksamepass();
    $('#confirmpassword').keyup(function(e) {
      checksamepass();
    });
    $('#newpassword').keyup(function(e) {
      checkpassword(e.target.value);
      checksamepass();
    });
    $('#newpassword').focusout(function(e) {
      checkpassword(e.target.value, "focusout");
      checksamepass();
    });
  }
  // If generating password, disable policy check
  togglecheckpassword = function(e) {
    var ref1;
    if (e.target.checked) {
      $('#newpassword').off('keyup');
      return (ref1 = $('#newpassword').get(0)) != null ? ref1.setCustomValidity('') : void 0;
    } else {
      // Restore check
      $('#newpassword').keyup(function(e) {
        checkpassword(e.target.value);
      });
      return checkpassword('');
    }
  };
  $('#newpassword').change(checksamepass);
  $('#confirmpassword').change(checksamepass);
  if ((window.datas.ppolicy != null) && $('#newpassword').length) {
    $('#reset').change(togglecheckpassword);
  }
  // Set local dates (used to display history)
  $(".localeDate").each(function() {
    var s;
    s = new Date($(this).attr("val") * 1000);
    return $(this).text(s.toLocaleString());
  });
  $('.oidcConsent').on('click', function() {
    return removeOidcConsent($(this).attr('partner'));
  });
  // Ping if asked
  if (datas['pingInterval'] && datas['pingInterval'] > 0) {
    window.setTimeout(ping, datas['pingInterval']);
  }
  // Functions to show/hide display password button
  if (datas['enablePasswordDisplay']) {
    field = '';
    if (datas['dontStorePassword']) {
      $(".toggle-password").on('mousedown touchstart', function() {
        field = $(this).attr('id');
        field = field.replace(/^toggle_/, '');
        console.debug('Display', field);
        $(this).toggleClass("fa-eye fa-eye-slash");
        return $(`input[name=${field}]`).attr('class', 'form-control');
      });
      $(".toggle-password").on('mouseup touchend', function() {
        $(this).toggleClass("fa-eye fa-eye-slash");
        if ($(`input[name=${field}]`).get(0).value) {
          return $(`input[name=${field}]`).attr('class', 'form-control key');
        }
      });
    } else {
      $(".toggle-password").on('mousedown touchstart', function() {
        field = $(this).attr('id');
        field = field.replace(/^toggle_/, '');
        console.debug('Display', field);
        $(this).toggleClass("fa-eye fa-eye-slash");
        return $(`input[name=${field}]`).attr("type", "text");
      });
      $(".toggle-password").on('mouseup touchend', function() {
        $(this).toggleClass("fa-eye fa-eye-slash");
        return $(`input[name=${field}]`).attr("type", "password");
      });
    }
  }
  // Functions to show/hide newpassword inputs
  $('#reset').change(function() {
    var checked, ref1, ref2, ref3, ref4, ref5;
    checked = $(this).prop('checked');
    console.debug('Reset is checked', checked);
    if (checked === true) {
      $('#ppolicy').hide();
      $('#newpasswords').hide();
      $('#newpassword').removeAttr('required');
      $('#confirmpassword').removeAttr('required');
      return (ref1 = $('#confirmpassword').get(0)) != null ? ref1.setCustomValidity('') : void 0;
    } else {
      $('#ppolicy').show();
      $('#newpasswords').show();
      $('#newpassword').attr('required', true);
      $('#confirmpassword').attr('required', true);
      if (((ref2 = $('#confirmpassword').get(0)) != null ? ref2.value : void 0) === ((ref3 = $('#newpassword').get(0)) != null ? ref3.value : void 0)) {
        return (ref4 = $('#confirmpassword').get(0)) != null ? ref4.setCustomValidity('') : void 0;
      } else {
        return (ref5 = $('#confirmpassword').get(0)) != null ? ref5.setCustomValidity(translate('PE34')) : void 0;
      }
    }
  });
  // Functions to show/hide placeholder password inputs
  $('#passwordfield').on('input', function() {
    if ($('#passwordfield').get(0).value && datas['dontStorePassword']) {
      return $("#passwordfield").attr('class', 'form-control key');
    } else {
      return $("#passwordfield").attr('class', 'form-control');
    }
  });
  $('#oldpassword').on('input', function() {
    if ($('#oldpassword').get(0).value && datas['dontStorePassword']) {
      return $("#oldpassword").attr('class', 'form-control key');
    } else {
      return $("#oldpassword").attr('class', 'form-control');
    }
  });
  $('#newpassword').on('input', function() {
    if ($('#newpassword').get(0).value && datas['dontStorePassword']) {
      return $("#newpassword").attr('class', 'form-control key');
    } else {
      return $("#newpassword").attr('class', 'form-control');
    }
  });
  $('#confirmpassword').on('input', function() {
    if ($('#confirmpassword').get(0).value && datas['dontStorePassword']) {
      return $("#confirmpassword").attr('class', 'form-control key');
    } else {
      return $("#confirmpassword").attr('class', 'form-control');
    }
  });
  //$('#formpass').on 'submit', changePwd
  $('.clear-finduser-field').on('click', function() {
    return $(this).parent().find(':input').each(function() {
      console.debug('Clear search field ->', $(this).attr('name'));
      return $(this).val('');
    });
  });
  $('#closefinduserform').on('click', function() {
    console.debug('Clear modal');
    return $('#finduserForm').trigger('reset');
  });
  $('#finduserbutton').on('click', function(event) {
    var str;
    event.preventDefault();
    document.body.style.cursor = 'progress';
    str = $("#finduserForm").serialize();
    console.debug('Send findUser request with parameters', str);
    return $.ajax({
      type: "POST",
      url: `${scriptname}finduser`,
      dataType: 'json',
      data: str,
      // On success, values are set
      success: function(data) {
        var user;
        document.body.style.cursor = 'default';
        user = data.user;
        console.debug('Suggested spoofId=', user);
        $("input[name=spoofId]").each(function() {
          return $(this).val(user);
        });
        if (data.captcha) {
          $('#captcha').attr('src', data.captcha);
        }
        if (data.token) {
          $('#finduserToken').val(data.token);
          return $('#token').val(data.token);
        }
      },
      error: function(j, status, err) {
        var res;
        document.body.style.cursor = 'default';
        if (err) {
          console.error('Error', err);
        }
        if (j) {
          res = JSON.parse(j.responseText);
        }
        if (res && res.error) {
          console.error('Returned error', res);
        }
      }
    });
  });
  $('#btn-back-to-top').on('click', function() {
    console.debug('Back to top');
    document.body.scrollTop = 0;
    return document.documentElement.scrollTop = 0;
  });
  $(window).on('scroll', function() {
    if (datas['scrollTop'] && (document.body.scrollTop > Math.abs(datas['scrollTop']) || document.documentElement.scrollTop > Math.abs(datas['scrollTop']))) {
      return $('#btn-back-to-top').css("display", "block");
    } else {
      return $('#btn-back-to-top').css("display", "none");
    }
  });
  $('form[data-property=single-submit]').on('submit', function(event) {
    if ($(this).data('data-submitted') === true) {
      event.preventDefault();
    } else {
      $(this).find(':submit').prop('disabled', true);
      return $(this).data('data-submitted', true);
    }
  });
  $(`.category[name=\"${datas['floatingCategory']}\"]`).appendTo('#floating-menu').find("i").remove();
  $(`.category[name=\"${datas['floatingCategory']}\"]`).draggable();
  const parent = document.getElementById('floating-menu');
  if (parent) {
    const divs = parent.querySelectorAll('.col-md-4');
    divs.forEach(
      (div, index) => {
        div.classList.remove("col-md-4");
        div.classList.add("col-md-12");
      }
    );
  }
  $(document).trigger("portalLoaded");
  return true;
});
