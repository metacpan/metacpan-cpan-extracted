# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::EN::Keywords;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#print "n" unless "sixsmith,moore,byers,secretary,transport" eq join",", 
keywords(<<EOF);
The "spin row" controversy at the Department of Transport has resurfaced with claims that the announcement of one senior civil servant's resignation was false. 

Stephen Byers had backed the resignations of his department's press chief Martin Sixsmith and transport special adviser Jo Moore, saying they had "done the right thing" by quitting.

Mr Sixsmith has now said he did not resign over the row about "burying" bad news, and insists he remains in the post.

But the government has again insisted that both he and Ms Moore had quit.

The latest twist in the saga has led to renewed accusations that Transport Secretary Stephen Byers has manipulated the truth and should stand down.

Shadow transport secretary Theresa May told BBC1's Breakfast With Frost: "What we've seen here is somebody who is more interested in sticking by his special adviser and in manipulating the news than he was in the underlying facts and truth of the situation."

Mr Sixsmith said on Saturday night: "I wasn't sacked, I didn't resign, I haven't offered my resignation.

"So when [Stephen Byers] announced it, he was in the very least mistaken."

The department then said in a statement: "Martin Sixsmith agreed with the Permanent Secretary of DTLR (Sir Richard Mottram) to resign from his post as director of communications on 15 February.

"This was agreed on the basis that Jo Moore also resigned and the terms of his resignation were agreed with him.

"Discussion on the terms of his resignation have been continuing on the basis that these were confidential between him and the department." 

Mr Sixsmith later insisted: "I have still not been sacked, I have still not resigned. No terms have been agreed. I still consider that I am in the job of director of communications at the DTLR."

He said that on 15 February, Sir Richard had asked him to resign with Ms Moore. He said he would consider it, and went off to a hospital appointment.

But on the way back from the hospital, he heard on the radio that both he and Ms Moore had quit.

"I was somewhat alarmed by that. I asked to see Byers but he wouldn't see me," he said.

Later that day, he added, Sir Richard then told him he was sorry but there had been a "complete cock-up", and someone had leaked the news of two resignations.

Sir Richard reportedly said: "How do we get the department and the government out of this mess?"

A report in the Sunday Times says Mr Sixsmith kept a detailed dossier of every phone call and meeting he had during the row, which backs up his version of events.

The shadow transport secretary called on Mr Byers to quit in light of the new claims. 

She told the BBC: "I think it is quite clear he is incapable of running his department.

"His department is in absolute chaos, there's no trust between ministers and civil servants, he compromised the impartiality of civil servants and I think it's clearly a resigning matter."

Scottish Secretary, Helen Liddel, told the same programme the row proved the communications side of that department was dysfunctional and needed sorting out.

The row began with a reported disagreement between Mr Sixsmith and Ms Moore over whether rail statistics should be published on the day of Princess Margaret's funeral.

There were reports that Mr Sixsmith rebuked Ms Moore, who infamously wanted to "bury" bad news on 11 September, for planning to release bad rail figures on that day.

The affair led to accusations that the ministry was "at war" with itself, with staff leaking against each other, and that the neutrality of the civil service was being undermined.

On 15 February it was reported that both had quit, and Mr Byers released a statement that they had done "the right thing".
EOF
print "ok 2\n";
