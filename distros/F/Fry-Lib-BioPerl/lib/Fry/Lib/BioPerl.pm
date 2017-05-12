package Fry::Lib::BioPerl;

use strict;
#use Benchmark qw/:all/;
use Time::HiRes qw/tv_interval gettimeofday/;
use Bio::SeqIO;
use Bio::AlignIO;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::Tools::Run::Alignment::TCoffee;
use Bio::DB::GenBank;
#use Bio::Graphics;
#Bio::Seq::RichSeq;
#Bio::Graphics::Feature;
	
our $VERSION = 0.15;
our $Verbose = 1;
$Bio::Root::Root::DEBUG = 0;

#these are defaults
our $seqio_file = "$ENV{HOME}/.cpanplus/5.8.1/build/bioperl-1.4/t/data/test.genbank";
#our $seqio_file = "t/data/test.genbank";
our $seqio_format = "genbank";
our $alnio_format =  "clustalw";
our $alnio_file = "$ENV{HOME}/.cpanplus/5.8.1/build/bioperl-1.4/t/data/testaln.aln";
#our $alnio_file = "t/data/testaln.aln";
our $default_seqio = "seqio1";
our $default_alnio = "alnio1";
our %clustal_params = (qw/matrix BLOSUM/);
our %tcoffee_params = ();
our %db_genbank_params = ();
my $seqcount = 0;
my $alncount = 0;
#hackish variable
our %temp;

sub _default_data {
	return {
		cmds=>{
			readSeq=>{qw/a brs/,d=>'Read a sequence from a file',
				u=>'$format$file$obj'},
			readAln=>{qw/a bra/,d=>'Read an alignment from a file',
				u=>'$format$file$obj'},
			startClustalw=>{qw/a bsc/,d=>'Initialize clustalw',u=>'%options'},
			startTCoffee=>{qw/a bst/,d=>'Initialize tcoffee',u=>'%options'},
			startDB=>{qw/a bsd/,d=>'Initialize database',u=>'%options'},
			clustalAlign=>{qw/a bca/,d=>'Align with clustalw',u=>'@seq'},
			tcoffeeAlign=>{qw/a bta/,d=>'Align with tcoffee',u=>'@seq'},	
			compareAlign=>{qw/a bcom/,d=>'Compare two alignment methods',
				u=>'@seq'},
			alnioFormat=>{qw/a baf/,d=>'Change alnioout format',u=>'$format'},
			seqioFormat=>{qw/a bsf/,d=>'Change seqioout format',u=>'$format'},
			listSeqs=>{qw/a bls/,d=>'Read all sequences from a file',
				u=>'$seqio'},
			#nextSeq=>{qw/a ,/,d=>'Get the next Seq'},
			writeAln=>{qw/a bwa/,d=>'Write alignments',u=>'@aln'},
			displayAln=>{qw/a bda/,d=>'Display alignment info',u=>'@aln'},
			getAlnSeqs=>{qw/a bas/,d=>'Save alignment seqs',u=>'$aln'},
			writeSeq=>{qw/a bws/,d=>'Write sequences',u=>'@seq'},
			translateSeq=>{qw/a bts/,d=>'Translate sequences',u=>'$seq'},
			revcomSeq=>{qw/a bts/,d=>'Reverse complement sequences',u=>'$seq'},
			getSeqById=>{qw/a bgsi/,d=>'Get sequence by id',u=>'$id'},
			#featureImage=>{qw/a bfi/,d=>''},
			libCmdAttr=>{qw/a lca/,d=>"Display a library's cmds' attributes",
				u=>'$attr$lib'},
		},
		objs=>{
			#seqio1=>{}
		}
	}	
}
sub _initLib {
	my ($cls) = @_;
	#reads in sequence file
	$cls->newSeqIoInObj;
	#sequence output
	$cls->newSeqIoObj('seqioout',-fh=>\*STDOUT,-format=>$seqio_format);
	#alignment output
	$cls->newAlnIoObj('alnioout',-fh=>\*STDOUT,-format=>$alnio_format);
}

