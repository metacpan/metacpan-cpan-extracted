#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

Benchmarks... what else could I say...

=head1 POWERED BY

     _    __ _____ _____ __  __ __ __   __
    | |__|  |     |     |  \|  |__|\  \/  /
    |  . |  |  |  |  |  |      |  | >    <
    |____|__|_____|_____|__|\__|__|/__/\__\

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Log::Handler;
use Benchmark;

sub buffer { }
my $log1 = Log::Handler->new(); # simple pattern
my $log2 = Log::Handler->new(); # default pattern & suppressed
my $log3 = Log::Handler->new(); # complex pattern
my $log4 = Log::Handler->new(); # message pattern
my $log5 = Log::Handler->new(); # filtered caller
my $log6 = Log::Handler->new(); # filtered message
my $log7 = Log::Handler->new(); # categories

$log1->add(
    forward => {
        alias      => 'simple pattern',
        maxlevel   => 'notice',
        minlevel   => 'notice',
        forward_to => \&buffer,
        message_layout => '%L - %m',
    }
);

$log2->add(
    forward => {
        alias      => 'default pattern & suppressed',
        maxlevel   => 'warning',
        minlevel   => 'warning',
        forward_to => \&buffer,
    }
);

$log3->add(
    forward => {
        alias      => 'complex pattern',
        maxlevel   => 'info',
        minlevel   => 'info',
        forward_to => \&buffer,
        message_layout => '%T [%L] %H(%P) %m (%C)%N',
    }
);

$log4->add(
    forward => {
        alias      => 'message pattern',
        maxlevel   => 'error',
        minlevel   => 'error',
        forward_to => \&buffer,
        message_layout  => '%m',
        message_pattern => [qw/%T %L %P/],
    }
);

$log5->add(
    forward => {
        alias      => 'filtered caller',
        maxlevel   => 'emerg',
        minlevel   => 'emerg',
        forward_to => \&buffer,
        filter_caller => qr/^Foo\z/,
    }
);

$log5->add(
    forward => {
        alias      => 'filtered caller',
        maxlevel   => 'emerg',
        minlevel   => 'emerg',
        forward_to => \&buffer,
        filter_caller => qr/^Bar\z/,
    }
);

$log5->add(
    forward => {
        alias      => 'filtered caller',
        maxlevel   => 'emerg',
        minlevel   => 'emerg',
        forward_to => \&buffer,
        filter_caller => qr/^Baz\z/,
    }
);

$log6->add(
    forward => {
        alias      => 'filtered message',
        maxlevel   => 'alert',
        minlevel   => 'alert',
        forward_to => \&buffer,
        filter_message => qr/bar/,
    }
);

$log6->add(
    forward => {
        alias      => 'filtered message',
        maxlevel   => 'alert',
        minlevel   => 'alert',
        forward_to => \&buffer,
        filter_message => qr/bar/,
    }
);

$log7->add(
    forward => {
        alias      => 'categories',
        maxlevel   => 'alert',
        minlevel   => 'alert',
        forward_to => \&buffer,
        category   => "Cat::Foo",
    }
);

my $count   = 100_000;
my $message = 'foo bar baz';

run("simple pattern output took", $count, sub { $log1->notice($message) } );
run("default pattern output took", $count, sub { $log2->warning($message) } );
run("complex pattern output took", $count, sub { $log3->info($message) } );
run("message pattern output took", $count, sub { $log4->error($message) } );
run("suppressed output took", $count, sub { $log2->debug($message) } );
run("filtered caller output took", $count, \&Foo::emerg );
run("suppressed caller output took", $count, \&Foo::Bar::emerg );
run("filtered messages output took", $count, sub { $log6->alert($message) } );
run("categorized messages output took", $count, \&Cat::Foo::Bar::alert );
run("suppressed categories output took", $count, \&Cat::Bar::Baz::alert );

sub run {
    my ($desc, $count, $bench) = @_;
    my $time = timeit($count, $bench);
    print sprintf('%-30s', $desc), ' : ', timestr($time), "\n";
}

# Filter messages by caller
package Foo;
sub emerg { $log5->emerg($message) }

# Suppressed messages by caller
package Foo::Bar;
sub emerg { $log5->emerg($message) }

package Cat::Foo::Bar;
sub alert { $log7->alert($message) }

package Cat::Bar::Baz;
sub alert { $log7->alert($message) }

1;
