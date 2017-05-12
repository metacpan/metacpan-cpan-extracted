package Grimlock::Web::Controller::Draft;
{
  $Grimlock::Web::Controller::Draft::VERSION = '0.11';
}
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;

BEGIN {extends 'Grimlock::Web::Controller::API'; }

=head1 NAME

Grimlock::Web::Controller::Draft - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub base : Chained('/api/base') PathPart('') CaptureArgs(0) {}

sub load_draft : Chained('base') PathPart('draft') CaptureArgs(1) {
  my ( $self, $c, $draftid ) = @_;
  my $draft = $c->model('Database::Entry')->find({
      display_title => $draftid,
  });
  $c->stash( draft => $draft );
}

sub create : Chained('base') PathPart('draft') Args(0) ActionClass('REST') {}

sub create_POST {
  my ( $self, $c ) = @_;
  my $params ||= $c->req->data || $c->req->params;
  my $user = $c->user->obj;
  $c->log->debug("PARAMS " . Dumper $params);
  my $draft = $user->update_or_create_related('drafts', $params);
  return $self->status_bad_request($c,
    message => "Couldn't create draft: $!"
  ) unless $draft;

  return $self->status_created($c,
    location => $c->uri_for_action('/draft/browse', [ $draft->title ]),
    entity => {
      draft => $draft,
      message => "Draft saved"
    }

  );
}



sub browse : Chained('load_draft') PathPart('') Args(0) ActionClass('REST') {
  my ( $self, $c ) = @_;
  my $draft = $c->stash->{'draft'};
  $c->stash( template => 'draft/browse.tt');
  return $self->status_bad_request($c,
    message => "No such draft"
  ) unless $draft;
}


sub browse_GET {
  my ( $self, $c ) = @_;
  my $draft = $c->stash->{'draft'};
  return $self->status_ok($c,
    entity => {
      draft => $draft
    }
  );
}

sub browse_DELETE {
  my ( $self, $c ) = @_;
  my $draft = $c->stash->{'draft'};
  $draft->delete || return $self->status_bad_request($c,
    message => "Can't delete draft: $!"
  );

  return $self->status_ok($c,
    entity => {
      message => "Draft deleted"
    }
  );
}


sub browse_PUT {
  my ( $self, $c ) = @_;
  my $params ||=  $c->req->data || $c->req->params;
  my $draft = $c->stash->{'draft'};
  my $user = $c->user;
  my $published = $params->{'published'} ? 1 : 0;
  my $message = $published ? 'Published' : 'Saved';
  my $entry = $draft->update({
    title     => $params->{'title'},
    body      => $params->{'body'},
    published => $published
  });
  return $self->status_bad_request($c,
    message => "Couldn't publish draft: $!"
  ) unless $draft;

  return $self->status_ok($c,
    entity => {
      entry => $entry,
      draft => $draft,
      message =>  join (" ", $message, $entry->display_title)
    }
  );
    
}
1;
