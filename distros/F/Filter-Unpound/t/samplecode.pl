$\="\n";
my $a="(var)";
print "Begin.";
#line# print ". 'line'";
# Auto-prints have extra newlines, since they add a newline in addition
# to the setting of $\.  I'm not sure I consider that a bug.
#line> . Auto-print > 'line'
#line#> . Auto-print #> 'line'; $a

print "Always.";	#inline# print ". 'inline'";
print "Text with #line# and #inline# stuff.";
# May look different in different versions!

#line#inline# print ". For 'line' _or_ 'inline'";
#line# #inline# print ". For 'line' _and_ 'inline'";

print "Maybe dangerous with #danger58> in v5.8";

#danger1> . Auto, maybe dangerous with #danger1> text
#danger2# print ". Non-auto, maybe dangerous with #danger2> text"

{ no warnings;
;<<'multi'
    print ".. Multi-line, 'multi'";
    print ".. Treatment of ( #multi# ) depends on version.";
multi
    ;
};

;my $dummy = <<'unmulti'	# comment here, shouldn't affect.
    print "\n.. Multi-line, 'unmulti'";
    print ".. variable declared\n";
unmulti
    ;

; $dummy=<<'unmulti'
    print "\n.. Multi-line, 'unmulti'; undeclared."
unmulti
    ;

print "All Done.";