#new*Obj
	#these methods create objects and index them as Fry::Obj objects as well
	sub newSeqIoInObj {
		my ($cls,%arg) = @_;

		#defaults
		my $objId = delete $arg{obj} || $default_seqio;
		$arg{-file} = $arg{-file} || $seqio_file;
		$arg{-format} = $arg{-format} || $seqio_format;

		$cls->newSeqIoObj($objId,%arg);

		#index seqs of seqio
		my ($id,@ids);
		my @newSeqs = $cls->ripStream($cls->obj->get($objId,'obj'));
		for (@newSeqs) { 
			$id = $cls->newSeqObj($_);
			push(@ids,$id);
		}
		$cls->obj->set($objId,seqs=>\@ids);
	}
	sub newSeqIoObj {
		my ($cls,$objId,%arg) = @_;
		#print Dumper \%arg;

		my $obj =  $cls->seqioNew(%arg) ; 
		$cls->obj->setOrMake($objId=>$obj);
	}
	sub newSeqObj {
		my ($cls,$obj) = @_;
		$seqcount++;
		my $id = "seq$seqcount";
		$cls->obj->manyNew($id=>{obj=>$obj}); 
		$cls->view("Created sequence '$id'\n") if ($Verbose);
		return $id;
	}
	sub newAlnObj {
		my ($cls,$obj) = @_;
		$alncount++;
		my $id = "aln$alncount";
		$cls->obj->manyNew($id=>{obj=>$obj}); 
		$cls->view("Created alignment '$id'\n") if ($Verbose);
		return $id;
	}
	sub newAlnIoObj {
		my ($cls,$objId,%arg) = @_;
		my $obj =  $cls->alnioNew(%arg) ; 
		$cls->obj->setOrMake($objId=>$obj);
	}
	sub newAlnIoInObj {
		my ($cls,%arg) = @_;
		my $objId = delete $arg{obj} || $default_alnio;
		$arg{-file} = $arg{-file} || $alnio_file;
		delete $arg{-format};
		#$arg{-format} = $arg{-format} || "clustalw";

		$cls->newAlnIoObj($objId,%arg);

		#index seqs of seqio
		my ($id,@ids);
		my @newAlns = $cls->ripStream($cls->obj->get($objId,'obj'));
		for (@newAlns) {
			$id = $cls->newAlnObj($_);
			push(@ids,$id);
		}
		$cls->obj->set($objId,alns=>\@ids);
	}
#wrappers around classes to easily substitute your own subclasses of any of these
	sub seqioNew { shift; return Bio::SeqIO->new(@_) }
	sub alnioNew { shift; return Bio::AlignIO->new(@_) }
	sub biodbNew { shift; return Bio::DB::GenBank->new(@_) }
	sub clustalwNew { shift; return Bio::Tools::Run::Alignment::Clustalw->new(@_) }
	sub tcoffeeNew { shift; return Bio::Tools::Run::Alignment::TCoffee->new(@_) }
	sub objObj { shift->obj->get($_[0],'obj') }
#commands
	#h: will probably break in other releases
	sub libCmdAttr {
		my ($cls,$attr) = @_;
		my $lib = "Fry::Lib::BioPerl";

		my @ids =  @{$cls->lib->get($lib,'cmds') };
		$cls->printGeneralAttr('cmd',$attr,@ids);
	}
#constructors
	sub readSeq {
		#d: initializes $seqio
		my ($cls,$format,$file,$objId) = @_;
		$cls->newSeqIoInObj(-file=>$file,-format=>$format,obj=>$objId);
	}
	sub readAln {
		my ($cls,$format,$file,$objId) = @_;
		$cls->newAlnIoInObj(-file=>$file,-format=>$format,obj=>$objId);
	}
	sub startClustalw {
		my ($cls,%arg) = @_;
		#$cls->verify_params(\%arg);
		my %params = (%clustal_params,%arg);
		my $obj = $cls->clustalwNew(%params);
		$cls->obj->manyNew('cw'=>{obj=>$obj}); 
	}
	sub startDB {
		my ($cls,%arg) = @_;
		my %params = (%db_genbank_params,%arg);
		my $obj = $cls->biodbNew(%params);
		$cls->obj->manyNew('db1'=>{obj=>$obj}); 
	}
	sub startTCoffee {
		my ($cls,%arg) = @_;
		my %params = (%tcoffee_params,%arg);
		my $obj = $cls->tcoffeeNew(%params);
		$cls->obj->manyNew('tc'=>{obj=>$obj}); 
	}
