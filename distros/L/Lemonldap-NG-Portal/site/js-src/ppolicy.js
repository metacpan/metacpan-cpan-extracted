var isAlphaNumeric;

isAlphaNumeric = function(chr) {
  var code;
  code = chr.charCodeAt(0);
  if (code > 47 && code < 58 || code > 64 && code < 91 || code > 96 && code < 123) {
    return true;
  }
  return false;
};

$(document).on('checkpassword', function(event, context) {
  var digit, hasforbidden, i, len, lower, nonwhitespechar, numspechar, password, report, setResult, upper;
  password = context.password;
  context.evType;
  setResult = context.setResult;
  report = function(result, id) {
    if (result) {
      return setResult(id, "good");
    } else {
      return setResult(id, "bad");
    }
  };
  if (window.datas.ppolicy.minsize > 0) {
    report(password.length >= window.datas.ppolicy.minsize, 'ppolicy-minsize-feedback');
  }
  if (window.datas.ppolicy.maxsize > 0) {
    report(password.length <= window.datas.ppolicy.maxsize, 'ppolicy-maxsize-feedback');
  }
  if (window.datas.ppolicy.minupper > 0) {
    upper = password.match(/[A-Z]/g);
    report(upper && upper.length >= window.datas.ppolicy.minupper, 'ppolicy-minupper-feedback');
  }
  if (window.datas.ppolicy.minlower > 0) {
    lower = password.match(/[a-z]/g);
    report(lower && lower.length >= window.datas.ppolicy.minlower, 'ppolicy-minlower-feedback');
  }
  if (window.datas.ppolicy.mindigit > 0) {
    digit = password.match(/[0-9]/g);
    report(digit && digit.length >= window.datas.ppolicy.mindigit, 'ppolicy-mindigit-feedback');
  }
  if (window.datas.ppolicy.allowedspechar) {
    nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '');
    nonwhitespechar = nonwhitespechar.replace(/<space>/g, ' ');
    hasforbidden = false;
    i = 0;
    len = password.length;
    while (i < len) {
      if (!isAlphaNumeric(password.charAt(i))) {
        if (nonwhitespechar.indexOf(password.charAt(i)) < 0) {
          hasforbidden = true;
        }
      }
      i++;
    }
    report(hasforbidden === false, 'ppolicy-allowedspechar-feedback');
  }
  if (window.datas.ppolicy.minspechar > 0 && window.datas.ppolicy.allowedspechar) {
    numspechar = 0;
    nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '');
    nonwhitespechar = nonwhitespechar.replace(/<space>/g, ' ');
    i = 0;
    while (i < password.length) {
      if (nonwhitespechar.indexOf(password.charAt(i)) >= 0) {
        numspechar++;
      }
      i++;
    }
    report(numspechar >= window.datas.ppolicy.minspechar, 'ppolicy-minspechar-feedback');
  }
  if (window.datas.ppolicy.minspechar > 0 && !window.datas.ppolicy.allowedspechar) {
    numspechar = 0;
    i = 0;
    while (i < password.length) {
      if (!isAlphaNumeric(password.charAt(i))) {
        numspechar++;
      }
      i++;
    }
    return report(numspechar >= window.datas.ppolicy.minspechar, 'ppolicy-minspechar-feedback');
  }
});
