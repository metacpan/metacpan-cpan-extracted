package Lingua::Align::Corpus::Parallel::STA;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel);

use FileHandle;
use File::Basename;

use XML::Parser;
use Lingua::Align::Corpus::Parallel;
use Lingua::Align::Corpus::Treebank;

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    # a treebank object of tree manipulation (used in print_alignments)
    $self->{TREES} = new Lingua::Align::Corpus::Treebank();

    return $self;
}


sub read_next_alignment{
    my $self=shift;
    my ($srctree,$trgtree,$links)=@_;

    my $file=$_[3] || $self->{-alignfile};

    # first: read all tree alignments (problem for large parallel treebanks?!)
    if ((! ref($self->{SRC})) || (! ref($self->{TRG}))){
	$self->read_tree_alignments($file);
    }

    return 0 if (not $self->{SRC}->next_sentence($srctree));
    return 0 if (not $self->{TRG}->next_sentence($trgtree));


    # if the current trees are not linked: read more trees
    # 1) no links defined for current source sentence! --> read more src
    while (not exists $self->{__XMLHANDLE__}->{SALIGN}->{$$srctree{ID}}){
	print STDERR "skip source $$srctree{ID}\n" if ($self->{-verbose});
	return 0 if (not $self->{SRC}->next_sentence($srctree));
    }
    # 2) target sentence is not linked to current source sentence
    if ($$trgtree{ID} ne $self->{__XMLHANDLE__}->{SALIGN}->{$$srctree{ID}}){
	my $thisID=$$trgtree{ID};
	my $linkedID=$self->{__XMLHANDLE__}->{SALIGN}->{$$srctree{ID}};
	$thisID=~s/^[^0-9]*//;
	$linkedID=~s/^[^0-9]*//;
	# assume that sentence IDs are ordered upwards
	while ($thisID<$linkedID){
	    return 0 if (not $self->{TRG}->next_sentence($trgtree));
	    $thisID=$$trgtree{ID};
	    $thisID=~s/^[^0-9]*//;
	}
    }
    # still not the one?
    # 3) source sentence is not linked to current target sentence
    if ($$trgtree{ID} ne $self->{__XMLHANDLE__}->{SALIGN}->{$$srctree{ID}}){
	my $thisID=$$srctree{ID};
	my $linkedID=$self->{__XMLHANDLE__}->{TALIGN}->{$$trgtree{ID}};
	$thisID=~s/^[^0-9]*//;
	$linkedID=~s/^[^0-9]*//;
	# assume that sentence IDs are ordered upwards
	while ($thisID<$linkedID){
	    return 0 if (not $self->{SRC}->next_sentence($srctree));
	    $thisID=$$srctree{ID};
	    $thisID=~s/^[^0-9]*//;
	}
    }
    # ... that's all I can do ....


    # this would be all links in the entire corpus:
    #    $$links = $self->{__XMLHANDLE__}->{LINKS};

    # return only links from current tree pair!
    $$links=$self->{__XMLHANDLE__}->{NLINKS}->{"$$srctree{ID}:$$trgtree{ID}"};

    return 1;

}


sub get_links{
    my $self=shift;
    my ($src,$trg)=@_;

    my $alllinks = $_[2] || $self->{__XMLHANDLE__}->{LINKS};

    my %links=();

    foreach my $sn (keys %{$$src{NODES}}){
	if (exists $$alllinks{$sn}){
	    foreach my $tn (keys %{$$trg{NODES}}){
		if (exists $$alllinks{$sn}{$tn}){
		    if ($$alllinks{$sn}{$tn} ne 'comment'){
			$links{$sn}{$tn} = $$alllinks{$sn}{$tn};
		    }
		}
	    }
	}
    }
    return %links;
}


# print tree alignments
# - SrcId, TrgId = treebank IDs (default: src & trg)
# - add link probablility in comment

