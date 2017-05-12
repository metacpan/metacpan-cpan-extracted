package Test::GenOOx::Data::File::SAM;

use base qw(Test::GenOOx);
use Test::Moose;
use Test::Most;


sub class {
	my ($self) = @_;
	
	return 'GenOO::Data::File::SAM';
}

#######################################################################
################   Startup (Runs once in the beginning  ###############
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
##########################   Initial Tests   ##########################
#######################################################################
sub _isa_test : Test(1) {
	my ($self) = @_;
	
	isa_ok $self->obj(0), $self->class, "... and the object";
}

#######################################################################
##########################   Interface Tests   ########################
#######################################################################
sub records_read_count : Test(5) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'records_read_count';
	is $self->obj(0)->records_read_count, 0, "... and should return the correct value";
	
	$self->obj(0)->next_record();
	is $self->obj(0)->records_read_count, 1, "... and should return the correct value again";
	
	$self->obj(0)->next_record();
	is $self->obj(0)->records_read_count, 2, "... and again";
	
	while ($self->obj(0)->next_record()) {}
	is $self->obj(0)->records_read_count, 977, "... and again (when the whole file is read)";
}

sub next_record : Test(2) {
	my ($self) = @_;
	
	can_ok $self->obj(0), 'next_record';
	isa_ok $self->obj(0)->next_record, 'GenOOx::Data::File::SAMstar::Record', "... and the returned object";
}

#######################################################################
###########################   Private Tests   #########################
#######################################################################
sub parse_record_line : Test(19) {
	my ($self) = @_;
	
	can_ok $self->obj(0), '_parse_record_line';
	
	my $sample_line = join("\t", 'HWI-ST628:553:C2GUNACXX:2:1114:7657:36948', '0', 'chr10', '59756187', '255', '29M', '*', '0', '0', 'CTGCCTGTCATCCTGGACATGATTAAGGG',                     'FHHHHGJJJJJIJIJJIIJJJHHJIJIJI', 'NH:i:1', 'HI:i:1', 'AS:i:28','nM:i:0', 'jM:B:c,-1', 'jI:B:i,-1');
	
	my $record = $self->obj(0)->_parse_record_line($sample_line);
	isa_ok $record, 'GenOOx::Data::File::SAMstar::Record', '... and object returned';
	is $record->qname, 'HWI-ST628:553:C2GUNACXX:2:1114:7657:36948', '... and should contain correct value';
	is $record->flag, '0', '... and should contain correct value again';
	is $record->rname, 'chr10', '... and again';
	is $record->pos, 59756187, '... and again';
	is $record->mapq, '255', '... and again';
	is $record->cigar, '29M', '... and again';
	is $record->rnext, '*', '... and again';
	is $record->pnext, 0, '... and again';
	is $record->tlen, 0, '... and again';
	is $record->seq, 'CTGCCTGTCATCCTGGACATGATTAAGGG', '... and again';
	is $record->qual, 'FHHHHGJJJJJIJIJJIIJJJHHJIJIJI', '... and again';
	is $record->tag('NH:i'), '1', '... and again';
	is $record->tag('HI:i'), '1', '... and again';
	is $record->tag('AS:i'), '28', '... and again';
	is $record->tag('nM:i'), '0', '... and again';
	is $record->tag('jM:B'), 'c,-1', '... and again';
	is $record->tag('jI:B'), 'i,-1', '... and again';
}


#######################################################################
###############   Class method to create test objects   ###############
#######################################################################
sub test_objects {
	my ($test_class) = @_;
	
	eval "require ".$test_class->class;
	
	my @test_objects;
	push @test_objects, $test_class->class->new(
		file          => 't/sample_data/sample.sam.gz',
		records_class => 'GenOOx::Data::File::SAMstar::Record'
	);
	
	return \@test_objects;
}

1;
