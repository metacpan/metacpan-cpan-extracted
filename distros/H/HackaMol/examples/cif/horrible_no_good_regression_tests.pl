use Modern::Perl;
use HackaMol;
use Data::Dumper;

#die "run this as much as you want! but it will take a long time to sync an empty dir";
#
my $bldr = HackaMol->new();

my @pdbids =     qw/
    6ayn 1a2c 3gtk 2ahn 2ah8 3oe0 4gpg 2A0Z 207l 3gtk 2a2x 
    1IVO 4urh
    1a2c 3gtk 2ahn 2ah8 3oe0 4gpg 2A0Z 207l 3gtk 2a2x 
    5a71 3j7p 1aq5 5aiy 3A34 2l9h 139L 6FB4
    /
    ;

$bldr->rcsb_sync_local('cif', @pdbids);

foreach my $pdbid (@pdbids[0]) { 
    my $file = $bldr->pdbid_local_path($pdbid,'cif');
    say $file->stringify;
    my $fh = $file->openr_raw;
    my $info = $bldr->read_cif_info($fh);
    print Dumper $info;
    say 'exp_method ', $info->{exp_method};
    say 'keywords ', $info->{keywords};
    say 'resolution ', $info->{resolution};
    say 'sequence ', $info->{entity}{1}{'_entity_poly.pdbx_seq_one_letter_code_can'};
    my $cys_count = 0;
    foreach my $seq (map{$info->{entity}{$_}{'_entity_poly.pdbx_seq_one_letter_code_can'}} keys %{$info->{entity}}){
        $cys_count += () = $seq =~ /c/ig;
    }

    say "unique seq_cys_count: ", $cys_count;
}


