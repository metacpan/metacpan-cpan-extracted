

package Lingua::Align::Corpus::Parallel::WPT;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Parallel::Moses);

use Lingua::Align::Corpus;
use Lingua::Align::Corpus::Parallel::Moses;


sub read_word_alignments{
    my $self=shift;
    my $file=$_[0] || $self->{-alignfile};
    my $links=$_[1];

    my $count=0;
    my $fh=$self->open_file($file);
    while (<$fh>){
	chomp;
	my ($sid,$s,$t,$type)=split(/\s+/);
	if ($type eq 'S'){$type='good';}
	if ($type eq 'P'){$type='fuzzy';}
#	$sid=~s/^(0*).//;
	$self->{WORDLINKS}->{$sid}->{"$sid\_$s"}->{"$sid\_$t"}=$type;
	$self->{ALLWORDLINKS}->{"$sid\_$s"}->{"$sid\_$t"}=$type;
	$count++;
    }
    $self->close_file($fh);
    if (ref($links)){
	$$links = $self->{ALLWORDLINKS};
    }
    return $count;
}


sub read_tree_alignments{
    my $self=shift;
    return $self->read_word_alignments(@_);
}


sub read_next_alignment{
    my $self=shift;
    my ($src,$trg,$links)=@_;

    my $file=$_[3] || $self->{-alignfile};
    my $ids=$_[4];

    if (not defined $self->{WORDLINKS}){
	$self->read_word_alignments($file);
	$self->{LINKID}=0;
    }


    if (exists $self->{-src_file}){
	if (! $self->{SRC}->next_sentence($src)){
	    return 0;
	}
    }
    if (exists $self->{-trg_file}){
	if (! $self->{TRG}->next_sentence($trg)){
	    return 0;
	}
    }

    $self->{LINKID}++;
    if (ref($src) eq 'HASH'){
	if (ref($trg) eq 'HASH'){
	    if ($src->{ID} eq $trg->{ID}){
		$self->{LINKID} = $src->{ID};
	    }
	}
    }

    return 0 if (! defined $self->{WORDLINKS});
    return 0 if (! defined $self->{WORDLINKS}->{$self->{LINKID}});

    $$links=$self->{WORDLINKS}->{$self->{LINKID}};
    return 1;
}

sub get_links{
    my $self=shift;
    my ($src,$trg)=@_;

    if (ref($self->{WORDLINKS}->{$self->{LINKID}}) eq 'HASH'){
	return %{$self->{WORDLINKS}->{$self->{LINKID}}};
    }
    return ();
}


1;
__END__

=head1 NAME

Lingua::Align::Corpus::Parallel::WPT - Read data from the WPT word alignment task

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
