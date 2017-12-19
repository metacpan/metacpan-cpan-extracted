package Log::Any::Adapter::LinuxJournal 0.173471;

# ABSTRACT: Log::Any adapter for the systemd journal on Linux

use v5.12;
use warnings;

use Linux::Systemd::Journal::Write 1.172760;
use Log::Any::Adapter::Util 1.700;
use base 'Log::Any::Adapter::Base';

sub init {
    my $self = shift;
    $self->{jnl} = Linux::Systemd::Journal::Write->new(@_, caller_level => 2);
    return;
}

sub structured {
    my ($self, $level, $category, @args) = @_;

    my %details = (
        PRIORITY => $level,
        CATEGORY => $category,
    );

    my @msg;
    while (my $arg = shift @args) {

        # TODO journal can only usefully take k => v, flatten v
        if (!ref $arg) {
            push @msg, $arg;
        } elsif (ref $arg eq 'HASH') {
            @details{keys %{$arg}} = values %{$arg};
        } elsif (ref $arg eq 'ARRAY') {
            while (my ($k, $v) = (shift @{$arg}, shift @{$arg})) {
                $details{$k} = $v;
            }
        } else {
            push @msg, Log::Any::Adapter::Util::dump_one_line($arg);
        }
    }

    $self->{jnl}->send(join(' ', @msg), \%details);

    return;
}

# TODO optionally disable debug
for my $method (Log::Any::Adapter::Util::detection_methods()) {
    no strict 'refs';    ## no critic
    *$method = sub {1};
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Log::Any::Adapter::LinuxJournal - Log::Any adapter for the systemd journal on Linux

=head1 VERSION

version 0.173471

=head1 SYNOPSIS

  use Log::Any::Adapter;
  Log::Any::Adapter->set('LinuxJournal',
      # app_id => 'myscript', # default is basename($0)
  );

=head1 DESCRIPTION

B<WARNING> This is a L<Log::Any> adpater for I<structured> logging, which means it
is only useful with a very recent version of L<Log::Any>, at least C<1.700>

It will log messages to the systemd journal via L<Linux::Systemd::Journal::Write>.

=head1 SEE ALSO

L<Log::Any::Adapter::Journal>

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Log::Any::Adapter::LinuxJournal

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Log-Any-Adapter-LinuxJournal>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues>.
You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The source code is available for from the following locations:

L<https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal>

  git clone git://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal.git

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
