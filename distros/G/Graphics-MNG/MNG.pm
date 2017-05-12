package Graphics::MNG;

#-----------------------------------------------------------------------------
#
# MNG.pm
#
# Written by David Mott, SEP 10/24/2001
#
#
# The Graphics::MNG module is Copyright (c) 2001 David P. Mott, USA (dpmott@sep.com)
# (this includes MNG.pm, MNG.xs, typemap, and all test scripts (t*.pl))
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself (i.e. GPL or Artistic).
#
#
#-----------------------------------------------------------------------------


use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use FileHandle;

our @ISA = qw(Exporter DynaLoader);


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use Graphics::MNG ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
   'errors' => [ qw(
      MNG_NOERROR
      MNG_OUTOFMEMORY      
      MNG_INVALIDHANDLE    
      MNG_NOCALLBACK       
      MNG_UNEXPECTEDEOF    
      MNG_ZLIBERROR        
      MNG_JPEGERROR        
      MNG_LCMSERROR        
      MNG_NOOUTPUTPROFILE  
      MNG_NOSRGBPROFILE    
      MNG_BUFOVERFLOW      
      MNG_FUNCTIONINVALID  
      MNG_OUTPUTERROR      
      MNG_JPEGBUFTOOSMALL  
      MNG_NEEDMOREDATA     
      MNG_NEEDTIMERWAIT    
      MNG_NEEDSECTIONWAIT  
      MNG_LOOPWITHCACHEOFF 
      MNG_DLLNOTLOADED     
      MNG_APPIOERROR       
      MNG_APPTIMERERROR    
      MNG_APPCMSERROR      
      MNG_APPMISCERROR     
      MNG_APPTRACEABORT    
      MNG_INTERNALERROR    
      MNG_INVALIDSIG       
      MNG_INVALIDCRC       
      MNG_INVALIDLENGTH    
      MNG_SEQUENCEERROR    
      MNG_CHUNKNOTALLOWED  
      MNG_MULTIPLEERROR    
      MNG_PLTEMISSING      
      MNG_IDATMISSING      
      MNG_CANNOTBEEMPTY    
      MNG_GLOBALLENGTHERR  
      MNG_INVALIDBITDEPTH  
      MNG_INVALIDCOLORTYPE 
      MNG_INVALIDCOMPRESS  
      MNG_INVALIDFILTER    
      MNG_INVALIDINTERLACE 
      MNG_NOTENOUGHIDAT    
      MNG_PLTEINDEXERROR   
      MNG_NULLNOTFOUND     
      MNG_KEYWORDNULL      
      MNG_OBJECTUNKNOWN    
      MNG_OBJECTEXISTS     
      MNG_TOOMUCHIDAT      
      MNG_INVSAMPLEDEPTH   
      MNG_INVOFFSETSIZE    
      MNG_INVENTRYTYPE     
      MNG_ENDWITHNULL      
      MNG_INVIMAGETYPE     
      MNG_INVDELTATYPE     
      MNG_INVALIDINDEX     
      MNG_TOOMUCHJDAT      
      MNG_JPEGPARMSERR     
      MNG_INVFILLMETHOD    
      MNG_OBJNOTCONCRETE   
      MNG_TARGETNOALPHA    
      MNG_MNGTOOCOMPLEX    
      MNG_UNKNOWNCRITICAL  
      MNG_UNSUPPORTEDNEED  
      MNG_INVALIDDELTA     
      MNG_INVALIDMETHOD    
      MNG_INVALIDCNVSTYLE  
      MNG_WRONGCHUNK       
      MNG_INVALIDENTRYIX   
      MNG_NOHEADER         
      MNG_NOCORRCHUNK      
      MNG_NOMHDR           
      MNG_IMAGETOOLARGE    
      MNG_NOTANANIMATION   
      MNG_FRAMENRTOOHIGH   
      MNG_LAYERNRTOOHIGH   
      MNG_PLAYTIMETOOHIGH  
      MNG_FNNOTIMPLEMENTED 
      MNG_IMAGEFROZEN      
      MNG_LCMS_NOHANDLE    
      MNG_LCMS_NOMEM       
      MNG_LCMS_NOTRANS     
   ) ],

   'canvas' => [ qw(
      MNG_CANVAS_RGB8      
      MNG_CANVAS_RGBA8     
      MNG_CANVAS_ARGB8     
      MNG_CANVAS_RGB8_A8   
      MNG_CANVAS_BGR8      
      MNG_CANVAS_BGRA8     
      MNG_CANVAS_BGRA8PM   
      MNG_CANVAS_ABGR8     
      MNG_CANVAS_RGB16     
      MNG_CANVAS_RGBA16    
      MNG_CANVAS_ARGB16    
      MNG_CANVAS_BGR16     
      MNG_CANVAS_BGRA16    
      MNG_CANVAS_ABGR16    
      MNG_CANVAS_GRAY8     
      MNG_CANVAS_GRAY16    
      MNG_CANVAS_GRAYA8    
      MNG_CANVAS_GRAYA16   
      MNG_CANVAS_AGRAY8    
      MNG_CANVAS_AGRAY16   
      MNG_CANVAS_DX15      
      MNG_CANVAS_DX16
   ) ],

   'canvas_fns' => [ qw(
      MNG_CANVAS_PIXELTYPE
      MNG_CANVAS_BITDEPTH
      MNG_CANVAS_HASALPHA
      MNG_CANVAS_ALPHAFIRST
      MNG_CANVAS_ALPHASEPD
      MNG_CANVAS_ALPHAPM
      MNG_CANVAS_RGB
      MNG_CANVAS_BGR
      MNG_CANVAS_GRAY
      MNG_CANVAS_DIRECTX15
      MNG_CANVAS_DIRECTX16
      MNG_CANVAS_8BIT
      MNG_CANVAS_16BIT
      MNG_CANVAS_PIXELFIRST
   ) ],

   'chunk_names' => [ qw(
      MNG_UINT_UNKN

      MNG_UINT_HUH
      MNG_UINT_BACK
      MNG_UINT_BASI
      MNG_UINT_CLIP 
      MNG_UINT_CLON
      MNG_UINT_DBYK
      MNG_UINT_DEFI
      MNG_UINT_DHDR 
      MNG_UINT_DISC
      MNG_UINT_DROP
      MNG_UINT_ENDL
      MNG_UINT_FRAM 
      MNG_UINT_IDAT 
      MNG_UINT_IEND 
      MNG_UINT_IHDR 
      MNG_UINT_IJNG 
      MNG_UINT_IPNG 
      MNG_UINT_JDAA 
      MNG_UINT_JDAT 
      MNG_UINT_JHDR 
      MNG_UINT_JSEP 
      MNG_UINT_JdAA 
      MNG_UINT_LOOP 
      MNG_UINT_MAGN 
      MNG_UINT_MEND 
      MNG_UINT_MHDR 
      MNG_UINT_MOVE 
      MNG_UINT_ORDR 
      MNG_UINT_PAST 
      MNG_UINT_PLTE 
      MNG_UINT_PPLT 
      MNG_UINT_PROM 
      MNG_UINT_SAVE 
      MNG_UINT_SEEK 
      MNG_UINT_SHOW 
      MNG_UINT_TERM 
      MNG_UINT_bKGD 
      MNG_UINT_cHRM 
      MNG_UINT_eXPI 
      MNG_UINT_fPRI 
      MNG_UINT_gAMA 
      MNG_UINT_hIST 
      MNG_UINT_iCCP 
      MNG_UINT_iTXt 
      MNG_UINT_nEED 
      MNG_UINT_oFFs 
      MNG_UINT_pCAL 
      MNG_UINT_pHYg 
      MNG_UINT_pHYs 
      MNG_UINT_sBIT 
      MNG_UINT_sCAL 
      MNG_UINT_sPLT 
      MNG_UINT_sRGB 
      MNG_UINT_tEXt 
      MNG_UINT_tIME 
      MNG_UINT_tRNS 
      MNG_UINT_zTXt
   ) ],


   'chunk_properties' => [ qw(
      MNG_BITDEPTH_1
      MNG_BITDEPTH_2
      MNG_BITDEPTH_4
      MNG_BITDEPTH_8
      MNG_BITDEPTH_16
      MNG_COLORTYPE_GRAY
      MNG_COLORTYPE_RGB                
      MNG_COLORTYPE_INDEXED            
      MNG_COLORTYPE_GRAYA              
      MNG_COLORTYPE_RGBA               
      MNG_COMPRESSION_DEFLATE          
      MNG_FILTER_ADAPTIVE              
      MNG_FILTER_NO_DIFFERING          
      MNG_FILTER_DIFFERING             
      MNG_INTERLACE_NONE               
      MNG_INTERLACE_ADAM7              
      MNG_FILTER_NONE                  
      MNG_FILTER_SUB                   
      MNG_FILTER_UP                    
      MNG_FILTER_AVERAGE               
      MNG_FILTER_PAETH                 
      MNG_INTENT_PERCEPTUAL            
      MNG_INTENT_RELATIVECOLORIMETRIC  
      MNG_INTENT_SATURATION            
      MNG_INTENT_ABSOLUTECOLORIMETRIC  
      MNG_TEXT_TITLE                   
      MNG_TEXT_AUTHOR                  
      MNG_TEXT_DESCRIPTION             
      MNG_TEXT_COPYRIGHT               
      MNG_TEXT_CREATIONTIME            
      MNG_TEXT_SOFTWARE                
      MNG_TEXT_DISCLAIMER              
      MNG_TEXT_WARNING                 
      MNG_TEXT_SOURCE                  
      MNG_TEXT_COMMENT                 
      MNG_FLAG_UNCOMPRESSED            
      MNG_FLAG_COMPRESSED              
      MNG_UNIT_UNKNOWN                 
      MNG_UNIT_METER                   
      MNG_SIMPLICITY_VALID             
      MNG_SIMPLICITY_SIMPLEFEATURES    
      MNG_SIMPLICITY_COMPLEXFEATURES   
      MNG_SIMPLICITY_TRANSPARENCY      
      MNG_SIMPLICITY_JNG               
      MNG_SIMPLICITY_DELTAPNG          
      MNG_TERMINATION_DECODER_NC       
      MNG_TERMINATION_USER_NC          
      MNG_TERMINATION_EXTERNAL_NC      
      MNG_TERMINATION_DETERMINISTIC_NC 
      MNG_TERMINATION_DECODER_C        
      MNG_TERMINATION_USER_C           
      MNG_TERMINATION_EXTERNAL_C       
      MNG_TERMINATION_DETERMINISTIC_C  
      MNG_DONOTSHOW_VISIBLE            
      MNG_DONOTSHOW_NOTVISIBLE         
      MNG_ABSTRACT                     
      MNG_CONCRETE                     
      MNG_NOTVIEWABLE                  
      MNG_VIEWABLE                     
      MNG_FULL_CLONE                   
      MNG_PARTIAL_CLONE                
      MNG_RENUMBER                     
      MNG_CONCRETE_ASPARENT            
      MNG_CONCRETE_MAKEABSTRACT        
      MNG_LOCATION_ABSOLUTE            
      MNG_LOCATION_RELATIVE            
      MNG_TARGET_ABSOLUTE              
      MNG_TARGET_RELATIVE_SAMEPAST     
      MNG_TARGET_RELATIVE_PREVPAST     
      MNG_COMPOSITE_OVER               
      MNG_COMPOSITE_REPLACE            
      MNG_COMPOSITE_UNDER              
      MNG_ORIENTATION_SAME             
      MNG_ORIENTATION_180DEG           
      MNG_ORIENTATION_FLIPHORZ         
      MNG_ORIENTATION_FLIPVERT         
      MNG_ORIENTATION_TILED            
      MNG_OFFSET_ABSOLUTE              
      MNG_OFFSET_RELATIVE              
      MNG_BOUNDARY_ABSOLUTE            
      MNG_BOUNDARY_RELATIVE            
      MNG_BACKGROUNDCOLOR_MANDATORY    
      MNG_BACKGROUNDIMAGE_MANDATORY    
      MNG_BACKGROUNDIMAGE_NOTILE       
      MNG_BACKGROUNDIMAGE_TILE         
      MNG_FRAMINGMODE_NOCHANGE         
      MNG_FRAMINGMODE_1                
      MNG_FRAMINGMODE_2                
      MNG_FRAMINGMODE_3                
      MNG_FRAMINGMODE_4                
      MNG_CHANGEDELAY_NO               
      MNG_CHANGEDELAY_NEXTSUBFRAME     
      MNG_CHANGEDELAY_DEFAULT          
      MNG_CHANGETIMOUT_NO              
      MNG_CHANGETIMOUT_DETERMINISTIC_1 
      MNG_CHANGETIMOUT_DETERMINISTIC_2 
      MNG_CHANGETIMOUT_DECODER_1       
      MNG_CHANGETIMOUT_DECODER_2       
      MNG_CHANGETIMOUT_USER_1          
      MNG_CHANGETIMOUT_USER_2          
      MNG_CHANGETIMOUT_EXTERNAL_1      
      MNG_CHANGETIMOUT_EXTERNAL_2      
      MNG_CHANGECLIPPING_NO            
      MNG_CHANGECLIPPING_NEXTSUBFRAME  
      MNG_CHANGECLIPPING_DEFAULT       
      MNG_CHANGESYNCID_NO              
      MNG_CHANGESYNCID_NEXTSUBFRAME    
      MNG_CHANGESYNCID_DEFAULT         
      MNG_CLIPPING_ABSOLUTE            
      MNG_CLIPPING_RELATIVE            
      MNG_SHOWMODE_0                   
      MNG_SHOWMODE_1                   
      MNG_SHOWMODE_2                   
      MNG_SHOWMODE_3                   
      MNG_SHOWMODE_4                   
      MNG_SHOWMODE_5                   
      MNG_SHOWMODE_6                   
      MNG_SHOWMODE_7                   
      MNG_TERMACTION_LASTFRAME         
      MNG_TERMACTION_CLEAR             
      MNG_TERMACTION_FIRSTFRAME        
      MNG_TERMACTION_REPEAT            
      MNG_ITERACTION_LASTFRAME         
      MNG_ITERACTION_CLEAR             
      MNG_ITERACTION_FIRSTFRAME        
      MNG_SAVEOFFSET_4BYTE             
      MNG_SAVEOFFSET_8BYTE             
      MNG_SAVEENTRY_SEGMENTFULL        
      MNG_SAVEENTRY_SEGMENT            
      MNG_SAVEENTRY_SUBFRAME           
      MNG_SAVEENTRY_EXPORTEDIMAGE      
      MNG_PRIORITY_ABSOLUTE            
      MNG_PRIORITY_RELATIVE            
      MNG_COLORTYPE_JPEGGRAY           
      MNG_COLORTYPE_JPEGCOLOR          
      MNG_COLORTYPE_JPEGGRAYA          
      MNG_COLORTYPE_JPEGCOLORA         
      MNG_BITDEPTH_JPEG8               
      MNG_BITDEPTH_JPEG12              
      MNG_BITDEPTH_JPEG8AND12          
      MNG_COMPRESSION_BASELINEJPEG     
      MNG_INTERLACE_SEQUENTIAL         
      MNG_INTERLACE_PROGRESSIVE        
      MNG_IMAGETYPE_UNKNOWN            
      MNG_IMAGETYPE_PNG                
      MNG_IMAGETYPE_JNG                
      MNG_DELTATYPE_REPLACE            
      MNG_DELTATYPE_BLOCKPIXELADD      
      MNG_DELTATYPE_BLOCKALPHAADD      
      MNG_DELTATYPE_BLOCKCOLORADD      
      MNG_DELTATYPE_BLOCKPIXELREPLACE  
      MNG_DELTATYPE_BLOCKALPHAREPLACE  
      MNG_DELTATYPE_BLOCKCOLORREPLACE  
      MNG_DELTATYPE_NOCHANGE           
      MNG_FILLMETHOD_LEFTBITREPLICATE  
      MNG_FILLMETHOD_ZEROFILL          
      MNG_DELTATYPE_REPLACERGB         
      MNG_DELTATYPE_DELTARGB           
      MNG_DELTATYPE_REPLACEALPHA       
      MNG_DELTATYPE_DELTAALPHA         
      MNG_DELTATYPE_REPLACERGBA        
      MNG_DELTATYPE_DELTARGBA          
      MNG_POLARITY_ONLY                
      MNG_POLARITY_ALLBUT              
   ) ],

   'compile_options' => [ qw(
      MNG_ACCESS_CHUNKS
      MNG_CHECK_BAD_ICCP
      MNG_DECL
      MNG_DLL
      MNG_ERROR_TELLTALE
      MNG_EXT
      MNG_FULL_CMS
      MNG_GAMMA_ONLY
      MNG_INCLUDE_DISPLAY_PROCS
      MNG_INCLUDE_DITHERING
      MNG_INCLUDE_ERROR_STRINGS
      MNG_INCLUDE_FILTERS
      MNG_INCLUDE_IJG6B
      MNG_INCLUDE_INTERLACE
      MNG_INCLUDE_JNG
      MNG_INCLUDE_JNG_READ
      MNG_INCLUDE_JNG_WRITE
      MNG_INCLUDE_LCMS
      MNG_INCLUDE_OBJECTS
      MNG_INCLUDE_READ_PROCS
      MNG_INCLUDE_TIMING_PROCS
      MNG_INCLUDE_TRACE_PROCS
      MNG_INCLUDE_TRACE_STRINGS
      MNG_INCLUDE_WRITE_PROCS
      MNG_INCLUDE_ZLIB
      MNG_STORE_CHUNKS
      MNG_SUPPORT_DISPLAY
      MNG_SUPPORT_FULL
      MNG_SUPPORT_IJG6B
      MNG_SUPPORT_JPEG8
      MNG_SUPPORT_READ
      MNG_SUPPORT_WRITE
      MNG_TRACE_TELLTALE
      MNG_USE_SETJMP
   ) ],

   'version' => [ qw(
      MNG_MNG_VERSION_MAJ
      MNG_MNG_VERSION_MIN
      MNG_PNG_VERSION_MAJ
      MNG_PNG_VERSION_MIN
      MNG_VERSION_DLL
      MNG_VERSION_MAJOR
      MNG_VERSION_MINOR
      MNG_VERSION_RELEASE
      MNG_VERSION_SO
      MNG_MNG_DRAFT
      MNG_MNG_VERSION
      MNG_PNG_VERSION
   ) ],


   'constants' => [ qw(
      MNG_FALSE
      MNG_TRUE
      MNG_NULL
      MNG_NOERROR
      MNG_INVALIDHANDLE
   ) ],

   # default IJG parameters for compression
   'IJG' => [ qw(
      MNG_JPEG_DCT
      MNG_JPEG_MAXBUF
      MNG_JPEG_OPTIMIZED
      MNG_JPEG_PROGRESSIVE
      MNG_JPEG_QUALITY
      MNG_JPEG_SMOOTHING
      MNG_MAX_JDAT_SIZE
   ) ],


   # default zlib compression parameters for deflateinit2
   'ZLIB' => [ qw(
      MNG_ZLIB_LEVEL
      MNG_ZLIB_MAXBUF
      MNG_ZLIB_MEMLEVEL
      MNG_ZLIB_METHOD
      MNG_ZLIB_STRATEGY
      MNG_ZLIB_WINDOWBITS
      MNG_MAX_IDAT_SIZE
   ) ],

   'callback_types' => [ qw(
      MNG_TYPE_ITXT
      MNG_TYPE_TEXT
      MNG_TYPE_ZTXT
   ) ],


   'misc' => [ qw(
      MNG_SUSPENDBUFFERSIZE
      MNG_SUSPENDREQUESTSIZE
   ) ],


   'fns' => [ qw(
      test_callback_fn
      putchunk_info
      getchunk_info
      getchunk_name

      version_text
      version_so
      version_dll
      version_major
      version_minor
      version_release

      initialize
      reset
      cleanup
      read
      read_resume
      write
      create
      readdisplay
      display
      display_resume
      display_freeze
      display_reset
      display_goframe
      display_golayer
      display_gotime
      getlasterror

      setcb_memalloc
      setcb_memfree
      setcb_openstream
      setcb_closestream
      setcb_readdata
      setcb_writedata
      setcb_errorproc
      setcb_traceproc
      setcb_processheader
      setcb_processtext
      setcb_processsave
      setcb_processseek
      setcb_processneed
      setcb_processmend
      setcb_processunknown
      setcb_processterm
      setcb_getcanvasline
      setcb_getbkgdline
      setcb_getalphaline
      setcb_refresh
      setcb_gettickcount
      setcb_settimer
      setcb_processgamma
      setcb_processchroma
      setcb_processsrgb
      setcb_processiccp
      setcb_processarow
      getcb_memalloc
      getcb_memfree
      getcb_openstream
      getcb_closestream
      getcb_readdata
      getcb_writedata
      getcb_errorproc
      getcb_traceproc
      getcb_processheader
      getcb_processtext
      getcb_processsave
      getcb_processseek
      getcb_processneed
      getcb_processmend
      getcb_processunknown
      getcb_processterm
      getcb_getcanvasline
      getcb_getbkgdline
      getcb_getalphaline
      getcb_refresh
      getcb_gettickcount
      getcb_settimer
      getcb_processgamma
      getcb_processchroma
      getcb_processsrgb
      getcb_processiccp
      getcb_processarow

      set_userdata
      set_canvasstyle
      set_bkgdstyle
      set_bgcolor
      set_usebkgd
      set_storechunks
      set_sectionbreaks
      set_cacheplayback
      set_doprogressive
      set_srgb
      set_outputprofile
      set_outputprofile2
      set_outputsrgb
      set_srgbprofile
      set_srgbprofile2
      set_srgbimplicit
      set_viewgamma
      set_displaygamma
      set_dfltimggamma
      set_viewgammaint
      set_displaygammaint
      set_dfltimggammaint
      set_maxcanvaswidth
      set_maxcanvasheight
      set_maxcanvassize
      set_zlib_level
      set_zlib_method
      set_zlib_windowbits
      set_zlib_memlevel
      set_zlib_strategy
      set_zlib_maxidat
      set_jpeg_dctmethod
      set_jpeg_quality
      set_jpeg_smoothing
      set_jpeg_progressive
      set_jpeg_optimized
      set_jpeg_maxjdat
      set_suspensionmode
      set_speed

      get_userdata
      get_sigtype
      get_imagetype
      get_imagewidth
      get_imageheight
      get_ticks
      get_framecount
      get_layercount
      get_playtime
      get_simplicity
      get_bitdepth
      get_colortype
      get_compression
      get_filter
      get_interlace
      get_alphabitdepth
      get_alphacompression
      get_alphafilter
      get_alphainterlace
      get_alphadepth
      get_refreshpass
      get_canvasstyle
      get_bkgdstyle
      get_bgcolor
      get_usebkgd
      get_storechunks
      get_sectionbreaks
      get_cacheplayback
      get_doprogressive
      get_srgb
      get_viewgamma
      get_displaygamma
      get_dfltimggamma
      get_viewgammaint
      get_displaygammaint
      get_dfltimggammaint
      get_maxcanvaswidth
      get_maxcanvasheight
      get_zlib_level
      get_zlib_method
      get_zlib_windowbits
      get_zlib_memlevel
      get_zlib_strategy
      get_zlib_maxidat
      get_jpeg_dctmethod
      get_jpeg_quality
      get_jpeg_smoothing
      get_jpeg_progressive
      get_jpeg_optimized
      get_jpeg_maxjdat
      get_suspensionmode
      get_speed
      get_imagelevel
      get_lastbackchunk
      get_starttime
      get_runtime
      get_currentframe
      get_currentlayer
      get_currentplaytime
      status_error
      status_reading
      status_suspendbreak
      status_creating
      status_writing
      status_displaying
      status_running
      status_timerbreak
      iterate_chunks

      getimgdata_seq
      getimgdata_chunkseq
      getimgdata_chunk
      putimgdata_ihdr
      putimgdata_jhdr
      updatemngheader
      updatemngsimplicity

   ) ],

   'util_fns' => [ qw(
      FileOpenStream
      FileCloseStream
      FileReadData
      FileReadHeader
      FileReadChunks
      FileWriteData
      FileWriteChunks
      FileIterateChunks
   ) ],


   'chunk_fns' => [ qw(
      getchunk_ihdr
      getchunk_plte
      getchunk_idat
      getchunk_trns
      getchunk_gama
      getchunk_chrm
      getchunk_srgb
      getchunk_iccp
      getchunk_text
      getchunk_ztxt
      getchunk_itxt
      getchunk_bkgd
      getchunk_phys
      getchunk_sbit
      getchunk_splt
      getchunk_hist
      getchunk_time
      getchunk_mhdr
      getchunk_loop
      getchunk_endl
      getchunk_defi
      getchunk_basi
      getchunk_clon
      getchunk_past
      getchunk_past_src
      getchunk_disc
      getchunk_back
      getchunk_fram
      getchunk_move
      getchunk_clip
      getchunk_show
      getchunk_term
      getchunk_save
      getchunk_save_entry
      getchunk_seek
      getchunk_expi
      getchunk_fpri
      getchunk_need
      getchunk_phyg
      getchunk_jhdr
      getchunk_jdat
      getchunk_dhdr
      getchunk_prom
      getchunk_pplt
      getchunk_pplt_entry
      getchunk_drop
      getchunk_dbyk
      getchunk_ordr
      getchunk_ordr_entry
      getchunk_magn
      getchunk_unknown

      putchunk_ihdr
      putchunk_plte
      putchunk_idat
      putchunk_iend
      putchunk_trns
      putchunk_gama
      putchunk_chrm
      putchunk_srgb
      putchunk_iccp
      putchunk_text
      putchunk_ztxt
      putchunk_itxt
      putchunk_bkgd
      putchunk_phys
      putchunk_sbit
      putchunk_splt
      putchunk_hist
      putchunk_time
      putchunk_mhdr
      putchunk_mend
      putchunk_loop
      putchunk_endl
      putchunk_defi
      putchunk_basi
      putchunk_clon
      putchunk_past
      putchunk_past_src
      putchunk_disc
      putchunk_back
      putchunk_fram
      putchunk_move
      putchunk_clip
      putchunk_show
      putchunk_term
      putchunk_save
      putchunk_save_entry
      putchunk_seek
      putchunk_expi
      putchunk_fpri
      putchunk_need
      putchunk_phyg
      putchunk_jhdr
      putchunk_jdat
      putchunk_jsep
      putchunk_dhdr
      putchunk_prom
      putchunk_ipng
      putchunk_pplt
      putchunk_pplt_entry
      putchunk_drop
      putchunk_dbyk
      putchunk_ordr
      putchunk_ordr_entry
      putchunk_magn
      putchunk_unknown
   ) ],

