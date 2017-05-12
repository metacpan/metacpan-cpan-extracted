#
#
#
#

package Lingua::Align::Classifier;

use strict;


use Lingua::Align::Classifier::Megam;
use Lingua::Align::Classifier::Clues;

# use Lingua::Align::Classifier::LibSVM;


sub new{
    my $class=shift;
    my %attr=@_;
    my $self;

    my $classifier="megam";
    if (exists $attr{-classifier}){
	$classifier = $attr{-classifier};
	delete $attr{-classifier};	
	if ($classifier=~/clue/i){
	    return $self=new Lingua::Align::Classifier::Clues(%attr);
	}
	elsif ($classifier=~/svm/i){
	    eval 'require Lingua::Align::Classifier::LibSVM';
	    if ($@){
		die "cannot load libSVM ($@)\n";
	    }
	    return $self=new Lingua::Align::Classifier::LibSVM(%attr);
	}
    }
    ## default = MEGAM classifier!
    return $self = new Lingua::Align::Classifier::Megam(%attr);

}


sub initialize_training{}
sub add_train_instance{}
sub start_development_data{}
sub train{}

sub initialize_classification{}
sub load_model{}
sub add_test_instance{}
sub classify{}

1;

__END__

=head1 NAME

Lingua::Align::Classifier - Class factory for link classification

=head1 SYNOPSIS

=head1 SEE ALSO

L<Lingua::Align::Classifier::Megam>

=head1 AUTHOR

Joerg Tiedemann, E<lt>jorg.tiedemann@lingfil.uu.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
