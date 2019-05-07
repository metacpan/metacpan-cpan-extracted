package Devel::KYTProf::Profiler::Redis::Fast;
use 5.012001;
use strict;
use warnings;
use Redis::Fast;

our $VERSION = "0.01";

sub strip {
    my $s = shift;
    if (length($s) > 255) {
        return substr($s, 0, 252) . "...";
    }
    return $s;
}

sub apply {
    # command for a key
    Devel::KYTProf->add_prof(
        'Redis::Fast',
        '__std_cmd',
        sub {
            my ($orig, $self, $cmd, @args) = @_;
            my $data = {
                command => uc($cmd),
            };
            if (lc($cmd) =~ /get/ && lc($cmd) ne "getset") {
                $data->{key} = strip(join(" ", @args));
            }
            else {
                $data->{key} = @args > 0 ? strip($args[0]) : "";
            }
            return [
                '%s %s',
                ['command', 'key'],
                $data,
            ];
        },
    );

    for my $cmd (qw/ ping quit shutdown keys select info subscribe psubscribe unsubscribe punsubscribe /) {
        Devel::KYTProf->add_prof(
            'Redis::Fast',
            $cmd,
            sub {
                my ($orig, $self, @args) = @_;
                my $data = {
                    command => uc($cmd),
                };
                if (@args > 0) {
                    if ($cmd =~ /subscribe/) {
                        pop @args; # remove subref
                    }
                    $data->{args} = strip(join(" ", @args));
                    return ['%s %s', ['command', 'args'], $data];
                }
                return ['%s', ['command'], $data];
            },
        );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Devel::KYTProf::Profiler::Redis::Fast - KYTProf profiler for Redis::Fast

=head1 SYNOPSIS

    use Devel::KYTProf;
    Devel::KYTProf->apply_prof('Redis::Fast');
    
    my $redis = Redis::Fast->new(server => 'localhost:6379');
    $redis->set('foo' => 'bar');
    $redis->mget('foo', 'bar');
    $redis->info;
    $redis->keys("*");

KYTProf will output profiles as below.

    0.114 ms  [Redis::Fast]  SET foo  | main:5
    0.080 ms  [Redis::Fast]  MGET foo bar  | main:6
    0.155 ms  [Redis::Fast]  info   | main:7
    0.079 ms  [Redis::Fast]  keys *  | main:8

=head1 DESCRIPTION

Devel::KYTProf::Profiler::Redis::Fast is KYTProf profiler for Redis::Fast.

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