sub print_alignments{
    my $self=shift;
    my $srctree=shift;
    my $trgtree=shift;
    my $links=shift;

    my $SrcId = shift || 'src';
    my $TrgId = shift || 'trg';

    my $str='';
    foreach my $s (keys %{$links}){
	my $stype='nt';
	$stype='t' if ($self->{TREES}->is_terminal($srctree,$s));
	foreach my $t (keys %{$$links{$s}}){
	    my $ttype='nt';
	    $ttype='t' if ($self->{TREES}->is_terminal($trgtree,$t));
#	    my $att="author=\"Lingua::Align\" prob=\"$$links{$s}{$t}\"";
	    my $att="author=\"Lingua-Align\" prob=\"$$links{$s}{$t}\"";

#	    my $att="comment=\"None\"";
	    # P<0.5 --> fuzzy link?!?
	    if ($$links{$s}{$t}>0.5){
		$str.="    <align $att type=\"good\">\n";
	    }
	    elsif ($$links{$s}{$t}=~s/w//){
		$str.="    <align $att type=\"weak\">\n";
	    }
	    else{
		$str.="    <align $att type=\"fuzzy\">\n";
	    }
#	    $str.="    <align $att type=\"auto\">\n";
	    $str.="      <node node_id=\"$s\" type=\"$stype\" treebank_id=\"$SrcId\"/>\n";
	    $str.="      <node node_id=\"$t\" type=\"$stype\" treebank_id=\"$TrgId\"/>\n";

#	    $str.="      <node node_id=\"$s\" treebank_id=\"$SrcId\"/>\n";
#	    $str.="      <node node_id=\"$t\" treebank_id=\"$TrgId\"/>\n";

	    $str.="    </align>\n";
	}
    }
    return $str;
}

sub print_header{
    my $self=shift;
    my ($srcfile,$trgfile,$srcid,$trgid)=@_;
    my $string = "<?xml version=\"1.0\" ?>\n<treealign>\n";
    $string.="<head>\n";
#    $string.="<alignment-metadata>\n";
#    $string.="    <date>";
#    $string.=localtime();
#    $string.="</date>\n";
#    $string.="    <author>Lingua-Align</author>\n";
#    $string.="  </alignment-metadata>\n";
    $string.="</head>\n";
    $string.="  <treebanks>\n";
    $string.="    <treebank filename=\"$srcfile\" id=\"$srcid\"/>\n";
    $string.="    <treebank filename=\"$trgfile\" id=\"$trgid\"/>\n";
    $string.="  </treebanks>\n  <alignments>\n";
    return $string;
}

sub print_tail{
    my $self=shift;
    return "  </alignments>\n</treealign>\n";
}


sub read_tree_alignments{
    my $self=shift;
    my $file=shift;
    my $links=shift;
    my ($srctypes,$trgtypes)=@_;    # hash of node types (NTs or Ts)

    if (! defined $self->{FH}->{$file}){
#	$self->{FH}->{$file} = new FileHandle;
#	$self->{FH}->{$file}->open("<$file") || die "cannot open file $file\n";
	$self->{FH}->{$file}=$self->open_file($file);
	$self->{__XMLPARSER__} = new XML::Parser(Handlers => 
						 {Start => \&__XMLTagStart,
						  End => \&__XMLTagEnd});
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
	if ($@){
	    warn $@;
	    print STDERR $_;
	}
    }
    $/=$OldDel;
    $fh->close;

    my $srcid = $self->{__XMLHANDLE__}->{TREEBANKIDS}->[0];
    my $trgid = $self->{__XMLHANDLE__}->{TREEBANKIDS}->[1];

    my %attr=();
    foreach (keys %{$self}){          # copy src/trg attributes
	if (/\-(src|trg)\_/){
	    $attr{$_}=$self->{$_};
	}
    }
    $attr{-src_type}=$self->{-src_type} || 'TigerXML';
    $attr{-trg_type}=$self->{-trg_type} || 'TigerXML';
    $attr{-src_file}=
	__find_corpus_file($self->{__XMLHANDLE__}->{TREEBANKS}->{$srcid},$file);
    $attr{-trg_file}=
	__find_corpus_file($self->{__XMLHANDLE__}->{TREEBANKS}->{$trgid},$file);

    $self->make_corpus_handles(%attr);
    if (ref($links)){
	$$links = $self->{__XMLHANDLE__}->{LINKS};
    }
    # return reference to node type hashs if necessary
    if (ref($srctypes)){
	if (exists $self->{__XMLHANDLE__}->{SRCNODETYPES}){
	    $$srctypes = $self->{__XMLHANDLE__}->{SRCNODETYPES};
	}
    }
    if (ref($trgtypes)){
	if (exists $self->{__XMLHANDLE__}->{TRGNODETYPES}){
	    $$trgtypes = $self->{__XMLHANDLE__}->{TRGNODETYPES};
	}
    }

    return $self->{__XMLHANDLE__}->{LINKCOUNT};
}



