package Lingua::Align::Corpus::Factored;

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus);


sub read_next_sentence{
    my $self=shift;
    my $factors=shift;

    my @tokens=();
    if ($self->SUPER::next_sentence(\@tokens,@_)){
	foreach (@tokens){
	    my $idx=@{$factors};
	    @{$$factors[$idx]}=split(/\|/);
	}
	return 1;
    }
    return 0;
}

sub print_sentence{
    my $self=shift;
    my $factors=shift;

    if (ref($factors) eq 'ARRAY'){
	my @words=();
	foreach my $f (@{$factors}){
	    if (ref($f) eq 'ARRAY'){
		push(@words,join('|',@{$f}));
	    }
	    else{
		push(@words,$f);
	    }
	}
	return join(' ',@words);
    }
    return '';
}


1;
__END__


=head1 NAME

Lingua::Align::Corpus::Factored - Read factored corpora (Moses format)

=head1 SYNOPSIS

  use Lingua::Align::Corpus::Factored;

  my $corpus = new Lingua::Align::Corpus::Factored(-file => $corpusfile);

  my @words=();
  while ($corpus->next_sentence(\@words)){
    print "\n",$corpus->current_id,"> ";
    foreach (0..$#words){
      print "word $_ = "
      print join(',',@{$words[$_]});
      print "\n";
    }
    print "---------------------\n";
  }

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
