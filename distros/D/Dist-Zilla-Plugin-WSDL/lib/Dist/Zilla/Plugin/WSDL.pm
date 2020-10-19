package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.208';     # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [WSDL]
#pod     uri = http://example.com/path/to/service.wsdl
#pod     prefix = My::Dist::Remote::
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Dist::Zilla|Dist::Zilla> plugin will create classes in your
#pod distribution for interacting with a web service based on that service's
#pod published WSDL file.  It uses L<SOAP::WSDL|SOAP::WSDL> and can optionally add
#pod both a class prefix and a typemap.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Dist::Zilla|Dist::Zilla>
#pod
#pod =item L<SOAP::WSDL|SOAP::WSDL>
#pod
#pod =back
#pod
#pod =cut

use autodie;
use English '-no_match_vars';
use File::Copy 'copy';
use LWP::UserAgent;
use Moose;
use Moose::Meta::TypeConstraint;
use MooseX::AttributeShortcuts;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Str);
use MooseX::Types::Perl 'ModuleName';
use MooseX::Types::URI 'Uri';
use Path::Tiny;
use SOAP::WSDL::Expat::WSDLParser;
use SOAP::WSDL::Factory::Generator;
use Try::Tiny;
use namespace::autoclean;
with qw(
    Dist::Zilla::Role::Tempdir
    Dist::Zilla::Role::BeforeBuild
);

#pod =attr uri
#pod
#pod URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
#pod Perl classes.
#pod
#pod =cut

has uri => ( is => 'ro', required => 1, coerce => 1, isa => Uri );

has _definitions => ( is => 'lazy', isa => 'SOAP::WSDL::Definitions' );

sub _build__definitions {
    my $self = shift;
    my $uri  = $self->uri;

    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $parser = SOAP::WSDL::Expat::WSDLParser->new( { user_agent => $lwp } );

    my $wsdl;
    try { $wsdl = $parser->parse_uri( $self->uri ) }
    catch { $self->log_fatal("could not parse $uri into WSDL: $_") };
    return $wsdl;
}

has _OUTPUT_PATH => ( is => 'lazy', isa => Str, default => q{.} );

#pod =attr prefix
#pod
#pod String used to prefix generated class names.  Default is "My", which will result
#pod in classes under:
#pod
#pod =over
#pod
#pod =item C<MyAttributes::>
#pod
#pod =item C<MyElements::>
#pod
#pod =item C<MyInterfaces::>
#pod
#pod =item C<MyServer::>
#pod
#pod =item C<MyTypes::>
#pod
#pod =item C<MyTypemaps::>
#pod
#pod =back
#pod
#pod =cut

has prefix => (
    is      => 'ro',
    default => 'My',
    isa     => Moose::Meta::TypeConstraint->new(
        message =>
            sub {'must be valid class name, optionally ending in "::"'},
        constraint => sub {
            ## no critic (Modules::RequireExplicitInclusion)
            s/ :: \z//msx;
            ModuleName->check($_);
        },
    ),
);

#pod =attr typemap
#pod
#pod A list of SOAP types and the classes that should be mapped to them. Provided
#pod because some WSDL files don't always define every type, especially fault
#pod responses.  Listed as a series of C<< => >> delimited pairs.
#pod
#pod Example:
#pod
#pod     typemap = Fault/detail/FooException => MyTypes::FooException
#pod     typemap = Fault/detail/BarException => MyTypes::BarException
#pod
#pod =for Pod::Coverage mvp_multivalue_args
#pod
#pod =cut

sub mvp_multivalue_args { return 'typemap' }

has _typemap_lines => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    traits   => ['Array'],
    init_arg => 'typemap',
    handles  => { _typemap_array => 'elements' },
    default  => sub { [] },
);

has _typemap => (
    is      => 'lazy',
    isa     => HashRef [ModuleName],
    traits  => ['Hash'],
    handles => { _has__typemap => 'count' },
    default => sub {
        return { map { split / \s* => \s* /msx } $_[0]->_typemap_array };
    },
);

