#! /bin/bash
#
# from the source of http://edit.my.yahoo.com/config/edit_pfview/?.vk=v1
#     <option value="s">Symbol
#     <option value="n">Name
#     <option value="l">Last Trade (With Time)
#     <option value="l1">Last Trade (Price Only)
#                    t1  time of last trade
#                    d1  date of last trade
#     <option value="c">Change &amp; Percent
#     <option value="c1">Change
#                    p2  percentage change
#     <option value="v">Volume
#     <option value="a2">Average Daily Volume
#     <option value="i">More Info
#     <option value="b">Bid
#     <option value="a">Ask
#     <option value="p">Previous Close
#     <option value="o">Open
#     <option value="m">Day's Range
#                    g  Day's low
#                    h  Day's high
#     <option value="w">52-Week Range
#                    j  52-week low
#                    k  52-week high
#     <option value="e">Earnings/Share
#     <option value="r">P/E Ratio
#     <option value="r1">Dividend Pay Date
#     <option value="q">Ex-Dividend Date
#     <option value="d">Dividend/Share
#     <option value="y">Dividend Yield
#     <option value="j1">Market Capitalization
#     <option value="s1">Shares Owned
#     <option value="p1">Price Paid
#     <option value="c3">Commission
#     <option value="v1">Holdings Value
#     <option value="w1">Day's Value Change
#     <option value="g1">Holdings Gain &amp; Percent
#     <option value="g4">Holdings Gain
#     <option value="d2">Trade Date
#     <option value="g3">Annualized Gain
#     <option value="l2">High Limit
#     <option value="l3">Low Limit
#     <option value="n4">Notes


#SERVERURL=http://uk.finance.yahoo.com
#STOCKS=UKX.L+BT.A.L+BII.L
#FORMAT="snl1t1d1c1p2vpoghw"

#SERVERURL=http://finance.yahoo.com
#STOCKS=IBM+MSFT+XIU.TO

#SERVERURL=http://au.finance.yahoo.com/d/quotes.csv
#STOCKS=TLSCB.AX+CDL.NZ+JARD.SI
#+CTI.AX+AFI.AX+CDL.NZ
#FORMAT=snl1d1t1c1poghjkdyv=
#FORMAT=snl1d1t1c1p2pomwverdyba

#FORMAT=snl1d1t1c1p2ghvva2bapomwerr1dyj1x
#FORMAT=snl1t1d1c1p2poghv 

SERVERURL=http://sg.finance.yahoo.com
STOCKS=OCBC.SI+JARD.SI+0307.HK
FORMAT=snl1d1t1c1p2pomwverdybaxq

#SERVERURL=http://finanzen.de.yahoo.com
#STOCKS=185775.F
##FORMAT=snl1d1t1c1p2poghwerdy
#FORMAT=snl1d1t1c1p2poghwv
#a2werr1dyj1

cd /tmp
rm -vf quote*csv*
wget -q "$SERVERURL/d/quotes.csv?f=$FORMAT&s=$STOCKS" 
cat quote*csv*

