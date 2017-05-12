#!/usr/bin/perl
use strict;
use warnings;
use Dancer qw/!pass/;

our @EXPORT = qw/
	start_dancing
	set_port
 /;

sub set_port
{
	my ($port) = @_;
	die "You must set a port\n" unless $port;
	set port => $port;
}

sub start_dancing
{
	dance;
}

get '/reset.css' => sub {
	content_type 'text/css';
	return<<EOF
* {
	margin:    0;
	padding:   0;
	border:    0;
	font-size: 100%;
	list-style-type: none;
}
EOF
};

get '/' => sub {
	return<<EOF;
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<title>webdriver test</title>
		<script type="text/javascript">
			Element.prototype.remove = function() {
				this.parentElement.removeChild(this);
			}
			NodeList.prototype.remove = HTMLCollection.prototype.remove = function() {
				for (var i = 0, len = this.length; i < len; i++) {
					if (this[i] && this[i].parentElement) {
						this[i].parentElement.removeChild(this[i]);
					}
				}
			}
		</script>
	</head>
	<body>
		<div id="get_text">
			<p class="empty"></p>
			<p class="whitespace">&nbsp;</p>
			<p class="full"><strong>There's data in them thar P tags</strong></p>
		</div>
		<div id="get_val">
			<input name="empty" class="empty" type="text">
			<input name="whitespace" class="whitespace" type="text" value=" ">
			<input name="full" class="full" type="text" value="myVal">
		</div>
		<div id="get_html">
			<div class="empty"></div>
			<div class="full"><div>&nbsp</div></div>
		</div>

		<a id="_test1"  target="_blank" href="/" >Test 1</a>
		<a id="_test2"   target="_blank" href="/test2" >Test 2</a>
		<a id="_test3" target="_blank" href="/test3" >Test 3</a>
		<select name="selector" form="_form">
			<option value="val 1">Label 1</option>
			<option value="val 2">Label 2</option>
			<option value="val 3">Label 3</option>
		</select>
		<form action="/" method="post" id="_form">
			<input class="_placeholder" type="text" placeholder="test?" name="test1">
			<input class="_value"       type="text" value="val 1" name="test2">
			<input class="_checkbox"    type="checkbox" value="option1" name="test3">
			<input type="submit" value="Done">
		</form>

		<br />
		<a id="_test_a" onclick="test_anchor()" href="#">Test anchor</a>
		<div id="_div_test_a" style="display:none"></div>
		<script>
			var div_is_vis = 0;
			function div_to_visible () {
				if (!div_is_vis) {
					var y = document.getElementById("_div_test_a");
					y.innerHTML = "You clicked on the link! Good on you";
					y.style.display = 'inline';
					div_is_vis = 1;
				} else {
					var y = document.getElementById("_div_test_a");
					y.style.display = 'none';
					div_is_vis = 0;
				}
			};
			function test_anchor () {
				setTimeout("div_to_visible()", 2000);
			};
		</script>
		<br />
		<a id="_murder" onclick="delete_guy()" href="#">Murder</a><div id="_that_guy"> Some guy here</div>
		<script>
			function delete_element () {
				document.getElementById("_that_guy").remove();
			};
			function delete_guy () {
				setTimeout("delete_element()", 2000);
			};
		</script>
		<br />
		<button class="popup" onclick="popup_func()">Popup</button>
		<script>
			function popup_func()
			{
				alert("I am an alert box!");
			}
		</script>

		<br />
		<button class="popup confirm" onclick="myFunction()">Popup Confirm</button>
		<p style="display:none" id="ok_cancel"></p>
		<script>
			function myFunction()
			{
				var x;
				var r=confirm("Press a button!");
				if (r==true) {
					x="OK!";
				} else {
					x="Cancel!";
				}
				var y = document.getElementById("ok_cancel");
				y.innerHTML = x;
				y.style.display = "inline";
			}
		</script>

		<br />
		<button class="popup input" onclick="my_Function()">Popup Input</button>
		<p id="popup_input"></p>
		<script>
			function my_Function()
			{
				var x;
				var person=prompt("Please enter your name", "synmon01");
				if (person!=null) {
					x="Hello " + person + "! How are you today?";
					var y = document.getElementById("popup_input");
					y.innerHTML = x;
					y.style.display = "inline";
				}
			}
		</script>
		<p id="test_text">
			Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
		</p>
	</body>
</html>
EOF
};

