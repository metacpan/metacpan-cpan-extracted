package Lingua::Align::Corpus::Treebank::Penn;

use 5.005;
use strict;

use Lingua::Align::Corpus::Treebank;
use File::Basename;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Treebank);

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    return $self;
}

sub next_sentence_id{
    my $self=shift;

    if ($self->{NO_SENTID_FILE}){
	$self->{SENTCOUNT}++;
	return $self->{SENTCOUNT};
    }

    my $file=shift || $self->{-id_file};
    if (! defined $self->{FH}->{$file}){
	if (not defined $file){
	    my $base=basename($self->{-file});
	    my $dir=dirname($self->{-file});
	    $base=~s/\..*$/.ids/;
	    if (-e $dir.'/text/'.$base){
		$file=$dir.'/text/'.$base;
	    }
	    elsif (-e $dir.'/text/'.$base.'.gz'){
		$file=$dir.'/text/'.$base.'.gz';
	    }
	    else{
		$self->{NO_SENTID_FILE}=1;
	    }
	    $self->{-id_file}=$file;
	    return $self->next_sentence_id();
	}
	else{
	    $self->{FH}->{$file} = $self->open_file($file);
	}
    }

    my $fh=$self->{FH}->{$file};
    my $id = <$fh>;
    chomp $id;

    if ($id=~/^(.*)\-([^-]+)$/){
	return $2;
    }
    return $id;
}


