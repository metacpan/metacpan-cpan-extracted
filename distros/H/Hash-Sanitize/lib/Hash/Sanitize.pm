package Hash::Sanitize;

use 5.010;
use strict;
use warnings FATAL => 'all';

use base 'Exporter';
use Clone;

our @EXPORT_OK = (qw/sanitize_hash sanitize_hash_deep/);

=head1 NAME

Hash::Sanitize - Remove undesired keys from a hash (recursive)

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

This module implements two methods that allows you to clean up a hash of
undesired keys.

When called the method will iterate trough the hash keys and delete any keys
that are non in the desired set.

This module is like Hash::Util's "legal_keys" method with the difference that
while legal_keys doens't let you create keys that are not allowed, this module
alows you to modify an existing hash and get a sanitized copy of it.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Hash::Sanitize qw(sanitize_hash sanitize_hash_deep);

    sanitize_hash(\%hash,\@allowed_keys);
    
    sanitize_hash_deep(\%hash,\@allowed_keys);

=head1 EXPORT

This module exports two methods:
    
    sanitize_hash
    
    and
    
    sanitize_hash_deep

=head1 SUBROUTINES/METHODS

=head2 sanitize_hash

Given a hash, it iterates trough the list of keys in the hash and deletes
the keys that are not in the allowed keys list

When called in a void context, it modifies the hash sent as a parameter.
When called in a array context (hash to be more exact) it will clone the
original hash and sanitize & return the copy, leaving the original hash intact.

Example :

    my %new_hash = sanitize_hash(\%hash,[qw/foo bar/]);
    
Called this way the method leaves %hash intact and returns a hash containing
only "foo" and "bar" keys (if they exist)

Example 2:

    sanitize_hash(\%hash,[qw/foo bar/]);
    
Called this way the method remove all the heys from %hash that are not "foo"
or "bar". Called this way the method *will* modifiy the setucture of the
original hash that was passed as an argument

In scalar context will return a hash referece, to a copy of the original hash.

=cut
sub sanitize_hash {
    my ($hash,$allowed_keys) = @_;
    
    die "First argument of sanitize_hash must be a HASH REF!"
                    unless ref($hash) && ref($hash) eq "HASH";
    die "Second argument of sanitize_hash must be a ARRAY REF!"
                    unless ref($allowed_keys) && ref($allowed_keys) eq "ARRAY";
       
    # not in void context
    if (defined wantarray) {
        #make a copy 
        my $copy = Clone::clone($hash);
        
        #sanitize the copy
        sanitize_hash($copy,$allowed_keys);
        
        #return
        if (wantarray) {
            return %{$copy};
        }
        else {
            return $copy;
        }
    }
    else { #void context
        #delete the keys that are not allowed to be there
	foreach my $k (keys %{$hash}) {
            delete $hash->{$k} unless ( grep { $k eq $_ } @{$allowed_keys} );
        }    
    }
}

=head2 sanitize_hash_deep

Same as sanitize_hash but this method will also sanitize the HASH structures
that are found as values for allowed keys

Example :

    my %hash = (
                a => 1,
                b => 2,
                c => { d => 3, e => 4, f => 5},
                g => 6,
    );
    
    my %hash_copy = sanitize_hash_deep(\%hash,[qw/a c d/]);
    
The content of %hash_copy will be :

    ( a => 1, c => { d => 3 } )
    
It can also be called in a void context. In this case it will apply all changes
to the original hash that was passed as an argument

In scalar context will return a hash referece, to a copy of the original hash.

=cut

sub sanitize_hash_deep {
    my ($hash,$allowed_keys) = @_;
    
    die "First argument of sanitize_hash_deep must be a HASH REF!"
                    unless ref($hash) && ref($hash) eq "HASH";
    die "Second argument of sanitize_hash_deep must be a ARRAY REF!"
                    unless ref($allowed_keys) && ref($allowed_keys) eq "ARRAY";
       
    # not in void context
    if (defined wantarray) {
        #make a copy 
        my $copy = Clone::clone($hash);
        
        #sanitize the copy
        sanitize_hash_deep($copy,$allowed_keys);
        
        #return
        if (wantarray) {
            return %{$copy};
        }
        else {
            return $copy;
        }
    }
    else { #void context
        #delete the keys that are not allowed to be there
        foreach my $k (keys %{$hash}) {
            if (! (grep { $k eq $_ } @{$allowed_keys}) ) {
                delete $hash->{$k};
                next;
            }
            else {
                if (ref($hash->{$k}) && ref($hash->{$k}) eq "HASH") {
                    sanitize_hash_deep($hash->{$k},$allowed_keys);
                }
            }   
        }
    }
}

=head1 AUTHOR

Horea Gligan, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-sanitize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HASH-Sanitize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Sanitize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HASH-Sanitize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HASH-Sanitize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HASH-Sanitize>

=item * Search CPAN

L<http://search.cpan.org/dist/HASH-Sanitize/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Evozon Systems

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Hash::Sanitize
