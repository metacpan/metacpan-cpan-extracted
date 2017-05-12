package Kwiki::DB::Test;
use Kwiki;

our @EXPORT=qw(load_hub);

sub load_hub {
    my $kwiki = Kwiki->new;
    my $hub   = $kwiki->load_hub(@_);
    $hub->registry->load;
    $hub->add_hooks;
    $hub->pre_process;
    return $hub;
}
