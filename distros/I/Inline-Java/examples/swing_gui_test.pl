use strict ;

use blib ;

use Inline (
	Java => 'DATA',
	STUDY => [
		'javax.swing.JFrame',
		'javax.swing.JPanel',
	],
) ;

my $f = HelloJava1->get_frame("HelloJava1") ;
$f->setSize(140, 100) ;
$f->getContentPane()->add(new HelloJava1()) ;
$f->setVisible(1) ;

<STDIN> ;

__END__

__Java__


class HelloJava1 extends javax.swing.JComponent {
  public HelloJava1() {
  }

  public void paintComponent(java.awt.Graphics g) {
    g.drawString("Hello from Java!", 17, 40) ;
  }

  public static javax.swing.JFrame get_frame(String name) {
    return new javax.swing.JFrame(name) ;
  }
}

