package Test::GenOOx::Data::File::SAMstar::Record;
use strict;

use base qw(Test::GenOOx);
use Test::Moose;
use Test::Most;

#######################################################################
################   Startup (Runs once in the begining  ################
#######################################################################
sub _check_loading : Test(startup => 1) {
	my ($self) = @_;
	use_ok $self->class;
};

#######################################################################
#################   Setup (Runs before every method)  #################
#######################################################################
sub create_new_test_objects : Test(setup) {
	my ($self) = @_;
	
	my $test_class = ref($self) || $self;
	$self->{TEST_OBJECTS} = $test_class->test_objects();
};

#######################################################################
###########################   Actual Tests   ##########################
#######################################################################
sub _isa_test : Test(1) {
	my ($self) = @_;
	
	isa_ok $self->obj(0), $self->class, "... and the object";
}

sub qname : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'qname';
	is $self->obj(0)->qname, 'HWI-ST628:553:C2GUNACXX:2:1114:7657:36948', "... and returns the correct value";
}

sub flag : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'flag';
	is $self->obj(0)->flag, 0, "... and returns the correct value";
}

sub rname : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'rname';
	is $self->obj(0)->rname, 'chr10', "... and returns the correct value";
}

sub pos : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'pos';
	is $self->obj(0)->pos, 59756187, "... and returns the correct value";
}

sub mapq : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'mapq';
	is $self->obj(0)->mapq, 255, "... and returns the correct value";
}

sub cigar : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'cigar';
	is $self->obj(0)->cigar, '29M', "... and returns the correct value";
}

sub rnext : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'rnext';
	is $self->obj(0)->rnext, '*', "... and returns the correct value";
}

sub pnext : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'pnext';
	is $self->obj(0)->pnext, 0, "... and returns the correct value";
}

sub tlen : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'tlen';
	is $self->obj(0)->tlen, 0, "... and returns the correct value";
}

sub seq : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'seq';
	is $self->obj(0)->seq, 'CTGCCTGTCATCCTGGACATGATTAAGGG', "... and returns the correct value";
}

sub qual : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'qual';
	is $self->obj(0)->qual, 'FHHHHGJJJJJIJIJJIIJJJHHJIJIJI', "... and returns the correct value";
}

sub tags : Test(1) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'tags';
}

sub alignment_length : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'alignment_length';
	is $self->obj(0)->alignment_length, 29, "... and returns the correct value";
}

sub start : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'start';
	is $self->obj(0)->start, 59756186, "... and returns the correct value";
	is $self->obj(1)->start, 136877060, "... and returns the correct value";
	is $self->obj(2)->start, 43811810, "... and returns the correct value";
}

sub stop : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'stop';
	is $self->obj(0)->stop, 59756214, "... and returns the correct value";
	is $self->obj(1)->stop, 136877088, "... and returns the correct value";
	is $self->obj(2)->stop, 43811838, "... and returns the correct value";
}

sub strand : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'strand';
	is $self->obj(0)->strand, 1, "... and returns the correct value";
	is $self->obj(1)->strand, -1, "... and returns the correct value";
	is $self->obj(2)->strand, -1, "... and returns the correct value";
}

sub strand_symbol : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'strand_symbol';
	
	is $self->obj(0)->strand_symbol, '+', "... and returns the correct value";
	is $self->obj(1)->strand_symbol, '-', "... and returns the correct value";
	is $self->obj(2)->strand_symbol, '-', "... and returns the correct value";
}

sub query_seq : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'query_seq';
	
	is $self->obj(0)->query_seq, 'CTGCCTGTCATCCTGGACATGATTAAGGG', "... and returns the correct value";
	is $self->obj(1)->query_seq, 'TTTGATGAAGCAATATTGGCTGCCCTGGA', "... and returns the correct value";
	is $self->obj(2)->query_seq, 'TTTGATGAAGCAATATTGGCTGCCCTGGA', "... and returns the correct value";
}

sub query_length : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'query_length';
	
	is $self->obj(0)->query_length, 29, "... and returns the correct value";
	is $self->obj(1)->query_length, 29, "... and returns the correct value";
	is $self->obj(2)->query_length, 29, "... and returns the correct value";
}

sub tag : Test(7) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'tag';
	
	is $self->obj(0)->tag('NH:i'), 1, "... and returns the correct value";
	is $self->obj(0)->tag('HI:i'), 1, "... and returns the correct value";
	is $self->obj(0)->tag('AS:i'), 28, "... and returns the correct value";
	is $self->obj(0)->tag('nM:i'), 0, "... and returns the correct value";
	is $self->obj(0)->tag('jM:B'), 'c,-1', "... and returns the correct value";
	is $self->obj(0)->tag('jI:B'), 'i,-1', "... and returns the correct value";
}

sub number_of_mappings : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'number_of_mappings';
	
	is $self->obj(0)->number_of_mappings, 1, "... and returns the correct value";
	is $self->obj(1)->number_of_mappings, 4, "... and returns the correct value";
	is $self->obj(2)->number_of_mappings, 4, "... and returns the correct value";
}

