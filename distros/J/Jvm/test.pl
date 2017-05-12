# Copyright (c) 2000 Ye, wei. 
# All rights reserved. 
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself. 
#
# Ident = $Id: test.pl,v 1.3 2000/09/11 04:13:19 yw Exp $


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Sys::Hostname;
use Jvm;

my $HOSTNAME = "/bin/hostname";

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $STEP = 1;

{
    $STEP ++;
    new Jvm();
    # if new Jvm() failed, it will croak before reach here.
    print "ok $STEP\n";
}

{  
    # static method call
    $STEP ++;
    # sleep 1 sec
  Jvm::call("java.lang.Thread", "sleep", "(J)V", 1000);
    print "ok $STEP\n";
}

{
    # static method call
    $STEP ++;
    my $hex = Jvm::call("java.lang.Integer", "toHexString", "(I)Ljava/lang/String;", 15);
    print ( $hex eq "f" ? "ok $STEP\n" : "not ok $STEP\n");
}

{
    # static method call
    $STEP ++;
    my $rand = myrand();
    my $i = Jvm::call("java.lang.Integer", "parseInt", "(Ljava/lang/String;)I", "$rand");
    print ($i == $rand ? "ok $STEP\n" : "not ok $STEP\n");
}

{
    # java.lang.Integer instance create and call
    $STEP ++;
    my $i = myrand();
    my $obj = new Jvm("java.lang.Integer", "(I)V", $i);
    print ($obj->toString("()Ljava/lang/String;") eq $i ? "ok $STEP\n" : "not ok $STEP\n");
}

{
    # java.lang.Byte instance create and call
    $STEP ++;
    my $rand = myrand(127);
    my $obj = new Jvm("java.lang.Byte", "(B)V", $rand);

    print ( $obj->byteValue("()B") == $rand ? "ok $STEP\n": "not ok $STEP\n");
    
    $STEP ++;
    print ( $obj->shortValue("()S") == $rand ? "ok $STEP\n": "not ok $STEP\n");

    $STEP ++;
    print ( $obj->intValue("()I") == $rand ? "ok $STEP\n" : "not ok $STEP\n");

    $STEP ++;
    print ( $obj->longValue("()J") == $rand ? "ok $STEP\n" : "not ok $STEP\n");

    $STEP ++;
    print ( $obj->floatValue("()F") == $rand ? "ok $STEP\n" : "not ok $STEP\n");

    $STEP ++;
    print ( $obj->doubleValue("()D") == $rand ? "ok $STEP\n" : "not ok $STEP\n");	 
}

{
    # get static member via Jvm::getProperty()
    $STEP ++;
    my $testString = "Hello World!";
    my  $out = Jvm::getProperty("java.lang.System", "out", "Ljava/io/PrintStream;");

    open(SAVEOUT, ">&STDOUT");
    my $tmpfile = "/tmp/TEMP$$";
    open(STDOUT, ">$tmpfile") || die "failed to write file '$tmpfile'.";
    $out->println("(Ljava/lang/String;)V", $testString);
    close(STDOUT);
    open(STDOUT, ">&SAVEOUT");
    close(SAVEOUT);

    open(F, "$tmpfile");
    my $line = <F>;
    chomp($line);
    close(F);

    unlink($tmpfile);

    print ($line eq $testString ? "ok $STEP\n" : "not ok $STEP\n");
}

{
    $STEP ++;

    if( ! -x $HOSTNAME) {
	print "ignore $STEP ($HOSTNAME not found)\n";
    }

    # Equivalent JAVA CODE:
    #   Runtime runtime = new java.lang.Runtime.getRuntime();
    #   Process process = runtime.exec("/bin/hostname");
    #   InputStream input = process.getInputStream();
    #   String hostname = "";
    #   while( (int c = input.read()) != -1) {
    #     hostname = hostname + (byte)c;
    #   }
    #   System.out.println("Hostname: " + hostname);

    my $runtime = Jvm::call("java.lang.Runtime", "getRuntime", "()Ljava/lang/Runtime;");
    #print $runtime, "\n";
    my $process = $runtime->exec("(Ljava/lang/String;)Ljava/lang/Process;", $HOSTNAME);
    my $input = $process->getInputStream("()Ljava/io/InputStream;");
    
    my $hostname = "";
    while( (my $i = $input->read("()I")) != -1) {
	$hostname .= sprintf("%c", $i);
    }

    chomp($hostname);
    print ($hostname eq hostname() ? "ok $STEP\n" : "not ok $STEP\n");
    #Jvm::dump($input);
}

sub myrand {
    my($max) = @_;
    if(! $max) { $max = 99999; }
    return int(rand($max));
}
