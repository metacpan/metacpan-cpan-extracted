var values;

values = {};

$(document).ready(function() {
  // Import application/init variables
  $("script[type='application/init']").each(function() {
    var e, k, results, tmp;
    try {
      tmp = JSON.parse($(this).text());
      results = [];
      for (k in tmp) {
        results.push(values[k] = tmp[k]);
      }
      return results;
    } catch (error) {
      //console.log 'values=', values[k]
      e = error;
      return console.log('Parsing error', e);
    }
  });
  // Initialize JS communication channel
  return window.addEventListener("message", function(e) {
    var client_id, message, salt, session_state, ss, stat;
    message = e.data;
    console.log('message=', message);
    client_id = decodeURIComponent(message.split(' ')[0]);
    //console.log 'client_id=', client_id
    session_state = decodeURIComponent(message.split(' ')[1]);
    //console.log 'session_state=', session_state
    salt = decodeURIComponent(session_state.split('.')[1]);
    //console.log 'salt=', salt
    // hash ??????
    //ss = hash.toString(CryptoJS.enc.Base64) + '.'  + salt
    ss = btoa(client_id + ' ' + e.origin + ' ' + salt) + '.' + salt;
    //word = CryptoJS.enc.Utf8.parse(client_id + ' ' + e.origin + ' ' + salt)
    //ss = CryptoJS.enc.Base64.stringify(word) + '.' + salt
    if (session_state === ss) {
      stat = 'unchanged';
    } else {
      stat = 'changed';
    }
    return e.source.postMessage(stat, e.origin);
  }, false);
});