#  'all' => [ qw() ],
);

%EXPORT_TAGS->{'all'} = [ map { @{ $_ } } values %EXPORT_TAGS ];

our @EXPORT_OK = ( @{ %EXPORT_TAGS->{'all'} }, '%EXPORT_TAGS' );
our @EXPORT    = (
                    @{ %EXPORT_TAGS->{'constants'} },
                    'error_as_string',
                 );

our $VERSION = '0.04';

#---------------------------------------------------------------------------
sub AUTOLOAD {
   # This AUTOLOAD is used to 'autoload' constants from the constant()
   # XS function.  If a constant is not found then control is passed
   # to the AUTOLOAD in AutoLoader.

   my $constname;
   our $AUTOLOAD;
   ($constname = $AUTOLOAD) =~ s/.*:://;
   croak "& not defined" if $constname eq 'constant';
   my $val = constant($constname, @_ ? $_[0] : 0);
   if ($! != 0) {
      if ($! =~ /Invalid/ || $!{EINVAL}) {
         $AutoLoader::AUTOLOAD = $AUTOLOAD;
         goto &AutoLoader::AUTOLOAD;
      }
      else {
          croak "Your vendor has not defined Graphics::MNG macro $constname";
      }
   }
   {
   	no strict 'refs';
   #	# Fixed between 5.005_53 and 5.005_61
   #	if ($] >= 5.00561) {
   #	    *$AUTOLOAD = sub () { $val };
   #	}
   #	else {
   	    *$AUTOLOAD = sub { $val };
   #	}
   }
   goto &$AUTOLOAD;
}

