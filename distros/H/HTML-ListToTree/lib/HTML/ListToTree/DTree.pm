=pod

=begin classdoc

Implements the HTML::ListToTree widget using the dtree software.
Contains the dtree software, stylesheet, and icons.<p>

The dtree widget software and components included in this
package are distributed in accordance
with the following license and copyright:
<pre>
	/*--------------------------------------------------|
	| dTree 2.05| www.destroydrop.com/javascripts/tree/ |
	|---------------------------------------------------|
	| Copyright (c) 2002-2003 Geir Landrö               |
	|                                                   |
	| This script can be used freely as long as all     |
	| copyright messages are intact.                    |
	|                                                   |
	| Updated: 17.04.2003                               |
	|--------------------------------------------------*/
</pre>

@author Dean Arnold
@since 2007-Jun-10
@self $self

=end classdoc

=cut

package HTML::ListToTree::DTree;

use MIME::Base64;

use strict;
use warnings;

our $VERSION = '1.01';

our %dtree_images = (
	'base.gif' =>
'R0lGODlhFQASAPcAAAAAAIAAAACAAICAAAAAgIAAgACAgICAgMDAwP8AAAD/AP//AAAA//8A/wD/
/////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMwAAZgAAmQAAzAAA/wAzAAAzMwAzZgAzmQAzzAAz/wBm
AABmMwBmZgBmmQBmzABm/wCZAACZMwCZZgCZmQCZzACZ/wDMAADMMwDMZgDMmQDMzADM/wD/AAD/
MwD/ZgD/mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMzADMzMzMzZjMzmTMzzDMz/zNmADNmMzNm
ZjNmmTNmzDNm/zOZADOZMzOZZjOZmTOZzDOZ/zPMADPMMzPMZjPMmTPMzDPM/zP/ADP/MzP/ZjP/
mTP/zDP//2YAAGYAM2YAZmYAmWYAzGYA/2YzAGYzM2YzZmYzmWYzzGYz/2ZmAGZmM2ZmZmZmmWZm
zGZm/2aZAGaZM2aZZmaZmWaZzGaZ/2bMAGbMM2bMZmbMmWbMzGbM/2b/AGb/M2b/Zmb/mWb/zGb/
/5kAAJkAM5kAZpkAmZkAzJkA/5kzAJkzM5kzZpkzmZkzzJkz/5lmAJlmM5lmZplmmZlmzJlm/5mZ
AJmZM5mZZpmZmZmZzJmZ/5nMAJnMM5nMZpnMmZnMzJnM/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwA
M8wAZswAmcwAzMwA/8wzAMwzM8wzZswzmcwzzMwz/8xmAMxmM8xmZsxmmcxmzMxm/8yZAMyZM8yZ
ZsyZmcyZzMyZ/8zMAMzMM8zMZszMmczMzMzM/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8A
mf8AzP8A//8zAP8zM/8zZv8zmf8zzP8z//9mAP9mM/9mZv9mmf9mzP9m//+ZAP+ZM/+ZZv+Zmf+Z
zP+Z///MAP/MM//MZv/Mmf/MzP/M////AP//M///Zv//mf//zP///ywAAAAAFQASAAAInAAfCBxI
sKDBgqMOKiSICpaohQoBzHkwrRDBP6hQLQRgSaDGB6gePvizUY5AaqJIClwwCgCAgwAuDQQw7cEC
jw8uvSwocaazgQtIztlJMOZMWDYFWhxqkONMakAJPWDK06RAmkkfJLREdKaliQ8A/BQoqqacrjPn
yMQ6itBYrhFNAijkp+ZAqjDnyLn0da/asxBdCh7sEqLhw4cDAgA7
',
	'closedbook.gif' =>
'R0lGODlhFgAUAPcAAAAAAIAAAACAAICAAAAAgIAAgACAgICAgMDAwP8AAAD/AP//AAAA//8A/wD/
/////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMwAAZgAAmQAAzAAA/wAzAAAzMwAzZgAzmQAzzAAz/wBm
AABmMwBmZgBmmQBmzABm/wCZAACZMwCZZgCZmQCZzACZ/wDMAADMMwDMZgDMmQDMzADM/wD/AAD/
MwD/ZgD/mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMzADMzMzMzZjMzmTMzzDMz/zNmADNmMzNm
ZjNmmTNmzDNm/zOZADOZMzOZZjOZmTOZzDOZ/zPMADPMMzPMZjPMmTPMzDPM/zP/ADP/MzP/ZjP/
mTP/zDP//2YAAGYAM2YAZmYAmWYAzGYA/2YzAGYzM2YzZmYzmWYzzGYz/2ZmAGZmM2ZmZmZmmWZm
zGZm/2aZAGaZM2aZZmaZmWaZzGaZ/2bMAGbMM2bMZmbMmWbMzGbM/2b/AGb/M2b/Zmb/mWb/zGb/
/5kAAJkAM5kAZpkAmZkAzJkA/5kzAJkzM5kzZpkzmZkzzJkz/5lmAJlmM5lmZplmmZlmzJlm/5mZ
AJmZM5mZZpmZmZmZzJmZ/5nMAJnMM5nMZpnMmZnMzJnM/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwA
M8wAZswAmcwAzMwA/8wzAMwzM8wzZswzmcwzzMwz/8xmAMxmM8xmZsxmmcxmzMxm/8yZAMyZM8yZ
ZsyZmcyZzMyZ/8zMAMzMM8zMZszMmczMzMzM/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8A
mf8AzP8A//8zAP8zM/8zZv8zmf8zzP8z//9mAP9mM/9mZv9mmf9mzP9m//+ZAP+ZM/+ZZv+Zmf+Z
zP+Z///MAP/MM//MZv/Mmf/MzP/M////AP//M///Zv//mf//zP///yH5BAEAABAALAAAAAAWABQA
AAiVAP8JHEiwoMGDCBMiRIFC4UIUl+Q0dDiQoaWIlixNVMhwjpw5luaI1MgR1qWLITOCnLPRIApL
1D6CvLSSZkuCKOZcmgbyoxyMIG8KzBmS2smTM+VoFJrzpxxqHn+KZIhqYcpLRiMyJPTPT8KcEedM
2+rsnzOGX39q9Fp2rNCCTRvC+oeWIt1LKFDVtTt0L9+/gANTDAgAOw==
',
	'empty.gif' =>
'R0lGODlhEgASAJEAAAAAAP///4CAgP///yH5BAEAAAMALAAAAAASABIAAAIPnI+py+0Po5y02ouz
3pwXADs=
',
	'folder.gif' =>
'R0lGODlhEgASANUAAPv7++/v79u3UsyZNOTk5MHBwaNxC8KPKre3t55sBrqHIpxqBMmWMb2KJbOB
G5lnAdu3cbWCHaBuCMuYM///urB+GMWSLad1D8eUL6ampqVzDbeEH6t5E8iVMMCNKMbGxq58Fppo
Aqh2EKx6FP/Ub//4k+vr6///nP/bdf/kf//viba2tv//////mQAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAC4ALAAAAAASABIAAAaRQJdw
SCwaj8ik0jUYTBidAEA5YFkplANhehxABGAwpKHYRByVwHBibbvbo8+Q0TrZ7/jWBTHEtP6AgX8G
K0MWLSWJiostEoVCBy0qk5SVLQmPLh4tKZ2eny0LmQ0tKKanqC0hmQotJK+wsS0PfEIBZxUgHCIa
BhIJCw8ZBUMABAUrycrLBQREAAEm0tPUUktKQQA7
',
	'folderopen.gif' =>
'R0lGODlhEgASANUAAO/v76VzDfv7+8yZNMHBweTk5JpoAqBuCMuYM8mWMZ5sBpxqBPr7/Le3t///
pcaaGvDker2KJc+iJqd1D7B+GOKzQ8KPKqJwCrOBG7WCHbeEH9e4QNq/bP/rhJlnAffwiaampuLB
UMmgIf3VcKRyDP/XhLqHIqNxC8iVMMbGxqx6FP/kf//bdf/vievr67a2tv/4k8aaGf//nP//mf//
/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAADUALAAAAAASABIAAAaVwJpw
SCwaj8ikUjgYIBIogEA5oFkZDEtheqzKvl9axKTJYCiAIYIGblutqtQwQYPZ73jZpCGM+f+AfiEd
Jy99M21tMxwxJQeGNTGIeHcyHzEjCpAAki2en54OIhULkAKSMiuqqysOGxIGkDWcMyy2t7YQDx58
QqcBwMAkFwcKCwYgBEQFBC/Oz9AEBUUALtbX2FJLSUEAOw==
',
	'globe.gif' =>
'R0lGODlhEwASAPcAAPr7/AFyAQFCpwGD6jy3/wE9on7N0AE+pAFjyMLI0AE2mwF94wGP9QFpzgU3
nISSopWgrmJsfTNLfgFHqAFuBilNiTp4sLnGzwWb/0xYb/P09mRygGl0hRlnMgR12V2Pr6e4xF9p
eS2Cyh5FpBdSfgF84YmisdPa30hjvw+foQFYvlWj4HWIlkWb5gk5n/b4+gw+kgFMscXb6ylmieDj
5ju2pylTsniElgqd/u/x8wGW/O7v8SVMsUq+JSSJXQFiwfv+/AFqvB9ntobZeKbc/9vt+B+YmW2r
vKruzQGPkm3PPrjmxQFIklrFLVbD4QGMYaXkoIPD13LC+nGw5AGFQHG66gF2eBaJxket9sLf84HI
+wF7axBdbg2c0CR+1QFsEIfJ7yqoUIbH41tldgF+KzVTjn3QfitZgTJZkaDR8gKDsXeWrE+zogE3
nCeKzQFtJ0tknjdnbQGB6EJgxQFqAcLJ0WC//yKm/wE+o7vI0ARozEOz/4/g/4KToyaX4/D09pCp
uNHV24HA6gw7oAF/AXWKnEVSb5TI6VzDTrPprxBQts7e6FNdcBA9oySd9RRjPAhnD2NvgIydrF+6
wdLo9v7//2K+twKSdDmKyeD56wGCyHq12VnF+ZXXsARdTjZWthShoo7gtilDlAFw1RCXvF+z6p/R
8kqZzAF0Oj5jjFuJqgFoAkRgxtzr9YmcrJKsugFlylfBgxJGhjJIeFnFuhmi/+bo65ipt8Hn+UhV
co7B5SZowAGBKoaZqAGGAVHBUwF8Qq7Y819qe4DEoVyYwrnb8QGN9GCy6QFTuHB9jgGY/gFRtuTu
9ZOhr150iwFbwTFiwFus4h9mYt/y+kWZ35vM7hGfccz43Xy/6m3BuS1GiYveqDRfwnbUV4rdu///
/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAN8ALAAAAAATABIA
AAj/AL8JHEiwVTVspar8ITiwiJhswyaBibJJUq9Trxh+S2OAVihvSzqRcoTpmy5ADIPFqrHtGpBE
TbrIuXJEBgiGbHoogTItExJOoAbw8rHmAkFTC8KYwTWkGx8COp4AozAjD8Epo4wQQfTLCQEcxqig
oiONBUFqerRYspYCgzIGmgi98cRlA8EVLaR4UJPk0oASVgKs6kAiBMFDdrzAarDFF5kgCJA9ilNB
GMFjWAQse/YjwBcVMfCcgTMr2UBKe0QIaHNgAiQmBRS4+CSKEYSBWe44E6JoEAxZDhrxmDPCEAca
A4vVinTCwi5uKFhBs6EtQ4QEOQYy8+NGUDRiqdCUJJGQa8yNQDsADHyxSNUHE4Vc3erzoFkdWxoA
VNLIv7///98EBAA7
',
	'join.gif' =>
'R0lGODlhEgASAIABAICAgP///yH5BAEAAAEALAAAAAASABIAAAIcjB+Ay+2rnpwo0uss3kf5BGoc
NJZiSZ2opK5BAQA7
',
	'joinbottom.gif' =>
'R0lGODlhEgASAIABAICAgP///yH5BAEAAAEALAAAAAASABIAAAIZjB+Ay+2rnpwo0uss3kf5BGrc
SJbmiaZGAQA7
',
	'line.gif' =>
'R0lGODlhEgASAIABAICAgP///yH5BAEAAAEALAAAAAASABIAAAIZjB+Ay+2rnpwo0uss3kfz7X1X
KE5k+ZxoAQA7
',
	'minus.gif' =>
'R0lGODlhEgASAJEDAIKCgoCAgAAAAP///yH5BAEAAAMALAAAAAASABIAAAInnD+By+2rnpyhWvsi
zE0zf4CIIpRlgiqaiDosa7zZdU22A9y6u98FADs=
',
	'minusbottom.gif' =>
'R0lGODlhEgASAJECAICAgAAAAP///wAAACH5BAEAAAIALAAAAAASABIAAAImlC+Ay+2rnpygWvsi
zE0zf4CIEpRlgiqaiDosa7zZdU32jed6XgAAOw==
',
	'nolines_minus.gif' =>
'R0lGODlhEgASAPcDAIKCgoCAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAMALAAAAAASABIA
AAg6AAcIHEiwoMGDCBMqXJgwgMOHDxseDCDRIEWEFwtmtDjgn0ePAzZqnFhxJEaSGCFCZMiypcuX
MBMGBAA7
',
	'nolines_plus.gif' =>
'R0lGODlhEgASAPcDAIKCgoCAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAMALAAAAAASABIA
AAhDAAcIHEiwoMGDCBMqXJgwgMOHDxseDCBR4L+BFBFmHHBR4EaDFP+JFDngY8GNHUtW5IhxJUGT
LyFCZEizps2bOBMGBAA7
',
	'openbook.gif' =>
'R0lGODlhFQASAPcAAAAAAIAAAACAAICAAAAAgIAAgACAgICAgMDAwP8AAAD/AP//AAAA//8A/wD/
/////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMwAAZgAAmQAAzAAA/wAzAAAzMwAzZgAzmQAzzAAz/wBm
AABmMwBmZgBmmQBmzABm/wCZAACZMwCZZgCZmQCZzACZ/wDMAADMMwDMZgDMmQDMzADM/wD/AAD/
MwD/ZgD/mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMzADMzMzMzZjMzmTMzzDMz/zNmADNmMzNm
ZjNmmTNmzDNm/zOZADOZMzOZZjOZmTOZzDOZ/zPMADPMMzPMZjPMmTPMzDPM/zP/ADP/MzP/ZjP/
mTP/zDP//2YAAGYAM2YAZmYAmWYAzGYA/2YzAGYzM2YzZmYzmWYzzGYz/2ZmAGZmM2ZmZmZmmWZm
zGZm/2aZAGaZM2aZZmaZmWaZzGaZ/2bMAGbMM2bMZmbMmWbMzGbM/2b/AGb/M2b/Zmb/mWb/zGb/
/5kAAJkAM5kAZpkAmZkAzJkA/5kzAJkzM5kzZpkzmZkzzJkz/5lmAJlmM5lmZplmmZlmzJlm/5mZ
AJmZM5mZZpmZmZmZzJmZ/5nMAJnMM5nMZpnMmZnMzJnM/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwA
M8wAZswAmcwAzMwA/8wzAMwzM8wzZswzmcwzzMwz/8xmAMxmM8xmZsxmmcxmzMxm/8yZAMyZM8yZ
ZsyZmcyZzMyZ/8zMAMzMM8zMZszMmczMzMzM/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8A
mf8AzP8A//8zAP8zM/8zZv8zmf8zzP8z//9mAP9mM/9mZv9mmf9mzP9m//+ZAP+ZM/+ZZv+Zmf+Z
zP+Z///MAP/MM//MZv/Mmf/MzP/M////AP//M///Zv//mf//zP///ywAAAAAFQASAAAInAAfCBxI
sKDBgqMOKiSICpaohQoBzHkwrRDBP6hQLQRgSaDGB6gePvizUY5AaqJIClwwCgCAgwAuDQQw7cEC
jw8uvSwocaazgQtIztlJMOZMWDYFWhxqkONMakAJPWDK06RAmkkfJLREdKaliQ8A/BQoqqacrjPn
yMQ6itBYrhFNAijkp+ZAqjDnyLn0da/asxBdCh7sEqLhw4cDAgA7
',
	'page.gif' =>
'R0lGODlhEgASAOYAAPv7++/v7/j7/+32/8HBweTk5P39/djr/8Df//7///P5/8Ph//T09fn5+YGV
w2t0pc7n/15hkFWn7ZOq0nqDsMDA/9nh7YSbyoqo2eTx/5G46pK873N+sPX6//f395Cjy83m/7rd
/9jl9m13qGVqmoeh0n+OvI+z5Yyu387T//b6/2dtnvz9/32JtpS/8sbGxv7+/tvn92lwom96rHJ8
rnSAsoep3NHp/8nk/7e3t+vr67a2tun1/3V4o+Hw/9vt/////wAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5
BAEAAEEALAAAAAASABIAAAejgEGCg4SFhoeILjaLjDY1AQCHG0AGAA0eDBY1E5CGGjBAoQkCMTUS
HwGGJwaiAh0iNbEvhiihAgIDPDwpFRw5hhgsuLk8Pz8HNL+FJSoKuT4+xzczyoQXzjzQxjcgI9WD
DrraPzc4OA/fgibZ0eTmCzLpQS0Z7TflCwgr8hT2EOYIQpCQ16OgwYMRCBgqQGCHw4cOCRQwBCCA
josYL3ZCxNFQIAA7
',
	'plus.gif' =>
'R0lGODlhEgASAJECAICAgAAAAP///wAAACH5BAEAAAIALAAAAAASABIAAAIqlC+Ay+2rnpygWvsi
zCcczWieAW7BeSaqookfZ4yqU5LZdU06vfe8rysAADs=
',
	'plusbottom.gif' =>
'R0lGODlhEgASAJECAICAgAAAAP///wAAACH5BAEAAAIALAAAAAASABIAAAIplC+Ay+2rnpygWvsi
zCcczWieAW7BeSaqookfZ4yqU5LZdU36zvd+XwAAOw==
',
	'question.gif' =>
'R0lGODlhEgASAPelAOP0//7//9bs//n///j//9Ls/8Pn//r//6rB1t3f5crO2N7g5k1livT4+7PW
9dXt/+v4/+Xl5LHW9Ov6/+j1/6CyxrfCz9rd5Nzj6un1/Z6ouwcvj8HBzO7+/+3//+Ln7BUuXNHv
/6K4y+/9/wEBZvX08snn/19qhufs8fP7/87n/+/t7czr/5q1yk55q97v/3Cfztnu//z//+X6/ypI
dMHY7rPc/7fX9cbl/9/h52WHr2yKrd/0/9fw/4KTs9rm75Svzb2+ya690pu92mWJrcT3//H//+Dv
/Xym35S216Ouwsvt/3N/mMnZ5gEBcMnq/wEBXs/o/wEBetzw/zdYpTdZpsvP2ClGml2N3b3H0Nzu
/2Z2lF1ricrl/93w/97h6JqluktojM/u/+/z9g8pVff4+ebu9q+1xa6/zzdFaIiXr5Wyz0xslrTK
4uL//2uIp11rh8Xj/NXn+Oz2/9bf6bG2xAEBePP//1xwkK/K5Nbr/8fp/2OBtG53kai3ykVCYwEB
de/6/7O4xabI+fD//+by/x8+jDhZpM/q/6jK58nO19ny/7jV7ZO42NHr/9H4/2ZwimSV6VBxwMDX
7Nvf5hYwX5m20sfb6Ieqyk9Yjr/k/cPM2NDp/+/098Tl9yQ9jLfW+Mne8sjU30JklP///wAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAKUALAAAAAASABIA
AAjxAEsJHEiwoMEyGMaQWthg0xeDAlGUWKjoz5mFAegY/LBiIalMUK54JCWEoJkIpA6kSDmoAykK
gRaqGSiq04A5A5r4AKOEAAAtE2S0USAwSwYIhUb8METiUwAvemLMCMVEoIUjAF5MIYXAThUCDzgV
WDQJjkA0cngIEHAHCCAqRqJ0QeQoDxeBFS71KKDCwxonhwiZwPEkzo4+AimJqBFCjBs+UjZ4WmLg
xhAQVgb6acGIBShJkbAgMSAhCQ1IBTW8sZRI055HDhoRqXQCYo4tDMJgsqGDTJo6EAlyYFNkVJDg
BgXBcJEAucEFeC44n04wIAA7
',
);

