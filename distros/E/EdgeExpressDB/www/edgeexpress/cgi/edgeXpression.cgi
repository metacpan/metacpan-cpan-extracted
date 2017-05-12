#!/usr/bin/python
import os,sys
import MySQLdb
import cgitb; cgitb.enable()
import cgi

os.environ[ 'HOME' ] = "/tmp"
IMG_DIR = "/data/www/html/4/edgeexpress/tmpimages/"
IMG_URL = "../tmpimages/"
import pylab
from matplotlib.font_manager import FontProperties

timecourses = {'CAGE':['0', '1', '4', '12', '24', '96'],
               'qRT-PCR':['0','1','2','4','6','12','24','48','72','96'],
               'Illumina':['0','1','2','4','6','12','24','48','72','96'],
               'miRNA':['0','1','2','4','6','12','24','48','72','96']}

ylabels = {'CAGE':'Tags Per Million',
           'qRT-PCR':'Copy Number',
           'Illumina':'Expression Ratio',
           'miRNA':'Normalized Intensity'}

linestyle = {'1':'-.',
             '3':'--',
             '6':'-'}
           
fonts = {'title':25,
	 'lw':3,
	 'label':25,
	 'legend':20,
	 'ticks':17,
	 'dpi':35,
         'image_size':''}

markersize = 10

colorcycle = ['b','g','r','c','m','y','k']
markercycle =['','^','o','s','d','>','<','x','h']



def fetchmiRNAData(lib1, lib3, lib6, mature):
	
	if mature:
		cursor.execute("select fl1.mat_mirna_id fid,mat_miRNA as primary_name,series_name,e.value "
		+"from experiment join expression e "
		+"using(experiment_id) join "
		+"(select mat.primary_name mat_miRNA,feature2_id mat_mirna_id,feature1_id mirna_probe_id "
		+"from feature probe join edge on(probe.feature_id = feature1_id) "
		+"join feature mat on(mat.feature_id = feature2_id) where edge_source_id=43 "
		+"and feature2_id in ("+idstring+"))fl1 where feature_id = mirna_probe_id "
		+"and series_name in ("+datasetstring+")")
	else:
		cursor.execute("select substring(fl3.mat_miRNA,length(fl3.mat_miRNA)-1) mat_miRNA,pre_mirna_id fid, pre_miRNA primary_name,series_name,value "
		+"from experiment join expression e "
		+"using(experiment_id) join (select fl1.*, fl2.feature1_id mirna_probe_id "
		+"from edge fl2 join "
		+"(select pre.primary_name pre_miRNA, mat.primary_name mat_miRNA, feature1_id pre_mirna_id, feature2_id mat_mirna_id "
		+"from feature pre join edge on(pre.feature_id = feature1_id) "
		+"join feature mat on(mat.feature_id = feature2_id) "
		+"where edge_source_id=20 and feature1_id in ("+idstring+"))fl1 "
		+"where fl1.mat_mirna_id = fl2.feature2_id)fl3 "
		+"where feature_id = mirna_probe_id "
		+"and series_name in ("+datasetstring+")")

	parseResultSet(lib1, lib3, lib6)

def fetchCAGEData(lib1, lib3, lib6):
    cursor.execute("select feature_id fid, primary_name, series_name, value "
    +"from experiment "
    +"join (select * from expression "
    +"join feature "
    +"using(feature_id) "
    +"where feature.feature_id in ("+idstring+"))e "
    +"using(experiment_id) "
    +"where platform='CAGE' and series_name in ("+datasetstring+") "
    +"and datatype_id=2 "
    +"order by feature_id, series_name, series_point;")

    parseResultSet(lib1, lib3, lib6)
    
def fetchQRTData(lib1, lib3, lib6):
	cursor.execute("SELECT enz.feature_id fid, enz.primary_name primary_name, "
	+"series_name, value, f2.primary_name primer_name, series_point "
	+"FROM feature enz "
	+"JOIN edge fl1 "
	+"on(fl1.feature2_id=enz.feature_id) JOIN feature f2 "
	+"on(fl1.feature1_id=f2.feature_id) JOIN expression fe "
	+"on(f2.feature_id = fe.feature_id) JOIN experiment using(experiment_id ) "
	+"WHERE fl1.edge_source_id=25 and enz.feature_id in ("+idstring+") "
	+"and series_name in ("+datasetstring+") AND datatype_id=2 "
	+"UNION SELECT f2.feature_id fid, f2.primary_name primary_name, series_name, "
	+"value, f2.primary_name primer_name, series_point  FROM feature f2  "
	+"JOIN expression fe  on(f2.feature_id = fe.feature_id) JOIN experiment using(experiment_id )  "
	+"WHERE platform='qRT_PCR' and f2.feature_id in ("+idstring+") AND datatype_id=2 "
	+"order by fid, primer_name, series_name, series_point")

	parseResultSet(lib1, lib3, lib6)
	


