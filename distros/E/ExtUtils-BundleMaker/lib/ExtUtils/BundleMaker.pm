package ExtUtils::BundleMaker;

use strict;
use warnings FATAL => 'all';
use version;

use Moo;
use MooX::Options with_config_from_file => 1;
use Module::CoreList ();
use Module::Runtime qw/require_module use_module module_notional_filename/;
use File::Basename qw/dirname/;
use File::Path qw//;
use File::Slurp qw/read_file write_file/;
use File::Spec qw//;
use Params::Util qw/_HASH _ARRAY/;
use Sub::Quote qw/quote_sub/;

=head1 NAME

ExtUtils::BundleMaker - Supports making bundles of modules recursively

=cut

our $VERSION = '0.006';

=head1 SYNOPSIS

    use ExtUtils::BundleMaker;

    my $eu_bm = ExtUtils::BundleMaker->new(
        modules => [ 'Important::One', 'Mandatory::Dependency' ],
	# down to which perl version core modules shall be included?
	recurse => 'v5.10',
	target => 'inc/bundle.inc',
    );
    # create bundle
    $eu_bm->make_bundle();

=head1 DESCRIPTION

ExtUtils::BundleMaker is designed to support authors automatically create
a bundle of important prerequisites which aren't needed outside of the
distribution but might interfere or overload target.

Because of no dependencies are recorded within a distribution, entire
distributions of recorded dependencies are bundled.

=head1 ATTRIBUTES

Following attributes are supported by ExtUtils::BundleMaker

=head2 modules

Specifies name of module(s) to create bundle for

=head2 target

Specifies target for bundle

=head2 recurse

Specify the Perl core version to recurse until.

=head2 name

Allows to specify a package name for generated bundle. Has C<has_> predicate
for test whether it's set or not.

=head1 METHODS

=cut

sub _coerce_modules
{
    my $modules = shift;
    _HASH($modules)  and return $modules;
    _ARRAY($modules) and return {
        map {
            my ( $m, $v ) = split( /=/, $_, 2 );
            defined $v or $v = 0;
            ( $m => $v )
        } @$modules
    };
    die "Inappropriate format: $modules";
}

option modules => (
    is        => "ro",
    doc       => "Specifies name of module(s) to create bundle for",
    required  => 1,
    format    => "s@",
    autosplit => ",",
    coerce    => \&_coerce_modules,
);

