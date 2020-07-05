package Markdent::Parser;

use strict;
use warnings;
use namespace::autoclean 0.09;

our $VERSION = '0.37';

use Markdent::Parser::BlockParser;
use Markdent::Parser::SpanParser;
use Markdent::Types;
use Module::Runtime qw( require_module );
use Moose::Meta::Class;
use Params::ValidationCompiler 0.14 qw( validation_for );
use Specio::Declare;
use Try::Tiny;

use Moose 0.92;
use MooseX::SemiAffordanceAccessor 0.05;
use MooseX::StrictConstructor 0.08;

with 'Markdent::Role::AnyParser';

has _block_parser_class => (
    is       => 'rw',
    isa      => t('BlockParserClass'),
    init_arg => 'block_parser_class',
    default  => 'Markdent::Parser::BlockParser',
);

has _block_parser => (
    is       => 'rw',
    does     => object_does_type('Markdent::Role::BlockParser'),
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_block_parser',
);

has _block_parser_args => (
    is       => 'rw',
    isa      => t('HashRef'),
    init_arg => undef,
);

has _span_parser_class => (
    is       => 'rw',
    isa      => t('SpanParserClass'),
    init_arg => 'span_parser_class',
    default  => 'Markdent::Parser::SpanParser',
);

has _span_parser => (
    is       => 'ro',
    does     => object_does_type('Markdent::Role::SpanParser'),
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_span_parser',
);

has _span_parser_args => (
    is       => 'rw',
    isa      => t('HashRef'),
    init_arg => undef,
);

override BUILDARGS => sub {
    my $class = shift;

    my $args = super();

    if ( exists $args->{dialect} ) {

        # XXX - deprecation warning
        $args->{dialects} = [ delete $args->{dialect} ];
    }
    elsif ( exists $args->{dialects} ) {
        $args->{dialects} = [ $args->{dialects} ]
            unless ref $args->{dialects};
    }

    return $args;
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    $self->_set_classes_for_dialects($args);

    my %sp_args;
    for my $key (
        grep {defined}
        map  { $_->init_arg() }
        $self->_span_parser_class()->meta()->get_all_attributes()
    ) {

        $sp_args{$key} = $args->{$key}
            if exists $args->{$key};
    }

    $sp_args{handler} = $self->handler();

    $self->_set_span_parser_args( \%sp_args );

    my %bp_args;
    for my $key (
        grep {defined}
        map  { $_->init_arg() }
        $self->_block_parser_class()->meta()->get_all_attributes()
    ) {

        $bp_args{$key} = $args->{$key}
            if exists $args->{$key};
    }

    $bp_args{handler}     = $self->handler();
    $bp_args{span_parser} = $self->_span_parser();

    $self->_set_block_parser_args( \%bp_args );
}

sub _set_classes_for_dialects {
    my $self = shift;
    my $args = shift;

    my $dialects = delete $args->{dialects};

    return unless @{ $dialects || [] };

    for my $thing (qw( block_parser span_parser )) {
        my @roles;

        for my $dialect ( @{$dialects} ) {
            next if $dialect eq 'Standard';

            my $role = $self->_role_name_for_dialect( $dialect, $thing );

            my $found = try {
                require_module($role);
            }
            catch {
                die $_ unless $_ =~ /Can't locate/;
                0;
            };
            next unless $found;

            my $specified_class = $args->{ $thing . '_class' };

            next
                if $specified_class
                && $specified_class->can('meta')
                && $specified_class->meta()->does_role($role);

            push @roles, $role;
        }

        next unless @roles;

        my $class_meth = q{_} . $thing . '_class';

        my $class = Moose::Meta::Class->create_anon_class(
            superclasses => [ $self->$class_meth() ],
            roles        => \@roles,
            cache        => 1,
        )->name();

        my $set_meth = '_set' . $class_meth;
        $self->$set_meth($class);
    }
}

sub _role_name_for_dialect {
    my $self    = shift;
    my $dialect = shift;
    my $type    = shift;

    my $suffix = join q{}, map {ucfirst} split /_/, $type;

    if ( $dialect =~ /::/ ) {
        return join '::', $dialect, $suffix;
    }
    else {
        return join '::', 'Markdent::Dialect', $dialect, $suffix;
    }
}

sub _build_block_parser {
    my $self = shift;

    return $self->_block_parser_class()->new( $self->_block_parser_args() );
}

sub _build_span_parser {
    my $self = shift;

    return $self->_span_parser_class()->new( $self->_span_parser_args() );
}

{
    my $validator = validation_for(
        params        => [ markdown => { type => t('Str') } ],
        named_to_list => 1,
    );

    sub parse {
        my $self = shift;
        my ($text) = $validator->(@_);

        $self->_clean_text( \$text );

        $self->_send_event('StartDocument');

        $self->_block_parser()->parse_document( \$text );

        $self->_send_event('EndDocument');

        return;
    }
}

sub _clean_text {
    my $self = shift;
    my $text = shift;

    ${$text} =~ s/\r\n?/\n/g;
    ${$text} .= "\n"
        unless substr( ${$text}, -1, 1 ) eq "\n";

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A markdown parser

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Parser - A markdown parser

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  my $handler = Markdent::Handler::HTMLStream->new( ... );

  my $parser = Markdent::Parser->new(
      dialect => ...,
      handler => $handler,
  );

  $parser->parse( markdown => $markdown );

=head1 DESCRIPTION

This class provides the primary interface for creating a parser. It ties a
block and span parser together with a handler.

By default, it will parse the standard Markdown dialect, but you can provide
alternate block or span parser classes.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Parser->new(...)

This method creates a new parser. It accepts the following parameters:

=over 4

=item * dialects => $name or [ $name1, $name2 ]

You can use this to apply dialect roles to the standard parser class.

If a dialect name does not contain a namespace separator (::), the constructor
looks for roles named C<Markdent::Dialect::${dialect}::BlockParser> and
C<Markdent::Dialect::${dialect}::SpanParser>.

If a dialect name does contain a namespace separator, it is used a prefix -
C<$dialect::BlockParser> and C<$dialect::SpanParser>.

If any relevant roles are found, they will be used by the parser.

It is okay if a given dialect only provides a block or span parser, but not
both.

=item * block_parser_class => $class

This defaults to L<Markdent::Parser::BlockParser>, but can be any class which
implements the L<Markdent::Role::BlockParser> role.

=item * span_parser_class => $class

This defaults to L<Markdent::Parser::SpanParser>, but can be any class which
implements the L<Markdent::Role::SpanParser> role.

=item * handler => $handler

This can be any object which implements the L<Markdent::Role::Handler>
role. It is required.

=back

=head2 $parser->parse( markdown => $markdown )

This method parses the given document. The parsing will cause events to be
fired which will be passed to the parser's handler.

=head1 ROLES

This class does the L<Markdent::Role::EventsAsMethods> and
L<Markdent::Role::Handler> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
