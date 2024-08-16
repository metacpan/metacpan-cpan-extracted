package JIRA::REST::Lite;

use strict;
use warnings;
use JSON;
use REST::Client;
use MIME::Base64;

our $VERSION = '0.08';

sub new {
    my ($class, $args) = @_;
    my $self = {
        url       => $args->{url},
        client    => REST::Client->new(),
        session   => $args->{session} || 0,
        anonymous => $args->{anonymous} || 0,
    };

    if ($self->{anonymous}) {
        $self->{client}->setHost($self->{url});
    } elsif ($args->{pat}) {
        $self->{client}->addHeader('Authorization', 'Bearer ' . $args->{pat});
    } elsif ($self->{session}) {
        my $auth = encode_json({ username => $args->{username}, password => $args->{password} });
        $self->{client}->POST('/rest/auth/1/session', $auth, { 'Content-Type' => 'application/json' });
    } else {
        $self->{client}->addHeader('Authorization', 'Basic ' . encode_base64("$args->{username}:$args->{password}"));
    }

    bless $self, $class;
    return $self;
}

sub GET {
    my ($self, $path) = @_;
    $self->{client}->GET($path);
    return decode_json($self->{client}->responseContent());
}

sub set_search_iterator {
    my ($self, $params) = @_;
    $self->{search} = {
        jql        => $params->{jql},
        maxResults => $params->{maxResults} || 50,
        fields     => $params->{fields} || [],
    };
    $self->{search}->{startAt} = 0;
    $self->_search();
}

sub next_issue {
    my ($self) = @_;
    return shift @{$self->{search}->{issues}} if @{$self->{search}->{issues}};
    return unless $self->{search}->{total} > $self->{search}->{startAt} + $self->{search}->{maxResults};
    
    $self->{search}->{startAt} += $self->{search}->{maxResults};
    $self->_search();
    return shift @{$self->{search}->{issues}};
}

sub _search {
    my ($self) = @_;
    my $jql = encode_json({
        jql        => $self->{search}->{jql},
        startAt    => $self->{search}->{startAt},
        maxResults => $self->{search}->{maxResults},
        fields     => $self->{search}->{fields},
    });
    $self->{client}->POST('/rest/api/2/search', $jql, { 'Content-Type' => 'application/json' });
    my $result = decode_json($self->{client}->responseContent());
    $self->{search}->{issues} = $result->{issues};
    $self->{search}->{total} = $result->{total};
}

1;

__END__

=head1 NAME

JIRA::REST::Lite - A lightweight Perl module for interacting with JIRA REST API

=head1 SYNOPSIS

  use JIRA::REST::Lite;
  
  my $jira = JIRA::REST::Lite->new({
      url      => 'https://jira.example.net',
      username => 'myuser',
      password => 'mypass',
  });

  # Get issue
  my $issue = $jira->GET("/issue/TST-101");

  # Iterate on issues
  $jira->set_search_iterator({
      jql        => 'project = "TST" and status = "open"',
      maxResults => 16,
      fields     => [ qw/summary status assignee/ ],
  });

  while (my $issue = $jira->next_issue) {
      print "Found issue $issue->{key}\n";
  }

=head1 DESCRIPTION

JIRA::REST::Lite provides a simple interface for interacting with the JIRA REST API, with minimal dependencies.

=head1 METHODS

=head2 new

  my $jira = JIRA::REST::Lite->new(\%args);

Creates a new JIRA::REST::Lite object. The arguments can include C<url>, C<username>, C<password>, C<session>, C<pat>, and C<anonymous>.

=head2 GET

  my $issue = $jira->GET($path);

Performs a GET request to the JIRA API.

=head2 set_search_iterator

  $jira->set_search_iterator(\%params);

Sets up an iterator for searching JIRA issues.

=head2 next_issue

  while (my $issue = $jira->next_issue) {
      print "Found issue $issue->{key}\n";
  }

Fetches the next issue from the search iterator.

=head1 AUTHOR

[Kawamura Shingo] <pannakoota@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

