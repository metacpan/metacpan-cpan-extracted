package IO::Factotum::ARGV;

use v5.16;
use warnings;

require IO::Factotum;

sub TIEHANDLE {
    my $class = shift;
    bless { fh => undef, nr => 0, started => 0 }, $class;
}

# Open the next file of @ARGV, which is looked at here for the first
# time, after the program has taken its options.  As with the plain
# <>, the standard input is read when there is no file, the name goes
# to $ARGV, and a file which can not be opened is skipped.
sub _next {
    my $self = shift;
    $self->{fh} = undef;
    my @stdin = !$self->{started}++ && !@ARGV ? ('-') : ();
    while (defined(my $file = @stdin ? shift @stdin : shift @ARGV)) {
	if (my $fh = IO::Factotum::open_input($file)) {
	    $main::ARGV = $file;
	    return $self->{fh} = $fh;
	}
	warn "Can't open $file: $!\n";
    }
    undef;
}

sub _readline {
    my $self = shift;
    while (1) {
	if (my $fh = $self->{fh}) {
	    my $line = readline $fh;
	    if (defined $line) {
		# $. is that of the handle just read: the lines of the
		# files are counted on, as the plain <> does
		$. = ++$self->{nr};
		return $line;
	    }
	}
	$self->_next or return undef;
    }
}

sub READLINE {
    my $self = shift;
    return $self->_readline unless wantarray;
    my @lines;
    while (defined(my $line = $self->_readline)) {
	push @lines, $line;
    }
    @lines;
}

# eof() with empty parentheses (2) is the end of the last file, and it
# goes on to the next file to see it.  The others are the end of the
# file being read.
sub EOF {
    my($self, $how) = @_;
    if (($how // 0) == 2) {
	while (1) {
	    return '' if $self->{fh} and not eof $self->{fh};
	    $self->_next or return 1;
	}
    }
    not $self->{fh} or eof $self->{fh};
}

# close ARGV starts the line numbers again
sub CLOSE {
    my $self = shift;
    my $fh = delete $self->{fh};
    $self->{nr} = 0;
    $fh ? close $fh : 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Factotum::ARGV - tie class to read the files of @ARGV by IO::Factotum

=head1 SYNOPSIS

    IO::Factotum::tie_argv();

    while (<>) {
        print "$ARGV: $_";
    }

=head1 DESCRIPTION

This is the class C<ARGV> is tied to by C<IO::Factotum::tie_argv>.
See L<IO::Factotum>.

=cut
