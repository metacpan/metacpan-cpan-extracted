#!/usr/bin/perl
use strict;
use warnings;
use blib ;

use Inline Java => "DATA" ;


package EventHandler ;

sub new {
	my $class = shift ;
	my $max = shift ;

	return bless({max => $max, nb => 0}, $class) ;
}


sub button_pressed {
	my $this = shift ;
	my $button = shift ;

	$this->{nb}++ ;
	print "Button Pressed $this->{nb} times (from perl)\n" ;
	if ($this->{nb} > $this->{max}){
		$button->StopCallbackLoop() ;
	}
 
	return $this->{nb} ;
}


my $button = MyButton->new(new EventHandler(10));
$button->StartCallbackLoop() ;
print "loop done\n" ;



package main ;

__DATA__
__Java__

import java.util.*;
import org.perl.inline.java.*;
import javax.swing.*;
import java.awt.event.*;

public class MyButton extends    InlineJavaPerlCaller
                      implements ActionListener
{
  InlineJavaPerlObject po = null ;

  public MyButton(InlineJavaPerlObject _po) throws InlineJavaException
  {
    po = _po ;
    // create frame
    JFrame frame = new JFrame("MyButton");
    frame.setSize(200,200);

    // create button
    JButton button = new JButton("Click Me!");
    frame.getContentPane().add(button);

    // tell the button that when it's clicked, report it to
    // this class.
    button.addActionListener(this);

    // all done, everything added, just show it
    frame.show();
  }

  public void actionPerformed(ActionEvent e)
  {
    try
    {
      String cnt = (String)CallPerlMethod(po, "button_pressed", new Object [] {this});
      System.out.println("Button Pressed " + cnt + " times (from java)") ;
    }
    catch (InlineJavaPerlException pe)  { }
    catch (InlineJavaException pe) { pe.printStackTrace() ;}
  }
}
