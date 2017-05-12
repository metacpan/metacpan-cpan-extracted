package Kwiki::Theme::Bluepole;
use strict;
use warnings;
use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '1.00';
const config_file => 'bluepole.yaml';
const theme_id => 'bluepole';
const class_title => 'The bluepole theme';
1;

__DATA__

=head1 NAME 

Kwiki::Theme::Bluepole - A nice, blue Kwiki Theme

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::Theme::Bluepole

=head1 DESCRIPTION

This theme was taken from a Kwiki theme at http://maypole.perl.org and
altered slightly so you could replace the text in the header.

=head2 Configuration

The default config variables that you can override in config.yaml are:

 header_left: theme/bluepole/images/header_left.png
 header_top: theme/bluepole/images/header_top.png
 header_text: Bluepole

=head1 AUTHOR

Jon Åslund <aslund.org> - just modified and uploaded it

gabbana - who is the greatest - created it

=head1 COPYRIGHT

Copyright (c) 2005. Jon Åslund. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__theme/bluepole/template/tt2/kwiki_screen.html__
[%- INCLUDE kwiki_doctype.html %]
<!-- BEGIN kwiki_screen.html -->
[% INCLUDE kwiki_begin.html %]
<div id="container">

<div style="position: absolute; left: 270px; top: 28px; font-size: 70px; font-weight: bold; color: white; font-family: Bitstream Vera Sans, Verdana, sans-serif;">[% header_text %]</div>
<div id="header_pane" style="height: 145px;">
<img src="[% header_top %]" alt="Bluepole Logo" />
</div>
<div id="left_pane">
</div>
<div id="group_1">
<div class="navigation">

<div id="logo_pane">
<img src="[% header_left %]" alt="Bluepole Logo" />
</div>

<div id="widgets_pane">
[% hub.widgets.html %]
</div>
</div><!-- navigation -->
</div><!-- group1 -->

<div id="group_2">
<div class="navigation">
<div id="title_pane">
<h1>
[% screen_title || self.class_title %]
</h1>
</div>

<div id="toolbar_pane">
[% hub.toolbar.html %]
[% IF hub.have_plugin('user_name') %]
[% INCLUDE user_name_title.html %]
[% END %]
</div>

<div id="status_pane">
[% hub.status.html %]
</div>
</div><!-- navigation -->

<hr />
<div id="content_pane">
[% INCLUDE $content_pane %]
</div>
<hr />

<div class="navigation">
<div id="toolbar_pane_2">
[% hub.toolbar.html %]
</div>
</div><!-- navigation -->
</div><!-- group2 -->
[% INCLUDE kwiki_end.html %]
</div><!-- container -->
<div id="right_pane">
</div>
<!-- END kwiki_screen.html -->
__theme/bluepole/css/.htaccess__
Allow from all
__theme/bluepole/css/kwiki.css__
#header_pane {
    background: #628DC7;
}

#logo_pane {
    text-align: center;
}
    
#logo_pane img {
    width: 131px;
}

#container {
    min-height:100%;
    position: absolute;
    margin-left: 80px;
    background: #FFF;
}
#group_1 {
    width: 125px;
    background: #fff;
    float: left;
}
    
#group_2 {
    float: left;
    width: 600px;
    background: #FFF;
    margin: 0px 10px 0px 0px;
    padding: 0px 30px 30px 0px;
}

#links {
    background:#FFF;
    color:#628DC7;
    margin-right:25%;
}

div#links div.side span a { display: inline }
div#links div.side span:after { content: " | " }

html {
}

body {
    background:#EAEAEA;
    font-family: sans-serif;
    font-size: 12px;
    color: #2E415A;
    top-margin: 0px;
    left-margin: 0px;
    bottom-margin: 0px;
    right-margin: 0px;
    margin: 0px;
    padding: 0px;
}

h1, h2, h3, h4, h5, h6 {
    font-weight: bold;
    color: #628DC7;
}

hr {
    border: 0px;
    padding: 0px;
    margin-bottom: 10px;
    clear: both;
    height: 1px;
    background-color: white;
    border-bottom: 1px solid #2E415A;
}

input[type=text] {
    height: 14px;
    font-family: sans-serif;
    font-size: 11px;
    color: #2E415A;
    border: 1px solid #628DC7;
    padding: 0px;
}

ul {
    list-style-type: circle;
}

form.edit input { position: absolute; left: 3% }
textarea { width: auto }
pre {
    background-color: #fff;
    color: black;
    border: none;
}

