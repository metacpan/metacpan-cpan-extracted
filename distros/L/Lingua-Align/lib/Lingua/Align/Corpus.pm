package Lingua::Align::Corpus;

use 5.005;
use strict;

use FileHandle;
use Lingua::Align::Corpus::Treebank;
use Lingua::Align::Corpus::Factored;

sub new{
    my $class=shift;
    my %attr=@_;

    if (defined $attr{-type}){
	if ($attr{-type}=~/(tiger|penn|alpino|stanford|berkeley)/i){
	    return new Lingua::Align::Corpus::Treebank(%attr);
	}
	elsif ($attr{-type}=~/factored/i){
	    delete $attr{-type};
	    return new Lingua::Align::Corpus::Factored(%attr);
	}
    }

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }
    $self->{-encoding} = $attr{-encoding} || 'utf8';

    return $self;
}



sub next_sentence{
    my $self=shift;
    my ($sent)=@_;
    __clean_delete($sent);    # make a perfectly clean new structure (?!)
    if ($self->read_sentence_from_buffer($sent)){
	return 1;
    }
    return $self->read_next_sentence(@_);
}


sub add_to_buffer{
    my $self=shift;
    my $sent=shift;
    if (not exists $self->{__BUFFER__}){
	$self->{__BUFFER__}=[];
    }
    my $idx = scalar @{$self->{__BUFFER__}};
    if (ref($sent) eq 'ARRAY'){
	@{$self->{__BUFFER__}->[$idx]} = @{$sent};
	return $idx+1;
    }
    elsif (ref($sent) eq 'HASH'){
	%{$self->{__BUFFER__}->[$idx]} = %{$sent};
	return $idx+1;
    }
    print STDERR "no data to buffer?!\n";
    if (not $idx){delete $self->{__BUFFER__};}
    return 0;
}


sub read_sentence_from_buffer{
    my $self=shift;
    return $self->read_from_buffer(@_);
}

sub read_from_buffer{
    my $self=shift;
    my $sent=shift;
    if (exists $self->{__BUFFER__}){
	if (scalar @{$self->{__BUFFER__}}){
	    if ((ref($sent) eq 'ARRAY') &&
		(ref($self->{__BUFFER__}->[-1]) eq 'ARRAY')){
		@{$sent} = @{$self->{__BUFFER__}->[-1]};
	    }
	    elsif ((ref($sent) eq 'HASH') &&
		(ref($self->{__BUFFER__}->[-1]) eq 'HASH')){
		%{$sent} = %{$self->{__BUFFER__}->[-1]};
	    }
	    else{
		print STDERR "buffered data is not compatible!\n";
		return 0;
	    }
	    __clean_delete($self->{__BUFFER__}->[-1]);
	    pop(@{$self->{__BUFFER__}});
	    return 1;
	}
	__clean_delete($self->{__BUFFER__});
	delete $self->{__BUFFER__};
    }
    return 0;
}


sub read_next_sentence{
    my $self=shift;
    my $sentence=shift;
    my $words=shift;

    my $file=shift || $self->{-file};
    my $encoding=shift || $self->{-encoding};

    my $fh=$self->open_file($file,$encoding);

#     if (! defined $self->{FH}->{$file}){
# 	$self->{FH}->{$file} = new FileHandle;
# 	$self->{FH}->{$file}->open("<$file") || die "cannot open file $file\n";
# 	binmode($self->{FH}->{$file},":encoding($encoding)");
# 	$self->{COUNT}->{$file}=0;
#     }
#     my $fh=$self->{FH}->{$file};

    if (my $sent=<$fh>){
	chomp $sent;
	$self->{COUNT}->{$file}++;
	if ($sent=~/^\<s (snum|id)=\"?([^\"\>]+)\"?(\s|\>)/i){
	    $self->{SENT_ID}->{$file}=$2;
	}
	else{
	    $self->{SENT_ID}->{$file}=$self->{COUNT}->{$file};
	}
	$self->{LAST_SENT_ID}=$self->{SENT_ID}->{$file};
	$sent=~s/^\<s.*?\>\s*//;
	$sent=~s/\s*\<\/s.*?\>$//;
	if (ref($sentence) eq 'ARRAY'){
	  @{$sentence}=split(/\s+/,$sent);
	  return 1;
	}
	elsif (ref($sentence) eq 'HASH'){   # expect a tree --> make a simple
	  my @words=split(/\s+/,$sent);     # tree structure
	  $self->words2tree(\@words,$sentence,$self->{SENT_ID}->{$file});
	  return 1;
	}
	else{ return $sent; }
    }
    $fh->close;
    delete $self->{FH}->{$file};
    return 0;
}


# make a simple hash structure compatible with treebank trees
# (all words linked to a common root node)
# ---> can treat word alignment as special case of tree alignment!

