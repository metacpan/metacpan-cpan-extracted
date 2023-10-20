package Email::Address::Classify;
use strict;
use warnings FATAL => 'all';
use File::Basename;

=head1 NAME

Email::Address::Classify - Classify email addresses

=head1 SYNOPSIS

    use Email::Address::Classify;

    $email = Email::Address::Classify->new('a.johnson@example.com');

    print "Is valid:  " . $email->is_valid() ? "Y\n" : "N\n";    # Y
    print "Is random: " . $email->is_random() ? "Y\n" : "N\n";   # N

=head1 DESCRIPTION

This module provides a simple way to classify email addresses. At the moment, it only
provides two classifications is_valid() and is_random(). More classifications may be
added in the future.

=head1 METHODS

=over 4

=item new($address)

Creates a new Email::Address::Classify object. The only argument is the email address.

=item is_valid()

Performs a simple check to determine if the address is formatted properly.
Note that this method does not check if the domain exists or if the mailbox is valid.
Nor is it a complete RFC 2822 validator. For that, you should use a module such as
L<Email::Address>.

If this method returns false, all other methods will return false as well.

=item is_random()

Returns true if the localpart is likely to be randomly generated, false otherwise.
Note that randomness is subjective and depends on the user's locale and other factors.
This method uses a list of common trigrams to determine if the localpart is random. The trigrams
were generated from a corpus of 30,000 email messages, mostly in English. The accuracy of this
method is about 95% for English email addresses.

If you would like to generate your own list of trigrams, you can use the included
C<ngrams.pl> script in the C<tools> directory of the source repository.

=back

=head1 TODO

Ideas for future classification methods:

    is_freemail()
    is_disposable()
    is_role_based()
    is_bounce()
    is_verp()
    is_srs()
    is_batv()
    is_sms_gateway()

=head1 AUTHOR

Kent Oyer <kent@mxguardian.net>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 MXGuardian LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the LICENSE
file included with this distribution for more information.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses/.

=cut

my %ngrams;
our $min_length = 4;
our $VERSION = '0.02';

sub _init {

    # read ngrams from Classify/ngrams.txt
    my $filename = dirname($INC{'Email/Address/Classify.pm'}).'/Classify/ngrams.txt';
    open(my $fh, '<', $filename) or die "Can't open $filename: $!";
    while (my $line = <$fh>) {
        chomp $line;
        $ngrams{$line} = 1;
    }
    close($fh);

}

sub new {
    my ($class,$address) = @_;
    my $self = bless {
        address => $address,
    }, $class;
    my $email = _parse_email($address);
    if ( $email ) {
        $self->{localpart} = $email->{localpart};
        $self->{domain} = $email->{domain};
        $self->{valid} = 1;
    } else {
        $self->{valid} = 0;
    }

    return $self;
}

sub is_valid {
    my $self = shift;
    return $self->{valid};
}

sub _find_ngrams {
    my $str = lc($_[0]);
    my @ngrams;
    for (my $i = 0; $i < length($str) - 2; $i++) {
        push @ngrams, substr($str, $i, 3);
    }
    return @ngrams;
}

sub is_random {
    my $self = shift;

    return $self->{random} if exists $self->{random};

    return $self->{random} = 0 unless $self->{valid} && length($self->{localpart}) >= $min_length;

    _init() unless %ngrams;

    my ($common,$uncommon) = (0,0);
    foreach (_find_ngrams($self->{localpart})) {
        if (exists $ngrams{$_} ) {
            $common++;
        } else {
            $uncommon++;
        }
    }
    if ( $common == $uncommon ) {
        # tie breaker
        $uncommon++ if $self->{localpart} =~ /[bcdfgjklmnpqrtvwxz]{5}|[aeiouy]{5}|([a-z]{1,2})(?:\1){3}/;
    }
    return $self->{random} = ($uncommon > $common ? 1 : 0);
}

sub _parse_email {
    my $email = shift;
    return undef unless defined($email) &&
        $email =~ /^((?:[a-zA-Z0-9\+\_\=\.\-])+)@((?:[a-zA-Z0-9\-])+(?:\.[a-zA-Z0-9\-]+)+)$/;

    return {
        address => $email,
        localpart => $1,
        domain => $2,
    };

}

1;