sub read_next_sentence{
    my $self=shift;
    my $tree=shift;
    %{$tree}=();

    my $file=shift || $self->{-file};
    if (! defined $self->{FH}->{$file}){
	$self->{FH}->{$file} = $self->open_file($file);
	$self->{-file}=$file;
    }
    my $fh=$self->{FH}->{$file};

    $self->__initialize_parser($tree);
    $tree->{ID}=$self->next_sentence_id();

    # look for a possible tree start
    while(<$fh>){
	next if (/Sentence skipped: /);             # stanford parser: skips
	if (/SENTENCE_SKIPPED_OR_UNPARSABLE/){      # some sentences ...
	    $self->__initialize_parser($tree);      # -> return next sentences!
	    $tree->{ID}=$self->next_sentence_id();  # (with next ID)
	    next;
#	    return $self->read_next_sentence($tree,$file,@_); # return next!!!
	}
	last if (/^\s*\(/)
    }

    # parse until first empty line
    if (defined $_){
	do {
	    if (/\S/){
		return 1 if ($self->__parse($_,$tree));
	    }
#	    $self->__parse($_,$tree);
	    $_=<$fh>;
	}
	until ($_!~/\S/);
	return 1;
    }
    return 0;

#    while (<$fh>){
#	chomp;
#	next if ($_!~/\S/);
#	return 1 if ($self->__parse($_,$tree));
#    }
#    return 0;

}

sub __initialize_parser{
    my $self=shift;
    $self->{OPEN_BRACKETS}=0;
    $self->{NODECOUNT}=0;
    delete $self->{CURRENTNODE};
}

sub __parse{
    my $self=shift;
    my ($string,$tree)=@_;

    while ($string=~/\S/){

	# terminal node!
	if ($string=~/^\s*\((\S+)\s+(\S+?)\)(.*)$/){
	    my ($pos,$word)=($1,$2);
	    if ($word eq '-RRB-'){$word=')';}        # brackets
	    elsif ($word eq '-LRB-'){$word='(';}
	    $string=$3;

	    $self->{NODECOUNT}++;
#	    my $node = 500+$self->{NODECOUNT};
	    my $node = $self->{NODECOUNT};
	    if ($pos=~s/\-(s?[0-9]+\_[0-9]+)\-([0-9]+)$//){
		$node = $1;
	    }
	    elsif ($pos=~s/\-([0-9]+)$//){
		$node=$tree->{ID}.'_'.$1;
	    }
	    else{
		$node=$tree->{ID}.'_'.$node;
	    }
	    $tree->{NODES}->{$node}->{id} = $node;
	    $tree->{NODES}->{$node}->{pos} = $pos;
	    $tree->{NODES}->{$node}->{word} = $word;
	    push(@{$tree->{TERMINALS}},$node);

	    my $parent = $self->{CURRENTNODE};
	    push(@{$tree->{NODES}->{$node}->{PARENTS}},$parent);
	    push(@{$tree->{NODES}->{$parent}->{CHILDREN}},$node);
#	    push(@{$tree->{NODES}->{$node}->{RELATION}},'--');
	    push(@{$tree->{NODES}->{$parent}->{RELATION}},'--');

	}

	elsif ($string=~/^\s*\((\S+)(.*)$/){
	    my $cat=$1;
	    $string=$2;

	    $self->{NODECOUNT}++;
	    $self->{OPEN_BRACKETS}++;
#	    my $node = $self->{NODECOUNT};
	    my $node = 500+$self->{NODECOUNT};

	    if ($cat=~s/\-(s?[0-9]+\_[0-9]+)\-([0-9]+)$//){
		$node = $1;
	    }
	    elsif ($cat=~s/\-([0-9]+)$//){
		$node=$tree->{ID}.'_'.$1;
	    }
	    else{
		$node=$tree->{ID}.'_'.$node;
	    }

	    $tree->{NODES}->{$node}->{cat} = $cat;
	    $tree->{NODES}->{$node}->{id} = $node;

	    if ($self->{NODECOUNT} == 1){
		$tree->{ROOTNODE} = $node;
	    }
	    else{
		my $parent = $self->{CURRENTNODE};
		push(@{$tree->{NODES}->{$node}->{PARENTS}},$parent);
		push(@{$tree->{NODES}->{$parent}->{CHILDREN}},$node);
#		push(@{$tree->{NODES}->{$node}->{RELATION}},'--');
		push(@{$tree->{NODES}->{$parent}->{RELATION}},'--');
	    }

	    $self->{CURRENTNODE} = $node;

	}

	elsif ($string=~/^\s*\)(.*)$/){
	    $string=$1;
	    my $node = $self->{CURRENTNODE};
	    my $parent = $tree->{NODES}->{$node}->{PARENTS}->[0];
	    $self->{CURRENTNODE}=$parent;
	    $self->{OPEN_BRACKETS}--;
	}

	# something is wrong!
	elsif ($string=~/\S/){
	    return 0;
	}

    }

    return 1 if ($self->{OPEN_BRACKETS} == 0);
    return 0;

}



sub print_tree{
    my $self=shift;
    my $tree=shift;

    my $ids=shift || [];
    my $node = shift || $tree->{ROOTNODE};

    my $string.='(';
    if (defined $tree->{NODES}->{$node}->{cat}){
	$string.=$tree->{NODES}->{$node}->{cat};
    }
    elsif (defined $tree->{NODES}->{$node}->{pos}){
	$string.=$tree->{NODES}->{$node}->{pos};
    }
    elsif (defined $tree->{NODES}->{$node}->{rel}){
	$string.=$tree->{NODES}->{$node}->{rel};
    }
    # add node ID if necessary (for Dublin aligner format)
    if ($self->{-add_ids}){
#	if (not $self->{-skip_node_ids}){
	if ($self->{-add_node_ids}){
	    $string.='-'.$tree->{NODES}->{$node}->{id};
	}
	my $idx = scalar @{$ids} + 1;
	$string.='-'.$idx;
	$tree->{NODES}->{$node}->{idx}=$idx;
    }
    push (@{$ids},$tree->{NODES}->{$node}->{id});
    $string.=' ';

    if (exists $tree->{NODES}->{$node}->{CHILDREN}){
	foreach my $c (@{$tree->{NODES}->{$node}->{CHILDREN}}){
	    $string.=$self->print_tree($tree,$ids,$c);
	}
    }

    elsif (defined $tree->{NODES}->{$node}->{word}){
	$string.=$tree->{NODES}->{$node}->{word};
    }
    elsif (defined $tree->{NODES}->{$node}->{index}){
#	my $child = $tree->{NODES}->{$node}->{CHILDREN2}->[0];
	$string.='index-'.$tree->{NODES}->{$node}->{CHILDREN2}->[0];
    }
    $string.=')';
    return $string;
}

    


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::Align::Corpus::Treebank::Penn - Read the Penn Treebank format

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
