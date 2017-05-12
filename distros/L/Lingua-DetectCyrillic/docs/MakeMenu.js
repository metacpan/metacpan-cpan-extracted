if (!MenuBuiltOnServer) {
	document.write($LocalMenuStart);
for (i=0;i<$AvailableLangs.length;i++) { 	
	document.write('<td><a href="../'+$AvailableLangs[i]+'/index.htm">'+$AvailableLangs[i]+'</a></td>'); 
}

	document.write($LocalMenuEnd);
}

