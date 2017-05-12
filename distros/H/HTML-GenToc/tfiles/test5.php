<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php 
    $myDir = "reviews/netfic";
    $relTopDir = "../..";
    $absTopDir = "/files/home_common/kat/kat_web/katspace";
    $sourceFile = "report.xhtm";
    $destFile = "report.tmpl";
    $destExt = "php";
    ?><html >
<!-- global default variables -->












<?php $menu_style = "side";?>
<!-- end default variables -->





<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<?php include_once "${relTopDir}/php_include/change_menu.inc"; ?>
  <meta name="generator" content="KWAFT" />
  
  <meta http-equiv="content-language" content="English" />
  <meta name="rating" content="General" />
  <meta name="MSSmartTagsPreventParsing" content="TRUE" />
    <?php if (preg_match("/Gecko/", $_SERVER['HTTP_USER_AGENT'])) {
        $browser_type = "full";
    } elseif (preg_match("/Mozilla.4/", $_SERVER['HTTP_USER_AGENT'])
    and !preg_match("/compatible/", $_SERVER['HTTP_USER_AGENT'])) {
        $browser_type = "Netscape4";
    } elseif (preg_match("/Konqueror/", $_SERVER['HTTP_USER_AGENT'])) {
        $browser_type = "konq";
    } elseif (preg_match("/Opera/", $_SERVER['HTTP_USER_AGENT'])) {
        $browser_type = "opera";
    } elseif (preg_match("/MSIE.6/", $_SERVER['HTTP_USER_AGENT'])
    or preg_match("/MSIE.5/", $_SERVER['HTTP_USER_AGENT'])) {
        $browser_type = "msie";
    }?>
<!-- enable the changing of the menu style -->
    <?php if ($_GET['menu_style'] != '') {
        $menu_style = $_GET['menu_style'];
    }
    $parent_file = basename($PHP_SELF);
    ?>
  
<link rel="icon" href="/images/catico1.png" type="image/png"/>
<link rel="stylesheet" href="/styles/common.css" type="text/css"/>
<!-- stylesheets -->

    <?php if ($menu_style == 'side') {
    ?>
    <link rel="stylesheet" type="text/css" href="../../styles/layout_side_netscape.css" />
    <?php } else {
    ?>
    <link rel="stylesheet" type="text/css" href="../../styles/layout_top.css" />
    <?php }
    ?>
<style type="text/css">
    <?php if ($menu_style == 'side') {
        if ($browser_type == 'full') {
      ?>
      @import url(../../styles/layout_side_framish.css);
      <?php } else if ($browser_type == 'msie') {
      ?>
      @import url(../../styles/layout_side_msie.css);
      <?php }}
      ?>
</style>
    <?php if ($browser_type == 'Netscape4') {
        ?>
    <link rel="stylesheet" href="../../styles/theme_netscape.css" title="Default" type="text/css" />

    <?php } else {
    ?>
    <link rel="stylesheet" href="../../styles/theme_alt.css" title="Default" type="text/css" />
    <!-- add the print style -->
    <link rel="stylesheet" type="text/css" media="print" href="../../styles/print.css" />

    <?php }
    ?>
<!-- make all the stylesheets possible alternates -->
<?php if ($browser_type == 'full') { ?>

<!-- the alternate stylesheets -->
  <link rel="alternate stylesheet" href="/styles/theme_default.css" title="MainGreyBlue" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_alt.css" title="AltGreyBlue" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_b5dark.css" title="B5Dark" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_b7.css" title="Blakes7" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_enarrare.css" title="Enarrare" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_jump.css" title="Jumping on the Breeze" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_lav.css" title="Lavender" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_gold.css" title="Gold" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_refract.css" title="Refractions" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/print.css" title="Print" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_sentin.css" title="Sentinel" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_sfc.css" title="SentinelsForChrist" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_stardig.css" title="Stargate" type="text/css" />

  <link rel="alternate stylesheet" href="/styles/theme_zines.css" title="Zines" type="text/css" />


<?php } ?>
<style type="text/css">
body {
margin: 0%; padding: 0%;
}
</style>
<title>Author Swellison
</title>
</head>
<body class="withbanner">
<!--ignore_perlfect_search-->
<?php if ($menu_style == 'min') {
	include "menu_min.php";
} elseif ($menu_style == 'topnav') {
	include "menu_topnav.php";
}
?>
<!--/ignore_perlfect_search-->
<div id="main">
  <div id="content">
  <a name="Top" style="height: 1px;" id="Top"><!-- Top --></a>



