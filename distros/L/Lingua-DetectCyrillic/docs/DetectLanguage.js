var Lang;
var Destination=$DefaultLang;

//navigator.systemLanguage == MSIE; navigator.language == NS
if ( navigator.systemLanguage )  { Lang=navigator.systemLanguage; }
if ( navigator.language )  { Lang=navigator.language; }

if ( Lang )  {
	//Перебираем все языки
	for (i=0;i<$AvailableLangs.length;i++) { 	
		if (Lang==$AvailableLangs[i]) { Destination=Lang; break; }
	}
}
window.location="./"+Destination+"/index.htm";
