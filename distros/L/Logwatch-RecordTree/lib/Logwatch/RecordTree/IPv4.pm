#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Logwatch::RecordTree::IPv4
#     ABSTRACT:  a subclass of Logwatch::RecordTree for IPv4 addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Thu Mar 12 18:41:04 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

package Logwatch::RecordTree::IPv4;
use parent 'Logwatch::RecordTree';
use Moo;
use UNIVERSAL::require;
# use Net::IP::Identifier 0.111
use Carp qw( croak );
use Sort::Key::IPv4;
use Sort::Key::Natural qw( natsort natkeysort );
use Math::BigInt;

our $VERSION = '2.056'; # VERSION

has identify => (
    is => 'rw',
);
has snowshoe => (   # number indicating width of mask to consider.  1 => 24
    is => 'rw',
);

my $identifier;  # class variable

sub identifier {
    my ($self) = @_;

    if (not $self->{identifier}) {
        if (not $identifier) {
            Net::IP::Identifier->require(0.111)
                or croak($@);
            $identifier = Net::IP::Identifier->new;
        }
        $self->{identifier} = $identifier;
    }
    return $self->{identifier};
}

sub create_child { # override
    my ($self, $name, $type, $opts) = @_;

    my $child = $self->SUPER::create_child($name, $type, $opts);

    # this is why we're overriding parent's create_child method.  we want
    #    to do these when child is created so caller can make changes
    $child->sprint_name(sub {
        my ($child) = @_;

        my $ip = $child->name;
        if ($self->identify and
            ($ip =~ m/^\d+\.\d+\.\d+\.\d+(\/\d+)?$/ or
             $ip =~ m/^[\d:]+(\/\d+)?$/)) {
            my $id = $self->identifier->identify($ip);
            if ($id) {
                $id = substr($id, 0, 8) if (length $id > 8);
                $ip = "$id-$ip";
            }
        }
        return $ip;
    });

    return $child;
}

# the IP list may contain non-IP addresses, split into two lists:
sub split_ips {
    my ($self, $ips_orig) = @_;

    my (@non_ips, @ips);
    for my $ip (@{$ips_orig}) {
        if ($ip =~ m/^\d+\.\d+\.\d+\.\d+(\/\d+)?$/ or
            $ip =~ m/^[\d:]+(\/\d+)?$/) {
            push @ips, $ip;
        }
        else {
            push @non_ips, $ip;
        }
    }
    return (\@non_ips, \@ips);
}

# sort a list of hosts which may include non-IP addresses
sub ipv4sort {
    my ($self, @ips_orig) = @_;

    my ($non_ips, $ips) = $self->split_ips(\@ips_orig);
    my $case_sensitive = ref $self ? $self->case_sensitive : 0;
    @{$non_ips} = $case_sensitive
      ? natsort @{$non_ips}
      : natkeysort { lc $_ } @{$non_ips};

    my %ips;
    for my $ip (@{$ips}) {
        my ($key) = $ip =~ m/([^\/]+)/;   # key on just the IP part without range
        $ips{$key} = $ip;
    }
    my @sorted_keys = Sort::Key::IPv4::ipv4sort(keys %ips);
    my @ips = map { $ips{$_} } @sorted_keys;

    return (@{$non_ips}, @ips);
}

sub sort_children {
    my ($self) = @_;

    my %keys = map { (defined($_->sort_key) ? $_->sort_key : $_->name) => $_ }
                   values %{$self->children};
    my @children = map { $keys{$_} } $self->ipv4sort(keys %keys);

    return wantarray
        ?  @children
        : \@children;
}

sub sprint {
    my ($self, @args) = @_;

    if ($self->snowshoe) {
        # create new child list and replace the old list
        $self->children($self->condense_snowshoes);
    }
    return $self->SUPER::sprint(@args);
}

# convert decimal dotted quad to binary IP
sub ip_to_bin {
    my ($self, $ip) = @_;

    my $bin = Math::BigInt->new(0);
    for my $part (split '\.', $ip) {
        $bin <<= 8;
        $bin |= $part;
    }
    return $bin
}

# convert binary IP to decimal dotted quad
sub bin_to_ip {
    my ($self, $bin) = @_;

    my @parts;
    while (@parts < 4) {
        unshift @parts, $bin & 0xff;
        $bin >>= 8;
    }
    return join('.', @parts);
}

# return a mask of $width
sub mask {
    my ($self, $width) = @_;

    return Math::BigInt->new(1)->blsft($width)->bsub(1)->blsft(32-$width);
}

sub min_range {
    my ($self, $group) = @_;    # group is ordered list of Logwatch::RecordTrees with IPs as names

    my $width = 32;
    my $mask = $self->mask($width); # full width mask to start

    my $masked_ip = $self->ip_to_bin($group->[0]->name);
    for my $item (@{$group}) {
        my $ip = $self->ip_to_bin($item->name);
        while ($width) {
            last if (($ip & $mask) == $masked_ip);
            $mask &= $mask->blsft(1);
            $width--;
            $masked_ip &= $mask;
        }
    }
    return $self->bin_to_ip($masked_ip). "/$width";
}

