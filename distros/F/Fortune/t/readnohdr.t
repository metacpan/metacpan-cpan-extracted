use Fortune;

#
# Test the reading capabilities of the Fortune module in the
# absence of a header (.dat) file.
#
# $Id: readnohdr.t,v 1.3 2000/02/27 02:23:04 greg Exp $
#

my $i = 0;
sub test
{
   my $ok = shift;
   print (($ok ? 'ok ' : 'not ok ') . (++$i) . "\n");
}

print "1..14\n";
test (my $ff = new Fortune ('t/test2'));
$ff->compute_header ('**');
test ($ff->{'numstr'} == 6 && $ff->num_fortunes() == 6);
test ($ff->{'max_length'} == 123 && $ff->{'min_length'} == 19);
test ($ff->{'delim'} eq '**');

@fortunes = ("Eschew Obfuscation\n",
	     "Time flies like an arrow; Fruit flies like a banana.\n",
	     "A closed mouth gathers no foot.\n",
	     "Time heals all wounds--if you don't keep picking off the scab.\n--Holly Ward\n",
	     "Death lasts even longer than grade school and high school put\ntogether.  --Matt Groening\n",
	     "A ship carrying two tons of red paint and a ship carrying one ton\nof blue paint collide.  All the passengers are marooned.\n");

@lengths = sort {$a <=> $b} (map (length, @fortunes));
test ($ff->{'max_length'} == $lengths[-1] &&
      $ff->{'min_length'} == $lengths[0]);

test ($ff->read_fortune (0) eq $fortunes[0]);
test ($ff->read_fortune (1) eq $fortunes[1]);
test ($ff->read_fortune (5) eq $fortunes[5]);
eval { $ff->read_fortune (6) };
test (defined $@ && $@ =~ /invalid fortune number/);

for $i (1 .. 5)
{
   $f = $ff->get_random_fortune ();
   test (grep ($_ eq $f, @fortunes) == 1);
}
