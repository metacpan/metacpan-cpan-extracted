#!/usr/bin/perl

=head1 NAME

sample.pl - Example using the Log4Perl Elapsed Pattern Layout.

=head1 SYNOPSIS

./sample.pl > all.txt
grep ' A ' all.txt  > a.txt
grep '^B ' all.txt  > b.txt
sdiff a.txt b.txt
rm all.txt a.txt b.txt

=head1 DESCRIPTION

This example shows how to use the Log4Perl Elapsed Pattern Layout. It also shows
how the layout behaves when used through different appenders with different
thresholds.

=cut

use strict;
use warnings;

use Log::Log4perl qw(:easy);

exit main();

sub main {

	init_logger();
	
	use Time::HiRes qw(sleep);
	INFO "Start";

	sleep 0.1;
	DEBUG "Pause: 0.1 sec";
	
	sleep 1.5;
	INFO  "Pause: 1.5 secs";
	
	sleep 0.5;
	DEBUG "Pause: 0.5 sec";
	
	WARN "End";

	return 0;
}

sub init_logger {
	my $conf = <<'__END__';
log4perl.rootLogger = ALL, A, B

log4perl.appender.A = Log::Log4perl::Appender::Screen
log4perl.appender.A.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.A.layout.ConversionPattern = %5rms %-5p   A %5Rms %m%n
log4perl.appender.A.stderr = 0
log4perl.appender.A.Threshold = ALL

log4perl.appender.B = Log::Log4perl::Appender::Screen
log4perl.appender.B.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
log4perl.appender.B.layout.ConversionPattern = B %5Rms %m%n
log4perl.appender.B.stderr = 0
log4perl.appender.B.Threshold = INFO
__END__
	Log::Log4perl->init(\$conf);
}


=head1 SEE ALSO

L<Log::Log4perl::Layout::PatternLayout::Elapsed>.

=head1 AUTHOR

Emmanuel Rodriguez, E<lt>emmanuel.rodriguez@gmail.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
