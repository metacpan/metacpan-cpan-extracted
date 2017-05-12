package Dist::Zilla::Plugin::PrecomputeVariable;

our $DATE = '2016-01-24'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
);

use Data::Dmp;

use namespace::autoclean;

sub mvp_multivalue_args { qw(variable) }
has variable => (is => 'rw');

sub munge_files {
    no warnings 'uninitialized';
    my $self = shift;

    # this is a list of variables specified in dist.ini. key=name,
    # value=initially 0 and set to 1 if found. so this list serves as a check
    # that we process all variables in the code and do not process variables not
    # listed here.
    my %variables;

    for my $v (ref($self->variable) eq 'ARRAY' ?
                   @{ $self->variable } : $self->variable) {
        $v =~ /\A[\$@%](\w+::)+\w+\z/ or
            $self->log_fatal([
                q(Invalid syntax of variable name '%s', please use fully-qualified ).
                    q(names like '$foo::bar', '@foo::baz', or '%%foo::qux'),
                $v]);
        $variables{$v} = 0;
    }

    for my $file (@{ $self->found_files }) {
        my $content = $file->content;

        # for simplicity, we assume only a single package per file
        my ($file_package) = $content =~ /^\s*package\s+(\w+(?:::\w+)*)/m;

        my $file_modified;
        $content =~ s{^
                      (\s*)                      #1) whitespace
                      ((?:my|our|local)\s+)?     #2) optional prefix
                      ([\$@%])((?:\w+::)+)?(\w+) #3) sigil 4) package 5) var name
                      (\s*=\s*)?                 #6) equal sign
                      (.+?)?                     #7) declaration
                      (;\s*\#\s*PRECOMPUTE)      #8) marker
                      $
                     }
                     {
                         my $v = $4 ? "$3$4$5" : "$3$file_package\::$5";
                         if (!$7) {
                             $self->log_fatal([q(Variable declaration '%s' in %s does not assign value to be precomputed), $v, $file->name]);
                         } elsif (exists $variables{$v}) {
                             $self->log_debug([q(Precomputing variable '%s' in %s ...), $v, $file->name]);
                             my @res = eval $7;
                             $self->log_fatal([q(Code '%s' in %s fails to compile: %s), $6, $file->name, $@]) if $@;
                             $variables{$v}++;
                             $file_modified++;
                             "$1$2$3$4$5$6".dmp(@res)."${8}D FROM: $7";
                         } else {
                             $self->log_fatal([q(Variable '%s' in %s not listed in dist.ini), $v, $file->name]);
                         }
                     }egmx;
        $file->content($content) if $file_modified;
    }

    for (keys %variables) {
        unless ($variables{$_}) {
            $self->log_fatal([q(Didn't find declaration of variable '%s'), $_]);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Precompute variable values during building

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PrecomputeVariable - Precompute variable values during building

=head1 VERSION

This document describes version 0.04 of Dist::Zilla::Plugin::PrecomputeVariable (from Perl distribution Dist-Zilla-Plugin-PrecomputeVariable), released on 2016-01-24.

=head1 SYNOPSIS

In F<dist.ini>:

 [PrecomputeVariable]
 variable = $Some::Module::var1
 variable = %Some::OtherModule::var2
 ; add more variables as needed

in your module F<lib/Some/Module.pm>:

 package Some::Module;
 our $var1 = do { some expensive operation }; # PRECOMPUTE
 ...

in your module F<lib/Some/OtherModule.pm>:

 package Some::OtherModule;
 my %Some::OtherModule::var2 = some_expensive_func(); # PRECOMPUTE
 ...

In the generated F<lib/Some/Module.pm>:

 package Some::Module;
 our $var1 = ["some", "value"]; # PRECOMPUTED FROM: do { some expensive operation }
 ...

In the generated F<lib/Some/OtherModule.pm>:

 package Some::OtherModule;
 my %Some::OtherModule::var2 = ("some", "value"); # PRECOMPUTED FROM: some_expensive_func();
 ...

=head1 DESCRIPTION

This plugin can be used to precompute variables values during build time and put
the resulting computed value into the built source code. This is useful in some
cases to reduce module startup time, especially if it takes some time to compute
the value.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PrecomputeVariable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Precompute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PrecomputeVariable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
