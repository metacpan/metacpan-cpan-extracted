10 4 4 1
 1 ctperl.dat  30  1280  0  1 a z
    2    ctperl.idx 30 0 0  0  4096  1 1  32  1 i
	    0 30 2

------------------------------------------------------------------------
ISAM paramter file format Quick reference
    (see Ctree Programmer's Reference Guide Chapter 5 for more info)

 Initialization Record
		    number of index file buffers 
		    number of indicies
		    number of node sectors
		    number of data files
    Data File Description Record
		    data file number 
		    data file name
		    record length
		    file size extension
		    file mode
			 0 = EXCLUSIVE
		  	 1 = SHARED
			 2 = PERMANENT
			 4 = VLENGTH
		  	 8 = READFIL
			16 = PREIMG
			48 = TRNLOG
			64 = WRITETHRU
			128= CHECKLOCK
		    number of index files
		    first field name (RTREE only)
		    last field name  (RTREE only)
       Index File Description Record
		    index file number
		    index file name
		    key length 
		    key type
			 4 = leading compression
			 8 = padding compression
	            duplicate flag
	            number of additional index file members
	            null key flag
	            empty character
	            number of key segments
		    symbolic index name (RTREE only)
           Optional Index Member Record
                    key number
                    key length
                    key type
                    deuplicate flag
                    null key flag
                    empty character
                    number of key segments
		    symbolic index name (RTREE only)
               Key Segment Description
                    segment position
                    segment length
                    segment mode
                       1 = INTSEG
                       2 = UREGSEG
                       3 = SRLSEG
                       4 = VARSEG
                       5 = UVARSEG
                       6 = YOURSEG1
                       7 = YOURSEG2
                       8 = SNGSEG
                       9 = FLTSEG
                       10= DECSEG
                       11= BCDSEG
                       12= SCHSEG
                       13= USCHSEG
                       14= VSCHSEG
                       15= UVSCHSEG
                       16= DSCSEG
                       32= ALTSEG
                       64= ENDSEG

