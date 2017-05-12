#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
sub render_html {
	my %param = @_;
	return <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$param{form}</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type="text/css" media="all">
	\@import "../css/vertically-aligned.css";
</style>
<!--[if IE]>
	<style type="text/css" media="all">
		\@import "../css/vertically-aligned-ie.css";
	</style>
<![endif]-->

</head>
<body>

<a href="../forms/$param{form}.yml">Form config file</a><br/><br/>

$param{html}

</body>
</html>

HTML
	
	
	
}

1;