package Test::Framework;

#
# Common resources for tests
#

use File::Spec::Functions qw( catfile );
use File::Temp qw( tmpnam );
use POSIX qw( mkfifo );

# some of the program text is UTF-8
use utf8;

use base qw( Exporter );

our(%file2path, %file2enc, %filecontent, @test_files, $fifo_supported);

@EXPORT = qw(
	make_test_data
	remove_test_data
	%file2path
	%file2enc
	%filecontent
	@test_files
	write_fifo
	$fifo_supported
	hexdump
    );

%file2enc = (
	'utf-32le.txt' => 'UTF-32LE',
	'utf-32be.txt' => 'UTF-32BE',
	'utf-16le.txt' => 'UTF-16LE',
	'utf-16be.txt' => 'UTF-16BE',
	'utf-8.txt'    => 'UTF-8',
	'no_bom.txt'   => '',
    );
%filecontent = (
	'utf-32le.txt' => 'Ûñíçôđè',
	'utf-32be.txt' => 'Ûñíçôđè',
	'utf-16le.txt' => 'Ûñíçôđè',
	'utf-16be.txt' => 'Ûñíçôđè',
	'utf-8.txt'    => 'Ûñíçôđè',
	'no_bom.txt'   => 'ascii',
    );
@test_files = keys %file2enc;

$file2path{$_} = catfile(qw(t data), $_) for @test_files;

# write data into files
sub make_test_data {
    while (my($name, $path) = each %file2path) {
	my $enc = $file2enc{$name};
	my $mode = $enc ? ">:encoding($enc)" : '>';

	open my $fh, $mode, $path
	    or die "Can't write '$path': $!\n";

	print $fh "\x{feff}" if $enc;
	print $fh $filecontent{$name}, "\n";

	close $fh;
    }
}

sub remove_test_data {
    for my $path (values %file2path) {
	unlink $path or warn "Couldn't remove '$path': $!";
    }
}

eval {
    my $tmp = tmpnam;

    if (mkfifo($tmp, 0700)) {
	unlink $tmp;
    }
    else {
	die $!;
    }
};

if ($@ =~ /^POSIX::mkfifo not implemented on this architecture/) {
    $fifo_supported = 0;
}
else {
    $fifo_supported = 1;
}

sub write_fifo ($) {
    my $bytes = shift;

    my $fifo = tmpnam();

    mkfifo($fifo, 0700) or die "Couldn't create fifo at '$fifo': $!";

    my $pid = fork();
    if ($pid) {
        # I'm the parent
	return ($pid, $fifo);
    }
    elsif (!defined $pid) {
        die "$0: fork: $!";
    }
    else {
        # I'm the child
	if (open my $writer, '>', $fifo) {
	    print $writer $bytes;
	    close $writer;
	}
	else {
	    unlink $fifo or die "Couldn't write or unlink fifo at '$fifo': $!";
	    die "Couldn't write to fifo at '$fifo': $!";
	}

	exit 0;
    }
}

sub hexdump {
    use bytes;
    join(' ', map { unpack("H2", pack("C1", ord)) } split('', $_[0]))
}

1;
