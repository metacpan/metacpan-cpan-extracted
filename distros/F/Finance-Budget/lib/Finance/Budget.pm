package Finance::Budget;

use strict;
use warnings;
our $VERSION = '0.05';
{   use Carp;
    use Text::CSV;
    use Date::Manip;
    use File::Slurp;
}

sub new
{
    my ( $class, $param_hr ) = @_;

    croak sprintf 'usage: %s->new(<hash ref>)', $class
        if ref $param_hr ne 'HASH';

    my %self = (
        days              => 365,
        currency_symbol   => '$',
        date_format       => '%m/%d/%Y',
        markup_callback   => sub { return $_[0]->{string} },
        opening_balance   => 0,
        transaction_types => [],
        exceptions        => [],
        recent_history    => [],
        categorizer       => {},
    );

    for my $opt (keys %{$param_hr})
    {
        croak sprintf '%s is not a recognized option among %s',
            $opt, ( join ',', keys %self )
            if not exists $self{$opt};

        my $type = ref $param_hr->{$opt};

        if ( !$type && stat $param_hr->{$opt} )
        {
            if ( $param_hr->{$opt} =~ m{ [.] csv \z}xmsi )
            {
                my @lines = File::Slurp::slurp( $param_hr->{$opt} );

                $param_hr->{$opt} = \@lines;
            }
            else
            {
                $param_hr->{$opt} = do $param_hr->{$opt};
            }

            $type = ref $param_hr->{$opt};

            if ( $type eq 'ARRAY' )
            {
                chomp @{ $param_hr->{$opt} };
            }
        }

        if ( ref $self{$opt} )
        {
            croak sprintf '%s should be of type %s ref',
                $opt, ( ref $self{$opt} )
                if $type ne ref $self{$opt};
        }
        elsif ( $self{$opt} =~ m{\A [%] }xms )
        {
            croak sprintf '%s should be a format string', $opt
                if $param_hr->{$opt} !~ m{ [%][a-z] }xmsi;
        }
        elsif ( $self{$opt} =~ m{\A \d }xms )
        {
            croak sprintf '%s should be a number', $opt
                if $param_hr->{$opt} !~ m{\A \d+ (?: [.] \d+ )? \z}xms;
        }

        $self{$opt} = $param_hr->{$opt};
    }

    croak 'there must be 1+ transaction types'
        if 0 == @{ $self{transaction_types} };

    croak 'there must be 1+ recent history for each transaction type'
        if @{ $self{recent_history} } < 1 + @{ $self{transaction_types} };

    croak 'there must be 1+ categorizer for each transaction type'
        if @{ $self{transaction_types} } > keys %{ $self{categorizer} };

    $self{opening_balance} *= 100; # dollars to cents

    _set_base_dates( \%self );

    _build_transactions( \%self );

    return bless \%self, $class;
}

sub get_last_occurences {
    my ($self) = @_;

    my %last_occurred;

    TYPE:
    for my $type_hr (@{ $self->{transaction_types} })
    {
        my $category   = $type_hr->{category};
        my $base_date  = $type_hr->{base_date};

        next TYPE
            if not $category;

        $last_occurred{$category} = $base_date->printf('%m/%d/%Y');
    }

    return \%last_occurred;
}

sub opening_balance
{
    my ($self) = @_;
    return _format_currency( $self->{opening_balance}, $self->{currency_symbol} );
}

sub next
{
    my ($self) = @_;

    return
        if not @{ $self->{transactions} };

    return shift @{ $self->{transactions} };
}

sub get_chokepoints
{
    my ($self) = @_;

    croak "no chokepoints encountered"
        if not exists $self->{chokepoints};

    return Finance::Budget::Chokepoints->new(
        {   chokepoints => $self->{chokepoints},
            markup      => $self->{markup_callback},
        }
    );
}

