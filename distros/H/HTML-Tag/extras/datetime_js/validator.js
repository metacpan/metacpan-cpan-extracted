function validate_integer(el,negative)
{
  var checkOK = "0123456789";
  if (negative) checkOK += '-';
  var checkStr = el.value;
  var isValid = true;
  var validGroups = true;
  var decPoints = 0;
  var allNum = "";
  for (i = 0;  i < checkStr.length;  i++)
  {
    ch = checkStr.charAt(i);
    for (j = 0;  j < checkOK.length;  j++)
      if (ch == checkOK.charAt(j))
        break;
    if (j == checkOK.length)
    {
      isValid = false;
      break;
    }
    allNum += ch;
  }
  return (isValid);
}

function validate_day(el) {
	var isValid	 = validate_integer(el);
	if (!isValid) return isValid;
	var checkStr = el.value;
	if (checkStr<1 || checkStr > 31) {
		isValid = false;
		return isValid;	
	}
	return isValid;
}