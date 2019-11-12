#!/usr/bin/perl
use warnings;
use strict;

# ABSTRACT: A simple hourly rate calculator
# PODNAME: hourly_rate.pl

use Getopt::Long;
use Pod::Usage;
use Config::Any;
use File::Spec::Functions qw(catfile);
use Finance::Salary::Rate;

my %opts = (
    help      => 0,
    config    => catfile($ENV{HOME}, qw (.config finance-salary rate.conf)),
);

{
    local $SIG{__WARN__};
    my $ok = eval {
        GetOptions(
            \%opts, qw(
                help
                income=s
                vacation=s
                taxes=s
                healthcare=s
                declarable=s
                days=i
                expenses=s
                config=s
                )
        );
    };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});


if (-f $opts{config}) {
    my $config = Config::Any->load_files({
            files => [$opts{config}],
            use_ext => 1,
            flatten_hash => 1,

        })->[0]{$opts{config}};

    foreach (keys %opts) {
        delete $config->{$_};
    }

    foreach (keys %$config) {
        # If an option is set multiple times in the config file, take
        # the last value and work with that
        $opts{$_} ||= ref $config->{$_} eq 'ARRAY'
            ? $config->{$_}[-1]
            : $config->{$_};
    }
}

my @required = qw(income);
my @optional = qw(vacation taxes healthcare declarable days expenses);
my $nok = 0;

foreach (@required) {
    if (!exists $opts{$_} || $opts{$_} <= 0) {
        $nok++;
    }
}

foreach (@optional) {
    if (exists $opts{$_} && $opts{$_} < 0) {
        $nok++;
    }
}

pod2usage(1) if $nok;

my %mapping = (
    income     => 'monthly_income',
    vacation   => 'vacaction_perc',
    taxes      => 'tax_perc',
    healthcare => 'healthcare_perc',
    declarable => 'declarable_days_perc',
    days       => 'working_days',
    expenses   => 'expenses',
);

my %args =  map { $mapping{$_} => $opts{$_} } grep { $opts{$_} } keys %mapping;

my $rate = Finance::Salary::Rate->new(%args);
printf ("%0.2f\n", $rate->hourly_rate);

__END__

=pod

=encoding UTF-8

=head1 NAME

hourly_rate.pl - A simple hourly rate calculator

=head1 VERSION

version 0.001

=head1 SYNOPSIS

hourly_rate.pl --income 2000 OPTIONS

=head1 OPTIONS

=over

=item days

The amount of working days

=item declarable

The percentage of declarable days

=item vacation

The percentage of vacation days

=item taxes

The percentage of taxes which needs to be paid to the government

=item healthcare

The percentage of healthcare fees

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
