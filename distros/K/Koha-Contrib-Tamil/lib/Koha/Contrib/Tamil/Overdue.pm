package Koha::Contrib::Tamil::Overdue;
$Koha::Contrib::Tamil::Overdue::VERSION = '0.070';
use Moose;
use Modern::Perl;
use YAML qw/ Dump LoadFile /;
use DateTime;
use List::Util qw/ first /;
use Path::Tiny;
use Text::Xslate;
use C4::Context;
use C4::Letters;
use C4::Letters;


# Is the process effective. If not, output the result.
has doit => ( is => 'rw', isa => 'Bool' );

# Is the process effective. If not, output the result.
has verbose => ( is => 'rw', isa => 'Bool' );


has c => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {
        my $file = $ENV{KOHA_CONF};
        $file =~ s/koha-conf\.xml/overdue\/config.yaml/;
        my $c = LoadFile($file);
        return $c;
    },
);

has tx => ( is => 'rw', isa => 'Text::Xslate' );

has now => (
    is => 'rw',
    isa => 'Str',
);


sub BUILD {
    my $self = shift;

    DateTime->DefaultLocale( $self->c->{date}->{locale} );
    my $d = DateTime->now()->strftime( $self->c->{date}->{now} );
    $d =~ s/  / /g;
    $self->now( $d );

    $self->tx( Text::Xslate->new(
        path => $self->c->{dirs}->{template},
        suffix => '.tx',
        type => 'text',
    ) );
}

 
#
# Claim a specific group of issues
#
sub claim {
    my ($self, $borrowernumber, $cycle, $items) = @_;
 
    # On the claim, branch info come from borrower home branch
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("
        SELECT *
          FROM borrowers
     LEFT JOIN branches USING(branchcode)
     LEFT JOIN categories USING(categorycode)
         WHERE borrowernumber=?" );
    $sth->execute($borrowernumber);
    my $borr = $sth->fetchrow_hashref;
    $borr->{$_} ||= '' for qw/ firstname surname /;
    my $has_email = $borr->{email} ? 1 : 0;

    # Skip issue from borrower of specific category
    return unless $borr->{overduenoticerequired};

    my $context = {
        now => $self->now,
        borrower => $borr,
    };
    if ( my $id = $borr->{guarantorid} ) {
        $sth = $dbh->prepare("
            SELECT *
              FROM borrowers
         LEFT JOIN branches USING(branchcode)
         LEFT JOIN categories USING(categorycode)
             WHERE borrowernumber=?" );
        $sth->execute($id);
        if ( my $g = $sth->fetchrow_hashref ) {
            $g->{$_} ||= '' for qw/ firstname surname /;
            $context->{guarantor} = $g;
        }
    }
    my $sql = "
        SELECT items.*,
               itemtypes.description  AS 'type.description',
               holding.branchname     AS 'holding.name',
               holding.branchaddress1 AS 'holding.address1',
               holding.branchaddress2 AS 'holding.address2',
               holding.branchaddress3 AS 'holding.address3',
               holding.branchzip      AS 'holding.zip',
               holding.branchcity     AS 'holding.city',
               holding.branchstate    AS 'holding.state',
               holding.branchcountry  AS 'holding.country',
               holding.branchphone    AS 'holding.phone',
               holding.branchemail    AS 'holding.email',
               holding.branchurl      AS 'holding.url',
               home.branchname        AS 'home.name',
               home.branchaddress1    AS 'home.address1',
               home.branchaddress2    AS 'home.address2',
               home.branchaddress3    AS 'home.address3',
               home.branchzip         AS 'home.zip',
               home.branchcity        AS 'home.city',
               home.branchstate       AS 'home.state',
               home.branchcountry     AS 'home.country',
               home.branchphone       AS 'home.phone',
               home.branchemail       AS 'home.email',
               home.branchurl         AS 'home.url',
               biblio.author          AS 'biblio.author',
               biblio.title           AS 'biblio.title',
               biblio.unititle        AS 'biblio.unititle',
               biblio.notes           AS 'biblio.notes',
               biblioitems.volume     AS 'biblio.volume',
               biblioitems.number     AS 'biblio.number',
               biblioitems.itemtype   AS 'biblio.type',
               biblioitems.isbn       AS 'biblio.isbn',
               biblioitems.lccn       AS 'biblio.lccn',
               issues.date_due        AS 'issue.date_due',
               issues.issuedate       AS 'issue.issuedate',
               TO_DAYS(NOW())-TO_DAYS(date_due) AS 'issue.overdue_days'
          FROM issues
     LEFT JOIN items USING(itemnumber)
     LEFT JOIN itemtypes ON itemtypes.itemtype = items.itype
     LEFT JOIN branches AS holding ON holding.branchcode = items.holdingbranch
     LEFT JOIN branches AS home ON home.branchcode = items.homebranch
     LEFT JOIN biblio USING(biblionumber)
     LEFT JOIN biblioitems USING(biblionumber)
         WHERE issues.itemnumber IN (" . join(',', @$items) . ")";
    $sth = $dbh->prepare($sql);
    $sth->execute;
    my $i = $context->{items} = [];
    my $strftime = $self->c->{date}->{due};
    while ( my $item = $sth->fetchrow_hashref ) {
        for my $name ( ('issue.date_due', 'issue.issuedate') ) {
            my $d = $item->{$name};
            $d = DateTime->new(
                year  => substr($d, 0, 4),
                month => substr($d, 5, 2),
                day   => substr($d, 8, 2) );
            $item->{$name} = $d->strftime($strftime);
        }
        push @$i, $item;
    }

    for my $claim ( @{$cycle->{claims}} ) {
        next if $claim->{type} eq 'email' && !$has_email;
        $context->{title} = $cycle->{title};
        my $template = $claim->{template};
        #say "CONTEXT", Dump($context);
        $self->tx->{type} = $has_email ? 'text' : 'html';
        my $content = $self->tx->render($template , $context);
        $content =~ s/&#39;/'/g; #FIXME: why?
        my $letter = {
            title => $cycle->{title},
            content => $content,
            'content-type' => $has_email ? 'text/plain; charset="UTF-8"' : 'text/html; charset="UTF-8"', 
        };
        if ( $self->verbose ) {
            say $letter->{title}, ": borrower #", $borr->{borrowernumber}, " ",
                $borr->{surname}, " ", $borr->{firstname};
        }
        if ( $self->doit ) {
            C4::Letters::EnqueueLetter( {
                 letter                 => $letter,
                 borrowernumber         => $borrowernumber,
                 message_transport_type => $claim->{type},
                 to_address             => $borr->{email} || '',
                 from_address           => $borr->{branchemail},
            } );
        }
        elsif ( $self->verbose ) {
            say '-' x 72, "\n", $content, "\n";
        }
        last;
    }
 
}


sub handle_borrower {
    my ($self, $borrower) = @_;
    return unless $borrower->{borrowernumber};

    while ( my ($icycle, $items) =  each %{$borrower->{cycles}} ) {
        $self->claim(
            $borrower->{borrowernumber},
            $self->c->{cycles}->[$icycle],
            $items 
        );
    }
}
 

my @fnames = qw/
    day
    borrower.category
    borrower.branch
    item.home
    item.holding
    item.type
    item.ccode
    biblio.type
/;


sub process {
    my $self = shift;
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("
        SELECT borrowers.borrowernumber,
               issues.itemnumber,
               TO_DAYS(NOW())-TO_DAYS(date_due) AS day,
               borrowers.branchcode   AS 'borrower.branch',
               borrowers.categorycode AS 'borrower.category',
               homebranch             AS 'item.home',
               holdingbranch          AS 'item.holding',
               itype                  AS 'item.type',
               items.ccode            AS 'item.ccode',
               itemtype               AS 'biblio.type'
          FROM issues
     LEFT JOIN borrowers USING(borrowernumber)
     LEFT JOIN items USING(itemnumber)
     LEFT JOIN biblioitems ON biblioitems.biblionumber = items.biblionumber
         WHERE date_due < NOW()
      ORDER BY surname, firstname
    ");
    $sth->execute;
    my $borrower = { borrowernumber => 0 };
    my @cycles = @{$self->c->{cycles}};
    while ( my $issue = $sth->fetchrow_hashref ) {
        my $icycle = 0;
        my $match;
        while ( $icycle < @cycles ) {
            my $cycle = $cycles[$icycle];
            my $criteria = $cycle->{criteria};
            my $code = $criteria;
            $code =~ s/$_/\$issue->{'$_'}/g for @fnames;
            $code = "\$match = $code";
            eval($code);
            if ( $@ ) {
                say "Wrong citeria:\n  $criteria\n  $code";
                warn();
                exit;
            }
            last if $match;
            $icycle++;
        }
        next unless $match;
        if ( $issue->{borrowernumber} != $borrower->{borrowernumber} ) {
            $self->handle_borrower($borrower);
            $borrower = { borrowernumber => $issue->{borrowernumber}, cycles => {} };
        }
        my $cycles = $borrower->{cycles};
        my $items = $cycles->{$icycle} ||= [];
        push @$items, $issue->{itemnumber};
    }
    $self->handle_borrower($borrower);
}


sub clear {
    my $sql =
        "DELETE FROM message_queue
          WHERE status = 'pending'
            AND message_transport_type IN ('email','print')
            AND time_queued >= DATE_SUB(now(), interval 1 HOUR) ";
    C4::Context->dbh->do($sql)
}


sub print {
    my $self = shift;

    my $messages = C4::Letters::_get_unsent_messages( { message_transport_type => 'print' } );
    my %msg_per_branch;
    for my $message ( @$messages ) {
        my $m = $msg_per_branch{$message->{branchcode}} ||= [];
        push @$m, $message;
    }
    $messages = undef;

    my $dir = $self->c->{dirs}->{print};
    say "Print in directory $dir" if $self->verbose;
    chdir $dir;
    my $now = DateTime->now();
    mkdir $now->year  unless -d $now->year;
    chdir $now->year;
    $now = $now->ymd;
    while ( my ($branch, $messages) = each %msg_per_branch ) {
        if ($self->doit) {
            mkdir $branch unless -d $branch;
            chdir $branch;
        }
        my $file = "$now-$branch.html";
        say "Create file $branch/$file" if $self->verbose;
        if ( $self->doit ) {
            my $fh = IO::File->new($file, ">:encoding(utf8)")
                or die "Enable to create $file";
            print $fh $_->{content} for @$messages;
        }
        chdir ".." if $self->doit;
    }

    return unless $self->doit;
    say "Set all 'print' messages from 'pending' to 'sent'" if $self->doit && $self->verbose;
    C4::Context->dbh->do(
        "UPDATE message_queue SET status='sent' WHERE message_transport_type='print'");
}


sub email {
  my $self = shift;
  return unless $self->doit;
  say "Send 'email' messages" if $self->verbose;
  C4::Letters::SendQueuedMessages({ verbose => $self->verbose });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Overdue

=head1 VERSION

version 0.070

=head1 ATTRIBUTES

=head2 c

Content of <KOHA_CONF directorty>/overdue/config.yaml file.

=head1 METHODS

=head2 process 

Process all overdues

=head2 clear

Clear 'email', 'print' messages with 'pending' status from message_queue that
have been added the last hour.

=head2 print

Print all 'print' type letters from message_queue that have 'pending' status.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
