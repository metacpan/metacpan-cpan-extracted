package Dist::Maker::Util;
use strict;
use parent qw(Exporter);
use Carp ();

our @EXPORT = qw(
    slurp
    parse_options
    p

    run_command
    mkpath
    rmtree
    usage

    save

    available_templates
);

sub slurp {
    my($file, $layer) = @_;
    open my $in, '<' . ($layer // ''), $file
        or Carp::croak("Cannot open '$file' to slurp: $!");
    local $/;
    return scalar <$in>;
}

sub parse_options {
    my($class, @args) = @_;

    my @spec         = $class->option_spec;
    my $pass_through = $class->pass_through;

    require Getopt::Long;
    my $old = Getopt::Long::Configure(
        "posix_default",
        "permute",        # the argument order doesn't matter
        "no_ignore_case",
        "bundling",
        ($pass_through ? "pass_through" : ()),
    );

    my %opts;
    my $success = Getopt::Long::GetOptionsFromArray(\@args, \%opts, @spec);

    Getopt::Long::Configure($old);

    if(!$pass_through and !$success) {
        usage();
        return;
    }
    return(\%opts, @args);
}

sub p {
    require Text::Xslate::Util;
    goto &Text::Xslate::Util::p;
}

sub run_command {
    my($logger, @command) = @_;

    require IPC::Open3;

    if(@command > 1 && $command[0] !~ /\s/) {
        my($name, @args) = @command;
        require File::Basename;
        $logger->note(join(' ',
            File::Basename::basename($name), @args), "\n");
    }
    else {
        $logger->note("@command\n");
    }
    local(*CIN, *COUT, *CERR);
    my $pid = IPC::Open3::open3(\*CIN, \*COUT, \*CERR, @command);

    close *CIN;
    local $/;

    my $stdout = <COUT>;
    my $stderr = <CERR>;

    waitpid $pid, 0;

    $logger->info($stdout) if $stdout;
    if($? == 0) {
        $logger->info($stderr);
    }
    else {
        $logger->diag($stderr);
    }
    return($stdout, $stderr);
}

sub mkpath {
    my($logger, @args) = @_;
    $logger->info("mkpath @args\n");
    require File::Path;
    File::Path::mkpath(\@args, $logger->verbose >= 5)
        or Carp::croak("Cannot mkpath(@args): $!");
}

sub rmtree {
    my($logger, @args) = @_;
   $logger->info("mktree @args\n");
    require File::Path;
    File::Path::rmtree(\@args, $logger->verbose >= 5);
}

sub save {
    my($logger, $file, $content) = @_;

    my $tmp = "$file.tmp";
    open my $fh, '>', $tmp
        or return $logger->diag("Cannot open '$tmp' for writing: $!\n");

    print $fh $content;

    close $fh or return $logger->diag("Cannot close '$tmp' in writing: $!\n");

    my $original_exists = -e $file;
    if($original_exists) {
        rename $file => "$file~" or $logger->diag("Cannot rename '$file': $!\n");
    }

    if(not rename $tmp => $file) {
        $logger->diag("Cannot rename '$tmp': $!\n");
        rename "$file~" => $file if $original_exists;
        return $logger->diag("Cannot save file '$file'\n");
    }
    unlink "$file~" if $original_exists;
    return 1;
}

sub usage {
    require Pod::Usage;
    Pod::Usage::pod2usage(@_);
    return 1;
}

sub available_templates {
    require File::Find;

    my %modules;
    foreach my $dir(@INC) {
        my $base = "$dir/Dist/Maker/Template";

        next if not -d $base;

        my $wanted = sub {
            return if !(-f $_ && -r _);
            if(/ Dist.Maker.Template.( .+ )\.pm  \z/xms) {
                my $name = $1;
                $name =~ s/\W/::/g;
                $modules{$name}++;
            }
        };

        File::Find::find(
            { wanted => $wanted, no_chdir => 1 }, $base
        );
    }
    return sort keys %modules; ## no critic
}

1;
__END__

=head1 NAME

Dist::Maker::Util - Common utilities

=cut
