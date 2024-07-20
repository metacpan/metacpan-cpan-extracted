package Devel::StatProfiler::SectionChangeReader;

use strict;
use warnings;

use Devel::StatProfiler::Reader;

sub new {
    my ($class, $reader) = @_;

    return bless {
        reader           => $reader,
        traces           => [],
        sections_changed => 0,
    }, $class;
}

sub read_traces {
    my ($self) = @_;
    my ($r, $traces) = @{$self}{qw(reader traces)};

    $self->{sections_changed} = 0;
    while (my $trace = $r->read_trace) {
        push @$traces, $trace;
        if ($trace->sections_changed) {
            $self->{sections_changed} = 1;
            return 1;
        }
    }

    return @$traces ? 1 : 0;
}

sub sections_changed { $_[0]->{sections_changed} }
sub empty { !@{$_[0]->{traces}} }

# Devel::StatProfiler::Reader methods

sub get_source_tick_duration { $_[0]->{reader}->get_source_tick_duration }
sub get_source_stack_sample_depth { $_[0]->{reader}->get_source_stack_sample_depth }
sub get_source_perl_version { $_[0]->{reader}->get_source_perl_version }
sub get_genealogy_info { $_[0]->{reader}->get_genealogy_info }
sub get_active_sections { $_[0]->{reader}->get_active_sections }
sub get_custom_metadata { $_[0]->{reader}->get_custom_metadata }
sub clear_custom_metadata { $_[0]->{reader}->clear_custom_metadata }
sub delete_custom_metadata { $_[0]->{reader}->delete_custom_metadata($_[1]) }
sub get_source_code { $_[0]->{reader}->get_source_code }

sub read_trace {
    return @{$_[0]->{traces}} ? shift @{$_[0]->{traces}} : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::StatProfiler::SectionChangeReader

=head1 VERSION

version 0.53

=head1 AUTHORS

=over 4

=item *

Mattia Barbon <mattia@barbon.org>

=item *

Steffen Mueller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mattia Barbon, Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