#---------------------------------------------------------------------------
bootstrap Graphics::MNG $VERSION;

# Package private variables go here.
my %retcode_to_string = ();

# Preloaded methods go here.

# This can't be a BEGIN block because our XS component isn't loaded yet.
# BEGIN
{
   use warnings::register qw(%Offsets);
   my $packageName = __PACKAGE__;
   my $warn_category = %warnings::Offsets->{$packageName};
   set_warn_category($warn_category);

   %retcode_to_string = map { eval("$_()") => $_ } ( @{ %EXPORT_TAGS->{'errors'} } );
}

#---------------------------------------------------------------------------
sub new(;$$)
{
   my ($proto,$data) = @_;
   my $class = ref($proto) || $proto || __PACKAGE__;
   my $self  = initialize( $data || undef );
   bless ( $self );
   return $self;
}

#---------------------------------------------------------------------------
sub DESTROY($)
{
   my ( $self ) = @_;
   my $dowarn = warnings::enabled($self);
   my $rv = cleanup( $self );
   if ( $rv != MNG_NOERROR() && $dowarn )
   {
      warn "DESTROY: cleanup() returned $rv";
   }
}



#---------------------------------------------------------------------------
#- Convenience functions
#---------------------------------------------------------------------------

sub MNG_CANVAS_PIXELTYPE($)  { $_[0] & 0x000000FF }
sub MNG_CANVAS_BITDEPTH($)   { $_[0] & 0x00000100 }
sub MNG_CANVAS_HASALPHA($)   { $_[0] & 0x00001000 }
sub MNG_CANVAS_ALPHAFIRST($) { $_[0] & 0x00002000 }
sub MNG_CANVAS_ALPHASEPD($)  { $_[0] & 0x00004000 }
sub MNG_CANVAS_ALPHAPM($)    { $_[0] & 0x00008000 }

