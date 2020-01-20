package TestBackup;
use File::Cmp qw(fcmp);
use File::Temp qw(tempdir);
use Exporter;
use re '/aa';
use Carp;
use Test;

our @ISA = qw(Test);
our @EXPORT=qw(makefile fileok plan ok);

sub import {
    my $pkg = shift;
    my $workdir = tempdir(CLEANUP => 1);
    chdir($workdir) or croak "can't change to $workdir: $!";
    @pattern = grep { /[\w\d]+/ } map { chr($_) } (1..127);
    delete $ENV{VERSION_CONTROL};
    $pkg->export_to_level(1, @_);
}    

sub makefile {
    my $file = shift;
    my $size = shift // 1024;

    open(FH, '>', $file) or croak "can't create file $file (wd $workdir): $!";
    while ($size) {
	my $n = @pattern;
	$n = $size if $n > $size;
	syswrite(FH, join('',@pattern[0..$n])) or
		 croak "write error creating $file: $!";
	$size -= $n;
    }
    close FH
}

sub fileok {
    ok(fcmp(@_));
}

1;
