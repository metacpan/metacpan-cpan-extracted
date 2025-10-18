document.onreadystatechange = function() {
  var redirect;
  if (document.readyState === "complete") {
    try {
      redirect = document.getElementById('redirect').textContent.replace(/\s/g, '');
    } catch (error) {
      redirect = document.getElementById('redirect').innerHTML.replace(/\s/g, '');
    }
    if (redirect) {
      if (redirect === 'form') {
        return document.getElementById('form').submit();
      } else {
        return document.location.href = redirect;
      }
    } else {
      console.error('No redirection !');
    }
  }
};