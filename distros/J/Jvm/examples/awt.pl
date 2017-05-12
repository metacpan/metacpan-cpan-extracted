#!/usr/bin/perl -w
#Ident = $Id: awt.pl,v 1.1 2000/09/22 03:11:37 yw Exp $

use ExtUtils::testlib;
use strict;
use Jvm;

new Jvm();
print sprintf("ver:%x\n", Jvm::getVersion());

my $frame = new Jvm("java.awt.Frame","(Ljava/lang/String;)V", "Perl");
my $button= new Jvm("java.awt.Button","(Ljava/lang/String;)V", "Click Me");
my $ret= $frame->add("(Ljava/lang/String;Ljava/awt/Component;)Ljava/awt/Component;","North", $button);
#print "$ret\n";

$frame->setSize("(II)V",200, 200);
$frame->validate("()V");
$frame->show("()V");

Jvm::call("java.lang.Thread", "sleep", "(J)V", 20000);

