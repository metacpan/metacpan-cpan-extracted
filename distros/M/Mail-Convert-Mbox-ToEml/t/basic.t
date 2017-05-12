use strict;
use Test;
BEGIN { plan tests => 1 };
use Mail::Convert::Mbox::ToEml;
ok(1); # If we made it this far, we're ok.

#my $MBX=Mail::Convert::Mbox::ToEml->new("D:/mail/PO and Portal", "D:/Download/Entwicklung/Delphi/out1");
#my $ret=$MBX->CreateEML();
#my @liste=$MBX->GetMessages();
#my %h = $MBX->FindMessage("WebPortal");
#foreach (keys %h)
#{
#	print "The key: $_="; 
#		foreach my $xx (keys %{$h{$_}})  
#		{
#			print "$xx=" . %{$h{$_}}->{$xx} . " ";
#		}
#	print " \n";
#}
#	print " \n";
#	print " \n";
#foreach (@liste)
#{
#	print "$_\n";
#}
