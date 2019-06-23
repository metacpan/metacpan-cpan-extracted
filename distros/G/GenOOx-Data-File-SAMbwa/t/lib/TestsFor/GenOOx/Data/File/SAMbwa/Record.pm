package TestsFor::GenOOx::Data::File::SAMbwa::Record;


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Test::Class::Moose;


#######################################################################
############################   Inheritance   ##########################
#######################################################################
with 'MTCM::Testable';


#######################################################################
#################   Setup (Runs before every method)  #################
#######################################################################
sub test_setup {
	my ( $test, $report ) = @_;
	
	$test->next::method;
	$test->_clear_testable_objects;
}


#######################################################################
###########################   Actual Tests   ##########################
#######################################################################
sub test_isa {
	my ($test) = @_;
	
	isa_ok $test->get_testable_object(0), $test->class_name, "... and the object";
}

sub test_qname {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'qname';
	is $test->get_testable_object(0)->qname, 'HWI-EAS235_25:1:1:4282:1093', "... and returns the correct value";
}

sub test_flag {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'flag';
	is $test->get_testable_object(0)->flag, 16, "... and returns the correct value";
}

sub test_rname {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'rname';
	is $test->get_testable_object(0)->rname, 'chr18', "... and returns the correct value";
}

sub test_pos {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'pos';
	is $test->get_testable_object(0)->pos, 85867636, "... and returns the correct value";
}

sub test_mapq {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'mapq';
	is $test->get_testable_object(0)->mapq, 0, "... and returns the correct value";
}

sub test_cigar {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'cigar';
	is $test->get_testable_object(0)->cigar, '32M', "... and returns the correct value";
}

sub test_rnext {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'rnext';
	is $test->get_testable_object(0)->rnext, '*', "... and returns the correct value";
}

sub test_pnext {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'pnext';
	is $test->get_testable_object(0)->pnext, 0, "... and returns the correct value";
}

sub test_tlen {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'tlen';
	is $test->get_testable_object(0)->tlen, 0, "... and returns the correct value";
}

sub test_seq {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'seq';
	is $test->get_testable_object(0)->seq, 'ATTCGGCAGGTGAGTTGTTACACACTCCTTAG', "... and returns the correct value";
}

sub test_qual {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'qual';
	is $test->get_testable_object(0)->qual, 'GHHGHHHGHHGGGDGEGHHHFHGG<GG>?BGG', "... and returns the correct value";
}

sub test_tags {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'tags';
}

sub test_alignment_length {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'alignment_length';
	is $test->get_testable_object(0)->alignment_length, 32, "... and returns the correct value";
	is $test->get_testable_object(1)->alignment_length, 102, "... and returns the correct value";
	is $test->get_testable_object(2)->alignment_length, 102, "... and returns the correct value";
	is $test->get_testable_object(3)->alignment_length, 102, "... and returns the correct value";
}

sub test_start {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'start';
	is $test->get_testable_object(0)->start, 85867635, "... and returns the correct value";
	is $test->get_testable_object(1)->start, 22051062, "... and returns the correct value";
	is $test->get_testable_object(2)->start, 187239349, "... and returns the correct value";
	is $test->get_testable_object(3)->start, 22985443, "... and returns the correct value";
}

sub test_stop {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'stop';
	is $test->get_testable_object(0)->stop, 85867666, "... and returns the correct value";
	is $test->get_testable_object(1)->stop, 22051163, "... and returns the correct value";
	is $test->get_testable_object(2)->stop, 187239450, "... and returns the correct value";
	is $test->get_testable_object(3)->stop, 22985544, "... and returns the correct value";
}

sub test_strand {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'strand';
	is $test->get_testable_object(0)->strand, -1, "... and returns the correct value";
	is $test->get_testable_object(1)->strand, -1, "... and returns the correct value";
	is $test->get_testable_object(2)->strand, 1, "... and returns the correct value";
	is $test->get_testable_object(3)->strand, 1, "... and returns the correct value";
	is $test->get_testable_object(4)->strand, undef, "... and returns the correct value";
}

sub test_strand_symbol {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'strand_symbol';
	
	is $test->get_testable_object(0)->strand_symbol, '-', "... and returns the correct value";
	is $test->get_testable_object(1)->strand_symbol, '-', "... and returns the correct value";
	is $test->get_testable_object(2)->strand_symbol, '+', "... and returns the correct value";
	is $test->get_testable_object(3)->strand_symbol, '+', "... and returns the correct value";
	is $test->get_testable_object(4)->strand_symbol, undef, "... and returns the correct value";
}

