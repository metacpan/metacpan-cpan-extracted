use Demo1 qr/bill/i => "William", is => 'was' ;

sub bill { print "My name is Bill\n"; "explicitly named" }

bill();
&bill;

print "Thanks, Bill, your bill is @{[bill()]}\n";
