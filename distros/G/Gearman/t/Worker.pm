package t::Worker;
use strict;
use warnings;
use base qw/Exporter/;
use Gearman::Worker;
use Proc::Guard;
our @EXPORT = qw/
    new_worker
    /;

sub new_worker {
    my (%args) = @_;
    defined($args{func}) || die "no func in passed arguments";
    my %func = %{ delete $args{func} };
    my $w    = Gearman::Worker->new(%args);

    while (my ($f, $v) = each(%func)) {
        $w->register_function($f, ref($v) eq "ARRAY" ? @{$v} : $v);
    }

    my $pg = Proc::Guard->new(
        code => sub {
            while (1) {
                $w->work(
                    stop_if => sub {
                        my ($idle, $last_job_time) = @_;
                        return $idle;
                    }
                );
            } ## end while (1)
        }
    );

    return $pg;
} ## end sub new_worker

1;
