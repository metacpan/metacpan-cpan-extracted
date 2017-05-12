
package Lingua::Align::Classifier::Clues;

use vars qw(@ISA);
use strict;
use Lingua::Align::Classifier;

use FileHandle;
use IPC::Open3;

@ISA = qw( Lingua::Align::Classifier );




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



sub initialize_training{
    my $self=shift;
    $self->{TRAIN_CORRECT}={};
    $self->{TRAIN_TOTAL}={};

    if (not exists $self->{-clue_min_freq}){
	$self->{-clue_min_freq}=5;
    }

}


sub add_train_instance{
    my ($self,$label,$feat,$weight)=@_;

    foreach (keys %{$feat}){
	if ($$feat{$_}>0.5){
	    if ($label == 1){
#		$self->{TRAIN_CORRECT}->{$_}++;
		$self->{TRAIN_CORRECT}->{$_}+=$weight;
	    }
#	    $self->{TRAIN_TOTAL}->{$_}++;
	    $self->{TRAIN_TOTAL}->{$_}+=$weight;
	}
    }

}

sub train{
    my $self = shift;
    my $model = shift || '__clues.'.$$;

# .... save the model parameters

    print STDERR "create model $model\n" if ($self->{-verbose});
    open F,">$model" || die "cannot open model file $model\n";

    foreach (keys %{$self->{TRAIN_CORRECT}}){
#	print STDERR "freq: $self->{TRAIN_TOTAL}->{$_} -- $self->{-clue_min_freq}\n";
	next if ($self->{TRAIN_TOTAL}->{$_}<$self->{-clue_min_freq});
	print F $_,' ',
	$self->{TRAIN_CORRECT}->{$_}/$self->{TRAIN_TOTAL}->{$_},"\n";
    }
    close F;

    return $model;
}







sub initialize_classification{
    my $self=shift;
    my $model = shift || '__clues.'.$$;

    return $self->load_model($model);

}

sub load_model{
    my $self=shift;
    my $model = shift || '__clues.'.$$;

    open F,"<$model" || die "cannot open model file $model\n";
    %{$self->{CLUEWEIGHTS}} = ();
    while (<F>){
	chomp;
	my ($name,$weight) = split(/\s+/);
	$self->{CLUEWEIGHTS}->{$name}=$weight;
    }

    close F;
    return $self->{CLUEWEIGHTS};

}


sub add_test_instance{
    my ($self,$feat)=@_;
    my $label = $_[2] || 0;

    if (not ref($self->{TEST_DATA})){
	$self->{TEST_DATA}=[];
	$self->{TEST_LABEL}=[];
    }
    push(@{$self->{TEST_DATA}},join(' ',%{$feat}));
    push(@{$self->{TEST_LABEL}},$label);
}



sub classify{
    my $self=shift;
    my $model = shift || '__clues.'.$$;

    return () if (not ref($self->{TEST_DATA}));

    if (not ref($self->{CLUEWEIGHTS})){
	$self->initialize_classification($model);
    }

    # send input data to the megam process

    my @scores=();
    foreach my $data (@{$self->{TEST_DATA}}){
	my $label=shift(@{$self->{TEST_LABEL}});

	my @parts = split(/\s+/,$data);
	my %clues=@parts;
	my $score=0;
	foreach my $c (sort keys %clues){
	    if (exists $self->{CLUEWEIGHTS}->{$c}){
		my $ClueScore=$self->{CLUEWEIGHTS}->{$c}*$clues{$c};
		$score += $ClueScore-$ClueScore*$score;
	    }
	}
	my $label=0;
	$label=1 if ($score>0.5);
	push (@scores,$score);
    }

    delete $self->{TEST_DATA};
    delete $self->{TEST_LABEL};

    return @scores;
}






1;