def fetchIlluminaData(lib1, lib3, lib6):
    cursor.execute("SELECT feature1_id id "
        +"FROM feature enz "
        +"JOIN edge fl1 on(fl1.feature2_id=enz.feature_id) "
        +"JOIN expression fe on(fl1.feature1_id = fe.feature_id) "
        +"WHERE fl1.edge_source_id=28 and enz.feature_id in ("+idstring+") "
        +"and sig_error>0.99 "
        +"and datatype_id=2 "
        +"and experiment_id not in(71,72) "
        +"group by feature1_id , feature2_id")

    rs = cursor.fetchallDict()
    probeIds = idstring 
    for row in rs:
        if len(probeIds)>0:
            probeIds+=','
        probeIds += str(row['id'])

    if len(probeIds)>0:
        cursor.execute("SELECT ilmn.feature_id fid, ilmn.primary_name, s.sym_value, "
            +"ilmn.primary_name ilm_id, series_name, value "
            +"FROM symbol s "
            +"JOIN feature_2_symbol f2s using(symbol_id) "
            +"JOIN feature ilmn using(feature_id) "
            +"JOIN expression fe on(ilmn.feature_id = fe.feature_id) "
            +"JOIN experiment using(experiment_id) "
            +"WHERE series_name in ("+datasetstring+") "
            +"and ilmn.feature_id in("+probeIds+") "
            +"and platform ='Illumina microarray' "
            +"and sym_type ='ILMN_hg6v2_key' "
            +"and datatype_id=2 "
            +"and experiment.experiment_id not in(71,72) "
            +"order by fid,ilm_id,series_name,series_point")

        parseResultSet(lib1, lib3, lib6)


def parseResultSet(lib1, lib3, lib6):
    rs = cursor.fetchallDict()
    lastid=-1
    lastgene=-1
    probeindex=0
    probecount=0 

    
    for row in rs:
        lib = {}
        probeid=''
        if row['series_name'].find("RIKEN1")==0:
            lib = lib1
        elif row['series_name'].find("RIKEN3")==0:
            lib = lib3
        else:
            lib = lib6
            
        if row.has_key('ilm_id'):
            probeid='_'+row['ilm_id']
            if ids.count(str(row['fid'])+probeid)==0:
                ids.append(str(row['fid'])+probeid)

        if row.has_key('primer_name'):
            probeid='_'+row['primer_name']
            if ids.count(str(row['fid'])+probeid)==0:
                ids.append(str(row['fid'])+probeid)
        
        if row.has_key('mat_miRNA'):
            probeid='_'+row['mat_miRNA']
            if ids.count(str(row['mat_miRNA'])+probeid)==0:
                ids.append(str(row['fid'])+probeid)
                

        if lib.has_key(str(row['fid'])+probeid):
            gene = lib[str(row['fid'])+probeid]
        else:
            gene = []
            lib[str(row['fid'])+probeid] = gene
            gene.append(str(row['fid'])+probeid)
            if row.has_key('ilm_id'):
                if lastid==-1 or lastid!=row['ilm_id']:
                    if lastgene==-1 or lastgene!=row['fid']:
                        probeindex=1
                        probecount=probecount+1
                    else:
                        probeindex=probeindex+1
                    lastid = row['ilm_id']
                    lastgene = row['fid']

                if fonts['image_size']=='L':
                    gene.append(row['primary_name'])
               	elif probecount>1:
                    gene.append(row['primary_name']+':M'+str(probeindex))
                else:
                    gene.append('M'+str(probeindex))

            elif row.has_key('primer_name'):
                if lastid==-1 or lastid!=row['primer_name']:
                    if lastgene==-1 or lastgene!=row['fid']:
                        probeindex=1
                        probecount=probecount+1
                    else:
                        probeindex=probeindex+1
                    lastid = row['primer_name']
                    lastgene = row['fid']

                if fonts['image_size']=='L':
                    gene.append(row['primary_name'])
                elif probecount>1:
                    gene.append(row['primary_name']+':Q'+str(probeindex))
                else:
                    gene.append('Q'+str(probeindex))
            
            elif row.has_key('mat_miRNA'):
            	gene.append(row['mat_miRNA']+':'+row['primary_name'])

            else:
                gene.append(row['primary_name'])

        gene.append(row['value'])



