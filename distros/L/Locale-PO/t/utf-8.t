=head1 NAME

t/utf-8.t

=head1 DESCRIPTION

Check that utf-8 files are read correctly

https://rt.cpan.org/Public/Bug/Display.html?id=76366

=cut

use strict;
use warnings;
use utf8;

use Test::More tests => 8;
use File::Slurp;
use Locale::PO;
use Data::Dumper;

my $file = "t/utf-8.po";
my $po = Locale::PO->load_file_asarray( $file, 'utf8' );
ok $po, "loaded ${file} file";

my $out = $po->[0]->dump;
ok $out, "dumped po object";

ok(Locale::PO->save_file_fromarray( "${file}.out", $po, 'utf8' ), "save again to file");
ok -e "${file}.out", "the file now exists";

my $po_after_rt = Locale::PO->load_file_asarray( "${file}.out", 'utf8' );
ok $po_after_rt, "loaded ${file}.out file"
    and unlink "${file}.out";

my $orig_entry = $po->[1];
my $new_entry  = $po_after_rt->[1];

is_deeply $orig_entry => $new_entry,
    "We have the same entry before and after a round trip";

is $new_entry->msgstr =>
    q("Этот текст на русском (UTF-8)"),
    "Multiline obsolete strings are conserved";

ok utf8::is_utf8( $new_entry->msgstr ), "Entry is UTF-8 marked string";
