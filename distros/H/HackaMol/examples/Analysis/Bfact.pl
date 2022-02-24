use Modern::Perl;
use HackaMol;
use List::Util qw(sum0);

my $mol = HackaMol->new->pdbid_mol('2cba');
my %select = (
    "protein" => ['protein'],
    "water"   => ['water'],
    "HETATM"  => ['record_name HETATM'],
    "not_water/protein", ['record_name HETATM','.not. water']
);

foreach my $select (sort keys %select){
    my $selects_ar = $select{$select};
    my $first_select = shift @{$selects_ar};
    my $group = $mol->select_group($first_select);
    while (my $added_select = shift @{$selects_ar}){
        $group = $group->select_group($added_select);
    }
    my $count = $group->count_atoms;
    if ($count){
        my @bfact = map {$_->bfact} $group->all_atoms;
        printf("%s,%i,%.2f\n",$select, $count, sum0(@bfact)/$count);
    }
    else{
        printf("%s,%i\n", $select,$count);
    }
}

