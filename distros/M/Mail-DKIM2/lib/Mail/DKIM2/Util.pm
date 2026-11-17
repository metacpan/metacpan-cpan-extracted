package Mail::DKIM2::Util;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.35';

use Carp ();

use Exporter 'import';
our @EXPORT_OK = qw(
    check_options
    is_base64string
);

# check_options($what, \%opts, @known): croak on an option not in @known.
# Every public constructor and class method taking named options calls this
# first (Mail::DKIM2 CONVENTIONS: a misspelling is an error, not a silently
# ignored setting -- Algz => ['sha512'] used to compute SHA-256).
sub check_options {
    my ($what, $opts, @known) = @_;
    my %known = map { $_ => 1 } @known;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;    # blame our caller's caller
    for my $k (sort keys %$opts) {
        Carp::croak("unknown option $k for $what") unless $known{$k};
    }
    return;
}

# A base64string (-09 §2.13), FWS already removed: base64 characters,
# padded with "=" to a multiple of four ("MUST be padded").
sub is_base64string {
    my ($s) = @_;
    return defined $s && length $s && length($s) % 4 == 0
        && $s =~ m{\A[A-Za-z0-9+/]+={0,2}\z};
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Util - Small helpers shared by the Mail::DKIM2 modules

=head1 SYNOPSIS

    use Mail::DKIM2::Util ();

    Mail::DKIM2::Util::check_options('My::Class->new', \%options, qw(Domain Selector));

=head1 DESCRIPTION

Internal to the distribution: what every module needs and none of the
others owns. New in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 check_options($what, \%options, @known)

Croaks C<unknown option NAME for $what>, blaming the caller's caller, if
C<%options> has a key that is not in C<@known>. Every constructor and
class method that takes named options calls it first, so a misspelt option
is an error and not a silently ignored setting.

=head2 is_base64string($string)

True if C<$string> is a base64string (-09 section 2.14) with its FWS
already removed: base64 characters padded with C<=> to a multiple of four.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
