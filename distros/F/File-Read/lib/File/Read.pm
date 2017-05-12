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

=head1 NAME

File::Read - Unique interface for reading one or more files

=head1 VERSION

Version 0.0801

=head1 SYNOPSIS

    use File::Read;

    # read a file
    $file = read_file($path);

    # read several files
    @files = read_files(@paths);

    # aggregate several files
    $file = read_files(@paths);

    # read a file as root, skip comments and blank lines
    $file = read_file({ as_root => 1, skip_comments => 1, skip_blanks => 1 }, $path);


=head1 DESCRIPTION

This module mainly proposes functions for reading one or more files, 
with different options. See below for more details and examples.

=head2 Rationale

This module was created to address a quite specific need: reading many 
files, some as a normal user and others as root, and eventually do a 
little more processing, all while being at the same time compatible 
with Perl 5.004. C<File::Slurp> addresses the first point, but not the 
others, hence the creation of C<File::Read>. If you don't need reading 
files as root or the post-processing features, then it's faster to 
directly use C<File::Slurp>.

=head1 EXPORT

By default, this module exports all the functions documented afterhand.
It also recognizes import options. For example

    use File::Read 'err_mode=quiet';

set C<read_file()>'s C<err_mode> option default value to C<"quiet">.

=head1 FUNCTIONS

=over

=item B<read_file()>

Read the files given in argument and return their content, 
as as list, one element per file, when called in list context, 
or as one big chunk of text when called in scalar context. 
Options can be set using a hashref as first parameter.

B<Options>

=over

=item *

C<aggregate> controls how the function returns the content of the files 
that were successfully read. By default, When set to true (default), 
the function returns the content as a scalar; when set to false, the 
content is returned as a list.

=item *

C<as_root> tells the function to read the given file(s) as root using 
the command indicated by the C<cmd> option.

=item *

C<cmd> sets the shell command used for reading files as root. Default 
is C<"sudo cat">. Therefore you need B<sudo(8)> and B<cat(1)> on your 
system, and F<sudoers(5)> must be set so the user can execute B<cat(1)>.

=item *

C<err_mode> controls how the function behaves when an error occurs. 
Available values are C<"croak">, C<"carp"> and C<"quiet">.
Default value is C<"croak">.

=item *

C<skip_comments> tells the functions to remove all comment lines from 
the read files. 

=item *

C<skip_blanks> tells the functions to remove all blank lines from 
the read files. 

=item *

C<to_ascii> tells the functions to convert the text to US-ASCII using
C<Text::Unidecode>. If this module is not available, non-ASCII data 
are deleted.

=back

B<Examples>

Just read a file:

    my $file = read_file($path);

Read a file, returning it as list:

    my @file = read_file({ aggregate => 0 }, $path);

Read a file, skipping comments:

    my $file = read_file({ skip_comments => 1 }, $path);

Read several files, skipping blank lines and comments:

    my @files = read_file({ skip_comments => 1, skip_blanks => 1 }, @paths);

=item B<read_files()>

C<read_files()> is just an alias for C<read_file()> so that it look more 
sane when reading several files. 

=cut

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

=back

=head1 DIAGNOSTICS

=over

=item C<Bad value '%s' for option '%s'>

B<(E)> You gave a bad value for the indicated option. Please check the 
documentation for the valid values. 

=item C<This function needs at least one path>

B<(E)> You called a function without giving it argument.

=back

=head1 SEE ALSO

L<File::Slurp>

L<IO::All>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-read at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Read>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Read

You can also look for information at:

=over 4

=item *

AnnoCPAN: Annotated CPAN documentation -
L<http://annocpan.org/dist/File-Read>

=item *

CPAN Ratings -
L<http://cpanratings.perl.org/d/File-Read>

=item *

RT: CPAN's request tracker -
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Read>

=item *

Search CPAN -
L<http://search.cpan.org/dist/File-Read>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006, 2007 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Read
