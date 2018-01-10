package Makefile::Update::CMakefile;
# ABSTRACT: Update lists of files in CMake variables.

use Exporter qw(import);
our @EXPORT = qw(update_cmakefile);

use strict;
use warnings;

our $VERSION = '0.4'; # VERSION


# Variables in our input files use make-like $(var) syntax while CMake uses
# shell-like ${var}, so convert to the target format.
sub _var_to_cmake
{
    my ($var) = @_;
    $var =~ s/\((\w+)\)/{$1}/g;
    $var;
}


sub update_cmakefile
{
    my ($in, $out, $vars) = @_;

    # Variable whose contents is being currently replaced.
    my $var;

    # Hash with files defined for the specified variable as keys and 0 or 1
    # depending on whether we have seen them in the input file as values.
    my %files;

    # Set to 1 if we made any changes.
    my $changed = 0;
    while (<$in>) {
        # Preserve the original line to be able to output it with any comments
        # that we strip below.
        my $line_orig = $_;

        # Get rid of white space and comments.
        chomp;
        s/^\s+//;
        s/\s+$//;
        s/ *#.*$//;

        # Are we inside a variable definition?
        if (defined $var) {
            if (/^\)$/) {
                # End of variable definition, check if we have any new files.
                #
                # TODO Insert them in alphabetical order.
                while (my ($file, $seen) = each(%files)) {
                    if (!$seen) {
                        # This file wasn't present in the input, add it.
                        # TODO Use proper indentation.
                        print $out "    $file\n";

                        $changed = 1;
                    }
                }

                undef $var;
            } elsif ($_) {
                # We're inside a variable definition.
                if (not exists $files{$_}) {
                    # This file was removed.
                    $changed = 1;
                    next;
                }

                if ($files{$_}) {
                    warn qq{Duplicate file "$_" in the definition of the } .
                         qq{variable "$var" at line $.\n}
                } else {
                    $files{$_} = 1;
                }
            }
        } elsif (/^set *\( *(\w+)$/ && exists $vars->{$1}) {
            # Start of a new variable definition.
            $var = $1;

            %files = map { _var_to_cmake($_) => 0 } @{$vars->{$var}};
        }

        print $out $line_orig;
    }

    $changed
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Makefile::Update::CMakefile - Update lists of files in CMake variables.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This can be used to update the contents of a variable containing a list of
files in a CMake file.

    use Makefile::Update::CMakefile;
    Makefile::Update::upmake('CMakeLists.txt', \&update_cmakefile, $vars);

=head1 FUNCTIONS

=head2 update_cmakefile

Update variable definitions in a CMake file with the data from the hash
ref containing all the file lists.

The variables are supposed to be defined in the following format:

    set(var
        foo
        bar
        baz
    )

Notably, each file has to be on its own line, including the first one.

Takes the (open) file handles of the files to read and to write and the file
lists hash ref as arguments.

Returns 1 if any changes were made.

=head1 SEE ALSO

Makefile::Update

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
