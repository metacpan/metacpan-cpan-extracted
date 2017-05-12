# IO::Callback 1.08 t/wrongway-ebadf.t
# Check that reads on write filehandles (and visa versa) give EBADF errors, same as real files. 

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use Errno qw/EBADF/';
    plan skip_all => 'Errno qw/EBADF/ required' if $@;
}
use Test::NoWarnings;

use IO::Callback;

# some bits of code for reading/writing the fh
my @code_bits = grep {/\S/} split /\n/, <<'EOF';
R $_ = <$fh>
R $_ = $fh->getline
R my @foo = <$fh>
R my @foo = $fh->getlines
R $_ = $fh->getc 
R $_ = $fh->ungetc(123) 
R my $x ; $_ = read $fh, $x, 1024
R my $x; $_ = sysread $fh, $x, 1024
W $_ = $fh->print(4)
W $_ = print $fh 4
W $_ = $fh->printf(4)
W $_ = printf $fh 4
W $_ = syswrite $fh, "asdfsadf", 3
EOF

plan tests => 4 * @code_bits + 1;

use vars qw/$fh/;

# The tests to run with a read-only fh as $fh (checking that read ops
# work and write ops fail with EBADF) as an array of coderefs.
my @try_on_read_fh;

# The tests to run with a write-only fh as $fh (checking that write ops
# work and read ops fail with EBADF) as an array of coderefs.
my @try_on_write_fh;

foreach my $code_bit (@code_bits) {
    $code_bit =~ s/^([RW])\s*// or die $code_bit;
    my $type = $1;

    my $code = $code_bit;
    $code .= '; ';
    if ($code =~ /\@foo/) {
        $code .= 'my $no_error = @foo;';
    } else {
        $code .= 'my $no_error = defined $_;';
    }
    my $ok_sub = eval <<EOF; die $@ if $@;
        sub {
            $code
            ok \$no_error, q{'$code_bit' gave no error};
        }
EOF
    my $notok_sub = eval <<EOF; die $@ if $@;
        sub {
            $code
            ok !\$no_error, q{'$code_bit' gave an error};
            ok \$!{EBADF}, 'errno set to EBADF';
            ok \$fh->error, "error flag set";
        }
EOF
    if ($type eq "R") {
        push @try_on_read_fh,  $ok_sub;    
        push @try_on_write_fh, $notok_sub;    
    } else {
        push @try_on_read_fh,  $notok_sub;    
        push @try_on_write_fh, $ok_sub;    
    }
}

foreach my $sub (@try_on_read_fh) {
    my @blocks = ("foo\nbar\n");
    $fh = IO::Callback->new('<', sub {shift @blocks});
    $sub->();
}

foreach my $sub (@try_on_write_fh) {
    $fh = IO::Callback->new('>', sub {});
    $sub->();
}

