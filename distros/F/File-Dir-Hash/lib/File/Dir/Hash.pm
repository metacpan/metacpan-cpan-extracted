package File::Dir::Hash;
use strict;
use warnings;

use File::Spec;
use File::Path qw(mkpath);
use Digest::MD5 qw(md5_hex);

use Class::XSAccessor {
    constructor => '_real_new',
    accessors => [qw(
        pattern
        hash_func
        basedir
    )]
};

our $VERSION = '0.02';

sub new {
    my ($cls,%opts) = @_;
    my $hash_func = delete $opts{hash_func};
    $hash_func ||= \&md5_hex;
    
    my $pattern = delete $opts{pattern};
    $pattern ||= [1,2,2,4];
    
    my $basedir = delete $opts{basedir};
    $basedir ||= "";
    
    my $self = __PACKAGE__->_real_new(
        pattern => $pattern, hash_func => $hash_func,
        basedir => $basedir);
    return $self;
}

sub genpath {
    my ($self,$key,$mkdir) = @_;
    my $hashstr = $self->hash_func->($key);
    my @chars = split(//, $hashstr);
    my @components;
    #Figure out our pattern..
    my @templ = @{$self->pattern};
    while (@templ && @chars) {
        my $n_elem = shift @templ;
        push @components, join("", splice(@chars, 0, $n_elem));
    }
    my $fname = $hashstr;
    
    my $tree = File::Spec->catdir($self->basedir, @components);
    if ($mkdir) {
        -d $tree or mkpath($tree);
    }
    return File::Spec->catdir($tree, $fname);    
}

1;

__END__

=head1 NAME

File::Dir::Hash - Relieve the stress on your filesystem by making arbitrarily large
trees to store otherwise non hierarchical data

=head1 DESCRIPTION

C<File::Dir::Hash> is a simple object and tries to be configurable to how you wish
to index your directory.

=head2 METHODS

=over

=item new(%opts)

Creates a new instance. It takes a hash of options. Valid keys are:

=over

=item hash_func

This is a coderef which will 'hash' your filenames/whatever. This doesn't have
to return a hash or even anything other than the string itself. It is called
with the input to L</genpath>. If ommited, will use md5_hex from L<Digest::MD5>

=item pattern

This determines how the index will split the key. This is an arrayref of integers.
The 'hash' is split as many times as there are elements in the array, with each split
being the size of the value of that element.

Thus if the C<hash_func> returns 'ABCEFGHIJKLMOPQRST' and the C<pattern> is C<[1,2,5]>
then the resultant path would be C<A/BC/EFGHI/JKLMNOPQRST>. The default pattern
is C<[1,2,2,4]>

=item basedir

This is the base directory. Nothing to see here, move along.

=back

=item genpath($key,$mkdir)

Tries to generate a path based on arbitrary input in C<$key> (passed to L</hash_func>)
and optionally creates the path (but not the last component, assumed to be a
filename), if C<$mkdir> is set to true.

=back

=head1 BUGS/CAVEATS/NOTES

Use this at your own risk. API and options might change.

=head1 AUTHOR AND COPYRIGHT

Copyright 2011 M. Nunberg
