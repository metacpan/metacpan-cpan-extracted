#!./perl -w

use Qt 2.0;
use Event;

package Qt::Application;
BEGIN { Qt::app->import; }  # must happen prior to this override:
{
    # Won't work unless these are *virtual* functions.  Troll Tech
    # hasn't yet seen fit to make this change.  Apply the attached
    # patch for qt, and recompile.
    # Don't forget to make similar adjustments to the PerlQt templates.
    no warnings;
    sub enter_loop { Event::loop() }
    sub exit_loop { Event::unloop() }
}

package MyMainWindow;
use base 'Qt::MainWindow';

use Qt::slots 'open_file()';
sub open_file {
    # call something that does exec(), and therefore enter_loop()
    Qt::FileDialog::getExistingDirectory();
}

use Qt::slots 'quit()';
sub quit { Event::unloop(0) }

package main;
Qt::app->import;

# Some versions of PerlQt don't provide xfd().  Fortunately, it is
# easy to add.
#
# Qt.pig:
#
#   #include <qwindefs.h>
#   #include <X11/Xlib.h>
#   static int xfd() : ConnectionNumber(qt_xdisplay());

Event->io(desc => 'Qt',
	  fd => Qt::xfd(),
	  timeout => .2,  # for balloon help, etc.
	  cb => sub {
	      $app->processEvents(3000);  #read
	      $app->flushX();             #write
	  });

my $w = MyMainWindow->new;

my $mb = $w->menuBar;
my $file = Qt::PopupMenu->new;
$file->insertItem("Open...", $w, 'open_file()');
$file->insertItem("Quit", $w, 'quit()');
$mb->insertItem("File", $file);

my $at = int rand 1000;
my $label = Qt::Label->new("$at", $w);
$w->setCentralWidget($label);

Event->timer(hard => 1, interval => .2, cb => sub {
		 --$at;
		 $at = int rand 1000
		     if $at < 1;
		 # prove that Event is in control
		 $label->setText($at);
	     });

$w->resize(200, 200);
$w->show;

$app->setMainWidget($w);
exit Event::loop();

__END__

diff -c 'qt-2.1.0/src/kernel/qapplication.h' 'qt-2.1.0.new/src/kernel/qapplication.h'
*** ././src/kernel/qapplication.h	Wed Apr 12 09:21:53 2000
--- ././src/kernel/qapplication.h	Wed Apr 12 13:53:51 2000
***************
*** 112,119 ****
      void	     processEvents();
      void	     processEvents( int maxtime );
      void	     processOneEvent();
!     int		     enter_loop();
!     void	     exit_loop();
      int		     loopLevel() const;
      static void	     exit( int retcode=0 );
  
--- 112,119 ----
      void	     processEvents();
      void	     processEvents( int maxtime );
      void	     processOneEvent();
!     virtual int		     enter_loop();
!     virtual void	     exit_loop();
      int		     loopLevel() const;
      static void	     exit( int retcode=0 );
  