sub is_uniquelly_mapped : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'is_uniquelly_mapped';
	
	is $self->obj(0)->is_uniquelly_mapped, 1, "... and returns the correct value";
	is $self->obj(1)->is_uniquelly_mapped, 0, "... and returns the correct value";
	is $self->obj(2)->is_uniquelly_mapped, 0, "... and returns the correct value";
}

sub is_primary_alignment : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'is_primary_alignment';
	
	is $self->obj(0)->is_primary_alignment, 1, "... and returns the correct value";
	is $self->obj(1)->is_primary_alignment, 1, "... and returns the correct value";
	is $self->obj(2)->is_primary_alignment, 0, "... and returns the correct value";
}

sub is_secondary_alignment : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'is_secondary_alignment';
	
	is $self->obj(0)->is_secondary_alignment, 0, "... and returns the correct value";
	is $self->obj(1)->is_secondary_alignment, 0, "... and returns the correct value";
	is $self->obj(2)->is_secondary_alignment, 1, "... and returns the correct value";
}

sub insertion_count : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'insertion_count';
	
	is $self->obj(0)->insertion_count, 0, "... and returns the correct value";
	is $self->obj(1)->insertion_count, 0, "... and returns the correct value";
	is $self->obj(2)->insertion_count, 0, "... and returns the correct value";
}

sub deletion_count : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'deletion_count';
	
	is $self->obj(0)->deletion_count, 0, "... and returns the correct value";
	is $self->obj(1)->deletion_count, 0, "... and returns the correct value";
	is $self->obj(2)->deletion_count, 0, "... and returns the correct value";
}

sub deletion_positions_on_query : Test(1) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'deletion_positions_on_query';
}

sub deletion_positions_on_reference : Test(1) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'deletion_positions_on_reference';
}

sub mismatch_positions_on_reference : Test(1) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'mismatch_positions_on_reference';
}

sub mismatch_positions_on_query : Test(1) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'mismatch_positions_on_query';
}

sub cigar_relative_to_query : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'cigar_relative_to_query';
	
	is $self->obj(0)->cigar_relative_to_query, '29M', "... and returns the correct value";
	is $self->obj(1)->cigar_relative_to_query, '29M', "... and returns the correct value";
	is $self->obj(2)->cigar_relative_to_query, '29M', "... and returns the correct value";
}

sub to_string : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'to_string';
	
	my $expected = join("\t", 'HWI-ST628:553:C2GUNACXX:2:1114:7657:36948', '0', 'chr10', '59756187', '255', '29M', '*', '0', '0', 'CTGCCTGTCATCCTGGACATGATTAAGGG', 'FHHHHGJJJJJIJIJJIIJJJHHJIJIJI', 'NH:i:1', 'HI:i:1', 'AS:i:28', 'nM:i:0', 'jM:B:c,-1', 'jI:B:i,-1');
	
	is $self->obj(0)->to_string, $expected, "... and returns the correct value";
}

sub is_mapped : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'is_mapped';
	
	is $self->obj(0)->is_mapped, 1, "... and returns the correct value";
	is $self->obj(1)->is_mapped, 1, "... and returns the correct value";
	is $self->obj(2)->is_mapped, 1, "... and returns the correct value";
}

sub is_unmapped : Test(4) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'is_unmapped';
	
	is $self->obj(0)->is_unmapped, 0, "... and returns the correct value";
	is $self->obj(1)->is_unmapped, 0, "... and returns the correct value";
	is $self->obj(2)->is_unmapped, 0, "... and returns the correct value";
}

#######################################################################
###############   Class method to create test objects   ###############
#######################################################################
sub test_objects {
	my ($test_class) = @_;
	
	eval "require ".$test_class->class;
	
	my @test_objects;
	
	push @test_objects, $test_class->class->new(fields => ['HWI-ST628:553:C2GUNACXX:2:1114:7657:36948', '0', 'chr10', '59756187', '255', '29M', '*', '0', '0', 'CTGCCTGTCATCCTGGACATGATTAAGGG', 'FHHHHGJJJJJIJIJJIIJJJHHJIJIJI', 'NH:i:1', 'HI:i:1', 'AS:i:28', 'nM:i:0', 'jM:B:c,-1', 'jI:B:i,-1']);
	
	push @test_objects, $test_class->class->new(fields => ['HWI-ST628:553:C2GUNACXX:2:1114:8476:36869', '16', 'chr4', '136877061', '1', '29M', '*', '0', '0', 'TCCAGGGCAGCCAATATTGCTTCATCAAA', 'IHGIIHGHJIIIGHHC<AHFJJJHHHHHF', 'NH:i:4', 'HI:i:1', 'AS:i:28', 'nM:i:0', 'jM:B:c,-1', 'jI:B:i,-1']);
	
	push @test_objects, $test_class->class->new(fields => ['HWI-ST628:553:C2GUNACXX:2:1114:8476:36869', '272', 'chr4', '43811811', '1', '29M', '*', '0', '0', 'TCCAGGGCAGCCAATATTGCTTCATCAAA', 'IHGIIHGHJIIIGHHC<AHFJJJHHHHHF', 'NH:i:4', 'HI:i:2', 'AS:i:28', 'nM:i:0', 'jM:B:c,-1', 'jI:B:i,-1']);
	return \@test_objects;
}

1;
