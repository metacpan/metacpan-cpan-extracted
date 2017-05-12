=head1 NAME

t/RT42811.t

=head1 DESCRIPTION

Check that flags are not added twice for the same entry, as per RT#42811:

https://rt.cpan.org/Ticket/Display.html?id=42811

=cut

use strict;
use warnings;

use Test::More tests => 6;
use File::Slurp;
use Locale::PO;
use Data::Dumper;

my $file = "t/RT42811.po";
my $po = Locale::PO->load_file_asarray($file);
ok $po, "loaded ${file} file";

my $out = $po->[1]->dump;
ok $out, "dumped po object";

is_deeply($po->[1]->_flags(), ['fuzzy'],
    'Fuzzy flag was loaded from the file');

ok($po->[1]->has_flag('fuzzy'), "has_flag() for fuzzy is true");

# After we re-add the fuzzy flag, there should still be only one
$po->[1]->add_flag('fuzzy');

ok($po->[1]->has_flag('fuzzy'),
    'has_flag() still true after we added fuzzy again');

#diag(Dumper($po));
is_deeply($po->[1]->_flags(), ['fuzzy'],
    "PO entry still has only *one* fuzzy flag, not more");