=pod

=begin classdoc

Return the dtree Javascript.

@return	the dtree Javascript as a string.

=end classdoc

=cut

sub getJavascript {
	return <<'EOJS';
/*--------------------------------------------------|
| dTree 2.05| www.destroydrop.com/javascripts/tree/ |
|---------------------------------------------------|
| Copyright (c) 2002-2003 Geir Landrö               |
|                                                   |
| This script can be used freely as long as all     |
| copyright messages are intact.                    |
|                                                   |
| Updated: 17.04.2003                               |
|--------------------------------------------------*/
/*
 * Add'l update 2007-08-14 D. Arnold:
 *	Added imgPath parameter to constructor
 *	Added addWithIcons method
 *	Added closeIcon, openIcon default config icons
 */
// Node object
function Node(id, pid, name, url, title, target, icon, iconOpen, open) {
	this.id = id;
	this.pid = pid;
	this.name = name;
	this.url = url;
	this.title = title;
	this.target = target;
	this.icon = icon;
	this.iconOpen = iconOpen;
	this._io = open || false;
	this._is = false;
	this._ls = false;
	this._hc = false;
	this._ai = 0;
	this._p;
};

// Tree object
function dTree(objName, imgPath) {
	this.config = {
		target			: null,
		folderLinks		: true,
		useSelection	: true,
		useCookies		: true,
		useLines		: true,
		useIcons		: true,
		useStatusText	: false,
		closeSameLevel	: false,
		inOrder			: false,
		closeIcon		: imgPath + '/folder.gif',
		openIcon		: imgPath + '/folderopen.gif'
	}
	this.icon = {
		root		: imgPath + '/base.gif',
		folder		: imgPath + '/folder.gif',
		folderOpen	: imgPath + '/folderopen.gif',
		node		: imgPath + '/page.gif',
		empty		: imgPath + '/empty.gif',
		line		: imgPath + '/line.gif',
		join		: imgPath + '/join.gif',
		joinBottom	: imgPath + '/joinbottom.gif',
		plus		: imgPath + '/plus.gif',
		plusBottom	: imgPath + '/plusbottom.gif',
		minus		: imgPath + '/minus.gif',
		minusBottom	: imgPath + '/minusbottom.gif',
		nlPlus		: imgPath + '/nolines_plus.gif',
		nlMinus		: imgPath + '/nolines_minus.gif'
	};
	this.obj = objName;
	this.aNodes = [];
	this.aIndent = [];
	this.root = new Node(-1);
	this.selectedNode = null;
	this.selectedFound = false;
	this.completed = false;
};

// Adds a new node to the node array
dTree.prototype.add = function(id, pid, name, url, title, target, icon, iconOpen, open) {
	this.aNodes[this.aNodes.length] = new Node(id, pid, name, url, title, target, icon, iconOpen, open);
};

// Adds a new node to the node array using default open/close icons
dTree.prototype.addWithIcons = function(id, pid, name, url, title, target, open) {
	this.aNodes[this.aNodes.length] = new Node(id, pid, name, url, title, target, this.config.closeIcon, this.config.openIcon, open);
};

// Open/close all nodes
dTree.prototype.openAll = function() {
	this.oAll(true);
};
dTree.prototype.closeAll = function() {
	this.oAll(false);
};

// Outputs the tree to the page
dTree.prototype.toString = function() {
	var str = '<div class="dtree">\n';
	if (document.getElementById) {
		if (this.config.useCookies) this.selectedNode = this.getSelected();
		str += this.addNode(this.root);
	} else str += 'Browser not supported.';
	str += '</div>';
	if (!this.selectedFound) this.selectedNode = null;
	this.completed = true;
	return str;
};

// Creates the tree structure
dTree.prototype.addNode = function(pNode) {
	var str = '';
	var n=0;
	if (this.config.inOrder) n = pNode._ai;
	for (n; n<this.aNodes.length; n++) {
		if (this.aNodes[n].pid == pNode.id) {
			var cn = this.aNodes[n];
			cn._p = pNode;
			cn._ai = n;
			this.setCS(cn);
			if (!cn.target && this.config.target) cn.target = this.config.target;
			if (cn._hc && !cn._io && this.config.useCookies) cn._io = this.isOpen(cn.id);
			if (!this.config.folderLinks && cn._hc) cn.url = null;
			if (this.config.useSelection && cn.id == this.selectedNode && !this.selectedFound) {
					cn._is = true;
					this.selectedNode = n;
					this.selectedFound = true;
			}
			str += this.node(cn, n);
			if (cn._ls) break;
		}
	}
	return str;
};

// Creates the node icon, url and text
dTree.prototype.node = function(node, nodeId) {
	var str = '<div class="dTreeNode">' + this.indent(node, nodeId);
	if (this.config.useIcons) {
		if (!node.icon) node.icon = (this.root.id == node.pid) ? this.icon.root : ((node._hc) ? this.icon.folder : this.icon.node);
		if (!node.iconOpen) node.iconOpen = (node._hc) ? this.icon.folderOpen : this.icon.node;
		if (this.root.id == node.pid) {
			node.icon = this.icon.root;
			node.iconOpen = this.icon.root;
		}
		str += '<img id="i' + this.obj + nodeId + '" src="' + ((node._io) ? node.iconOpen : node.icon) + '" alt="" />';
	}
	if (node.url) {
		str += '<a id="s' + this.obj + nodeId + '" class="' + ((this.config.useSelection) ? ((node._is ? 'nodeSel' : 'node')) : 'node') + '" href="' + node.url + '"';
		if (node.title) str += ' title="' + node.title + '"';
		if (node.target) str += ' target="' + node.target + '"';
		if (this.config.useStatusText) str += ' onmouseover="window.status=\'' + node.name + '\';return true;" onmouseout="window.status=\'\';return true;" ';
		if (this.config.useSelection && ((node._hc && this.config.folderLinks) || !node._hc))
			str += ' onclick="javascript: ' + this.obj + '.s(' + nodeId + ');"';
		str += '>';
	}
	else if ((!this.config.folderLinks || !node.url) && node._hc && node.pid != this.root.id)
		str += '<a href="javascript: ' + this.obj + '.o(' + nodeId + ');" class="node">';
	str += node.name;
	if (node.url || ((!this.config.folderLinks || !node.url) && node._hc)) str += '</a>';
	str += '</div>';
	if (node._hc) {
		str += '<div id="d' + this.obj + nodeId + '" class="clip" style="display:' + ((this.root.id == node.pid || node._io) ? 'block' : 'none') + ';">';
		str += this.addNode(node);
		str += '</div>';
	}
	this.aIndent.pop();
	return str;
};

// Adds the empty and line icons
dTree.prototype.indent = function(node, nodeId) {
	var str = '';
	if (this.root.id != node.pid) {
		for (var n=0; n<this.aIndent.length; n++)
			str += '<img src="' + ( (this.aIndent[n] == 1 && this.config.useLines) ? this.icon.line : this.icon.empty ) + '" alt="" />';
		(node._ls) ? this.aIndent.push(0) : this.aIndent.push(1);
		if (node._hc) {
			str += '<a href="javascript: ' + this.obj + '.o(' + nodeId + ');"><img id="j' + this.obj + nodeId + '" src="';
			if (!this.config.useLines) str += (node._io) ? this.icon.nlMinus : this.icon.nlPlus;
			else str += ( (node._io) ? ((node._ls && this.config.useLines) ? this.icon.minusBottom : this.icon.minus) : ((node._ls && this.config.useLines) ? this.icon.plusBottom : this.icon.plus ) );
			str += '" alt="" /></a>';
		} else str += '<img src="' + ( (this.config.useLines) ? ((node._ls) ? this.icon.joinBottom : this.icon.join ) : this.icon.empty) + '" alt="" />';
	}
	return str;
};

// Checks if a node has any children and if it is the last sibling
dTree.prototype.setCS = function(node) {
	var lastId;
	for (var n=0; n<this.aNodes.length; n++) {
		if (this.aNodes[n].pid == node.id) node._hc = true;
		if (this.aNodes[n].pid == node.pid) lastId = this.aNodes[n].id;
	}
	if (lastId==node.id) node._ls = true;
};

// Returns the selected node
dTree.prototype.getSelected = function() {
	var sn = this.getCookie('cs' + this.obj);
	return (sn) ? sn : null;
};

// Highlights the selected node
dTree.prototype.s = function(id) {
	if (!this.config.useSelection) return;
	var cn = this.aNodes[id];
	if (cn._hc && !this.config.folderLinks) return;
	if (this.selectedNode != id) {
		if (this.selectedNode || this.selectedNode==0) {
			eOld = document.getElementById("s" + this.obj + this.selectedNode);
			eOld.className = "node";
		}
		eNew = document.getElementById("s" + this.obj + id);
		eNew.className = "nodeSel";
		this.selectedNode = id;
		if (this.config.useCookies) this.setCookie('cs' + this.obj, cn.id);
	}
};

// Toggle Open or close
dTree.prototype.o = function(id) {
	var cn = this.aNodes[id];
	this.nodeStatus(!cn._io, id, cn._ls);
	cn._io = !cn._io;
	if (this.config.closeSameLevel) this.closeLevel(cn);
	if (this.config.useCookies) this.updateCookie();
};

// Open or close all nodes
dTree.prototype.oAll = function(status) {
	for (var n=0; n<this.aNodes.length; n++) {
		if (this.aNodes[n]._hc && this.aNodes[n].pid != this.root.id) {
			this.nodeStatus(status, n, this.aNodes[n]._ls)
			this.aNodes[n]._io = status;
		}
	}
	if (this.config.useCookies) this.updateCookie();
};

// Opens the tree to a specific node
dTree.prototype.openTo = function(nId, bSelect, bFirst) {
	if (!bFirst) {
		for (var n=0; n<this.aNodes.length; n++) {
			if (this.aNodes[n].id == nId) {
				nId=n;
				break;
			}
		}
	}
	var cn=this.aNodes[nId];
	if (cn.pid==this.root.id || !cn._p) return;
	cn._io = true;
	cn._is = bSelect;
	if (this.completed && cn._hc) this.nodeStatus(true, cn._ai, cn._ls);
	if (this.completed && bSelect) this.s(cn._ai);
	else if (bSelect) this._sn=cn._ai;
	this.openTo(cn._p._ai, false, true);
};

// Closes all nodes on the same level as certain node
dTree.prototype.closeLevel = function(node) {
	for (var n=0; n<this.aNodes.length; n++) {
		if (this.aNodes[n].pid == node.pid && this.aNodes[n].id != node.id && this.aNodes[n]._hc) {
			this.nodeStatus(false, n, this.aNodes[n]._ls);
			this.aNodes[n]._io = false;
			this.closeAllChildren(this.aNodes[n]);
		}
	}
}

// Closes all children of a node
dTree.prototype.closeAllChildren = function(node) {
	for (var n=0; n<this.aNodes.length; n++) {
		if (this.aNodes[n].pid == node.id && this.aNodes[n]._hc) {
			if (this.aNodes[n]._io) this.nodeStatus(false, n, this.aNodes[n]._ls);
			this.aNodes[n]._io = false;
			this.closeAllChildren(this.aNodes[n]);
		}
	}
}

// Change the status of a node(open or closed)
dTree.prototype.nodeStatus = function(status, id, bottom) {
	eDiv	= document.getElementById('d' + this.obj + id);
	eJoin	= document.getElementById('j' + this.obj + id);
	if (this.config.useIcons) {
		eIcon	= document.getElementById('i' + this.obj + id);
		eIcon.src = (status) ? this.aNodes[id].iconOpen : this.aNodes[id].icon;
	}
	eJoin.src = (this.config.useLines)?
	((status)?((bottom)?this.icon.minusBottom:this.icon.minus):((bottom)?this.icon.plusBottom:this.icon.plus)):
	((status)?this.icon.nlMinus:this.icon.nlPlus);
	eDiv.style.display = (status) ? 'block': 'none';
};


// [Cookie] Clears a cookie
dTree.prototype.clearCookie = function() {
	var now = new Date();
	var yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
	this.setCookie('co'+this.obj, 'cookieValue', yesterday);
	this.setCookie('cs'+this.obj, 'cookieValue', yesterday);
};

// [Cookie] Sets value in a cookie
dTree.prototype.setCookie = function(cookieName, cookieValue, expires, path, domain, secure) {
	document.cookie =
		escape(cookieName) + '=' + escape(cookieValue)
		+ (expires ? '; expires=' + expires.toGMTString() : '')
		+ (path ? '; path=' + path : '')
		+ (domain ? '; domain=' + domain : '')
		+ (secure ? '; secure' : '');
};

// [Cookie] Gets a value from a cookie
dTree.prototype.getCookie = function(cookieName) {
	var cookieValue = '';
	var posName = document.cookie.indexOf(escape(cookieName) + '=');
	if (posName != -1) {
		var posValue = posName + (escape(cookieName) + '=').length;
		var endPos = document.cookie.indexOf(';', posValue);
		if (endPos != -1) cookieValue = unescape(document.cookie.substring(posValue, endPos));
		else cookieValue = unescape(document.cookie.substring(posValue));
	}
	return (cookieValue);
};

// [Cookie] Returns ids of open nodes as a string
dTree.prototype.updateCookie = function() {
	var str = '';
	for (var n=0; n<this.aNodes.length; n++) {
		if (this.aNodes[n]._io && this.aNodes[n].pid != this.root.id) {
			if (str) str += '.';
			str += this.aNodes[n].id;
		}
	}
	this.setCookie('co' + this.obj, str);
};

// [Cookie] Checks if a node id is in a cookie
dTree.prototype.isOpen = function(id) {
	var aOpen = this.getCookie('co' + this.obj).split('.');
	for (var n=0; n<aOpen.length; n++)
		if (aOpen[n] == id) return true;
	return false;
};

// If Push and pop is not implemented by the browser
if (!Array.prototype.push) {
	Array.prototype.push = function array_push() {
		for(var i=0;i<arguments.length;i++)
			this[this.length]=arguments[i];
		return this.length;
	}
};
if (!Array.prototype.pop) {
	Array.prototype.pop = function array_pop() {
		lastElement = this[this.length-1];
		this.length = Math.max(this.length-1,0);
		return lastElement;
	}
};
EOJS
}

