function tooltip (variable) {
//  alert("tooltip for " + variable);
  url = 'http://' + document.location.host + '/ajax_variable/' + variable;
//  alert("url is " + url);
  new Ajax.Request(
    url, {
    asynchronous: 1,
    onComplete:
      function (request) {
        response  = request.responseXML.documentElement;
        variable = response.getElementsByTagName('variable')[0].firstChild.data;
      value = response.getElementsByTagName('value')[0].firstChild.data;
      return overlib('<div style="font-family: \'monospace\'">' + value + '</div>', FOLLOWMOUSE, WRAP);
      return true;
    }
  });
  return false;
}