/* ------------------------------------------------------------------- */

a         {text-decoration: none}
a:link    {color: #628DC7}
a:visited {color: #6E7E95}
a:hover   {text-decoration: underline}
a:active  {text-decoration: underline}
a.empty   {color: gray}
a.private {color: black}

.error    {color: #f00;}

div.side a { display: list-item; list-style-type: none }
div.upper-nav { }
textarea { width: 100% }
div.navigation a:visited {
    color: #628DC7;
}
__theme/bluepole/images/.htaccess__
Allow from all
__theme/bluepole/images/header_top.png__
iVBORw0KGgoAAAANSUhEUgAAAo8AAACRBAMAAABQ/U+KAAAAGFBMVEWBpNKqwuFUeKnY4/Fb
g7lNbZn///9ijceIDUKrAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QELBQoqQ9lq
OgAAB+FJREFUeNrtnd1q6zoQhXt33qNY5D1MhO+NTV5jI2z0+ptz6ib6WWsspyH0zDgXmw1N
A/k6M2vNSLI+In/NL35N8Ze8/nx8/Pvvaz9S+KF7Mchb/DUk41tB+heDHOIvev35+OdtIMNr
OY7xd4F848dpzey3/11eWySjXZDhDMgXVQqntUK+G2RQKtnv166XOaBLtA3yRck9aufY4KZe
QfJziCfI2H9H1VNIu8/uGg28mvz99fr5eR2ei80u2ngdaJSW//fE5/eAXE/7+BqQX5k9HgU5
nCBhZl/cacR/BrLfAqw5w0cbTvwwSPetHc0yY2FWcRzkco+v1q5xcJZkuxlkf5eOtVWuvSXZ
bgb5CC/fOqVYLcl2K8jwUA4m2670j8GSbLeCXB+rBQzkzReuZ7Ek260gH5m9UJD38cZGb7Gk
No0gk8xOWu7RF111cJkNd4bUphHkQ7M3puNy7a65gP8XeVeX5HN/guSZvYGc6jnGF7AtnxOQ
NtSmDeRShVnHQMbkreEEWbx84gh9IsUBbABIQG7R2Z0gQWZv/x8AyCH5eVf93gky0+zviGsD
aahJbAKZZnZM0ziApes0Cr2dJrEJZMpmSYNsASB98mZDatMCMsvs1P3sgjTUJLaAXNNs7jnI
qa6Ldma7LSAz7U1tJASZtTN2ZLsBZJ6fPktWsPK6piC9gS2mzSD7THpdJh8AZACyPpwgy/Rc
GkFu3O2ozT7InMUXyLvFBpvEEcjuBFlmdsh7FVe3NkuWzWbUpnV/5Jh5yqkZpJkmcRdkUeXW
3Bg64MizX+itNIm7INdcd3P3UyzNprOzC+iKTIMs1l1EkLcEZBdtyfYeyBJE7n4QyJhPc62o
zR7IwlFv7oeATCe/t2hLbfZAFgG1FFg8nVpM0Zba7IGcj4AcQQxaaRLbjtANEdvIcmdaPf4x
swC2A7KscH1B5QTZBrKiULgfCDLkVdGI2jSd1x4icT8lyKGao5lRGxlktQpYgg3gCGzebFtR
m5ZHMUyliMcWkJdoqrcRQVYMSvdTgkx7xCGa6m1EkFV5K91PeT7xVk8trKhNw5OoptgMckry
v7OlNhLIurqV7geDzJttI2ojgVwrAnsgR9BsG1m3kUDWxc1VsTXvNttG1EYAWWd2OUSrD8OD
HtGI2ggg69q21EQcaG1KdTGhNgLIOpBCnaPzfo9oQ20EkPUzKQBIB1qbEpyJARAHCeJorTfp
uf1m24bacJBgI5mvu2aHWptSpSyoDQfpWB4PuyCLHtFEkaQgwdBm2QeZtjad9Fl2QILjb8D9
lKfgJxjMFtSGggSZ3QAS9ogm1IaCBNvogfuRQI7CPM4OSKQPPUjQdebLX9GS2jCQnqbxpRXk
HC2pDQEJn6IARLsCOUBHbuChDAwkCqEWkLi1MWDJCUioDujMTIAgS0duQG0ISJSKyP1UIDvo
yA2oDQa5oDOEyP2IIG/RkCXHIGEANYGcsCPXb8kxSKgNyP1Uaw3EketXGwgSJ+IBkCsZrisu
khgk9M/I/RCQYSarZBdbIKFZqZcQEcg5YiOpXm0gSKgM0P3UIAcSf9qLJAIJzQ8W7frZfQN2
5OotOQKJhQGDjPi6lTqRtZ+lQyBxFva4yDkB5FSHrimQ2Dx7DMLBm708WzmbDIEkTsVhI4hB
1kZSu9oAkEQWGkFmj6Dar7yaQTrJ58Q2kAtbg1RbJGuQi4NPj1pIZnrY2iBquotkDZKkIHE/
DCTQaN1Fsga54hwm7qcGORAjyT5YLUiSgb4R5BbKnu0v0FokK5ALecCeJ5orghxBE3QzApK5
FOJ+0qfhpxGHHkGuWm0qkEQSFjZzWDHIAN6vem5RgSRhw9xPfU3vjRlJ3Za8BMkUITwH8gIc
amcCJIuawIQikBslHd2qMZkAyVzz+hxItAdQZ5EsQc5iA3NpAJk9FHZqCneFIKlpdkdBgkGa
aktegFxJzOAlxARO1SMG1BAqLpIFSFYiD4CcB+p/NM8tcpDUoFAbSUFGlMaKi2QBkhWxQHNy
mXFrE9FYU3GRzEHSJo6DjAwkkm3FRTIHSa+N8zySZtzaSDvaRu0geQ/3BEjYVK5qi2QGku+G
cPz7O9LaXBEzvUUyA9nTxQBhlYCBxMzUDnczkLRELkdAjlmduBgpkhlIGi6L8PUZSCzbaotk
CpKXSMH91Is2o3S7gNoimYLk66W9MJH1rLWBN8eqHe6mIHn9EtwPBxmgu9daJFOQXFHdIZAX
KYu1roAlIIXyJdjIehkxv0OInCe5KAbJBXVDEhtB3jL8nY0imYD0O6Oy8ShI/IFKi+QDpHA4
/SDI4poG6ABmxSB58ZJsZL1oc38jHuMqLZIPkMI996vUINcgi9sFhmih3X6AFGqX/xFIvKt/
VAtSGF5LfhyBHKRuG68v6gEplS7JRoJFm1m+70LnGbA7SGGBj6/F7oDETaJOJ3kHKezLOQyy
uKZhsFAk7yCFEinaSBEkVhuV7fY3SCnfgryGOtPWBjeJOp3kN0hpD8TzIL10xrtTCVJKNy87
6Jm2NqRJVNluf4OUBMDLmSiAJHGuceEmB4nTd+fIuqOtDauGGovkBlL8ak6OHwFkxAdENbbb
G0hJa2QbCUEOstpoLJIbSOmbLTvf2vHWBm6Ajir3SW4gpRK5B9ILIMmAQmGR/AIpXoK0YyMR
yEuUm0SF+yS/QIqp1v8AZCShp69I/vkLT/ViC/+fQLAAAAAASUVORK5CYII=
__theme/bluepole/images/header_left.png__
iVBORw0KGgoAAAANSUhEUgAAAIMAAACtCAMAAACk5TwSAAAABGdBTUEAAK/INwWK6QAAABl0
RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAMAUExURWSApujs8oSaucbQ3lp4
ofz9/t7k7JqsxVBwm1Rzne3w9U9umtXc5/H098TP3Yacuvv8/Vl3oG6IrNDZ5Pv8/LzI2Yid
umyGq56wx6a2zNbc6GJ+pa680IGYt2B9pICWto6ivsjS4LC+0nWOsM7W47vH2Imeu9jf6OHm
7szW4tzi62aCqPn6/LLA0/j6+9rh6r7K2l16osvU4ZyuxuLn7n2UtJirxLjF1lh2n8LN3HqS
s1NynOru8/3+/qS1y+Xq8HiQsnCKre7y9nOMr5apw+Lm7miDqZOmwau6z7bE1bXC1NPa5lBv
mt3j7F57o5SownSOsIOZuNLa5c/Y5GqGqoyhvZGkwO7x9mqFqsHM29vi6o+jv8DL21JxnJ+x
yE5umaOzynGKruru9Pb3+uPo78nT4GJ+puTp8HmQsXKLrsHM3Km4zrbC1F58o2aCp1V0nsPO
3X6Wtay7z36WtsjR34ugvMzV4nCJray80HqRsuDm7YyhvrG/0qi4zZeqxOnv8+nt8ufs8a27
0Nng6tng6WF+pZ2vyHmSs5SnwrbD1VFwm6K0yqKyydbe6NPc52qEqZGlwE1tmf7+/vj5+1Z0
nu7x9fP1+GmEqfr7/Fd1n/X3+Vx5of7+/+fr8fb4+nSNr9Tb5uzv9PT2+PT2+ff4+n6Vtf7/
/3SNsHuTtPHz9/L1+LnG156vx1d1nqi3zfDz9vP2+Fx5ot/l7WWBp7PB1LTB1E5tmfDy9vL0
9/v7/Obq8LrG1198o6m5zvDz96GyyWB8o6++0dXd5/f5++js8W2Hq/X2+ff5+vX3+nePsbvI
2I2ivvH0+GmEqvT3+Zeqw/v7/d3k7LC+0fr6/Obq8ebr8VZ1n4+kv01umlx6ob7J2k5tmld2
n5iqw//+/p+wyJSowU1tmk1umff4+3yTs/Dy9/r7/fb3+dHZ5dDY473J2eDl7vz+/f39/qe4
zX6Vtvr7+/T3+PX3+P7//uvw9Nrg6e/y9vb4+Vd2oGF9pMfR3+fr8vP0+JutxnyTtP///5gn
daYAAAkNSURBVHja7JhpXFTXGYfZByYgFxTQMoDsIMMiIswowxKo6wxWQEHRoEWqxFbRFOgY
tGhqLCSkdEZwYAZkFxAB93GpiIrGmLhGE0yNzVqima6EFlp68547cMePvef29zsfOs855x2+
/F8ezt3mYkFPEuL6WxMWa+n/nuJkU7AtkuaOxdQPPUMvOHRXc2hxeswUTC3j4dCVlGvqVJuu
4tAi9qApWXqdh8MFzxe2oaieS4sFclMyg8J3sHVef+bz3Nzcjz/5PPczuVTMoYNBcuaT3DNn
cs/k5n72cQ2N7zB9UP6S/CWQQEtpx6GBajNkUAqy8pM0DweBCyjI5cySi7j8NeJpkynAwZmH
Q8wBudyemcC2Ri4NOrcyKXsUP76Bh0O4RUWFfQUse7l9hYDT9XV+MZNE2YpFbvgOevf1FeuN
VKzXFhq4NLjSBqGKCpRcnzSM7zC+cSH8elgLYTkrODWY5soE0VxYFIPtQD2VLGRxKFVzajDg
aco+HcV2CPZa6GAEPv0DuDVItTEmUYtAMbbDMguH7Q4O2wGo84TcGnRshySTd3BopHEd4lMP
Ao8OHtwOH1xP7bPZk2Hg5IfYDvkpx2prH9UyHHO345a3S4PQsWOPoMWxpBZchzyRRFKLZu0/
JZK0BE4XJm0Yl0h+DwOodZlN4zoo3F1cJBIXiQuaW4q5xa+KUAyC0OJyD66D7bg3dLBxsbGB
ajO7jlu8WjAZBBY9w3Vo6rex0WpttKiL1mMZx/imIJsptP7f4Do8Tx46flw7NKTVaoeOL3jI
Md64QHtca2TI6jmuw7O5aXPT0uYi0ixiucYLSyA210iqENfBPQ34GQwgO4NrfCDsYtoUWxtw
HfZfvghchnrZW2ngGu/2vsjEUYlS4Tp4j3l7w4I65hnONa0OYtJjl6GEpdO4Dp6enmOw9u8f
8wyL13FMC+dDdj8a+z1TNvFwsLBAIkAs52/FJ5JR1gJa/MTTqxrb4QXyNVzTw9tM6SoK2+Ek
i9curmHqMcQmO4S9RWM7hIVt2xYWdhLKEs6b2bKPCSO2lSzFd1g0RYF1O9dw00w2vUg5ju/w
waFDMH9z6FCVgnM4ZvGhKT6wcsR3yJ5kcDfnM5KudM/OzszMhHRmdlUIvoNHJozBQQ+fadzD
+Ts8AIhneng8jcd3GHQdZCjCeOK4KY1ZV+gh0uM7uBo5MgsjvNPfGC4pcXWNUuM7JJeUJAP+
lRjheSklCJRPzqDwHTYWbAQKrHBeT4oKNhYwwEeICt8hpSAFKIi7yj1raEthsgXQ4kf4pwNt
cRg4clgZKeOe7Tpy+AgA8cOH22Q8HPwZ5m3mHpVtNmb9b8LMoXk43GSIw/gedtfRmL2ZdDPp
wEw+DklJyqSkoHyMqHp8y5YkYAs08BHxcVgAKCdw3labA5UHlMoFStTByo2PQwfgg/WWlnW/
o+M/HR1ffgkdinz5OMwHrAJwomWz5rNUNfJxaHvtz23OrTjRza/seK1tB4y2HTti5/Bx8AFK
63CiilQflv7zfBy8vLxWDmtwosGrvVh2C/k4rFxpJVBgRYdXrWQZaOHjYGVlNYD3ZhDtbMUS
R/FxcHZ+He/atp3mbCKK5uPg7p4ajJVsfexuxNnd+dY4L4egoD14+1gTF8SyIoCXQ1FRINZV
QQtPFbEIHPk5zF6Ltw9lA6teR6No1apVG+bwcriVgPnOvmnJbMStHCg9z3k55JR34iVP9OR8
lJOD1kc5ovO8HPZIMZNrE6qqVq9eXYU4Hc/LoVuBmQzuX8wSd5aXwzzcO5zjzF+vQOMPMKNa
eDmsw/2PXvpEKrAClVRpBC+HStx9yIi98+TJnj1Pnjy5c8daxcsB93SgAgSxsbECKILYiXya
l0MvZlAdPTExIYApEEz0h/JzwA3W+c5jSZjOz0GHGawZ7wZmvtn9Znf3Vkcy++BU+PQVNNDc
GUzIQdrf3/92P+LtgXtkHDqjNiDeQqU0hoyD3i2BpdSSjENf+SyW0iYyDnnhPT09f+rZDaPH
r4uMg1j0O5YBNRmHu0tMiGhCx8JPtO8XO3fuE+3bue+0LRmHSz8dEE0RGEHGYeTCfT9gwM/v
vp+0joxDmVtpaWl4eCmq1jVkHOrXnQo/dQrW6dOnovVkHD6ULmMpdiK0D9Kl5eVLl5ZDLQ8g
tA+WhXEsAYTOh3jphaNHj6J19GhAHhmHrHWB7wUGvgcrMDCa0L26JuoZ4MYsXwMZh7wolsfW
hJ4Xf5SuWTeFr46Mg378Val0zauINaFiMg6XQgulhcYpTSf0vBgdnsbSSOj+cPYd63HrcZjW
1tZXCN2r9T/w9fX9uS9THDvJOLRcyWdpJPS8EF+Jji6Ggcp0QueDyjG0uDgUURxK6nlBVwaY
yGsnsw+RGd9kTEHoWNiGDE8yfbgxi4wDdT59+fJ0xPL0yh8TcohvdGx8x7ERUVlGxsEgvAI4
MiW4ntB1Iaw0Qej/D3T12mAWS4qMw1d2kW9890Yk8KvvLDVkHGpCIiPXwkBzr5iMQ+sP5ygU
MGHNSSTkQMUo7tndUyjsYIacI+NAx9idOGEHC7AjdE6q9u56vgsIgfr8KhkHw0gMy6ZmQg5O
m1gSOwkdi5bNLImjhM7JuoeJiQ/PJzK8rCPj0PDL+vr6h/X1/4L6MkXGQS3ce83ymqUlrGtZ
GjIO57LKysriyxiEYjIOqtF4liZC+0Drm5pGmiYRt5NxuF0tFI4IgZERYauOjENENSKLqS2E
jgU1OjqaBQOhJ+RgeP/SV2fP9vZe6u3t7VIRcrju9L5Tp1OnHmofRcZBdlXf1fVvZupbNGQc
dOKa5ua+vr6ampq+v4rJONCa6y3Nzc11t5v/1nxbrCPjQDXU1dW9mwfr3TqxjIyDQZ3X2gDk
NTT8I8JAxqFdfKO19UbrDfUXX7SqCe0DrYlQR6gZItSE9oGmxCYoQg4qjfiB5i+aBw80Gg0p
B/rcjBnUuXPUjK81d78m5NBuS5lQEdoHgy2Cogy25Bx03xpktoZvDQhSDrRMZpDJZCqVyqAi
5vBp+6cqnY7Wtev+3k7K4X+B2cHsYHYwO5gdzA5mB7OD2cHsYHYwO5gdzA5mB7PD/4PD9wIM
AIu3LLBAYeeAAAAAAElFTkSuQmCC
__config/bluepole.yaml__
header_left: theme/bluepole/images/header_left.png
header_top: theme/bluepole/images/header_top.png
header_text: Bluepole
