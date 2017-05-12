use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Builder::Process::ASYNC = 0;

sub get_printed_string {
    my ($printed_string, $is_stderr) = @_;
    my $builder = Gnuplot::Builder::Script->new;
    my $target = $is_stderr ? "" : qq{'-'};
    $builder->add(qq{set print $target});
    $builder->add(qq{print "$printed_string"});
    return $builder->run;    
}

{
    local $Gnuplot::Builder::Process::NO_STDERR = 0;
    is get_printed_string("foobar", 0), "foobar\n";
    is get_printed_string("FOOBAR", 1), "FOOBAR\n";
}

{
    local $Gnuplot::Builder::Process::NO_STDERR = 1;
    is get_printed_string("hoge", 0), "hoge\n";
    is get_printed_string("HOGE", 1), "";
}

{
    note("-- no_stderr option for plotting methods");
    local $Gnuplot::Builder::Process::NO_STDERR = 0;
    my $err_script = Gnuplot::Builder::Script->new(
        term => "dumb",
        print => "",
    )->add(qq{print "hogehoge foobar"});
    my $out_script = $err_script->new_child->set(print => "'-'");
    foreach my $method (qw(plot_with splot_with)) {
        my %params = (dataset => 'sin(x)', no_stderr => 1);
        unlike $err_script->$method(%params), qr/hogehoge foobar/, "$method: no_stderr suppresses STDERR";
        like $out_script->$method(%params), qr/hogehoge foobar/, "$method: no_stderr allows STDOUT";
    }
    foreach my $method (qw(multiplot_with run_with)) {
        my %params = (
            no_stderr => 1,
            do => sub {
                my ($writer) = @_;
                $writer->('plot sin(x)');
            }
        );
        unlike $err_script->$method(%params), qr/hogehoge foobar/, "$method: no_stderr suppresses STDERR";
        like $out_script->$method(%params), qr/hogehoge foobar/, "$method: no_stderr allows STDOUT";
    }
}

done_testing;
