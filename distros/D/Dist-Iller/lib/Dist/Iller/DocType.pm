use 5.14.0;
use strict;
use warnings;

package Dist::Iller::DocType;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Role for document types that can be used in Dist::Iller configs
our $VERSION = '0.1411';

use Moose::Role;
use MooseX::AttributeShortcuts;
use namespace::autoclean;
use Try::Tiny;
use Text::Diff;
use Types::Standard qw/ConsumerOf Str HashRef InstanceOf Maybe/;
use Module::Load qw/load/;
use String::CamelCase qw/decamelize/;
use YAML::Tiny;
use Carp qw/croak/;
use DateTime;
use Path::Tiny;
use Safe::Isa qw/$_can/;
use Types::Path::Tiny qw/Path/;
use PerlX::Maybe qw/maybe/;

requires qw/
    filename
    parse
    phase
    to_hash
    to_string
    comment_start
/;

# this is set if we are parsing a ::Config class
has config_obj => (
    is => 'ro',
    isa => ConsumerOf['Dist::Iller::Config'],
    predicate =>1,
);
has doctype => (
    is => 'ro',
    isa => Str,
    init_arg => undef,
    default => sub { decamelize( (split /::/, shift->meta->name)[-1] ); },
);
has included_configs => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    traits => ['Hash'],
    default => sub { +{ } },
    handles => {
        set_included_config => 'set',
        all_included_configs => 'kv',
        has_included_configs => 'count',
    },
);
has global => (
    is => 'ro',
    isa => Maybe[InstanceOf['Dist::Iller::DocType::Global']],
    predicate => 1,
);

around parse => sub {
    my $next = shift;
    my $self = shift;
    my $yaml = shift;

    $self->parse_config($yaml->{'configs'});
    $self->$next($yaml);

    return $self;
};
sub parse_config {
    my $self = shift;
    my $yaml = shift;

    return if !defined $yaml;

    if(ref $yaml eq 'ARRAY') {
        warn 'Multiple configs found';
        for my $doc (@{ $yaml }) {
            $self->parse_config($doc);
        }
    }
    else {
        my $config_name = delete $yaml->{'+config'};
        my $config_class = "Dist::Iller::Config::$config_name";

        try {
            load "$config_class";
        }
        catch {
            croak "Can't find $config_class ($_)";
        };

        my $configobj = $config_class->new(
            %{ $yaml },
            maybe distribution_name => ($self->$_can('name') ? $self->name : undef),
            maybe global => ($self->global ? $self->global : undef),
        );
        my $configdoc = $configobj->get_yaml_for($self->doctype);
        return if !defined $configdoc;

        $self->parse($configdoc);
        $self->set_included_config($config_class, $config_class->VERSION);
    }
}

sub to_yaml { YAML::Tiny->new(shift->to_hash)->[0] }

around to_string => sub {
    my $next = shift;
    my $self = shift;

    my $string = $self->$next(@_);
    return $string if !defined $self->comment_start;

    my $now = DateTime->now;

    my @intro = ();
    push @intro => $self->comment_start . sprintf (' This file was auto-generated from iller.yaml by Dist::Iller on %s %s %s.', $now->ymd, $now->hms, $now->time_zone->name);
    if($self->has_included_configs) {
        push @intro => $self->comment_start . ' The following configs were used:';

        for my $config (sort { $a->[0] cmp $b->[0] } $self->all_included_configs) {
            push @intro => $self->comment_start . qq{ * $config->[0]: $config->[1]};
        }
    }
    push @intro => ('', '');

    return join ("\n", @intro) . $string;

};

sub generate_file {
    my $self = shift;

    return if !$self->filename; # for doctype:global

    my $path = Path->check($self->filename) ? $self->filename : Path->coerce($self->filename);

    my $new_document = $self->to_string;
    my $previous_document = $path->exists ? $path->slurp_utf8 : undef;

    if(!defined $previous_document) {
        $path->spew_utf8($new_document);
        say "[Iller] Creates $path";
        return;
    }

    my $comment_start = $self->comment_start;
    my $diff = diff \$previous_document, \$new_document, { STYLE => 'Unified' };
    my $diff_count = 0;
    my $skip_first = 1;
    for my $row (split m{\r?\n}, $diff) {
        next if $skip_first-- == 1;
        next if $row =~ m{^ };
        if($row =~ m{; authordep }) {
            ++$diff_count;
            next;
        }
        next if $row =~ m{^[-+]\s*?$comment_start};
        next if $row =~ m{^[-+]\s*$};
        ++$diff_count;
    }

    if($diff_count) {
        $path->spew_utf8($new_document);
        say "[Iller] Generates $path";
    }
    else {
        say "[Iller] No changes for $path";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::DocType - Role for document types that can be used in Dist::Iller configs

=head1 VERSION

Version 0.1411, released 2020-01-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
