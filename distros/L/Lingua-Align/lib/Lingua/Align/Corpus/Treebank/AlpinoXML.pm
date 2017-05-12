package Lingua::Align::Corpus::Treebank::AlpinoXML;

use 5.005;
use strict;
use Lingua::Align::Corpus::Treebank;
use Lingua::Align::Corpus::Treebank::TigerXML;


use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Treebank::TigerXML);

use FileHandle;
use XML::Parser;



sub read_index{
    my $self=shift;
    my $corpus=shift;
    $corpus=~s/\.data(\.[dg]z)?//;
    my $index=$corpus.'.index';
    if (-e $index){
	if (open F,"<$index"){
	    while (<F>){
		chomp;
		my ($id,$start,$length)=split(/\s+/);
		$id=~s/\.xml//;
		my $longid=$id;
		my $base=$corpus;
		if ($id=~/^(.*)\-([^\-]+)$/){
		    $base = $1;
		    $id = $2;
		}
		push (@{$self->{SENT_ID}},$id);
		push (@{$self->{SENT_LONGID}},$longid);
	    }
	    close F;
	}
	else{
	    warn "cannot open index file for $corpus\n";
	}
    }
}

sub next_sentence_id_would_be{
    my $self=shift;
    my $offset=shift;
    if (ref($self->{SENT_ID}) eq 'ARRAY'){
	if ($self->{NEXT_SENT}+$offset <= $#{$self->{SENT_ID}}){
	    return $self->{SENT_ID}->[$self->{NEXT_SENT}+$offset];
	}
	return 'EOF';
    }
    return $self->{NEXT_SENT}+$offset+1;
}


sub read_next_sentence{
    my $self=shift;
    my $tree=shift;

    my $file=shift || $self->{-file};
    if (! defined $self->{FH}->{$file}){
	$self->{FH}->{$file} = new FileHandle;
	if ($file=~/\.[dg]z$/){
	    $self->{FH}->{$file}->open("gzip -cd <$file |") || 
		die "cannot open file $file\n";
	}
	else{
	    $self->{FH}->{$file}->open("<$file") || 
		die "cannot open file $file\n";
	}
	$self->{__XMLPARSER__} = new XML::Parser(Handlers => 
						 {Start => \&__XMLTagStart,
						  End => \&__XMLTagEnd,
						  Char => \&__XMLChar});
	$self->{__XMLHANDLE__} = $self->{__XMLPARSER__}->parse_start;
	$self->{__FIRST_SENTENCE__}=1;
	$self->read_index($file);
	$self->{NEXT_SENT}=0;
	if ($self->{-skip_indexed}){
	    $self->{__XMLHANDLE__}->{-skip_indexed}=1;
	}
    }

    my $sentid = $self->next_sentence_id_would_be();
    $self->{__XMLHANDLE__}->{SENTID}=$sentid;
    delete $self->{__XMLHANDLE__}->{SENT};

    my $fh=$self->{FH}->{$file};
    my $OldDel=$/;
    $/='>';
    while (<$fh>){

	## parse XML header only for first sentence
	## add global root node before first tag
	## end of sentence if not at the beginning of the file
	if (/\<\?xml\s+version.*\?\>/){
	    last if (not $self->{__FIRST_SENTENCE__});
	    delete $self->{__FIRST_SENTENCE__};
	    $_.='<DocRoot>';
	}

	eval { $self->{__XMLHANDLE__}->parse_more($_); };
	if ($@){
	    warn $@;
	    print STDERR $_;
	}
    }
    $/=$OldDel;
    if (defined $self->{__XMLHANDLE__}->{SENT}){
	$tree->{ROOTNODE}=$self->{__XMLHANDLE__}->{ROOTNODE};
	$tree->{NODES}=$self->{__XMLHANDLE__}->{NODES};
	@{$tree->{TERMINALS}}=@{$self->{__XMLHANDLE__}->{TERMINALS}};

	if ($self->{__XMLHANDLE__}->{SENTID}=~/^(.*)\-([^-]+)$/){
	    $tree->{ID}=$2;
	    $tree->{CORPUS}=$1;
	    $tree->{LONGID}=$self->{__XMLHANDLE__}->{SENTID};
	}
	else{
	    $tree->{ID}=$self->{__XMLHANDLE__}->{SENTID};
	}
	$self->{NEXT_SENT}++;
	return 1;
    }
    $self->close_file($file);
    return 0;
}


