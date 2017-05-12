package Lingua::Align::Corpus::Parallel::OPUS;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel::STA);

use FileHandle;
use File::Basename;

use XML::Parser;
use Lingua::Align::Corpus::Parallel;
use Lingua::Align::Corpus::Parallel::STA;



sub read_next_alignment{
    my $self=shift;
    my ($srcsent,$trgsent,$links)=@_;

    my $file=$_[3] || $self->{-alignfile};
    my $readmax = $self->{-read_max_sentences} || 1000;


    if (! defined $self->{FH}->{$file}){
	$self->{FH}->{$file} = $self->open_file($file);
	$self->{__XMLPARSER__} = new XML::Parser(Handlers => 
						 {Start => \&__XMLTagStart});
	$self->{__XMLHANDLE__} = $self->{__XMLPARSER__}->parse_start;

	# swap sentencee alignments
	if ($self->{-swap_alignment}){
	    $self->{__XMLHANDLE__}->{SWAP_ALIGN}=1;
	}


    }

    my $fh=$self->{FH}->{$file};
    my $OldDel=$/;

    $/='>';
    while (<$fh>){
	eval { $self->{__XMLHANDLE__}->parse_more($_); };
	$/=$OldDel;
	if ($@){
	    warn $@;
	    print STDERR $_;
	}

	if ((defined $self->{__XMLHANDLE__}->{FROMDOC}) && 
	    (defined $self->{__XMLHANDLE__}->{TODOC})){
	    my %attr=();
	    $attr{-src_type}=$self->{-src_type} || 'XML';
	    $attr{-trg_type}=$self->{-trg_type} || 'XML';
	    $attr{-src_file}=$self->{-src_file} || 
		__find_corpus_file($self->{__XMLHANDLE__}->{FROMDOC},$file);
	    $attr{-trg_file}=$self->{-trg_file} || 
		__find_corpus_file($self->{__XMLHANDLE__}->{TODOC},$file);

	    $self->make_corpus_handles(%attr);
	    $self->{FROMDOC}=$self->{__XMLHANDLE__}->{FROMDOC};
	    $self->{TODOC}=$self->{__XMLHANDLE__}->{TODOC};
	    delete $self->{__XMLHANDLE__}->{FROMDOC};
	    delete $self->{__XMLHANDLE__}->{TODOC};
	}

	if (ref($self->{__XMLHANDLE__}->{SRCSENT}) eq 'ARRAY'){
	    if (ref($self->{__XMLHANDLE__}->{TRGSENT}) eq 'ARRAY'){

		my @src = @{$self->{__XMLHANDLE__}->{SRCSENT}};
		my @trg = @{$self->{__XMLHANDLE__}->{TRGSENT}};

		if (($#src != 0) || ($#trg != 0)){
		    if ($self->{-verbose}){
			print STDERR "only 1:1 alignments allowed!\n";
			print STDERR "skip ";
			print STDERR join('+',@src);
			print STDERR " <--> ";
			print STDERR join('+',@trg);
			print STDERR "\n";
		    }
		    next;
		}

		# check if one of the next 50 sentence IDs would be the one
		# that we try to read

		my $srcok=0;
		for (0..$readmax){
		    my $id = $self->{SRC}->next_sentence_id_would_be($_);
		    if ($id eq $src[0]){$srcok=1;}
		    elsif (not defined $id){$srcok=1;}  # no info about IDs
		    last if ($srcok);
		}
		my $trgok=0;
		for (0..$readmax){
		    my $id = $self->{TRG}->next_sentence_id_would_be($_);
		    if ($id eq $trg[0]){$trgok=1;}
		    elsif (not defined $id){$trgok=1;}  # no info about IDs
		    last if ($trgok);
		}


		# read next sentences until I reach the aligned ones

		if ($srcok && $trgok){
		    my $count=0;
		    do {
			$count++;
			last if ($count>$readmax);
			$self->{SRC}->next_sentence($srcsent);
			if ($$srcsent{ID}>$src[0]){
			    if ($self->{-verbose}){
				print STDERR "src: $$srcsent{ID}>$src[0]! ";
				print STDERR "stop reading ....\n";
			    }
			    $self->{SRC}->add_to_buffer($srcsent);
			    next;
			}
		    }
		    until ($$srcsent{ID} eq $src[0]);
		    next if ($$srcsent{ID} ne $src[0]);

		    my $count=0;
		    do {
			$count++;
			last if ($count>$readmax);
			$self->{TRG}->next_sentence($trgsent);
			if ($$trgsent{ID}>$trg[0]){
			    if ($self->{-verbose}){
				print STDERR "trg: $$trgsent{ID}>$trg[0]! ";
				print STDERR "stop reading ....\n";
			    }
			    $self->{TRG}->add_to_buffer($trgsent);
			    next;
			}
		    }
		    until ($$trgsent{ID} eq $trg[0]);
		    next if ($$trgsent{ID} ne $trg[0]);

		}
		elsif ($self->{-verbose}){
		    print STDERR "cannot find sentences with these IDs!\n";
		    print STDERR "skip ";
		    print STDERR join('+',@src);
		    print STDERR " <--> ";
		    print STDERR join('+',@trg);
		    print STDERR "\n";
		}
		return 1;
	    }
	}
	$/='>';
    }
    $/=$OldDel;
    $fh->close;

    return 0;
}





# print tree alignments
# - SrcId, TrgId = treebank IDs (default: src & trg)
# - add link probablility in comment

sub print_alignments{
    my $self=shift;
    my $srcsent=shift;
    my $trgsent=shift;
    my $links=shift;

    my $SrcId = shift || 'src';
    my $TrgId = shift || 'trg';

    my $str='';
    foreach my $s (keys %{$links}){
	foreach my $t (keys %{$$links{$s}}){
	    my $att="author=\"Lingua::Align\" prob=\"$$links{$s}{$t}\"";

#	    my $att="comment=\"None\"";
	    # P<0.5 --> fuzzy link?!?
	    if ($$links{$s}{$t}>0.5){
		$str.="    <align $att type=\"good\">\n";
	    }
	    else{
		$str.="    <align $att type=\"fuzzy\">\n";
	    }
#	    $str.="    <align $att type=\"auto\">\n";
	    $str.="      <node node_id=\"$s\" treebank_id=\"$SrcId\"/>\n";
	    $str.="      <node node_id=\"$t\" treebank_id=\"$TrgId\"/>\n";
	    $str.="    </align>\n";
	}
    }
    return $str;
}

sub print_header{
    my $self=shift;
    my ($srcfile,$trgfile,$srcid,$trgid)=@_;
    my $string = "<?xml version=\"1.0\" ?>\n<treealign>\n  <treebanks>\n";
    $string.="    <treebank filename=\"$srcfile\" id=\"$srcid\"/>\n";
    $string.="    <treebank filename=\"$trgfile\" id=\"$trgid\"/>\n";
    $string.="  </treebanks>\n  <alignments>\n";
    return $string;
}

sub print_tail{
    my $self=shift;
    return "  </alignments>\n</treealign>\n";
}




sub __find_corpus_file{
    my ($file,$alignfile)=@_;
    return $file if (-e $file);
    my $dir = dirname($alignfile);
    return $dir.'/'.$file if (-e $dir.'/'.$file);
    my $base=basename($file);
    return $dir.'/'.$base if (-e $dir.'/'.$base);

    my $tmp = $file;
    if ($tmp=~s/xml\///){
	return $dir.'/'.$tmp if (-e $dir.'/'.$tmp);
    }

    if ($file!~/\.gz$/){
	return __find_corpus_file($file.'.gz',$alignfile);
    }
    warn "cannot find file $file\n";
    return $file;
}



##-------------------------------------------------------------------------
## 

sub __XMLTagStart{
    my ($p,$e,%a)=@_;

    if ($e eq 'cesAlign'){
#	$p->{TREEBANKIDS}=[];
#	$p->{TREEBANKCOUNT}=0
    }
    elsif ($e eq 'linkGrp'){
	if ($p->{SWAP_ALIGN}){           # swap alignment direction
# 	    print STDERR "swap direction!\n";
	    $p->{FROMDOC}=$a{toDoc};
	    $p->{TODOC}=$a{fromDoc};
	}
	else{
	    $p->{FROMDOC}=$a{fromDoc};
	    $p->{TODOC}=$a{toDoc};
	}
    }
    elsif ($e eq 'link'){
	my ($s,$t) = split(/\s*\;\s*/,$a{xtargets});
	if ($p->{SWAP_ALIGN}){                       # swap alignment direction
	    @{$p->{TRGSENT}} = split(/\s+/,$s);
	    @{$p->{SRCSENT}} = split(/\s+/,$t);
	}
	else{
	    @{$p->{SRCSENT}} = split(/\s+/,$s);
	    @{$p->{TRGSENT}} = split(/\s+/,$t);
	}
    }
}





1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::Align::Corpus::Parallel::OPUS - Read parallel corpora in OPUS format

=head1 SYNOPSIS

=head1 DESCRIPTION

OPUS is a collection of parallel corpora that uses a particular XML format and standoff annotation of sentence alignments.

=head2 EXPORT

=head1 SEE ALSO

L<http://www.let.rug.nl/~tiedeman/OPUS/>

=head1 AUTHOR

Joerg Tiedemann, E<lt>tiedeman@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
