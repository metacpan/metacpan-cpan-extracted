package Lingua::RU::OpenCorpora::Tokenizer::Updater;

use strict;
use warnings;

use LWP::UserAgent;
use Carp qw(croak);
use Lingua::RU::OpenCorpora::Tokenizer::List;
use Lingua::RU::OpenCorpora::Tokenizer::Vectors;

our $VERSION = 0.06;

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;

    $self->_init;

    $self;
}

sub vectors_update_available    { $_[0]->_update_available('vectors', $_[1])    }
sub hyphens_update_available    { $_[0]->_update_available('hyphens', $_[1])    }
sub exceptions_update_available { $_[0]->_update_available('exceptions', $_[1]) }
sub prefixes_update_available   { $_[0]->_update_available('prefixes', $_[1])   }

sub update_vectors    { $_[0]->_update('vectors')    }
sub update_hyphens    { $_[0]->_update('hyphens')    }
sub update_exceptions { $_[0]->_update('exceptions') }
sub update_prefixes   { $_[0]->_update('prefixes')   }

sub _init {
    my $self = shift;

    my $ua = LWP::UserAgent->new(
        agent     => __PACKAGE__ . ' ' . $VERSION . ', ',
        env_proxy => 1,
    );
    $self->{ua} = $ua;

    for(qw(exceptions prefixes hyphens)) {
        $self->{$_} = Lingua::RU::OpenCorpora::Tokenizer::List->new($_);
    }
    $self->{vectors} = Lingua::RU::OpenCorpora::Tokenizer::Vectors->new;

    return;
}

sub _update_available {
    my($self, $mode, $force) = @_;

    my $url = $self->{$mode}->_url('version');
    my $res = $self->{ua}->get($url);
    croak "$url: " . $res->code unless $res->is_success;

    chomp(my $latest = $res->content);
    my $current = $self->{$mode}->{version};

    $self->{"${mode}_latest"}  = $latest;
    $self->{"${mode}_current"} = $current;

    return $force
        ? 1
        : $latest > $current;
}

sub _update {
    my($self, $mode) = @_;

    my $url = $self->{$mode}->_url('file');
    my $res = $self->{ua}->get($url);
    croak "$url: " . $res->code unless $res->is_success;

    $self->{$mode}->_update($res->content);
}

1;

__END__

=head1 NAME

Lingua::RU::OpenCorpora::Tokenizer::Updater - download newer data for tokenizer

=head1 DESCRIPTION

This module is not supposed to be used directly. Instead use C<opencorpora-update-tokenizer> script that comes with this distribution.

=head1 SEE ALSO

L<Lingua::RU::OpenCorpora::Tokenizer>

L<Lingua::RU::OpenCorpora::Tokenizer::List>

L<Lingua::RU::OpenCorpora::Tokenizer::Vectors>

=head1 AUTHOR

OpenCorpora team L<http://opencorpora.org>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
