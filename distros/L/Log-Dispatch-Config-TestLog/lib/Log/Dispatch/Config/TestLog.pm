#!/usr/bin/perl

package Log::Dispatch::Config::TestLog;

use strict;
use warnings;

our $VERSION = "0.02";

use Sub::Override;
use Test::Builder;
use Log::Dispatch::Config;
use Path::Class;

use base qw(Log::Dispatch::Configurator);

sub new {
    my ( $class, %args ) = @_;

    bless {
		%args,
        global => {
            dispatchers => [qw(file)],
			%{ $args{global} || {} }
        },
        file => {
            class     => 'Log::Dispatch::File',
            min_level => 'debug',
			%{ $args{file} || {} }
        },
    }, $class;
}

sub get_attrs {
    my ( $self, $name ) = @_;
    $self->{$name};
}

sub get_attrs_global { shift->get_attrs("global") }

sub needs_reload { return }

sub caller_file_to_log_file {
	my ( $self, $file, %args ) = @_;

	my $log_dir = dir( $ENV{TEST_LOG_DIR} || $args{log_dir} || $file->parent );

	unless ( -d $log_dir ) {
		$log_dir->mkpath
			or die "Couldn't create test log directory $log_dir";
	}

	unless ( -w $log_dir ) {
		die "Log directory $log_dir is not writable";
	}

	return $log_dir->file( $file->basename . ".log" )->stringify;
}

my @overrides;

sub import {
    my ( $self, %args ) = @_;

	require Test::Builder;

	my $file = file($0)->absolute;

    Log::Dispatch::Config->configure(
        $self->new(
			%args,
            file => {
				mode     => "write",
				filename => $self->caller_file_to_log_file( $file, %args ),
				format   => "[%d] [%p] %m\n",
				%{ $args{file} || {} }
			},
        ),
    );

	my $logger = Log::Dispatch::Config->instance;

	$logger->info("Starting test $0, pid = $$");

	my $tap_level = exists($args{tap_log_level})
		? $args{tap_log_level}
		: "info";

	if ( defined( $tap_level ) ) {
		
		unless ( @overrides ) {
			foreach my $print ( qw(_diag _print_to_fh) ) {
				no strict 'refs';
				my $fq = "Test::Builder::$print";
				my $orig = \&$fq;

				push @overrides, Sub::Override->new( $fq, sub {
					my ( $builder, @output ) = @_;
					shift @output if $print eq '_print_to_fh'; # first arg is output handle
					chomp( my $out = "@output" );
					$logger->$tap_level("TAP: $out") if length $out;
					goto $orig;
				});
			}
		}
	}
}

END {
    Log::Dispatch::Config->__instance && Log::Dispatch::Config->instance->info("Finishing test $0");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Dispatch::Config::TestLog - Set up Log::Dispatch::Config for a test run

=head1 SYNOPSIS

	use Log::Dispatch::Config::TestLog;

=head1 DESCRIPTION

This module will load L<Log::Dispatch::Config> and set things up so that:

=over 4

=item *

By default there is a single dispatcher, C<file>, a L<Log::Dispatch::File>
instance, whose output is the name of the test appended with C<log>.

If the environment variable C<TEST_LOG_DIR> is set or the C<log_dir> parameter
is given to C<import>, then log files will be created in that directory
instead.

=item *

All TAP output is logged with the C<info> level by default. If the C<tap_level>
parameter is given to C<import> then that level will be used instead. C<undef>
can be passed to disable TAP output.

Note that this only works for L<Test::Builder> based tests.

=back

=head1 TODO

=over 4

=item Better test logging

Make the test logging use different levels for certain things (fails increase
the level, for instance), and consider scrubbing multi line output since we
provide a one line format by default.

=back

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/log-dispatch-config-testlog>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008, 2010 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
