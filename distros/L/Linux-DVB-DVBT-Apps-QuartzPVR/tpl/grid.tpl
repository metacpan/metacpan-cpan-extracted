<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<!-- VERSION 1.001 -->

        <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
        
        
        <title>Listings</title>
        <link rel="shortcut icon" href="https://sdprice.plus.com/favicon.ico" type="image/x-icon"> 

	    <link rel="stylesheet" href="css/main.css" type="text/css">


<!-- 
<script language="javascript" type="text/javascript">

function showProg()
{
	var grid = GridApp.grids.tv ;
	var chan = grid.channels.get(1) ;
	var progs = chan.progs.values(Prog.prog_in_display) ;
	var prog = progs[0] ;
	var popupObj = prog['_progPopup'] ;
	var popupDiv = popupObj.dom ;
	var popup = popupObj.top ;
	popup.show(popupDiv, 100, 100, 400);
}

function hideProg()
{
	var grid = GridApp.grids.tv ;
	var chan = grid.channels.get(1) ;
	var progs = chan.progs.values(Prog.prog_in_display) ;
	var prog = progs[0] ;
	var popupObj = prog['_progPopup'] ;
	var popupDiv = popupObj.dom ;
	var popup = popupObj.top ;
	popup.hide();
}

</script>
 -->

</head>

<body id="quartz-net-com">

<div id="quartz-body">

<div id="quartz-content">
<div class="chrome">

<div class="listings" id="qtv-listings">

<!-- Heading -->
<div class="hd" id="list-hd">
	<div id="gridhd">
	
<!-- Overwritten when app starts
		<h2>
			<a href="#">TV listings (multirec)</a>
		</h2>
		
		<div id="toolbar">
			<img src="css/theme/black/tbend.gif" /> 
			
			<a href="#" onclick="Settings.set();"><img src="css/theme/black/tools.png" /></a>
		</div>
 -->
 
 		
	</div>
</div>
 
<!-- Body -->
<div class="bd" id="list-body">

	<div class="grid" id="gridbox">
	
		
	</div>

</div> <!-- bd -->

<!-- Footer -->
<div class="ft">
	<span></span>
</div>


</div> <!-- quartz-content -->
</div> <!-- chrome -->
</div> <!-- qtv-listings -->

	
</div>

<!-- 
<button onclick="Settings.set();">Settings</button>
<button onclick="GridApp.msgbox.info('this is some info', 400, 400);">Info!</button>
<button onclick="GridApp.msgbox.warn('this is a warning', 0, 0);">Warning!</button>
<button onclick="GridApp.msgbox.error('this is an error', 200, 200);">Error!</button>
<button onclick="showProg();">Unhide prog details</button>
<button onclick="hideProg();">Hide prog details</button>

<button onclick="GridApp.redraw();">Redraw screen</button>
 -->

<!--
<div id="infox" style="color:white;"></div>

<script type="text/javascript">
var txt = "" ;
txt += "<p>Browser codename: " + navigator.appCodeName + "</p>" ;
txt += "<p>Browser name: " + navigator.appName + "</p>" ;
txt += "<p>Browser version: " + navigator.appVersion + "</p>" ;
txt += "<p>Platform: " + navigator.platform + "</p>" ;
txt += "<p>User Agent: " + navigator.userAgent + "</p>" ;

document.getElementById("infox").innerHTML = txt ;
</script>
-->

<!--  -->   <!--  <script language="javascript" src="js/alljs.js" type="text/javascript"></script>  -->

		<!-- JQuery -->
		<script language='javascript' src='js/jquery/jquery-1.4.js' type='text/javascript'></script>
		<script language='javascript' src='js/quartz/jqps3.js' type='text/javascript'></script>
 
		<!-- David Flanagan -->
        <script language="javascript" src="js/df/Log.js" type="text/javascript"></script>
        <script language="javascript" src="js/df/Cookie.js" type="text/javascript"></script>

		<!-- Mine -->
		<script language='javascript' src='js/quartz/Geometry.js' type='text/javascript'></script>
        <script language="javascript" src="js/quartz/http.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/DomUtils.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/TabList.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/Dialog.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/Msgbox.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/Profile.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/Loading.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/DateUtils.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/Env.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/ObjList.js" type="text/javascript"></script>
        <script language="javascript" src="js/quartz/SortedObjList.js" type="text/javascript"></script>
		<script language='javascript' src='js/quartz/Popup.js' type='text/javascript'></script>
		<script language='javascript' src='js/quartz/PopupHandler.js' type='text/javascript'></script>
		<script language='javascript' src='js/quartz/ClickHandler.js' type='text/javascript'></script>
		<script language='javascript' src='js/quartz/InPlace.js' type='text/javascript'></script>
		
		<script language="javascript" src="js/tvguide/Objects/Settings.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/Prog.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/Multirec.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/Recording.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/Schedule.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/Chan.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/TitleBar.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Objects/TvList.js" type="text/javascript"></script>
        
        <script language="javascript" src="js/tvguide/Pages/Grid.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Pages/RecList.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Pages/SearchList.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Pages/Recorded.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Pages/ChanSel.js" type="text/javascript"></script>
        <script language="javascript" src="js/tvguide/Pages/Scan.js" type="text/javascript"></script>
        
        <script language="javascript" src="js/tvguide/GridApp.js" type="text/javascript"></script>
 
 
</body>

</html>