sub words2tree{
    my $self=shift;
    my ($words,$tree,$sid)=@_;
    %{$tree}=();
    $tree->{ID}=$sid;
    $tree->{NODES}={};
    $tree->{ROOTNODE}="$sid\_0";
    $tree->{NODES}->{"$sid\_0"}={ id => "$sid\_0" };
    $tree->{TERMINALS}=[];
    my $nr=1;
    foreach my $w (@{$words}){
	$tree->{NODES}->{"$sid\_$nr"}->{word}=$w;
	$tree->{NODES}->{"$sid\_$nr"}->{id}="$sid\_$nr";
	$tree->{NODES}->{"$sid\_$nr"}->{PARENTS}->[0]="$sid\_0";
	push(@{$tree->{TERMINALS}},"$sid\_$nr");
	push(@{$tree->{NODES}->{"$sid\_0"}->{CHILDREN}},"$sid\_$nr");
	$nr++;
    }
}

sub current_id{
    my $self=shift;
    if ($_[0]){
	return $self->{SENT_ID}->{$_[0]};
    }
    return $self->{LAST_SENT_ID};
}

sub open_file{
    my $self=shift;

    my $file=shift || $self->{-file};
    my $encoding=shift || $self->{-encoding};

    $self->{-file} = $file;
    $self->{-encoding} = $encoding;

    if (! defined $self->{FH}->{$file}){
	$self->{FH}->{$file} = new FileHandle;
	my $filename = $file;

	# if file doesn't exist but the gzipped version exists
	if ((! -e $file) && (-e $file.'.gz')){$filename=$file.'.gz';}

	if ($filename=~/\.gz$/){
	    $self->{FH}->{$file}->open("gzip -cd < $filename |") ||
		die "cannot open file '$filename'\n";
	}
	else{
	    $self->{FH}->{$file}->open("<$filename") || 
		die "cannot open file '$filename'\n";
	}
	if ($encoding){
	    binmode($self->{FH}->{$file},":encoding($encoding)");
	}
	$self->{COUNT}->{$file}=0;
	return $self->{FH}->{$file};
    }
    else{
	return $self->{FH}->{$file};
    }

    ## shouldn't get here ....
    return undef;
}

sub close_file{
    my $self=shift;
    my $file=shift;
    if (defined $self->{FH}){
	if (defined $self->{FH}->{$file}){
	    if (ref($self->{FH}->{$file})=~/FileHandle/){
		$self->{FH}->{$file}->close;
		delete $self->{FH}->{$file};
	    }
	}
    }
}	    

sub is_open{
    my $self=shift;
    my $file=shift;
    if (defined $self->{FH}){
	if (defined $self->{FH}->{$file}){
	    return 1;
	}
    }
    return 0;
}	    


sub close{
    my $self=shift;
    if (defined $self->{FH}){
	if (ref($self->{FH}) eq 'HASH'){
	    foreach my $f (keys %{$self->{FH}}){
		$self->close_file($f);
	    }
	}
    }
}

sub open{
    my $self=shift;
    return $self->open_file(@_);
}


sub print_header{
    my $self=shift;
    return '';
}

sub print_tail{
    my $self=shift;
    return '';
}

sub print_sentence{
    my $self=shift;
    my $words=shift;
    my $str='';
    if (ref($words) eq 'ARRAY'){
	$str=join(' ',@{$words});
    }
    return $str;
}

# try to delete complex structures
# without circular references behind causing any memory leaks

sub __clean_delete{
    my $data=shift;
    if (ref($data) eq 'ARRAY'){
	foreach my $e (@{$data}){
	    __clean_delete($e);
	}
	@{$data}=();
    }
    elsif (ref($data) eq 'HASH'){
	foreach my $e (%{$data}){
	    __clean_delete($e);
	}
	%{$data}=();
    }
    $data = undef;
}



1;
__END__

=head1 NAME

Lingua::Align::Corpus - reading corpus data

=head1 Description

Read corpus data in various formats. Default format = plain text, 1 sentence per line. For other types (parsed corpora etc): Use the C<-type> flag.

=head1 SYNOPSIS

  use Lingua::Align::Corpus;

  my $corpus = new Lingua::Align::Corpus(-file => $corpusfile);

  my @words=();
  while ($corpus->next_sentence(\@words)){
    print "\n",$corpus->current_id,"> ";
    print $treebank->print_sentence(\%tree);
  }

  my $treebank = new Lingua::Align::Corpus(-file => $corpusfile,
                                           -type => 'TigerXML');

  my %tree=();
  while ($treebank->next_sentence(\%tree)){
    print $treebank->print_sentence(\%tree);
    print "\n";
  }


=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>jorg.tiedemann@lingfil.uu.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
