
package Lingua::Align::Classifier::LibSVM;

use vars qw(@ISA);
use strict;

use FileHandle;
use IPC::Open3;
use Algorithm::SVM;
use Algorithm::SVM::DataSet;

@ISA = qw( Lingua::Align::Classifier::Megam );


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
    $self->{SVM} = new Algorithm::SVM(Type => 'C-SVC',
				      Kernel => 'radial');
    $self->{SVM_TRAINSET}=[];

    ## if we want to create a file with training data ....
    ## --------------------------------------------------------------
    # $self->{TRAINFILE} = $self->{-training_data} || '__train.'.$$;
    # $self->{TRAIN_FH} = new FileHandle;
    # $self->{TRAIN_FH}->open(">$self->{TRAINFILE}") || 
    # 	die "cannot open training data file $self->{TRAINFILE}\n";
    # binmode($self->{TRAIN_FH}, ":utf8");

}


sub add_train_instance{
    my ($self,$label,$feat,$weight)=@_;
    if (not ref($self->{SVM})){
	$self->initialize_training();
    }

    if ($label==0){$label='-1';}
    if ($label==1){$label='+1';}

    if (defined($weight) && ($weight != 1)){
	if ($weight<1){
	    print STDERR "weights are not supported!\n --> use weight=1!\n";
	}
    }
    else{$weight=1;}

    my @data=();
    foreach (keys %{$feat}){
	if (! exists $self->{__FEATIDS__}->{$_}){
	    $self->{__FEATCOUNT__}++;
	    $self->{__FEATIDS__}->{$_}=$self->{__FEATCOUNT__};
	}
	$data[$self->{__FEATIDS__}->{$_}]=$$feat{$_};
#	print STDERR "feature $_ ($self->{__FEATIDS__}->{$_}) = $$feat{$_} \n";
    }

    my $instance = new Algorithm::SVM::DataSet(Label => $label, 
					       Data => \@data);
#    for (my $i=0;$i<$weight;$i++){
	push(@{$self->{SVM_TRAINSET}},$instance);
#    }


## print data instances to a file .... 
##----------------------------------------
#     my $fh=$self->{TRAIN_FH};
#     print $fh $label;
#     foreach (0..$#data){
# 	if ($data[$_]){
# #	    print STDERR "$_:$data[$_]\n";
# 	    print $fh " $_:$data[$_]";
# 	}
#     }
#     print $fh "\n";


}

sub train{
    my $self = shift;
    my $model = shift || '__svm.'.$$;

    $self->{SVM}->train(@{$self->{SVM_TRAINSET}});

    # cross validation on training set
    if ($self->{-verbose}){
	my $accuracy = $self->{SVM}->validate(5);
	print STDERR "accuracy = $accuracy\n";
    }

    $self->{SVM}->save($model);
    $self->save_feature_ids($model.'.ids',$self->{__FEATIDS__});

    ################################ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ## save feature ids ......
    ## ---> need them for feature extraction for aligning!!!!!!!!!
    ################################ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    return $model;
}

sub save_feature_ids{
    my $self=shift;
    my ($file,$feat)=@_;
    open F,">$file" || die "cannot open feature ID file $file\n";
    foreach (keys %{$feat}){
	print F "$$feat{$_}\t$_\n";
    }
    close F;
}

sub load_feature_ids{
    my $self=shift;
    my ($file,$feat)=@_;
    open F,"<$file" || die "cannot open feature ID file $file\n";
    while (<F>){
	chomp;
	my ($id,$f)=split(/\t/);
	$$feat{$f}=$id;
    }
    close F;
}





sub initialize_classification{
    my $self=shift;
    my $model=shift;

    $self->{__FEATCOUNT__}=0;
    $self->{__FEATIDS__}={};

#				      Kernel => 'radial',
#				      Type => 'one-class',
#				      Gamma  => 64,
#				      C      => 8);

    $self->{SVM} = new Algorithm::SVM(Model => $model,
				      C      => 2048,
				      Gamma  => 0.125,
				      Kernel => 'radial',
				      Type => 'C-SVC');

# features = catpos:moses ???
#
# Best c=2048.0, g=0.125 CV rate=97.9978
# Training...
# Output model: __train.28910.model
# svm_type c_svc
# kernel_type rbf
# gamma 0.125
# nr_class 2
# total_sv 389
# rho 19.5711
# label -1 1
# nr_sv 213 176

    $self->{SVM_MODEL} = $model;
    $self->load_feature_ids($model.'.ids',$self->{__FEATIDS__});

    return 1;
}

sub add_test_instance{
    my ($self,$feat)=@_;
    my $label = $_[2] || 0;

    if (not ref($self->{TEST_DATA})){
	$self->{TEST_DATA}=[];
	$self->{TEST_LABEL}=[];
    }

#    if ($label==0){$label='-1';}
#    if ($label==1){$label='+1';}

    my @data=();
    foreach (keys %{$feat}){
	if (! exists $self->{__FEATIDS__}->{$_}){
	    if ($self->{-verbose}){
		print STDERR "feature $_ does not exist! ignore!\n";
	    }
	}
	$data[$self->{__FEATIDS__}->{$_}]=$$feat{$_};
    }

    my $instance = new Algorithm::SVM::DataSet(Label => $label, 
					       Data => \@data);
    push(@{$self->{TEST_DATA}},$instance);
    push(@{$self->{TEST_LABEL}},$label);

}


sub classify{
    my $self=shift;
    my $model = shift || '__svm.'.$$;

    return () if (not ref($self->{TEST_DATA}));

    if ($self->{SVM_MODEL} ne $model){
	$self->initialize_classification($model);
    }

    # send input data to the megam process

    my @scores=();
    my @labels=();
    foreach my $data (@{$self->{TEST_DATA}}){
	my $res=$self->{SVM}->predict($data);
	my $val=$self->{SVM}->predict_value($data);
#	my $prob=$self->{SVM}->getSVRProbability();
#	if ($res>0){
#	    print STDERR "!!!!! positive!!!!!!\n";
#	}

	if ($res>0){
#	    print STDERR "$res ... $val ...\n";
	    push (@scores,$res);
	    push (@labels,1);
	}
    }

    delete $self->{TEST_DATA};
    delete $self->{TEST_LABEL};

    return @scores;

}


1;