def plotGraph():
    lineColors = {}

    imageName= ''
    
    uids =[]
    
    singleTitle = ""
    for dataset in datasets:
	if dataset=='1':
		lib = lib1
	elif dataset=='3':
		lib = lib3
	else:
		lib = lib6
		 
	for id in ids:
		if id not in uids and id in lib.keys():
			uids.append( id )

    if(len(uids)<1):
    	return
           
    for id in uids:
	imageName+= id+'_' 
        
    for dataset in datasets:
        imageName += dataset

    imageName+=fonts['image_size']+'.png'
    
    imageExists = os.path.isfile(IMG_DIR+imageName+'as')
 
    pylab.clf() # Clears the current figure

    if thistype=='CAGE':
    	if fonts['image_size']=='L':
    		pylab.figure(figsize=(11,6)) 
    		pylab.axes([0.06,.08, .67, .84])
    	else:
    		pylab.figure(figsize=(10,6)) 
    		pylab.axes([0.11,0.11,.64,.8])
    else:
    	pylab.figure()
    	if thistype=='miRNA' and fonts['image_size']!='L':
    		pylab.axes([0.18,0.11,.79,.8])
    	if thistype=='qRT-PCR' and fonts['image_size']!='L':
    		pylab.axes([0.16,0.10,.78,.8])
    	else:
    		pylab.axes()
    	

    timecourse = timecourses[thistype]

    targetGenes = []
    labels = []
    color = ''
    colcycleindex = 0
    markercycleindex = 0
    geneid = ''

    for id in uids:
        if geneid!=id.split('_')[0]:
            markercycleindex=0

        geneid = id.split('_')[0]

        for dataset in datasets:       
            if dataset=='1':
                lib = lib1
            elif dataset=='3':
                lib = lib3
            else:
                lib = lib6

            if not lib.has_key(id):
                markercycleindex=-1
                continue

            if thistype=='CAGE' and promoterAlias.has_key(id) and fonts['image_size']=='':
                lib[id][1]=promoterAlias[id]
                
                           
            if fonts['image_size']=='L':
            	probeprimer = lib[id][0].split('_')
            	if thistype=='Illumina' or thistype=='qRT-PCR':
			label = probeprimer[1]+":R"+dataset
		else:
			label = lib[id][1]+":R"+dataset
            elif thistype=='miRNA':
            	if len(lib)>1:
            		label = lib[id][1][0:2]+":R"+dataset
            	else:
            		label = 'R'+dataset
            else:
            	label = lib[id][1]+":R"+dataset


            values = lib[id][2:]

            targetGenes.append(lib[id][:2]+[dataset]+values)
            

	    if thistype=='Illumina':
                fvalues=[float(i) for i in values]
                med=pylab.median(fvalues)
                values=["%1.4f"%(f/med) for f in fvalues]  

            if not imageExists:
                    if not lineColors.has_key(geneid):
                            lineColors[geneid]= colorcycle[colcycleindex]
                            colcycleindex = colcycleindex+1
                            colcycleindex%=len(colorcycle)
                        
                    color = lineColors[geneid] 
                    pylab.plot(values,
                               lw=fonts['lw'],
                               ls=linestyle[dataset],
                               ms=markersize,
                               marker=markercycle[markercycleindex],
                               c=color)

                    labels.append(label)
                    
        if thistype!='CAGE':
                markercycleindex=markercycleindex+1
                     
                 
    graphData.append({'type':thistype,
                      'imageName':imageName,
                      'timecourse':timecourse,
                      'values':targetGenes})

    if not imageExists:
            
            pylab.xlabel('Timecourse',fontsize=fonts['label'])
            pylab.ylabel(ylabels[thistype],fontsize=fonts['label'])
            if thistype=='CAGE':
            	pylab.legend(labels,'center left',axespad=1.03,labelsep=0.001,shadow=True, prop = FontProperties(size=fonts['legend']))
            else:
            	pylab.legend(labels,'best',shadow=True, prop = FontProperties(size=fonts['legend']))

            n = len(timecourse)
            pylab.yticks(fontsize=fonts['ticks'])
            pylab.xticks(pylab.arange(n), timecourse, fontsize=fonts['ticks'])
            
            if thistype=='miRNA':
            	pylab.title('Agilent miRNA',fontsize=fonts['title'])
            else:
                pylab.title(thistype, fontsize=fonts['title'] )
            
            pylab.savefig(IMG_DIR+imageName,dpi=fonts['dpi'])
        

