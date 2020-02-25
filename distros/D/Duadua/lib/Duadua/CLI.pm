package Duadua::CLI;
use strict;
use warnings;
use Duadua;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON qw/encode_json/;

sub new {
    my $class = shift;

    return bless {
        _d   => Duadua->new('', { version => 1 }),
        _opt => $class->_get_opt(@_),
    }, $class;
}

sub d { shift->{_d} }

sub opt { $_[0]->{_opt}{$_[1]} }

sub run {
    my ($self) = @_;

    my @results;

    if (my $ua_list = $self->opt('ua_list')) {
        for my $ua (@{$ua_list}) {
            push @results, $self->_parse($ua);
        }
    }

    if ($self->_is_opened_stdin) {
        while (my $ua = <STDIN>) {
            chomp $ua;
            push @results, $self->_parse($ua);
        }
    }

    if (scalar @results == 0) {
        _show_usage(1);
    }
    else {
        print encode_json(scalar @results == 1 ? $results[0] : \@results);
    }
}

sub _is_opened_stdin { -p STDIN }

sub _parse {
    my ($self, $ua) = @_;

    $ua =~ s!^"!!g;
    $ua =~ s!"$!!g;

    my $r = $self->d->reparse($ua);

    my $v = {
        ua      => $r->ua,
        name    => $r->name,
        version => $r->version || '-',
    };

    for my $k (qw/
        is_bot
        is_ios
        is_android
        is_linux
        is_windows
        is_chromeos
    /) {
        $v->{$k} = $r->$k || 0;
    }

    return $v;
}

sub _get_opt {
    my ($class, @argv) = @_;

    my $opt = {};

    GetOptionsFromArray(
        \@argv,
        'help'    => sub {
            $class->_show_usage(1);
        },
        'version' => sub {
            print "$0 $Duadua::VERSION\n";
            exit 1;
        },
    );

    if (scalar @argv > 0) {
        push @{$opt->{ua_list}}, @argv;
    }

    return $opt;
}

sub _show_usage {
    my ($class, $exitval) = @_;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Duadua::CLI - CLI runner of Duadua


=head1 METHODS

=head2 new(@ARGV)

=head2 d()

=head2 opt()

=head2 run()


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