# hackers often rent IP blocks (/24 is common) so the source IP isn't
# exactly duplicated.  Collect IPs within a block into single child.
sub condense_snowshoes {
    my ($self) = @_;

    my $mask_width = $self->snowshoe;
    # mask width of 1 is pretty useless, so we'll interpret it as /24:
    $mask_width = 24 if ($mask_width == 1);
    my $mask = $self->mask($mask_width);

    my ($non_ips, $ips) = $self->split_ips([keys %{$self->children}]);
    @{$ips} = Sort::Key::IPv4::ipv4sort(@{$ips});

    my ($masked_ip, $count, @group, %new_children);
    for my $ip (@{$ips}, '') {   # add dummy at end to flush
        my $child;
        $child = $self->child_by_name($ip) if ($ip);
        if ($masked_ip) {   # skip the first time through
            if ($ip and
                $masked_ip == ($self->ip_to_bin($ip) & $mask)) {  # in range?
                $count += $child->count;
                push @group, $child;
            }
            else { # out of range (or last time through the loop with dummy)
                if (@group < 3) {   # require at least three before condensing
                    map { $new_children{$_->name} = $_ } @group;    # copy to new list
                }
                else {
                    my $name = $self->min_range(\@group);
                    my $new_child
                      = $new_children{$name}
                      = $group[0]->new(  # clone first child
                        name         => $name,
                        sprint_name  => $group[0]->sprint_name,
                        count_fields => [ '/', scalar @group ],
                    );
                    # transfer any children from group items to new parent
                    for my $item (@group) {
                        my @g_children = values %{$item->children};
                        if (@g_children) {
                            for my $child (@g_children) {
                                $new_child->adopt($child);
                            }
                        }
                        else {  # no children, count is entirely from item
                            $new_child->count($new_child->count + $item->count);
                        }
                    }
                }
                undef $masked_ip;    # start a new range
            }
        }
        if ($ip and not $masked_ip) {
            $masked_ip = $self->ip_to_bin($ip) & $mask;
            @group = ( $self->child_by_name($ip) );
            $count = $child->count;
        }
    }

    # rejoin the non-IP children
    map { $new_children{$_} = $self->child_by_name($_) } @{$non_ips};

    $self->children(\%new_children);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Logwatch::RecordTree::IPv4 - a subclass of Logwatch::RecordTree for IPv4 addresses

=head1 VERSION

version 2.056

=head1 SYNOPSIS

 use Logwatch::RecordTree;
 use Logwatch::RecordTree::IPv4 (
    neat_names => -1,   # left-justified neat names
    columnize  => 1,    # put into columns, if it fits
    identify   => 1,    # try to identify each IP's owner
    snowshoe   => 1,    # condense nets within /24 netblocks to CIDRs
);

 my $tree = Logwatch::RecordTree->new( name => 'Service', ... );

 $tree->log(..., ['Name', 'Logwatch::RecordTree::IPv4', { options }], '10.1.1.1', ...);

 print $tree;

=head1 DESCRIPTION

B<Logwatch::RecordTree::IPv4> is a sub-class of B<Logwatch::RecordTree>
intended for collecting events that should be keyed by IPv4 addresses.

NOTE: this module should I<contain> the IP address items, meaning that the
children added to this module will have B<name>s (or B<sort_keys>) that are
IP addresses.

While this module is most useful when the B<name>s are actual IP addresses,
it is tolerant of B<name>s that are not IP addresses.  When sorting, non-IP
addresses are separated out and sorted alphabetically.  The IP addresses
are sorted using Sort::Key::IPv4::ipv4sort and the two lists are
concatenated.

=head2 Methods

=over

=item Logwatch::RecordTree::IPv4->new ( [ %options ] )

Same as the B<Logwatch::RecordTree> B<new> method, but adds two flag options
(B<identify> and B<snowshoe>), and sets the B<neat_names> flag.

=back

=head3 Options

=over 8

=item identify

Child names to this item are normally IPv4 addresses.  This flag enables
use of the B<Net::IP::Identifier> module to attempt to attach network
block identification to those IP addresses.  If identifiable, the first
eight characters of the identity are prepended to the IP address.  Sorting
is still based on the original IP address.

=item snowshoe

Hackers / SPAMmers often rent blocks of IP addresses spreading out their
'footprint' (like a snowshoe) so their source address isn't exactly
duplicated.  Turning on this flag condenses long lists of IPs within a mask
range into a single line.  The value of this flag is the width of the mask,
so 24 is 256 IPs (i.e 192.168.33.0 - 192.168.33.255), 16 is 65,536 IPs,
etc.  When false, snowshoe detection is disabled.  Setting to one (1) is
interpreted as 24 since a mask width of one is not very useful, and /24 is
commonly seen.

See B<sprint> below for more details.

=back

In the following methods, either B<$tree> or B<$item> is used as the
object reference.  B<$item> indicates that the particular item at
that point of the RecordTree is affected.  B<$tree> indicates that
the method is inherently recursive and may descend down through the
RecordTree.

=over

=item $item->sort_children

This method overrides the B<Logwatch::RecordTree> method to provide tolerant
IPv4 sorting.

=item $item->identifier

Creates (if necessary) a Net::IP::Identifier object and returns it.  This is
a class variable.  The same Net::IP::Identifier is used for all instances.

=item $item->create_child

This method in B<Logwatch::RecordTree> is overridden here to alter the
default B<sprint_name> method in children as they are added.

The new B<sprint_name> method checks for this item's B<identify> flag, and
if true, it tries to identify the IPs in the B<children>s' B<name>s.  For
each identified IP, the name is modified with the identity (up to 8 leading
characters of it).

=item $tree->sprint

This B<Logwatch::RecordTree> method is overridden here to support the
B<snowshoe> option.  When B<snowshoe> is enabled, the B<children> hash is
replaced before B<Logwatch::RecordTree-E<gt>sprint> is called.  In the
replacement, groups of IPs that fall within the range specified by the
B<snowshoe> mask width are condensed into a single line.  The B<count>s of
each individual IP are summed into the replacement line B<count>.

=back

=head1 SEE ALSO

=over

=item Logwatch::RecordTree

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
