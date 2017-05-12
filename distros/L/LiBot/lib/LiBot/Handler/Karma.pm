package LiBot::Handler::Karma;
use strict;
use warnings;
use utf8;
use DB_File;

use Mouse;

has path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has dict => (
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        tie my %karma_dict, 'DB_File', $self->path;
        \%karma_dict;
    },
);

no Mouse;

sub init {
    my ($self, $bot) = @_;

    print "Registering karma bot\n";
    $bot->register(
        qr/(\w+)(\+\+|--)/ => sub {
            my ($cb, $event, $name, $op) = @_;

            print "Processing karma\n";
            $self->dict->{$name} += 1 if $op eq '++';
            $self->dict->{$name} -= 1 if $op eq '--';
            $cb->(sprintf("$name: %s", $self->dict->{$name}));
        }
    );
}

1;
__END__

=head1 NAME

LiBot::Handler::Karma - Karma bot

=head1 SYNOPSIS

    # config.pl
    +{
        'handlers' => [
            'Karma' => {
                path => 'path/to/database.db',
            }
        ]
    }

    # script
    <hsegawa> gfx--
    >bot< gfx: -1

=head1 DESCRIPTION

This is a karma bot.

=head1 CONFIGURATION

=over 4

=item path

Path to database file. Required.

=back

=head1 DEPENDENCIES

L<DB_File>

