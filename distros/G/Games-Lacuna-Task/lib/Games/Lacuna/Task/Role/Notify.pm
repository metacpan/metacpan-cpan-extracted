package Games::Lacuna::Task::Role::Notify;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Email::Stuff;

has 'email' => (
    is              => 'rw',
    isa             => 'Str',
    documentation   => q[Notification e-mail address],
    required        => 1,
);

has 'email_send' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    default         => sub { [] },
    documentation   => q[e-mail send methods],
);

sub notify {
    my ($self,$subject,$message) = @_;
    
    my $email = Email::Stuff
        ->from($self->email)
        ->to($self->email)
        ->subject($subject);
        
    if ($message =~ m/<html>/i) {
        $email->html_body($message);
    } else {
        $email->text_body($message);
    }
    
    $email->send( @{ $self->email_send } );
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::Notify - Send email notifications

=head1 SYNOPSIS

 package Games::Lacuna::Task::Action::MyTask;
 use Moose;
 extends qw(Games::Lacuna::Task::Action);
 with qw(Games::Lacuna::Task::Role::Notify);
 
 sub run {
     my ($self) = @_;
     $self->notify('Alarm!!','Something has happened');
 }

=head1 ACCESSORS

=head2 email

Recipient email

=head2 email_send

MIME::Lite send configuration

=head1 METHODS

=head2 notify

Sends an email notification

 $self->log($subject,$message);

=cut