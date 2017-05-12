package Log::Log4perl::Appender::File::FixedSize;

use 5.006;
use strict;
use warnings;

use File::RoundRobin;

=head1 NAME

Log::Log4perl::Appender::File::FixedSize - Log::Log4perl appender which creates files limited in size

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module allows you to create log files with a limited size. Once the file
reaches the size limit it starts to overwrite the old content with the new one
in the same order it was added.

Example:

    use Log::Log4perl::Appender::File::FixedSize;

    my $file = Log::Log4perl::Appender::File::FixedSize->new(
                        filename => '/tmp/log.txt',
                        size     => '10Mb',
    );
    ...
    
    $file->log(message => 'Hello world');

=head1 Log::Log4perl config

Here is an example how you can use this module with Log::Log4perl

	log4perl.rootLogger=DEBUG, test
    
	log4perl.appender.test=Log::Log4perl::Appender::File::FixedSize
	log4perl.appender.test.filename=test.log
	log4perl.appender.test.mode=append
	log4perl.appender.test.size=1M
    
	log4perl.appender.test.layout=PatternLayout
	log4perl.appender.test.layout.ConversionPattern=[%r] %F %L %c - %m%n

Basically it's the same config as for Log::Log4perl::Appender::File with an extra paramater : I<size>


=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
	my $class = shift;
	my %params = @_;
	
	$class = ref($class) if ref($class);
	
	my $self = {
				__file__ => File::RoundRobin->new( 
								path => $params{filename},
								size => $params{size},
								mode => $params{mode} || "new",
								autoflush => $params{autoflush}
				 			),
				};
			
	bless $self, $class;
	
	return $self;
}

=head2 log

=cut

sub log {
	my ($self,%params) = @_;
		
	$self->{__file__}->write($params{message});
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-appender-file-fixedsize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-Appender-File-FixedSize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Log4perl::Appender::File::FixedSize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Appender-File-FixedSize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Log4perl-Appender-File-FixedSize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Log4perl-Appender-File-FixedSize>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Log4perl-Appender-File-FixedSize/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Log::Log4perl::Appender::File::FixedSize