sub _set_base_dates
{
    my ($self) = @_;

    my %base_date_for
        = map { $_->{category} => 0 }
        grep { exists $_->{category} }
        @{ $self->{transaction_types} };

    if ( @{ $self->{recent_history} } > 1 )
    {
        my $csv = Text::CSV->new()
            || die sprintf "Text::CSV: %s\n",
                Text::CSV->error_diag();

        chomp @{ $self->{recent_history} };

        my @cols;
        {
            my ($header) = shift @{ $self->{recent_history} };

            $csv->parse(lc $header)
                || die sprintf "Text::CSV::parse %s\n",
                    Text::CSV->error_diag();

            @cols = $csv->fields();
        }

        croak "recent history CSV header must have a 'date' column"
            if 0 == grep { $_ eq 'date' } @cols;

        croak "recent history CSV header must have a 'description' column"
            if 0 == grep { $_ eq 'description' } @cols;

        my $categorize = sub {
            my ($event_hr) = @_;
            for my $category (keys %{ $self->{categorizer} })
            {
                my $categorizer = $self->{categorizer}->{$category};
                my $type = ref $categorizer;

                croak 'categorizer should be a %s or a %s',
                    'hash of array refs', 'hash of code refs'
                    if $type ne 'ARRAY' && $type ne 'CODE';

                if ( $type eq 'CODE' )
                {
                    return $category
                        if $categorizer->($event_hr);
                }
                else
                {
                    for my $regex (@{$categorizer})
                    {
                        return $category
                            if $event_hr->{description} =~ m/$regex/xmsi;
                    }
                }
            }
            return;
        };

        EVENT:
        for my $event_csv (@{ $self->{recent_history} })
        {
            $csv->parse($event_csv)
                || die sprintf "Text::CSV::parse %s\n",
                    Text::CSV->error_diag();

            my %event;
            @event{@cols} = $csv->fields();

            my $category = $categorize->( \%event )
                || next EVENT;

            next EVENT
                if ref $base_date_for{$category};

            my $date = Date::Manip::Date->new();

            my $err = $date->parse($event{date});

            die sprintf "Date::Manip::Date::parse %s -- %s\n",
                $event{date}, $err
                if $err;

            $base_date_for{$category} = $date;
        }
    }

    CAT:
    for my $category (keys %base_date_for)
    {
        croak sprintf 'failed to find base date for %s in recent history',
            $category
            if not ref $base_date_for{$category};

        for my $type_hr (@{ $self->{transaction_types} })
        {
            if ( $type_hr->{category} eq $category )
            {
                $type_hr->{base_date} = $base_date_for{$category};

                next CAT;
            }
        }
    }

    return;
}

sub _build_transactions {
    my ($self) = @_;

    my $width = 0;
    my $balance = $self->{opening_balance};
    my ( %events_for, @transactions, @chokepoints );

    my $start_date = ParseDate('today');
    my $end_date   = DateCalc('today', sprintf '+%dD', $self->{days});

    my ($major_income)
        = map { $_->{category} }
        sort  { $b->{amount} <=> $a->{amount} }
        @{ $self->{transaction_types} };

    my ($major_payment)
        = map { $_->{category} }
        sort  { $a->{amount} <=> $b->{amount} }
        @{ $self->{transaction_types} };

    my %amount_for;

    for my $except_hr (@{ $self->{exceptions} })
    {
        for my $field ( keys %{$except_hr} )
        {
            croak "exceptions must have: { date, category, amount }"
                if not exists $except_hr->{$field};
        }

        my $date = Date::Manip::Date->new();

        my $err = $date->parse($except_hr->{date});

        die sprintf "Date::Manip::Date::parse %s -- %s\n",
            $except_hr->{date}, $err
            if $err;

        my $category = lc $except_hr->{category};

        $amount_for{ $date->printf("$category:%s") } = $except_hr->{amount};
    }

    my $find_amount_cr = sub {
        my ( $category, $epoch, $default ) = @_;

        my $exception_key = lc "$category:$epoch";

        return $amount_for{$exception_key}
            if exists $amount_for{$exception_key};

        return $default;
    };

    my $type_help
        = "transaction_types must have { category, amount, recurrence }";

    my $major_payment_hit = 0;

    for my $type_hr (@{ $self->{transaction_types} })
    {
        my $category   = $type_hr->{category} || die "$type_help\n";
        my $amount     = $type_hr->{amount} // die "$type_help\n";
        my $recurrence = $type_hr->{recurrence} || die "$type_help\n";
        my $base_date  = $type_hr->{base_date};

        $width = $width < length $category ? length $category : $width;

        my $recur = Date::Manip::Recur->new();

        $recur->parse( $recurrence, $base_date, $start_date, $end_date );

        my @dates = $recur->dates();

        for my $date (@dates)
        {
            my $epoch = $date->printf('%s');

            $amount = $find_amount_cr->(
                $type_hr->{category},
                $epoch,
                $type_hr->{amount},
            );

            $events_for{$epoch} //= [];

            push @{ $events_for{$epoch} },
                {   category    => $type_hr->{category},
                    cents       => ( 100 * $amount ),
                    date        => $date,
                };
        }
    }

    for my $epoch (sort { $a <=> $b } keys %events_for)
    {
        my @events
            = sort { $b->{cents} <=> $a->{cents} } @{ $events_for{$epoch} };

        for my $event_hr (@events)
        {
            if ( $event_hr->{category} eq $major_income )
            {
                if ( $major_payment_hit )
                {
                    my $past_hr = $transactions[-1]->{event};

                    push @chokepoints,
                        {   date        => $past_hr->{date},
                            date_str    => $past_hr->{date_str},
                            cents       => $balance,
                            balance     => $balance,
                            balance_str => _format_currency(
                                $balance,
                                $self->{currency_symbol}
                            ),
                        };
                }

                $major_payment_hit = 0;
            }
            elsif ( $event_hr->{category} eq $major_payment )
            {
                $major_payment_hit = 1;
            }

            $balance += $event_hr->{cents};

            push @transactions,
                Finance::Budget::Transaction->new(
                    {   event           => $event_hr,
                        balance         => $balance,
                        width           => $width,
                        date_format     => $self->{date_format},
                        markup          => $self->{markup_callback},
                        currency_symbol => $self->{currency_symbol},
                    }
                );
        }
    }

    $self->{chokepoints}  = \@chokepoints;
    $self->{transactions} = \@transactions;

    return;
}