sub test_query_seq {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'query_seq';
	
	is $test->get_testable_object(0)->query_seq, 'CTAAGGAGTGTGTAACAACTCACCTGCCGAAT', "... and returns the correct value";
	is $test->get_testable_object(1)->query_seq, 'TGAAGCACAAAAGGACTTGGCCACTGTGAATACCAATCNATTTGATGAACCTGATGTAACAGAATTAAATCCATTTGGAGATCCTGACTCAGAAGAACCAA', "... and returns the correct value";
	is $test->get_testable_object(2)->query_seq, 'AGGAGCAGGAGAAAGGGCAACAGTGGAGGAGAGCAGCCTAGGCATGAGCTCTGGGAAGTCTAGCACACAGTTACTCCTGAAAGGGGCTTCCCGGAGCAGGA', "... and returns the correct value";
	is $test->get_testable_object(3)->query_seq, 'CAACACGTAAAGATCTATTTCAACGCTTCTTGCTTGTTTCTATATTGCTGAATACTAAGTAAGCCACATTGAAAAAGTAAAAGCAAGATTGCTTAGCTCTC', "... and returns the correct value";
	is $test->get_testable_object(4)->query_seq, 'TNNNNNNNNCCAAGTGAAAG', "... and returns the correct value";
}

sub test_query_length {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'query_length';
	
	is $test->get_testable_object(0)->query_length, 32, "... and returns the correct value";
	is $test->get_testable_object(1)->query_length, 101, "... and returns the correct value";
	is $test->get_testable_object(2)->query_length, 101, "... and returns the correct value";
	is $test->get_testable_object(3)->query_length, 101, "... and returns the correct value";
	is $test->get_testable_object(4)->query_length, 20, "... and returns the correct value";
}

sub test_tag {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'tag';
	
	is $test->get_testable_object(0)->tag('XT:A'), 'R', "... and returns the correct value";
	is $test->get_testable_object(0)->tag('NM:i'), 0, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('X0:i'), 2, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('X1:i'), 0, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('XM:i'), 0, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('XO:i'), 0, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('XG:i'), 0, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('MD:Z'), 32, "... and returns the correct value";
	is $test->get_testable_object(0)->tag('XA:Z'), 'chr9,+110183777,32M,0;chr8,+110183756,30M1I,0;',  "... and returns the correct value";
	is $test->get_testable_object(3)->tag('XT:A'), 'U',  "... and returns the correct value";
	
}

sub test_number_of_best_hits {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'number_of_best_hits';
	
	is $test->get_testable_object(0)->number_of_best_hits, 2, "... and returns the correct value";
	is $test->get_testable_object(1)->number_of_best_hits, 1, "... and returns the correct value";
	is $test->get_testable_object(2)->number_of_best_hits, 1, "... and returns the correct value";
	is $test->get_testable_object(3)->number_of_best_hits, 1, "... and returns the correct value";
	is $test->get_testable_object(4)->number_of_best_hits, 0, "... and returns the correct value";
}

sub test_number_of_suboptimal_hits {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'number_of_suboptimal_hits';
	
	is $test->get_testable_object(0)->number_of_suboptimal_hits, 0, "... and returns the correct value";
	is $test->get_testable_object(1)->number_of_suboptimal_hits, 0, "... and returns the correct value";
	is $test->get_testable_object(2)->number_of_suboptimal_hits, 0, "... and returns the correct value";
	is $test->get_testable_object(3)->number_of_suboptimal_hits, 0, "... and returns the correct value";
	is $test->get_testable_object(4)->number_of_suboptimal_hits, 0, "... and returns the correct value";
}

sub test_alternative_mappings {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'alternative_mappings';
	
	my @values = $test->get_testable_object(0)->alternative_mappings;
	is $values[0], 'chr9,+110183777,32M,0', "... and should return the correct value";
	is $values[1], 'chr8,+110183756,30M1I,0', "... and again";
}

sub test_insertion_count {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'insertion_count';
	
	is $test->get_testable_object(0)->insertion_count, 0, "... and returns the correct value";
	is $test->get_testable_object(1)->insertion_count, 1, "... and returns the correct value";
	is $test->get_testable_object(2)->insertion_count, 1, "... and returns the correct value";
	is $test->get_testable_object(3)->insertion_count, 0, "... and returns the correct value";
}

sub test_deletion_count {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'deletion_count';
	
	is $test->get_testable_object(0)->deletion_count, 0, "... and returns the correct value";
	is $test->get_testable_object(1)->deletion_count, 2, "... and returns the correct value";
	is $test->get_testable_object(2)->deletion_count, 2, "... and returns the correct value";
	is $test->get_testable_object(3)->deletion_count, 1, "... and returns the correct value";
}

