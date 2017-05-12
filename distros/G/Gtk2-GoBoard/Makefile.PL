require 5.008;

use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM	=> {
    		    Gtk2		   => 1.043,
                    Games::Go::SimpleBoard => 1.01,
		   },
    DIR		=> [],
    NAME	=> 'Gtk2::GoBoard',
    VERSION_FROM => 'GoBoard.pm',
    META_MERGE => {
        recommends => {
           Audio::Play   => 1,
        }
    },
    PM		=> {
       'GoBoard.pm'		=> '$(INST_LIBDIR)/GoBoard.pm',

       'data/woodgrain-01.jpg'	=> '$(INST_LIBDIR)/GoBoard/data/woodgrain-01.jpg',
       'data/b-01.png'		=> '$(INST_LIBDIR)/GoBoard/data/b-01.png',
       'data/circle-b.png'	=> '$(INST_LIBDIR)/GoBoard/data/circle-b.png',
       'data/circle-w.png'	=> '$(INST_LIBDIR)/GoBoard/data/circle-w.png',
       'data/shadow.png'	=> '$(INST_LIBDIR)/GoBoard/data/shadow.png',
       'data/square-b.png'	=> '$(INST_LIBDIR)/GoBoard/data/square-b.png',
       'data/square-w.png'	=> '$(INST_LIBDIR)/GoBoard/data/square-w.png',
       'data/triangle-b.png'	=> '$(INST_LIBDIR)/GoBoard/data/triangle-b.png',
       'data/triangle-w.png'	=> '$(INST_LIBDIR)/GoBoard/data/triangle-w.png',
       'data/cross-b.png'	=> '$(INST_LIBDIR)/GoBoard/data/cross-b.png',
       'data/cross-w.png'	=> '$(INST_LIBDIR)/GoBoard/data/cross-w.png',
       'data/w-01.png'		=> '$(INST_LIBDIR)/GoBoard/data/w-01.png',
       'data/w-02.png'		=> '$(INST_LIBDIR)/GoBoard/data/w-02.png',
       'data/w-03.png'		=> '$(INST_LIBDIR)/GoBoard/data/w-03.png',
       'data/w-04.png'		=> '$(INST_LIBDIR)/GoBoard/data/w-04.png',
       'data/w-05.png'		=> '$(INST_LIBDIR)/GoBoard/data/w-05.png',

       'data/alarm.au'		=> '$(INST_LIBDIR)/GoBoard/data/alarm.au',
       'data/connect.au'	=> '$(INST_LIBDIR)/GoBoard/data/connect.au',
       'data/gamestart.au'	=> '$(INST_LIBDIR)/GoBoard/data/gamestart.au',
       'data/move.au'		=> '$(INST_LIBDIR)/GoBoard/data/move.au',
       'data/pass.au'		=> '$(INST_LIBDIR)/GoBoard/data/pass.au',
       'data/resign.au'		=> '$(INST_LIBDIR)/GoBoard/data/resign.au',
       'data/outoftime.au'	=> '$(INST_LIBDIR)/GoBoard/data/outoftime.au',
       'data/ring.au'		=> '$(INST_LIBDIR)/GoBoard/data/ring.au',
       'data/warning.au'	=> '$(INST_LIBDIR)/GoBoard/data/warning.au',
       'data/info.au'		=> '$(INST_LIBDIR)/GoBoard/data/info.au',
    },
);