=pod

=begin classdoc

Return the dtree CSS stylesheet.

@return	the dtree CSS stylesheet as a string.

=end classdoc

=cut

sub getCSS {
	return <<'EOCSS';
/*--------------------------------------------------|
| dTree 2.05 | www.destroydrop.com/javascript/tree/ |
|---------------------------------------------------|
| Copyright (c) 2002-2003 Geir Landrö               |
|--------------------------------------------------*/

.dtree {
	font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
	font-size: 11px;
	color: #666;
	white-space: nowrap;
}
.dtree img {
	border: 0px;
	vertical-align: middle;
}
.dtree a {
	color: #333;
	text-decoration: none;
}
.dtree a.node, .dtree a.nodeSel {
	white-space: nowrap;
	padding: 1px 2px 1px 2px;
}
.dtree a.node:hover, .dtree a.nodeSel:hover {
	color: #333;
	text-decoration: underline;
}
.dtree a.nodeSel {
	background-color: #c0d2ec;
}
.dtree .clip {
	overflow: hidden;
}

.dtree a.rootnode {
	white-space: nowrap;
	padding: 1px 2px 1px 2px;
	color: #000;
	font-weight: bold;
}
EOCSS
}

=pod

=begin classdoc

Return the specified dtree icon image data.

@return	the dtree icon image data.

