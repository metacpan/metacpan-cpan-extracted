use 5.020;
use strict;
use warnings;
use Test::More;
use Devel::XSCover::XS ();

my $xs = Devel::XSCover::XS->new(dir => 't/fixtures/ex-op');
my @xsubs = $xs->xsubs('Op.c');
is(scalar @xsubs, 16, 'sixteen wrappers in Op.c, the prototype lines and the boot left out');
my %by = map { $_->{c_name} => $_ } @xsubs;
is_deeply($by{XS_Ex__Op_import}, { c_name => 'XS_Ex__Op_import', c_line => 1171, file => 'Op.xs', body_line => 1015 }, 'import: the wrapper and its body line');

my $map = $xs->map('Op.c');
is_deeply($map->{files}, ['Op.xs'], 'one XS file');
my %line = map { $_->{names}[0] => $_->{line} } $xs->subroutines($map);
is($line{'Ex::Op::import'}, 1013, 'import declared on 1013');
is($line{'Ex::Op::unimport'}, 1034, 'unimport on 1034');
is($line{'Ex::Op::export'}, 1046, 'export on 1046');
is($line{'Ex::Op::is_op'}, 1188, 'is_op, with PPCODE unindented, on 1188');
is($line{'Ex::Op::why_not'}, 1198, 'why_not on 1198');
is($line{'Ex::Op::CLONE'}, 1239, 'CLONE on 1239');
is(scalar keys %line, 16, 'every wrapper has a line');

is($xs->declaration_line('Op.xs', 1191, 'is_op'), 1188, 'the scan from the body line');
is($xs->declaration_line('Op.xs', 1191, 'other'), undef, 'but not under another name');
is($xs->declaration_line('Op.xs', 1013), undef, 'a scan that reaches a MODULE line finds nothing');

my $spike = Devel::XSCover::XS->new(dir => 't/fixtures/spike');
my $smap  = $spike->map('Spike.c');
is_deeply($smap->{files}, ['Spike.xs', 'xs/more.xs'], 'the spike and its INCLUDEd file');
%line = map { $_->{names}[0] => $_->{line} } $spike->subroutines($smap);
is($line{'Spike::add'}, 20, 'add, past its ALIAS and CODE lines');
is($line{'Spike::kind'}, 44, 'kind');
is($line{'Spike::guard'}, 92, 'guard');
is($line{'Spike::More::triple'}, 4, 'triple in the included file');
is($line{'Spike::More::never'}, 28, 'never');
is_deeply([$spike->find_declaration(['Spike.xs', 'xs/more.xs'], 'Spike::More::child_only')], ['xs/more.xs', 12], 'the fallback by name in the right PACKAGE');
is_deeply([$spike->find_declaration(['Spike.xs', 'xs/more.xs'], 'Spike::nothing')], [], 'and nothing for a name that is not there');
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is_deeply([$spike->find_declaration(['Spike.xs', 'xs/more.xs'], 'Spike::()')], [], 'an overload table entry is no declaration');
    is_deeply([$spike->find_declaration(['Spike.xs', 'xs/more.xs'], 'Spike::(""')], [], 'nor is an overload method');
    is_deeply(\@warnings, [], 'and neither warns');
}

done_testing;
