package Lingua::Align::Corpus::Treebank::TigerXML;

use 5.005;
use strict;
use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Treebank;




use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Treebank);

use FileHandle;
use XML::Parser;


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


sub print_header{
    my $self=shift;
    my $str = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<corpus xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="TigerXML.xsd"
        id="Lingua::Align conversion">
  <head>
    <meta>
      <format></format>
      <name>testset</name>
      <author></author>
      <date></date>
      <description></description>
    </meta>
    <annotation>
';
    if (ref($self->{TFEATURES}) eq 'HASH'){
	foreach my $f (keys %{$self->{TFEATURES}}){
	    $str.="      <feature name=\"$f\" domain=\"T\" >\n";
	    foreach my $n (keys %{$self->{TFEATURES}->{$f}}){
		$str.="        <value name=\"$n\">";
		$str.="$self->{TFEATURES}->{$f}->{$n}</value>\n";
	    }
	    $str.="      </feature>\n";
	}
    }
    if (ref($self->{NTFEATURES}) eq 'HASH'){
	foreach my $f (keys %{$self->{NTFEATURES}}){
	    $str.="      <feature name=\"$f\" domain=\"NT\" >\n";
	    foreach my $n (keys %{$self->{NTFEATURES}->{$f}}){
		$str.="        <value name=\"$n\">";
		$str.="$self->{NTFEATURES}->{$f}->{$n}</value>\n";
	    }
	    $str.="      </feature>\n";
	}
    }

    if (ref($self->{EDGELABELS}) eq 'HASH'){
	$str.="      <edgelabel>\n";
	foreach my $e (keys %{$self->{EDGELABELS}}){
	    $str.="        <value name=\"$e\">";
	    $str.="$self->{EDGELABELS}->{$e}</value>\n";
	}
	$str.="      </edgelabel>\n";
    }

    if (ref($self->{SECEDGELABELS}) eq 'HASH'){
	$str.="      <secedgelabel>\n";
	foreach my $e (keys %{$self->{SECEDGELABELS}}){
	    $str.="        <value name=\"$e\">";
	    $str.="$self->{SECEDGELABELS}->{$e}</value>\n";
	}
	$str.="      </secedgelabel>\n";
    }

    $str.="    </annotation>\n   </head>\n  <body>\n";
    return $str;
}

sub print_tail{
    return '</body>
</corpus>
';
}


sub escape_string{
    my $string = shift;
    $string=~s/\&/&amp;/gs;
    $string=~s/\>/&gt;/gs;
    $string=~s/\</&lt;/gs;
    $string=~s/\"/&quot;/gs;
    return $string;
}


