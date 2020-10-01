package Github::Email;
$Github::Email::VERSION = '1.1.0';
# ABSTRACT: Search and print particular Github user emails.

use strict;
use warnings;

use Carp qw(confess); 
use JSON;
use LWP::UserAgent;
use List::MoreUtils qw(uniq);
use Email::Valid;


sub get_emails {
    my $username = shift;

    my $user_agent = LWP::UserAgent->new;
    my $get_json =
      $user_agent->get("https://api.github.com/users/$username/events/public");

    if ( $get_json->is_success ) {
        my $raw_json    = $get_json->decoded_content;
        my $decoded_json    = decode_json $raw_json;
        my @push_events = grep { $_->{type} eq 'PushEvent' } @{$decoded_json};
        my @commits     = map { @{$_->{payload}->{commits}} } @push_events;
        my @addresses   = map { $_->{author}->{email} } @commits;
        my @unique_addresses = uniq @addresses;
        my @retrieved_addresses;

        for my $address (@unique_addresses) {
            if ( $address ne 'git@github.com' && Email::Valid->address($address) ) {
                push( @retrieved_addresses, $address );
            }
        }

        return @retrieved_addresses;
    }

    else {
        confess("User doesn't exist");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Github::Email - Search and print particular Github user emails.

=head1 VERSION

version 1.1.0

=head1 SYNOPSIS

    github-email <github_username>

    # Example
    github-email momozor

=head2 Functions

=over 4

=item get_emails($username)

    description: Retrieves Github user email addresses.

    parameter: $username - Github account username.

    returns: A list of email addresses.

=back

=head1 AUTHOR

Momozor <momozor4@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2020 by Momozor.

This is free software, licensed under:

  The MIT (X11) License

=cut
