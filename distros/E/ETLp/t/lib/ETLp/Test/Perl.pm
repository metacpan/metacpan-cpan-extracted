package ETLp::Test::Perl;
use strict;
use warnings;
use File::Copy;
use autodie;

sub add_suffix {
    my %args         = @_;
    my $filename     = $args{filename};
    my $new_filename = $filename . $args{'suffix'};
    move($filename, $new_filename) || die $!;
    return $new_filename;
}

sub serial_test {
    my %args     = @_;
    my $filename = $args{filename};
    die "File $filename already exists" if -f $filename;
    open(my $fh, '>', $filename);
    print $fh 'Hello world';
    close $fh;
}

1;