use strict;
use warnings;
use IO::Handle ();

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw(write_file read_file);
use Test::More ;

plan tests => 1;

sub simple_write_file {
    open my $fh, ">", $_[0] or die "Couldn't open $_[0] for write: $!";
    $fh->print($_[1]);
}

sub newline_size {
    my ($code) = @_;

    my $file = temp_file_path();

    local $\ = '';
    $code->($file, "\n" x 3);

    my $size = -s $file;

    unlink $file;

    return $size;
}

is(newline_size(\&write_file), newline_size(\&simple_write_file), 'newline');