=end classdoc

=cut

sub getIcon {
	my ($self, $image) = @_;
	$image ||= $self;	# if called as expoerted method
	return decode_base64($dtree_images{$image});
}

=pod

=begin classdoc

Return the dtree icon images.

@returnlist	the dtree icon images as a hash mapping icon file names to the image data

=end classdoc

=cut

sub getIcons {
	my %icons = ();
	my ($k, $v);
	$icons{$k} = decode_base64($v)
		while (($k, $v) = each %dtree_images);
	return %icons;
}


=pod

=begin classdoc

@constructor

Create a new dtree widget object.

@return the created widget object.

=end classdoc

=cut

sub new { return bless {}, $_[0]; }

=pod

=begin classdoc

Start the widget rendering.

@param RootText text for root node of tree
@optional CSSPath full path to the stylesheet; default './css/dtree.css'
@optional JSPath full path to the Javascript document; default './js/dtree.js'
@optional UseIcons if true, widget includes open/close icons; default false
@optional RootIcon icon used for root node of tree; default none
@optional RootLink URL of root node of tree; default none
@optional Target name of target frem for tree links; default 'mainframe'
@optional CloseIcon icon used for closed nodes; default <IconPath>/folder.gif
@optional OpenIcon icon used for open node; default <IconPath>/folderopen.gif
@optional IconPath path to the icon image directory

