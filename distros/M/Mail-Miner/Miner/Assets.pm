package Mail::Miner::Assets;
use Mail::Miner;
use strict;
use warnings;
use Carp;

# Preloaded methods go here.

#This is the generic method
sub analyse {
    my ($class, %hash) = @_;
    for (qw(head body)) {
    croak "Need to supply a get$_ closure" if ref $hash{"get$_"} ne "CODE";
    }
    
    no strict 'refs'; 
    my @assets;
    for my $module (Mail::Miner->modules()) {
        push @assets, map { 
                        ref $_ eq "HASH" ? $_ :
                        { asset => $_, creator => $module } 
                      }
                        $module->process(%hash);
    }

    $hash{store}->(@assets) if ref $hash{store} eq "CODE";
    return @assets;
}

# This is the specific method
sub miner_analyse {
    my $obj = shift;
    Mail::Miner::Assets->analyse(
            getbody => sub { $obj->content->bodyhandle->as_string },
            gethead => sub { $obj->content->head->as_string },
            store   => sub { $obj->add_to_assets($_) for @_ }
    );
}

1;