sub test_deletion_positions_on_query {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'deletion_positions_on_query';
	
	is_deeply [$test->get_testable_object(0)->deletion_positions_on_query], [], "... and returns the correct value";
	is_deeply [$test->get_testable_object(1)->deletion_positions_on_query], [94], "... and returns the correct value";
	is_deeply [$test->get_testable_object(2)->deletion_positions_on_query], [35], "... and returns the correct value";
	is_deeply [$test->get_testable_object(3)->deletion_positions_on_query], [55], "... and returns the correct value";
}

sub test_deletion_positions_on_reference {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'deletion_positions_on_reference';
	
	is_deeply [$test->get_testable_object(0)->deletion_positions_on_reference], [], "... and returns the correct value";
	is_deeply [$test->get_testable_object(1)->deletion_positions_on_reference], [22051067,22051068], "... and returns the correct value";
	is_deeply [$test->get_testable_object(2)->deletion_positions_on_reference], [187239385,187239386], "... and returns the correct value";
	is_deeply [$test->get_testable_object(3)->deletion_positions_on_reference], [22985499], "... and returns the correct value";
}

sub test_mismatch_positions_on_reference {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'mismatch_positions_on_reference';
	
	is_deeply [$test->get_testable_object(0)->mismatch_positions_on_reference], [], "... and returns the correct value";
	is_deeply [$test->get_testable_object(1)->mismatch_positions_on_reference], [22051062,22051125], "... and returns the correct value";
	is_deeply [$test->get_testable_object(2)->mismatch_positions_on_reference], [187239361,187239398], "... and returns the correct value";
	is_deeply [$test->get_testable_object(3)->mismatch_positions_on_reference], [22985517,22985530,22985542,22985544], "... and returns the correct value";
	is_deeply [$test->get_testable_object(5)->mismatch_positions_on_reference], [22985516,22985529,22985541,22985543], "... and returns the correct value";
}

sub test_mismatch_positions_on_query {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'mismatch_positions_on_query';
	
	is_deeply [$test->get_testable_object(0)->mismatch_positions_on_query], [], "... and returns the correct value";
	is_deeply [$test->get_testable_object(1)->mismatch_positions_on_query], [100,38], "... and returns the correct value";
	is_deeply [$test->get_testable_object(2)->mismatch_positions_on_query], [12,48], "... and returns the correct value";
	is_deeply [$test->get_testable_object(3)->mismatch_positions_on_query], [73,86,98,100], "... and returns the correct value";
	is_deeply [$test->get_testable_object(5)->mismatch_positions_on_query], [73,86,98,100], "... and returns the correct value";
}

sub test_cigar_relative_to_query {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'cigar_relative_to_query';
	
	is $test->get_testable_object(0)->cigar_relative_to_query, '32M', "... and returns the correct value";
	is $test->get_testable_object(1)->cigar_relative_to_query, '95M2D3M1I2M', "... and returns the correct value";
	is $test->get_testable_object(2)->cigar_relative_to_query, '36M2D2M1I62M', "... and returns the correct value";
	is $test->get_testable_object(3)->cigar_relative_to_query, '56M1D45M', "... and returns the correct value";
	is $test->get_testable_object(4)->cigar_relative_to_query, '*', "... and again";
}

sub test_to_string {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'to_string';
	
	my $expected = join("\t", 'HWI-EAS235_25:1:1:4282:1093', '16', 'chr18', '85867636',
	'0', '32M', '*', '0', '0', 'ATTCGGCAGGTGAGTTGTTACACACTCCTTAG',
	'GHHGHHHGHHGGGDGEGHHHFHGG<GG>?BGG', 'XT:A:R', 'NM:i:0', 'X0:i:2', 'X1:i:0','XM:i:0',
	'XO:i:0',	'XG:i:0', 'MD:Z:32', 'XA:Z:chr9,+110183777,32M,0;chr8,+110183756,30M1I,0;');
	
	is $test->get_testable_object(0)->to_string, $expected, "... and returns the correct value";
}

sub test_is_mapped {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'is_mapped';
	
	is $test->get_testable_object(0)->is_mapped, 1, "... and returns the correct value";
	is $test->get_testable_object(1)->is_mapped, 1, "... and returns the correct value";
	is $test->get_testable_object(2)->is_mapped, 1, "... and returns the correct value";
	is $test->get_testable_object(3)->is_mapped, 1, "... and returns the correct value";
	is $test->get_testable_object(4)->is_mapped, 0, "... and again";
}

sub test_is_unmapped {
	my ($test) = @_;
	
	can_ok $test->get_testable_object(0), 'is_unmapped';
	
	is $test->get_testable_object(0)->is_unmapped, 0, "... and returns the correct value";
	is $test->get_testable_object(1)->is_unmapped, 0, "... and returns the correct value";
	is $test->get_testable_object(2)->is_unmapped, 0, "... and returns the correct value";
	is $test->get_testable_object(3)->is_unmapped, 0, "... and returns the correct value";
	is $test->get_testable_object(4)->is_unmapped, 1, "... and again";
}