sub _format_currency {
    my ($cents, $currency) = @_;

    my $sign = $cents < 0 ? '-' : '';

    $cents = abs $cents;

    my ( $dollars, $pennies );

    if ( $cents < 99 )
    {
        $dollars = substr 0, 1, sprintf '0.%02d', $cents;
        $dollars ||= '0.00';
    }
    else
    {
        $dollars = sprintf '%.2f', ( $cents / 100 );
    }

    return sprintf '% 10s', "${sign}${currency}${dollars}";
}

package Finance::Budget::Transaction;

use strict;
use warnings;
use overload (
    q{""} => \&_stringify,
    q{<}  => \&_lt,
    q{==} => \&_eq,
    q{!=} => sub { !_eq( @_ ) },
    q{>}  => sub { !_eq( @_ ) && !_lt( @_ ) },
);

sub new {
    my ($class, $conf_hr) = @_;

    $conf_hr->{width} += 1;

    $conf_hr->{event}->{date_str}
        = $conf_hr->{event}->{date}->printf($conf_hr->{date_format});

    $conf_hr->{event}->{title}
        = sprintf "% $conf_hr->{width}s", $conf_hr->{event}->{category};

    $conf_hr->{event}->{amount} = Finance::Budget::_format_currency(
        $conf_hr->{event}->{cents},
        $conf_hr->{currency_symbol}
    );

    $conf_hr->{event}->{balance} = $conf_hr->{balance};

    $conf_hr->{event}->{balance_str} = Finance::Budget::_format_currency(
        $conf_hr->{balance},
        $conf_hr->{currency_symbol}
    );

    $conf_hr->{event}->{string} = join ' ',
        @{ $conf_hr->{event} }{qw( date_str title amount balance_str )};

    return bless $conf_hr, $class;
}

sub get_date {
    my ($self) = @_;
    return $self->{event}->{date_str};
}

sub get_category {
    my ($self) = @_;
    return $self->{event}->{category};
}

sub get_amount {
    my ($self) = @_;
    return $self->{event}->{amount};
}

sub get_balance {
    my ($self) = @_;
    return $self->{balance_str};
}

sub _stringify {
    my ($self) = @_;

    return $self->{markup}->( $self->{event} )
        if $self->{markup};

    return $self->{event}->{string};
}

sub _lt {
    my ($self, $arg) = @_;
    return $self->{event}->{cents} < $arg;
}

sub _eq {
    my ($self, $arg) = @_;
    return $self->{event}->{cents} == $arg;
}


package Finance::Budget::Chokepoints;

use strict;
use warnings;
use Carp;

sub new
{
    my ($class, $param_hr) = @_;

    die "$class requires 'chokepoints' parameter"
        if not exists $param_hr->{chokepoints};

    return bless $param_hr, $class;
}

