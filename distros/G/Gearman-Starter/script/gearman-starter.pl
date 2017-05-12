#!/usr/bin/perl
use strict;
use warnings;
use Gearman::Starter;
Gearman::Starter->new_with_options(@ARGV)->run;

__END__

=head1 SYNOPSIS

    % gearman-starter.pl --server=127.0.0.1 MyApp::Worker::Foo
    Options:
        MyApp::Worker::Name                                      (Required)
        --server|s=s@               gearman servers              (Required)
        --max-workers               max workers                  (Default:10)
        --max-requests-per-child    max requests per child       (Default: 100)
        --scoreboard-dir            scoreboard directory         (Optional)
        --listen                    local address for monitoring (Default: 0.0.0.0)
        --port                      local port for monitoring    (Optional)
        --prefix=s

=head1 DESCRIPTION

Gearman worker starter.

=head1 AUTHORS

Tokuhiro Matsuno

Masahiro Nagano

Masayuki Matsuki
