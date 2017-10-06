package Log::Any::Adapter::LinuxJournal 0.172762;

# ABSTRACT: Log::Any adapter for the systemd journal on Linux

use v5.12;
use warnings;

use Linux::Systemd::Journal::Write 1.172760;
use Log::Any::Adapter::Util '1.700';
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

=for :stopwords Ioan Rogers

=head1 NAME

Log::Any::Adapter::LinuxJournal - Log::Any adapter for the systemd journal on Linux

=head1 VERSION

version 0.172762

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

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Log::Any::Adapter::LinuxJournal/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal>
and may be cloned from L<git://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