#Alignment
	##$tcoffee
	sub tcoffeeAlign {
		my ($cls,@seqs) = @_;
		@seqs = $cls->idToObj(@seqs);

		my $t0= [ gettimeofday()];
		my $alnobj = $cls->obj->get('tc','obj')->align(\@seqs);
		my $elapsed = tv_interval($t0);
		$cls->newAlnObj($alnobj);
		$temp{tc} = {time=>$elapsed,alnid=>"aln$alncount"};

		$cls->view("This alignment took $elapsed seconds\n") if $Verbose;
	}
	##$clustalw
	sub clustalAlign {
		my ($cls,@seqs) = @_;
		@seqs = $cls->idToObj(@seqs);

		my $t0= [ gettimeofday()];
		my $alnobj = $cls->obj->get('cw','obj')->align(\@seqs);
		my $elapsed = tv_interval($t0);
		$cls->newAlnObj($alnobj);
		$temp{cw} = {time=>$elapsed,alnid=>"aln$alncount"};

		$cls->view("This alignment took $elapsed seconds\n") if $Verbose;
	}
	##macros
	sub compareAlign {
		my ($cls,@seqs) = @_;
		@seqs = $cls->idToObj(@seqs);

		$cls->clustalAlign(@seqs);
		$cls->tcoffeeAlign(@seqs);

		$cls->view("Alignment from Clustalw\n");
		$cls->view("------------------------------------\n");
		$cls->displayAln($temp{cw}{alnid});
		$cls->view("Time: ",$temp{cw}{time},"\n");
		$cls->view("\nAlignment from TCoffee\n");
		$cls->view("------------------------------------\n");
		$cls->displayAln($temp{tc}{alnid});
		$cls->view("Time: ",$temp{tc}{time},"\n");
	}
#IO
	##$alignio
	sub alnioFormat {
		my ($cls,$format) = @_;
		$format ||= $alnio_format;
		$cls->newAlnIoObj('alnioout',-fh=>\*STDOUT,-format=>$format);
	}
	##$seqio
	sub seqioFormat {
		my ($cls,$format) = @_;
		$format ||= $seqio_format;
		$cls->newSeqIoObj('seqioout',-fh=>\*STDOUT,-format=>$format);
	}
#Sequences
	##$biodb
	sub getSeqById {
		my ($cls,$id) = @_;
		my $method = "get_Seq_by_id";
		my $seq = $cls->objObj('db1')->$method($id);
		$cls->newSeqObj($seq);
	}
	##$seq
	sub listSeqs {
		#d: readSeqs
		my ($cls,$seqioId) = @_;
		$seqioId ||= $default_seqio;
		my @seqs = @{$cls->obj->get($seqioId,'seqs') || []};
		my $output = "Sequence ids of $seqioId are:\n";
		$output .= $cls->seqIds(map {$cls->obj->get($_,'obj')} @seqs);
		$cls->view($output);
	}
	sub translateSeq {
		my ($cls,$seqId) = @_;
		my $seqObj = $cls->obj->get($seqId,'obj')->translate;
		$cls->newSeqObj($seqObj);
	}
	sub revcomSeq {
		my ($cls,$seqId) = @_;
		my $seqObj = $cls->obj->get($seqId,'obj')->revcom;
		$cls->newSeqObj($seqObj);
	}
	sub writeSeq {
		my ($cls,@seqs) = @_;
		@seqs = $cls->idToObj(@seqs);
		for my $seq (@seqs) {
			$cls->obj->get(seqioout=>'obj')->write_seq($seq);
		}
	}
