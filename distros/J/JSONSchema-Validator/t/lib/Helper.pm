package Helper;

use strict;
use warnings;
use Cwd;
use File::Basename;

our @ISA = 'Exporter';
our @EXPORT_OK = qw(test_dir detect_warnings);

my @WARNINGS;

sub import {
    Helper->catch_warnings if grep { $_ eq 'detect_warnings' } @_;
    Helper->export_to_level(1, @_);
}

sub test_dir {
    my $base = Cwd::realpath(dirname(__FILE__) . '/..');
    return $base unless @_ > 0;
    return $base . '/' . $_[0];
}

sub catch_warnings {
    $SIG{__WARN__} = sub {
        my $msg = shift;
        print STDERR $msg;
        push @WARNINGS, $msg;
    };
}

sub detect_warnings {
    return @WARNINGS;
}

1;
