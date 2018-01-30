=head1 NAME

Devel::PerlySense::Util::Log - Log routines

=cut



use strict;
use warnings;
use utf8;

package Devel::PerlySense::Util::Log;
$Devel::PerlySense::Util::Log::VERSION = '0.0219';
use base "Exporter";

our @EXPORT = (
    qw/
       debug
       /);






use Carp;
use Data::Dumper;
use File::Basename;
use Path::Class;

use Devel::PerlySense::Home;





=head1 ROUTINES

=head2 debug($message)

Log debug $message to a log file in the HOME log directory.

Return 1.

=cut
my $fileDebug;
my @aHistoryMessage;
my $maxCountHistory = 200;
sub debug {
	my ($message) = @_;

    my $messageLog = localtime() . ": $message\n";

    #Keep recent messages in memory for test diagnostics
    push(@aHistoryMessage, $messageLog);
    @aHistoryMessage > $maxCountHistory and shift(@aHistoryMessage);

    
    $0 =~ /\.t$/ and return 1;  #Don't log when running tests

    $fileDebug ||= do {
        my $oHome = Devel::PerlySense::Home->new();
        file($oHome->dirHomeLog, "debug.log");
        
    } or return 0;

    open(my $fh, ">>", $fileDebug) or return 0;
    $fh->print($messageLog);
    
    return(1);
}





#Debugging aid during CPAN testers failures
#This is a hack, please ignore
sub _textTailDebug {
    my $class = shift;
    return join("\n", @aHistoryMessage);
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
