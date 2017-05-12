package Dist::Zilla::App::Command::weaverconf; # git description: v0.04-1-ga3e3502
# ABSTRACT: Extract your distribution's Pod::Weaver configuration
$Dist::Zilla::App::Command::weaverconf::VERSION = '0.05';
use Dist::Zilla::App -command;
use Moose 0.91;
use JSON::MaybeXS ();
use List::Util qw(first);
use MooseX::Types::Moose qw(Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map);
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod     $ dzil weaverconf
#pod     {
#pod         "collectors" : [
#pod             { "command" : "attr",   "new_command" : "head2" },
#pod             { "command" : "method", "new_command" : "head2" },
#pod             { "command" : "func",   "new_command" : "head2" },
#pod             { "command" : "type",   "new_command" : "head2" }
#pod         ],
#pod         "transformers" : [
#pod             {
#pod                 "name" : "Pod::Elemental::Transformer::List",
#pod                 "args" : { "format_name" : "list" }
#pod             }
#pod         ]
#pod
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command will extract the Pod::Weaver configuration from a
#pod directory containing a L<Dist::Zilla> distribution.
#pod
#pod The results will be serialized in the requested format, and written to
#pod C<STDOUT>.
#pod
#pod The option C<-f> or C<--format> may be used to request a particular
#pod output format. The following formats are currently available:
#pod
#pod =for :list
#pod * json
#pod the default
#pod * lisp
#pod a plist of lists of plists
#pod
#pod =cut

has formatters => (
    traits  => [qw(Hash)],
    isa     => Map[Str, CodeRef],
    lazy    => 1,
    builder => '_build_formatters',
    handles => {
        formatter_for     => 'get',
        has_formatter_for => 'exists',
    },
);

sub _build_formatters {
    my ($self) = @_;
    return {
        lisp => sub { Dist::Zilla::App::CommandHelper::weaverconf::SExpGen->new->visit($_[0]) },
        json => sub { JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1)->encode($_[0]) },
    };
}

sub abstract { "extract your dist's Pod::Weaver configuration" }

sub opt_spec {
    [ 'format|f:s' => 'the output format to use. defaults to json' ],
}

sub execute {
    my ($self, $opt, $arg) = @_;
    $self->print(
        $self->format_weaver_config({
            format => (exists $opt->{format} ? $opt->{format} : 'json'),
            config => $self->extract_weaver_config
        }),
    );
    return;
}

sub extract_weaver_config {
    my ($self) = @_;

    my $zilla_weaver = first {
        $_->isa('Dist::Zilla::Plugin::PodWeaver')
    } @{ $self->zilla->plugins};
    exit 1 unless $zilla_weaver;

    my @weaver_plugins = @{ $zilla_weaver->weaver->plugins };

    return {
        collectors => [
            map {
                my $t = $_;
                +{ map {
                    ($_ => $t->$_)
                } qw(command new_command) }
            } grep {
                $_->isa('Pod::Weaver::Section::Collect')
            } @weaver_plugins
        ],
        transformers => [
            map {
                +{
                    name => blessed $_->transformer,
                    args => {
                        $_->transformer->isa('Pod::Elemental::Transformer::List')
                            ? (format_name => $_->transformer->format_name)
                            : ()
                    },
                }
            } grep {
                $_->isa('Pod::Weaver::Plugin::Transformer')
            } @weaver_plugins
        ],
    };
}

sub format_weaver_config {
    my ($self, $args) = @_;

    unless ($self->has_formatter_for($args->{format})) {
        $self->log("No formatter available for " . $args->{format});
        exit 1;
    }

    return $self->formatter_for($args->{format})->($args->{config});
}

sub print {
    my ($self, $formatted) = @_;
    $self->log($formatted);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::weaverconf - Extract your distribution's Pod::Weaver configuration

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    $ dzil weaverconf
    {
        "collectors" : [
            { "command" : "attr",   "new_command" : "head2" },
            { "command" : "method", "new_command" : "head2" },
            { "command" : "func",   "new_command" : "head2" },
            { "command" : "type",   "new_command" : "head2" }
        ],
        "transformers" : [
            {
                "name" : "Pod::Elemental::Transformer::List",
                "args" : { "format_name" : "list" }
            }
        ]

    }

=head1 DESCRIPTION

This command will extract the Pod::Weaver configuration from a
directory containing a L<Dist::Zilla> distribution.

The results will be serialized in the requested format, and written to
C<STDOUT>.

The option C<-f> or C<--format> may be used to request a particular
output format. The following formats are currently available:

=over 4

=item *

json

the default

=item *

lisp

a plist of lists of plists

=back

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=cut
