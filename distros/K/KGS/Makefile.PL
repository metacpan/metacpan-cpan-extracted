require 5.008;

use Config;

use ExtUtils::MakeMaker;

if (eval { require Gtk2 }) {
   Gtk2->CHECK_VERSION (2, 4, 0)
      or die "gtk+ version 2.4.0 or higher is required to run this program\n";
}

sub MY::postamble {
   my $self=shift;
   <<EOF

.PHONY: doc

doc:
	cd doc && make

run: all doc
	\$(PERL) -Mblib -MCarp=verbose bin/kgsueme

trace: all doc
	\$(PERL) -Mblib -MCarp=verbose bin/kgstrace

EOF
}

WriteMakefile(
    dist	=> {
	            PREOP	=> 'chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM	=> {
                    Convert::Scalar	=> 0,
    		    Gtk2		=> 1.043,
                    Audio::Data		=> 0,
                    Audio::Play		=> 0,
                    Time::HiRes		=> 0,
                    Compress::Zlib	=> 0,
		   },
    DIR		=> [],
    NAME	=> 'KGS',
    linkext	=> { LINKTYPE => '' },
    VERSION_FROM => 'lib/KGS/Protocol.pm',
    EXE_FILES	=> [qw(bin/kgsueme bin/kgstrace bin/gtp-controller)], # not ready: kgs-igs
    PM		=> {
       'lib/Gtk2/GoBoard.pm'		=> '$(INST_LIBDIR)/Gtk2/GoBoard.pm',
       'lib/Gtk2/GoBoard/Constants.pm'	=> '$(INST_LIBDIR)/Gtk2/GoBoard/Constants.pm',

       'images/woodgrain-01.jpg'	=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/woodgrain-01.jpg',
       'images/b-01.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/b-01.png',
       'images/circle-b.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/circle-b.png',
       'images/circle-w.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/circle-w.png',
       'images/shadow.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/shadow.png',
       'images/square-b.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/square-b.png',
       'images/square-w.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/square-w.png',
       'images/triangle-b.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/triangle-b.png',
       'images/triangle-w.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/triangle-w.png',
       'images/w-01.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/w-01.png',
       'images/w-02.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/w-02.png',
       'images/w-03.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/w-03.png',
       'images/w-04.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/w-04.png',
       'images/w-05.png'		=> '$(INST_LIBDIR)/Gtk2/GoBoard/images/w-05.png',

       'lib/KGS/SGF.pm'			=> '$(INST_LIBDIR)/KGS/SGF.pm',
       'lib/KGS/Messages.pm'		=> '$(INST_LIBDIR)/KGS/Messages.pm',
       'lib/KGS/Constants.pm'		=> '$(INST_LIBDIR)/KGS/Constants.pm',
       'lib/KGS/Game/Board.pm'		=> '$(INST_LIBDIR)/KGS/Game/Board.pm',
       'lib/KGS/Game/Tree.pm'		=> '$(INST_LIBDIR)/KGS/Game/Tree.pm',
       'lib/KGS/Listener.pm'		=> '$(INST_LIBDIR)/KGS/Listener.pm',
       'lib/KGS/Listener/Channel.pm'	=> '$(INST_LIBDIR)/KGS/Listener/Channel.pm',
       'lib/KGS/Listener/Debug.pm'	=> '$(INST_LIBDIR)/KGS/Listener/Debug.pm',
       'lib/KGS/Listener/Game.pm'	=> '$(INST_LIBDIR)/KGS/Listener/Game.pm',
       'lib/KGS/Listener/Room.pm'	=> '$(INST_LIBDIR)/KGS/Listener/Room.pm',
       'lib/KGS/Listener/Roomlist.pm'	=> '$(INST_LIBDIR)/KGS/Listener/Roomlist.pm',
       'lib/KGS/Listener/User.pm'	=> '$(INST_LIBDIR)/KGS/Listener/User.pm',
       'lib/KGS/Protocol.pm'		=> '$(INST_LIBDIR)/KGS/Protocol.pm',
       'lib/KGS/Protocol/Client.pm'	=> '$(INST_LIBDIR)/KGS/Protocol/Client.pm',
       'lib/KGS/Protocol/Server.pm'	=> '$(INST_LIBDIR)/KGS/Protocol/Server.pm',

       'images/default_userpic.png'	=> '$(INST_LIBDIR)/KGS/kgsueme/images/default_userpic.png',

       'sounds/alarm'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/alarm',
       'sounds/connect'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/connect',
       'sounds/gamestart'		=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/gamestart',
       'sounds/move'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/move',
       'sounds/pass'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/pass',
       'sounds/resign'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/resign',
       'sounds/outoftime'		=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/outoftime',
       'sounds/ring'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/ring',
       'sounds/user_unknown'		=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/user_unknown',
       'sounds/warning'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/warning',
       'sounds/info'			=> '$(INST_LIBDIR)/KGS/kgsueme/sounds/info',

       'kgsueme/app.pl'			=> '$(INST_LIBDIR)/KGS/kgsueme/app.pl',
       'kgsueme/chat.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/chat.pl',
       'kgsueme/game.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/game.pl',
       'kgsueme/gamelist.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/gamelist.pl',
       'kgsueme/gtk.pl'			=> '$(INST_LIBDIR)/KGS/kgsueme/gtk.pl',
       'kgsueme/room.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/room.pl',
       'kgsueme/roomlist.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/roomlist.pl',
       'kgsueme/sound.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/sound.pl',
       'kgsueme/user.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/user.pl',
       'kgsueme/userlist.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/userlist.pl',
       'kgsueme/util.pl'		=> '$(INST_LIBDIR)/KGS/kgsueme/util.pl',
    },
);



