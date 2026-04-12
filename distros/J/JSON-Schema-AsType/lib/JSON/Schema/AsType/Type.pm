package JSON::Schema::AsType::Type;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Type::VERSION = '1.0.0';
# ABSTRACT: JSON::Schema::AsType role providing all Type::Tiny methods


use 5.42.0;
use warnings;

use feature 'signatures', 'module_true';

use Types::Standard qw/ Any /;
use List::Util      qw/ reduce /;
use Type::Tiny;

use Moose::Role;
use MooseX::MungeHas 'is_ro';

use JSON::Schema::AsType::Annotations;

has type => (
    is      => 'rwp',
    handles => [qw/ check validate validate_explain /],
    builder => 1,
    lazy    => 1
);

has base_type => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub validate_schema {
    my $self = shift;
    $self->metaschema->validate( $self->schema );
}

sub validate_explain_schema {
    my $self = shift;
    $self->metaschema->validate_explain( $self->schema );
}

sub _build_base_type {
    my $self = shift;

    return $self->schema ? Any : ~Any
      if JSON::is_bool( $self->schema );

    my @types =
      grep { $_ and $_->name ne 'Any' }
      map { $self->_process_keyword($_) } $self->all_active_keywords;

    return Type::Tiny->new(
        display_name => $self->uri,
        parent       => @types ? reduce { $a & $b } @types : Any,
    );
}

my $Scope = Type::Tiny->new(
    name                 => 'Scope',
    constraint_generator => sub {
        my $type = shift;
        return sub {
            annotation_scope(
                sub {
                    $type->check($_);
                }
            );
        }
    },
    deep_explanation => sub( $type, $value, $varname ) {
        my @whines;
        my $inner = $type->parameters->[0];
        push @whines, sprintf "%s was %s, and failed %s: %s",
          $varname, $value, $inner->name, join "\n",
          $inner->validate_explain($value)->@*;
        return \@whines;
    }
);

sub _build_type($self) {
    return $Scope->of( $self->base_type );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Type - JSON::Schema::AsType role providing all Type::Tiny methods

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

    use DDP;
    say "\t" x $JSON::Schema::AsType::Type::INDENT, "checking ", $self->uri;
    say "\t" x $JSON::Schema::AsType::Type::INDENT, $self->type->display_name;
    say "\t" x $JSON::Schema::AsType::Type::INDENT, "value ", np $value;

    local $JSON::Schema::AsType::Type::INDENT = $JSON::Schema::AsType::Type::INDENT + 1;
    my $verdict = $orig->($self,$value);


    say "\t" x --$JSON::Schema::AsType::Type::INDENT, "verdict: $verdict";

    return $verdict;

};

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
