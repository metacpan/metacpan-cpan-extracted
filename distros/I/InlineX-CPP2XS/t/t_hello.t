use warnings;
use strict;
use InlineX::CPP2XS qw(cpp2xs);

print "1..1\n";

cpp2xs('hello', 'hello',
       {PREFIX => 'remove_', BOOT => 'printf("Hi from bootstrap\n");'});

my $ok = 1;
my @rd1;
my $count = 0;


if($ok) {
  if(!open(RD1, '<', 'hello.xs')) {
    warn "unable to open hello.xs for reading: $!\n";
    print "not ok 1\n";
    $ok = 0;
  }
}



if($ok) {
  @rd1 = <RD1>;
}


if($ok) {
  for(@rd1) {
     $count++ if $_ =~ /#include <iostream/;			#2
     $count++ if $_ =~ /void greet/;				#1
     $count++ if $_ =~ /MODULE/;				#1
     $count++ if $_ =~ /PACKAGE/;				#1
     $count++ if $_ =~ /PREFIX = remove_/;			#1
     $count++ if $_ =~ /PREINIT:/;				#1
     $count++ if $_ =~ /PPCODE:/;				#1
     $count++ if $_ =~ /BOOT:/;					#1
     $count++ if $_ =~ /printf\(\"Hi from bootstrap\\n\"\);/;	#1
     $count++ if $_ =~ /Remove_me_foo/;				#2
     $count++ if $_ =~ /PROTOTYPES: DISABLE/;			#1
  }
}

if($ok && ($count != 13)) {
  warn "hello.xs not as expected\n";
  print "not ok 1\n";
}

elsif($ok) {print "ok 1\n"}

close(RD1) or warn "Unable to close hello.xs after reading: $!\n";
if(!unlink('hello.xs')) { warn "Couldn't unlink hello.xs\n"}