#Alignments
	##$aln
	#add,remove,indexSeq,slice,remove_gaps,map_chars
	sub displayAln {
		my ($cls,@alns) = @_;
		@alns = $cls->idToObj(@alns);
		my %methods = (score=>'Score',consensus_string=>'Consensus string',
			length=>'Length',no_residues=>'Number of residues',
			no_sequences=>'Number of sequences',percentage_identity=>'Percentage identity');
		my $output;

		for my $aln (@alns) {
			for my $m (sort keys %methods) {
				$output .= $methods{$m}.": ". $aln->$m
				."\n";
			}
		}
		$cls->view($output);
	}
	sub getAlnSeqs {
		my ($cls,$alnId) = @_;
		my $aln = $cls->objObj($alnId);
		my @ids;

		for my $seq ($aln->each_seq) { push(@ids,$cls->newSeqObj($seq)) }
		#for my $seq ($aln->each_seq) {
			#my $obj = Bio::Seq->new(-display_id=>$seq->{display_id},-seq=>$seq->{seq});
			##print "s: ",$seq->{seq},"\n";
			#push(@ids,$cls->newSeqObj($obj)) 
		#}
		$cls->obj->set($alnId,seqs=>\@ids);
	}
	sub writeAln {
		my ($cls,@alns) = @_;
		@alns = $cls->idToObj(@alns);
		for my $aln (@alns) {
			$cls->obj->get(alnioout=>'obj')->write_aln($aln);
		}
	}
	##misc
	sub seqIds {
		my ($cls,@seqs) = @_;
		my $output;

		if (@seqs > 0) {
			for my $seq  (@seqs) {
				$output .= sprintf "%s\n", $seq->display_id;
			}
		}
		else { $output = "No sequences to display." }
		return $output;
	}
	sub idToObj {
		my ($cls,@idOrObj) = @_;
		my @return;
		if (ref $idOrObj[0]) {
			@return = @idOrObj;
		}
		else { @return = map { $cls->obj->get($_,'obj') } @idOrObj }
		wantarray ? @return : $return[0];
	}
	#d: all Bio::*IO can use this
	sub ripStream { my $fh = $_[1]->fh; my @seqs = <$fh>; return @seqs }
1;
__END__
#my old crap code
	sub nextSeq {
		my ($cls,$seqio) = @_;

		#td?: history of used seq
		$seqio ||= $default_seqio;
		my $seq = $cls->obj->get($seqio,'obj')->next_seq or do {warn("failed next_seq(): $@") ; return};
		#my $seq = $seqio->next_seq or do {warn("failed next_seq(): $@") ; return};
		#print $seq->seq,"\n"; $out->write_seq($seq);
		$cls->writeSeq($seq);
	}
	sub parseArgs { 
		my $cls = shift;
		my ($seqio1,$seqio2);
		if (ref $_[0] =~ /Bio::/) {
		}
		#elsif ($_[0] =~ /(file|format)[12]/) {
		#}
		else { ($seqio1,$seqio2) = ($in,$out) }
		return ($seqio1,$seqio2);
	}
	sub featureImage {
		my ($cls,$seq) = @_;
		$seq = $cls->idToObj($seq);
 my @features = $seq->all_SeqFeatures;

 # sort features by their primary tags
 my %sorted_features;
 for my $f (@features) {
   my $tag = $f->primary_tag;
   push @{$sorted_features{$tag}},$f;
 }

 my $wholeseq = Bio::SeqFeature::Generic->new(-start=>1,-end=>$seq->length);

 my $panel = Bio::Graphics::Panel->new(
				      -length    => $seq->length,
 				      -key_style => 'between',
 				      -width     => 800,
 				      -pad_left  => 10,
 				      -pad_right => 10,
 				      );
 $panel->add_track($wholeseq,
 		  -glyph => 'arrow',
 		  -bump => 0,
 		  -double=>1,
 		  -tick => 2);

 $panel->add_track($seq,
 		  -glyph  => 'generic',
 		  -bgcolor => 'blue',
 		  -label  => 1,
 		 );

 # general case
 my @colors = qw(cyan orange blue purple green chartreuse magenta yellow aqua);
 my $idx    = 0;
 for my $tag (sort keys %sorted_features) {
   my $features = $sorted_features{$tag};
   $panel->add_track($features,
 		    -glyph    =>  'generic',
 		    -bgcolor  =>  $colors[$idx++ % @colors],
 		    -fgcolor  => 'black',
 		    -font2color => 'red',
 		    -key      => "${tag}s",
 		    -bump     => +1,
 		    -height   => 8,
 		    -label    => 1,
 		    -description => 1,
 		   );
 }
	}


=head1 NAME

Fry::Lib::BioPerl -  Commandline enables common tasks for sequence and alignment objects for Bio::Perl modules.

=head1 DESCRIPTION 

