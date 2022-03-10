package Koha::Contrib::Tamil::Claimer;
$Koha::Contrib::Tamil::Claimer::VERSION = '0.067';
# ABSTRACT: Claim overdues
use Moose;

use feature ":5.10";
use YAML;
use C4::Context;
use C4::Letters;


has rule => ( is => 'rw', isa => 'HashRef' );


# Is the process effective. If not, output the result.
has doit => ( is => 'rw', isa => 'Bool', default => 0 );

# To who sent the notification, rather that the borrower email
has to => ( is => 'rw', isa => 'Str', default => '' );



sub BUILD {
    my $self = shift;

    my $claim_string = C4::Context->preference("ClaimRules");   
    unless ($claim_string) {
        say "ClaimRules system preference not found";
        exit;
    }

    my $rule = {};
    for ( split /\n/, $claim_string ) {
        next if $_ eq '' || /^#/;
        my ($branch, $itype, $day, $action, $notice) = split;
        unless ($branch && $itype && $day && $action && $notice) {
            say "Bad rule: $_";
            next;
        }
        my $branchcode = $branch eq '*' ? '' : $branch;
        $rule->{"$branch-$itype-$day"} = {
            action => $action,
            notice => $notice,
            letter => C4::Letters::getletter('circulation', $notice, $branchcode),
        };
    }
    unless ( keys %$rule ) {
        say "There isn't any valid rule in ClaimRules system preference";
        exit;
    }
    $self->rule($rule);
}


# Substitute letter placeholder with fields values
sub substitute_placeholder {
    my ($content, $record) = @_; # $record contient le prêt
    while ( 1 ) {
        last unless $content =~ /<<(.*?)>>/;
        my $name = $1;
        if ( exists $record->{$name} ) {
            my $value = $record->{$name};
            $content =~ s/<<$name>>/$value/;
            next;
        }
        if ( $name =~ /.*\.(.*)/ ) {
            my $short_name = $1;
            if ( exists $record->{$short_name} ) {
                my $value = $record->{$short_name} || '';
                $value = substr($value, 0, 10)
                    if $short_name eq 'date_due' &&
                       $value =~ /23:59:00/;
                $content =~ s/<<$name>>/$value/;
                next;
            }
        }
        $content =~ s/<<$name>>/unknown $name/;
    }
    return $content;
}


#
# Claim a specific group of issues
#
sub claim {
    my ($self, $borrowernumber, $items, $letter) = @_;

    # On the claim, branch info come from borrower home branch
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("
        SELECT borrowers.*, branches.*, categories.*
          FROM borrowers, branches, categories
         WHERE borrowers.borrowernumber = ?
           AND categories.categorycode = borrowers.categorycode
           AND branches.branchcode = borrowers.branchcode
        ");
    $sth->execute($borrowernumber);
    my $borr = $sth->fetchrow_hashref;

    # Skip issue from borrower of specific category
    return unless $borr->{overduenoticerequired};

    my $sql = "
        SELECT items.*,
               itemtypes.*,
               branches.branchname AS item_branch,
               biblio.*,
               biblioitems.*,
               issues.date_due,
               issues.issuedate,
               TO_DAYS(NOW())-TO_DAYS(date_due) AS overdue_days
          FROM issues, items, itemtypes, branches, biblio, biblioitems
         WHERE issues.itemnumber IN (" . join(',', @$items) . ")
           AND items.itemnumber = issues.itemnumber
           AND itemtypes.itemtype = items.itype
           AND branches.branchcode = items.holdingbranch
           AND biblio.biblionumber = items.biblionumber
           AND biblioitems.biblionumber = items.biblionumber";
    $sth = $dbh->prepare($sql);
    $sth->execute;
    my %let = %$letter;
    my $content = $let{content};
    my ($icontent) = $content =~ /<items>(.*)<\/items>/s;
    die "No placeholder <items></items> in " . $letter->{code}
        unless $icontent;
    my $buffer = '';
    while ( my $issue = $sth->fetchrow_hashref ) {
        my $ibuffer = $icontent;
        $buffer .= substitute_placeholder($ibuffer, $issue);
    }
    $content =~ s/(.*)<items>.*<\/items>(.*)$/$1$buffer$2/s;

    # Substitute borrowers placeholder
    $content = substitute_placeholder( $content, $borr );

    $let{content} = $content;
    if ( $self->doit ) {
        my $to_address = $self->to || $borr->{email};
        C4::Letters::EnqueueLetter( {
             letter                 => \%let,
             borrowernumber         => $borrowernumber,
             message_transport_type => 'email',
             to_address             => $to_address,
             from_address           => $borr->{branchemail},
        } );
    }
    else {
        print "CLAIM TO: ", $borr->{firstname}, " ", $borr->{surname}, "\n",
              "Letter:   ", $let{code}, " - ", $let{name}, "\n",
              '-' x 72, "\n",
              $content, "\n\n";
    }
}


sub handle_borrower {
    my ($self, $borrower) = @_;
    return unless $borrower->{borrowernumber};

    while ( my ($action, $action_href) = each %{$borrower->{action}} ) {
        while ( my ($notice, $notice_href) = each %$action_href ) {
            if ( $action == 1 ) {
                $self->claim(
                    $borrower->{borrowernumber},
                    $notice_href->{items}, $notice_href->{letter} );
            }
            elsif ( $action == 2 ) {
                # Debarre
            }
        }
    }
}


sub claim_all_overdues {
    my $self = shift;
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("
        SELECT borrowers.borrowernumber,
               issues.itemnumber,
               issues.branchcode,
               itype,
               TO_DAYS(NOW())-TO_DAYS(date_due) AS day
          FROM issues, borrowers, items
         WHERE date_due < NOW()
           AND borrowers.borrowernumber = issues.borrowernumber
           AND items.itemnumber = issues.itemnumber
      ORDER BY borrowers.borrowernumber
    ");
    $sth->execute;
    my $borrower = { borrowernumber => 0 };
    while ( my ($borrowernumber, $itemnumber, $branch, $itype, $day)
            = $sth->fetchrow )
    {
        $itype ||= '';
        #say "borrowernumber = $borrowernumber";
        #say "day = $day";
        my $rule = $self->rule->{"$branch-$itype-$day"} ||
                   $self->rule->{"*-$itype-$day"}       ||
                   $self->rule->{"$branch-*-$day"}      ||
                   $self->rule->{"*-*-$day"};
        next unless $rule;
        if ( $borrowernumber != $borrower->{borrowernumber} ) {
            $self->handle_borrower( $borrower );
            $borrower = { borrowernumber => $borrowernumber, action => {} };
        }
        #say "rule = ", Dump($rule);
        my $action = $borrower->{action}->{$rule->{action}} ||= {};
        my $notice = $action->{$rule->{notice}}
                     ||= { letter => $rule->{letter}, items => [] };
        my $items = $notice->{items};
        push @$items, $itemnumber;
    }
    $self->handle_borrower( $borrower );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Claimer - Claim overdues

=head1 VERSION

version 0.067

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