option recurse => (
    is       => "lazy",
    doc      => "Automatically bundles dependencies for specified Perl version",
    required => 1,
    format   => "s",
    isa      => quote_sub(q{ exists $Module::CoreList::version{$_[0]} or die "Unsupported Perl version: $_[0]" }),
    coerce   => quote_sub(q{ my $nv = version->new($_[0])->numify; $nv =~ s/0+$//; $nv; }),
);

option target => (
    is       => "ro",
    doc      => "Specifies target for bundle",
    required => 1,
    format   => "s"
);

option name => (
    is        => "ro",
    doc       => "Allows to specify a package name for generated bundle",
    format    => "s",
    predicate => 1,
);

has _remaining_deps => (
    is        => "lazy",
    init_args => undef
);

has _provided => (
    is        => "ro",
    default   => sub { {} },
    init_args => undef
);

sub _build__remaining_deps { {} }

sub _build_recurse
{
    $];
}

has chi_init => ( is => "lazy" );

sub _build_chi_init
{
    my %chi_args = (
        driver   => 'File',
        root_dir => '/tmp/metacpan-cache',
    );
    return \%chi_args;
}

has _meta_cpan => (
    is       => "lazy",
    init_arg => undef,
);

sub _build__meta_cpan
{
    my $self = shift;
    require_module("MetaCPAN::Client");
    my %ua;
    eval {
        use_module("CHI");
        use_module("WWW::Mechanize::Cached");
        use_module("HTTP::Tiny::Mech");
        %ua = (
            ua => HTTP::Tiny::Mech->new(
                mechua => WWW::Mechanize::Cached->new(
                    cache => CHI->new( %{ $self->chi_init } ),
                )
            )
        );
    };
    my $mcpan = MetaCPAN::Client->new(%ua);
    return $mcpan;
}

has requires => (
    is => "lazy",
);

sub _build_requires
{
    my $self     = shift;
    my $core_v   = $self->recurse;
    my $mcpan    = $self->_meta_cpan;
    my %modules  = %{ $self->modules };
    my @required = sort keys %modules;
    my %core_req;
    my %satisfied;
    my @loaded;

    while (@required)
    {
        my $modname = shift @required;
        $modname eq "perl" and next;    # XXX update $core_v if gt and rerun?
        my $mod = $mcpan->module($modname);
        $mod->distribution eq "perl" and next;
        my $dist = $mcpan->release( $mod->distribution );
        unless ( $dist->provides )
        {
            warn $mod->distribution . " provides nothing - skip bundling";
            $core_req{$modname} = $modules{$modname};
            next;
        }
        foreach my $dist_mod ( @{ $dist->provides } )
        {
            $satisfied{$dist_mod} and next;
            push @loaded, $dist_mod;
            $satisfied{$dist_mod} = 1;
            eval {
                my $pmod = $mcpan->module($dist_mod);
                $satisfied{$_} = 1 for ( map { $_->{name} } @{ $pmod->module } );
            };
        }

        my %deps = map { $_->{module} => $_->{version} }
          grep { $_->{phase} eq "runtime" and $_->{relationship} eq "requires" } @{ $dist->dependency };
        foreach my $dep ( keys %deps )
        {
            defined $satisfied{$dep} and next;
            # nice use-case for part, but will result in chicken-egg situation
            if (
                Module::CoreList::is_core( $dep, $deps{$dep} ? $deps{$dep} : undef, $core_v )
                and not( Module::CoreList::deprecated_in($dep)
                    or Module::CoreList::removed_from($dep) )
              )
            {
                defined( $core_req{$dep} )
                  and version->new( $core_req{$dep} ) > version->new( $deps{$dep} )
                  and next;
                $core_req{$dep} = $deps{$dep};
            }
            else
            {
                push @required, $dep;
                $modules{$dep} = $deps{$dep};
            }
        }
    }

    delete $modules{perl};

    # update modules for loader ...
    %{ $self->modules }         = %modules;
    %{ $self->_remaining_deps } = %core_req;

    [ reverse @loaded ];
}

has _bundle_body_stub => ( is => "lazy" );

sub _build__bundle_body_stub
{
    my $self       = shift;
    my $_body_stub = "";

    $self->has_name and $_body_stub .= "package " . $self->name . ";\n\n";

    $_body_stub .= <<'EOU';
use IPC::Cmd qw(run QUOTE);

sub check_module
{
    my ($mod, $ver) = @_;
    my $test_code = QUOTE . "$mod->VERSION($ver)" . QUOTE;
    ($ok, $err, $full_buf, $stdout_buff, $stderr_buff) = run( command => "$^X -M$mod -e $test_code");
    return $ok;
}

EOU

    my @requires = @{ $self->requires };
    $self->has_name
      and $_body_stub .= sprintf
      <<'EOR', Data::Dumper->new( [ $self->_remaining_deps ] )->Terse(1)->Purity(1)->Useqq(1)->Sortkeys(1)->Dump, Data::Dumper->new( [ $self->_provided ] )->Terse(1)->Purity(1)->Useqq(1)->Sortkeys(1)->Dump, Data::Dumper->new( [ $self->requires ] )->Terse(1)->Purity(1)->Useqq(1)->Sortkeys(1)->Dump;
sub remaining_deps
{
    return %s
}

sub provided_bundle
{
    return %s
}

sub required_order
{
    return %s
}

EOR

    return $_body_stub;
}

has _bundle_body => ( is => "lazy" );

sub _build__bundle_body
{
    my $self = shift;

    my @requires = @{ $self->requires };
    # keep order; requires builder might update modules
    my %modules = %{ $self->modules };
    my $body    = "";

    foreach my $mod (@requires)
    {
        my $modv = $modules{$mod};
        defined $modv or $modv = 0;
        my $mnf = module_notional_filename( $modv ? use_module( $mod, $modv ) : use_module($mod) );
        $body .= sprintf <<'EOU', $mod, $modv;
check_module("%s", "%s") or do { eval <<'END_OF_EXTUTILS_BUNDLE_MAKER_MARKER';
EOU

        $body .= read_file( $INC{$mnf} );
        $body .= "\nEND_OF_EXTUTILS_BUNDLE_MAKER_MARKER\n\n";
        $body .= "    \$@ and die \$@;\n";
        $body .= sprintf "    defined \$INC{'%s'} or \$INC{'%s'} = 'Bundled';\n};\n", $mnf, $mnf;
        $body .= "\n";

        $modv = $mod->VERSION;
        defined $modv or $modv = 0;
        $modules{$mod} = $modv;
    }

    %{ $self->_provided } = %modules;

    return $body;
}

=head2 make_bundle

=cut

sub make_bundle
{
    my $self   = shift;
    my $target = $self->target;

    my $body = $self->_bundle_body . "\n1;\n";
    # stub contains additional information when module is generated
    $body = $self->_bundle_body_stub . $body;

    my $target_dir = dirname($target);
    -d $target_dir or File::Path::make_path($target_dir);

    return write_file( $target, $body );
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-extutils-bundlemaker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-BundleMaker>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::BundleMaker

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-BundleMaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-BundleMaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-BundleMaker>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-BundleMaker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of ExtUtils::BundleMaker