The main point of this library is to view,retrieve and create sequences and alignments.
All objects created are indexed by the shell as Fry::Obj objects. See
L<Fry::Lib::Default> for commands that you can perform on these objects.

Sequence and alignment objects created are automatically named with an
abbreviation followed by an incremental number ie seq1 and seq2
for sequences and aln1 and aln2 for alignments. Not all classes have unique
objects. Bio::DB::GenBank only has one object and its getSeqById command assume this.
This can of course be changed. Classes that have commands to create and index
more than one of its objects are Bio::Seq derived classes, Bio::SimpleAlign,
Bio::SeqIO and Bio::AlignIO.

=head1 DIRECTIONS

To load this library read the Using Libraries subsection of L<Fry::Shell>.

After loading this library, &_initLib will be called. This creates a Bio::SeqIO
object for sequence output, a Bio::AlignIO for alignment output and reads in a sequence file
to create Bio::Seq::RichSeq objects. The default sequence file assumes you're
in the installation directory of a bio-perl bundle since it uses a file in
t/. If any one the default actions don't work, just comment it out in
&_initLib.

=head1 REQUIREMENTS

You should install the bioperl-1.4 bundle. Time::HiRes and the bioperl-run
bundle are used by some of the commands but comment them out if you don't have
them and want to try other commands.

=head1 COMMANDS

	Note: Brief explanation of what some names mean in a command's usage:
		seq- sequence object or its Fry::Obj id
		aln- a Bio::SimpleAlign object or its Fry::Obj id
		seqio- Bio::SeqIO object or its Fry::Obj id
		alnio- a Bio::AlignIO object or its Fry::Obj id

	Constructors: Creates objects to be used by other commands

		readSeq($file,$format,$object_name): Reads a sequence file, creates a
			Bio::SeqIO object and then creates and indexes its sequence objects.
		readAln($file,$format,$object_name): Reads an alignment file, creates a
			Bio::AlignIO object and then creates and indexes its alignment objects.
		startClustalw(%options): Creates a
			Bio::Tools::Run::Alignment::ClustalW object with given options.
			Default options are specified by %clustal_params.
		startTCoffee(%options): Creates a
			Bio::Tools::Run::Alignment::TCoffee object with given options.
			Default options are specified by %tcoffee_params.
		startDB(%options): Creates a Bio::DB::GenBank object with given
			options. Default options are defined by %db_genbank_params.
	
	IO
		alnioFormat($format): Changes format of alignment output.
		seqioFormat($format): Changes format of sequence output.

	Sequence based
		listSeqs($seqio): Displays sequence ids belonging to a file.
		writeSeq(@seq): Displays sequences via SeqIO.
			`listSeqs seq1 seq3`
		translateSeq($seq): Translates sequence, creating new sequence object.
		revcomSeq($seq): Reverse complements sequence, creating new sequence object.
		getSeqById($id): Calls &get_Seq_by_id on a Bio::DB::GenBank object to
			retrieve a sequence.

	General Alignment
		writeAln(@aln): Displays alignments via AlignIO.
		displayAln(@aln): Custom display of alignments.
		getAlnSeqs(@aln): Creates sequence objects from alignment objects.
		Alignment

	Special Alignment
		clustalAlign(@seq): Calls &align on ClustalW object, creating an alignment object.
		tcoffeeAlign(@seq): Calls &align on TCoffee object, creating an alignment object.
		compareAlign(@seq): Times alignments made by TCoffee and ClustalW and
			displays resulting alignments.
	Other
		libCmdAttr($cmd_attribute): See a command attribute for only :BioPerl
			commands.

=head1 MOTIVATION AND MAINTENANCE

I wrote this library for a Bioinformatics class. Since I won't to be doing any
bioinformatics in the forseeable future, it's unlikely I'll add more to this
library. However, since I'm very interested in making a fully featured shell,
more functionality will appear in this shell to make writing commands
easier. Ideally, I'd like most of these library commands to be replaced by a
config file. 

If you want to expand this library, send me patches. I can also pass over ownership
of this module.  You can also write your own library. But beware that the library and scripting
APIs are still changing.

=head1 SEE ALSO

L<Fry::Shell>, L<Bio::Perl>


=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004-2005, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

