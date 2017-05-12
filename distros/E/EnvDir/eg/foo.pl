use strict;
use warnings;
use FindBin;
use EnvDir 'envdir', -clean;


# Both environment variables don't exist.
print_env('FOO', 'BAR', 'PATH');

{
    write_env_file('FOO', 'foo');
    $ENV{PATH} = '/path/to/executables'; # this value will be overrided.
    my $guard = envdir("$FindBin::Bin/env");

    # FOO=foo, Bar doesn't exist.
    print_env('FOO', 'BAR', 'PATH');

    {
        write_env_file('BAR', 'bar');
        my $guard = envdir("$FindBin::Bin/env");

        # Foo=foo, BAR=bar
        print_env('FOO', 'BAR', 'PATH');
    }

    # FOO=foo, Bar doesn't exist.
    print_env('FOO', 'BAR', 'PATH');
}

# Both environment variables don't exist.
print_env('FOO', 'BAR', 'PATH');

# === Utility functions  ===
my @files;
END { unlink $_ for @files }

sub write_env_file {
    my ($file, $value) = @_;
    my $path = "$FindBin::Bin/env/$file";
    open my $fh, '>', $path or die $!;
    print $fh $value;
    close $fh;
    push @files, $path;

}

sub print_env {
    my @keys = @_;
    my ($package, $filename, $line) = caller;
    printf "--- line %s\n", $line;
    for (@keys) {
        if ( exists $ENV{$_} ) {
            printf "%s is %s\n", $_, $ENV{$_} || 'undef'; 
        }
        else {
            printf "%s doesn't exist\n", $_;
        }
    }
}
