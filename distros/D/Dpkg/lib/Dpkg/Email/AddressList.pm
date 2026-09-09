# Copyright © 2025 Guillem Jover <guillem@debian.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Dpkg::Email::AddressList - manage email address lists

=head1 DESCRIPTION

It provides a class which is able to manage email address lists,
as used in L<deb822(5)> data.

=cut

package Dpkg::Email::AddressList 0.01;

use v5.36;

use Exporter qw(import);
use List::Util qw(any);

use Dpkg::Gettext;
use Dpkg::ErrorHandling;
use Dpkg::Email::Address;

my $addr_regex = Dpkg::Email::Address::REGEX();

my $addrlist_elem_regex = qr{
    \s* $addr_regex (?: \s* , )*
}x;

my $addrlist_regex = qr{
    ^
    # Optional addresses separated by comma.
    (?: \s* $addr_regex (?: \s* , )+ )*

    # Required address followed by an optional trailing comma.
    (?: \s* $addr_regex ) (?: \s* , )*
    \s*
    $
}x;

=head1 FUNCTIONS

=over 4

=item $regex = PARSE_REGEX()

Returns the regex used to parse email address lists.

Matches on a single entire email address.

=cut

sub MATCH_REGEX()
{
    return $addrlist_elem_regex;
}

=item $regex = CHECK_REGEX()

Returns the regex used to validate email address lists.

=cut

sub CHECK_REGEX()
{
    return $addrlist_regex;
}

=back

=head1 METHODS

=over 4

=item $addrlist = Dpkg::Email::AddressList->new($string)

Create a new object that can hold an email address list.

=cut

sub new($this, $str = undef)
{
    my $class = ref($this) || $this;
    my $self = {
        addrlist => [],
    };
    bless $self, $class;

    $self->parse($str) if defined $str;

    return $self;
}

=item @addrlist = $addrlist->addrlist()

Returns a list of L<Dpkg::Email::Address> objects that art part of this
email address list object.

=cut

sub addrlist($self)
{
    return @{$self->{addrlist}};
}

=item $bool = $addrlist->parse($string)

Parses $string into the current object replacing the current address list.

Will die on parse errors.

=cut

sub parse($self, $str)
{
    my @addrlist;

    if ($str !~ m{$addrlist_regex}) {
        error(g_("invalid email address list '%s'"), $str);
    }

    while ($str =~ m{$addrlist_elem_regex}g) {
        my $addr = Dpkg::Email::Address->new();
        $addr->name($1);
        $addr->email($2);

        push @addrlist, $addr;
    }

    if (@addrlist == 0) {
        error(g_("invalid email address list '%s'"), $str);
    }

    $self->{addrlist} = \@addrlist;

    return;
}

=item $bool = $addrlist->contains($addr)

Checks whether the $addr Dpkg::Email::Address is present in the email
address list.

=cut

sub contains($self, $addr)
{
    my $addr_str = $addr->as_string();

    return any {
        $addr_str eq $_->as_string()
    } @{$self->{addrlist}};
}

=item $string = $addrlist->as_string()

Returns the email address list formatted as a string of email addresses
separated by commas.

=cut

sub as_string($self)
{
    my $str = join q{, }, map {
        $_->as_string()
    } @{$self->{addrlist}};

    return $str;
}

=back

=head1 CHANGES

=head2 Version 0.xx

This is a private module.

=cut

1;
