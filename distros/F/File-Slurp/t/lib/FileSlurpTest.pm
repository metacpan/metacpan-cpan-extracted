package FileSlurpTest;

use strict;
use warnings;
use Exporter qw(import);
use IO::Handle ();
use File::Spec ();
use File::Temp qw(tempfile);

use File::Slurp ();

our @EXPORT_OK = qw(
    IS_WSL temp_file_path trap_function trap_function_list_context
);

sub IS_WSL() {
  if ($^O eq 'linux') {
    require POSIX;
    return 1 if (POSIX::uname())[2] =~ /windows/i;
  }
}

sub temp_file_path {
    my ($pick_nonsense_path) = @_;

    # older EUMMs turn this on. We don't want to emit warnings.
    # also, some of our CORE function overrides emit warnings. Silence those.
    local $^W;

    my $file;
    if ($pick_nonsense_path) {
        $file = File::Spec->catfile(File::Spec->tmpdir, 'super', 'bad', 'file-slurp', 'path');
    }
    else {
        (undef, $file) = tempfile('tempXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);
    }
    return $file;
}

sub trap_function {
    my ($function, @args) = @_;
    my $res;
    my $warn;
    my $err = do { # catch
        local $@;
        local $SIG{__WARN__} = sub {$warn = join '', @_};
        eval { # try
            $res = $function->(@args);
            1;
        };
        $@;
    };
    return ($res, $warn, $err);
}

sub trap_function_list_context {
    my ($function, @args) = @_;
    my @res;
    my $warn;
    my $err = do { # catch
        local $@;
        local $SIG{__WARN__} = sub {$warn = join '', @_};
        eval { # try
            @res = $function->(@args);
            1;
        };
        $@;
    };
    return (\@res, $warn, $err);
}

1;
