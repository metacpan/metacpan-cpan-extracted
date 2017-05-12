package Email::Folder::Search;

# ABSTRACT: wait and search emails from mailbox

=head1 NAME

Email::Folder::Search - wait and search emails from mailbox

=head1 DESCRIPTION

Search email from mailbox file. This module is mainly to test that the emails are received or not.

=head1 SYNOPSIS

    use Email::Folder::Search;
    my $folder = Email::Folder::Search->new('/var/spool/mbox');
    my %msg = $folder->search(email => 'hello@test.com', subject => qr/this is a subject/);
    $folder->clear();

=cut

=head1 Methods

=cut

use strict;
use warnings;
use Encode qw(decode);
use Scalar::Util qw(blessed);
use base 'Email::Folder';
use Email::MIME;
use mro;

our $VERSION = '0.012';

=head2 new($folder, %options)

takes the name of a folder, and a hash of options

options:

=over

=item timeout

The seconds that search will wait if the email cannot be found.

=back

=cut

sub new {
    my ($class, @args) = @_;
    my $self = $class->next::method(@args);
    $self->{folder_path} = $args[0];
    $self->{timeout} //= 3;
    return $self;
}

=head2 search(email => $email, subject => qr/the subject/);

get emails with receiver address and subject(regexp). Return an array of messages which are hashref.

    my $msgs = search(email => 'hello@test.com', subject => qr/this is a subject/);

=cut

sub search {
    my ($self, %cond) = @_;

    die 'Need email address and subject regexp' unless $cond{email} && $cond{subject} && ref($cond{subject}) eq 'Regexp';

    my $email          = $cond{email};
    my $subject_regexp = $cond{subject};

    my @msgs;

    my $found = 0;
    #mailbox maybe late, so we wait 3 seconds
    WAIT: for (0 .. $self->{timeout}) {
        MSG: while (my $tmsg = $self->next_message) {
            $tmsg = Email::MIME->new($tmsg->as_string);
            my $address = $tmsg->header('To');
            my $from    = $tmsg->header('From');
            my $subject = $tmsg->header('Subject');

            if ($address eq $email && $subject =~ $subject_regexp) {
                my %msg;
                $msg{body}    = $tmsg->body_str;
                $msg{address} = $address;
                $msg{subject} = $subject;
                $msg{from}    = $from;
                $msg{MIME}    = $tmsg;
                push @msgs, \%msg;
                $found = 1;
            }
        }
        last WAIT if $found;
        # reset reader
        $self->reset;
        sleep 1;
    }
    return @msgs;
}

=head2 reset

Reset the mailbox

=cut

sub reset {    ## no critic (ProhibitBuiltinHomonyms)
    my $self         = shift;
    my $reader_class = blessed($self->{_folder});
    delete $self->{_folder};
    $self->{_folder} = $reader_class->new($self->{folder_path}, %$self);
    return;
}

=head2 clear

clear the content of mailbox

=cut

sub clear {
    my $self = shift;
    my $type = blessed($self->{_folder}) // '';

    $self->reset;

    if ($type eq 'Email::Folder::Mbox') {
        truncate($self->{folder_path}, 0) // die "Cannot clear mailbox $self->{folder_path}\n";
    } else {
        die "Sorry, I can only clear the mailbox with the type Mbox\n";
    }

    return 1;
}

=head2 init

init Email folder for test

=cut

sub init {
    my $self = shift;

    my $type = blessed($self->{_folder}) // '';

    if ($type eq 'Email::Folder::Mbox') {
        open(my $fh, ">>", $self->{folder_path}) // die "Cannot init mailbox $self->{folder_path}\n";
        close($fh);
    } else {
        die "Sorry, I can only init the mailbox with the type Mbox\n";
    }
    return 1;
}

=head1 SEE ALSO

L<Email::Folder>

=head1 LICENSE

Same as perl

=cut

1;

