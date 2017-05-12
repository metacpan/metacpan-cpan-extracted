// this file was adapted from an example on Wikipedia
function FindProxyForURL(url, host) {

  // our local URLs from the domains below example.com don't need a proxy:
  if (shExpMatch(url,"*.example.com/*"))    {return "DIRECT"}
  if (shExpMatch(url, "*.example.com:*/*")) {return "DIRECT"}

  /* HTTP::ProxyAutoConfig checks that the returned PROXY exists/answers, 
     so we use two host/ports that are likely to answer in the future */
  if (isInNet(host, "10.0.0.0",  "255.255.248.0")) {
     return "PROXY www.google.com:80; DIRECT";
  }
  return "PROXY www.yahoo.com:80; DIRECT";
}