sub MNG_CANVAS_RGB($)        { MNG_CANVAS_PIXELTYPE ($_[0]) == 0}
sub MNG_CANVAS_BGR($)        { MNG_CANVAS_PIXELTYPE ($_[0]) == 1}
sub MNG_CANVAS_GRAY($)       { MNG_CANVAS_PIXELTYPE ($_[0]) == 2}
sub MNG_CANVAS_DIRECTX15($)  { MNG_CANVAS_PIXELTYPE ($_[0]) == 3}
sub MNG_CANVAS_DIRECTX16($)  { MNG_CANVAS_PIXELTYPE ($_[0]) == 4}
sub MNG_CANVAS_8BIT($)       { !MNG_CANVAS_BITDEPTH ($_[0])     }
sub MNG_CANVAS_16BIT($)      {  MNG_CANVAS_BITDEPTH ($_[0])     }
sub MNG_CANVAS_PIXELFIRST($) { !MNG_CANVAS_ALPHAFIRST ($_[0])   }

sub MNG_PNG_VERSION() { MNG_PNG_VERSION_MAJ() . '.' . MNG_PNG_VERSION_MIN() };
sub MNG_MNG_VERSION() { MNG_MNG_VERSION_MAJ() . '.' . MNG_MNG_VERSION_MIN() };



#---------------------------------------------------------------------------
sub error_as_string($$)
{
   my ($status) = pop @_;
   return (%retcode_to_string->{$status} || '');
}

#---------------------------------------------------------------------------
sub getchunk_name($;$)
{
   # take only the last argument
   my ( $iChunktype ) = pop @_;

   # decode the chunkname
   my @aCh;
   $aCh[0] = ($iChunktype >> 24) & 0xFF;
   $aCh[1] = ($iChunktype >> 16) & 0xFF;
   $aCh[2] = ($iChunktype >>  8) & 0xFF;
   $aCh[3] = ($iChunktype      ) & 0xFF;

   # this hexadecimal representation of the type should be machine independent
   my $type = join('', map { sprintf("%02x",$_) } @aCh);
   my $name = join('', map { chr } @aCh);

   return ($name, $type);
}

