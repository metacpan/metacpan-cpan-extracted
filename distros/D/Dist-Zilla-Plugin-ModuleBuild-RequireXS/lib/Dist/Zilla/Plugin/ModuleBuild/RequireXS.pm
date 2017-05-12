package Dist::Zilla::Plugin::ModuleBuild::RequireXS;
{
  $Dist::Zilla::Plugin::ModuleBuild::RequireXS::VERSION = '0.01';
}

use strict;
use warnings;

use Moose;
extends 'Dist::Zilla::Plugin::ModuleBuild';

my $cc_check = <<'EOF';
use ExtUtils::CBuilder;

if ( !( grep { $_ eq '--pp' } @ARGV )
    && ExtUtils::CBuilder->new()->have_compiler )
{
    my $recommends = $module_build_args{recommends} || {};
    my $requires   = $module_build_args{requires}   || {};
    my @modules    = MODULES;
    @modules       = grep {/\bXS\b/} keys %$recommends
        unless @modules;
    $requires->{$_} = delete $recommends->{$_} || 0
        for @modules;
}

EOF

has module => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

sub mvp_multivalue_args { return qw(module) }

after setup_installer => sub {
    my $self = shift;

    my ($file)
        = grep { $_->name() eq 'Build.PL' } @{ $self->zilla()->files() };

    my $content = $file->content();
    my $check   = $cc_check;
    my $modules = 'qw(' . join( ' ', @{ $self->module } ) . ')';
    $check   =~ s/MODULES/$modules/;
    $content =~ s/(my \$build)/$check$1/;

    $file->content($content);

    return;
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Auto-promote recommended XS modules to required, when a C compiler is available.

__END__

=head1 NAME

Dist::Zilla::Plugin::ModuleBuild::RequireXS

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your F<dist.ini>:

   # Any module that contains 'XS'
   [ModuleBuild::RequireXS]

   # Only specified modules
   [ModuleBuild::RequireXS]
   module = JSON::XS
   module = YAML::XS

=head1 DESCRIPTION

Use this plugin instead of the regular C<ModuleBuild> plugin when you are
relying on XS modules that have a pure Perl fallback, eg L<JSON>, L<JSON::XS>
and L<JSON::PP>.

It generates a F<Build.PL> which will promote XS modules
from C<recommends> to C<requires> if there is a working C compiler.
This behaviour can be disabled by passing a C<--pp> flag to C<Build.PL>.

By default, it will select any module in the C<recommends> list that
include C<XS> in the name.  Otherwise you can specify a list of modules in
your C<dist.ini>

=head1 SUPPORT

If you have any suggestions for improvements, or find any bugs, please report
them to L<http://github.com/clintongormley/Dist-Zilla-Plugin-ModuleBuild-RequireXS/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=cut
