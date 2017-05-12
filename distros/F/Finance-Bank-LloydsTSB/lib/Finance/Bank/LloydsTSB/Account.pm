package Finance::Bank::LloydsTSB::Account;

=head1 NAME

Finance::Bank::LloydsTSB::Account - 

=head1 SYNOPSIS

synopsis

=head1 DESCRIPTION

description

=cut

use strict;
use warnings;

our $VERSION = '1.35';
our $DEBUG = 0;

use Time::Local;

use Finance::Bank::LloydsTSB::Statement;
use Finance::Bank::LloydsTSB::utils qw(debug);

sub ua         { shift->{ua}         }
sub name       { shift->{name}       }
sub descr_num  { shift->{descr_num}  }
sub sort_code  { shift->{sort_code}  }
sub account_no { shift->{account_no} }
sub balance    { shift->{balance}    }
sub parent     { shift->{parent}     }
sub form_index { shift->{form_index} }

sub _on_account_overview_page {
    my $self = shift;
    $self->debug("On account overview page?\n");

    # Notice case difference of 'O' between this and navigation link to
    # this page
    if ($self->ua->content =~ /Account Overview/) {
        $self->debug("yes\n");
        return 1;
    }
    else {
        $self->debug("no\n");
        return 0;
    }
}

sub _navigate_to_account_overview {
    my $self = shift;

    if (! $self->_on_account_overview_page) {
# This is the one we want
#         my @links = $self->ua->find_all_links;
#         my $correct = $links[0]->text;

        # GRR!  &nbsp; gets decoded into \xa0 by HTML::TokeParser
        # (which uses HTML::Entities::decode_entities)
        unless ($self->ua->follow_link(text_regex =>
                                         qr/Account[ \xa0]overview/))
        {
#             my $dumpfile = '/tmp/dump.html';
#             $self->debug("Writing content to $dumpfile\n");
#             $self->ua->save_content($dumpfile);
#             my @context = $self->ua->content =~ /(.{100}overview.{100,}?$)/gims;
#             die "no overview???", $self->ua->content
#               unless @context;
#               map "---\n$_\n---\n", @context;
            die "Couldn't go to account overview page\n";
        }
        $self->debug("Gone to account overview page\n");
    }
}

sub _on_account_details_page {
    my $self = shift;
    $self->debug("On details page for ", $self->name, "?\n");

    if ($self->ua->content !~ /Your account details/) {
        $self->debug("no\n");
        return 0;
    }

    if ($self->_check_selected_account_text) {
        $self->debug("yes\n");
        return 1;
    }

    $self->debug("no\n");
    return 0;
}

sub _check_selected_account_text {
    my $self = shift;

    # Look for a table which has the right 'Selected account' in the
    # header.
    my $te = new HTML::TableExtract;
    $te->parse($self->ua->content);
    foreach my $ts ($te->table_states) {
        my @rows = $ts->rows;
        my $header = $rows[0];
        foreach my $td (@$header) {
            if ($td =~ /Selected account/ && (index($td, $self->{name}) >= 0)) {
                return 1;
            }
        }
    }
    
    return 0;
}

sub _navigate_to_details {
    my $self = shift;
    if ($self->_on_account_details_page) {
        $self->debug("Already on details page for ", $self->name, "\n");
        return;
    }

    if (! $self->_on_account_overview_page) {
        $self->_navigate_to_account_overview;
    }

    $self->ua->follow_link(text => $self->name)
      or die "Couldn't go to account ", $self->name;
    $self->debug("Gone to ", $self->name, " details page\n");
}

sub _on_account_statement_page {
    my $self = shift;
    $self->debug("On account statement page?\n");

    if ($self->ua->content !~ /Your account statement/) {
        $self->debug("no\n");
        return 0;
    }

    if ($self->_check_selected_account_text) {
        $self->debug("yes\n");
        return 1;
    }
    
    $self->debug("yes\n");
    return 1;
}

sub _navigate_to_statement {
    my $self = shift;

    if ($self->_on_account_statement_page) {
        $self->debug("Already on statement page for ", $self->name, "\n");
        return;
    }

    $self->_navigate_to_account_overview;

    if (0) {
      # Go via details page
      $self->_navigate_to_details;
      $self->ua->follow_link(text => 'Statement')
        or die "Couldn't go to statement for ", $self->name;
    }
    else {
      # Go via Options form
      my $form = $self->ua->form_number($self->form_index);
      $self->ua->select('SelectAction', 'statement.ibc');
      my $response = $self->ua->submit_form;
      die "submit of $self->name actions form failed with HTTP code ",
          $response->code, "\n" # also $self->ua->status
        unless $response->is_success; # also $self->ua->success
    }

    $self->debug("Gone to ", $self->name, " statement page\n");
}