#---------------------------------------------------------------------------
sub getchunk_info($$$)
{
   my ($hHandle,$hChunk,$iChunktype) = @_;

   my %enum_to_fn = (
      MNG_UINT_IHDR() => [\&getchunk_ihdr,          'iWidth', 'iHeight', 'iBitdepth', 'iColortype', 'iCompression', 'iFilter', 'iInterlace'],
      MNG_UINT_PLTE() => [\&getchunk_plte,          'iCount', 'aPalette'],
      MNG_UINT_IDAT() => [\&getchunk_idat,          'iRawlen', 'pRawdata'],
    # not implemented yet?
      MNG_UINT_IEND() => [sub { MNG_NOERROR() }],
      MNG_UINT_tRNS() => [\&getchunk_trns,          'bEmpty', 'bGlobal', 'iType', 'iCount', 'aAlphas', 'iGray', 'iRed', 'iGreen', 'iBlue', 'iRawlen', 'aRawdata'],
      MNG_UINT_gAMA() => [\&getchunk_gama,          'bEmpty', 'iGamma'],
      MNG_UINT_cHRM() => [\&getchunk_chrm,          'bEmpty', 'iWhitepointx', 'iWhitepointy', 'iRedx', 'iRedy', 'iGreenx', 'iGreeny', 'iBluex', 'iBluey'],
      MNG_UINT_sRGB() => [\&getchunk_srgb,          'bEmpty', 'iRenderingintent'],
      MNG_UINT_iCCP() => [\&getchunk_iccp,          'bEmpty', 'iNamesize', 'zName', 'iCompression', 'iProfilesize', 'pProfile'],
      MNG_UINT_tEXt() => [\&getchunk_text,          'iKeywordsize', 'zKeyword', 'iTextsize', 'zText'],
      MNG_UINT_zTXt() => [\&getchunk_ztxt,          'iKeywordsize', 'zKeyword', 'iCompression', 'iTextsize', 'zText'],
      MNG_UINT_iTXt() => [\&getchunk_itxt,          'iKeywordsize', 'zKeyword', 'iCompressionflag', 'iCompressionmethod', 'iLanguagesize', 'zLanguage', 'iTranslationsize', 'zTranslation', 'iTextsize', 'zText'],
      MNG_UINT_bKGD() => [\&getchunk_bkgd,          'bEmpty', 'iType', 'iIndex', 'iGray', 'iRed', 'iGreen', 'iBlue'],
      MNG_UINT_pHYs() => [\&getchunk_phys,          'bEmpty', 'iSizex', 'iSizey', 'iUnit'],
      MNG_UINT_sBIT() => [\&getchunk_sbit,          'bEmpty', 'iType', 'aBits'],
      MNG_UINT_sPLT() => [\&getchunk_splt,          'bEmpty', 'iNamesize', 'zName', 'iSampledepth', 'iEntrycount', 'pEntries'],
      MNG_UINT_hIST() => [\&getchunk_hist,          'iEntrycount', 'aEntries'],
      MNG_UINT_tIME() => [\&getchunk_time,          'iYear', 'iMonth', 'iDay', 'iHour', 'iMinute', 'iSecond'],
      MNG_UINT_MHDR() => [\&getchunk_mhdr,          'iWidth', 'iHeight', 'iTicks', 'iLayercount', 'iFramecount', 'iPlaytime', 'iSimplicity'],
    # not implemented yet?
      MNG_UINT_MEND() => [sub { MNG_NOERROR() }],
      MNG_UINT_LOOP() => [\&getchunk_loop,          'iLevel', 'iRepeat', 'iTermination', 'iItermin', 'iItermax', 'iCount', 'pSignals'],
      MNG_UINT_ENDL() => [\&getchunk_endl,          'iLevel'],
      MNG_UINT_DEFI() => [\&getchunk_defi,          'iObjectid', 'iDonotshow', 'iConcrete', 'bHasloca', 'iXlocation', 'iYlocation', 'bHasclip', 'iLeftcb', 'iRightcb', 'iTopcb', 'iBottomcb'],
      MNG_UINT_BASI() => [\&getchunk_basi,          'iWidth', 'iHeight', 'iBitdepth', 'iColortype', 'iCompression', 'iFilter', 'iInterlace', 'iRed', 'iGreen', 'iBlue', 'iAlpha', 'iViewable'],
      MNG_UINT_CLON() => [\&getchunk_clon,          'iSourceid', 'iCloneid', 'iClonetype', 'iDonotshow', 'iConcrete', 'bHasloca', 'iLocationtype', 'iLocationx', 'iLocationy'],
      MNG_UINT_PAST() => [\&getchunk_past,          'iDestid', 'iTargettype', 'iTargetx', 'iTargety', 'iCount'],
    # wrong footprint...
    # MNG_UINT_PAST() => [\&getchunk_past_src,      'iEntry', 'iSourceid', 'iComposition', 'iOrientation', 'iOffsettype', 'iOffsetx', 'iOffsety', 'iBoundarytype', 'iBoundaryl', 'iBoundaryr', 'iBoundaryt', 'iBoundaryb'],
      MNG_UINT_DISC() => [\&getchunk_disc,          'iCount', 'pObjectids'],
      MNG_UINT_BACK() => [\&getchunk_back,          'iRed', 'iGreen', 'iBlue', 'iMandatory', 'iImageid', 'iTile'],
      MNG_UINT_FRAM() => [\&getchunk_fram,          'bEmpty', 'iMode', 'iNamesize', 'zName', 'iChangedelay', 'iChangetimeout', 'iChangeclipping', 'iChangesyncid', 'iDelay', 'iTimeout', 'iBoundarytype', 'iBoundaryl', 'iBoundaryr', 'iBoundaryt', 'iBoundaryb', 'iCount', 'pSyncids'],
      MNG_UINT_MOVE() => [\&getchunk_move,          'iFirstid', 'iLastid', 'iMovetype', 'iMovex', 'iMovey'],
      MNG_UINT_CLIP() => [\&getchunk_clip,          'iFirstid', 'iLastid', 'iCliptype', 'iClipl', 'iClipr', 'iClipt', 'iClipb'],
      MNG_UINT_SHOW() => [\&getchunk_show,          'bEmpty', 'iFirstid', 'iLastid', 'iMode'],
      MNG_UINT_TERM() => [\&getchunk_term,          'iTermaction', 'iIteraction', 'iDelay', 'iItermax'],
      MNG_UINT_SAVE() => [\&getchunk_save,          'bEmpty', 'iOffsettype', 'iCount'],
    # wrong footprint...
    # MNG_UINT_SAVE() => [\&getchunk_save_entry,    'iEntry', 'iEntrytype', 'iOffset', 'iStarttime', 'iLayernr', 'iFramenr', 'iNamesize', 'zName'],
      MNG_UINT_SEEK() => [\&getchunk_seek,          'iNamesize', 'zName'],
      MNG_UINT_eXPI() => [\&getchunk_expi,          'iSnapshotid', 'iNamesize', 'zName'],
      MNG_UINT_fPRI() => [\&getchunk_fpri,          'iDeltatype', 'iPriority'],
      MNG_UINT_nEED() => [\&getchunk_need,          'iKeywordssize', 'zKeywords'],
      MNG_UINT_pHYg() => [\&getchunk_phyg,          'bEmpty', 'iSizex', 'iSizey', 'iUnit'],
      MNG_UINT_JHDR() => [\&getchunk_jhdr,          'iWidth', 'iHeight', 'iColortype', 'iImagesampledepth', 'iImagecompression', 'iImageinterlace', 'iAlphasampledepth', 'iAlphacompression', 'iAlphafilter', 'iAlphainterlace'],
      MNG_UINT_JDAT() => [\&getchunk_jdat,          'iRawlen', 'pRawdata'],
    # not yet implemented
    # MNG_UINT_JDAA() => [sub { MNG_NOERROR() },    'iRawlen', 'pRawdata'], 
    # MNG_UINT_JSEP()
      MNG_UINT_DHDR() => [\&getchunk_dhdr,          'iObjectid', 'iImagetype', 'iDeltatype', 'iBlockwidth', 'iBlockheight', 'iBlockx', 'iBlocky'],
      MNG_UINT_PROM() => [\&getchunk_prom,          'iColortype', 'iSampledepth', 'iFilltype'],
    # MNG_UINT_IPNG()
      MNG_UINT_PPLT() => [\&getchunk_pplt,          'iCount'],
    # wrong footprint...
    # MNG_UINT_PPLT() => [\&getchunk_pplt_entry,    'iEntry', 'iRed', 'iGreen', 'iBlue', 'iAlpha', 'bUsed'],
    # no such symmetrical function
    # MNG_UINT_JPNG() => [\&getchunk_jpng],
      MNG_UINT_DROP() => [\&getchunk_drop,          'iCount', 'pChunknames'],
      MNG_UINT_DBYK() => [\&getchunk_dbyk,          'iChunkname', 'iPolarity', 'iKeywordssize', 'zKeywords'],
      MNG_UINT_ORDR() => [\&getchunk_ordr,          'iCount'],
    # wrong footprint...
    # MNG_UINT_ORDR() => [\&getchunk_ordr_entry,    'iEntry', 'iChunkname', 'iOrdertype'],
      MNG_UINT_MAGN() => [\&getchunk_magn,          'iFirstid', 'iLastid', 'iMethodX', 'iMX', 'iMY', 'iML', 'iMR', 'iMT', 'iMB', 'iMethodY'],

      MNG_UINT_HUH()  => [\&getchunk_unknown,       'iChunkname', 'iRawlen', 'pRawdata'],
      MNG_UINT_UNKN() => [\&getchunk_unknown,       'iChunkname', 'iRawlen', 'pRawdata'],
      'unknown'       => [\&getchunk_unknown,       'iChunkname', 'iRawlen', 'pRawdata'],

   );

   my ( $name, $type ) = getchunk_name($iChunktype);
   if ( ! exists %enum_to_fn->{$iChunktype} )
   {
      warnings::warnif($hHandle,__PACKAGE__ . "::getchunk_info(): could not translate $iChunktype ($type/$name) to a callable function\n");
      return undef;
   }

   my @fn_info = @{ %enum_to_fn->{$iChunktype} };
   my $fn_ptr  = shift @fn_info;
   my @rv      = &{ $fn_ptr }($hHandle,$hChunk);
   my $rv      = shift @rv;
   my %rv      = (
                   'iChunktype'      => $iChunktype,
                 # 'iChunktype(hex)' => $type,
                   'pChunkname'      => $name,
                    map { @fn_info->[$_] => @rv->[$_] } (0..@rv-1)
                  );

   if ( $rv == MNG_WRONGCHUNK() )
   {
      warnings::warnif($hHandle,__PACKAGE__ . "::getchunk_info(): problem with type $type/$name\n");
   }
   elsif( @rv != @fn_info )
   {
      warnings::warnif($hHandle,__PACKAGE__ . "::getchunk_info(): returned array v/s param list length mismatch for type $type/$name\n") ;
   }

   if ( wantarray )
   {
      return ($rv, \%rv);
   }
   else
   {
      return [$rv, \%rv];
   }
}