sub print_tree{
    my $self=shift;
    my $tree=shift;

    my $ids=shift || [];
    my $node = shift || $tree->{ROOTNODE};

    my $str='<s id="'.$tree->{ID}."\">\n";
    $str.='  <graph root="'.$node."\">\n";
    $str.="    <terminals>\n";

    my %begin=();
    foreach (@{$tree->{TERMINALS}}){
	if (exists $tree->{NODES}->{$_}->{begin}){
	    $begin{$_}=$tree->{NODES}->{$_}->{begin};
	}
	else{
	    my ($id,$b)=split(/\_/);
	    $begin{$_}=$b;
	}
    }
#    foreach my $t (sort @{$tree->{TERMINALS}}){
    foreach my $t (sort { $begin{$a} <=> $begin{$b} } keys %begin){
	$str.= '      <t id="'.$t.'"';
	foreach my $k (keys %{$tree->{NODES}->{$t}}){
	    next if (ref($tree->{NODES}->{$t}->{$k}));
	    next if ($k eq 'id');
	    # save values for the header .... (if not word|lemma|root|..)
	    if ($k!~/(word|root|lemma|sense|id|begin|end|index)/i){
		$self->{TFEATURES}->{$k}->{$tree->{NODES}->{$t}->{$k}}='--';
	    }
	    else{$self->{TFEATURES}->{$k}={};}
	    $tree->{NODES}->{$t}->{$k}=
		escape_string($tree->{NODES}->{$t}->{$k});
	    $str.= " $k=\"$tree->{NODES}->{$t}->{$k}\"";
	}
	$str.= " />\n";
    }
    $str.="    </terminals>\n    <nonterminals>\n";
    foreach my $n (keys %{$tree->{NODES}}){
#	if (exists $tree->{NODES}->{$n}->{CHILDREN}){
	if ((exists $tree->{NODES}->{$n}->{CHILDREN}) || 
	    (exists $tree->{NODES}->{$n}->{CHILDREN2})){  # secondary edges ...
	    $str.= '      <nt id="'.$n.'"';

	    #---------------------------------------------------------
	    # if there is not category label: make one
	    # (stockholm tree aligner needs this .... (is this bad?)
	    if (not exists $tree->{NODES}->{$n}->{cat}){
		if (exists $tree->{NODES}->{$n}->{lcat}){
		    $tree->{NODES}->{$n}->{cat} = $tree->{NODES}->{$n}->{lcat};
		}
		if (exists $tree->{NODES}->{$n}->{index}){
		    $tree->{NODES}->{$n}->{cat}=
			'[idx'.$tree->{NODES}->{$n}->{index}.']';
		}
		else{
		    $tree->{NODES}->{$n}->{cat} = '--';
		}
	    }
	    #---------------------------------------------------------


	    foreach my $k (keys %{$tree->{NODES}->{$n}}){
		next if (ref($tree->{NODES}->{$n}->{$k}));
		next if ($k eq 'id');
		# save values for the header ....
		if ($k!~/(word|root|lemma|sense|id|begin|end|index)/i){
		    $self->{NTFEATURES}->{$k}->{$tree->{NODES}->{$n}->{$k}}='--';
		}
		else{$self->{NTFEATURES}->{$k}={};}
		$tree->{NODES}->{$n}->{$k}=
		    escape_string($tree->{NODES}->{$n}->{$k});
		$str.= " $k=\"$tree->{NODES}->{$n}->{$k}\"";
	    }
	    $str.= " >\n";

	    if (exists $tree->{NODES}->{$n}->{CHILDREN}){
		for my $c (0..$#{$tree->{NODES}->{$n}->{CHILDREN}}){
		    $str.='        <edge idref="';
		    $str.=$tree->{NODES}->{$n}->{CHILDREN}->[$c];
		    $str.='" label="';
		    my $label =
			escape_string($tree->{NODES}->{$n}->{RELATION}->[$c]);
		    $self->{EDGELABELS}->{$label}='--';
		    $str.=$label;
		    $str.="\" />\n";
		    # save values for the header ....
		    $self->{LABELS}->{$label}='--';
		}
	    }
	    if (exists $tree->{NODES}->{$n}->{CHILDREN2}){
		for my $c (0..$#{$tree->{NODES}->{$n}->{CHILDREN2}}){
#		    $str.='        <secedge idref="';
		    $str.='        <edge idref="';
		    $str.=$tree->{NODES}->{$n}->{CHILDREN2}->[$c];
		    $str.='" label="';
		    my $label =
			escape_string($tree->{NODES}->{$n}->{RELATION2}->[$c]);
		    $self->{EDGELABELS}->{$label}='--';
#		    $self->{SECEDGELABELS}->{$label}='--';
		    $str.=$label;
		    $str.="\" />\n";
		    # save values for the header ....
		    $self->{LABELS}->{$label}='--';
		}
	    }


	    $str.= "      </nt>\n";
	}
    }
    $str.="    </nonterminals>\n  </graph>\n</s>\n";
    return $str;
}


# go to a specific sentence ID
# right now: only sequential readin is allowed!
# --> if already open: close file and restart reading
# better -> we should do some indexing
# but: problem with gzipped files!


sub go_to{
    my $self=shift;
    my $sentID=shift;

    if (not $sentID){
	print STDERR "Don't know where to go to! Specify a sentence ID!\n";
	return 0;
    }

    my $file=shift || $self->{-file};
    if (defined $self->{FH}->{$file}){
	$self->{SRC}->close();
    }
    $self->{LAST_TREE}={};
    while ($self->next_sentence($self->{LAST_TREE}={})){
	return 1 if ($self->{LAST_TREE}->{ID} eq $sentID);
    }

    print STDERR "Could not find sentence $sentID? What can I do?\n";
    return 0;

}