<h1><a name="Swellison"/>Swellison</h1>
<h3><a name="Title-Archaeology701"/><a href="http://www.idol-pursuits.tv/swellison.html">Archaeology 701</a> (<a href="Universe_Sentinel.php">Sentinel</a>)</h3>
<p></p>
<p>Reviewed by Kathryn Andersen on 22 July 2000 (2)<br/>
<br/> Cool to see Jim in Blair's world, for once.
Evidence gathering is evidence gathering, though policemen don't
usually have to <em>dig</em> for it.  Nice.<br/>
</p>
<h3><a name="Title-Platinum"/><a href="http://www.idol-pursuits.tv/swellison.html">Platinum</a> (<a href="Universe_Sentinel.php">Sentinel</a>)</h3>
<p></p>
<p>Reviewed by Kathryn Andersen on 26 August 2000 (9)<br/>
<br/> A lot of cool senses work in this story, I really liked that.
And I enjoyed the banter between the guys.  And it was a case story
too!<br/>
</p>
<h3><a name="Title-RoutineTrafficStop"/><a href="http://www.angelfire.com/nf/sentiwheel/">Routine Traffic Stop</a> (<a href="Universe_SentinelER.php">Sentinel/ER</a>)</h3>
<p></p>
<p>Reviewed by Kathryn Andersen on 29 July 2001 (14)<br/>
<br/> This is one of the stories written for the "<a href="../../fandef.php#crossover">crossover</a>" Lyric Wheel,
though the ER stuff is more of a cameo -- the main concentration is on
Jim and Blair.  There are two parts to this story -- the action and the
owies.  I found the action the most interesting bit, the plot
deliciously ironic.  Jim and Blair on the beat, and it's just a routine
traffic stop -- NOT!  (grin)  The bit at the hospital is good because
the ER characters are, well, from ER (therefore not cyphers as they
often are) but I found some parts with Jim at the hospital were a bit
soppy -- saying things aloud that he would think, but probably wouldn't
say -- but you could argue that since he was effectively alone, there
was no difference...<br/>
</p>
<h2><a name="Series-FauxPawsProductions" href="Series_FauxPawsProductions.php">Faux Paws Productions</a></h2>

<h3><a name="Title-WindShiftFPP-506"/>(520) <a href="http://www.skeeter63.org/~fpp/">Wind Shift (FPP-506)</a> (<a href="Universe_Sentinel.php">Sentinel</a>)</h3>
<p></p>
<p>Reviewed by Kathryn Andersen on 26 August 2000 (1)<br/>
<br/> This was good.  I liked the little bit of continuity with
<em>Deal's Way</em>.  This was just a good case story, with a cool
little Jim flashback in there.<br/>
</p>
<hr/><p><a href="Author_SuburbanHouseElf.php">Prev Author: Suburban House Elf</a> <a href="Author_TAE.php">Next Author: TAE</a></p>


  <a name="Bottom" style="height: 1px;" id="Bottom"><!-- Bottom --></a>
  </div>
<!--ignore_perlfect_search-->
  <div id="footer">
  <p class="center">
  
  Last touched: 2003-04-30 08:12 * Generated: 2004-08-08 18:47
  <?php echo "<", "a href=\"http://validator.w3.org/check?uri=http://",
  	$_SERVER['HTTP_HOST'], $_SERVER['REQUEST_URI'],
	"\">Validate My HTML<", "/a>\n";
  ?>
  <?php echo "<", "a href=\"http://jigsaw.w3.org/css-validator/validator?uri=http://",
  	$_SERVER['HTTP_HOST'], $_SERVER['REQUEST_URI'],
	"\">Validate My CSS<", "/a>\n";
  ?>
  </p>
  </div>
<!--/ignore_perlfect_search-->
</div>
<!--ignore_perlfect_search-->
  <?php if ($menu_style == 'side') {
  	include "menu_side.php";
  }
  ?>
<!--/ignore_perlfect_search-->
</body>
</html>