#---------------------------------------------------------------------------
sub putchunk_info($;$$)
{
   my ($hHandle,$chunktype,$args) = @_;

   my %enum_to_fn = (
      MNG_UINT_IHDR() => [\&putchunk_ihdr,       'iWidth', 'iHeight', 'iBitdepth', 'iColortype', 'iCompression', 'iFilter', 'iInterlace'],
      MNG_UINT_PLTE() => [\&putchunk_plte,       'iCount', 'aPalette'],
      MNG_UINT_IDAT() => [\&putchunk_idat,       'iRawlen', 'pRawdata'],
    # implemented?
      MNG_UINT_IEND() => [\&putchunk_iend],
      MNG_UINT_tRNS() => [\&putchunk_trns,       'bEmpty', 'bGlobal', 'iType', 'iCount', 'aAlphas', 'iGray', 'iRed', 'iGreen', 'iBlue', 'iRawlen', 'aRawdata'],
      MNG_UINT_gAMA() => [\&putchunk_gama,       'bEmpty', 'iGamma'],
      MNG_UINT_cHRM() => [\&putchunk_chrm,       'bEmpty', 'iWhitepointx', 'iWhitepointy', 'iRedx', 'iRedy', 'iGreenx', 'iGreeny', 'iBluex', 'iBluey'],
      MNG_UINT_sRGB() => [\&putchunk_srgb,       'bEmpty', 'iRenderingintent'],
      MNG_UINT_iCCP() => [\&putchunk_iccp,       'bEmpty', 'iNamesize', 'zName', 'iCompression', 'iProfilesize', 'pProfile'],
      MNG_UINT_tEXt() => [\&putchunk_text,       'iKeywordsize', 'zKeyword', 'iTextsize', 'zText'],
      MNG_UINT_zTXt() => [\&putchunk_ztxt,       'iKeywordsize', 'zKeyword', 'iCompression', 'iTextsize', 'zText'],
      MNG_UINT_iTXt() => [\&putchunk_itxt,       'iKeywordsize', 'zKeyword', 'iCompressionflag', 'iCompressionmethod', 'iLanguagesize', 'zLanguage', 'iTranslationsize', 'zTranslation', 'iTextsize', 'zText'],
      MNG_UINT_bKGD() => [\&putchunk_bkgd,       'bEmpty', 'iType', 'iIndex', 'iGray', 'iRed', 'iGreen', 'iBlue'],
      MNG_UINT_pHYs() => [\&putchunk_phys,       'bEmpty', 'iSizex', 'iSizey', 'iUnit'],
      MNG_UINT_sBIT() => [\&putchunk_sbit,       'bEmpty', 'iType', 'aBits'],
      MNG_UINT_sPLT() => [\&putchunk_splt,       'bEmpty', 'iNamesize', 'zName', 'iSampledepth', 'iEntrycount', 'pEntries'],
      MNG_UINT_hIST() => [\&putchunk_hist,       'iEntrycount', 'aEntries'],
      MNG_UINT_tIME() => [\&putchunk_time,       'iYear', 'iMonth', 'iDay', 'iHour', 'iMinute', 'iSecond'],
      MNG_UINT_MHDR() => [\&putchunk_mhdr,       'iWidth', 'iHeight', 'iTicks', 'iLayercount', 'iFramecount', 'iPlaytime', 'iSimplicity'],
    # implemented?
      MNG_UINT_MEND() => [\&putchunk_mend],
      MNG_UINT_LOOP() => [\&putchunk_loop,       'iLevel', 'iRepeat', 'iTermination', 'iItermin', 'iItermax', 'iCount', 'pSignals'],
      MNG_UINT_ENDL() => [\&putchunk_endl,       'iLevel'],
      MNG_UINT_DEFI() => [\&putchunk_defi,       'iObjectid', 'iDonotshow', 'iConcrete', 'bHasloca', 'iXlocation', 'iYlocation', 'bHasclip', 'iLeftcb', 'iRightcb', 'iTopcb', 'iBottomcb'],
      MNG_UINT_BASI() => [\&putchunk_basi,       'iWidth', 'iHeight', 'iBitdepth', 'iColortype', 'iCompression', 'iFilter', 'iInterlace', 'iRed', 'iGreen', 'iBlue', 'iAlpha', 'iViewable'],
      MNG_UINT_CLON() => [\&putchunk_clon,       'iSourceid', 'iCloneid', 'iClonetype', 'iDonotshow', 'iConcrete', 'bHasloca', 'iLocationtype', 'iLocationx', 'iLocationy'],
      MNG_UINT_PAST() => [\&putchunk_past,       'iDestid', 'iTargettype', 'iTargetx', 'iTargety', 'iCount'],
    # wrong footprint...
    # MNG_UINT_PAST() => [\&putchunk_past_src,   'iEntry', 'iSourceid', 'iComposition', 'iOrientation', 'iOffsettype', 'iOffsetx', 'iOffsety', 'iBoundarytype', 'iBoundaryl', 'iBoundaryr', 'iBoundaryt', 'iBoundaryb'],
      MNG_UINT_DISC() => [\&putchunk_disc,       'iCount', 'pObjectids'],
      MNG_UINT_BACK() => [\&putchunk_back,       'iRed', 'iGreen', 'iBlue', 'iMandatory', 'iImageid', 'iTile'],
      MNG_UINT_FRAM() => [\&putchunk_fram,       'bEmpty', 'iMode', 'iNamesize', 'zName', 'iChangedelay', 'iChangetimeout', 'iChangeclipping', 'iChangesyncid', 'iDelay', 'iTimeout', 'iBoundarytype', 'iBoundaryl', 'iBoundaryr', 'iBoundaryt', 'iBoundaryb', 'iCount', 'pSyncids'],
      MNG_UINT_MOVE() => [\&putchunk_move,       'iFirstid', 'iLastid', 'iMovetype', 'iMovex', 'iMovey'],
      MNG_UINT_CLIP() => [\&putchunk_clip,       'iFirstid', 'iLastid', 'iCliptype', 'iClipl', 'iClipr', 'iClipt', 'iClipb'],
      MNG_UINT_SHOW() => [\&putchunk_show,       'bEmpty', 'iFirstid', 'iLastid', 'iMode'],
      MNG_UINT_TERM() => [\&putchunk_term,       'iTermaction', 'iIteraction', 'iDelay', 'iItermax'],
      MNG_UINT_SAVE() => [\&putchunk_save,       'bEmpty', 'iOffsettype', 'iCount'],
    # wrong footprint...
    # MNG_UINT_SAVE() => [\&putchunk_save_entry, 'iEntry', 'iEntrytype', 'iOffset', 'iStarttime', 'iLayernr', 'iFramenr', 'iNamesize', 'zName'],
      MNG_UINT_SEEK() => [\&putchunk_seek,       'iNamesize', 'zName'],
      MNG_UINT_eXPI() => [\&putchunk_expi,       'iSnapshotid', 'iNamesize', 'zName'],
      MNG_UINT_fPRI() => [\&putchunk_fpri,       'iDeltatype', 'iPriority'],
      MNG_UINT_nEED() => [\&putchunk_need,       'iKeywordssize', 'zKeywords'],
      MNG_UINT_pHYg() => [\&putchunk_phyg,       'bEmpty', 'iSizex', 'iSizey', 'iUnit'],
      MNG_UINT_JHDR() => [\&putchunk_jhdr,       'iWidth', 'iHeight', 'iColortype', 'iImagesampledepth', 'iImagecompression', 'iImageinterlace', 'iAlphasampledepth', 'iAlphacompression', 'iAlphafilter', 'iAlphainterlace'],
      MNG_UINT_JDAT() => [\&putchunk_jdat,       'iRawlen', 'pRawdata'],
    # not yet implemented
    # MNG_UINT_JDAA() => [\&putchunk_jdaa,       'iRawlen', 'pRawdata'],
      MNG_UINT_JSEP() => [\&putchunk_jsep],
      MNG_UINT_DHDR() => [\&putchunk_dhdr,       'iObjectid', 'iImagetype', 'iDeltatype', 'iBlockwidth', 'iBlockheight', 'iBlockx', 'iBlocky'],
      MNG_UINT_PROM() => [\&putchunk_prom,       'iColortype', 'iSampledepth', 'iFilltype'],
      MNG_UINT_IPNG() => [\&putchunk_ipng],
      MNG_UINT_PPLT() => [\&putchunk_pplt,       'iCount'],
    # wrong footprint...
    # MNG_UINT_PPLT() => [\&putchunk_pplt_entry, 'iEntry', 'iRed', 'iGreen', 'iBlue', 'iAlpha', 'bUsed'],
    # not yet implemented
    # MNG_UINT_JPNG() => [\&putchunk_jpng],
      MNG_UINT_DROP() => [\&putchunk_drop,       'iCount', 'pChunknames'],
      MNG_UINT_DBYK() => [\&putchunk_dbyk,       'iChunkname', 'iPolarity', 'iKeywordssize', 'zKeywords'],
      MNG_UINT_ORDR() => [\&putchunk_ordr,       'iCount'],
    # wrong footprint...
    # MNG_UINT_ORDR() => [\&putchunk_ordr_entry, 'iEntry', 'iChunkname', 'iOrdertype'],
      MNG_UINT_MAGN() => [\&putchunk_magn,       'iFirstid', 'iLastid', 'iMethodX', 'iMX', 'iMY', 'iML', 'iMR', 'iMT', 'iMB', 'iMethodY'],
 
      MNG_UINT_HUH()  => [\&putchunk_unknown,    'iChunkname', 'iRawlen', 'pRawdata'],
      MNG_UINT_UNKN() => [\&putchunk_unknown,    'iChunkname', 'iRawlen', 'pRawdata'],
   );

   # make sure $args points to something
   if ( ref($chunktype) eq 'HASH' )  
   {
      # they didn't pass in the type first
      $args = $chunktype;
      $chunktype = $args->{'iChunktype'};
   }
   else
   {
      # chunktype is (hopefully) valid
      # args is (hopefully) valid
   }

   # make sure that $args is really a hash ref, and that $chunktype is defined.
   $args      ||= {};
   $chunktype ||= '';

   if ( !$chunktype || ! exists %enum_to_fn->{$chunktype} )
   {
      my ( $name, $type ) = getchunk_name($chunktype);
      warnings::warnif($hHandle,__PACKAGE__ . "::putchunk_info(): could not translate $chunktype ($type/$name) to a callable function\n");
      return undef;
   }

   my @fn_info = @{ %enum_to_fn->{$chunktype} };
   my $fn_ptr  = shift @fn_info;
   my @args    = map { $args->{$_} || '0' } @fn_info;  # hopefully '0' is always a good default...
   my $rv      = &{ $fn_ptr }($hHandle, @args);

   return $rv;
}




#---------------------------------------------------------------------------
#- Utility Functions
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
sub FileReadData # ($$$$)
{
   my ( $hHandle, $pBuf, $iSize, $pRead ) = @_;
   my ( $userdata ) = $hHandle->get_userdata();
   $$pRead = sysread( $userdata->{'fh'}, $$pBuf, $iSize );
   return MNG_TRUE();
}

#---------------------------------------------------------------------------
sub FileWriteData # ($$$$)
{
   my ( $hHandle, $pBuf, $iBuflen, $pWritten ) = @_;
   my ( $userdata ) = $hHandle->get_userdata();
   $$pWritten = syswrite($userdata->{'fh'}, $pBuf, $iBuflen);
   return MNG_TRUE();
}

#---------------------------------------------------------------------------
sub FileReadHeader # ($$$)
{
   my ( $hHandle, $iWidth, $iHeight ) = @_;
   my ( $userdata ) = $hHandle->get_userdata();
   @$userdata{'width','height'} = ($iWidth,$iHeight);
   return MNG_TRUE();
}

#---------------------------------------------------------------------------
sub FileOpenStream # ($)
{
   my ( $hHandle  ) = @_;
   my ( $userdata ) = $hHandle->get_userdata();
   my ( $fn       ) = $userdata->{'filename'};
   my ( $fperms   ) = $userdata->{'fperms'} || 'r';
   my ( $rv       ) = MNG_FALSE();

   my $fh = $userdata->{'fh'} = new FileHandle( $fn, $fperms );

   if ( defined $fh )
   {
      $fh->autoflush(1);
      binmode($fh);
      return MNG_TRUE();
   }

   warnings::warnif($hHandle,__PACKAGE__ . "::OpenStream(): Failed to open '$fn'\n");
   return MNG_FALSE();
}