sub print_tree{
    my $self=shift;
    my $tree=shift;

    my $ids=shift || [];
    my $node = shift || $tree->{ROOTNODE};

    my $str='';
    if (not $self->{-single_document}){
	$str= "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    }
    $str .= "<alpino_ds version=\"1.2\">\n";
    $str .= $self->print_sub_tree($tree,$node,'  ','top');

    $str .= '  <sentence>';
    my @words = $self->get_all_leafs($tree);
    $str .= join(' ',@words);
    $str .= "</sentence>\n";
    $str .= "  <comments>\n    <comment>Q#";
    $str .= $tree->{ID};
    $str .= '|';
    $str .= join(' ',@words);
    $str.="|||</comment>\n  </comments>\n</alpino_ds>\n";
    return $str;
}

sub print_sub_tree{
    my $self=shift;
    my $tree=shift;
    my $node=shift;
    my $indent=shift;
    my $rel=shift;
    my $done=shift;

    if (not ref($done)){ $done = {}; }      # another hash
    return '' if (defined $done->{$node});  # to avoid inifinite loops
    $done->{$node} = 1;

    if ($rel && (! exists $tree->{NODES}->{$node}->{rel})){
	$tree->{NODES}->{$node}->{rel}=$rel;
    }

    my $str.= $indent.'<node';
    foreach my $k (keys %{$tree->{NODES}->{$node}}){
	next if (ref($tree->{NODES}->{$node}->{$k}));
	my $val = escape_string($tree->{NODES}->{$node}->{$k});

# just leave the node ID's as they are!
# 
#	if ($k eq 'id'){
#	    $val =~s/^.*\_([0-9]+)$/$1/;
#	    if ($val>500){$val-=500;}
#	}

	$str .= ' '.$k.'="';
	$str .= $val;
	$str .= '"';
    }
    if (exists $tree->{NODES}->{$node}->{CHILDREN}){
	$str .= ">\n";
	foreach my $i (0..$#{$tree->{NODES}->{$node}->{CHILDREN}}){
	    my $n = $tree->{NODES}->{$node}->{CHILDREN}->[$i];
	    my $nrel = $tree->{NODES}->{$node}->{RELATION}->[$i];
	    $str .= $self->print_sub_tree($tree,$n,$indent.'  ',$nrel,$done);
	}
	$str.= $indent."</node>\n";
    }
    else{$str.= " />\n";}

    return $str;
}


sub escape_string{
    my $string = shift;
    $string=~s/\&/&amp;/gs;
    $string=~s/\>/&gt;/gs;
    $string=~s/\</&lt;/gs;
    $string=~s/\"/&quot;/gs;
    return $string;
}


sub print_header{
    my $self=shift;
    if ($self->{-single_document}){
	my $h='<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>';
	$h.="\n<treebank>\n";
	return $h;
    }
}

sub print_tail{
    my $self=shift;
    if ($self->{-single_document}){
	return "</treebank>\n";
    }
}


##-------------------------------------------------------------------------
## 


sub __XMLTagStart{
    my ($p,$e,%a)=@_;

    if ($e eq 'alpino_ds'){
#	$p->{NODES}={};        # need better clean-up?! (memory leak?)
	Lingua::Align::Corpus::__clean_delete($p->{NODES});  # better (?!)
	$p->{TERMINALS}=[];
	$p->{INDEX}={};
	delete $p->{ROOTNODE};
	delete $p->{CURRENT};
    }
    elsif ($e eq 'node'){

	if (exists $a{token}){       # PACO-MT: Vincent's conversion
	    $a{word} = $a{token};    # saves words in token-attributes!
	    delete $a{token};
	}

	if (exists $a{index} && (not exists $a{word})){
	    $p->{IS_INDEX_NODE}=1;
	    if ($p->{-skip_indexed}){      # skip all index nodes!
		return 1;
	    }
	}
	else{ $p->{IS_INDEX_NODE}=0; }

	if ($a{id} =~/^(.*)\_(.*)$/){         # take sentence ID from token ID
	    $p->{SENTID} = $1;                # (is that always OK?)
	}
	else{                                 # other cases: add sentID
	    $a{id}=$p->{SENTID}.'_'.$a{id};   # --> makes nodeIDs unique!
	}

	if (exists $a{word}){
	    push(@{$p->{TERMINALS}},$a{id});
	}

	foreach (keys %a){
	    $p->{NODES}->{$a{id}}->{$_}=$a{$_};
	}

	if (exists $p->{CURRENT}){
	    my $parent=$p->{CURRENT};
	    push(@{$p->{NODES}->{$a{id}}->{PARENTS}},$parent);
	    push(@{$p->{NODES}->{$parent}->{CHILDREN}},$a{id});
#	    push(@{$p->{NODES}->{$a{id}}->{RELATION}},$a{rel});
	    push(@{$p->{NODES}->{$parent}->{RELATION}},$a{rel});
	}

	if (exists $a{index}){
	    push(@{$p->{INDEX}->{$a{index}}},$a{id});
	}

	$p->{CURRENT}=$a{id};
	if (not exists $p->{ROOTNODE}){
	    $p->{ROOTNODE}=$a{id};
	}
    }
#    elsif ($e eq 'sentence'){
#    }
    elsif ($e eq 'comment'){
	$p->{__COMMENT__}=1;
    }
}

sub __XMLTagEnd{
    my ($p,$e)=@_;

    if ($e eq 'node'){

	if ($p->{-skip_indexed}){       # check if we skip index nodes; yes?
	    if ($p->{IS_INDEX_NODE}){   # do nothing if this is an index node
		return 1;
	    }
	}

	my $id = $p->{CURRENT};
	if (exists $p->{NODES}->{$id}->{PARENTS}){
	    $p->{CURRENT} = $p->{NODES}->{$id}->{PARENTS}->[0];
	}
	else{
	    delete $p->{CURRENT};
	}
    }
    elsif ($e eq 'comment'){
	delete $p->{__COMMENT__};
    }

    elsif (($e eq 'alpino_ds') && (not $p->{-skip_indexed})){

	# solve index links ...
	my %add=();
	foreach my $i (keys %{$p->{INDEX}}){
	    foreach my $n1 (@{$p->{INDEX}->{$i}}){
		foreach my $n2 (@{$p->{INDEX}->{$i}}){
		    next if ($n1 eq $n2);

		    # if n1 has children
		    # --> add them to n2 as well!
		    # if n1 is a terminal node
		    # --> add child to n2!

		    if (exists $p->{NODES}->{$n1}->{CHILDREN}){
			@{$add{$n2}}=@{$p->{NODES}->{$n1}->{CHILDREN}};
		    }
		    elsif (exists $p->{NODES}->{$n1}->{word}){
			@{$add{$n2}}=($n1);
		    }
		}
	    }
	}

	# add links to children as collected above
	# (this could probably be simplified ...)

	foreach my $n (keys %add){
#	    print STDERR "add ";
#	    print STDERR join(' ',@{$add{$n}});
#	    print STDERR " to $n\n";
	    push(@{$p->{NODES}->{$n}->{CHILDREN2}},@{$add{$n}});
	    foreach my $c (@{$add{$n}}){
		push(@{$p->{NODES}->{$n}->{RELATION2}},
		     $p->{NODES}->{$n}->{rel});
	    }

	}
    }

    if ($e eq 'alpino_ds'){
	# no sentence or comment tag ---> make sentence out of tokens
	if (not $p->{SENT}){
	    foreach (@{$p->{TERMINALS}}){
		if (exists $p->{NODES}->{$_}->{word}){
		    $p->{SENT}.=$p->{NODES}->{$_}->{word}.' ';
		}
	    }
	    chomp $p->{SENT};
	}
	# sort terminals by begin position
	print STDERR join(':',@{$p->{TERMINALS}});
	@{$p->{TERMINALS}}= 
	    sort { $p->{NODES}->{$a}->{begin} <=> 
		       $p->{NODES}->{$b}->{begin} } @{$p->{TERMINALS}};
	print STDERR "\n";
	print STDERR join(':',@{$p->{TERMINALS}});
	print STDERR "\n";

#	sort { my @x=split(/[\-\_]/,$a);
#	       my @y=split(/[\-\_]/,$b); 
#	       return $x[-1] <=> $y[-1] } @{$p->{TERMINALS}};

    }
}

sub __XMLChar{
    my ($p,$s)=@_;

    if (exists $p->{__COMMENT__}){
	if ($s=~/Q\#(.*?)\|/){
	    $p->{SENT}=$1;
	}
#	my ($sid)=split(/\|/,$s);
#	$sid=~s/^.*?\#//;
#	$p->{SENTID}=$sid;
    }
}





# Preloaded methods go here.

1;
__END__

=head1 NAME

Lingua::Align::Corpus::Treebank::AlpinoXML - Read Alpino XML

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 EXPORT

=head1 SEE ALSO

Alpino Treebank L<http://www.let.rug.nl/vannoord/alp/>

=head1 AUTHOR

Joerg Tiedemann, E<lt>tiedeman@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