@return this widget object

=end classdoc

=cut

sub start {
	my $self = shift;
	my %args = @_;
	$args{IconPath} ||= './img';
	$args{CSSPath} ||= './css/dtree.css';
	$args{JSPath} ||= './js/dtree.js';
	$args{Target} = $args{Target} ? "'$args{Target}'" : "'mainframe'";
	$args{RootLink} = $args{RootLink} ? "'$args{RootLink}'" : 'null';
	$args{RootIcon} = $args{RootIcon} ? "'$args{RootIcon}'" : 'null';
	$args{OpenIcon} = $args{OpenIcon} ? "'$args{OpenIcon}'" : "'$args{IconPath}/folderopen.gif'";
	$args{CloseIcon} = $args{CloseIcon} ? "'$args{CloseIcon}'" : "'$args{IconPath}/folder.gif'";
	$args{RootText} ||= '';
	$self->{_jstree} = "
<html>
<head>
	<link rel='StyleSheet' href='$args{CSSPath}' type='text/css' />
	<script type='text/javascript' src='$args{JSPath}'></script>

</head>
<body>
<div class='dtree'>

	<script type='text/javascript'>
		<!--

		d = new dTree('d', '$args{IconPath}');

		d.config.useLines = true;
		d.config.useIcons = $args{UseIcons};
		d.config.inOrder = false;
		d.icon.root = $args{RootIcon};
		d.config.closeIcon = $args{CloseIcon}; 
		d.config.openIcon = $args{OpenIcon};
		d.config.target = $args{Target};

		d.add(0,-1,'$args{RootText}', $args{RootLink});
";
	$self->{_target} = $args{Target};
	return $self;
}