#---------------------------------------------------------------------------
sub FileCloseStream # ($)
{
   my ( $hHandle  ) = @_;
   my ( $userdata ) = $hHandle->get_userdata();
   (delete $userdata->{'fh'})->close();
   return MNG_TRUE();
}

#---------------------------------------------------------------------------
sub FileIterateChunks # ($$$$)
{
   my ( $hHandle, $hChunk, $iChunktype, $iChunkseq ) = @_;
   my ( $userdata    ) = $hHandle->get_userdata();
   my ( $name, $type ) = $hHandle->getchunk_name($iChunktype);
   my ( $rv,   $info ) = $hHandle->getchunk_info($hChunk,$iChunktype);

   $info ||= {};                             # provide a default hash ref
   %$info->{'iChunkseq'} = $iChunkseq;       # add the sequence information
   push( @{$userdata->{'chunks'}}, $info )   # store the chunk
      if defined $rv && $rv==MNG_NOERROR();

   # provide for default arrays
   $userdata->{'PLTE'} ||= [];
   $userdata->{'tRNS'} ||= [];

   # Store the palette and transparency information
   push( @{ $userdata->{'PLTE'} }, $info ) if( $name eq 'PLTE' );
   push( @{ $userdata->{'tRNS'} }, $info ) if( $name eq 'tRNS' );

   # always return MNG_TRUE so we can capture all of the chunks
   return MNG_TRUE();
}

#---------------------------------------------------------------------------
sub FileReadChunks($;$)
{
   my ( $fn, $iterFn ) = @_;
   my ( $rv );

   my $obj = Graphics::MNG::new();
   return MNG_INTERNALERROR() unless defined $obj;

   # populate the user data
   $obj->set_userdata( { 'filename' => $fn,
                         'fh'       => undef,
                         'fperms'   => 'r',
                         'width'    => 0,
                         'height'   => 0,
                         'chunks'   => [],
                       } );

   # hook the callbacks...
   $rv ||= $obj->setcb_openstream   ( \&FileOpenStream  );
   $rv ||= $obj->setcb_closestream  ( \&FileCloseStream );
   $rv ||= $obj->setcb_processheader( \&FileReadHeader  );
   $rv ||= $obj->setcb_readdata     ( \&FileReadData    );

   # read the file into memory, and iterate through the chunk list
   $rv ||= $obj->read();
   $rv ||= $obj->iterate_chunks(0, $iterFn ? $iterFn : \&FileIterateChunks );

   return ($rv,$obj);
}

#---------------------------------------------------------------------------
sub FileWriteChunks($$)
{
   my ( $fn, $chunkRef ) = @_;
   my ( $rv );

   my $obj = Graphics::MNG::new();
   return MNG_INTERNALERROR() unless defined $obj;

   warnings::warnif(__PACKAGE__,"Type of arg 2 to " . __PACKAGE__ . "::FileWriteChunks() must be array ref\n")
      unless defined $chunkRef and ref $chunkRef eq 'ARRAY';

   my $userdata;
   $obj->set_userdata( $userdata = 
                       { 'filename' => $fn,
                         'fh'       => undef,
                         'fperms'   => 'w+',
                         'width'    => 0,
                         'height'   => 0,
                       } );

   # hook the callbacks and indicate that we're going to make a new file...

   $rv ||= $obj->setcb_openstream ( \&FileOpenStream  );
   $rv ||= $obj->setcb_closestream( \&FileCloseStream );
   $rv ||= $obj->setcb_writedata  ( \&FileWriteData   );
   $rv ||= $obj->create();

   # now see if we can write out all of those chunks...
   foreach my $chunk ( @$chunkRef )
   {
      $rv ||= $obj->putchunk_info($chunk);
      last unless $rv==MNG_NOERROR();
   }

   # now write the file
   $rv ||= $obj->write();

   return $rv;
}



#---------------------------------------------------------------------------
#- Autoload methods go after =cut, and are processed by the autosplit program.
#---------------------------------------------------------------------------

1;
__END__


=head1 NAME

Graphics::MNG - Perl extension for the MNG library from Gerard Juyn (gerard@libmng.com)


=head1 SYNOPSIS

   # OO-interface
   use Graphics::MNG;
   my $it=['user data'];
   my $obj = new Graphics::MNG (                   ); # w/o user data
   my $obj = new Graphics::MNG ( undef             ); # w/o user data
   my $obj = new Graphics::MNG ( $it               ); # w/  user data
   my $obj = Graphics::MNG::new(                   ); # w/o name w/o data
   my $obj = Graphics::MNG::new('Graphics::MNG'    ); # w/  name w/o data
   my $obj = Graphics::MNG::new('Graphics::MNG',$it); # w/  name w/  data
   $obj->set_userdata(['user data']);
   my $data = $obj->get_userdata();
   print @$data[0],"\n";
   undef $obj;

   # functional interface
   use Graphics::MNG qw( :fns );
   my $handle = initialize( ['more user data'] );
   die "Can't get an MNG handle" if ( MNG_NULL == $handle );
   my $rv = reset( $handle );
   die "Can't reset the MNG handle" unless ( MNG_NOERROR == $rv );
   my $data = get_userdata( $handle );
   print @$data[0],"\n";
   $rv = cleanup( $handle );
   die "handle not NULL" unless ( MNG_NULL == $handle );


=head1 DESCRIPTION

   This is alpha stage software.  Use at your own risk.

   Please visit http://www.libmng.com/ to learn all about the new 
   MNG format.

   MNG (which stands for Multiple Network Graphics) is an extension  
   of the PNG format, which is already gaining popularity over the 
   GIF format. MNG adds the aspect of animation that PNG lacks.

   The Gd module (by Lincoln Stein) supports PNG formats, but MNG is 
   more complicated. It would be cumbersome to add support to the Gd 
   interface for MNG.

   Gerard Juyn as been kind enough to bring us a C-library that 
   supports MNG, so now I thought I'd do my part in bringing you a 
   Perl interface to that library.

   The Graphics::MNG module is an attempt to provide an "accurate"
   interface to the MNG graphics library.  This means that the Perl
   methods supported in this module should look very much like the
   functions in the MNG library interface.

   This module supports both a functional and an OO interface to the 
   MNG library.


=head1 EXPORT

   Everthing under the :constants tag is exported by default.

   Ideally, you'll use one of the incantations of new() to get 
   yourself an object reference, and you'll call methods on that.


=head1 EXPORTABLE CONSTANTS

   :all               -- everything
   :callback_types    -- enum list of callback types (MNG_TYPE_*)
   :canvas            -- constants for canvas ops (MNG_CANVAS_*)
   :canvas_fns        -- functions for canvas ops (MNG_CANVAS_*)
   :chunk_fns         -- functions for chunk ops (getchunk_*,putchunk_*)
   :chunk_names       -- constants for chunk ops (MNG_UINT_*)
   :chunk_properties  -- constants for chunk ops
   :compile_options   -- constants describing how this extension was built
   :constants         -- constants which are commonly used
                         (MNG_FALSE,   MNG_TRUE, 
                          MNG_NOERROR, MNG_NULL, MNG_INVALIDHANDLE)
   :errors            -- constants returned as error values
   :fns               -- functions for the MNG functional interface
   :misc              -- constants misc.  (MNG_SUSPEND*)
   :util_fns          -- pure PERL default implementations of callback
                         functions (see section "UTILITY FUNCTIONS" below)
   :version           -- functions to return various version numbers
                         (MNG,PNG,draft,etc.)
   :IJG               -- constants IJG parameters for compression
   :ZLIB              -- constants zlib compression params for deflateinit2


