package Linux::GetPidstat::Writer::File;
use 5.008001;
use strict;
use warnings;

use Path::Tiny qw/path/;
use IO::Handle;

sub new {
    my ( $class, %opt ) = @_;

    $opt{file} = path($opt{res_file});
    bless \%opt, $class;
}

sub output {
    my ($self, $program_name, $metric_name, $metric) = @_;

    my $msg = join ",", $self->{now}->datetime, $self->{now}->epoch,
        $program_name, $metric_name, $metric;

    if ($self->{dry_run}) {
        print "(dry_run) file write: $msg\n";
        return;
    }

    $self->{file}->append("$msg\n");
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::GetPidstat::Writer::File - Write pidstat's results to a file

=head1 SYNOPSIS

    use Linux::GetPidstat::Writer::File;

    my $t = localtime;
    my $instance = Linux::GetPidstat::Writer::File->new(
        res_file => './res.log',
        now      => $t,
        dry_run  => '0',
    );
    $instance->output('backup_mysql', 'cpu', '21.20');

=cut


