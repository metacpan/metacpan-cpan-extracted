#!/bin/sh -v

# ISO-8859-1
wget -N http://www.kawa.net/xp/index-e.html

# Shift_JIS
wget -N http://www.kawa.net/xp/index-j.html

# UTF-8
wget -O flickr.html http://www.flickr.com/photos/u-suke/

# EUC-JP
wget -O yahoo.html http://blog.yahoo.co.jp/kawa_kawa_kawa_kawa/
