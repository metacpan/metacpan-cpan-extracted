package Test::Make::Util;

use Test::Util -Base;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    process_args
    touch utouch
    clean_env
);

sub process_args ($) {
    my $text = shift;
    my @args = split_arg($text);
    foreach (@args) {
        #warn "----------\n";
        #warn Dumper(@args, $_);
        #warn "----------\n";
        if (/^"(.*)"$/) {
            #warn "---------";
            #warn qq{Pusing "$1" into args\n};
            $_ = $1;
            process_escape( $_, q{"\\$@\#} );
        } elsif (/^'(.*)'$/) {
            #warn "  Pusing '$1' into args\n";
            $_ = $1;
        }
    }
    return @args;
}

sub touch (@) {
    utouch(0, @_);
}

# Touch with a time offset.  To DTRT, call touch() then use stat() to get the
# access/mod time for each file and apply the offset.

sub utouch ($@) {
    my $off = shift;
    my @files = @_;
    foreach my $file (@files) {
        my $in;
        open $in, ">>$file" or
            print $in '' or close $in or
            die "Can't touch $file: $!";
    }
    my (@s) = stat($files[0]);
    utime($s[8] + $off, $s[9] + $off, @files);
}

# the current implementation of clean_env is buggy. haven't found a better approach
sub clean_env () {
  # Get a clean environment

  my %makeENV = ();
  # Pull in benign variables from the user's environment
  #
  foreach (# UNIX-specific things
           'TZ', 'LANG', 'TMPDIR', 'HOME', 'USER', 'LOGNAME', 'PATH',
           # Purify things
           'PURIFYOPTIONS',
           # Windows NT-specific stuff
           'Path', 'SystemRoot', 'TMP', 'SystemDrive', 'TEMP', 'OS', 'HOMEPATH',
           # DJGPP-specific stuff
           'DJDIR', 'DJGPP', 'SHELL', 'COMSPEC', 'HOSTNAME', 'LFN',
           'FNCASE', '387', 'EMU387', 'GROUP',
           'GNU_MAKE_PATH', 'GNU_SHELL_PATH', 'INC', 'path',
          ) {
    $makeENV{$_} = $ENV{$_} if defined $ENV{$_};
  }
  %ENV = ();
  %ENV = %makeENV;
}

1;
