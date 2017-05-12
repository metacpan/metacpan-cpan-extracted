use 5.008001;
use strict;
use warnings;
package File::TreeBuilder;
BEGIN {
  $File::TreeBuilder::VERSION = '0.02';
}
# ABSTRACT: Build simple trees of files and directories.

# --------------------------------------------------------------------
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(build_tree);

# --------------------------------------------------------------------
sub build_tree {
    my ($dir, $str) = @_;
    my $caller_pkg = (caller)[0];
    $str = q[] unless defined $str;
    my @lines = split /\n/, $str;
        # Remove blank lines and comments.
    @lines = grep ! /^\s*(?:#|$)/, @lines;
    my $err_str = q[];
    _build_tree($dir, $caller_pkg, \$err_str, @lines);
    return $err_str;
}

# --------------------------------------------------------------------
sub _build_tree {
    my ($dir, $caller_pkg, $err_str_ref, @lines) = @_;
    if (! defined $dir) {
        $$err_str_ref .= "Directory not defined.\n";
        return;
    }
    if ($dir eq '') {
        $$err_str_ref .= "\$dir is empty string.\n";
        return;
    }
    if (! -d $dir) {
        mkdir($dir) or do {
            $$err_str_ref .= "Couldn't create '$dir'.\n";
            return;
        }
    }
    return unless @lines;
        # Remove from the beginning of each line as many leading
        # spaces as there are on the first one.
    my ($leading_spaces) = $lines[0] =~ /^( +)/;
    my ($nb_leading_spaces) = length($leading_spaces || '');
    @lines = map { s/ {$nb_leading_spaces}//; $_ } @lines;
    my $i = 0;
    while ($i < @lines) {
        if ($lines[$i] =~ /^\./) {
            _build_file($dir, $caller_pkg, $err_str_ref, $lines[$i]);
            return unless $$err_str_ref eq q[];
            ++$i;
        }
        elsif ($lines[$i] =~ /^\//) {
            my ($to_eval) = $lines[$i] =~ / ^ \/ \s+ (.*) /x;
            my $sub_dir;
            eval "no strict; package $caller_pkg; (\$sub_dir) = ($to_eval)";
            ++$i, next unless defined $sub_dir;
            my @sub_lines;
            push @sub_lines, $lines[$i]
              while ++$i < @lines && substr($lines[$i], 0, 1) eq ' ';
            _build_tree("$dir/$sub_dir", $caller_pkg, $err_str_ref, @sub_lines);
        }
        else {
            ++$i;
        }
    }
}

# --------------------------------------------------------------------
sub _build_file {
    my ($dir, $caller_pkg, $err_str_ref, $line) = @_;
    my ($to_eval) = $line =~ / ^ \. \s+ (.*) /x;
    my ($fname, $contents);
    eval "no strict; package $caller_pkg; (\$fname, \$contents) = ($to_eval)";
    my $file_spec = "$dir/$fname";
    open my $hdl, ">", $file_spec
      or $$err_str_ref .= "Couldn't open '$file_spec' for writing: $!";
    print $hdl $contents if defined($contents) && $contents ne '';
    $hdl->close();
}

# --------------------------------------------------------------------
1;

__END__
=pod

=head1 NAME

File::TreeBuilder - Build simple trees of files and directories.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use File::TreeBuilder qw(build_tree);

    our $contents_str = 'Bla';

    build_tree($some_dir, q{
        / "D2"
            . "F_in_D2", "contents"
        . "F_in_top"
        / "D1 with spaces"
            . "F_in_D1", $contents_str
            . "F with spaces in D1", $contents_str
    });

That creates the following directory structure:

    $some_dir/
        "D1 with spaces"/
            F_in_D1    # Contains 'Bla'.
            "F with spaces in D1" # Contains 'Bla'.
        D2/
            F_in_D2    # Contains 'contents'.
        F_in_top       # Empty file (0 bytes).

=head1 DESCRIPTION

This module is used for building small trees of files and directories
by describing what is needed in a text string.

=head1 FUNCTIONS

=head2 build_tree ($dir, $str)

Builds a tree of directories and files under $dir according to the
given C<$str>. Returns an empty string if successful, an error message
otherwise. See the SYNOPSIS for example usage.

In C<$str>, blank or empty lines or lines whose first non-blank
character is a pound sign (C<#>) are ignored.  Lines beginning with a
slash (C</>) indicate directories to be created, while dots
(C<.>) indicate files. Directories are created hierarchically,
according to the indentation. Files are created in the directory
hierarchically above them. Anything that follows the filename on the
line will be evaluated and placed in the file as its contents.

Important:

=over 4

=item Evaluated strings must not use lexicals, only package variables:
    use C<our> instead of C<my>.

=item If lines are indented bizarrely, you may get bizarre results.

=item Use spaces only or tabs only to indent. Mixing the two may confuse
    the parser.

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Luc St-Louis <lucs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Luc St-Louis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

