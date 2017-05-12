# IO::Callback 1.08 t/sysread-params.t
# Check that IO::Callback's sysread() accurately emulates Perl's sysread(),
# particularly in terms of parameter validation.

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use IO::Callback;
use File::Slurp;
use File::Temp qw/tempdir/;
use Fatal qw/open close/;

our $test_nowarnings_hook = $SIG{__WARN__};
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $warning =~ /^Use of uninitialized value (?:\$(?:len|offset) )?in sysread/i;
    $test_nowarnings_hook->($warning);
};

our $tmpfile = tempdir(CLEANUP => 1) . "/testfile";

my @input_len_values = (0, 1, 2, 3);   # size of input file
my @buf_len_values = (0, 1, 2, 3, 10); # initial size of target buffer
my @len_values = (-1, 0, 1, 2, 3, 10, undef); # length param to sysread
my @offset_values = (-1, -2, -3, -10, 0, 1, 2, 3, 10, undef); # offset param to sysread

plan tests => 6 * @input_len_values * @buf_len_values * @len_values * @offset_values + 1;

foreach my $input_len (@input_len_values) {
    my $input = substr 'qwerty123456789', 0, $input_len;
    write_file $tmpfile, $input;
    foreach my $buflen (@buf_len_values) {
        foreach my $include_undef_params (0, 1) {
            foreach my $len (@len_values) {
                foreach my $offset (@offset_values) {
                    my $test_name = test_name($input_len, $buflen, $include_undef_params, $len, $offset);

                    my $save_input = $input;
                    open my $real_fh, "<", $tmpfile;
                    my $iocode_fh = IO::Callback->new('<', sub {shift @{$_[0]}}, [$input, '']);

                    my @results;
                    foreach my $fh ($iocode_fh, $real_fh) {
                        my $ret;
                        my $buf = substr 'QWERTYasdfghjkl', 0, $buflen;
                        if ($include_undef_params or defined $offset) {
                            eval { $ret = sysread $fh, $buf, $len, $offset };
                        } else {
                            eval { $ret = sysread $fh, $buf, $len };
                        }
                        if ($@) {
                            $@ =~ s/(line \d+)\./$1/;
                            push @results, "died: $@, buf {$buf}";
                        } else {
                            defined $ret or $ret = '**undef**';
                            push @results, "returned: $ret, buf {$buf}";
                        }
                    }
                    my ($got, $want) = @results;

                    is $got, $want, "$test_name results same as real file";
                    is $iocode_fh->error, $real_fh->error, "error flag same as real file";
                    is $input, $save_input, "$test_name left input buffer unchanged";

                }
            }
        }
    }
}

sub test_name {
    my ($inlen, $buflen, $include_undef, $len, $offset) = @_;
    defined $len    or $len    = 'undef';
    defined $offset or $offset = 'undef';

    return "il=$inlen bl=$buflen iu=$include_undef len=$len offset=$offset";
}