post '/' => sub {
	
	return "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<title>webdriver test 2</title>
	</head>
	<body>_placeholder: <div style=\"display:inline;\" id=\"_placeholder\">".param('test1')."</div>
	<br />_value: <div style=\"display:inline;\" id=\"_value\">".param('test2')."</div>
	<br />select: <div style=\"display:inline;\" id=\"select\">".param('selector')."</div>
	</body></html>"
};

get '/test2' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>webdriver test 2</title>
	</head>
	<body>TEST 2</body>
</html>
EOF
};

get '/test3' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>webdriver test 3</title>
	</head>
	<body>TEST 3</body>
</html>
EOF
};


get '/p_tag' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>p tag test</title>
	</head>
	<body>
		<a id="_adder" onclick="add()" href="#">Counter</a><br/>
		<a id="_creator" onclick="birth()" href="#">Appear</a><br/>
		<p class="p_test">
			this is text
			<span id="t">and some more</span>
			and now the end
		</p>
		<div id="_stump"></div>
		<script>
			var counter = 0;
			function add () {
				counter++;
				var y = document.getElementById("t");
				y.innerHTML = counter;
			};
			function birth () {
				var para=document.createElement('p');
				para.setAttribute('class', '_p_');
				var text=document.createTextNode("New text begins ");
				var spanner=document.createElement('span');
				spanner.setAttribute('id', '_span_man');
				var spanner_text=document.createTextNode("Spanner Text ");
				var ender=document.createTextNode("Speak for those that cannot");
				spanner.appendChild(spanner_text);
				para.appendChild(text);
				para.appendChild(spanner);
				para.appendChild(ender);
				document.getElementById("_stump").appendChild(para);
			}
		</script>
	</body>
</html>
EOF
};

get '/iframe' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>iframe test</title>
	</head>
	<body>
		<iframe id="main-0" frameborder="0" src="/iframe0"></iframe>
		<iframe id="main-1" frameborder="0" src="/iframe1"></iframe>
	</body>
</html>
EOF
};

get '/iframe0' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>iframe test, shim 0</title>
	</head>
	<body>
		<div id="i0-0">Hello there</div>
		<iframe id="i0-1" frameborder="0" src="/iframe2"></iframe>
	</body>
</html>
EOF
};

get '/iframe1' => sub {
	return<<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>iframe test, shim 1</title>
		<script>
			function text_changer(e) {
				e.preventDefault();
				document.getElementById("texter").innerHTML = "New Text";
			};

			function btn_div_click(e) {
				e.preventDefault();
				document.getElementById("btn-div-txt").innerHTML = "New Div Text";
			};
		</script>
	</head>
	<body>
		<div id="i1-0">Goodbye here</div>
		<form class="click_test">
			<button onclick="text_changer(event)">Test</button>
		</form>
		<div id="texter">
			placeholder
		</div>
		<div onclick="btn_div_click(event)" id="btn-div">
			clicker
		</div>
		<div id="btn-div-txt">
			div text
		</div>
	</body>
</html>
EOF
};

get '/iframe2' => sub {
	return<<EOF
<!DOCTYPE html>
<html lang="en_US">
	<head>
		<meta charset="UTF-8">
		<title>iframe test, shim 2</title>
	</head>
	<body>
		<div id="i2-0">Goodday Sir</div>
	</body>
</html>
EOF
};

get '/frame_location' => sub {
	return<<EOF
<!DOCTYPE html>
<html lang="en_US">
	<head>
		<meta charset="UTF-8">
		<title>Iframe Location</title>
		<link rel="stylesheet" href="/reset.css" />
		<link rel="stylesheet" href="/frame_location.css" />
	</head>
	<body>
		<div class="padding"></div>
		<div class="columns">
			<div class="col left"></div>
			<div class="col" id="loader"></div>
			<script type="text/javascript">
				document.getElementById("loader").innerHTML =
					'<iframe id="frame" frameborder="0" style="border:none;vertical-align:middle" src="/iframe1"></iframe>';
			</script>
		</div>
	</body>
</html>
EOF

};

get '/frame_location.css' => sub {
	content_type 'text/css';
	return<<EOF
div.padding {
	width: 200px;
	height: 200px;
}
div.col {
	float: left;
}
div.left {
	width: 200px;
	height: 200px;
}
EOF
};

dance if $ARGV[0] && $ARGV[0] eq 'start';

1;
