package Email::Store::List;
use strict;
use warnings;
use base 'Email::Store::DBI';
use Mail::ListDetector 0.31;
Email::Store::List->table("list");
Email::Store::List->columns(All => qw/id name posting_address/);
Email::Store::List->columns(Primary => qw/id/);

sub on_store_order { 70 }

sub _detect {
    my ($self, $simple) = @_;
    my $list = Mail::ListDetector->new( $simple ) or return;
    Email::Store::List->find_or_create({
        name => $list->listname,
        posting_address => $list->posting_address
    });
}

sub on_store {
    my ($class, $mail) = @_;
    my $simple = $mail->simple;
    my $list = $class->_detect($simple) or return;
    my $subject = $simple->header("Subject");
    my $name = $list->name;
    if ($subject =~ s/\[\Q$name\E\]\s*//ig) {
        $simple->header_set("Subject", $subject);
        $mail->message($simple->as_string);
        $mail->update;
    }
    $list->add_to_posts({mail => $mail->id});
}

sub on_seen_duplicate_order { 1 }
sub on_seen_duplicate { 
    my ($class, $mail, $orig) = @_;
    my $new_list = $class->_detect($orig) or return;
    $new_list->add_to_posts({mail => $mail->id})
        unless Email::Store::List::Post->search( mail => $mail->id,
                               list => $new_list->id
                             );
}

package Email::Store::List::Post;
use base 'Email::Store::DBI';
Email::Store::List::Post->table("list_post");
Email::Store::List::Post->columns(All => qw/id mail list/);
Email::Store::List::Post->columns(Primary => qw/id/);

# Relationships
Email::Store::List::Post->has_a(mail => "Email::Store::Mail");
Email::Store::List::Post->has_a(list => "Email::Store::List");
Email::Store::List->has_many(posts => [ "Email::Store::List::Post" => "mail" ]);
Email::Store::Mail->has_many(lists => [ "Email::Store::List::Post" => "list" ]);

package Email::Store::List;
1;

=head1 NAME

Email::Store::List - Detect and store information about mailing lists

=head1 SYNOPSIS

    # Look for cross-posts in perl6-internals
    my ($p6i) = Email::Store::List->search( name => "perl6-internals" );
    @mails = $p6i->posts;
    
    for my $mail (@mails) {
        print "Mail ".$mail->message_id." cross-posted to ".$_->name."\n"
        for grep {$_ != $p6i} $mail->lists;
    }

=head1 DESCRIPTION

This plugin adds the concepts of a C<list> and a C<post>. A list
represents a mailing list, which has a C<name> and a C<posting_address>.
When mails are indexed, C<Mail::ListDetector> is used to identify lists
mentioned in mail headers. C<post>, which is largely transparent, is the
many-to-many table used to map mails to lists and vice versa.

If a mail is seen for the second time, it is re-examined for mailing
list headers, as a mail with the same message ID may be Cc'd to multiple
lists and appear through them several times. Note that
C<Mail::ListDetector> looks at headers added by the mailing list
software, not the C<Cc>, C<To> and C<From> headers.

=cut

__DATA__
CREATE TABLE IF NOT EXISTS list (
    id integer NOT NULL auto_increment primary key,
    name varchar(255),
    posting_address varchar(255)
);

CREATE TABLE IF NOT EXISTS list_post (
    id integer NOT NULL auto_increment primary key,
    list integer,
    mail varchar(255)
);
