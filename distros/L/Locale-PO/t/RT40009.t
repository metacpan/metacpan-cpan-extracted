=head1 NAME

t/RT40009.t

=head1 DESCRIPTION

Check that obsolete multiline msgstr entries are
recognized and stored correctly, as per RT#40009:

https://rt.cpan.org/Ticket/Display.html?id=40009

=cut

use strict;
use warnings;

use Test::More tests => 8;
use File::Slurp;
use Locale::PO;
use Data::Dumper;

my $file = "t/RT40009.po";
my $po = Locale::PO->load_file_asarray($file);
ok $po, "loaded ${file} file";

my $out = $po->[0]->dump;
ok $out, "dumped po object";

ok(Locale::PO->save_file_fromarray("${file}.out", $po), "save again to file");
ok -e "${file}.out", "the file now exists";

my $po_after_rt = Locale::PO->load_file_asarray("${file}.out");
ok $po_after_rt, "loaded ${file}.out file"
    and unlink "${file}.out"; 

# Check that our multiline obsolete msgstr is
# still the same string, even if it might have changed
# from multiple lines to single line internally

# Old Locale::PO used to barf with "Strange line at ..."
# See RT#40009, https://rt.cpan.org/Ticket/Display.html?id=40009
my $orig_entry = $po->[1];
my $new_entry  = $po_after_rt->[1];

ok $new_entry->obsolete, "Entry is marked as obsolete";

is_deeply $orig_entry => $new_entry,
    "We have the same entry before and after a round trip";

is $new_entry->msgstr =>
    q("This is an obsolete string that appears to run over multiple lines and there is nothing you can do to escape the simple fact that it does run over multiple lines."),
    "Multiline obsolete strings are conserved";