=head1 INTERFACE FUNCTIONS/METHODS

   The OO-I/F is the same as the functional interface, except that you
   new() your handle into existence, and you undef() it out.  Also,
   you don't pass it as the first parameter to any of the methods -- 
   that's done for you when you use the -> calling syntax to call a
   method.

   There are a *lot* of interface functions in the MNG library.  I'd 
   love to list them all here, but you're really better off opening up 
   the libmng.h file, related documentation, or the Graphics/MNG.pm file 
   and looking at the list of exported methods.  I'll try to make a 
   list here of the methods that deviate in interface characteristics 
   from those found in the MNG library itself.

   I doubt that I've implemented the Perl interface correctly for all 
   of them.  You will find bugs.  Sorry about that.

   In some cases it is convenient to change the Perl interface to make 
   it more convenient to use from within Perl.  A good example of this 
   is any mng_get*() methods that returned values via pointers in the 
   parameter list.  Most or all of these will return a list of values 
   (with the status as the first element), and will only accept the
   input parameters.  On error, only the status code is returned.

   The method getlasterror() behaves in a similiar manner, except that
   it will return the list of parameters only when there is an error.
   Otherwise, it just returns the status (in this case MNG_NOERROR).

   The method initialize() currently takes only one argument -- a
   scalar (typically a reference) to user data.  If the MNG library is
   not compiled with MNG_INTERNAL_MEMMNGMT, then this Perl interface 
   will provide default memory allocation support.  You can use other
   interface methods to enable/disable trace support.



   I've also added some new methods to the interface:
   my ($texterror)   = error_as_string([$hHandle,] MNG_NOERROR());
   my ($name, $type) = getchunk_name([$hHandle,] $iChunktype);
   my ($rv, $href)   = getchunk_info($hHandle, $hChunk, $iChunktype)
   my ($rv)          = putchunk_info($hHandle, [$iChunktype,] \%chunkHash)

   - error_as_string():
     This method takes an mng_retcode and translates it into the
     corresponding string.  For example, 0 => 'MNG_NOERROR'.
     This class method may also be called as a function.
  
   - getchunk_name():
     This method takes the chunktype and returns the ASCII name of the 
     chunk, and also a string containing the hexadecimal representation 
     of the chunktype.  This class method may also be called as a
     function.

   - getchunk_info():
     This method uses the $iChunktype parameter to look up the correct
     getchunk_*() method to call on the $hHandle object to get the chunk
     information related to $hChunk.  It returns a list of status and a
     hash reference containing all of the chunk information.  If called 
     in a scalar context, an array reference containing this list is 
     returned.  The key names of the hash correspond to the libmng 
     parameter names for the appropriate mng_getchunk_*() function.
  
     There are two additional fields added to the returned hash:
        'iChunktype' : the type as passed in by $iChunktype
        'pChunkname' : the chunk name (from getchunk_name($iChunktype))
  
     This hash reference can be passed directly to putchunk_info().

   - putchunk_info():
     This method uses the $iChunktype parameter to look up the correct
     putchunk_*() method to call on the $hHandle object.  The key names
     of the hash must correspond to the libmng parameter names for the
     mng_putchunk_*() function that will be called.
  
     If the $iChunktype parameter is excluded, then the hash is examined
     for a field named 'iChunktype'.
  
     If any fields are excluded, they default to '0', which (before
     presentation to the libmng interface) will translate to a string 
     for array and pointer types, and will translate to zero for integer 
     types.  This seems safe because most arrays and pointer types are 
     accompanied by a length field, which will also default to zero if
     it is excluded.
  
     This method is mostly useful for directly copying chunks from one 
     file to another in conjunction with the getchunk_info() method.

=head1 UTILITY FUNCTIONS

   This section documents the list of added interfaces provided by the
   MNG module which do not exist in libmng.  They have been added for
   your convenience.  They can be imported under the ':util_fns' tag.

   - FileOpenStream( $hHandle )
     This is a default callback implementation for use with
     setcb_openstream.

   - FileCloseStream( $hHandle )
     This is a default callback implementation for use with
     setcb_closestream.

   - FileReadData( $hHandle, \$pBuf, $iSize, \$pRead )
     This is a default callback implementation for use with
     setcb_readdata.

   - FileReadHeader( $hHandle, $iWidth, $iHeight )
     This is a default callback implementation for use with
     setcb_processheader.

   - FileWriteData( $hHandle, $pBuf, $iBuflen, \$pWritten )
     This is a default callback implementation for use with
     setcb_writedata.

   - FileIterateChunks( $hHandle, $hChunk, $iChunktype, $iChunkseq )
     This is a default callback implementation for use with
     iterate_chunks.

   - FileReadChunks( $filename [, \&iteration_function] )

     NOTE: This is not an object method.

     This is a convenience function which will return a list of two
     elements (status, MNG object). The userdata portion of the
     returned MNG object will contain the following keys:

     'filename' => <filename>,
     'width'    => <width of image>,
     'height'   => <height of image>,
     'chunks'   => [ <list of image chunks> ],

     You can specify your own chunk iteration function, or you can leave
     it out and the default (FileIterateChunks()) will be used.

   - FileWriteChunks( $filename, \@chunks )

     NOTE: This is not an object method.

     This is a convenience function which will accept a list of image 
     chunks (as returned by FileReadChunks) and will write them to the
     specified filename.  The status of the entire operation is returned.


=head1 LIMITATIONS

   The MNG library is designed around the concept of callbacks.  I've 
   tried to make the Perl interface closely model the library interface.  
   That means that you'll be working with callback functions.  Depending 
   on your point of view, that's a limitation.

   If you want to write a file with the MNG library, you'll have to
   call create() before writing chunks.  That's just how libmng works.
   If you forget, you'll be disappointed with the results.

   This Perl module is in the alpha stage of development.  That means
   that you'll be lucky to compile it, let alone use it effectively
   without tripping over bugs.

   The MNG library may have limitations of its own, please visit the MNG 
   homepage to learn about them.


=head1 PREREQUISITES/DEPENDENCIES

   You'll need a compiled MNG library, complete with header files, in 
   order to build this Perl module.

   MNG requires some or all of the following support libraries:
   - lcms (little CMS)
   - libjpeg
   - libz

   Specifically, I compile the MNG library (static library, NOT a DLL)
   using MSVC++ with the following compilation flags:
      MNG_FULL_CMS, MNG_INTERNAL_MEMMNGMT, NON_WINDOWS, 
      MNG_BUILD_SO, MNG_SUPPORT_TRACE


=head1 INSTALLATION

   Since this is alpha software...
   - compile the MNG as a static library (Win32) or as a shared library
   - edit Makefile.PL as appropriate for your header file and lib paths

   Then you can install this module by typing the following:
   perl Makefile.PL
   make
   make test
   make install


=head1 TESTING

   There is a suite of tests packaged with this module.  Test #0 is 
   really just a setup script that has been pieced together from other 
   sources.  It uses pure PERL to generate a test case MNG file for 
   later tests.  If you have GD, it will also generate the necessary
   PNG images.

   Since all of the output of this script is already packaged in the
   distribution, you probably won't need to run it.  It's just there
   for your reference and my convenience.

   The last couple of tests actually read and write MNG files.  There 
   are some good examples in there, it's worth checking out.

   If you're on cygwin, 'make test' may not work correctly.  If it
   complains about not being able to open up t/*.t, just type this 
   at the command prompt in the Graphics/MNG directory:
      perl -Mblib test.pl


=head1 KNOWN BUGS

   I have successfully read and written MNG files with this interface.
   If you can't write (simple) MNG files, you may be doing something
   wrong.  See the section LIMITATIONS for related topics.

   You may have noticed that the "mng_" prefix has been removed from
   all of the functions.  This was done to make the OO-I/F look
   prettier.  However, if you import the functional interface, you'll
   get read() and write() in your namespace, thus clashing with Perl's
   built-in functions.  I may change the name for these in the future
   (i.e. an interface deviation).  In the meantime, I suggest that you
   use sysread() and syswrite() in your callbacks.  Even better, use
   the OO-I/F and don't import qw(:fns).

   I'm developing exclusively on Win32 for now, although everything
   *should* work well for any other platform that the MNG library
   supports.

   I'm pretty sure that I have *not* gotten all of the appropriate
   #ifdef protection around parts of the XS code that may be affected
   by MNG compilation flags.
   

=head1 CHANGES AND FUTURE DEVELOPMENT

   This is alpha software.  Expect the worst.  Hope for the best.

   For any functions that return or accept an array of integers or 
   structs, I plan (eventually) to provide a Perl interface that accepts 
   an array of integers or structs (the structs themselves probably being 
   represented as arrays or hashes).  Right now, you'll need to pack() 
   and unpack() the string.

   I may add a convenience method to insert PNG or JNG files into the
   MNG stream.  This would make use of getchunk_*() and putchunk_*()
   methods.

   I need to add a questionaire to the Makefile.PL script to ask the
   user how the libmng was built.  I may also automate a search for
   the appropriate header files, and prompt the user if they can't
   be found.  This interaction may look much like the setup/install
   scripts for GD or PPM.
   

=head1 AUTHOR

   David P. Mott (dpmott@sep.com)


=head1 SUPPORT

   I'd love to support this interface full time, but my work schedule
   won't allow that.  If you see a problem, try to fix it.  If you can
   fix it, write a test case for it.  If you get all of that done, send
   me the fix and the test case, and I'll include it in the next release.

   If you can't fix it, or don't know how to test it, go ahead and send 
   me some email.  I'll see what I can do.

   If you want to maintain this module, by all means mail me and I'll
   get you set up.

   Releases will happen approximately whenever I feel like I have 
   something worthwhile to release, or whenever I get a whole bunch of 
   email from people like you demanding a release.


=head1 COPYRIGHT AND LICENCE

   The Graphics::MNG module is Copyright (c) 2001 David P. Mott, USA
   (dpmott@sep.com)
   All rights reserved.

   This program is free software; you can redistribute it and/or
   modify it under the same terms as Perl itself (i.e. GPL or Artistic).

   See the the Perl README file for more details.
   (maybe here: http://www.perldoc.com/perl5.6.1/README.html)

   For more info on GNU software and the GPL see http://www.gnu.org/
   For more info on the Artistic license see
      http://www.perl.com/perl/misc/Artistic.html

   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
   MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=head1 SEE ALSO

   L<perl>.
   The PNG homepage:      http://www.libpng.org/pub/png/
   The MNG homepage:      http://www.libmng.com/
   The PNG specification: http://www.libpng.org/pub/png/spec/
   The MNG specification: http://www.libpng.org/pub/mng/spec/

   The JPEG homepage:     http://www.ijg.org/
   The Lcms homepage:     http://www.littlecms.com/ 
   The Zlib homepage:     http://www.gzip.org/zlib/

   The GD module:         [download it from your favorite CPAN server]
   The GD homepage:       http://www.boutell.com/gd/
   The Freetype homepage: http://www.freetype.org/

=cut

