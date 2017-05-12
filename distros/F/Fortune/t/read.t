use Fortune;

#
# Test the reading capabilities of the Fortune module.
#
# $Id: read.t,v 1.1 1999/02/20 18:56:59 greg Exp $
#

my $i = 0;
sub test
{
   my $ok = shift;
   print (($ok ? 'ok ' : 'not ok ') . (++$i) . "\n");
}

print "1..13\n";
test (my $ff = new Fortune ('t/test'));
$ff->read_header ();
test ($ff->{'numstr'} == 3 && $ff->num_fortunes() == 3);
test ($ff->{'max_length'} == 54 && $ff->{'min_length'} == 13);
test ($ff->{'delim'} eq '%');

@fortunes = ("This is\na test\nfortune file.\n",
             "Must have single-line as well as multi-line fortunes.\n",
             "And goodbye!\n");

test ($ff->read_fortune (0) eq $fortunes[0]);
test ($ff->read_fortune (1) eq $fortunes[1]);
test ($ff->read_fortune (2) eq $fortunes[2]);
eval { $ff->read_fortune (3) };
test (defined $@ && $@ =~ /invalid fortune number/);

for $i (1 .. 5)
{
   $f = $ff->get_random_fortune ();
   test (grep ($_ eq $f, @fortunes) == 1);
}
