package Hash::ConsistentHash;

use v5.10;
use strict;
use warnings;

=head1 NAME

Hash::ConsistentHash - Constant hash algorithm

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

    use Hash::ConsistentHash;
    use String::CRC32;

    my $chash = Hash::ConsistentHash->new(
        buckets   => [qw(10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4)],
        hash_func => \&crc32
    );
    # get just one bucket
    my $server = $chash->get_bucket('foo');

    # or get a serie of non-repeating buckets through iterator
    my $next  = $chash->lookup('bar');
    $server   = $next->(); # get bucket
    # do stuff with $server
    $server   = $next->(); # get another bucket
    ...

=head1 DESCRIPTION

Hash::ConsistentHash algorithm distributes keys over fixed number of buckets.
Constant hash distribution means that if we add a bucket to a hash with N
buckets filled with M keys we have to reassign only M/(N+1) keys to new
buckets.

What puts apart this module from all similar modules available is that you
could ask for non-repeatable series of buckets. Using this property you
could implement not only consistent distribution but also redundancy - one
key to be directed to more than one bucket.

=head1 METHODS

=head2 new

Creates ConsistentHash object. It accept following params:

=over

=item hash_func

Hash function to be used on keys and buckets

=item buckets

Arrayref or Hashref. If buckets are given as arrayref they will have
same weight. If given as hashref, every bucket could have differend
weight.

Examples:

    # All buckets have same weight so they will hold equal amount of keys
    my $chash = Hash::ConsistentHash->new(
        buckets => [qw(A B C)],
        hash_func=>\&crc32 );

    # Bucket "B" will hold twice the amount of keys of bucket A or C
    my $chash = Cash::ConsistentHash->new(
        buckets => {A=>1, B=>2, C=>1},
        hash_func=>\&crc32 );


=back

=cut

sub new {
    my $self   = shift;
    my $class  = ref($self)||$self;
    $self   = bless {bukets=>0}, $class;

    my %params = @_;
    die "You showld specify hash_func coderef"
        unless ref($params{hash_func}) eq 'CODE';

    $self->{hash_func} = $params{hash_func};
    $self->{mask} = $params{mask} // 0xFF;

    my (@dest,$weight);
    if (ref $params{buckets} eq 'ARRAY'){
        @dest  = @{$params{buckets}};
        $weight= { map {$_ => 1 } @dest };
    }elsif(ref $params{buckets} eq 'HASH'){
        @dest  = keys %{$params{buckets}};
        $weight= $params{buckets};
    }
    return unless @dest;
    $self->{buckets} = scalar(@dest);
    my $total_weight = 0;
    for my $bucket (@dest){
        $total_weight += $weight->{$bucket};
    }
    my $buckets_per_waight = int($self->{mask}/$total_weight);
    while( $buckets_per_waight < 5 ){
        $self->{mask} |= $self->{mask} << 1;
        $buckets_per_waight = int($self->{mask}/$total_weight);
    }
    for my $bucket (@dest){
        srand($self->{hash_func}->($bucket));
        my $bucks = $buckets_per_waight * $weight->{$bucket};
        while ($bucks > 0) {
            my $n = int(rand($self->{mask}));
            next if defined $self->{ring}->[$n];
            $self->{ring}->[$n] = $bucket;
            $bucks--;
        }
    }
    for my $n (0..$self->{mask}){
        $self->{ring}->[$n] //= shift @dest;
    }
    return $self;
}


=head2 lookup

Lookup a key in the hash. Accept one param - the key. Returns an iterator
over the hash buckets.

Example:

    my $chash = Hash::ConsistentHash->new(
        buckets => [qw(A B C)],
        hash_func=>\&crc32 );

    my $next   = $chash->lookup('foo');
    my $bucket = $next->(); # B
    $bucket    = $next->(); # A
    $bucket    = $next->(); # C, hash is exhausted
    $bucket    = $next->(); # A
    ...

Returned buckets will not repeat until all buckets are exhausted.

=cut

sub lookup {
    my ($self,$key) = @_;
    my $idx = $self->{hash_func}->($key) & $self->{mask};
    my $ring= $self->{ring};
    my %seen;
    my $returned = 0;
    return sub {
        # start from the beggining if we have already returned all buckets
        if ($returned >= $self->{buckets}){
            $returned = 0;
            %seen = ();
        }
        while($seen{$ring->[$idx]}){
            $idx++;
            $idx = 0 if $idx > $self->{mask};
        }
        $seen{$ring->[$idx]}=1;
        $returned ++;
        return $ring->[$idx];
    }
}

=head2 get_bucket

Lookup a key in the hash. Accept one param - the key. Returns a bucket.

Example:

    my $chash = Hash::ConsistentHash->new(
        buckets => [qw(A B C)],
        hash_func=>\&crc32 );

    my $bucket  = $chash->get_bucket('foo');

=cut

sub get_bucket {
    my ($self,$key) = @_;
    my $idx = $self->{hash_func}->($key) & $self->{mask};
    return $self->{ring}->[$idx];
}

=head1 SEE ALSO

L<Set::ConsistentHash>, L<Algorithm::ConsistentHash::Ketama>

=head1 AUTHOR

Luben Karavelov, C<< <karavelov at spnet.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-consistenthash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-ConsistentHash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::ConsistentHash


You can also look for information at:

=over 4

=item * GIT repository with the latest stuff

L<https://github.com/luben/Hash-ConsistentHash>

L<git://github.com/luben/Hash-ConsistentHash.git>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-ConsistentHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-ConsistentHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-ConsistentHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-ConsistentHash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Luben Karavelov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hash::ConsistentHash