sub treebankID{
    my $self=shift;
    my $nr=shift || 0;
    if (exists $self->{__XMLHANDLE__}){
	if (exists $self->{__XMLHANDLE__}->{TREEBANKIDS}){
	    if (ref($self->{__XMLHANDLE__}->{TREEBANKIDS}) eq 'ARRAY'){
		return $self->{__XMLHANDLE__}->{TREEBANKIDS}->[$nr];
	    }
	}
    }
    return $nr+1;
#    return undef;
}

sub src_treebankID{
    my $self=shift;
    return $self->treebankID(0);
}

sub trg_treebankID{
    my $self=shift;
    return $self->treebankID(1);
}

sub src_treebank{
    my $self=shift;
    my $id=$self->src_treebankID();
    if (defined $id){
	if (ref($self->{__XMLHANDLE__}->{TREEBANKS}) eq 'HASH'){
	    return $self->{__XMLHANDLE__}->{TREEBANKS}->{$id};
	}
	else{
	    return $self->{-src_file};
	}
    }
    return undef;
}

sub trg_treebank{
    my $self=shift;
    my $id=$self->trg_treebankID();
    if (defined $id){
	if (ref($self->{__XMLHANDLE__}->{TREEBANKS}) eq 'HASH'){
	    return $self->{__XMLHANDLE__}->{TREEBANKS}->{$id};
	}
	else{
	    return $self->{-trg_file};
	}
    }
    return undef;
}


sub __find_corpus_file{
    my ($file,$alignfile)=@_;
    return $file if (-e $file);
    my $dir = dirname($alignfile);
    return $dir.'/'.$file if (-e $dir.'/'.$file);
    my $base=basename($file);
    return $dir.'/'.$base if (-e $dir.'/'.$base);
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

    if ($e eq 'treebanks'){
	$p->{TREEBANKIDS}=[];
    }
    elsif ($e eq 'treebank'){
	$p->{TREEBANKS}->{$a{id}}=$a{filename};
	push (@{$p->{TREEBANKIDS}},$a{id});
    }
    elsif ($e eq 'align'){
	$p->{ALIGN}->{type}=$a{type};
	$p->{ALIGN}->{prob}=$a{prob} if (exists $a{prob});
	$p->{ALIGN}->{comment}=$a{comment} if (exists $a{comment});
    }
    elsif ($e eq 'node'){
	$p->{ALIGN}->{$a{treebank_id}}=$a{node_id}; # (always 1 node/id?)
	if (exists $a{type}){
	    $p->{NODETYPE}->{$a{treebank_id}} = $a{type};
	}
    }

}

sub __XMLTagEnd{
    my ($p,$e)=@_;
    
    if ($e eq 'align'){
	# we assume that there are only two treebansk linked with each other
	my $src=$p->{ALIGN}->{$p->{TREEBANKIDS}->[0]};
	my $trg=$p->{ALIGN}->{$p->{TREEBANKIDS}->[1]};
	$p->{LINKS}->{$src}->{$trg}=$p->{ALIGN}->{type};
	$p->{LINKCOUNT}++;
	# assume that node IDs include sentence ID
	# assume also that there are only 1:1 sentence alignments
	my ($sid)=split(/\_/,$src);
	my ($tid)=split(/\_/,$trg);
	$p->{SALIGN}->{$sid}=$tid;
	$p->{TALIGN}->{$tid}=$sid;
	# node links per tree pair
	if (exists $p->{ALIGN}->{prob}){
	    $p->{NLINKS}->{"$sid:$tid"}->{$src}->{$trg}=$p->{ALIGN}->{prob};
	}
	else{
	    $p->{NLINKS}->{"$sid:$tid"}->{$src}->{$trg}=$p->{ALIGN}->{type};
	}
	# node types
	if (exists $p->{NODETYPE}){
	    my $srctype=$p->{NODETYPE}->{$p->{TREEBANKIDS}->[0]};
	    my $trgtype=$p->{NODETYPE}->{$p->{TREEBANKIDS}->[1]};
	    $p->{SRCNODETYPES}->{$src} = $srctype;
	    $p->{TRGNODETYPES}->{$trg} = $trgtype;
	}
    }
    elsif ($e eq 'treebanks'){
	if ($p->{SWAP_ALIGN}){           # swap alignment direction
	    print STDERR "swap alignment direction!\n";
	    my $src = $p->{TREEBANKIDS}->[0];
	    $p->{TREEBANKIDS}->[0] = $p->{TREEBANKIDS}->[1];
	    $p->{TREEBANKIDS}->[1] = $src;
	}
	$p->{NEWTREEBANKINFO}=1;
    }
}





1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::Align::Corpus::Parallel::STA - Read the STockholm Tree Aligner Format

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
