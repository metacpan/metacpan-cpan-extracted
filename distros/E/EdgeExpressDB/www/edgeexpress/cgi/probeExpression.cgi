#!/usr/bin/python
import os,sys
import cgitb; cgitb.enable()
import cgi
os.environ[ 'HOME' ] = "/tmp"
IMG_DIR = "/data/www/html/nw2006/edgeexpress/tmpimages/"
EXP_URL = "../cgi/edgeexpress.fcgi?mode=express_xml&name=" 

def drawImage():
	data = open( imageName , 'rb').read()
	print "Content-type: image/png\n"
	print data
	
def colorbars(lib,color):
	cb = []
	for i in lib:
		cb.append(bars[i])	
	pylab.setp(cb,facecolor=color)
	
	
form = cgi.FieldStorage() # instantiate only once!
    
if form.has_key('probeid'):
   probeid = form.getfirst("probeid", ""); 
else:
   print "Content-type: text/html\n"
   print 'The URL must provide a probeid'
   sys.exit()

#if form.has_key('dataset'):
#        datasets = form.getfirst("dataset", "").split(",");
#        datasets.sort()
#else:
#        datasets = ['1','3','6']

imageName = IMG_DIR+"px"+probeid+".png"
if os.path.isfile(imageName):
   drawImage()
   sys.exit()	


 
import xml.dom.minidom
import urllib
dom = xml.dom.minidom.parse(urllib.urlopen(EXP_URL+probeid))
features = dom.getElementsByTagName('feature')

if len(features)<1:
	print "Content-type: text/html\n"
	print 'Probeid ',probeid,' was not found'
	sys.exit()

values = []
labels = []
RIKEN1 = []
RIKEN3 = []
RIKEN6 = []
ILMN_siRNA_V2series1 = []
ILMN_siRNA_V2series234_181207 = [] 
ILMN_miRNA_V2_181207 = []
NOT_DETECTED = []

feature = features[0]


feature_id = feature.getAttribute('id')
category = feature.getAttribute('category')

nodes = dom.getElementsByTagName('expression')
for i in range(len(nodes)):
	#if not nodes[i].getAttribute('series_name')[-1:] in datasets:
	#	continue	
	#else:
		labels.insert(0,nodes[i].getAttribute('exp_name'))
		values.insert(0,eval(nodes[i].getAttribute('value')))

rowCount=0
for i in range(len(nodes)):
	#if not nodes[i].getAttribute('series_name')[-1:] in datasets:
	#	continue	
	#else:
		ds = eval(nodes[i].getAttribute('sig_error'))
		if ds<.99 and ds>.01:
			NOT_DETECTED.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='F4_ILMN_RIKEN1_PMA':
			RIKEN1.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='F4_ILMN_RIKEN3_PMA':
			RIKEN3.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='F4_ILMN_RIKEN3_PMA_techrep2':
			RIKEN3.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='F4_ILMN_RIKEN6_PMA':
			RIKEN6.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='ILMN_siRNA_V2series1':
			ILMN_siRNA_V2series1.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='ILMN_siRNA_V2series234_181207':
			ILMN_siRNA_V2series234_181207.append(len(values)-rowCount-1)
		elif nodes[i].getAttribute('series_name')=='ILMN_miRNA_V2_181207':
			ILMN_miRNA_V2_181207.append(len(values)-rowCount-1)
		rowCount = rowCount+1


if len(values)<1:
	print "Content-type:text/html\n\nSomething went wrong,<br>Was it invalid library parameter?",datasets
	sys.exit()
	
	
dom.unlink()


import pylab
from numpy import arange
from matplotlib.font_manager import FontProperties


axisFontSize = 6.3
titleFontSize= 10
barWidth = 0.779 

pylab.figure(figsize=(4, len(values)/(axisFontSize*1.7))) 
pylab.axes([0.49,0.01,.49,.97])



pylab.title(category+':'+probeid,position=(.3,1.005),fontsize=titleFontSize)
ind = arange(0,len(values))  # the x locations for the groups
bars = pylab.barh(ind-(barWidth/2.0), values, barWidth, color='blue',lw=0.5)
pylab.yticks(ind, labels,fontsize=axisFontSize,fontname='Helvetica' )
pylab.ylim(-.7,len(ind)-.35)
pylab.xticks(fontsize=axisFontSize)


colorbars(RIKEN1,'#5555ff')
colorbars(RIKEN3,'#9999FF')
colorbars(RIKEN6,'#ddddFF')
colorbars(ILMN_siRNA_V2series1,'#ff5555')
colorbars(ILMN_siRNA_V2series234_181207,'#ff9999') 
colorbars(ILMN_miRNA_V2_181207,'#ffdddd')

colorbars(NOT_DETECTED,'#EEEEEE')


pylab.savefig( imageName, format='png')

drawImage()
