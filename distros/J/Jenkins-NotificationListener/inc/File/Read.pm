#line 1
package File::Read;
use strict;
use Carp;
use File::Slurp ();
require Exporter;

{   no strict;
    $VERSION = '0.0801';
    @ISA = qw(Exporter);
    @EXPORT = qw(read_file read_files);
}

*read_files = \&read_file;

#line 144

my %defaults = (
    aggregate       => 1, 
    cmd             => "sudo cat",
    err_mode        => 'croak', 
    skip_comments   => 0, 
    skip_blanks     => 0, 
    to_ascii        => 0, 
);

sub import {
    my ($module, @args) = @_;
    my @new = ();

    # parse arguments
    for my $arg (@args) {
        if (index($arg, '=') >= 0) {
            my ($opt, $val) = split '=', $arg;
            $defaults{$opt} = $val if exists $defaults{$opt};
        }
        else {
            push @new, $arg
        }
    }

    $module->export_to_level(1, $module, @new);
}

sub read_file {
    my %opts = ref $_[0] eq 'HASH' ? %{+shift} : ();
    my @paths = @_;
    my @files = ();

    # check options
    for my $opt (keys %defaults) {
        $opts{$opt} = $defaults{$opt} unless defined $opts{$opt}
    }

    # define error handler
    $opts{err_mode} =~ /^(?:carp|croak|quiet)$/
        or croak "error: Bad value '$opts{err_mode}' for option 'err_mode'";

    my %err_with = (
        'carp'  => \&carp, 
        'croak' => \&croak, 
        'quiet' => sub{}, 
    );
    my $err_sub = $err_with{$opts{err_mode}};

    $err_sub->("error: This function needs at least one path") unless @paths;

    for my $path (@paths) {
        my @lines = ();
        my $error = '';
        
        # first, read the file
        if ($opts{as_root}) {   # ... as root
            my $redir = $opts{err_mode} eq 'quiet' ? '2>&1' : '';
            @lines = `$opts{cmd} $path $redir`;

            if ($?) {
                if (not -f $path) {
                    $! = eval { require Errno; Errno->import(":POSIX"); ENOENT() } ||  2
                }
                elsif (not -r $path) {
                    $! = eval { require Errno; Errno->import(":POSIX"); EACCES() } || 13
                }
                else {
                    $! = 1024
                }
                ($error = "$!") =~ s/ 1024//;
            }
        }
        else {                  # ... as a normal user
            @lines = eval { File::Slurp::read_file($path) };
            $error = $@;
        }

        # if there's an error
        $error and $err_sub->("error: $error");

        # if there's any content at all...
        if (@lines) {
            # ... then do some filtering work if asked so
            @lines = grep { ! /^$/    } @lines  if $opts{skip_blanks};
            @lines = grep { ! /^\s*#/ } @lines  if $opts{skip_comments};
            @lines = map { _to_ascii($_) } @lines  if $opts{to_ascii};
        }

        push @files, $opts{aggregate} ? join('', @lines) : @lines;
    }

    # how to return the content(s)?
    return wantarray ? @files : join '', @files
}


# Text::Unidecode doesn't work on Perl 5.6
my $has_unidecode = eval "require 5.008; require Text::Unidecode; 1"; $@ = "";

sub _to_ascii {
    # use Text::Unidecode if available
    if ($has_unidecode) {
        return Text::Unidecode::unidecode(@_)
    }
    else { # use a simple s///
        my @text = @_;
        map { s/[^\x00-\x7f]//g } @text;
        return @text
    }
}

#line 331

1; # End of File::Read
