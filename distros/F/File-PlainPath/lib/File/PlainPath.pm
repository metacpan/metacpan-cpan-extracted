use strict;
use warnings;
package File::PlainPath;

# ABSTRACT: Construct portable filesystem paths in a simple way

our $VERSION = '0.030'; # VERSION

use File::Spec;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(path to_path);

sub import
{
    my $class  = shift;
    my %opts   = ();
    my @export = ();
    while (@_) {
        my $arg = shift;
        if ($arg =~ m{^ [-] (.+) $}x)
        {
            $opts{$1} = shift;
            next;
        }
        push @export, $arg;
    }
    
    if (exists $opts{'separator'}) {
        $^H{+__PACKAGE__} = $opts{'separator'};
    }
    
    @_ = ($class, @export);
    goto \&Exporter::import;
}


sub path {    
    my @caller       = caller(0);
    my $separator    = exists $caller[10]{+__PACKAGE__} ?
        $caller[10]{+__PACKAGE__} : '/';
    my $separator_re = qr{ \Q$separator\E }x;

    my @paths = @_;
    my @path_components = map { split($separator_re, $_) } @paths;

    return File::Spec->catfile(@path_components);
}


*to_path = *path;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::PlainPath - Construct portable filesystem paths in a simple way

=head1 VERSION

version 0.030

=head1 SYNOPSIS

    use File::PlainPath qw(path);
    
    # Forward slash is the default directory separator
    my $path = path 'dir/subdir/file.txt';
    
    # Set backslash as directory separator
    use File::PlainPath -separator => '\\';   
    my $other_path = path 'dir\\other_dir\\other_file.txt';

=head1 DESCRIPTION

File::PlainPath translates filesystem paths that use a common directory
separator to OS-specific paths. It allows you to replace constructs like this:

    my $path = File::Spec->catfile('dir', 'subdir', 'file.txt');

with a simpler notation:

    my $path = path 'dir/subdir/file.txt';

The default directory separator used in paths is the forward slash (C</>), but
any other character can be designated as the separator:

    use File::PlainPath -separator => ':';
    my $path = path 'dir:subdir:file.txt';

This is lexically scoped.

=head1 FUNCTIONS

=head2 path

Translates the provided path to OS-specific format. If more than one path is
specified, the paths are concatenated to produce the resulting path. 

Examples:

    my $path = path 'dir/file.txt';

    my $path = path 'dir', 'subdir/file.txt';
    # On Unix, this produces: "dir/subdir/file.txt" 

=head2 to_path

An alias for L</path>. Use it when there's another module that exports a
subroutine named C<path> (such as L<File::Spec::Functions>).

Example:

    use File::PlainPath qw(to_path);
    
    my $path = to_path 'dir/file.txt';

=head1 SEE ALSO

=over 4

=item * L<File::Spec>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/File-PlainPath/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/File-PlainPath>

  git clone https://github.com/odyniec/File-PlainPath.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Michal Wojciechowski <odyniec@odyniec.net>

=item *

Michał Wojciechowski <odyniec@odyniec.eu.org>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
