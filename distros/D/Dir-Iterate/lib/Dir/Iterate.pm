package Dir::Iterate;

=head1 NAME

Dir::Iterate - map/grep-style directory traversal

=head1 SYNOPSIS

    use Dir::Iterate;
    
    my @config_dirs = grepdir { -d } '/etc';
    my @filenames = mapdir { (split '/')[-1] } $ENV{HOME}, '/usr';

=head1 DESCRIPTION

Dir::Iterate implements equivalents to the built-in C<map> and C<grep> functions
which traverse directories instead of arrays.  The block will be called for 
each file and directory below the given list of directories.  It acts as a 
more usable layer on top of File::Find.

=head2 Functions

=over 4

=cut

use strict;
use warnings;

use Exporter;
use base 'Exporter';

our $VERSION = 0.02;
our @EXPORT = qw(grepdir mapdir);

use File::Find ();
use File::Spec;

=item mapdir { ... } $path1[, $path2...]

The block is called for each file, folder, or other filesystem entity under the 
given path(s).  The full path to the object is in $_.  The return value or 
values of the block are collected together and returned in a list.

=cut

sub mapdir(&@) {
    my($closure, @paths) = @_;
    
    my @results;
    
    File::Find::find(
        {
            wanted => sub {
                local $_ = $File::Find::fullname;
                push @results, $closure->();
            },
            no_chdir => 1,
            follow   => 1
        },
        map { File::Spec->rel2abs($_) } @paths
    );
    
    return @results;
}

=item grepdir { ... } $path1[, $path2...]

The block is called for each file, folder, or other filesystem entity under the 
given path(s).  The full path to the object is in $_.  If the return value of 
the block is true, the full path will be in the list returned by the method.

=cut

sub grepdir(&@) {
    my $predicate = shift;
    unshift @_, sub { $predicate->() ? $_ : () };
    goto &mapdir;
}

=back 4

=head1 EXPORTS

C<mapdir> and C<grepdir> by default.

=head1 AUTHOR

Brent Royal-Gordon <brentdax@cpan.org>, for the University of Kent.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

1;