sub _on_account_statement_download_page {
    my $self = shift;
    $self->debug("On account statement download page?\n");

    if ($self->ua->content !~ /Download a statement/) {
        $self->debug("no\n");
        return 0;
    }

    if ($self->_check_selected_account_text) {
        $self->debug("yes\n");
        return 1;
    }
    
    $self->debug("yes\n");
    return 1;
}

sub _navigate_to_statement_download {
    my $self = shift;

    if ($self->_on_account_statement_download_page) {
        $self->debug("Already on statement download page for ", $self->name, "\n");
        return;
    }

    $self->_navigate_to_statement;

    # <option value="6">Download a statement</option>
    $self->ua->select("selectbox", 6);

    # This used to work, but now the Go <input> button has name="" :-(
#    $self->ua->click_button(value => "Go");
    $self->ua->submit_form(form_name => "StatementSearch");

    die "Go to download statement failed with HTTP ", $self->ua->status
      unless $self->ua->success;
    $self->debug("Gone to ", $self->name, " statement download page\n");
}

=head2 fetch_statement

Fetches a Finance::Bank::LloydsTSB::Statement object representing the
latest statement page.

=cut

sub fetch_statement {
    my $self = shift;

    $self->_navigate_to_statement;

    my $te = new HTML::TableExtract(
        headers => [
            "Date",
            "Payment Type",
            "Details",
            "Paid Out",
            "Paid In",
            "Balance",
        ]
    );
    (my $html = $self->ua->content) =~ s/&nbsp;/ /g;
    $te->parse($html);
    my @tables = $te->tables;
    die "Couldn't find unique statement table" unless @tables == 1;

    my $DATE_RE = qr/^([ \d]\d)(\w\w\w)(\d\d)$/;

    my @transactions;
    my @fields = qw(date type details out in balance);

  ROW:
    foreach my $row ($tables[0]->rows) {
        my %transaction;
        for my $i (0 .. $#fields) {
            my $field = $fields[$i];
            my $cell = $row->[$i];
            if (ref $cell eq 'SCALAR') {
              $cell = $$cell;
            }
            elsif (ref($cell) =~ /HTML/) {
              $cell = $cell->as_trimmed_text;
            }
            next ROW unless defined $cell;
            $transaction{$field} = $cell;
        }
        next unless $transaction{date} =~ /\S/;
        if ($transaction{date} =~ $DATE_RE) {
            $transaction{dom} = $1;
            $transaction{month} = $2;
            $transaction{year} = $3;
        }
        else {
            warn "transaction date '", $transaction{date}, "' didn't match /$DATE_RE/\n";
        }
        push @transactions, \%transaction;
    }

    return bless({
        transactions => \@transactions,
        start_date   => $transactions[ 0]{date},
        end_date     => $transactions[-1]{date},
    }, 'Finance::Bank::LloydsTSB::Statement');
}

=head2 download_statement($year, $month, $day, $duration)

Downloads a statement in QIF format for time period starting on the
given date, and returns it in a scalar.

Duration options are taken from the website's HTML:

    <option value="1">This date only</option>
    <option value="2">+/- 1 week</option>
    <option value="3">+/- 2 weeks</option>
    <option value="4">+/- 3 weeks</option>
    <option value="5">+ 1 month</option>
    <option value="6">+ 2 months</option>
    <option value="7">+ 3 months</option>

e.g. 5 for 1 month's worth of QIF transactions.

=cut

sub download_statement {
    my $self = shift;
    my ($year, $month, $day, $duration) = @_;

    $self->debug("Downloading statement for $year/$month/$day, duration option $duration\n");
    $self->_navigate_to_statement_download;
    $self->debug("\n");

    $self->ua->set_fields(
        DateYear => $year,
        DateMonth => $month,
        DateDay => $day,
        DateRangeSelection => $duration,
        # radio button, 'DownloadLatest' is the other option
        'Download' => 'DownloadDate',
    );

    $self->ua->select('Format', 104); # download as QIF
    $self->ua->submit_form;
    my $ok = 0;
    my $ct = $self->ua->ct;
    if ($ct eq 'text/x-qif') {
      $self->debug("Got content type $ct\n");
      $ok = 1;
    }
    else {
      warn "Expected content type 'text/x-qif' but got '$ct'\n";
    }
    my $qif = $self->ua->content;

    # For some extremely weird reason, if we do this:

#     # pop .qif download off stack so that we can still use other links
#     $self->debug("Going back a page\n");
#     $self->ua->back; 

    # then $self->ua->follow_link either leads us back to the login
    # page or gets us into a state where we can't do anything.

    # A workaround is to start at the beginning:
    $self->ua->get("https://online.lloydstsb.co.uk/customer.ibc");
    # although this time we don't need to log in.

    return ($ct, $qif);
}

1;

