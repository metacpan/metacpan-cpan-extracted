package Mail::Miner::Mail;

use strict;
use warnings;
use Carp;
use base 'Mail::Miner::DBI';
use Date::Manip qw(UnixDate ParseDate);
use Mail::Miner::Attachment;
use Mail::Miner;

__PACKAGE__->set_up_table('messages');
__PACKAGE__->has_many("assets", 'Mail::Miner::Asset' => "message_id");
__PACKAGE__->has_many("attachments", 'Mail::Miner::Attachment' => "message_id");
__PACKAGE__->has_a(
    content => 'MIME::Entity',
    inflate => sub { $Mail::Miner::parser->parse_data(shift) },
    deflate => 'stringify'
);

sub date_epoch {
    my $obj = shift;
    return UnixDate(ParseDate($obj->received), '%s');
}

sub create {
    my ($class, $message) = @_;
    croak "Not a MIME::Entity" unless $message->isa("MIME::Entity");
    my $head = $message->head;
    my $format = "%Y-%m-%d %H:%M:%S";

    my ($subject, $from) = map { $head->get($_) } qw(Subject From);

    chomp $subject; $subject =~ s/^\s+//; $subject =~ s/\s+$//;
    chomp $from;    $from    =~ s/^\s+//; $from    =~ s/\s+$//;

    my $obj = $class->SUPER::create(
        {
        from_address => ($from    || "(Unknown Sender)"),
        subject      => ($subject || "(No subject)"),
        received     => (UnixDate(
                            ParseDate($head->get("Date") || scalar localtime)
                         , $format))
        }
    );
    
    $message = Mail::Miner::Attachments::detach_attachments($obj, $message);
    $obj->content($message);
    Mail::Miner::Assets::miner_analyse($obj);
    $obj->commit;
    return $obj;
}

#sub _quote {
#    my ($dbh) = (__PACKAGE__->db_handles)[0];
#    return $dbh->quote(shift);
#}
our %basic = # Add additional "basic" terms here
    ( from     => { field => "from_address", type => "=s",
                    help => "Match messages from a given sender" },
      subject  => { field => "subject",      type => "=s",
                    help => "Match messages with a given subject" },
      id       => { field => "id", type => "=i" ,
                    help => "Match a given Mail Miner ID"} );


sub select {
    my $class = shift;
    my %options = @_;
    # We have some conditions, we'd like a bunch of objects.
    my %search;

    for (keys %basic) {
        next unless exists $options{$_};
        my $match = $basic{$_};
        if ($match->{type} eq "=s") {
            $search{$match->{field}} = "%$options{$_}%";
        } elsif ($match->{type} eq "=i") {
            my $id;
            ($id = $options{$_}) =~ s/\D//g;
            die "Search term '$options{$_}' for field $_ should be numeric.\n" unless length $id;
            $search{$match->{field}} = $id;
        } else {
            die "Internal urp: Bad match type for $_\n";
        }
        delete $options{$_};
    }

    if (!%options) { # Just a basic search
        if (!%search) { return $class->retrieve_all };
        return $class->search_like(%search);
    }
    # OK, let's grab a candidate set of records.

    my $it = %search ? $class->search_like(%search) : $class->retrieve_all;
    
    my @rv;
    my %plugins = Mail::Miner->plugins();

    MAILS: while (my $mail = $it->next) {
        my @assets = $mail->assets;
        next unless @assets;
        for my $opt (keys %options) {
            die "Unknown search term $opt (".(join ",", keys %plugins).")\n"
                unless $plugins{$opt};
            my $term = $options{$opt};
            my @relevant_assets = grep {$_->creator eq $plugins{$opt}} @assets;

            # Do we have a specialised search engine for this plugin?
            no strict 'refs';
            if (defined (my $search = *{$plugins{$opt}."::search"}{CODE})) {
                next MAILS 
                 unless $search->($mail, $term, @relevant_assets);
            }

            # OK, just do an ordinary regex search on the asset.
            next MAILS 
                 unless grep { $_->asset =~ /$term/ } @relevant_assets;
        }
        # We made it.
        push @rv, $mail;
    }
    return @rv;
}

sub display_verbose {
    my ($class, @objs) = @_;
    for (@objs) {
        print "From mail-miner-".$_->id."\@localhost @{[scalar localtime]}\n";
        print $_->content->stringify;
        print "\n\n# Mail Miner ID: ".$_->id."\n\n";
        # Makes it handy mailbox format.
    }
}

sub display_summary { 
    my ($class, $rr, @objs) = @_;
    my %plugins = Mail::Miner->plugins;
    my %options = map { $plugins{$_} => 1 } @$rr;
    if (!@objs) {
        print "No messages matched.\n"; return;
    }
    print @objs." matches\n";
    my $id_width = (sort map {length $_->id} @objs)[-1];
    for (@objs) {
        printf "%${id_width}i:%10s:%40s:%s\n",
            $_->id,
            substr($_->received,0,10),
            substr($_->from_address,-40,40),
            substr($_->subject,0,$ENV{COLUMNS}?$ENV{COLUMNS}-(53+$id_width):25-$id_width);
        my $last = "";
        for (sort {$a->creator cmp $b->creator } $_->assets) {
            next unless $options{$_->creator};
            my $metadata = $Mail::Miner::recognisers{$_->creator};
            next if $metadata->{nodisplay};
            print "  ".$metadata->{title}.":\n" unless $last eq $_->creator; 
            $last = $_->creator;
            print $_->asset,"\n";
        }
    }
}
1;