has _generator =>
    ( is => 'lazy', isa => 'SOAP::WSDL::Generator::Template::XSD' );

sub _build__generator {
    my $self = shift;

    my $generator
        = SOAP::WSDL::Factory::Generator->get_generator( { type => 'XSD' } );
    if ( $self->_has__typemap and $generator->can('set_typemap') ) {
        $generator->set_typemap( $self->_typemap );
    }

    my %prefix_method = map { ( $_ => "set_${_}_prefix" ) }
        qw(attribute type typemap element interface server);
    while ( my ( $prefix, $method ) = each %prefix_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->prefix
                . ucfirst($prefix)
                . ( 'server' eq $prefix ? q{} : 's' ) );
    }

    my %attr_method
        = map { ( "_$_" => "set_$_" ) } qw(OUTPUT_PATH definitions);
    while ( my ( $attr, $method ) = each %attr_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->$attr );
    }

    return $generator;
}

#pod =attr generate_server
#pod
#pod Boolean value on whether to generate CGI server code or just interface code.
#pod Defaults to false.
#pod
#pod =cut

has generate_server => ( is => 'lazy', isa => Bool, default => 0 );

#pod =method before_build
#pod
#pod Instructs L<SOAP::WSDL|SOAP::WSDL> to generate Perl classes for the provided
#pod WSDL and gathers them into the C<lib> directory of your distribution.
#pod
#pod =cut

sub before_build {
    my $self = shift;

    my (@generated_files) = $self->capture_tempdir(
        sub {
            $self->_generator->generate();
            my $method = 'generate_'
                . ( $self->generate_server ? 'server' : 'interface' );
            $self->_generator->$method;
        },
    );

    for my $file ( map { $_->file } grep { $_->is_new() } @generated_files ) {
        $file->name( path( 'lib', $file->name )->stringify() );
        $self->log( 'Saving ' . $file->name );
        my $file_path = $self->zilla->root->path( $file->name );
        $file_path->parent->mkpath();
        my $fh = $file_path->openw()
            or $self->log_fatal(
            "could not open $file_path for writing: $OS_ERROR");
        print {$fh} $file->content;
        close $fh;
    }
    return;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

__END__

=pod

=encoding utf8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::WSDL - WSDL to Perl classes when building your dist

=head1 VERSION

version 0.208

=head1 SYNOPSIS

In your F<dist.ini>:

    [WSDL]
    uri = http://example.com/path/to/service.wsdl
    prefix = My::Dist::Remote::

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> plugin will create classes in your
distribution for interacting with a web service based on that service's
published WSDL file.  It uses L<SOAP::WSDL|SOAP::WSDL> and can optionally add
both a class prefix and a typemap.

=head1 ATTRIBUTES

=head2 uri

URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
Perl classes.

=head2 prefix

String used to prefix generated class names.  Default is "My", which will result
in classes under:

=over

=item C<MyAttributes::>

=item C<MyElements::>

=item C<MyInterfaces::>

=item C<MyServer::>

=item C<MyTypes::>

=item C<MyTypemaps::>

=back

=head2 typemap

A list of SOAP types and the classes that should be mapped to them. Provided
because some WSDL files don't always define every type, especially fault
responses.  Listed as a series of C<< => >> delimited pairs.

Example:

    typemap = Fault/detail/FooException => MyTypes::FooException
    typemap = Fault/detail/BarException => MyTypes::BarException

=head2 generate_server

Boolean value on whether to generate CGI server code or just interface code.
Defaults to false.

=head1 METHODS

=head2 before_build

Instructs L<SOAP::WSDL|SOAP::WSDL> to generate Perl classes for the provided
WSDL and gathers them into the C<lib> directory of your distribution.

=head1 SEE ALSO

=over

=item L<Dist::Zilla|Dist::Zilla>

=item L<SOAP::WSDL|SOAP::WSDL>

=back

=for Pod::Coverage mvp_multivalue_args

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::WSDL

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-WSDL>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-WSDL>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-WSDL>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::WSDL>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL>

  git clone git://github.com/mjgardner/Dist-Zilla-Plugin-WSDL.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