sub eye
{
    my ($self) = @_;

    croak 'no chokepoints encountered'
        if not @{ $self->{chokepoints} };

    my ($eye_hr)
        = sort { $a->{cents} <=> $b->{cents} } @{ $self->{chokepoints} };

    return Finance::Budget::Chokepoint->new(
        {   point  => $eye_hr,
            markup => $self->{markup},
        }
    );
}

sub next
{
    my ($self) = @_;

    return
        if not @{ $self->{chokepoints} };

    my $point_hr = shift @{ $self->{chokepoints} };

    return Finance::Budget::Chokepoint->new(
        {   point  => $point_hr,
            markup => $self->{markup},
        }
    );
}

package Finance::Budget::Chokepoint;

use strict;
use warnings;
use overload (
    q{""} => \&_stringify,
    q{<}  => \&_lt,
    q{==} => \&_eq,
    q{!=} => sub { !_eq( @_ ) },
    q{>}  => sub { !_eq( @_ ) && !_lt( @_ ) },
);

sub new
{
    my ( $class, $param_hr ) = @_;
    $param_hr->{point}->{string}
        = sprintf '%s %s', @{ $param_hr->{point} }{qw( date_str balance_str)};
    return bless $param_hr, $class;
}

sub _stringify
{
    my ($self) = @_;
    return $self->{markup}->( $self->{point} );
}

sub _lt {
    my ($self, $arg) = @_;
    return $self->{point}->{cents} < $arg;
}

sub _eq {
    my ($self, $arg) = @_;
    return $self->{point}->{cents} == $arg;
}


1;

__END__

=head1 NAME

Finance::Budget - A module for helping you predict the effectiveness of your
budget.

=head1 SYNOPSIS

  use Finance::Budget;

  my $budget = Finance::Budget->new(
      {   days              => 365,
          opening_balance   => 123.01,
          transaction_types => [
              {   category   => 'PAYCHECK',
                  amount     => 1234.56,
                  recurrence => '0:0:2*4:0:0:0', # every second Thursday
              },
              {   category   => 'Visa',
                  amount     => -100.00,
                  recurrence => '0:1*0:0:0:0:0', # first of every month
              },
              {   category   => 'Cox',
                  amount     => -101.01,
                  recurrence => '0:1*0:15:0:0:0', # fifteenth of every month
              },
              {   category   => 'Mortgage',
                  amount     => -1000.10,
                  recurrence => '0:1*0:0:0:0:0',
              },
              {   category   => 'Water',
                  amount     => -150.00,
                  recurrence => '0:3*0:1:0:0:0', # first of every third month
              },
          ],
          exceptions => [
              {   category => 'Visa',
                  amount   => 0.00,
                  date     => '12/20/2016',
              },
              {   category => 'Cox',
                  amount   => 0.00,
                  date     => '01/01/2017',
              },
              {   category => 'Mortgage',
                  amount   => 0.00,
                  date     => '01/01/2017',
              },
          ],
          recent_history => [
              qq{"Date","No.","Description","Debit","Credit"},
              qq{"12/28/2016","","ACH Trans - Big Plastic","100.00",""},
              qq{"12/27/2016","","ACH Trans - COX CABLE","101.01",""},
              qq{"12/26/2016","","ACH Trans - US BANK MTG","1000.10",""},
              qq{"12/01/2016","","ACH Trans - Waters R Us","150.00",""},
              qq{"12/22/2016","","Deposit - Employer Inc","","1234.56"},
          ],
          categorizer => {
              'PAYCHECK' => [
                  qr{ employer \s inc }xmsi
              ],
              'Visa' => [
                  qr{ big \s plastic }xmsi
              ],
              'Cox' => [
                  qr{ cox \s cable }xmsi,
                  qr{ cox \s communications }xmsi,
              ],
              'Mortgage' => [
                  qr{ us \s bank \s mtg }xmsi
              ],
              'Water' => [
                  qr{ waters \s r \s us }xmsi
              ]
          }
      }
  );

  printf "Opening Balance: % 25s\n",
      $budget->opening_balance();

  while ( my $transaction = $budget->next() )
  {
      print "$transaction\n"
        if $transaction != 0;
  }

  my $chokepoints = $budget->get_chokepoints();

  printf "\nEye of the needle:\n%s\n\n",
      $chokepoints->eye();

  printf "Chokepoints:\n";

  while ( my $point = $chokepoints->next() )
  {
      die "negative chokepoint: $point\n"
          if $point < 0;

      print "$point\n";
  }


