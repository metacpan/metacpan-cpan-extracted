
package Mail::Miner::Attachment;
use base 'Mail::Miner::DBI';
__PACKAGE__->set_up_table("attachments");

1;
package Mail::Miner::Attachments;
use strict;
use Exporter;
use Mail::Address;
our @ISA = qw(Exporter);
our @EXPORT = qw(detach_attachments detach);

my $GFileNo;

=head1 NAME

Mail::Miner::Attachment - Backend methods for Mail::Miner attachments

=head1 DESCRIPTION

This module implements some backend functionality for dealing with
C<Mail::Miner> attachments.

=head2 C<detach_attachments>

    detach_attachments($entity, $messageid);

This subroutine takes a C<MIME::Entity> object, and flattens it,
storing any parts which are non-text, or have a recommended filename, into
the database. The textual body of the message is updated to alert the
user to how to extract the attachments.

=cut

my %ok_parts = map { $_ => 1 } ( "text/plain", "multipart/alternative");

sub detach_attachments {
    my $object = shift;
    my $entity = shift;
    my @body;
    my $content;

    $entity->make_multipart;
    for ($entity->parts) {
        my $fn = $_->head->recommended_filename;
        if (exists($ok_parts{$_->mime_type})  and !$fn) {
            $content = $_ unless $content;
            push @body, @{$_->body};
        } else {
            my $att = $_->mime_type;
            my $add = $object->add_to_attachments({
         filename => $fn,
         contenttype => $_->mime_type,
         encoding => ($_->bodyhandle && $_->bodyhandle->as_string)
            });

            return $entity unless $add->id; # Just in case
            push @body, "\n", 
                "[ ".$entity->mime_type." attachment $fn detached - use \n",
                "\tmm --detach ".$add->id."\n",
                " to recover ]\n";
        }
    }
    if ($content) {
        my $io;
        if ($io = $content->open("w")) {
           foreach (@body) { $io->print($_) }
           $io->close;
        }
    } else { 
        # Shit, no text at all
        $content =  MIME::Entity->build(
                Type        => "text/plain",
                Data        => \@body
        );
    }
    $entity->parts([$content]);
    $entity->make_singlepart;
    return $entity;
}

=head2 C<detach>

    detach($msgid)

This implements the front-end C<detach> option to C<mm>, the Mail::Miner 
command-line tool. It saves a message's attachments to the current
directory, interactively. 

=cut

sub detach {
    my $id = shift;
    my $obj = Mail::Miner::Attachment->fetch($id);

    die "Couldn't find that attachment!\n" unless $obj;

    my $first=0;
    my $filename = $a->filename ||
                   _gen_filename($a->contenttype);

    my $from = _namefrom(Mail::Address->parse($a->from_address));
    print "Detaching $filename (".$a->contenttype.") sent by $from...\n";
    
    if (-e $filename) {
        print "\n! $filename already exists. Replace? (y/N)\n";
        my $foo = <STDIN>;
        if ($foo !~ /^y/i) {
            print "OK, skipping...\n";
            next;
            }
        }
        open (OUT, ">", $filename) or do {warn "! $filename: $!\n"; next;};
        print OUT $a->attachment;
        close OUT;
}

sub _gen_filename {
    my $content_type = shift;
    # We're only using this for the generation of file names, so the
    # directory we feed it is irrelevant.
    my $filer = MIME::Parser::FileInto->new("/tmp");
    # This code borrowed from MIME::Parser::Filer
    my ($type, $subtype) = split m{/}, $content_type;
    $subtype ||= '';
    my $ext = ($filer->{MPF_Ext}{"$type/$subtype"} ||
               $filer->{MPF_Ext}{"$type/*"} ||
               $filer->{MPF_Ext}{"*/*"} ||
               ".dat");
    ++$GFileNo;
    return "attachment-$$-$GFileNo$ext";
}

sub _namefrom {
    my $what=shift;
    return unless $what;
    my ($address, $name, $phrase) = ($what->address, $what->name, $what->phrase);

    return  $name || $phrase || $address;
}

1;
