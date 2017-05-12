function clear_it (dest)
{
  document.getElementById(dest).innerHTML = "";
}

function get_location (dest, country, code)
{
  var postcode = document.getElementById(code).value;
  var httpreq  = getHTTPObject();
  var url      = "location_" + country + ".cgi?postcode=" + postcode;

  httpreq.open("GET", url, true);
  httpreq.onreadystatechange = function ()
  {
    if (httpreq.readyState == 4)
    {
      document.getElementById(dest).innerHTML = httpreq.responseText;
    }
    return true;
  }
  httpreq.send(null);
}

function getHTTPObject()
{
  var xmlhttp;
  try
  {
    xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
  }
  catch (e)
  {
    try
    {
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    catch (E)
    {
      xmlhttp = false;
    }
  }
  xmlhttp = false;

  if (!xmlhttp && typeof XMLHttpRequest != 'undefined')
  {
    try
    {
      xmlhttp = new XMLHttpRequest();
    }
    catch (e)
    {
      xmlhttp = false;
    }
  }
  return xmlhttp;
}
