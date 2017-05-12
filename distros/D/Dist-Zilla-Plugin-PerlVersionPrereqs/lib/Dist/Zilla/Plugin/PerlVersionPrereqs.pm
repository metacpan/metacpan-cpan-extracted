package Dist::Zilla::Plugin::PerlVersionPrereqs;
BEGIN {
  $Dist::Zilla::Plugin::PerlVersionPrereqs::AUTHORITY = 'cpan:DOY';
}
{
  $Dist::Zilla::Plugin::PerlVersionPrereqs::VERSION = '0.01';
}
use Moose;
# ABSTRACT: set additional prereqs for older perls

with 'Dist::Zilla::Role::InstallTool', 'Dist::Zilla::Role::MetaProvider';


has prereq_perl_version => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->plugin_name;
    },
);

has _prereqs => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    my $opts = $class->SUPER::BUILDARGS(@_);

    my $zilla       = delete $opts->{zilla};
    my $plugin_name = delete $opts->{plugin_name};

    my %extra = map { $_ => delete $opts->{$_} } grep { /^\W/ } keys %$opts;

    return {
        zilla       => $zilla,
        plugin_name => $plugin_name,
        _prereqs    => $opts,
        (map { $_ => $extra{$_} } keys %extra),
    };
}

sub setup_installer {
    my $self = shift;

    my $perl_version = $self->prereq_perl_version;

    confess "You must specify a perl version"
        unless $perl_version;

    my ($makefile_pl) = grep { $_->name eq 'Makefile.PL' }
                             @{ $self->zilla->files };

    confess "This plugin only supports [MakeMaker]"
        unless $makefile_pl;

    my $prereqs = $self->_prereqs;
    return unless keys %$prereqs;

    my $content = $makefile_pl->content;

    my $prereq_string = join("\n        ", map {
        qq["$_" => "$prereqs->{$_}",]
    } keys %$prereqs);

    my $extra_content = <<EXTRA;
if (\$] < $perl_version) {
    \$WriteMakefileArgs{PREREQ_PM} = {
        \%{ \$WriteMakefileArgs{PREREQ_PM} },
        $prereq_string
    };
}
EXTRA

    $content =~ s/(WriteMakefile\()/$extra_content\n$1/
        or die "Couldn't update Makefile.PL contents";

    $makefile_pl->content($content);
}

sub metadata {
    return { dynamic_config => 1 };
}

around dump_config => sub {
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig(@_);

    $config->{''.__PACKAGE__} = {
        perl_version => $self->prereq_perl_version,
    };

    return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::PerlVersionPrereqs - set additional prereqs for older perls

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  ; dist.ini
  [PerlVersionPrereqs / 5.010]
  Perl6::Say = 0

=head1 DESCRIPTION

When perl gets new features, oftentimes they are reimplemented as CPAN modules
for earlier perls which don't have those features. It's a bit silly to
unconditionally depend on those backwards compatiblity modules if they are just
going to do nothing at all on the version of perl you're installing them on
though, so this module allows you to specify that certain dependencies aren't
required on perls newer than a certain version.

NOTE: This plugin only works on dists that are using the default C<[MakeMaker]>
plugin.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-dist-zilla-plugin-perlversionprereqs at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-PerlVersionPrereqs>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::OSPrereqs>

This plugin is based heavily on code from the C<[OSPrereqs]> plugin.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Dist::Zilla::Plugin::PerlVersionPrereqs

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Dist-Zilla-Plugin-PerlVersionPrereqs>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-PerlVersionPrereqs>

=item * Github

L<https://github.com/doy/dist-zilla-plugin-perlversionprereqs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-PerlVersionPrereqs>

=back

=for Pod::Coverage   metadata
  setup_installer

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
