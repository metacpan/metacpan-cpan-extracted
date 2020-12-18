package JavaScript::Const::Exporter;

# ABSTRACT: Convert exported Perl constants to JavaScript

use v5.10;

use Moo 1.002000;
use MooX::Options
    protect_argv => 0,
    usage_string => '%c %o [output-filename]';

use Carp;
use JSON::MaybeXS ();
use Module::Load qw/ load /;
use Package::Stash;
use Ref::Util qw/ is_scalarref /;
use Sub::Identify 0.06 qw/ is_sub_constant /;
use Try::Tiny;
use Types::Common::String qw/ NonEmptySimpleStr /;
use Types::Standard qw/ ArrayRef Bool HashRef InstanceOf /;

# RECOMMEND PREREQ: Cpanel::JSON::XS
# RECOMMEND PREREQ: Package::Stash::XS
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean;

our $VERSION = 'v0.1.4';


option use_var => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
    negatable => 0,
    short     => 'u',
    doc       => 'use var instead of const',
);


option module => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
    format   => 's',
    short    => 'm',
    doc      => 'module name to extract constants from',
);


option constants => (
    is         => 'ro',
    isa        => ArrayRef [NonEmptySimpleStr],
    predicate  => 1,
    format     => 's',
    repeatable => 1,
    short      => 'c',
    doc        => 'constants or export tags to extract',
);


option include => (
    is         => 'ro',
    isa        => ArrayRef [NonEmptySimpleStr],
    predicate  => 1,
    short      => 'I',
    format     => 's',
    repeatable => 1,
    doc        => 'paths to include',
);


option pretty => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
    short     => 'p',
    doc       => 'enable pretty printed JSON',
);


has stash => (
    is      => 'lazy',
    isa     => InstanceOf ['Package::Stash'],
    builder => sub {
        my ($self) = @_;
        if ($self->has_include) {
            push @INC, @{$self->include};
        }
        my $namespace = $self->module;
        load($namespace);
        return Package::Stash->new($namespace);
    },
    handles => [qw/ has_symbol get_symbol /],
);


has tags => (
    is      => 'lazy',
    isa     => HashRef,
    builder => sub {
        my ($self) = @_;
        if ( $self->has_symbol('%EXPORT_TAGS') ) {
            return $self->get_symbol('%EXPORT_TAGS');
        }
        else {
            my $namespace = $self->module;
            croak "No \%EXPORT_TAGS were found in ${namespace}";
        }
    }
);


has json => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        return JSON::MaybeXS->new(
            utf8         => 1,
            allow_nonref => 1,
            pretty       => $self->pretty,
        );
    },
    handles => [qw/ encode /],
);


sub process {
    my ($self) = @_;

    my @imports;

    if ( $self->has_constants ) {
        @imports = @{ $self->constants };
    }
    elsif ( $self->has_symbol('@EXPORT_OK') ) {
        @imports = @{ $self->get_symbol('@EXPORT_OK') };
    }
    else {
        croak "No \@EXPORT_OK in " . $self->module;
    }

    my %symbols = map { $self->_import_to_symbol($_) } @imports;

    my $decl = $self->use_var ? "var" : "const";

    my $buffer = "";
    for my $name ( sort keys %symbols ) {
        my $val = $symbols{$name};
        my $json = $self->encode($val);
        $json =~ s/\n$// if $self->pretty;
        $buffer .= "${decl} ${name} = ${json};\n";
    }
    return $buffer;
}

sub _import_to_symbol {
    my ( $self, $import ) = @_;

    state $reserved = {
        map { $_ => 1 }
          qw/
          abstract arguments await boolean break byte case catch char class
          const continue debugger default delete do double else enum eval
          export extends false final finally float for function goto if
          implements import in instanceof int interface let long native new
          null package private protected public return short static super
          switch synchronized this throw throws transient true try typeof
          var void volatile while with yield
          /
    };

    return ( ) if $reserved->{$import};

    if ( my ($name) = $import =~ /^[\$\@\%](\w.*)$/ ) {
        my $ref = $self->get_symbol($import);
        my $val = is_scalarref($ref) ? $$ref : $ref;
        return ( $name => $val );
    }
    elsif ( my ($tag) = $import =~ /^[:\-](\w.*)$/ ) {
        my $imports = $self->tags->{$tag}
          or croak "No tag '${tag}' found in " . $self->module;
        return ( map { $self->_import_to_symbol($_) } @{$imports} );
    }
    else {
        my $fn  = $self->get_symbol( '&' . $import )
            or croak "Cannot find symbol '${import}' in " . $self->module;
        is_sub_constant($fn) or carp "Symbol '${import}' is not a constant in " . $self->module;
        my $val = $fn->();
        return ( $import => $val );
    }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JavaScript::Const::Exporter - Convert exported Perl constants to JavaScript

=head1 VERSION

version v0.1.4

=head1 SYNOPSIS

Support a project has a module that defines constants for export:

  package MyApp::Const;

  use Exporter qw/ import /;

  our @EXPORT_OK = qw/ A B /;

  use constant A => 123;
  use constant B => "Hello";

Then you can export these constants to JavaScript for use with a
web-application's front-end:

  use JavaScript::Const::Exporter;

  my $exporter = JavaScript::Const::Exporter->new(
      module    => 'MyApp::Const',
      constants => [qw/ A B /],
  );

  my $js = $exporter->process

This will return a string with the JavaScript code:

  const A = 123;
  const B = "Hello";

=head1 DESCRIPTION

This module allows you to extract a list of exported constants from a
Perl module and generate JavaScript that can be included in a web
application, thus allowing you to share constants between Perl and
JavaScript.

=head1 ATTRIBUTES

=head2 use_var

When true, these will be defined as "var" variables instead of "const"
values.

=head2 module

This is the (required) name of the Perl module to include.

=head2 constants

This is an array reference of symbols or export tags in the
L</module>'s namespace to export.

If it is omitted (not recommened), then it will look at the modules
C<@EXPORT_OK> list an export all modules.

Any subroutine can be included, however if the subroutine is not not a
coderef constant, e.g. created by L<constant>, then it will emit a
warning.

You must include sigils of constants. However, the exported JavaScript
will omit them, e.g. C<$NAME> will export JavaScript that specifies a
constant called C<NAME>.

=head2 has_constants

True if there are L</constants>.

=head2 include

This is an array reference of paths to add to your C<@INC>, when the
L</module> is not in the default path.

=head2 has_include

True if there are included paths.

=head2 pretty

When true, pretty-print any arrays or objects.

=head2 stash

This is a L<Package::Stash> for the namespace. This is intended for
internal use.

=head2 tags

This is the content of the module's C<%EXPORT_TAGS>. This is intended
for internal use.

=head2 json

This is the JSON encoder. This is intended for internal use.

=head1 METHODS

=head2 process

This method attempts to retrieve the symbols from the module and
generate the JavaScript.

On success, it will return a string containing the JavaScript.

=head1 KNOWN ISSUES

When using with L<Const::Fast::Exporter>-based modules, you must
explicitly list all of the constants to be exported, as that doesn't
provide an C<@EXPORT_OK> variable that can be queried.

=head1 SEE ALSO

L<Const::Exporter>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/JavaScript-Const-Exporter>
and may be cloned from L<git://github.com/robrwo/JavaScript-Const-Exporter.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/JavaScript-Const-Exporter/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
