package Email::Store::Attachment;
use base "Email::Store::DBI";
use strict;
use MIME::Parser;
__PACKAGE__->table("attachment");
__PACKAGE__->columns(All => qw[ id mail filename content_type payload ]);
__PACKAGE__->has_a(mail => "Email::Store::Mail");
Email::Store::Mail->has_many(attachments => "Email::Store::Attachment");


sub on_store {
    my ($class, $mail) = @_;

    my $id     = $mail->message_id;
    my $rfc822 = $mail->message;
    my $parser = MIME::Parser->new();

    $parser->output_to_core('ALL');
    $parser->extract_nested_messages(0);

    my $entity = $parser->parse_data($rfc822);

    my @keep;
    for ($entity->parts) {
        push (@keep, $_) && next if keep_part($_);
        my $type    = $_->effective_type;
        my $file    = $_->head->recommended_filename() || invent_filename($type);
        my $payload = $_->bodyhandle->as_string;
        $class->create({ mail => $id,  payload => $payload, content_type => $type, filename => $file });
    }
    $entity->parts(\@keep);
    $entity->make_singlepart;

    $mail->message($entity->as_string);
    undef $mail->{simple}; # Invalidate cache
    $mail->update;
}

sub on_store_order { 1 }

my $gname = 0;

sub invent_filename {
    my ($ct) = @_;
    require MIME::Types;
    my $type = MIME::Types->new->type($ct);
    my $ext = $type && (($type->extensions)[0]);
    $ext ||= "dat";
    return "attachment-$$-".$gname++.".$ext";
}


sub keep_part {
    my $p = shift;
    my $fn = $_->head->recommended_filename();
    my $ct = $p->effective_type                   || 'text/plain';
    my $dp = $p->head->get('Content-Disposition') || 'inline';
    return $ct =~ m[text/plain] && $dp =~ /inline/ && (!defined $fn or $fn =~ /^\s*$/);
}


1;

=head1 NAME

Email::Store::Attachment - Split attachments from mails

=head1 SYNOPSIS

    my @attachments = $mail->attachments;
    for (@attachments) {
        print $_->filename, $_->content_type, $_->payload;
    }

=head1 DESCRIPTION

This plug-in adds the concept of an attachment. At index time, it
removes all attachments from the mail, and stores them in a separate
attachments table. This records the C<filename>, C<content_type> and
C<payload> of the attachments, and each mail's attachments can be
reached through the C<attachments> accessor. The text of the mail,
sans attachments, is replaced into the mail table.

=head1 WARNING

If your database requires you to turn on some attribute for encoding
binary nulls, you need to do this in your call to C<use Email::Store>.

=cut

__DATA__

CREATE TABLE IF NOT EXISTS attachment (
    id           integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
    mail         varchar(255),
    payload      text,
    filename     varchar(255),
    content_type varchar(255)
);
