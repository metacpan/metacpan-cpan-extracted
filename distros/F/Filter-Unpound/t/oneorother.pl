print "Start\n";

#debug# ;my $X=<<'EEOOFF'
print "Debugging is OFF\n";
#debug# EEOOFF
#debug# ;
#debug# print ". Debugging is ON\n";

#debug# ;my $X=<<'EEOOFF'
print "Multi-line debugging... ";
print "... is OFF\n";
#debug# EEOOFF
#debug# ;
;<<'debug'
print "But multi-line debugging... ";
print "... is ON\n";
debug
    ;