=head1 DESCRIPTION

This module consumes information about your budget planning and then creates
a series of transactions to project what lays ahead.

This can be useful when
considering taking on a new car payment or making a big purchase. For example,
spending $300 today might have unexpected ramifications 90 days from now. This
can also be handy in fine tuning your budget to ensure that it is sustainable.

Check out budget.pl in the demo directory of this project.

=head1 CONSTRUCTOR

=head2 PARAMETERS

=over

=item days

The number of days to project into the future. The default is 365.

=item date_format

The format that the transactions will use on stringafication.
The default is '%m/%d/%Y'.

=item currency_symbol

Set any string as a currency symbol. The default is '$'.

=item markup_callback

This is a code reference that gets invoked for each transaction
stringafication event. You can use this to format the output any way you like.

The callback receives as the first argument a hash ref like:

  {   date_str    => '...',
      title       => '...',
      amount      => '$...',
      balance_str => '...',
      string      => '...',
      date        => <Date::Manip::Date object>,
      category    => '...',
      cents       => 0,
  }

The callback retuns a formatted string. The default just returns the 'string'
value.

=item opening_balance

The opening blanace, in dollars, of your checking account. The default is 0.

=item transaction_types

This is a list of transaction type descriptor hashes. Each descriptor has
three attributes:

  {   category   => 'Foobar',        # category name
      amount     => -1.00,           # dollar amount -/+
      recurrence => '0:1*0:0:0:0:0', # Date::Manip::Recur string
  }

This field also accepts a data filename which will be read using the Perl do()
function.

=item exceptions

Use this to define one-off exceptions. For example, your electric utilty bill
might generally be $100.00. But you happen to know the next payment will be
exactly $87.42.

So, you can define an exception:

  {   category => 'Electric',
      amount   => -87.42,
      date     => '02/01/2017',  # parsable by Date::Manip::Date
  }

This field also accepts a data filename which will be read using the Perl do()
function.

=item recent_history

This is a list of CSV lines that are scanned for the most recent occurrence
date for each transaction type. These dates are important because they are the
'base date' for each recurring transaction. (See Date::Manip::Recur)

Each CSV line is expected to have a 'date' and a 'description' field as given
by the first CSV line. This happens to be exactly what my financial
institution provides when I download a CSV file from my online banking site.

This field also accepts a CSV filename which will be slurped into memory.

=item categorizer

This option accepts a hash of category names mapped to one of two things:

=over

=item 1

An array ref of regexes. Each regex will be applied to the 'description' in
the recent history data. When a match is made that category is applied.

=item 2

A code ref for a function that returns true if the 'description' applies to
this category.

=back

=back

=head1 METHODS

=head2 opening_balance()

Returns a stringified version of the opening balance (supplied in the
constructor).

=head2 next()

Get the next transaction.

=head2 get_chokepoints()

Returns a chokepoint iterator.

=head2 get_last_occurences()

Returns a hash ref mapping of categories and the last time each one
occurred as parsed from the recent history.

This might be helpful for debugging your categorizers.


=head1 TRANSACTIONS

Each transaction represents one event in your budget lifespan.

You'll probably just be satisified to print each "$transaction" in its
stringified form, which uses the markup callback you provide.

The transaction object also offers some getter methods.

=over

=item get_date()

=item get_category()

=item get_amount()

=item get_balance()

=back

The transaction objects can be interpolated into strings and they can be used
in numeric comparisons.

  print "$transaction\n"
      if $transaction != 0;


=head1 CHOKEPOINTS

The chokepoints are the balance minima between the significant expenses and
the significant income events. You might be interested in iterating through
these to see where you're going to run into trouble.

The chokepoint objects can be interpolated into strings and they can be used
in numeric comparisons.

  die "negative chokepoint: $point\n"
      if $point < 0;

=head2 eye()

This is the "eye" as in threading the needle -- the smallest of the
chokepoints.

=head2 next()

Get the next chokepoint.


=head1 SEE ALSO

  Date::Manip::Recur
  Text::CSV

=head1 AUTHOR

Dylan Doxey, E<lt>dylan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Dylan Doxey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