sub next_tree{
    my $self=shift;
    return $self->next_sentence(@_);
}


sub read_next_sentence{
    my $self=shift;
    my $tree=shift;

    my $file=shift || $self->{-file};
    if (! defined $self->{FH}->{$file}){
	$self->open_file($file);
	$self->{__XMLPARSER__} = new XML::Parser(Handlers => 
						 {Start => \&__XMLTagStart,
						  End => \&__XMLTagEnd});
	$self->{__XMLHANDLE__} = $self->{__XMLPARSER__}->parse_start;
    }

    $self->{__XMLHANDLE__}->{SENTID}=undef;
    $self->{__XMLHANDLE__}->{SENT_ENDED}=0;

    my $fh=$self->{FH}->{$file};
    my $header;
    my $tail;

    my $OldDel=$/;
    $/='>';
    while (<$fh>){
	eval { $self->{__XMLHANDLE__}->parse_more($_); };
	if ($@){
	    warn $@;
	    print STDERR $_;
	}
	if (not $self->{__XMLHANDLE__}->{SENT}){
	    if (not $self->{HEADER}){$header .= $_;}
	    elsif (not $self->{TAIL}){$tail .= $_;}
	}
	last if ($self->{__XMLHANDLE__}->{SENT_ENDED});
    }
    $/=$OldDel;

    if (defined $header){$self->{HEADER} = $header;}
    if (defined $tail){$self->{HEADER} = $tail;}

    if (defined $self->{__XMLHANDLE__}->{SENTID}){
	$tree->{ROOTNODE}=$self->{__XMLHANDLE__}->{ROOTNODE};
	$tree->{NODES}=$self->{__XMLHANDLE__}->{NODES};
	$tree->{TERMINALS}=$self->{__XMLHANDLE__}->{TERMINALS};
	$tree->{ID}=$self->{__XMLHANDLE__}->{SENTID};
	return 1;
    }
    $self->close_file($file);
#    $fh->close;
    return 0;
}





##-------------------------------------------------------------------------
## 


sub __XMLTagStart{
    my ($p,$e,%a)=@_;

    if ($e eq 's'){
	$p->{SENT}=1;
	$p->{SENTID}=$a{id};
#	$p->{NODES}={};               # need better clean-up?! (memory leak?)
	Lingua::Align::Corpus::__clean_delete($p->{NODES});  # better (?!)
	$p->{TERMINALS}=[];
    }
    elsif ($e eq 't'){
	push(@{$p->{TERMINALS}},$a{id});
	foreach (keys %a){
	    $p->{NODES}->{$a{id}}->{$_}=$a{$_};
	}
    }
    elsif ($e eq 'nt'){
	foreach (keys %a){
	    $p->{NODES}->{$a{id}}->{$_}=$a{$_};
	}
	$p->{CURRENT}=$a{id};
    }
    elsif ($e eq 'edge'){
	my $parent=$p->{CURRENT};
	my $child=$a{idref};
	my $rel=$a{label};
        # do I have to allow multiple parents? (->secondary edges?!)
	push(@{$p->{NODES}->{$child}->{PARENTS}},$parent);
	push(@{$p->{NODES}->{$parent}->{CHILDREN}},$child);
# 	push(@{$p->{NODES}->{$child}->{RELATION}},$rel);
	push(@{$p->{NODES}->{$parent}->{RELATION}},$rel);
#	$p->{REL}->{$child}->{$parent}=$rel;
#	$p->{REL}->{$parent}->{$child}=$rel;
    }
    elsif ($e eq 'graph'){
	$p->{ROOTNODE}=$a{root};
    }
}

sub __XMLTagEnd{
    my ($p,$e)=@_;

    if ($e eq 's'){
	$p->{SENT_ENDED}=1;
    }
}





# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::Align::Corpus::Treebank::TigerXML - Read the TigerXML format

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