def writeTableData():
    if isHTML:
        for graph in graphData:
            if len( graph['values'] )==0:
                continue
            print "<img src=\""+IMG_URL+graph['imageName']+"\">"
        print "<br><pre>"
        print """<br><br><br>&lt;?xml version=\"1.0\" encoding=\"UTF-8\"?&gt;<br>&lt;expressionGraphs&gt;"""
    else:
        print """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<expressionGraphs>"""

    for graph in graphData:
        
        if len( graph['values'] )==0:
            continue
        
        if isHTML:
            print "<br>&nbsp;&nbsp;&lt;graph url=\""+graph['imageName']+"\" type=\""+graph['type']+"\"&gt;"
        else:
            print "<graph url=\""+graph['imageName']+"\" type=\""+graph['type']+"\">"

        
        for gene in graph['values']:

            if isHTML:
                gstring="<br>&nbsp;&nbsp;&nbsp;&nbsp;&lt;"
            else:
                gstring="<"

            gstring += "gene id=\""
            
            if graph['type']!='CAGE':
                ids = gene[0].split('_')
                gstring += ids[0]+"\""
            else:
                gstring += gene[0]+"\""

            gstring+=" name=\""+gene[1]+"\""

            if graph['type']=='Illumina':
                gstring+=" probeId=\""+ids[1]+"\""
            elif graph['type']=='qRT-PCR':
                gstring+=" primerName=\""+ids[1]+"\""
             
                
            gstring += " dataset=\""+gene[2]+"\" data=\""
            
            gSize = len(gene)
            for i in range(3, gSize):
                gstring += "("+graph['timecourse'][i-3]+","+("%1.2f" % float(gene[i]))+")"
                if(i<gSize-1):
                    gstring += ","
            
            if isHTML:
                gstring+="\"/&gt;"
            else:
                gstring+="\"/>"

            print gstring
            
        if isHTML:
            print "<br>&nbsp;&nbsp;&lt;/graph&gt;"
        else:
            print "</graph>"
    if isHTML:
        print "<br>&lt;/expressionGraphs&gt;\n</pre>\n</body>\n</html>"
    else:
        print "</expressionGraphs>"


######################################################################
######################################################################


conn = MySQLdb.connect(host="fantom40.gsc.riken.jp",user="read",passwd="read",db="eeDB_fantom4")
cursor = MySQLdb.cursors.DictCursor(conn)
form = cgi.FieldStorage() 
isHTML = 0
if form.has_key('format') and form.getfirst("format") == 'html':
    isHTML = 1
    print "Content-type: text/html"
    print
    print "<html>\n<head>\n<title>GOI Expression</title>\n</head>\n<body style='background-color:#dddddd;'>"
else:
    print "Content-type: text/xml; charset=UTF-8"
    print

promoterAlias = {}
idstring = ""
ids = []

if form.has_key('names'):

	names = form.getfirst("names","").split(",")
	for name in names:
		alias = name.split(":")
		id = name
		if len(alias)>1:
			id = alias[1]
			alias = alias[0]+":"
		else:
			alias = ""

		cursor.execute("SELECT feature_id from feature where primary_name='"
				+id+"' and feature_source_id in(31,48,49) ")
		rs = cursor.fetchallDict()
		for row in rs:
			ids.append(alias+str(row['feature_id']))

if form.has_key('ids'):
    ids.extend(form.getfirst("ids","").split(","))

for i in range(len(ids)):
	alias = ids[i].split(":")
	if len(idstring)>1:
	    idstring+=","
	if len(alias)>1:
	    promoterAlias[alias[1]]=alias[0]
	    idstring+=alias[1]
	    ids[i] = alias[1]
	else:
	    idstring+=alias[0]


if form.has_key('type'):
   type = form.getfirst("type", "").split(",");
else:
   type = ""

if form.has_key('dataset'):
        datasets = form.getfirst("dataset", "").split(",");
        datasets.sort()
else:
        datasets = ['1','3','6']

datasetstring=""
for ds in datasets:
    if len(datasetstring)>0:
        datasetstring=datasetstring+','
    datasetstring=datasetstring+'\'RIKEN'+ds+'\''

       
if form.has_key('size'):
    #Its either big or small in this version
    fonts['title']=16
    fonts['lw']=1
    fonts['label']=12
    fonts['legend']=9
    fonts['ticks']=10
    fonts['dpi']=100
    fonts['image_size']='L'
    markersize=5



graphData = [];
if len(idstring)>0:
	for thistype in type:  
	    lib1 ={}
	    lib3 ={}
	    lib6 ={}
	    if thistype.lower()=="cage":
		thistype = "CAGE"
		fetchCAGEData(lib1, lib3, lib6)

	    elif thistype.lower()=="qrt-pcr":
		thistype = "qRT-PCR"
		fetchQRTData(lib1, lib3, lib6)

	    elif thistype.lower()=="illumina":
		thistype = "Illumina"
		fetchIlluminaData(lib1, lib3, lib6)

	    elif thistype.lower()=="mirna":
		mature = 0
		if form.has_key('mature') and form.getfirst("mature") == 'true':
			mature = 1
		thistype = "miRNA"
		fetchmiRNAData(lib1, lib3, lib6, mature)
	    else:
		continue
	    plotGraph()

	writeTableData()

cursor.close()
conn.close()