=pod

=begin classdoc

Add a leaf node to the widget (without icons).

@param $node integer index for the node
@param $parent integer index of node parent
@param $text text label for the node
@optional $link URL for the node

@return this widget object

=end classdoc

=cut

sub addLeaf {
	my $self = shift;
	my ($node, $parent, $text, $link) = @_;
	$link = $link ? "'$link'" : 'null';
	$self->{_jstree} .= "\td.add($node, $parent, '$text', $link);\n";
	return $self;
}

=pod

=begin classdoc

Add an intermediate node with open/close icons to the widget.

@param $node integer index for the node
@param $parent integer index of node parent
@param $text text label for the node
@optional $link URL for the node

@return this widget object

=end classdoc

=cut

sub add {
	my $self = shift;
	my ($node, $parent, $text, $link) = @_;
	$link = $link ? "'$link'" : 'null';
	$self->{_jstree} .= "\td.addWithIcons($node, $parent, '$text', $link);\n";
	return $self;
}

=pod

=begin classdoc

Return the currently defined widget. The Javascript and HTML for the widget is closed
out, and the widget returned as an HTML document containing Javascript.

@optional $adds any additional HTML to be appended to the tree.

@return the widget HTML document

=end classdoc

=cut

sub getWidget {
	my $self = shift;
	my $adds = shift || '';
	return $self->{_jstree} . "
		document.write(d);

		//-->
	</script>

</div>
<p>
$adds
</body>
</html>
";
}

1;