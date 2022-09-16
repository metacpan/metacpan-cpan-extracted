package HTTP::OAI::Debug;

=pod

=head1 NAME

B<HTTP::OAI::Debug> - debug the HTTP::OAI libraries

=head1 DESCRIPTION

This package is a copy of L<LWP::Debug> and exposes the same API. In addition to "trace", "debug" and "conns" this exposes a "sax" level for debugging SAX events.

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(level trace debug conns);

our $VERSION = '4.12';

use Carp ();

my @levels = qw(trace debug conns sax);
%current_level = ();


sub import
{
    my $pack = shift;
    my $callpkg = caller(0);
    my @symbols = ();
    my @levels = ();
    for (@_) {
	if (/^[-+]/) {
	    push(@levels, $_);
	}
	else {
	    push(@symbols, $_);
	}
    }
    Exporter::export($pack, $callpkg, @symbols);
    level(@levels);
}


sub level
{
    for (@_) {
	if ($_ eq '+') {              # all on
	    # switch on all levels
	    %current_level = map { $_ => 1 } @levels;
	}
	elsif ($_ eq '-') {           # all off
	    %current_level = ();
	}
	elsif (/^([-+])(\w+)$/) {
	    $current_level{$2} = $1 eq '+';
	}
	else {
	    Carp::croak("Illegal level format $_");
	}
    }
}


sub trace  { _log(@_) if $current_level{'trace'}; }
sub debug  { _log(@_) if $current_level{'debug'}; }
sub conns  { _log(@_) if $current_level{'conns'}; }
sub sax    { _log(@_) if $current_level{'sax'}; }


sub _log
{
    my $msg = shift;
	$msg =~ s/\n$//;
	$msg =~ s/\n/\\n/g;

    my($package,$filename,$line,$sub) = caller(2);
    print STDERR "$sub: $msg\n";
}

1;
