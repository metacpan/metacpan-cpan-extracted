package Finance::Huntington::Statement;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use HTML::Parser;
use Time::Local;

our @ISA = qw(HTML::Parser Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# Preloaded methods go here.

sub new {
        my $usage = <<END;
Usage:
        new Finance::Huntington::Statement ();
END

        my $pkg = shift;
        
        die $usage unless $pkg;

        # Bless our package.
        my $parser = SUPER::new $pkg (
                api_version => 3,
                text_h => [\&_process, "self, dtext"]
                );

        # No broken text.
        $parser->unbroken_text ('TRUE');

        # Set up defaults.
        $parser->{current_section} = 0;
        $parser->{sections} = [
                ["A C C O U N T.*?S T A T E M E N T", \&_process_account_statement],
                ["Deposits", \&_process_deposits],
                ["Check", \&_process_checks],
                ["E-Pay", \&_process_epay],
                ["ATM Transactions", \&_process_atm],
                ["Debit Card", \&_process_debit_cards],
                ["MDC Transactions", \&_process_mdc],
                ["Account Navigation", sub {my $self = shift; $self->eof;}]];

        return $parser;
}

sub _process {
        my $self = shift;
        my $text = shift;

        # Throw away meaningless lines.
        return if $text =~ /^[\W\s]*$/;

        # Trim leading/trailing whitespace.
        $text =~ s/^([^\w\(\)]*)(.*?)([^\w\(\)]*)$/$2/;
        # Escape embedded parens so they don't blow up in regex's.
        $text =~ s/([\(\)])/\\$1/g;

        # See if we are in the next document section yet.
        if ($self->{current_section} < @{$self->{sections}}) {
                my $regex = $self->{sections}->[$self->{current_section}]->[0];
                $self->{current_section}++ if ( $text =~ /$regex/ );
        }

        # Process according to the section we are in. We are not
        # considered to be in a section until we have actually matched
        # the key of the section.  For this reason, we execute the
        # subroutine of $self->{current_section} - 1.
        if ($self->{current_section} > 0) {
                no strict 'refs';
                &{ $self->{sections}->[$self->{current_section} - 1]->[1] } ($self, $text);
                use strict 'refs';
        }
}

sub _process_account_statement {
        my $self = shift;
        my $text = shift;

        # Determine what we are looking for. (We assume that no blank
        # lines will be passed into here.)
        if ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        elsif (!defined ($self->{account_name})) {
                $self->{account_name} = $text;
        }
        elsif (!defined ($self->{account_number})) {
                $self->{account_number} = $text;
        }
        elsif (!defined ($self->{last_updated})) {
                if ($text =~ m%(\d+)/(\d+)/(\d+)@(\d+):(\d+)%) {
                        $self->{last_updated} =
                                timelocal (0, $5, $4, $2, $1, $3);
                }
                else {
                        $self->{last_updated} = 0;
                }
        }
        elsif (!defined ($self->{current_statement_balance})) {
                if ($text =~ /(\d+)\.(\d+)/) {
                        $self->{current_statement_balance} = "${1}.${2}";
                }
                # else we haven't got there yet
        }
        elsif (!defined ($self->{available_statement_balance})) {
                if ($text =~ /(\d+)\.(\d+)/) {
                        $self->{available_statement_balance} = "${1}.${2}";
                }
                # else we haven't got there yet
        }
        elsif (!defined ($self->{current_register_balance})) {
                if ($text =~ /(\d+)\.(\d+)/) {
                        $self->{current_register_balance} = "${1}.${2}";
                }
                # else we haven't got there yet
        }
}

sub _process_atm {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payee',
                'category',
                'amount');

        if (!defined ($self->{atms})) {
                $self->{atms} = [];
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'atms',
                        \@template);
        }
}

sub _process_checks {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payee',
                'category',
                'amount');

        if (!defined ($self->{checks})) {
                $self->{checks} = [];
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'checks',
                        \@template);
        }
}

sub _process_debit_cards {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payee',
                'category',
                'amount');

        if (!defined ($self->{debit_cards})) {
                $self->{debit_cards} = [];
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'debit_cards',
                        \@template);
        }
}

sub _process_deposits {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payor',
                'category',
                'amount');

        if (!defined ($self->{deposits})) {
                $self->{deposits} = [];
                # The regular expression for deposits will currently
                # get hit twice in the Statement.  The first time is
                # not actually the deposits section.
                $self->{current_section}--;
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'deposits',
                        \@template);
        }
}

sub _process_epay {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payee',
                'category',
                'amount');

        if (!defined ($self->{epays})) {
                $self->{epays} = [];
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'epays',
                        \@template);
        }
}

sub _process_mdc {
        my $self = shift;
        my $text = shift;

        my @template = (
                'number',
                'date',
                'payee',
                'category',
                'amount');

        if (!defined ($self->{mdcs})) {
                $self->{mdcs} = [];
        }
        elsif ($text =~ /$self->{sections}->[$self->{current_section} - 1]->[0]/) {
                # Do nothing.
        }
        else {
                $self->_process_template (
                        $text,
                        'mdcs',
                        \@template);
        }
}

sub _process_template {
        my $self = shift;
        my $text = shift;
        my $key = shift;
        # Note: entries in this array must be spelled the same as
        # the given section's sub-headings (case insensitive).
        my $template = shift;

        my $current;
        my $stored_val = 0;

        if (grep /^$text$/i, @{$template}) {
                # This is the section sub-heading. Skip it.
        }
        else {
                $current = pop @{ $self->{$key} };

                if (!defined ($current)) {
                        $current = {};
                }

                foreach (@{$template}) {
                        if (!defined ($current->{$_})) {
                                $current->{$_} = $text;
                                $stored_val = 1;
                                last;
                        }
                }

                unless ($stored_val) {
                        # This entry is already full, we must create
                        # a new one.
                        push @{ $self->{$key} }, $current;
                        $current = {};
                        $current->{@{$template}[0]} = $text;
                }

                push @{ $self->{$key} }, $current;
        }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Finance::Huntington::Statement - Perl extension for parsing html bank
statements from the Huntington Bank website.

=head1 SYNOPSIS

  use Finance::Huntington::Statement;
  $obj = new Finance::Huntington::Statement;
  $obj->parse_file (<open file handle | path to file>);

  print $obj->{account_name};
  print $obj->{account_number};
  print $obj->{last_updated}; (a time value)
  print $obj->{current_statement_balance};
  print $obj->{available_statement_balance};
  print $obj->{current_register_balance};
  @atms = %{$obj->{atms}};
  foreach (@atms) {
          print $_->{number};
          print $_->{date};
          print $_->{payee};
          print $_->{category};
          print $_->{amount};
  }
  # The following arrays may be accessed in the same way as 'atms':
  # checks
  # debit_cards
  # epays
  # mdcs
  @deposits = %{$obj->{deposits}};
  foreach (@deposits) {
          print $_->{number};
          print $_->{date};
          print $_->{payor}; # NOTE: only diff from others
          print $_->{category};
          print $_->{amount};
  }

=head1 DESCRIPTION

This version of Statement will parse Huntington online bank
statements as of 09/2000.  If the statement format changes,
this gets broken.  Look for later versions of this module
for updates to correspond with current statements.

After parsing supplied html statement, $obj will hold a 
data structure representing the information extracted from
the page.

=head2 EXPORT

None by default.

=head1 AUTHOR

Chad Lavy, chad@chadlavy.com

=head1 SEE ALSO

perl(1).

=cut
