

package Lingua::Align::Corpus::Parallel::Dublin;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel);

use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Parallel;

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    my %CorpusAttr=%attr;
    $CorpusAttr{-type} = 'penn';
    $CorpusAttr{-add_ids} = 1;           # add node id's
#    if ($attr{-skip_node_ids}){          # but skip adding the original
#	$CorpusAttr{-skip_node_ids} = 1;  # node IDs
    if ($attr{-add_node_ids}){
	$CorpusAttr{-add_node_ids} = 1;
    }
    if ($attr{-alignfile}){
	$CorpusAttr{-file} = $attr{-alignfile};
    }

#    $self->make_corpus_handles(%attr);
    $self->{CORPUS}=new Lingua::Align::Corpus(%CorpusAttr);
    $self->{SRC} = $self->{CORPUS};
    $self->{TRG} = $self->{CORPUS};

    return $self;
}


sub read_next_alignment{
    my $self=shift;
    my ($src,$trg,$links)=@_;

    return 0 if (not $self->{CORPUS}->next_sentence($src));
    return 0 if (not $self->{CORPUS}->next_sentence($trg));

    my $fh = $self->{CORPUS}->open_file();
    my $LinkStr = <$fh>;
    chomp($LinkStr);
    my @LinkArr = split(/\s+/,$LinkStr);
    $$links = {};

    while (@LinkArr){
	my $sid = shift(@LinkArr);
	$sid = $src->{ID}.'_'.$sid;
	my $tid = shift(@LinkArr);
	$tid = $trg->{ID}.'_'.$tid;
	$self->{LINKS}->{$sid}->{$tid}='good';
	$$links->{$sid}{$tid}='good';
    }

#    return 0 if (not $self->{SRC}->next_sentence($src));
#    return 0 if (not $self->{TRG}->next_sentence($trg));

    ## .... unfinished
    ## do something more to handle collapsed unary sub-trees
    ## do something to handle node alignments ....
    ## .....

    return 1;
}

sub read_tree_alignments{
    my $self=shift;
    my $file=shift;
    my $AllLinks=shift;

    $self->{CORPUS}->open_file($file);
    my %srctree=();
    my %trgtree=();
    my $links;
    while ($self->next_alignment(\%srctree,\%trgtree,\$links)){
	# I am reading ....
    }
    if (ref($links)){
	$$AllLinks=$self->{LINKS};
    }
}


sub print_alignments{
    my $self=shift;
    my $srctree=shift;
    my $trgtree=shift;
    my $links=shift;

    
    my @srcIDs=();
    my $str=$self->{CORPUS}->print_tree($srctree,\@srcIDs);
    $str.="\n";
    my @trgIDs=();
    $str.=$self->{CORPUS}->print_tree($trgtree,\@trgIDs);
    $str.="\n";

    my %srcid2nr=();
    for (0..@srcIDs){
	$srcid2nr{$srcIDs[$_]}=$_+1;
    }
    my %trgid2nr=();
    for (0..@trgIDs){
	$trgid2nr{$trgIDs[$_]}=$_+1;
    }

    my @LinkNr=();
    foreach my $s (keys %{$links}){
	foreach my $t (keys %{$$links{$s}}){
	    push(@LinkNr,$srcid2nr{$s}.' '.$trgid2nr{$t});
	}
    }
    $str.=join(' ',sort {$a <=> $b} @LinkNr);
    $str.="\n\n";
    return $str;

}




1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel::Dublin - Read Dublin Subtree Aligner format

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