#######################################################################
###############   Class method to create test objects   ###############
#######################################################################
sub _init_testable_objects {
	my ($test) = @_;
	
	return [$test->map_data_for_testable_objects(sub {$test->class_name->new($_)})];
}

sub _init_data_for_testable_objects {
	my ($test) = @_;
	
	my @data;
	
	push @data, {fields => ['HWI-EAS235_25:1:1:4282:1093', '16', 'chr18', '85867636', '0', '32M', '*', '0', '0', 'ATTCGGCAGGTGAGTTGTTACACACTCCTTAG', 'GHHGHHHGHHGGGDGEGHHHFHGG<GG>?BGG', 'XT:A:R', 'NM:i:0', 'X0:i:2', 'X1:i:0', 'XM:i:0', 'XO:i:0', 'XG:i:0', 'MD:Z:32', 'XA:Z:chr9,+110183777,32M,0;chr8,+110183756,30M1I,0;']};
	
	push @data, {fields => ['HWI-EAS235_32:2:20:11311:1509', '16', 'chr11', '22051063', '37', '2M1I3M2D95M', '*', '0', '0', 'TTGGTTCTTCTGAGTCAGGATCTCCAAATGGATTTAATTCTGTTACATCAGGTTCATCAAATNGATTGGTATTCACAGTGGCCAAGTCCTTTTGTGCTTCA', 'B>D>EEBGHGEGCGGHFCGEEFB@HFFFGFDAEC?C>G@EFBDD@DHHFHHGGB<D8>@@@/#869>EGGEG@<DGBH<EHHHHHHHHHHHDEG@EGGGFG', 'XT:A:U', 'NM:i:5', 'X0:i:1', 'X1:i:0', 'XM:i:4', 'XO:i:1', 'XG:i:1', 'MD:Z:0A4^AC56G38']};
	
	push @data, {fields => ['HWI-EAS235_32:2:20:9009:10694', '0', 'chr1', '187239350', '37', '36M2D2M1I62M', '*', '0', '0', 'AGGAGCAGGAGAAAGGGCAACAGTGGAGGAGAGCAGCCTAGGCATGAGCTCTGGGAAGTCTAGCACACAGTTACTCCTGAAAGGGGCTTCCCGGAGCAGGA', '4*24.7*0*9B;B=;9:2=0/531.+*288===>=@BB03=8*==?==/1A8@?@;8BB=8??=@1@688,7@89CCCCCCCCCAC6CC@CC@C@C<<@C9','XT:A:U', 'NM:i:5', 'X0:i:1', 'X1:i:0', 'XM:i:4', 'XO:i:1', 'XG:i:1', 'MD:Z:12G23^GT11A52']};
	
	push @data, {fields => ['HWI-EAS235_32:2:19:14059:2128', '0', 'chr5', '22985444', '37', '56M1D45M', '*', '0', '0', 'CAACACGTAAAGATCTATTTCAACGCTTCTTGCTTGTTTCTATATTGCTGAATACTAAGTAAGCCACATTGAAAAAGTAAAAGCAAGATTGCTTAGCTCTC', 'DDGE<EF8BFFGDDFHBGHHHHHHHGHH@GHHGHHD2@==FEEGEDBGGGGH@GFGDD@,EE8AAAACCCAAC;CA<8AE@;+)9<3:08<===<=*A>@5', 'XT:A:U', 'NM:i:5', 'X0:i:1', 'X1:i:0', 'XM:i:4', 'XO:i:1', 'XG:i:1', 'MD:Z:56^A17C12A11A1A0']};
	
	push @data, {fields => ['HWI-EAS235_32:1:1:7112:1235', '4', '*', '0', '0', '*', '*', '0', '0', 'TNNNNNNNNCCAAGTGAAAG', '?########20;<73@@B@@']};
	
	push @data, {fields => ['HWI-EAS235_32:2:19:14059:2128', '0', 'chr5', '22985444', '37', '101M', '*', '0', '0', 'CAACACGTAAAGATCTATTTCAACGCTTCTTGCTTGTTTCTATATTGCTGAATACTAAGTAAGCCACATTGAAAAAGTAAAAGCAAGATTGCTTAGCTCTC', 'DDGE<EF8BFFGDDFHBGHHHHHHHGHH@GHHGHHD2@==FEEGEDBGGGGH@GFGDD@,EE8AAAACCCAAC;CA<8AE@;+)9<3:08<===<=*A>@5', 'XT:A:U', 'NM:i:5', 'X0:i:1', 'X1:i:0', 'XM:i:4', 'XO:i:1', 'XG:i:1', 'MD:Z:73C12A11A1A0']};
	
	return \@data;
}

1;
