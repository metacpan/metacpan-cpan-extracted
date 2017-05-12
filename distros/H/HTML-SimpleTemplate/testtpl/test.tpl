# this is the test template for HTML::SimpleTemplate
?!$BlockBanner
**********************************************************************
                HTML::SimpleTemplate Test Template
**********************************************************************
?end
?$UserMessage
$UserMessage
?end

The current value of the Color variable is "$Color". The current value
of the Number variable is "$Number".
ok 3

Is the Color green?
?($Color eq "green")
Yes, it is. (A1)
ok 4
?else
No, it isn't. (A2)
not ok 4
?end

Is the Number 3?
?($Number==3)
not ok 5
Yes, it is. Is the Color green? (B1)
?($Color eq "green")
Yes, it is. The number is 3 AND the color is green. (B1A)
?else
No, it isn't. The number is 3 but the color ISN'T green.(B1B)
?end
?else
No, the number isn't 3. Is the Color green? (B2)
ok 5
?($Color eq "green")
Yes, it is. The number is not 3 but the color is green. (B2A)
ok 6
?else
No, it isn't. The number is not 3 and the color isn't green either. (B2B)
not ok 6
?end
?end

